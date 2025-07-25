import 'package:flutter/material.dart';
import '../../services/firestore_service.dart';

class AdminGroupSettingsScreen extends StatefulWidget {
  final String groupId;

  const AdminGroupSettingsScreen({super.key, required this.groupId});

  @override
  State<AdminGroupSettingsScreen> createState() => _AdminGroupSettingsScreenState();
}

class _AdminGroupSettingsScreenState extends State<AdminGroupSettingsScreen> {
  final _formKey = GlobalKey<FormState>();

  String? groupName;
  String? description;
  double? contributionAmount;
  int? frequencyDays;
  double? adminFeePercent;

  bool isLoading = false;
  bool isPaused = false;

  @override
  void initState() {
    super.initState();
    _loadCurrentSettings();
  }

  Future<void> _loadCurrentSettings() async {
    final doc = await FirestoreService().getGroupById(widget.groupId);
    if (doc != null) {
      final data = doc.data() ?? {}; // ✅ Safely fallback to empty map
      setState(() {
        groupName = data['groupName'] ?? '';
        description = data['description'] ?? '';
        contributionAmount = (data['contributionAmount'] ?? 0).toDouble();
        frequencyDays = (data['frequencyDays'] ?? 0).toInt();
        adminFeePercent = (data['adminFeePercent'] ?? 0).toDouble();
        isPaused = data['paused'] == true;
      });
    }
  }

  Future<void> _saveSettings() async {
    if (!_formKey.currentState!.validate()) return;
    _formKey.currentState!.save();
    setState(() => isLoading = true);

    await FirestoreService().updateGroupSettings(
      groupId: widget.groupId,
      groupName: groupName,
      description: description,
      contributionAmount: contributionAmount,
      frequencyDays: frequencyDays,
      adminFeePercent: adminFeePercent,
    );

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Settings updated')),
    );

    setState(() => isLoading = false);
  }

  Future<void> _togglePauseStatus() async {
    setState(() => isLoading = true);
    if (isPaused) {
      await FirestoreService().resumeAjo(widget.groupId);
    } else {
      await FirestoreService().pauseAjo(widget.groupId);
    }
    setState(() {
      isPaused = !isPaused;
      isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Admin Settings')),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    TextFormField(
                      initialValue: groupName,
                      decoration: const InputDecoration(labelText: 'Group Name'),
                      onSaved: (val) => groupName = val,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      initialValue: description,
                      decoration: const InputDecoration(labelText: 'Description'),
                      onSaved: (val) => description = val,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      initialValue: contributionAmount?.toString(),
                      decoration: const InputDecoration(labelText: 'Contribution Amount'),
                      keyboardType: TextInputType.number,
                      onSaved: (val) => contributionAmount = double.tryParse(val ?? '0'),
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      initialValue: frequencyDays?.toString(),
                      decoration: const InputDecoration(labelText: 'Contribution Frequency (days)'),
                      keyboardType: TextInputType.number,
                      onSaved: (val) => frequencyDays = int.tryParse(val ?? '0'),
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      initialValue: adminFeePercent?.toString(),
                      decoration: const InputDecoration(labelText: 'Admin Fee Percent'),
                      keyboardType: TextInputType.number,
                      onSaved: (val) => adminFeePercent = double.tryParse(val ?? '0'),
                    ),
                    const SizedBox(height: 20),
                    ElevatedButton(
                      onPressed: _saveSettings,
                      child: const Text('Save Settings'),
                    ),
                    const SizedBox(height: 12),
                    OutlinedButton(
                      onPressed: _togglePauseStatus,
                      child: Text(isPaused ? 'Resume Ajo' : 'Pause Ajo'),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}