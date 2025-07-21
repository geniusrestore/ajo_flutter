import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

class CreateGroupScreen extends StatefulWidget {
  const CreateGroupScreen({super.key});

  @override
  State<CreateGroupScreen> createState() => _CreateGroupScreenState();
}

class _CreateGroupScreenState extends State<CreateGroupScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _groupNameController = TextEditingController();
  final TextEditingController _groupDescriptionController = TextEditingController();
  File? _groupImage;
  bool _isLoading = false;

  Future<void> _pickGroupImage() async {
    final picked = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (picked != null) {
      setState(() {
        _groupImage = File(picked.path);
      });
    }
  }

  Future<String?> _uploadGroupImage(String groupId) async {
    if (_groupImage == null) return null;

    final storageRef = FirebaseStorage.instance.ref().child('group_images/$groupId.jpg');
    await storageRef.putFile(_groupImage!);
    return await storageRef.getDownloadURL();
  }

  Future<void> _createGroup() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final user = FirebaseAuth.instance.currentUser;
      final groupRef = FirebaseFirestore.instance.collection('groups').doc();

      final imageUrl = await _uploadGroupImage(groupRef.id);

      await groupRef.set({
        'id': groupRef.id,
        'name': _groupNameController.text.trim(),
        'description': _groupDescriptionController.text.trim(),
        'imageUrl': imageUrl ?? '',
        'createdBy': user?.uid,
        'createdAt': Timestamp.now(),
        'members': [user?.uid],
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Group created successfully')),
      );

      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error creating group: $e')),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Create Group'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : Form(
                key: _formKey,
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      GestureDetector(
                        onTap: _pickGroupImage,
                        child: CircleAvatar(
                          radius: 50,
                          backgroundImage:
                              _groupImage != null ? FileImage(_groupImage!) : null,
                          child: _groupImage == null
                              ? const Icon(Icons.add_a_photo, size: 40)
                              : null,
                        ),
                      ),
                      const SizedBox(height: 20),
                      TextFormField(
                        controller: _groupNameController,
                        decoration: const InputDecoration(
                          labelText: 'Group Name',
                          border: OutlineInputBorder(),
                        ),
                        validator: (value) =>
                            value == null || value.isEmpty ? 'Enter group name' : null,
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _groupDescriptionController,
                        maxLines: 3,
                        decoration: const InputDecoration(
                          labelText: 'Group Description',
                          border: OutlineInputBorder(),
                        ),
                        validator: (value) =>
                            value == null || value.isEmpty ? 'Enter description' : null,
                      ),
                      const SizedBox(height: 24),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: _createGroup,
                          icon: const Icon(Icons.group_add),
                          label: const Text('Create Group'),
                        ),
                      )
                    ],
                  ),
                ),
              ),
      ),
    );
  }
}