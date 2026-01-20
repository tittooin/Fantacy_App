
// Abstract interface for Payment Service


abstract class PaymentService {
  Future<void> depositCash({
    required double amount, 
    required String orderId, 
    required Function(String) onSuccess,
    required Function(String) onFailure,
  });
}
