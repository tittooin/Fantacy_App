import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

final walletRepositoryProvider = Provider((ref) => WalletRepository());

class WalletRepository {
  final Dio _dio = Dio();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Worker URL
  static const String _workerUrl = "https://fantasy-cricket-api.moremagical4.workers.dev";

  /// Realtime Listener for User Wallet Data
  Stream<DocumentSnapshot> listenToUserData(String userId) {
    return _firestore.collection('users').doc(userId).snapshots();
  }
  
  /// Create Order via Backend Worker
  /// Returns {success, paymentLink, orderId, error}
  Future<Map<String, dynamic>> createDepositOrder(String userId, double amount) async {
    try {
      debugPrint("💸 Creating Order: $userId, $amount");

      final token = await FirebaseAuth.instance.currentUser?.getIdToken();
      if (token == null) return {"success": false, "error": "User not authenticated"};

      final response = await _dio.post(
        '$_workerUrl/api/create-payment',
        data: {
          "userId": userId,
          "amount": amount,
        },
        options: Options(
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $token',
          },
        ),
      );
      
      debugPrint("💸 Response: ${response.statusCode} - ${response.data}");

      if (response.statusCode == 200) {
        return response.data;
      } else {
         return {"success": false, "error": "Server Error: ${response.statusCode}"};
      }
    } catch (e) {
      debugPrint("WalletRepository: Create Order Failed: $e");
      return {"success": false, "error": e.toString()};
    }
  }

  /// Get Transaction History (Stream - Expensive)
  Stream<QuerySnapshot> listenToTransactions(String userId) {
    return _firestore
        .collection('transactions')
        .where('userId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .limit(20)
        .snapshots();
  }

  /// Get Transaction History (Future - Optimized using D1)
  Future<List<Map<String, dynamic>>> getTransactions(String userId) async {
    try {
      // Fetch from D1 Worker
      final response = await _dio.get('/api/transactions/my', queryParameters: {'userId': userId});
      
      if (response.statusCode == 200 && response.data['success'] == true) {
        return List<Map<String, dynamic>>.from(response.data['transactions'] ?? []);
      }

      // Fallback: Try Firestore if Worker fails or returns empty (for legacy data)
      final snapshot = await _firestore
          .collection('transactions')
          .where('userId', isEqualTo: userId)
          .orderBy('createdAt', descending: true)
          .limit(20)
          .get();

      return snapshot.docs.map((doc) => doc.data()).toList();
    } catch (e) {
      debugPrint("Error fetching transactions: $e");
      return [];
    }
  }

  /// Internal: Add Funds (Winnings/Refunds)
  Future<void> addFunds(String userId, double amount) async {
    await _firestore.runTransaction((transaction) async {
      final userRef = _firestore.collection('users').doc(userId);
      final snapshot = await transaction.get(userRef);
      
      if (snapshot.exists) {
        final current = (snapshot.data()?['winningBalance'] ?? 0.0) as num; 
        transaction.update(userRef, {
           'winningBalance': current.toDouble() + amount,
           'walletBalance': ((snapshot.data()?['walletBalance'] ?? 0.0) as num).toDouble() + amount
        });
      }
    });
  }

  // --- Withdrawal System (Manual) ---

  /// 1. Create Withdrawal Request (User)
  Future<void> requestWithdrawal({
    required String userId,
    required double amount,
    required String method, // 'UPI', 'Bank', 'Voucher'
    required String details, // UPI ID / Email
    required double currentBalance,
  }) async {
    if (amount > currentBalance) throw Exception("Insufficient Balance");
    if (amount < 100) throw Exception("Minimum withdrawal is ₹100");

    final batch = _firestore.batch();
    
    // A. Deduct from User Wallet (Immediate Hold)
    final userRef = _firestore.collection('users').doc(userId);
    batch.update(userRef, {
      'walletBalance': FieldValue.increment(-amount),
      'winningBalance': FieldValue.increment(-amount), // Assuming withdrawal comes from winnings first
    });

    // B. Create Withdrawal Request Doc
    final withdrawRef = _firestore.collection('withdrawals').doc();
    batch.set(withdrawRef, {
      'id': withdrawRef.id,
      'userId': userId,
      'amount': amount,
      'method': method,
      'details': details,
      'status': 'pending',
      'requestDate': FieldValue.serverTimestamp(),
    });

    // C. Add Transaction Record
    final transRef = _firestore.collection('transactions').doc();
    batch.set(transRef, {
      'id': transRef.id,
      'userId': userId,
      'amount': amount,
      'type': 'withdrawal_request',
      'status': 'pending',
      'createdAt': FieldValue.serverTimestamp(),
      'description': 'Withdrawal Request via $method',
      'relatedId': withdrawRef.id, 
    });

    await batch.commit();
  }

  /// 2. Get Pending Withdrawals (Admin)
  Stream<QuerySnapshot> getPendingWithdrawals() {
    return _firestore.collection('withdrawals')
        .where('status', isEqualTo: 'pending')
        .orderBy('requestDate', descending: true)
        .snapshots();
  }

  /// 3. Approve Withdrawal (Admin)
  Future<void> approveWithdrawal(String withdrawId, String userId, String adminNote) async {
    final batch = _firestore.batch();
    
    // A. Update Withdrawal Doc
    batch.update(_firestore.collection('withdrawals').doc(withdrawId), {
      'status': 'approved',
      'processedDate': FieldValue.serverTimestamp(),
      'adminNote': adminNote,
    });

    // B. Transaction Log
    final transRef = _firestore.collection('transactions').doc();
    batch.set(transRef, {
      'id': transRef.id,
      'userId': userId,
      'amount': 0, // No money moves, just status
      'type': 'withdrawal_success',
      'status': 'success',
      'createdAt': FieldValue.serverTimestamp(),
      'description': 'Withdrawal Processed: $adminNote',
      'relatedId': withdrawId,
    });

    await batch.commit();
  }

  /// 4. Reject Withdrawal (Admin)
  Future<void> rejectWithdrawal(String withdrawId, String userId, double amount, String reason) async {
    final batch = _firestore.batch();

    // A. Refund Money
    final userRef = _firestore.collection('users').doc(userId);
    batch.update(userRef, {
      'walletBalance': FieldValue.increment(amount),
      'winningBalance': FieldValue.increment(amount),
    });

    // B. Update Withdrawal Doc
    batch.update(_firestore.collection('withdrawals').doc(withdrawId), {
      'status': 'rejected',
      'processedDate': FieldValue.serverTimestamp(),
      'adminNote': reason,
    });

    // C. Add Refund Transaction
    final transRef = _firestore.collection('transactions').doc();
    batch.set(transRef, {
      'id': transRef.id,
      'userId': userId,
      'amount': amount,
      'type': 'refund',
      'status': 'success',
      'createdAt': FieldValue.serverTimestamp(),
      'description': 'Withdrawal Rejected: $reason',
      'relatedId': withdrawId,
    });

    await batch.commit();
  }
}
