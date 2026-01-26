import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

final walletRepositoryProvider = Provider((ref) => WalletRepository());

class WalletRepository {
  final Dio _dio = Dio();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Worker URL
  static const String _workerUrl = "https://fantasy-cricket-api.tittooin.workers.dev";

  /// Realtime Listener for User Wallet Data
  Stream<DocumentSnapshot> listenToUserData(String userId) {
    return _firestore.collection('users').doc(userId).snapshots();
  }
  
  /// Create Order via Backend Worker
  /// Returns {success, paymentLink, orderId, error}
  Future<Map<String, dynamic>> createDepositOrder(String userId, double amount) async {
    try {
      final response = await _dio.post(
        '$_workerUrl/api/create-payment',
        data: {
          "userId": userId,
          "amount": amount,
        },
        options: Options(
          headers: {
            // Add any auth headers if needed, currently open or secured by conventions
            'Content-Type': 'application/json',
          },
        ),
      );

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

  /// Get Transaction History
  Stream<QuerySnapshot> listenToTransactions(String userId) {
    return _firestore
        .collection('transactions')
        .where('userId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .limit(20)
        .snapshots();
  }

  /// Internal: Add Funds (Winnings/Refunds)
  Future<void> addFunds(String userId, double amount) async {
    // Ideally this goes through Worker for security, but for Service-to-Service internal calls in MVP
    // we can use direct DB update if Rules allow, or simple increment.
    // For now, doing direct increment as Admin/System.
    
    await _firestore.runTransaction((transaction) async {
      final userRef = _firestore.collection('users').doc(userId);
      final snapshot = await transaction.get(userRef);
      
      if (snapshot.exists) {
        final current = (snapshot.data()?['winningBalance'] ?? 0.0) as num; 
        // Note: Check if we update winningBalance or walletBalance
        transaction.update(userRef, {
           'winningBalance': current.toDouble() + amount,
           'walletBalance': ((snapshot.data()?['walletBalance'] ?? 0.0) as num).toDouble() + amount
        });
      }
    });
  }
}
