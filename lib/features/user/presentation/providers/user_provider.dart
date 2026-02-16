import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:axevora11/features/user/domain/user_entity.dart';
import 'package:axevora11/features/auth/data/auth_repository.dart';

/// Provides the current authenticated user's ID reactively.
final authUserIdProvider = Provider<String?>((ref) {
  // Watching authStateProvider from auth_repository.dart
  final authStateValue = ref.watch(authStateProvider);
  return authStateValue.value?.uid;
});

/// Stream of the User Entity from Firestore for a specific UID.
final userByUidProvider = StreamProvider.family<UserEntity?, String>((ref, uid) {
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
            // Log error to console - prevents red screen crashes on malformed data
            print("User Parse Error for $uid: $e");
            return null;
          }
        }
        return null;
      });
});

/// Global provider for the currently logged-in user entity.
/// Replaces the old userEntityProvider for backward compatibility.
final userEntityProvider = StreamProvider<UserEntity?>((ref) {
  final uid = ref.watch(authUserIdProvider);
  if (uid == null) return Stream.value(null);
  
  // Return the stream from the family provider
  return ref.watch(userByUidProvider(uid).stream);
});
