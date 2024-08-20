// ignore_for_file: deprecated_member_use, library_private_types_in_public_api

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:monforilens/ui/screens/select_photo.dart';
import 'package:path/path.dart' as path;
import 'package:share_plus/share_plus.dart';

class FinalActionScreen extends StatefulWidget {
  final List<File> processedFiles;

  const FinalActionScreen({super.key, required this.processedFiles});

  @override
  _FinalActionScreenState createState() => _FinalActionScreenState();
}

class _FinalActionScreenState extends State<FinalActionScreen> {
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
    _handleCancel();
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
          title: const Text('Final Actions', style: TextStyle(color: Colors.white)),
          iconTheme: const IconThemeData(color: Colors.white),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () {
              _handleCancel();
            },
          ),
          actions: [
            TextButton(
              onPressed: () {
                _handleCancel();
              },
              child: const Text('Cancel', style: TextStyle(color: Colors.white)),
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
              _buildActionButton(Icons.save, 'Save to Local', _handleSave),
              const SizedBox(height: 15),
              _buildActionButton(Icons.cloud_upload, 'Upload to Cloud', _handleUpload),
              const SizedBox(height: 15),
              _buildActionButton(Icons.share, 'Share', _handleShare),
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

  Future<void> _handleSave() async {
    final folderName = _folderNameController.text;
    final directory = Directory('/storage/emulated/0/MonforiLens/$folderName');
    await directory.create(recursive: true);

    for (File file in widget.processedFiles) {
      final newPath = path.join(directory.path, path.basename(file.path));
      await file.copy(newPath);
    }

    _showSnackBar('Files saved to ${directory.path}');
    _deleteTempFiles();
  }

  Future<void> _handleUpload() async {
    // Implement cloud upload logic here
    _showSnackBar('Upload functionality not implemented yet');
  }

  Future<void> _handleShare() async {
    await Share.shareXFiles(
      widget.processedFiles.map((file) => XFile(file.path)).toList(),
      subject: 'Sharing processed images',
    );
  }

  void _handleCancel() {
    _deleteTempFiles();
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (context) => const SelectPhoto()),
      (Route<dynamic> route) => false,
    );
  }

  Future<void> _deleteTempFiles() async {
    for (File file in widget.processedFiles) {
      await file.delete();
    }
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }
}
