import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../../services/firestore_service.dart';

class JoinGroupScreen extends StatefulWidget {
  const JoinGroupScreen({super.key});

  @override
  State<JoinGroupScreen> createState() => _JoinGroupScreenState();
}

class _JoinGroupScreenState extends State<JoinGroupScreen> {
  final FirestoreService _firestoreService = FirestoreService();
  List<DocumentSnapshot> publicGroups = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchPublicGroups();
  }

  Future<void> fetchPublicGroups() async {
    final snapshot = await FirebaseFirestore.instance
        .collection('groups')
        .where('isPublic', isEqualTo: true)
        .get();

    setState(() {
      publicGroups = snapshot.docs;
      isLoading = false;
    });
  }

  Future<void> sendJoinRequest(String groupId) async {
    await _firestoreService.sendJoinRequest(groupId);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Join request sent!')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Join Ajo Group"),
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : publicGroups.isEmpty
              ? const Center(child: Text("No public groups available."))
              : ListView.builder(
                  itemCount: publicGroups.length,
                  itemBuilder: (context, index) {
                    final group = publicGroups[index].data() as Map<String, dynamic>;
                    return Card(
                      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      elevation: 3,
                      child: ListTile(
                        title: Text(group['name'] ?? 'Unnamed Group'),
                        subtitle: Text(group['description'] ?? ''),
                        trailing: ElevatedButton(
                          onPressed: () => sendJoinRequest(publicGroups[index].id),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                            foregroundColor: Colors.white,
                          ),
                          child: const Text("Request"),
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}