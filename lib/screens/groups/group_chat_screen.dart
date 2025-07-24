import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'package:uuid/uuid.dart';

class GroupChatScreen extends StatefulWidget {
  final String groupId;
  final String groupName;

  const GroupChatScreen({
    super.key,
    required this.groupId,
    required this.groupName,
  });

  @override
  State<GroupChatScreen> createState() => _GroupChatScreenState();
}

class _GroupChatScreenState extends State<GroupChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final userId = FirebaseAuth.instance.currentUser!.uid;
  String? userName;
  bool isTyping = false;
  String? editingMessageId;
  Map<String, dynamic>? replyingTo;
  final uuid = Uuid();

  @override
  void initState() {
    super.initState();
    _setTypingListener();
    _fetchUserName();
  }

  Future<void> _fetchUserName() async {
    final doc = await FirebaseFirestore.instance.collection('users').doc(userId).get();
    setState(() {
      userName = doc['name'] ?? doc['fullName'] ?? 'Unknown';
    });
  }

  void _setTypingListener() {
    _messageController.addListener(() {
      final currentlyTyping = _messageController.text.isNotEmpty;
      if (currentlyTyping != isTyping) {
        isTyping = currentlyTyping;
        FirebaseFirestore.instance
            .collection('groups')
            .doc(widget.groupId)
            .update({'typing_$userId': isTyping});
      }
    });
  }

  Future<void> _sendMessage({String? imageUrl}) async {
    final text = _messageController.text.trim();
    if (text.isEmpty && imageUrl == null) return;

    final msgId = uuid.v4();
    final msg = {
      'id': msgId,
      'senderId': userId,
      'senderName': userName ?? 'Unknown',
      'text': imageUrl == null ? text : '',
      'imageUrl': imageUrl ?? '',
      'timestamp': FieldValue.serverTimestamp(),
      'replyTo': replyingTo,
    };

    await FirebaseFirestore.instance
        .collection('groups')
        .doc(widget.groupId)
        .collection('messages')
        .doc(msgId)
        .set(msg);

    setState(() {
      _messageController.clear();
      replyingTo = null;
    });

    _scrollController.animateTo(
      _scrollController.position.maxScrollExtent + 100,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOut,
    );
  }

  Future<void> _pickAndSendImage() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery, imageQuality: 75);
    if (picked == null) return;

    final ref = FirebaseStorage.instance
        .ref('groupChats/${widget.groupId}/${DateTime.now().millisecondsSinceEpoch}');
    await ref.putFile(File(picked.path));
    final url = await ref.getDownloadURL();
    await _sendMessage(imageUrl: url);
  }

  Future<void> _deleteMessage(String messageId) async {
    await FirebaseFirestore.instance
        .collection('groups')
        .doc(widget.groupId)
        .collection('messages')
        .doc(messageId)
        .delete();
  }

  Widget _buildReplyBanner() {
    if (replyingTo == null) return const SizedBox.shrink();
    return Container(
      color: Colors.grey[200],
      padding: const EdgeInsets.all(8),
      child: Row(
        children: [
          const Icon(Icons.reply, size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              replyingTo!['text'] ?? 'Image',
              style: const TextStyle(fontStyle: FontStyle.italic),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close),
            onPressed: () => setState(() => replyingTo = null),
          ),
        ],
      ),
    );
  }

  Widget _buildTypingIndicator(Map<String, dynamic> groupData) {
    final typingUsers = groupData.entries
        .where((e) => e.key.startsWith('typing_') && e.value == true && !e.key.endsWith(userId))
        .map((e) => e.key.replaceFirst('typing_', ''))
        .toList();

    if (typingUsers.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Text(
          '${typingUsers.join(", ")} is typing...',
          style: const TextStyle(color: Colors.grey),
        ),
      ),
    );
  }

  Widget _buildMessageTile(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    final isMe = data['senderId'] == userId;

    return GestureDetector(
      onLongPress: () {
        final List<Widget> options = [];
        if (isMe) {
          options.add(ListTile(
            leading: const Icon(Icons.delete, color: Colors.red),
            title: const Text('Delete'),
            onTap: () {
              _deleteMessage(doc.id);
              Navigator.pop(context);
            },
          ));
        }
        options.add(ListTile(
          leading: const Icon(Icons.reply),
          title: const Text('Reply'),
          onTap: () {
            setState(() => replyingTo = {
                  'senderName': data['senderName'],
                  'text': data['text'],
                  'imageUrl': data['imageUrl'],
                });
            Navigator.pop(context);
          },
        ));
        showModalBottomSheet(context: context, builder: (_) => Wrap(children: options));
      },
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
        child: Column(
          crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: [
            if (data['replyTo'] != null)
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  "${data['replyTo']['senderName']}: ${data['replyTo']['text'] ?? 'Image'}",
                  style: const TextStyle(fontSize: 12, fontStyle: FontStyle.italic),
                ),
              ),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: isMe ? Colors.blue[100] : Colors.grey[300],
                borderRadius: BorderRadius.circular(12),
              ),
              child: data['imageUrl'] != ''
                  ? Image.network(data['imageUrl'], height: 150)
                  : Text(data['text']),
            ),
            const SizedBox(height: 4),
            Text(
              data['senderName'] ?? '',
              style: const TextStyle(fontSize: 10, color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    FirebaseFirestore.instance
        .collection('groups')
        .doc(widget.groupId)
        .update({'typing_$userId': false});
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final groupDoc = FirebaseFirestore.instance.collection('groups').doc(widget.groupId);
    final messages = groupDoc.collection('messages').orderBy('timestamp');

    return Scaffold(
      appBar: AppBar(title: Text(widget.groupName)),
      body: Column(
        children: [
          _buildReplyBanner(),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: messages.snapshots(),
              builder: (_, snapshot) {
                if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
                final docs = snapshot.data!.docs;
                return ListView.builder(
                  controller: _scrollController,
                  itemCount: docs.length,
                  itemBuilder: (_, i) => _buildMessageTile(docs[i]),
                );
              },
            ),
          ),
          StreamBuilder<DocumentSnapshot>(
            stream: groupDoc.snapshots(),
            builder: (_, snap) {
              if (!snap.hasData) return const SizedBox.shrink();
              final data = snap.data!.data() as Map<String, dynamic>;
              return _buildTypingIndicator(data);
            },
          ),
          SafeArea(
            child: Row(
              children: [
                IconButton(icon: const Icon(Icons.image), onPressed: _pickAndSendImage),
                Expanded(
                  child: TextField(
                    controller: _messageController,
                    decoration: const InputDecoration(hintText: 'Type a message'),
                  ),
                ),
                IconButton(icon: const Icon(Icons.send), onPressed: _sendMessage),
              ],
            ),
          ),
        ],
      ),
    );
  }
}