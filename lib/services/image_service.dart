import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:image/image.dart' as img;

import '../widgets/webcam_capture_dialog.dart';

final imageServiceProvider = Provider<ImageService>((ref) {
  return ImageService();
});

class ImageService {
  final _picker = ImagePicker();

  /// Pick from camera. On web over HTTP, camera may be blocked by the browser.
  /// Returns null if the user cancels OR if camera is unavailable.
  /// [onCameraBlocked] is called if the camera throws so the caller can show a message.
  Future<Uint8List?> pickFromCamera({
    void Function()? onCameraBlocked,
  }) async {
    try {
      final file = await _picker.pickImage(
        source: ImageSource.camera,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );
      return file != null ? await file.readAsBytes() : null;
    } catch (e) {
      // Camera unavailable (HTTPS required on web, or permissions denied)
      onCameraBlocked?.call();
      return null;
    }
  }

  Future<Uint8List?> pickFromGallery() async {
    try {
      final file = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );
      return file != null ? await file.readAsBytes() : null;
    } catch (_) {
      return null;
    }
  }

  /// Shows a bottom sheet asking Camera or Gallery, then picks accordingly.
  /// Handles camera permission errors with a user-friendly snackbar.
  Future<Uint8List?> pickWithSheet(BuildContext context) async {
    final source = await showModalBottomSheet<String>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 36, height: 4,
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              ListTile(
                leading: const CircleAvatar(
                  backgroundColor: Color(0xFFD8A7B1),
                  child: Icon(Icons.camera_alt, color: Colors.white, size: 20),
                ),
                title: const Text('Take a Photo',
                    style: TextStyle(fontWeight: FontWeight.w600)),
                subtitle: Text(kIsWeb
                    ? 'Opens camera (allow access in browser)'
                    : 'Use your camera'),
                onTap: () => Navigator.pop(ctx, 'camera'),
              ),
              ListTile(
                leading: const CircleAvatar(
                  backgroundColor: Color(0xFFC6A96B),
                  child: Icon(Icons.photo_library, color: Colors.white, size: 20),
                ),
                title: const Text('Upload from Device',
                    style: TextStyle(fontWeight: FontWeight.w600)),
                subtitle: const Text('Pick an existing photo'),
                onTap: () => Navigator.pop(ctx, 'gallery'),
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );

    if (source == null) return null;

    if (source == 'camera') {
      // On web, open our custom getUserMedia dialog so desktop users get a
      // real webcam preview + capture (not the browser's file picker).
      if (kIsWeb && context.mounted) {
        final bytes = await WebcamCaptureDialog.open(context);
        if (bytes != null) return bytes;
        // Dialog returned null (cancelled or camera denied) → show a snackbar
        // and fall through to the native picker / gallery.
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'Camera unavailable — allow camera access in your browser, or upload a photo instead.',
              ),
              behavior: SnackBarBehavior.floating,
              duration: Duration(seconds: 3),
            ),
          );
        }
        return pickFromGallery();
      }

      // Native camera path (mobile web + iOS/Android)
      Uint8List? bytes;
      bytes = await pickFromCamera(
        onCameraBlocked: () {
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Row(
                  children: [
                    const Icon(Icons.info_outline, color: Colors.white, size: 18),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        kIsWeb
                            ? 'Camera blocked — allow camera access in your browser settings, or upload from device instead.'
                            : 'Camera not available — opening gallery instead.',
                        style: const TextStyle(fontSize: 13),
                      ),
                    ),
                  ],
                ),
                behavior: SnackBarBehavior.floating,
                duration: const Duration(seconds: 3),
              ),
            );
          }
        },
      );
      if (bytes == null) {
        bytes = await pickFromGallery();
      }
      return bytes;
    } else {
      return pickFromGallery();
    }
  }

  /// Compress and resize image to target dimensions
  Uint8List compressImage(Uint8List bytes, {int maxSize = 512}) {
    final image = img.decodeImage(bytes);
    if (image == null) return bytes;

    final resized = img.copyResize(
      image,
      width: image.width > image.height ? maxSize : null,
      height: image.height >= image.width ? maxSize : null,
    );

    return Uint8List.fromList(img.encodePng(resized));
  }

  /// Create a thumbnail version
  Uint8List createThumbnail(Uint8List bytes, {int size = 200}) {
    final image = img.decodeImage(bytes);
    if (image == null) return bytes;

    final thumb = img.copyResizeCropSquare(image, size: size);
    return Uint8List.fromList(img.encodePng(thumb));
  }
}
