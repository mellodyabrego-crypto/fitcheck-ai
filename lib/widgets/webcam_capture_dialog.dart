// Web-only: show a full-screen dialog with a live webcam preview and a
// capture button. Returns the captured PNG bytes, or null if cancelled.
//
// Uses `dart:html` + `dart:ui_web` to embed a <video> element via
// HtmlElementView, then snapshots to a <canvas> when the user taps capture.

import 'dart:async';
// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;
import 'dart:typed_data';
// ignore: avoid_web_libraries_in_flutter
import 'dart:ui_web' as ui_web;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../core/theme.dart';

class WebcamCaptureDialog extends StatefulWidget {
  const WebcamCaptureDialog({super.key});

  /// Convenience launcher. Returns captured bytes, or null on cancel / failure.
  static Future<Uint8List?> open(BuildContext context) {
    if (!kIsWeb) return Future.value(null);
    return Navigator.of(context).push<Uint8List>(
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (_) => const WebcamCaptureDialog(),
      ),
    );
  }

  @override
  State<WebcamCaptureDialog> createState() => _WebcamCaptureDialogState();
}

class _WebcamCaptureDialogState extends State<WebcamCaptureDialog> {
  html.VideoElement? _video;
  html.MediaStream? _stream;
  String? _error;
  bool _starting = true;
  late final String _viewType;

  @override
  void initState() {
    super.initState();
    _viewType = 'webcam-preview-${DateTime.now().microsecondsSinceEpoch}';
    _start();
  }

  Future<void> _start() async {
    try {
      _stream = await html.window.navigator.mediaDevices!.getUserMedia({
        'video': {'facingMode': 'user', 'width': 1280, 'height': 720},
        'audio': false,
      });

      final v = html.VideoElement()
        ..autoplay = true
        ..muted = true
        ..srcObject = _stream
        ..style.width = '100%'
        ..style.height = '100%'
        ..style.objectFit = 'cover';
      v.setAttribute('playsinline', 'true');

      // Register the platform view factory so HtmlElementView can mount it.
      ui_web.platformViewRegistry.registerViewFactory(
        _viewType,
        (int viewId) => v,
      );

      _video = v;
      if (mounted) setState(() => _starting = false);
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Could not access camera: $e\n\n'
              'Check your browser permissions, or close other apps using the camera.';
          _starting = false;
        });
      }
    }
  }

  Future<Uint8List?> _snapshot() async {
    final v = _video;
    if (v == null || v.videoWidth == 0) return null;
    final canvas =
        html.CanvasElement(width: v.videoWidth, height: v.videoHeight);
    final ctx = canvas.context2D;
    ctx.drawImage(v, 0, 0);
    final blob = await canvas.toBlob('image/png');
    final reader = html.FileReader();
    reader.readAsArrayBuffer(blob);
    await reader.onLoad.first;
    return Uint8List.fromList(reader.result as List<int>);
  }

  void _stopStream() {
    _stream?.getTracks().forEach((t) => t.stop());
    _stream = null;
  }

  @override
  void dispose() {
    _stopStream();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title:
            const Text('Take a Photo', style: TextStyle(color: Colors.white)),
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(null),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: _starting
                ? const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CircularProgressIndicator(color: AppTheme.primary),
                        SizedBox(height: 16),
                        Text('Starting camera…',
                            style: TextStyle(color: Colors.white70)),
                      ],
                    ),
                  )
                : _error != null
                    ? Center(
                        child: Padding(
                          padding: const EdgeInsets.all(24),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.videocam_off,
                                  color: Colors.white70, size: 48),
                              const SizedBox(height: 16),
                              Text(_error!,
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(
                                      color: Colors.white70, fontSize: 14)),
                            ],
                          ),
                        ),
                      )
                    : HtmlElementView(viewType: _viewType),
          ),
          // Capture controls
          Container(
            color: Colors.black,
            padding: const EdgeInsets.symmetric(vertical: 20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                IconButton(
                  iconSize: 32,
                  icon: const Icon(Icons.cancel, color: Colors.white70),
                  onPressed: () => Navigator.of(context).pop(null),
                ),
                const SizedBox(width: 40),
                GestureDetector(
                  onTap: _error != null
                      ? null
                      : () async {
                          final bytes = await _snapshot();
                          _stopStream();
                          if (!mounted) return;
                          Navigator.of(context).pop(bytes);
                        },
                  child: Container(
                    width: 72,
                    height: 72,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 4),
                    ),
                    child: Container(
                      margin: const EdgeInsets.all(6),
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 40),
                const SizedBox(width: 32),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
