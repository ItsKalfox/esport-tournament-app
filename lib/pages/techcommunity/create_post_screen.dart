import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'tech_community.dart';

class CreatePostScreen extends StatefulWidget {
  const CreatePostScreen({super.key});

  @override
  State<CreatePostScreen> createState() => _CreatePostScreenState();
}

class _CreatePostScreenState extends State<CreatePostScreen> {
  final TextEditingController _captionController = TextEditingController();
  final ImagePicker _picker = ImagePicker();
  final FirebaseStorage _storage = FirebaseStorage.instance;

  List<XFile> _selectedImages = [];
  bool _isPosting = false;
  bool _isUploading = false;
  String? _selectedFeeling;
  List<String> _taggedUsers = [];
  bool _showCaption = false;

  final List<String> _feelings = [
    'Happy', 'Excited', 'Grateful', 'Motivated', 'Proud',
    'Inspired', 'Blessed', 'Focused', 'Creative', 'Adventurous',
  ];

  Future<void> _pickImages() async {
    try {
      final List<XFile>? images = await _picker.pickMultiImage();
      if (images != null && images.isNotEmpty) {
        setState(() {
          _selectedImages = [..._selectedImages, ...images].take(4).toList();
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Unable to access gallery: ${e.toString()}')),
        );
      }
    }
  }

  Future<void> _takePhoto() async {
    try {
      final XFile? image = await _picker.pickImage(source: ImageSource.camera);
      if (image != null) {
        setState(() {
          _selectedImages = [..._selectedImages, image].take(4).toList();
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Unable to open camera: ${e.toString()}')),
        );
      }
    }
  }

  void _removeImage(int index) {
    setState(() {
      _selectedImages.removeAt(index);
      if (_selectedImages.isEmpty) {
        _showCaption = false;
        _captionController.clear();
        _selectedFeeling = null;
        _taggedUsers.clear();
      }
    });
  }

  Future<String?> _uploadImage(XFile image) async {
    try {
      final String fileName =
          'posts/${DateTime.now().millisecondsSinceEpoch}_${image.name}';
      final Reference ref = _storage.ref().child(fileName);
      final UploadTask task = ref.putFile(File(image.path));
      final TaskSnapshot snapshot = await task;
      return await snapshot.ref.getDownloadURL();
    } catch (e) {
      return null;
    }
  }

  Future<void> _createPost() async {
    if (_selectedImages.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please add at least one image')),
      );
      return;
    }

    setState(() {
      _isPosting = true;
      _isUploading = true;
    });

    try {
      final List<String> imageUrls = [];

      for (final image in _selectedImages) {
        final url = await _uploadImage(image);
        if (url != null) {
          imageUrls.add(url);
        }
      }

      if (imageUrls.isEmpty) {
        throw Exception('Failed to upload images');
      }

      final user = FirebaseAuth.instance.currentUser;
      final name = user?.displayName ?? 'Anonymous';
      final initials = name.split(' ').take(2).map((e) => e.isNotEmpty ? e[0].toUpperCase() : '').join();
      
      final DocumentReference doc = await FirebaseFirestore.instance
          .collection('posts')
          .add({
            'userId': user?.uid,
            'userName': name,
            'userInitials': initials.isNotEmpty ? initials : 'GX',
            'userAvatar': user?.photoURL ?? '',
            'caption': _captionController.text,
            'feeling': _selectedFeeling ?? '',
            'taggedUsers': _taggedUsers,
            'imageUrls': imageUrls,
            'createdAt': FieldValue.serverTimestamp(),
            'likes': 0,
            'likeCount': 0,
            'likers': [],
          });

      setState(() {
        _isUploading = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Post created successfully!')),
        );
        Navigator.of(context).pop();
        Navigator.of(context).push(
          MaterialPageRoute(builder: (context) => const TechCommunityScreen()),
        );
      }
    } catch (e) {
      setState(() {
        _isPosting = false;
        _isUploading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: ${e.toString()}')));
      }
    }
  }

  @override
  void dispose() {
    _captionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final accent = const Color(0xFFFF8A00);
    final bg = const Color(0xFF121212);
    final cardBg = const Color(0xFF1A1A1A);
    final user = FirebaseAuth.instance.currentUser;
    final name = user?.displayName ?? '';
    final initials = name.split(' ').take(2).map((e) => e.isNotEmpty ? e[0].toUpperCase() : '').join();

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        backgroundColor: bg,
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text(
          'Create Post',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w600,
            fontSize: 18,
          ),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: TextButton(
              onPressed: _isPosting ? null : _createPost,
              child: _isUploading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : Text(
                      'Share',
                      style: TextStyle(
                        color: accent,
                        fontWeight: FontWeight.w600,
                        fontSize: 16,
                      ),
                    ),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          const Color(0xFFC8860A),
                          const Color(0xFFF0A500),
                        ],
                      ),
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Text(
                        initials.isNotEmpty ? initials : 'GX',
                        style: const TextStyle(
                          color: Colors.black,
                          fontWeight: FontWeight.w900,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    _selectedFeeling != null ? 'Feeling $_selectedFeeling' : 'Your story',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            if (_selectedImages.isEmpty)
              _buildMediaPicker(accent)
            else
              _buildSelectedImages(),
            if (_selectedImages.isNotEmpty && !_showCaption)
              Padding(
                padding: const EdgeInsets.all(16),
                child: GestureDetector(
                  onTap: () => setState(() => _showCaption = true),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                    decoration: BoxDecoration(
                      color: cardBg,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.edit, color: Colors.grey[500], size: 20),
                        const SizedBox(width: 12),
                        Text(
                          'Write a caption...',
                          style: TextStyle(color: Colors.grey[500], fontSize: 14),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            if (_selectedImages.isNotEmpty && _showCaption)
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextField(
                      controller: _captionController,
                      maxLines: 4,
                      style: const TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        hintText: 'Write a caption...',
                        hintStyle: TextStyle(color: Colors.grey[500]),
                        border: InputBorder.none,
                      ),
                    ),
                    const Divider(color: Colors.grey),
                    const SizedBox(height: 8),
                    _buildOptionRow(
                      Icons.emoji_emotions_outlined,
                      _selectedFeeling != null ? _selectedFeeling! : 'Feeling/Activity',
                      accent,
                      _showFeelingPicker,
                    ),
                    _buildOptionRow(
                      Icons.location_on_outlined,
                      'Add location',
                      accent,
                      null,
                    ),
                    _buildOptionRow(
                      Icons.person_add_outlined,
                      _taggedUsers.isNotEmpty ? '${_taggedUsers.length} tagged' : 'Tag people',
                      accent,
                      _showTagPeople,
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  void _showFeelingPicker() {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1A1A1A),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'How are you feeling?',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _feelings.map((feeling) {
                final isSelected = _selectedFeeling == feeling;
                return GestureDetector(
                  onTap: () {
                    setState(() => _selectedFeeling = feeling);
                    Navigator.pop(context);
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    decoration: BoxDecoration(
                      color: isSelected ? const Color(0xFFFF8A00) : const Color(0xFF2A2A2A),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: isSelected ? const Color(0xFFFF8A00) : Colors.grey[700]!,
                      ),
                    ),
                    child: Text(
                      feeling,
                      style: TextStyle(
                        color: isSelected ? Colors.black : Colors.white,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }

  void _showTagPeople() {
    final controller = TextEditingController();
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1A1A1A),
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
          left: 16,
          right: 16,
          top: 16,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Tag people',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: controller,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: 'Enter username',
                hintStyle: TextStyle(color: Colors.grey[500]),
                filled: true,
                fillColor: const Color(0xFF2A2A2A),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide.none,
                ),
              ),
              onSubmitted: (value) {
                if (value.isNotEmpty && !_taggedUsers.contains(value)) {
                  setState(() => _taggedUsers.add(value));
                  controller.clear();
                }
              },
            ),
            const SizedBox(height: 12),
            if (_taggedUsers.isNotEmpty) ...[
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _taggedUsers.map((user) {
                  return Chip(
                    label: Text(
                      '@$user',
                      style: const TextStyle(color: Colors.white, fontSize: 12),
                    ),
                    backgroundColor: const Color(0xFF2A2A2A),
                    deleteIcon: const Icon(Icons.close, size: 16, color: Colors.white),
                    onDeleted: () {
                      setState(() => _taggedUsers.remove(user));
                    },
                  );
                }).toList(),
              ),
              const SizedBox(height: 12),
            ],
            ElevatedButton(
              onPressed: () {
                if (controller.text.isNotEmpty && !_taggedUsers.contains(controller.text)) {
                  setState(() => _taggedUsers.add(controller.text));
                }
                Navigator.pop(context);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFF8A00),
                minimumSize: const Size(double.infinity, 44),
              ),
              child: const Text('Done', style: TextStyle(color: Colors.black)),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildMediaPicker(Color accent) {
    return Container(
      height: 300,
      width: double.infinity,
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1A),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: accent.withOpacity(0.5), width: 1),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.add_photo_alternate_outlined,
            size: 64,
            color: accent.withOpacity(0.7),
          ),
          const SizedBox(height: 16),
          const Text(
            'Add Media',
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Photos or videos',
            style: TextStyle(color: Colors.grey[500], fontSize: 14),
          ),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _actionButton(
                Icons.photo_library_outlined,
                'Gallery',
                accent,
                _pickImages,
              ),
              const SizedBox(width: 16),
              _actionButton(
                Icons.camera_alt_outlined,
                'Camera',
                accent,
                _takePhoto,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _actionButton(
    IconData icon,
    String label,
    Color accent,
    VoidCallback onTap,
  ) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        decoration: BoxDecoration(
          color: accent.withOpacity(0.2),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: accent),
        ),
        child: Row(
          children: [
            Icon(icon, color: accent, size: 20),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(color: accent, fontWeight: FontWeight.w500),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSelectedImages() {
    final accent = const Color(0xFFFF8A00);

    return Column(
      children: [
        SizedBox(
          height: 200,
          child: _selectedImages.length == 1
              ? _buildImagePreview(_selectedImages[0], 0)
              : GridView.builder(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 1,
                    mainAxisSpacing: 8,
                  ),
                  itemCount: _selectedImages.length,
                  itemBuilder: (context, index) =>
                      _buildImagePreview(_selectedImages[index], index),
                ),
        ),
        Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              _actionButton(
                Icons.add_photo_alternate_outlined,
                'Add More',
                accent,
                _pickImages,
              ),
              const SizedBox(width: 12),
              _actionButton(
                Icons.camera_alt_outlined,
                'Camera',
                accent,
                _takePhoto,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildImagePreview(XFile image, int index) {
    return Stack(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Image.file(
            File(image.path),
            width: double.infinity,
            height: double.infinity,
            fit: BoxFit.cover,
          ),
        ),
        Positioned(
          top: 8,
          right: 8,
          child: GestureDetector(
            onTap: () => _removeImage(index),
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: const BoxDecoration(
                color: Colors.black54,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.close, color: Colors.white, size: 18),
            ),
          ),
        ),
        if (index == 0)
          Positioned(
            bottom: 8,
            left: 8,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.black54,
                borderRadius: BorderRadius.circular(4),
              ),
              child: const Text(
                'Cover',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildOptionRow(IconData icon, String label, Color accent, VoidCallback? onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Row(
          children: [
            Icon(icon, color: Colors.white70, size: 22),
            const SizedBox(width: 16),
            Text(
              label,
              style: const TextStyle(color: Colors.white70, fontSize: 14),
            ),
            const Spacer(),
            const Icon(Icons.chevron_right, color: Colors.white38),
          ],
        ),
      ),
    );
  }
}
