import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../theme/app_theme.dart';

Future<String?> pickAndStorePhoto(BuildContext context) async {
  final palette = context.colors;

  final source = await showModalBottomSheet<ImageSource>(
    context: context,
    backgroundColor: Colors.transparent,
    builder: (sheetContext) => appThemeScope(
      palette,
      SafeArea(
        child: Container(
          decoration: BoxDecoration(
            color: palette.bgSurface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 12),
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: palette.divider,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              const SizedBox(height: 8),
              ListTile(
                leading: Icon(
                  Icons.photo_camera_rounded,
                  color: palette.accentCyan,
                ),
                title: const Text('Take Photo'),
                onTap: () => Navigator.pop(sheetContext, ImageSource.camera),
              ),
              ListTile(
                leading: Icon(
                  Icons.photo_library_rounded,
                  color: palette.accentCyan,
                ),
                title: const Text('Choose from Gallery'),
                onTap: () => Navigator.pop(sheetContext, ImageSource.gallery),
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    ),
  );

  if (source == null) return null;

  try {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: source, imageQuality: 80);
    if (picked == null) return null;

    final docsDir = await getApplicationDocumentsDirectory();
    final proofDir = Directory(p.join(docsDir.path, 'proof_photos'));
    if (!await proofDir.exists()) {
      await proofDir.create(recursive: true);
    }

    final fileName =
        'proof_${DateTime.now().millisecondsSinceEpoch}${p.extension(picked.path)}';
    final savedPath = p.join(proofDir.path, fileName);
    await File(picked.path).copy(savedPath);

    return savedPath;
  } catch (e) {
    debugPrint('pickAndStorePhoto failed: $e');
    if (context.mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Could not get photo: $e')));
    }
    return null;
  }
}

class PhotoUploadField extends StatelessWidget {
  final String? photoPath;
  final VoidCallback onTap;
  final String label;
  final bool hasError;

  const PhotoUploadField({
    super.key,
    required this.photoPath,
    required this.onTap,
    this.label = 'Proof Photo',
    this.hasError = false,
  });

  @override
  Widget build(BuildContext context) {
    final palette = context.colors;
    final hasPhoto = photoPath != null && photoPath!.isNotEmpty;
    final borderColor = hasPhoto
        ? Colors.transparent
        : (hasError ? palette.danger : palette.divider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        GestureDetector(
          onTap: onTap,
          child: Container(
            width: double.infinity,
            height: hasPhoto ? 180 : 110,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: borderColor, width: 1.4),
              color: palette.bgSurfaceAlt,
            ),
            clipBehavior: Clip.antiAlias,
            child: hasPhoto
                ? Stack(
                    fit: StackFit.expand,
                    children: [
                      Image.file(File(photoPath!), fit: BoxFit.cover),
                      Positioned(
                        right: 8,
                        bottom: 8,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.6),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: const Text(
                            'Change Photo',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    ],
                  )
                : Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.add_a_photo_rounded,
                          color: hasError ? palette.danger : palette.accentCyan,
                          size: 26,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Tap to add $label',
                          style: AppText.bodyMuted(
                            context,
                          ).copyWith(color: hasError ? palette.danger : null),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
          ),
        ),
        if (hasError) ...[
          const SizedBox(height: 6),
          Text(
            'This field is required.',
            style: TextStyle(
              color: palette.danger,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ],
    );
  }
}
