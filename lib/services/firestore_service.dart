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
      'walletBalance': 0.0,
      'totalContributed': 0.0,
      'totalReceived': 0.0,
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
// === AUTH ===

Future<void> sendPasswordResetEmail(String email) async {
  try {
    await _auth.sendPasswordResetEmail(email: email);
  } catch (e) {
    throw Exception('Failed to send password reset email: $e');
  }
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
    'contributionAmount': amount,
    'adminFeePercent': 5,
    'groupWalletBalance': 0.0,
    'groupImageUrl': groupImageUrl,
    'createdAt': FieldValue.serverTimestamp(),
    'members': [uid], // legacy support
    'admins': [uid],  // legacy support
    'public': true,
    'payoutOrder': [uid],
    'currentRound': 1,
    'nextPayoutUserId': uid,
  });

  // ✅ Add admin user to group's members subcollection
  await groupRef.collection('members').doc(uid).set({
    'userId': uid,
    'isAdmin': true,
    'joinedAt': FieldValue.serverTimestamp(),
  });

  // ✅ Add group to user's joinedGroups
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
      'payoutOrder': FieldValue.arrayUnion([userId]),
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
      'payoutOrder': FieldValue.arrayRemove([userId]),
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

Future<List<Map<String, dynamic>>> getUserGroups(String userId) async {
  try {
    final snapshot = await FirebaseFirestore.instance
        .collection('groups')
        .where('members', arrayContains: userId)
        .get();

    return snapshot.docs.map((doc) {
      final data = doc.data();
      return {
        'groupId': doc.id,
        'name': data['name'] ?? '',
        'abbreviation': data['abbreviation'] ?? '',
        'isAdmin': (data['admins'] ?? []).contains(userId),
      };
    }).toList();
  } catch (e) {
    print('Error fetching user groups: $e');
    return [];
  }
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
// === GROUP ADMIN SETTINGS METHODS ===

Future<void> updateGroupSettings({
  required String groupId,
  String? groupName,
  String? description,
  double? contributionAmount,
  int? frequencyDays,
  double? adminFeePercent,
}) async {
  final updates = <String, dynamic>{};

  if (groupName != null) updates['groupName'] = groupName;
  if (description != null) updates['description'] = description;
  if (contributionAmount != null) updates['contributionAmount'] = contributionAmount;
  if (frequencyDays != null) updates['frequencyDays'] = frequencyDays;
  if (adminFeePercent != null) updates['adminFeePercent'] = adminFeePercent;

  if (updates.isNotEmpty) {
    await _db.collection('groups').doc(groupId).update(updates);
  }
}

Future<void> pauseAjo(String groupId) async {
  await _db.collection('groups').doc(groupId).update({
    'paused': true,
  });
}

Future<void> resumeAjo(String groupId) async {
  await _db.collection('groups').doc(groupId).update({
    'paused': false,
  });
}
  // === WALLET METHODS ===

  Future<void> topUpWallet(String userId, double amount) async {
  final walletRef = _db.collection('wallets').doc(userId);
  final walletSnap = await walletRef.get();
  final currentBalance = walletSnap.exists ? walletSnap['balance'] ?? 0.0 : 0.0;

  // Update balance
  await walletRef.set({'balance': currentBalance + amount}, SetOptions(merge: true));

  // Log transaction
  await _db.collection('transactions').add({
    'userId': userId,
    'type': 'top_up',
    'amount': amount,
    'timestamp': FieldValue.serverTimestamp(),
  });
}

  Future<void> contributeToGroup(String groupId) async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return;

    final userRef = _db.collection('users').doc(uid);
    final groupRef = _db.collection('groups').doc(groupId);

    await _db.runTransaction((transaction) async {
      final userSnap = await transaction.get(userRef);
      final groupSnap = await transaction.get(groupRef);

      double wallet = (userSnap['walletBalance'] ?? 0).toDouble();
      double amount = (groupSnap['contributionAmount'] ?? 0).toDouble();
      double feePercent = (groupSnap['adminFeePercent'] ?? 5).toDouble();
      double fee = (feePercent / 100) * amount;
      double netAmount = amount - fee;

      if (wallet < amount) throw Exception("Insufficient wallet balance");

      transaction.update(userRef, {
        'walletBalance': wallet - amount,
        'totalContributed': FieldValue.increment(amount),
      });

      transaction.update(groupRef, {
        'groupWalletBalance': FieldValue.increment(netAmount),
      });

      transaction.set(groupRef.collection('contributions').doc(), {
        'userId': uid,
        'amount': amount,
        'feeDeducted': fee,
        'netAmount': netAmount,
        'round': groupSnap['currentRound'],
        'timestamp': FieldValue.serverTimestamp(),
      });

      transaction.set(_db.collection('transactions').doc(), {
        'userId': uid,
        'groupId': groupId,
        'amount': amount,
        'type': 'contribution',
        'timestamp': FieldValue.serverTimestamp(),
      });
    });
  }

  Future<void> disbursePayout(String groupId) async {
    final groupRef = _db.collection('groups').doc(groupId);
    final groupSnap = await groupRef.get();
    final nextUserId = groupSnap['nextPayoutUserId'];
    final groupBalance = (groupSnap['groupWalletBalance'] ?? 0).toDouble();

    if (groupBalance <= 0) throw Exception("No funds to disburse");

    final userRef = _db.collection('users').doc(nextUserId);

    await _db.runTransaction((transaction) async {
      transaction.update(userRef, {
        'walletBalance': FieldValue.increment(groupBalance),
        'totalReceived': FieldValue.increment(groupBalance),
      });

      transaction.update(groupRef, {
        'groupWalletBalance': 0,
        'currentRound': FieldValue.increment(1),
      });

      List<dynamic> order = groupSnap['payoutOrder'];
      int currentIndex = order.indexOf(nextUserId);
      int nextIndex = (currentIndex + 1) % order.length;
      transaction.update(groupRef, {
        'nextPayoutUserId': order[nextIndex],
      });

      transaction.set(_db.collection('transactions').doc(), {
        'userId': nextUserId,
        'groupId': groupId,
        'amount': groupBalance,
        'type': 'payout',
        'timestamp': FieldValue.serverTimestamp(),
      });
    });
  }

  Future<double> getUserWalletBalance(String uid) async {
    final snap = await _db.collection('users').doc(uid).get();
    return (snap.data()?['walletBalance'] ?? 0).toDouble();
  }
Future<List<Map<String, dynamic>>> getUserTransactions(String userId) async {
  final snapshot = await _db
      .collection('transactions')
      .where('userId', isEqualTo: userId)
      .orderBy('timestamp', descending: true)
      .get();

  return snapshot.docs.map((doc) => doc.data()).toList();
}
  Future<double> getGroupWalletBalance(String groupId) async {
    final snap = await _db.collection('groups').doc(groupId).get();
    return (snap.data()?['groupWalletBalance'] ?? 0).toDouble();
  }
Future<void> topUpUserWallet({
  required String userId,
  required double amount,
}) async {
  final walletRef = _db.collection('wallets').doc(userId);

  await _db.runTransaction((transaction) async {
    final snapshot = await transaction.get(walletRef);

    if (!snapshot.exists) {
      // Create new wallet if it doesn't exist
      transaction.set(walletRef, {'balance': amount});
    } else {
      final currentBalance = (snapshot.data()?['balance'] ?? 0.0).toDouble();
      transaction.update(walletRef, {
        'balance': currentBalance + amount,
      });
    }
  });
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

  String get currentUserId => _auth.currentUser?.uid ?? '';
}