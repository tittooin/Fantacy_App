import 'package:axevora11/features/user/domain/user_entity.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// Provides the current authenticated user's ID
final authUserIdProvider = Provider<String?>((ref) {
  return FirebaseAuth.instance.currentUser?.uid;
});

// Stream of the User Entity from Firestore
final userEntityProvider = StreamProvider<UserEntity?>((ref) {
  final uid = ref.watch(authUserIdProvider);
  if (uid == null) {
    return Stream.value(null);
  }

  return FirebaseFirestore.instance
      .collection('users')
      .doc(uid)
      .snapshots()
      .map((snapshot) {
        if (snapshot.exists && snapshot.data() != null) {
          final data = snapshot.data()!;
          data['uid'] = snapshot.id; // Ensure UID is present from Doc ID

          try {
            return UserEntity.fromJson(data);
          } catch (e) {
            // Log error to console (visible in DevTools)
            // This prevents the 'Red Screen' / 'White Blank' crash
            print("🚨 User Parse Error: $e");
            print("📄 Corrupted Data: $data");
            return null; // Fallback to Guest/Logout
          }
        }
        return null;
      });
});
