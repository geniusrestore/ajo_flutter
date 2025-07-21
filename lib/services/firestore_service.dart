import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Create or update user profile on signup/login
  Future<void> createOrUpdateUser({
    required String email,
    required String name,
    String? phone,
  }) async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return;

    final userDoc = _db.collection('users').doc(uid);

    await userDoc.set({
      'uid': uid,
      'email': email,
      'name': name,
      if (phone != null) 'phone': phone,
      'joinedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  // ✅ Get current user document (for home screen)
  Future<DocumentSnapshot?> getCurrentUserDoc() async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return null;

    final doc = await _db.collection('users').doc(uid).get();
    return doc.exists ? doc : null;
  }

  // ✅ Get user groups by IDs (for home screen)
  Future<List<DocumentSnapshot>> getUserGroups(List<String> groupIds) async {
    if (groupIds.isEmpty) return [];

    final snapshot = await _db
        .collection('groups')
        .where(FieldPath.documentId, whereIn: groupIds)
        .get();

    return snapshot.docs;
  }

  // Create a new Ajo group
  Future<void> createGroup({
    required String groupName,
    required double amount,
    required int frequencyDays,
  }) async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return;

    final groupRef = _db.collection('groups').doc();

    await groupRef.set({
      'groupId': groupRef.id,
      'createdBy': uid,
      'groupName': groupName,
      'amount': amount,
      'frequencyDays': frequencyDays,
      'createdAt': FieldValue.serverTimestamp(),
      'members': [uid],
    });

    // Update user's joined groups
    await _db.collection('users').doc(uid).set({
      'joinedGroups': FieldValue.arrayUnion([groupRef.id]),
    }, SetOptions(merge: true));
  }

  // Add a contribution to a group
  Future<void> addContribution({
    required String groupId,
    required double amount,
  }) async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return;

    await _db.collection('contributions').add({
      'groupId': groupId,
      'userId': uid,
      'amount': amount,
      'timestamp': FieldValue.serverTimestamp(),
    });
  }

  // Record a payout for a user
  Future<void> recordPayout({
    required String groupId,
    required String userId,
    required double amount,
  }) async {
    await _db.collection('payouts').add({
      'groupId': groupId,
      'userId': userId,
      'amount': amount,
      'payoutDate': FieldValue.serverTimestamp(),
    });
  }
}