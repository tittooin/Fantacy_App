import 'package:axevora11/features/user/domain/user_entity.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

abstract class UserRepository {
  Future<void> createUserOrUpdate(User user);
  Future<void> updateUserState(String uid, String state, bool isRestricted);
  Future<UserEntity?> getUser(String uid);
  Future<void> updateProfile({required String uid, String? bio, String? photoUrl, String? displayName});
  Future<void> followUser({required String currentUid, required String targetUid});
  Future<void> unfollowUser({required String currentUid, required String targetUid});
  Future<bool> isFollowing(String currentUid, String targetUid);
}

class FirestoreUserRepository implements UserRepository {
  final FirebaseFirestore _firestore;

  FirestoreUserRepository(this._firestore);

  @override
  Future<void> createUserOrUpdate(User user) async {
    final userRef = _firestore.collection('users').doc(user.uid);
    final snapshot = await userRef.get();

    if (!snapshot.exists) {
      // Create new user (defaults handle new fields)
      final newUser = UserEntity(
        uid: user.uid,
        email: user.email,
        phoneNumber: user.phoneNumber,
        displayName: user.displayName,
        createdAt: DateTime.now(),
        lastLoginAt: DateTime.now(),
      );
      await userRef.set(newUser.toJson());
    } else {
      // Update last login
      await userRef.update({
        'lastLoginAt': Timestamp.now(),
      });
    }
  }

  @override
  Future<void> updateUserState(String uid, String state, bool isRestricted) async {
    await _firestore.collection('users').doc(uid).update({
      'selectedState': state,
      'isRestricted': isRestricted,
    });
  }

  @override
  Future<UserEntity?> getUser(String uid) async {
    final snapshot = await _firestore.collection('users').doc(uid).get();
    if (snapshot.exists && snapshot.data() != null) {
      return UserEntity.fromJson(snapshot.data()!);
    }
    return null;
  }

  @override
  Future<void> updateProfile({required String uid, String? bio, String? photoUrl, String? displayName}) async {
    final Map<String, dynamic> updates = {};
    if (bio != null) updates['bio'] = bio;
    if (photoUrl != null) updates['photoUrl'] = photoUrl;
    if (displayName != null) updates['displayName'] = displayName;

    if (updates.isNotEmpty) {
      await _firestore.collection('users').doc(uid).update(updates);
    }
  }

  @override
  Future<void> followUser({required String currentUid, required String targetUid}) async {
    final userRef = _firestore.collection('users').doc(currentUid);
    final targetRef = _firestore.collection('users').doc(targetUid);
    
    // Subcollections
    final followingRef = userRef.collection('following').doc(targetUid);
    final followerRef = targetRef.collection('followers').doc(currentUid);

    await _firestore.runTransaction((transaction) async {
      final followingSnap = await transaction.get(followingRef);
      if (followingSnap.exists) return; // Already following

      transaction.set(followingRef, {'timestamp': FieldValue.serverTimestamp()});
      transaction.set(followerRef, {'timestamp': FieldValue.serverTimestamp()});

      transaction.update(userRef, {'followingCount': FieldValue.increment(1)});
      transaction.update(targetRef, {'followersCount': FieldValue.increment(1)});
    });
  }

  @override
  Future<void> unfollowUser({required String currentUid, required String targetUid}) async {
    final userRef = _firestore.collection('users').doc(currentUid);
    final targetRef = _firestore.collection('users').doc(targetUid);
    
    final followingRef = userRef.collection('following').doc(targetUid);
    final followerRef = targetRef.collection('followers').doc(currentUid);

    await _firestore.runTransaction((transaction) async {
      final followingSnap = await transaction.get(followingRef);
      if (!followingSnap.exists) return; // Not following

      transaction.delete(followingRef);
      transaction.delete(followerRef);

      transaction.update(userRef, {'followingCount': FieldValue.increment(-1)});
      transaction.update(targetRef, {'followersCount': FieldValue.increment(-1)});
    });
  }

  @override
  Future<bool> isFollowing(String currentUid, String targetUid) async {
     final doc = await _firestore.collection('users').doc(currentUid).collection('following').doc(targetUid).get();
     return doc.exists;
  }
}

final userRepositoryProvider = Provider<UserRepository>((ref) {
  return FirestoreUserRepository(FirebaseFirestore.instance);
});
