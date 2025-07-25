import 'package:flutter/material.dart';
import '../../services/firestore_service.dart';
import '../groups/group_details_screen.dart';
import 'top_up_wallet_screen.dart';

class WalletDashboardScreen extends StatefulWidget {
  final String userId;

  const WalletDashboardScreen({super.key, required this.userId});

  @override
  State<WalletDashboardScreen> createState() => _WalletDashboardScreenState();
}

class _WalletDashboardScreenState extends State<WalletDashboardScreen> {
  final FirestoreService _firestoreService = FirestoreService();

  double _walletBalance = 0.0;
  List<Map<String, dynamic>> _userGroups = [];

  @override
  void initState() {
    super.initState();
    _loadWalletAndGroups();
  }

  Future<void> _loadWalletAndGroups() async {
    try {
      final balance = final balance = await _firestoreService.getUserWalletBalance(widget.userId);

      // ✅ FIXED: Cast the result to List<Map<String, dynamic>> to avoid type error
      final groups = List<Map<String, dynamic>>.from(
        await _firestoreService.getUserGroups(widget.userId),
      );

      setState(() {
        _walletBalance = balance;
        _userGroups = groups;
      });
    } catch (e) {
      print("Error loading wallet and groups: $e");
      // Optionally show a snackbar or dialog
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Wallet Dashboard"),
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
      ),
      body: RefreshIndicator(
        onRefresh: _loadWalletAndGroups,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Card(
              elevation: 4,
              child: ListTile(
                leading: const Icon(Icons.account_balance_wallet, color: Colors.green),
                title: const Text("Wallet Balance"),
                subtitle: Text("₦${_walletBalance.toStringAsFixed(2)}"),
              ),
            ),
            const SizedBox(height: 20),
            const Text("Your Groups", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            _userGroups.isEmpty
                ? const Text("You are not in any group.")
                : Column(
                    children: _userGroups.map((group) {
                      return Card(
                        child: ListTile(
                          leading: const Icon(Icons.group),
                          title: Text(group['name'] ?? 'Unnamed'),
                          subtitle: Text("Abbreviation: ${group['abbreviation'] ?? ''}"),
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => GroupDetailsScreen(
                                  groupId: group['groupId'],
                                  groupName: group['name'],
                                  isAdmin: group['isAdmin'] ?? false,
                                ),
                              ),
                            );
                          },
                        ),
                      );
                    }).toList(),
                  ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => TopUpWalletScreen(userId: widget.userId),
            ),
          );
          _loadWalletAndGroups(); // Refresh after top-up
        },
        backgroundColor: Colors.green,
        icon: const Icon(Icons.add),
        label: const Text("Top Up"),
      ),
    );
  }
} 