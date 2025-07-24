import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:uuid/uuid.dart';

class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final Uuid _uuid = Uuid();

  // === USER METHODS ===

  Future<void> createOrUpdateUser({
    required String uid,
    required String email,
    required String name,
    String? phone,
    String? photoUrl,
  }) async {
    final userRef = _db.collection('users').doc(uid);

    await userRef.set({
      'uid': uid,
      'email': email,
      'name': name,
      if (phone != null) 'phone': phone,
      if (photoUrl != null) 'photoUrl': photoUrl,
      'joinedGroups': FieldValue.arrayUnion([]),
      'createdAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Future<DocumentSnapshot<Map<String, dynamic>>?> getCurrentUserDoc() async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return null;
    final doc = await _db.collection('users').doc(uid).get();
    return doc.exists ? doc : null;
  }

  Future<Map<String, dynamic>?> getUserById(String userId) async {
    final doc = await _db.collection('users').doc(userId).get();
    return doc.exists ? doc.data() : null;
  }

  Future<void> updateUserProfile({
    required String name,
    required String phone,
    String? photoUrl,
  }) async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return;

    await _db.collection('users').doc(uid).update({
      'name': name,
      'phone': phone,
      if (photoUrl != null) 'photoUrl': photoUrl,
    });
  }

  // === GROUP METHODS ===

  Future<String?> createGroup({
    required String groupName,
    required String description,
    required double amount,
    required int frequencyDays,
    String? groupImageUrl,
  }) async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return null;

    final groupRef = _db.collection('groups').doc();

    await groupRef.set({
      'groupId': groupRef.id,
      'createdBy': uid,
      'groupName': groupName,
      'description': description,
      'amount': amount,
      'frequencyDays': frequencyDays,
      'groupImageUrl': groupImageUrl,
      'createdAt': FieldValue.serverTimestamp(),
      'members': [uid],
      'admins': [uid],
      'public': true,
    });

    await _db.collection('users').doc(uid).update({
      'joinedGroups': FieldValue.arrayUnion([groupRef.id]),
    });

    return groupRef.id;
  }

  Future<void> sendJoinRequest(String groupId) async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return;

    final requestRef = _db.collection('groups').doc(groupId).collection('joinRequests').doc(uid);

    await requestRef.set({
      'userId': uid,
      'requestedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> approveJoinRequest(String groupId, String userId) async {
    final groupRef = _db.collection('groups').doc(groupId);

    await groupRef.update({
      'members': FieldValue.arrayUnion([userId]),
    });

    await _db.collection('users').doc(userId).update({
      'joinedGroups': FieldValue.arrayUnion([groupId]),
    });

    await groupRef.collection('joinRequests').doc(userId).delete();
  }

  Future<void> rejectJoinRequest(String groupId, String userId) async {
    await _db.collection('groups').doc(groupId).collection('joinRequests').doc(userId).delete();
  }

  Future<void> removeMemberFromGroup(String groupId, String userId) async {
    await _db.collection('groups').doc(groupId).update({
      'members': FieldValue.arrayRemove([userId]),
      'admins': FieldValue.arrayRemove([userId]),
    });

    await _db.collection('users').doc(userId).update({
      'joinedGroups': FieldValue.arrayRemove([groupId]),
    });
  }

  Future<void> makeUserAdmin(String groupId, String userId) async {
    await _db.collection('groups').doc(groupId).update({
      'admins': FieldValue.arrayUnion([userId]),
    });
  }

  Future<void> removeUserAdmin(String groupId, String userId) async {
    await _db.collection('groups').doc(groupId).update({
      'admins': FieldValue.arrayRemove([userId]),
    });
  }

  Future<List<Map<String, dynamic>>> getJoinRequests(String groupId) async {
    final snapshot = await _db.collection('groups').doc(groupId).collection('joinRequests').get();
    final requests = <Map<String, dynamic>>[];

    for (var doc in snapshot.docs) {
      final userId = doc.data()['userId'];
      final user = await getUserById(userId);
      if (user != null) {
        requests.add(user);
      }
    }

    return requests;
  }

  Future<List<DocumentSnapshot<Map<String, dynamic>>>> getUserGroups(List<String> groupIds) async {
    if (groupIds.isEmpty) return [];
    final snapshot = await _db
        .collection('groups')
        .where(FieldPath.documentId, whereIn: groupIds)
        .get();
    return snapshot.docs;
  }

  Future<List<DocumentSnapshot<Map<String, dynamic>>>> getPublicGroups() async {
    final snapshot = await _db.collection('groups').where('public', isEqualTo: true).get();
    return snapshot.docs;
  }

  Future<DocumentSnapshot<Map<String, dynamic>>> getGroupById(String groupId) async {
    return await _db.collection('groups').doc(groupId).get();
  }

  Future<List<Map<String, dynamic>>> getGroupMembers(String groupId) async {
    final groupDoc = await getGroupById(groupId);
    final memberIds = List<String>.from(groupDoc.data()?['members'] ?? []);

    if (memberIds.isEmpty) return [];

    final snapshot = await _db
        .collection('users')
        .where(FieldPath.documentId, whereIn: memberIds)
        .get();

    return snapshot.docs.map((doc) => doc.data()).toList();
  }

  Future<bool> isUserAdmin(String groupId) async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return false;

    final groupDoc = await _db.collection('groups').doc(groupId).get();
    final admins = List<String>.from(groupDoc.data()?['admins'] ?? []);
    return admins.contains(uid);
  }

  Future<bool> isUserMember(String groupId) async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return false;

    final groupDoc = await _db.collection('groups').doc(groupId).get();
    final members = List<String>.from(groupDoc.data()?['members'] ?? []);
    return members.contains(uid);
  }

  // === CONTRIBUTIONS ===

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

  Future<List<DocumentSnapshot<Map<String, dynamic>>>> getUserContributions(String userId) async {
    final snapshot = await _db
        .collection('contributions')
        .where('userId', isEqualTo: userId)
        .orderBy('timestamp', descending: true)
        .get();
    return snapshot.docs;
  }

  Future<List<DocumentSnapshot<Map<String, dynamic>>>> getGroupContributions(String groupId) async {
    final snapshot = await _db
        .collection('contributions')
        .where('groupId', isEqualTo: groupId)
        .orderBy('timestamp', descending: true)
        .get();
    return snapshot.docs;
  }

  // === PAYOUTS ===

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

  Future<List<DocumentSnapshot<Map<String, dynamic>>>> getUserPayouts(String userId) async {
    final snapshot = await _db
        .collection('payouts')
        .where('userId', isEqualTo: userId)
        .orderBy('payoutDate', descending: true)
        .get();
    return snapshot.docs;
  }

  // === GROUP CHAT ===

  Future<void> sendGroupMessage({
    required String groupId,
    required String message,
  }) async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return;

    final messageId = _uuid.v4();

    await _db.collection('groups').doc(groupId).collection('messages').doc(messageId).set({
      'messageId': messageId,
      'userId': uid,
      'message': message,
      'sentAt': FieldValue.serverTimestamp(),
      'readBy': [uid],
    });
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> getGroupMessages(String groupId) {
    return _db
        .collection('groups')
        .doc(groupId)
        .collection('messages')
        .orderBy('sentAt', descending: true)
        .snapshots();
  }

  Future<void> updateMessage({
    required String groupId,
    required String messageId,
    required Map<String, dynamic> updatedData,
  }) async {
    await _db
        .collection('groups')
        .doc(groupId)
        .collection('messages')
        .doc(messageId)
        .update(updatedData);
  }

  Future<void> markMessageAsRead({
    required String groupId,
    required String messageId,
    required String userId,
  }) async {
    final messageRef = _db
        .collection('groups')
        .doc(groupId)
        .collection('messages')
        .doc(messageId);

    final snapshot = await messageRef.get();
    if (snapshot.exists) {
      List<dynamic> readBy = snapshot.data()?['readBy'] ?? [];
      if (!readBy.contains(userId)) {
        readBy.add(userId);
        await messageRef.update({'readBy': readBy});
      }
    }
  }

  /// ✅ Add reaction to a message
  Future<void> addReaction({
    required String groupId,
    required String messageId,
    required String userId,
    required String emoji,
  }) async {
    final messageRef = _db
        .collection('groups')
        .doc(groupId)
        .collection('messages')
        .doc(messageId);

    await messageRef.update({
      'reactions.$userId': emoji,
    });
  }

  // === HELPERS ===

  String get currentUserId => _auth.currentUser?.uid ?? '';
}