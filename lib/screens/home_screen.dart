import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  void _logout() async {
    await FirebaseAuth.instance.signOut();
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Ajo Savings'),
        actions: [
          IconButton(
            onPressed: _logout,
            icon: const Icon(Icons.logout),
            tooltip: "Logout",
          )
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Welcome, ${user?.email ?? "User"} 👋',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 20),

            // 💰 Total Savings Card
            Card(
              color: Colors.green.shade50,
              elevation: 3,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Row(
                  children: const [
                    Icon(Icons.savings, size: 40, color: Colors.green),
                    SizedBox(width: 15),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text("Total Savings",
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            )),
                        SizedBox(height: 5),
                        Text("₦0.00",
                            style: TextStyle(
                              fontSize: 24,
                              color: Colors.green,
                              fontWeight: FontWeight.bold,
                            )),
                      ],
                    )
                  ],
                ),
              ),
            ),

            const SizedBox(height: 30),

            // ➕ Create or Join Group
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton.icon(
                  onPressed: () {
                    // TODO: Navigate to create group
                  },
                  icon: const Icon(Icons.group_add),
                  label: const Text("Create Group"),
                ),
                OutlinedButton.icon(
                  onPressed: () {
                    // TODO: Navigate to join group
                  },
                  icon: const Icon(Icons.login),
                  label: const Text("Join Group"),
                ),
              ],
            ),

            const SizedBox(height: 30),

            const Text(
              "Your Groups",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 10),

            // 🧾 List of Groups (Static for now)
            Expanded(
              child: ListView(
                children: const [
                  ListTile(
                    leading: Icon(Icons.group),
                    title: Text("July Ajo Group"),
                    subtitle: Text("Next contribution: ₦5,000 on July 25"),
                    trailing: Icon(Icons.chevron_right),
                  ),
                  ListTile(
                    leading: Icon(Icons.group),
                    title: Text("Family Fund"),
                    subtitle: Text("Next contribution: ₦10,000 on July 28"),
                    trailing: Icon(Icons.chevron_right),
                  ),
                ],
              ),
            )
          ],
        ),
      ),
    );
  }
}