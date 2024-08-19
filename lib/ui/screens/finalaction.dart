import 'package:flutter/material.dart';

class FinalActionScreen extends StatelessWidget {
  const FinalActionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: const Text(
          'Final Actions',
          style: TextStyle(color: Colors.white),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _buildActionButton(
            context,
            Icons.share,
            'Share',
            _handleShare,
          ),
          const SizedBox(height: 20),
          _buildActionButton(
            context,
            Icons.cloud_upload,
            'Upload to Cloud',
            _handleUpload,
          ),
          const SizedBox(height: 20),
          _buildActionButton(
            context,
            Icons.save,
            'Save to Local',
            _handleSave,
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton(BuildContext context, IconData icon, String label, VoidCallback onPressed) {
    return ElevatedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, color: Colors.white),
      label: Text(label, style: const TextStyle(color: Colors.white)),
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.blue,
        padding: const EdgeInsets.symmetric(vertical: 15.0, horizontal: 30.0),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10.0),
        ),
      ),
    );
  }

  void _handleShare() {
    // Handle share logic here
  }

  void _handleUpload() {
    // Handle upload logic here
  }

  void _handleSave() {
    // Handle save logic here
  }
}
