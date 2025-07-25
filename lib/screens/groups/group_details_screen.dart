import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../../services/firestore_service.dart';
import 'group_chat_screen.dart';

class GroupDetailsScreen extends StatefulWidget {
  final String groupId;
  final bool isAdmin;
  final String groupName;

  const GroupDetailsScreen({
    super.key,
    required this.groupId,
    required this.isAdmin,
    required this.groupName,
  });

  @override
  State<GroupDetailsScreen> createState() => _GroupDetailsScreenState();
}

class _GroupDetailsScreenState extends State<GroupDetailsScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final FirestoreService _firestoreService = FirestoreService();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: widget.isAdmin ? 3 : 2, vsync: this);
  }

  Future<void> approveRequest(String userId) async {
    await _firestoreService.approveJoinRequest(widget.groupId, userId);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("User approved successfully")),
    );
    setState(() {});
  }

  Future<void> rejectRequest(String userId) async {
    await _firestoreService.rejectJoinRequest(widget.groupId, userId);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("User rejected")),
    );
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.groupName),
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
        bottom: TabBar(
          controller: _tabController,
          tabs: widget.isAdmin
              ? const [
                  Tab(text: 'Members'),
                  Tab(text: 'Requests'),
                  Tab(text: 'Settings'),
                ]
              : const [
                  Tab(text: 'Members'),
                  Tab(text: 'Settings'),
                ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: widget.isAdmin
            ? [
                _buildMembersTab(),
                _buildRequestsTab(),
                _buildSettingsTab(),
              ]
            : [
                _buildMembersTab(),
                _buildSettingsTab(),
              ],
      ),
    );
  }

  Widget _buildMembersTab() {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: _firestoreService.getGroupMembers(widget.groupId),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
        final members = snapshot.data!;
        return ListView.builder(
          itemCount: members.length,
          itemBuilder: (context, index) {
            final member = members[index];
            return ListTile(
              leading: const Icon(Icons.person),
              title: Text(member['name'] ?? 'Unnamed'),
              subtitle: Text(member['email'] ?? ''),
            );
          },
        );
      },
    );
  }

  Widget _buildRequestsTab() {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: _firestoreService.getJoinRequests(widget.groupId),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
        final requests = snapshot.data!;
        return ListView.builder(
          itemCount: requests.length,
          itemBuilder: (context, index) {
            final user = requests[index];
            return Card(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              child: ListTile(
                title: Text(user['name'] ?? 'Pending User'),
                subtitle: Text(user['email'] ?? ''),
                trailing: Wrap(
                  spacing: 8,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.check_circle, color: Colors.green),
                      onPressed: () => approveRequest(user['uid']),
                    ),
                    IconButton(
                      icon: const Icon(Icons.cancel, color: Colors.red),
                      onPressed: () => rejectRequest(user['uid']),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildSettingsTab() {
    return FutureBuilder<DocumentSnapshot>(
      future: FirebaseFirestore.instance.collection('groups').doc(widget.groupId).get(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());

        final groupData = snapshot.data!.data() as Map<String, dynamic>;
        final isPaused = groupData['isPaused'] ?? false;

        return Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              ElevatedButton.icon(
                icon: const Icon(Icons.chat),
                label: const Text('Open Chat'),
                style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => GroupChatScreen(
                        groupId: widget.groupId,
                        groupName: widget.groupName,
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(height: 20),
              ElevatedButton.icon(
                icon: Icon(isPaused ? Icons.play_arrow : Icons.pause),
                label: Text(isPaused ? 'Resume Ajo Rotation' : 'Pause Ajo Rotation'),
                style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
                onPressed: () async {
                  if (isPaused) {
                    await _firestoreService.resumeAjo(widget.groupId);
                  } else {
                    await _firestoreService.pauseAjo(widget.groupId);
                  }
                  setState(() {});
                },
              ),
              const SizedBox(height: 20),
              ElevatedButton.icon(
                icon: const Icon(Icons.settings),
                label: const Text('Update Group Settings'),
                style: ElevatedButton.styleFrom(backgroundColor: Colors.blueGrey),
                onPressed: () {
                  // Future: Navigate to settings update screen
                },
              ),
            ],
          ),
        );
      },
    );
  }
}