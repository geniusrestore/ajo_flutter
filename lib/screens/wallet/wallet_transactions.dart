import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../services/firestore_service.dart';

class WalletTransactionsScreen extends StatefulWidget {
  final String userId;

  const WalletTransactionsScreen({super.key, required this.userId});

  @override
  State<WalletTransactionsScreen> createState() => _WalletTransactionsScreenState();
}

class _WalletTransactionsScreenState extends State<WalletTransactionsScreen> {
  final FirestoreService _firestoreService = FirestoreService();
  List<Map<String, dynamic>> _transactions = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadTransactions();
  }

  Future<void> _loadTransactions() async {
    try {
      final txs = await _firestoreService.getUserTransactions(widget.userId);
      setState(() {
        _transactions = txs;
        _isLoading = false;
      });
    } catch (e) {
      print("Error loading transactions: $e");
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Transaction History'),
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _transactions.isEmpty
              ? const Center(child: Text('No transactions found.'))
              : ListView.builder(
                  padding: const EdgeInsets.all(12),
                  itemCount: _transactions.length,
                  itemBuilder: (context, index) {
                    final tx = _transactions[index];
                    final type = tx['type'] ?? 'Unknown';
                    final amount = tx['amount'] ?? 0.0;
                    final timestamp = tx['timestamp'] as Timestamp?;
                    final groupName = tx['groupName'] ?? '';
                    final date = timestamp != null
                        ? DateFormat.yMMMd().add_jm().format(timestamp.toDate())
                        : 'Unknown date';

                    IconData icon;
                    Color color;
                    if (type == 'topup') {
                      icon = Icons.arrow_downward;
                      color = Colors.green;
                    } else if (type == 'contribution') {
                      icon = Icons.arrow_upward;
                      color = Colors.orange;
                    } else if (type == 'payout') {
                      icon = Icons.attach_money;
                      color = Colors.blue;
                    } else {
                      icon = Icons.sync;
                      color = Colors.grey;
                    }

                    return Card(
                      child: ListTile(
                        leading: Icon(icon, color: color),
                        title: Text(
                          type == 'topup'
                              ? 'Wallet Top-Up'
                              : type == 'contribution'
                                  ? 'Contribution to $groupName'
                                  : type == 'payout'
                                      ? 'Received Payout from $groupName'
                                      : 'Transaction',
                        ),
                        subtitle: Text(date),
                        trailing: Text(
                          '₦${amount.toStringAsFixed(2)}',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: type == 'topup'
                                ? Colors.green
                                : type == 'contribution'
                                    ? Colors.red
                                    : Colors.black,
                          ),
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}