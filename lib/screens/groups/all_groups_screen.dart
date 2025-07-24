import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../groups/group_details_screen.dart';

class AllGroupsScreen extends StatefulWidget {
  const AllGroupsScreen({Key? key}) : super(key: key);

  @override
  State<AllGroupsScreen> createState() => _AllGroupsScreenState();
}

class _AllGroupsScreenState extends State<AllGroupsScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  String _searchQuery = '';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('All Groups'),
        backgroundColor: Colors.green,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: TextField(
              decoration: const InputDecoration(
                hintText: 'Search groups...',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(),
              ),
              onChanged: (val) {
                setState(() {
                  _searchQuery = val.toLowerCase();
                });
              },
            ),
          ),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: _firestore
                  .collection('groups')
                  .orderBy('name') // ✅ Alphabetical order
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return const Center(child: Text('Error loading groups'));
                }
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                final allGroups = snapshot.data!.docs;

                // ✅ Search by name only (case-insensitive)
                final groups = allGroups.where((doc) {
                  final groupName = doc['name'].toString().toLowerCase();
                  return groupName.contains(_searchQuery);
                }).toList();

                if (groups.isEmpty) {
                  return const Center(child: Text('No groups found.'));
                }

                return ListView.builder(
                  itemCount: groups.length,
                  itemBuilder: (context, index) {
                    final group = groups[index];
                    final groupId = group.id;
                    final groupName = group['name'];
                    final adminId = group['adminId'];
                    final currentUserId = _auth.currentUser?.uid;
                    final isAdmin = currentUserId == adminId;

                    return ListTile(
                      leading: const Icon(Icons.group),
                      title: Text(groupName),
                      subtitle: Text('Created by: $adminId'),
                      trailing: const Icon(Icons.arrow_forward_ios),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => GroupDetailsScreen(
                              groupId: groupId,
                              isAdmin: isAdmin,
                              groupName: groupName,
                            ),
                          ),
                        );
                      },
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}