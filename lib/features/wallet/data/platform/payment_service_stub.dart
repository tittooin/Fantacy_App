
import 'package:flutter/foundation.dart';
import 'payment_service_interface.dart';

class PaymentServiceImpl implements PaymentService {
  @override
  Future<void> depositCash({
    required double amount,
    required String orderId,
    required Function(String) onSuccess,
    required Function(String) onFailure,
  }) async {
    debugPrint("WEB/STUB Payment: Mocking Success for $orderId");
    // Mock Delay and Success
    await Future.delayed(const Duration(seconds: 1));
    onSuccess(orderId);
  }
}
