import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final kycRepositoryProvider = Provider((ref) => KYCRepository());

class KYCRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;

  /// Submit KYC Documents
  Future<void> submitKYC({
    required String userId,
    required String fullName,
    required String panNumber,
    required String dob,
    required File panImage,
    required File aadhaarFrontImage,
    required File aadhaarBackImage,
  }) async {
    // 1. Upload Images
    final panUrl = await _uploadFile(userId, 'pan', panImage);
    final aadharFrontUrl = await _uploadFile(userId, 'aadhaar_front', aadhaarFrontImage);
    final aadharBackUrl = await _uploadFile(userId, 'aadhaar_back', aadhaarBackImage);

    // 2. Create KYC Request in Firestore
    await _firestore.collection('kyc_requests').doc(userId).set({
      'userId': userId,
      'fullName': fullName,
      'panNumber': panNumber,
      'dob': dob,
      'panUrl': panUrl,
      'aadhaarFrontUrl': aadharFrontUrl,
      'aadhaarBackUrl': aadharBackUrl,
      'status': 'pending', // pending, verified, rejected
      'submittedAt': FieldValue.serverTimestamp(),
      'rejectionReason': null,
    });

    // 3. Update User Profile Status
    await _firestore.collection('users').doc(userId).update({
      'kycStatus': 'pending',
    });
  }

  Future<String> _uploadFile(String userId, String type, File file) async {
    final ref = _storage.ref().child('kyc_docs/$userId/$type.jpg');
    await ref.putFile(file);
    return await ref.getDownloadURL();
  }

  /// Get KYC Status for User
  Stream<DocumentSnapshot> getKYCStatus(String userId) {
    return _firestore.collection('kyc_requests').doc(userId).snapshots();
  }

  /// Get All Pending KYC Requests (Admin)
  Stream<QuerySnapshot> getPendingKYCRequests() {
    return _firestore.collection('kyc_requests')
        .where('status', isEqualTo: 'pending')
        .orderBy('submittedAt', descending: true)
        .snapshots();
  }

  /// Approve KYC (Admin)
  Future<void> approveKYC(String userId) async {
    final batch = _firestore.batch();
    
    // Update Request
    batch.update(_firestore.collection('kyc_requests').doc(userId), {
      'status': 'verified',
      'verifiedAt': FieldValue.serverTimestamp(),
    });

    // Update User
    batch.update(_firestore.collection('users').doc(userId), {
      'kycStatus': 'verified',
      'isKYCVerified': true,
    });

    await batch.commit();
  }

  /// Reject KYC (Admin)
  Future<void> rejectKYC(String userId, String reason) async {
     final batch = _firestore.batch();
    
    // Update Request
    batch.update(_firestore.collection('kyc_requests').doc(userId), {
      'status': 'rejected',
      'rejectionReason': reason,
      'rejectedAt': FieldValue.serverTimestamp(),
    });

    // Update User
    batch.update(_firestore.collection('users').doc(userId), {
      'kycStatus': 'rejected',
      'isKYCVerified': false,
    });

    await batch.commit();
  }
}
