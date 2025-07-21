import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'profile_screen.dart'; // Make sure this import points to your existing editable screen

class ProfileViewScreen extends StatefulWidget {
  const ProfileViewScreen({super.key});

  @override
  State<ProfileViewScreen> createState() => _ProfileViewScreenState();
}

class _ProfileViewScreenState extends State<ProfileViewScreen> {
  final user = FirebaseAuth.instance.currentUser!;
  Map<String, dynamic>? userData;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchUserData();
  }

  Future<void> _fetchUserData() async {
    final doc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
    if (doc.exists) {
      setState(() {
        userData = doc.data();
        isLoading = false;
      });
    }
  }

  Widget _buildProfileField(String label, String? value) {
    return value == null || value.isEmpty
        ? const SizedBox.shrink()
        : Padding(
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "$label: ",
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                Expanded(child: Text(value)),
              ],
            ),
          );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Profile'),
        backgroundColor: Colors.green[700],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : userData == null
              ? const Center(child: Text("No profile data found."))
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    children: [
                      CircleAvatar(
                        radius: 60,
                        backgroundImage: userData!['photoUrl'] != null
                            ? NetworkImage(userData!['photoUrl'])
                            : const AssetImage('assets/avatar.png') as ImageProvider,
                      ),
                      const SizedBox(height: 24),
                      _buildProfileField("Full Name", userData!['fullName']),
                      _buildProfileField("City", userData!['city']),
                      _buildProfileField("State", userData!['state']),
                      _buildProfileField("Age", userData!['age']),
                      _buildProfileField("Job", userData!['job']),
                      _buildProfileField("Phone", userData!['phone']),
                      const SizedBox(height: 24),
                      ElevatedButton.icon(
                        icon: const Icon(Icons.edit),
                        label: const Text("Edit Profile"),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                              vertical: 14, horizontal: 32),
                        ),
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const ProfileScreen(),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
    );
  }
}