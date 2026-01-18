import 'package:axevora11/core/constants/api_keys.dart';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

final walletRepositoryProvider = Provider((ref) => WalletRepository());

class WalletRepository {
  final Dio _dio = Dio();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Cashfree Base URLs
  static const String _prodUrl = "https://api.cashfree.com/pg";
  static const String _testUrl = "https://sandbox.cashfree.com/pg";

  String get _baseUrl => ApiKeys.cashfreeEnvironment == 'PROD' ? _prodUrl : _testUrl;

  Future<void> addFunds(String userId, double amount) async {
    final userRef = _firestore.collection('users').doc(userId);
    await _firestore.runTransaction((transaction) async {
      final snapshot = await transaction.get(userRef);
      if (snapshot.exists) {
        final currentBalance = (snapshot.data()?['walletBalance'] as num?)?.toDouble() ?? 0.0;
        final newBalance = currentBalance + amount;
        transaction.update(userRef, {'walletBalance': newBalance});
      }
    });
  }

  Future<String?> createOrder(String userId, double amount, String phone) async {
    final orderId = "ORDER_${userId.substring(0, 5)}_${DateTime.now().millisecondsSinceEpoch}";
    
    try {
      final response = await _dio.post(
        '$_baseUrl/orders',
        options: Options(
          headers: {
            'x-client-id': ApiKeys.cashfreeAppId,
            'x-client-secret': ApiKeys.cashfreeSecretKey,
            'x-api-version': '2023-08-01',
            'Content-Type': 'application/json',
          },
        ),
        data: {
          "order_id": orderId,
          "order_amount": amount,
          "order_currency": "INR",
          "customer_details": {
            "customer_id": userId,
            "customer_phone": phone.isNotEmpty ? phone : "9999999999", // Default if missing
            "customer_name": "User $userId" // Can be updated
          },
          "order_meta": {
            "return_url": "https://example.com/return?order_id=$orderId" // Required but handled by SDK
          }
        },
      );

      if (response.statusCode == 200) {
        return response.data['payment_session_id'];
      }
      return null;
    } catch (e) {
      debugPrint("WalletRepository: Create Order Failed: $e");
      if (e is DioException) {
        debugPrint("Response: ${e.response?.data}");
      }
      return null;
    }
  }
}
