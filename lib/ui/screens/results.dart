// ignore_for_file: library_private_types_in_public_api

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:share_plus/share_plus.dart';
import 'package:photo_manager/photo_manager.dart';
import 'home.dart';

class ResultsScreen extends StatefulWidget {
  final List<File> processedFiles;

  const ResultsScreen({super.key, required this.processedFiles});

  @override
  _ResultsScreenState createState() => _ResultsScreenState();
}

class _ResultsScreenState extends State<ResultsScreen> {
  late TextEditingController _folderNameController;

  @override
  void initState() {
    super.initState();
    _folderNameController = TextEditingController(text: _getDefaultFolderName());
  }

  @override
  void dispose() {
    _folderNameController.dispose();
    super.dispose();
  }

  String _getDefaultFolderName() {
    return 'monforilens-${DateFormat('yyyyMMddHHmmss').format(DateTime.now())}';
  }

  Future<bool> _onWillPop() async {
    Navigator.of(context).pop();
    return false;
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: _onWillPop,
      child: Scaffold(
        backgroundColor: Colors.black,
        appBar: AppBar(
          backgroundColor: Colors.black,
          title: const Text('Hasil Akhir', style: TextStyle(color: Colors.white)),
          iconTheme: const IconThemeData(color: Colors.white),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () {
              Navigator.of(context).pop();
            },
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.home),
              onPressed: _handleCancel,
            ),
          ],
        ),
        body: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextField(
                controller: _folderNameController,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  labelText: 'Folder Name',
                  labelStyle: const TextStyle(color: Colors.white70),
                  enabledBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.white.withOpacity(0.3)),
                  ),
                  focusedBorder: const OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.white),
                  ),
                ),
              ),
              const SizedBox(height: 30),
              _buildActionButton(Icons.save, 'Simpan ke Penyimpanan', _handleSave),
              const SizedBox(height: 15),
              _buildActionButton(Icons.cloud_upload, 'Upload ke Cloud', _handleUpload),
              const SizedBox(height: 15),
              _buildActionButton(Icons.share, 'Bagikan', _handleShare),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActionButton(IconData icon, String label, VoidCallback onPressed) {
    return ElevatedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, color: Colors.white),
      label: Text(label, style: const TextStyle(color: Colors.white)),
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.blue,
        padding: const EdgeInsets.symmetric(vertical: 15.0),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.0)),
      ),
    );
  }

  Future<String> _getSafePath() async {
    if (Platform.isAndroid) {
      return '/storage/emulated/0/MonforiLens';
    } else {
      final directory = await getApplicationDocumentsDirectory();
      return '${directory.path}/MonforiLens';
    }
  }

  Future<void> _handleSave() async {
  bool hasPermission = await _requestStoragePermission();
  if (!hasPermission) {
    _showSnackBar('Izin penyimpanan diperlukan untuk menyimpan file');
    return;
  }

  final folderName = _folderNameController.text;
  final basePath = await _getSafePath();
  final directory = Directory('$basePath/$folderName');
  
  try {
    // Buat folder MonforiLens jika belum ada
    await Directory(basePath).create(recursive: true);
    
    // Buat folder output, tambahkan angka jika sudah ada
    String finalFolderPath = directory.path;
    int counter = 1;
    while (await Directory(finalFolderPath).exists()) {
      finalFolderPath = '$basePath/${folderName}_$counter';
      counter++;
    }
    await Directory(finalFolderPath).create();

    for (File file in widget.processedFiles) {
      final newPath = path.join(finalFolderPath, path.basename(file.path));
      await file.copy(newPath);
      
      // Simpan file ke galeri menggunakan photo_manager
      final result = await PhotoManager.editor.saveImageWithPath(
        newPath,
        title: path.basename(newPath),
      );
      
      if (result == null) {
        print('Failed to save file to gallery: $newPath');
      }
    }

    _showSnackBar('Files saved to $finalFolderPath and added to gallery');
  } catch (e) {
    _showSnackBar('Error saving files: $e');
  }
}

  Future<bool> _requestStoragePermission() async {
  if (Platform.isAndroid) {
    if (await Permission.manageExternalStorage.isGranted) {
      return true;
    }
    PermissionStatus status = await Permission.manageExternalStorage.request();
    if (status.isGranted) {
      return true;
    }
    if (status.isPermanentlyDenied) {
      await openAppSettings();
    }
    return false;
  }
  return true;
}

  Future<void> _handleUpload() async {
    _showSnackBar('Segera diimplementasikan');
  }

Future<void> _handleShare() async {
  List<XFile> xFiles = widget.processedFiles.map((file) => XFile(file.path)).toList();

  await Share.shareXFiles(
    xFiles,
    subject: 'Sharing processed images',
  );
}


  void _handleCancel() {
    _deleteTempFiles();
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (context) => const HomePage()),
      (Route<dynamic> route) => false,
    );
  }

  Future<void> _deleteTempFiles() async {
    for (File file in widget.processedFiles) {
      try {
        await file.delete();
      } catch (e) {
        print('Error deleting temp file: $e');
      }
    }
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }
}