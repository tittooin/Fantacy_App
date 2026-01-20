import 'package:flutter_cashfree_pg_sdk/api/cfreasesion/cfree_session.dart';
import 'package:flutter_cashfree_pg_sdk/api/cferror/cferror.dart';
import 'package:flutter_cashfree_pg_sdk/utils/cfenums.dart';
import 'package:flutter_cashfree_pg_sdk/utils/cfexceptions.dart';
import 'package:flutter_cashfree_pg_sdk/api/cfpayment/cfwebcheckoutpayment.dart';
import 'package:flutter_cashfree_pg_sdk/api/cfpaymentgateway/cfpaymentgatewayservice.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:axevora11/features/user/presentation/providers/user_provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

class PaymentRepository {
  final Ref ref;
  final CFPaymentGatewayService _cfPaymentGatewayService = CFPaymentGatewayService();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  PaymentRepository(this.ref);

  // Cashfree integration requires a "Session ID" from your backend.
  // Since we are serverless (partially), we might need a Cloud Function or a secure way to generate this.
  // For strict security, NEVER generate Session ID on client.
  // Assuming we have a Cloud Function endpoint or similar.
  // For Phase 19 Base, we will simulate the "Start" and handling.

  Future<void> depositCash({
    required double amount, 
    required String orderId, 
    required Function(String) onSuccess,
    required Function(String) onFailure
  }) async {
    try {
      // 1. In a real app, call Backend to get 'payment_session_id' for this orderId + amount.
      // String sessionId = await _backend.createOrder(amount, orderId);
      
      // MOCK for now (or Placeholder):
      String sessionId = "session_placeholder_$orderId"; 
      
      // 2. Create Session
      var session = CFSessionBuilder()
          .setEnvironment(CFEnvironment.SANDBOX) // Switch to PRODUCTION when keys ready
          .setOrderId(orderId)
          .setPaymentSessionId(sessionId)
          .build();

      // 3. Web Checkout (since we are on Web mostly, or use specific flow)
      // Check platform
      if (kIsWeb) {
        var cfWebCheckout = CFWebCheckoutPaymentBuilder()
            .setSession(session)
            .build();
        _cfPaymentGatewayService.doPayment(cfWebCheckout);
      } else {
         // Android/iOS Native
         // _cfPaymentGatewayService.doPayment(cfDropCheckoutPayment);
         // For now, keeping it robust/simple.
         onFailure("Native payment flows need 'Drop' checkout implementation.");
      }
      
      // Listeners are usually set via the SDK callbacks globally or passed.
      _cfPaymentGatewayService.setCallback(
        (orderId) {
           verifyPayment(orderId).then((success) {
             if (success) onSuccess(orderId);
             else onFailure("Verification Failed");
           });
        },
        (error, orderId) => onFailure(error.getMessage() ?? "Payment Failed"),
      );

    } catch (e) {
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
    final user = ref.read(userProvider);
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
