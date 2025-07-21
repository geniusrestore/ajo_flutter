import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final user = FirebaseAuth.instance.currentUser!;
  final picker = ImagePicker();

  String fullName = '';
  String city = '';
  String state = '';
  String age = '';
  String job = '';
  String phone = '';
  String? photoUrl;
  bool isLoading = false;
  File? _image;

  @override
  void initState() {
    super.initState();
    _loadUserProfile();
  }

  Future<void> _loadUserProfile() async {
    final doc =
        await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
    if (doc.exists) {
      final data = doc.data()!;
      setState(() {
        fullName = data['fullName'] ?? '';
        city = data['city'] ?? '';
        state = data['state'] ?? '';
        age = data['age'] ?? '';
        job = data['job'] ?? '';
        phone = data['phone'] ?? '';
        photoUrl = data['photoUrl'];
      });
    }
  }

  Future<void> _pickImage() async {
    final picked = await picker.pickImage(source: ImageSource.gallery);
    if (picked != null) {
      setState(() {
        _image = File(picked.path);
      });
    }
  }

  Future<String?> _uploadPhoto(File file) async {
    final ref = FirebaseStorage.instance
        .ref()
        .child('profile_photos')
        .child('${user.uid}.jpg');
    await ref.putFile(file);
    return await ref.getDownloadURL();
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;
    _formKey.currentState!.save();

    setState(() => isLoading = true);

    try {
      String? imageUrl = photoUrl;

      if (_image != null) {
        imageUrl = await _uploadPhoto(_image!);
      }

      await FirebaseFirestore.instance.collection('users').doc(user.uid).update({
        'fullName': fullName,
        'city': city,
        'state': state,
        'age': age,
        'job': job,
        'phone': phone,
        'photoUrl': imageUrl,
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Profile updated successfully!"),
          backgroundColor: Colors.green,
        ),
      );

      setState(() {
        photoUrl = imageUrl;
        _image = null;
      });

    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Error: ${e.toString()}"),
          backgroundColor: Colors.red,
        ),
      );
    }

    setState(() => isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Set Up Profile'),
        backgroundColor: Colors.green[700],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    Stack(
                      alignment: Alignment.bottomRight,
                      children: [
                        CircleAvatar(
                          radius: 60,
                          backgroundImage: _image != null
                              ? FileImage(_image!)
                              : (photoUrl != null
                                  ? NetworkImage(photoUrl!)
                                  : const AssetImage('assets/avatar.png'))
                                  as ImageProvider,
                        ),
                        IconButton(
                          icon: const Icon(Icons.edit, color: Colors.green),
                          onPressed: _pickImage,
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    TextFormField(
                      initialValue: fullName,
                      decoration: const InputDecoration(labelText: 'Full Name'),
                      onSaved: (val) => fullName = val!.trim(),
                      validator: (val) =>
                          val == null || val.isEmpty ? 'Required' : null,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      initialValue: city,
                      decoration: const InputDecoration(labelText: 'City'),
                      onSaved: (val) => city = val!.trim(),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      initialValue: state,
                      decoration: const InputDecoration(labelText: 'State'),
                      onSaved: (val) => state = val!.trim(),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      initialValue: age,
                      decoration: const InputDecoration(labelText: 'Age'),
                      keyboardType: TextInputType.number,
                      onSaved: (val) => age = val!.trim(),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      initialValue: job,
                      decoration: const InputDecoration(labelText: 'Job'),
                      onSaved: (val) => job = val!.trim(),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      initialValue: phone,
                      decoration: const InputDecoration(labelText: 'Phone Number'),
                      keyboardType: TextInputType.phone,
                      onSaved: (val) => phone = val!.trim(),
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton.icon(
                      icon: const Icon(Icons.save),
                      label: const Text('Save Profile'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                            vertical: 14, horizontal: 32),
                      ),
                      onPressed: _saveProfile,
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}