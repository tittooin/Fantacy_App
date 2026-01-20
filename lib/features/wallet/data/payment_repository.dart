import 'package:axevora11/features/wallet/data/platform/payment_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:axevora11/features/user/presentation/providers/user_provider.dart';
import 'package:axevora11/features/user/domain/user_entity.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

class PaymentRepository {
  final Ref ref;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  PaymentRepository(this.ref);

  Future<void> depositCash({
    required double amount, 
    required String orderId, 
    required Function(String) onSuccess,
    required Function(String) onFailure
  }) async {
    try {
      debugPrint("PaymentRepository: Initiating Deposit $amount for $orderId");
      
      // Use the platform-specific implementation (Android SDK or Web Mock)
      // The correct implementation is loaded via conditional import in 'platform/payment_service.dart'
      final paymentService = PaymentServiceImpl();
      
      await paymentService.depositCash(
        amount: amount,
        orderId: orderId,
        onSuccess: onSuccess,
        onFailure: onFailure,
      );

    } catch (e) {
      debugPrint("PaymentRepository Error: $e");
      onFailure(e.toString());
    }
  }

  Future<bool> verifyPayment(String orderId) async {
    // Call backend to verify status
    // await _backend.verify(orderId);
    return true; // Mock success
  }

  Future<void> requestWithdrawal({
    required double amount,
    required String upiId,
  }) async {
    final userAsync = ref.read(userEntityProvider);
    final user = userAsync.value;
    
    if (user == null) throw Exception("User not logged in");
    
    // SAFETY CHECK: KYC
    if (!user.isKYCVerified) {
       throw Exception("KYC Verification Required for Withdrawal.");
    }
    
    // SAFETY CHECK: Winning Balance
    if (user.winningBalance < amount) {
      throw Exception("Insufficient Winning Balance.");
    }

    // Log Request
    await _firestore.collection('withdrawals').add({
      'userId': user.uid,
      'amount': amount,
      'upiId': upiId,
      'status': 'PENDING',
      'timestamp': FieldValue.serverTimestamp(),
    });
  }
}

final paymentRepositoryProvider = Provider((ref) => PaymentRepository(ref));
