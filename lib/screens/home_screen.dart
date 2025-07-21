import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../services/firestore_service.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final FirestoreService _firestoreService = FirestoreService();
  String userName = "";
  List<Map<String, dynamic>> groups = [];

  @override
  void initState() {
    super.initState();
    loadUserData();
  }

  Future<void> loadUserData() async {
    final userDoc = await _firestoreService.getCurrentUserDoc();
    if (userDoc != null) {
      final data = userDoc.data() as Map<String, dynamic>;
      final name = data['name'] ?? 'User';
      final List<dynamic> groupIds = data['joinedGroups'] ?? [];

      final groupDocs = await _firestoreService.getUserGroups(
        groupIds.map((id) => id.toString()).toList(),
      );

      setState(() {
        userName = name;
        groups = groupDocs.map((doc) => doc.data() as Map<String, dynamic>).toList();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F9F8),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 1,
        centerTitle: false,
        title: const Text(
          'Ajo',
          style: TextStyle(
            color: Colors.green,
            fontWeight: FontWeight.bold,
            fontSize: 22,
          ),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: ListView(
          children: [
            Text(
              'Hi, $userName 👋',
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 20),
            _buildAjoSummaryCard(),
            const SizedBox(height: 24),
            const Text(
              'Your Ajo Groups',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 12),
            _buildGroupCarousel(),
            const SizedBox(height: 32),
            _buildCreateJoinButtons(),
          ],
        ),
      ),
    );
  }

  Widget _buildAjoSummaryCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.green.shade100,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: const [
          Text(
            "Your Ajo Summary",
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 18,
            ),
          ),
          SizedBox(height: 8),
          Text("Groups joined: 3"),
          Text("Total saved: ₦60,000"),
          Text("Upcoming payout: ₦20,000 on Jul 30"),
        ],
      ),
    );
  }

  Widget _buildGroupCarousel() {
    if (groups.isEmpty) {
      return const Text("You haven’t joined any Ajo group yet.");
    }

    return SizedBox(
      height: 120,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: groups.length,
        itemBuilder: (context, index) {
          final group = groups[index];
          return Container(
            width: 180,
            margin: const EdgeInsets.only(right: 12),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border.all(color: Colors.green.shade100),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  group["name"] ?? "Unnamed Group",
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 8),
                Text("Amount: ₦${group["amount"] ?? "0"}"),
                Text("Next: ${group["nextPayoutDate"] ?? "N/A"}"),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildCreateJoinButtons() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        ElevatedButton.icon(
          onPressed: () {
            // TODO: Add Create Ajo logic
          },
          icon: const Icon(Icons.add),
          label: const Text("Create Ajo"),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.green,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          ),
        ),
        OutlinedButton.icon(
          onPressed: () {
            // TODO: Add Join Ajo logic
          },
          icon: const Icon(Icons.group),
          label: const Text("Join Ajo"),
          style: OutlinedButton.styleFrom(
            foregroundColor: Colors.green,
            side: const BorderSide(color: Colors.green),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          ),
        ),
      ],
    );
  }
}