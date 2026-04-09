import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:firebase_storage/firebase_storage.dart';

/// Limits and crop configuration
const int kMaxPosterSizeBytes = 5 * 1024 * 1024; // 5 MB
const int kMaxLogoSizeBytes = 2 * 1024 * 1024;   // 2 MB

class ImageUploadService {
  static final _picker = ImagePicker();
  static final _storage = FirebaseStorage.instance;

  // ── Pick + Crop image ─────────────────────────────────────────────────────

  /// Picks an image from gallery/camera, crops it, and returns the [File].
  /// [cropStyle]: CropStyle.rectangle for poster, CropStyle.circle for logo
  /// [aspectRatio]: null = free, CropAspectRatio(16,9) for poster, 1:1 for logo
  /// [maxBytes]: size limit checked BEFORE Upload — shows error and returns null if exceeded
  static Future<File?> pickAndCrop({
    required BuildContext context,
    required ImageSource source,
    CropStyle cropStyle = CropStyle.rectangle,
    CropAspectRatio? aspectRatio,
    int maxBytes = kMaxLogoSizeBytes,
    String toolbarTitle = 'Crop Image',
  }) async {
    // Pick
    final XFile? picked = await _picker.pickImage(
      source: source,
      imageQuality: 90,
      maxWidth: 1920,
    );
    if (picked == null) return null;

    // Check size before cropping
    final rawBytes = await picked.length();
    if (rawBytes > maxBytes) {
      if (context.mounted) {
        _showSizeError(
          context,
          maxBytes,
          rawBytes,
        );
      }
      return null;
    }

    // Crop
    final cropped = await ImageCropper().cropImage(
      sourcePath: picked.path,
      aspectRatio: aspectRatio,
      compressFormat: ImageCompressFormat.jpg,
      compressQuality: 85,
      uiSettings: [
        AndroidUiSettings(
          toolbarTitle: toolbarTitle,
          toolbarColor: const Color(0xFF111111),
          toolbarWidgetColor: const Color(0xFFF0A500),
          backgroundColor: const Color(0xFF0D0D0D),
          activeControlsWidgetColor: const Color(0xFFF0A500),
          cropGridColor: const Color(0xFF333333),
          cropFrameColor: const Color(0xFFF0A500),
          statusBarLight: false,
          lockAspectRatio: aspectRatio != null,
          hideBottomControls: false,
          cropStyle: cropStyle,
          initAspectRatio: aspectRatio != null
              ? CropAspectRatioPreset.ratio16x9
              : CropAspectRatioPreset.original,
        ),
        IOSUiSettings(
          title: toolbarTitle,
          doneButtonTitle: 'Done',
          cancelButtonTitle: 'Cancel',
          cropStyle: cropStyle,
          aspectRatioLockEnabled: aspectRatio != null,
          resetAspectRatioEnabled: aspectRatio == null,
        ),
      ],
    );
    if (cropped == null) return null;

    // Recheck size after crop+compress
    final croppedFile = File(cropped.path);
    final croppedBytes = await croppedFile.length();
    if (croppedBytes > maxBytes) {
      if (context.mounted) {
        _showSizeError(context, maxBytes, croppedBytes);
      }
      return null;
    }

    return croppedFile;
  }

  // ── Upload to Firebase Storage ────────────────────────────────────────────

  /// Uploads [file] to [storagePath] and returns the download URL.
  static Future<String> uploadImage({
    required File file,
    required String storagePath,
    void Function(double progress)? onProgress,
  }) async {
    final ref = _storage.ref().child(storagePath);
    final task = ref.putFile(
      file,
      SettableMetadata(contentType: 'image/jpeg'),
    );

    if (onProgress != null) {
      task.snapshotEvents.listen((snapshot) {
        final progress =
            snapshot.bytesTransferred / snapshot.totalBytes;
        onProgress(progress);
      });
    }

    await task;
    return await ref.getDownloadURL();
  }

  // ── Show Picker Bottom Sheet ──────────────────────────────────────────────

  /// Shows a bottom sheet asking gallery or camera, returns picked+cropped File.
  static Future<File?> showPickerSheet({
    required BuildContext context,
    CropStyle cropStyle = CropStyle.rectangle,
    CropAspectRatio? aspectRatio,
    int maxBytes = kMaxLogoSizeBytes,
    String toolbarTitle = 'Crop Image',
  }) async {
    ImageSource? source;
    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: const Color(0xFF1A1A1A),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 36,
                height: 4,
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                  color: const Color(0xFF444444),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              ListTile(
                leading: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: const Color(0xFF2A1800),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.photo_library_outlined,
                      color: Color(0xFFF0A500), size: 20),
                ),
                title: const Text('Choose from Gallery',
                    style: TextStyle(color: Colors.white, fontSize: 14)),
                subtitle: const Text('Select a photo from your library',
                    style: TextStyle(color: Color(0xFF555555), fontSize: 11)),
                onTap: () {
                  source = ImageSource.gallery;
                  Navigator.pop(ctx);
                },
              ),
              ListTile(
                leading: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: const Color(0xFF1A1A2A),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.camera_alt_outlined,
                      color: Color(0xFF7777FF), size: 20),
                ),
                title: const Text('Take a Photo',
                    style: TextStyle(color: Colors.white, fontSize: 14)),
                subtitle: const Text('Open camera to take a new photo',
                    style: TextStyle(color: Color(0xFF555555), fontSize: 11)),
                onTap: () {
                  source = ImageSource.camera;
                  Navigator.pop(ctx);
                },
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );

    if (source == null) return null;
    return pickAndCrop(
      context: context,
      source: source!,
      cropStyle: cropStyle,
      aspectRatio: aspectRatio,
      maxBytes: maxBytes,
      toolbarTitle: toolbarTitle,
    );
  }

  // ── Helpers ───────────────────────────────────────────────────────────────

  static void _showSizeError(
      BuildContext context, int maxBytes, int actualBytes) {
    final maxMb = (maxBytes / (1024 * 1024)).toStringAsFixed(0);
    final actualMb = (actualBytes / (1024 * 1024)).toStringAsFixed(1);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
            'Image too large ($actualMb MB). Max allowed is $maxMb MB.'),
        backgroundColor: const Color(0xFF8C0000),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  /// Returns a human-readable file size string.
  static String formatBytes(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }
}
