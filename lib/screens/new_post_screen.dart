import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:file_picker/file_picker.dart';
import 'package:provider/provider.dart';
import 'package:pawquest/services/forum_service.dart';
import 'package:pawquest/providers/theme_provider.dart';

/// Full-screen compose page for a new post with optional image.
/// Uses a full page (not a dialog) so the system image picker opens in the
/// same context as the avatar picker, avoiding render conflicts.
class NewPostScreen extends StatefulWidget {
  const NewPostScreen({super.key});

  @override
  State<NewPostScreen> createState() => _NewPostScreenState();
}

class _NewPostScreenState extends State<NewPostScreen> {
  final _controller = TextEditingController();
  final _forum = ForumService();

  Uint8List? _picked;
  bool _busy = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.image,
      withData: true,
    );
    if (result == null || result.files.isEmpty) return;
    final bytes = result.files.first.bytes;
    if (bytes == null) return;
    setState(() => _picked = bytes);
  }

  Future<void> _submit() async {
    final content = _controller.text.trim();
    final user = FirebaseAuth.instance.currentUser;
    if ((content.isEmpty && _picked == null) || user == null) {
      Navigator.pop(context);
      return;
    }

    setState(() => _busy = true);
    try {
      String? imageUrl;
      if (_picked != null) {
        final ref = FirebaseStorage.instance.ref(
            'post_images/${user.uid}/${DateTime.now().millisecondsSinceEpoch}.jpg');
        await ref.putData(
          _picked!,
          SettableMetadata(contentType: 'image/jpeg'),
        );
        imageUrl = await ref.getDownloadURL();
      }

      final nickname = await _forum.resolveNickname(user.uid);
      await FirebaseFirestore.instance.collection('posts').add({
        'authorId': user.uid,
        'authorName': nickname,
        'content': content,
        'imageUrl': imageUrl,
        'likes': 0,
        'likedBy': <String>[],
        'timestamp': FieldValue.serverTimestamp(),
      });
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      setState(() => _busy = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not post: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = context.watch<ThemeProvider>().palette;
    return Scaffold(
      backgroundColor: p.background,
      appBar: AppBar(
        backgroundColor: p.accent,
        foregroundColor: Colors.white,
        elevation: 0,
        title: const Text('New Post',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: TextButton(
              onPressed: _busy ? null : _submit,
              child: _busy
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white),
                    )
                  : const Text('Post',
                      style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 16)),
            ),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(18),
        children: [
          TextField(
            controller: _controller,
            maxLines: 6,
            minLines: 3,
            style: TextStyle(color: p.text, fontSize: 15),
            decoration: InputDecoration(
              hintText: 'Share something...',
              hintStyle: TextStyle(color: p.text.withValues(alpha: 0.4)),
              filled: true,
              fillColor: p.surface,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide.none,
              ),
            ),
          ),
          const SizedBox(height: 16),
          if (_picked != null)
            Stack(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: Image.memory(
                    _picked!,
                    width: double.infinity,
                    height: 220,
                    fit: BoxFit.cover,
                  ),
                ),
                Positioned(
                  top: 8,
                  right: 8,
                  child: GestureDetector(
                    onTap: () => setState(() => _picked = null),
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.55),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.close,
                          size: 18, color: Colors.white),
                    ),
                  ),
                ),
              ],
            )
          else
            OutlinedButton.icon(
              onPressed: _busy ? null : _pickImage,
              icon: Icon(Icons.image_outlined, color: p.primary),
              label: Text('Add image', style: TextStyle(color: p.primary)),
              style: OutlinedButton.styleFrom(
                side: BorderSide(color: p.primary.withValues(alpha: 0.5)),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16)),
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
            ),
        ],
      ),
    );
  }
}
