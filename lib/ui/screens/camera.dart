// ignore_for_file: library_private_types_in_public_api, use_build_context_synchronously

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import 'package:photo_manager/photo_manager.dart';
import 'photos.dart';

class CameraPage extends StatefulWidget {
  const CameraPage({super.key});

  @override
  _CameraPageState createState() => _CameraPageState();
}

class _CameraPageState extends State<CameraPage> {
  CameraController? _controller;
  Future<void>? _initializeControllerFuture;
  bool _isRearCameraSelected = true;
  List<CameraDescription>? _cameras;

  @override
  void initState() {
    super.initState();
    _initializeCamera();
  }

  Future<void> _initializeCamera() async {
    _cameras = await availableCameras();
    _setCamera(_isRearCameraSelected ? _cameras!.first : _cameras!.last);
  }

  void _setCamera(CameraDescription camera) {
    _controller = CameraController(
      camera,
      ResolutionPreset.high,
    );
    _initializeControllerFuture = _controller!.initialize();
    if (mounted) {
      setState(() {});
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: FutureBuilder<void>(
        future: _initializeControllerFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.done) {
            return Stack(
              children: [
                CameraPreview(_controller!),
                _buildCameraOverlay(),
              ],
            );
          } else {
            return const Center(child: CircularProgressIndicator());
          }
        },
      ),
    );
  }

  Widget _buildCameraOverlay() {
    return Align(
      alignment: Alignment.bottomCenter,
      child: Container(
        height: MediaQuery.of(context).size.height * 0.2,
        padding: const EdgeInsets.symmetric(horizontal: 20.0),
        color: Colors.black.withOpacity(0.6),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _buildIconButton(Icons.photo_library, _openGallery),
            _buildCaptureButton(),
            _buildIconButton(Icons.switch_camera, _switchCamera),
          ],
        ),
      ),
    );
  }

  Widget _buildIconButton(IconData icon, Function() onPressed, {double size = 28}) {
    return IconButton(
      icon: Icon(icon, color: Colors.white.withOpacity(0.8)),
      iconSize: size,
      onPressed: onPressed,
    );
  }

  Widget _buildCaptureButton() {
    return GestureDetector(
      onTap: _takePicture,
      child: Container(
        width: 65,
        height: 65,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(
            color: Colors.white,
            width: 3,
          ),
        ),
        child: Center(
          child: Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white.withOpacity(0.9),
            ),
          ),
        ),
      ),
    );
  }

  void _switchCamera() {
    setState(() {
      _isRearCameraSelected = !_isRearCameraSelected;
    });
    _setCamera(_isRearCameraSelected ? _cameras!.first : _cameras!.last);
  }

  void _openGallery() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const PhotosPage(selectedMedias: []),
      ),
    );
  }

  Future<void> _takePicture() async {
    try {
      await _initializeControllerFuture;
      final image = await _controller!.takePicture();
      final directory = await getApplicationDocumentsDirectory();
      final imagePath = path.join(directory.path, '${DateTime.now()}.png');
      await image.saveTo(imagePath);

      final result = await PhotoManager.editor.saveImageWithPath(
        imagePath,
        title: 'Photo ${DateTime.now()}',
      );

      if (result != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Photo saved to gallery')),
        );
      }
    } catch (e) {
      if (kDebugMode) {
        print(e);
      }
    }
  }
}
