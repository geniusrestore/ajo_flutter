import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import 'group_chat_screen.dart';
import 'group_details_screen.dart';

class MyGroupsScreen extends StatelessWidget {
  const MyGroupsScreen({super.key});

  Stream<QuerySnapshot> _getUserGroups() {
    final uid = FirebaseAuth.instance.currentUser!.uid;
    return FirebaseFirestore.instance
        .collection('groups')
        .where('members', arrayContains: uid)
        .orderBy('createdAt', descending: true)
        .snapshots();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('My Groups')),
      body: StreamBuilder<QuerySnapshot>(
        stream: _getUserGroups(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final groups = snapshot.data?.docs ?? [];

          if (groups.isEmpty) {
            return const Center(child: Text('You are not in any groups yet.'));
          }

          return ListView.builder(
            itemCount: groups.length,
            itemBuilder: (context, index) {
              final group = groups[index];
              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                child: ListTile(
                  title: Text(group['name']),
                  subtitle: Text(
                      '${group['frequency']} • ₦${group['amountPerCycle']} • ${group['groupSize']} members'),
                  trailing: ElevatedButton.icon(
                    icon: const Icon(Icons.chat),
                    label: const Text('Chat'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      minimumSize: const Size(80, 36),
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                    ),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => GroupChatScreen(
                            groupId: group.id,
                            groupName: group['name'],
                          ),
                        ),
                      );
                    },
                  ),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => GroupDetailsScreen(
                          groupId: group.id,
                          isAdmin: false, // You can adjust this based on your logic
                        ),
                      ),
                    );
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }
}