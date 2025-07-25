import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:ajo/services/firestore_service.dart'; 
import 'groups/create_group_screen.dart';
import 'groups/join_group_screen.dart';

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
    final userId = userDoc.id;

    // Load all groups user belongs to
    final userGroups = await _firestoreService.getUserGroups(userId);

    setState(() {
      userName = name;
      groups = userGroups;
    });
  }
}

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F8F7),
      appBar: AppBar(
        elevation: 1,
        backgroundColor: Colors.white,
        title: const Text(
          'Ajo',
          style: TextStyle(
            color: Colors.green,
            fontWeight: FontWeight.bold,
            fontSize: 24,
          ),
        ),
        actions: const [],
      ),
      body: RefreshIndicator(
        onRefresh: loadUserData,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
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
              const SizedBox(height: 36),
              _buildCreateJoinButtons(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAjoSummaryCard() {
    // This is static for now. Later you can fetch actual data from Firestore.
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.green.shade100,
        borderRadius: BorderRadius.circular(16),
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
          SizedBox(height: 10),
          Text("Groups joined: 3"),
          Text("Total saved: ₦60,000"),
          Text("Upcoming payout: ₦20,000 on Jul 30"),
        ],
      ),
    );
  }

  Widget _buildGroupCarousel() {
    if (groups.isEmpty) {
      return const Padding(
        padding: EdgeInsets.only(top: 8),
        child: Text(
          "You haven’t joined any Ajo group yet.",
          style: TextStyle(fontSize: 15, color: Colors.black54),
        ),
      );
    }

    return SizedBox(
      height: 140,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: groups.length,
        itemBuilder: (context, index) {
          final group = groups[index];
          return Container(
            width: 190,
            margin: const EdgeInsets.only(right: 14),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border.all(color: Colors.green.shade100),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.green.withOpacity(0.05),
                  blurRadius: 6,
                  offset: const Offset(0, 3),
                ),
              ],
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
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 6),
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
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const CreateGroupScreen()),
            );
          },
          icon: const Icon(Icons.add),
          label: const Text("Create Ajo"),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.green,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        ),
        OutlinedButton.icon(
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const JoinGroupScreen()),
            );
          },
          icon: const Icon(Icons.group),
          label: const Text("Join Ajo"),
          style: OutlinedButton.styleFrom(
            foregroundColor: Colors.green,
            side: const BorderSide(color: Colors.green),
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        ),
      ],
    );
  }
}