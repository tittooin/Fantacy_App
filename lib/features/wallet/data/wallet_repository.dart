import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';

class WalletRepository {
  final Dio _dio = Dio();

  // Worker URL
  static const String _workerUrl = "https://fantasy-cricket-api.moremagical4.workers.dev";

  /// Fetch Live Balance from Cloudflare Worker (D1)
  Future<Map<String, dynamic>> getBalance(String userId) async {
    try {
      final response = await _dio.get('$_workerUrl/api/wallet/balance', queryParameters: {'userId': userId});
      if (response.statusCode == 200 && response.data['success'] == true) {
        return response.data['balance'] ?? {'deposit': 0, 'winnings': 0, 'total': 0};
      }
      return {'deposit': 0, 'winnings': 0, 'total': 0};
    } catch (e) {
      debugPrint("WalletRepository: Get Balance Failed: $e");
      return {'deposit': 0, 'winnings': 0, 'total': 0};
    }
  }

  /// Create Order via Backend Worker (D1)
  Future<Map<String, dynamic>> createDepositOrder(String userId, double amount) async {
    try {
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

  /// Get Transaction History (Optimized using D1)
  Future<List<Map<String, dynamic>>> getTransactions(String userId) async {
    try {
      final response = await _dio.get('$_workerUrl/api/wallet/transactions', queryParameters: {'userId': userId});
      
      if (response.statusCode == 200 && response.data['success'] == true) {
        return List<Map<String, dynamic>>.from(response.data['transactions'] ?? []);
      }
      return [];
    } catch (e) {
      debugPrint("Error fetching transactions from D1: $e");
      return [];
    }
  }

  /// Create Withdrawal Request (D1 via Worker)
  Future<bool> requestWithdrawal({
    required String userId,
    required double amount,
    required String method,
    required String details,
  }) async {
    try {
      final response = await _dio.post(
        '$_workerUrl/api/wallet/withdraw',
        data: {
          'userId': userId,
          'amount': amount,
          'method': method,
          'details': details,
        },
      );
      return response.statusCode == 200 && response.data['success'] == true;
    } catch (e) {
      debugPrint("WalletRepository: Withdrawal Error: $e");
      return false;
    }
  }

  // --- ADMIN WALLET FUNCTIONS (D1 via Worker) ---

  /// Get List of Pending Payouts
  Future<List<Map<String, dynamic>>> getPendingWithdrawals() async {
    try {
      final response = await _dio.get('$_workerUrl/api/admin/withdrawals');
      if (response.statusCode == 200 && response.data['success'] == true) {
        return List<Map<String, dynamic>>.from(response.data['withdrawals'] ?? []);
      }
      return [];
    } catch (e) {
      debugPrint("WalletRepository: Get Pending Withdrawals Failed: $e");
      return [];
    }
  }

  /// Approve/Mark as Paid
  Future<bool> approveWithdrawal(String requestId, String userId, String note) async {
    try {
      final response = await _dio.post(
        '$_workerUrl/api/admin/payout/status',
        data: {
          'requestId': requestId,
          'status': 'approved',
          'note': note,
        },
      );
      return response.statusCode == 200 && response.data['success'] == true;
    } catch (e) {
      debugPrint("WalletRepository: Approve Payout Failed: $e");
      return false;
    }
  }

  /// Reject and Refund
  Future<bool> rejectWithdrawal(String requestId, String userId, double amount, String reason) async {
    try {
      final response = await _dio.post(
        '$_workerUrl/api/admin/payout/status',
        data: {
          'requestId': requestId,
          'status': 'rejected',
          'note': reason,
        },
      );
      return response.statusCode == 200 && response.data['success'] == true;
    } catch (e) {
      debugPrint("WalletRepository: Reject Payout Failed: $e");
      return false;
    }
  }

  /// Issue Manual Reward (Wins)
  Future<bool> issueRewardCredit(String userId, double amount, String note) async {
    try {
      final response = await _dio.post(
        '$_workerUrl/api/admin/payout/reward',
        data: {
          'userId': userId,
          'amount': amount,
          'note': note,
        },
      );
      return response.statusCode == 200 && response.data['success'] == true;
    } catch (e) {
      debugPrint("WalletRepository: Issue Reward Failed: $e");
      return false;
    }
  }

  /// Generic Add Funds (Alias for Reward for now)
  Future<bool> addFunds(String userId, double amount) async {
    return issueRewardCredit(userId, amount, "Manual Credit");
  }

  /// Get All Users List (Admin)
  Future<List<Map<String, dynamic>>> getAllUsers() async {
    try {
      final response = await _dio.get('$_workerUrl/api/admin/users');
      if (response.statusCode == 200 && response.data['success'] == true) {
        return List<Map<String, dynamic>>.from(response.data['users'] ?? []);
      }
      return [];
    } catch (e) {
      debugPrint("WalletRepository: Get All Users Failed: $e");
      return [];
    }
  }

  /// Search User by Email (Admin)
  Future<Map<String, dynamic>?> searchUserByEmail(String email) async {
    try {
      final response = await _dio.get('$_workerUrl/api/admin/user/search', queryParameters: {'email': email});
      if (response.statusCode == 200 && response.data['success'] == true) {
        return response.data['user'];
      }
      return null;
    } catch (e) {
      debugPrint("WalletRepository: Search User Failed: $e");
      return null;
    }
  }
}

final walletRepositoryProvider = Provider((ref) => WalletRepository());
