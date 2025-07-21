import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'group_details_screen.dart'; // Correct relative import

class AllGroupsScreen extends StatelessWidget {
  const AllGroupsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final currentUserId = FirebaseAuth.instance.currentUser?.uid;

    return Scaffold(
      appBar: AppBar(
        title: const Text('All Groups'),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('groups')
            .orderBy('createdAt', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final groupDocs = snapshot.data?.docs ?? [];

          if (groupDocs.isEmpty) {
            return const Center(child: Text('No groups available yet.'));
          }

          return ListView.builder(
            itemCount: groupDocs.length,
            itemBuilder: (context, index) {
              final data = groupDocs[index].data() as Map<String, dynamic>;
              final groupId = groupDocs[index].id;

              return ListTile(
                leading: CircleAvatar(
                  backgroundImage: data['imageUrl'] != null &&
                          data['imageUrl'].toString().isNotEmpty
                      ? NetworkImage(data['imageUrl'])
                      : null,
                  child: data['imageUrl'] == null ||
                          data['imageUrl'].toString().isEmpty
                      ? const Icon(Icons.group)
                      : null,
                ),
                title: Text(data['name'] ?? 'No Name'),
                subtitle: Text(data['description'] ?? ''),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => GroupDetailsScreen(groupId: groupId, isAdmin: false),
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}