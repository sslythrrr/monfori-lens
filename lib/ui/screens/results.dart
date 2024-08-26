// ignore_for_file: library_private_types_in_public_api, deprecated_member_use

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:share_plus/share_plus.dart';
import 'package:archive/archive.dart';
import 'package:android_intent_plus/android_intent.dart';
import 'package:android_intent_plus/flag.dart';
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

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvoked: (didPop) {
        if (didPop) return;
        Navigator.of(context).pop();
      },
      child: Scaffold(
        backgroundColor: Colors.black,
        appBar: AppBar(
          backgroundColor: Colors.black,
          title: const Text('Hasil Akhir', style: TextStyle(color: Colors.white)),
          iconTheme: const IconThemeData(color: Colors.white),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => Navigator.of(context).pop(),
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
              _buildActionButton(Icons.share, 'Bagikan File', _handleShare),
              const SizedBox(height: 15),
              _buildActionButton(Icons.folder_zip, 'Bagikan Folder (Compressed)', _handleShareCompressed),
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
      await Directory(basePath).create(recursive: true);
      
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
      }

      // Kirim broadcast agar media scanner memperbarui file di Monforilens
      _refreshGallery(finalFolderPath);

      _showSnackBar('Files saved to $finalFolderPath');
    } catch (e) {
      _showSnackBar('Error saving files: $e');
    }
}

void _refreshGallery(String path) async {
  if (Platform.isAndroid) {
    final intent = AndroidIntent(
      action: 'android.intent.action.MEDIA_SCANNER_SCAN_FILE',
      data: Uri.file(path).toString(),
      flags: <int>[Flag.FLAG_GRANT_READ_URI_PERMISSION],
    );
    await intent.launch();
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

  Future<void> _handleShareCompressed() async {
    final folderName = _folderNameController.text;
    final tempDir = await getTemporaryDirectory();
    final zipFile = File('${tempDir.path}/$folderName.zip');

    try {
      final encoder = ZipEncoder();
      final archive = Archive();

      for (File file in widget.processedFiles) {
        final bytes = await file.readAsBytes();
        final archiveFile = ArchiveFile(path.basename(file.path), bytes.length, bytes);
        archive.addFile(archiveFile);
      }

      final zipData = encoder.encode(archive);
      if (zipData != null) {
        await zipFile.writeAsBytes(zipData);
        await Share.shareXFiles([XFile(zipFile.path)], subject: 'Sharing compressed folder');
      } else {
        _showSnackBar('Error creating zip file');
      }
    } catch (e) {
      _showSnackBar('Error sharing compressed folder: $e');
    } finally {
      // Clean up temporary zip file
      if (await zipFile.exists()) {
        await zipFile.delete();
      }
    }
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
        // Handle error silently
      }
    }
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }
}