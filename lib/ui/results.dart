// ignore_for_file: library_private_types_in_public_api, use_build_context_synchronously, deprecated_member_use

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:archive/archive_io.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as path;
import 'package:image/image.dart' as img;
import 'home.dart';

class ResultsScreen extends StatefulWidget {
  final List<File> processedFiles;

  const ResultsScreen({super.key, required this.processedFiles});

  @override
  _ResultsScreenState createState() => _ResultsScreenState();
}

class _ResultsScreenState extends State<ResultsScreen>
    with WidgetsBindingObserver {
  late TextEditingController _folderNameController;
  bool _isProcessing = false;
  bool _isCompressed = false;
  File? _compressedFile;
  int _processedCount = 0;
  int _totalFiles = 0;
  double _progressPercentage = 0.0;

  @override
  void initState() {
    super.initState();
    _folderNameController =
        TextEditingController(text: _getDefaultFolderName());
    _totalFiles = widget.processedFiles.length;

    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance
        .addPostFrameCallback((_) => _handleCompressFolder(context));
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _folderNameController.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.detached) {
      _deleteTempFiles();
    }
  }

  String _getDefaultFolderName() {
    return 'mf-${DateFormat('yyyyMMddHHmmss').format(DateTime.now())}';
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        _deleteTempFiles();
        return true;
      },
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: _buildAppBar(),
        body: _buildBody(),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: Colors.white,
      elevation: 0,
      title: Text(
        'Hasil Akhir',
        style: GoogleFonts.poppins(
          color: Colors.black,
          fontWeight: FontWeight.w600,
          fontSize: 20,
        ),
      ),
      leading: IconButton(
        icon: const Icon(Icons.arrow_back, color: Colors.black),
        onPressed: () => Navigator.of(context).pop(),
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.home, color: Colors.black),
          onPressed: () => _handleCancel(context),
        ),
      ],
    );
  }

  Widget _buildBody() {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Icon(Icons.folder_zip, size: 80, color: Colors.green),
            const SizedBox(height: 24),
            Text(
              _isCompressed
                  ? 'Folder siap untuk dibagikan'
                  : 'Mengompres folder...',
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.w500,
                color: Colors.black87,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            _buildFolderNameInput(),
            const SizedBox(height: 32),
            _buildActionButtons(),
            if (_isProcessing) _buildProgressIndicator(),
          ],
        ),
      ),
    );
  }

  Widget _buildFolderNameInput() {
    return TextFormField(
      controller: _folderNameController,
      decoration: InputDecoration(
        labelText: 'Nama Folder',
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        filled: true,
        fillColor: Colors.grey[100],
        prefixIcon: const Icon(Icons.folder, color: Colors.green),
        labelStyle: GoogleFonts.poppins(),
      ),
      style: GoogleFonts.poppins(),
      enabled: _isCompressed,
    );
  }

  Widget _buildActionButtons() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Column(
        children: [
          _buildActionButton(
            onPressed:
                _isProcessing ? null : () => _handleShareCompressed(context),
            backgroundColor: Colors.green,
            icon: Icons.share,
            label: 'Bagikan',
          ),
          const SizedBox(height: 12),
          _buildActionButton(
            onPressed: _isProcessing ? null : () => _handleSaveToLocal(context),
            backgroundColor: const Color(0xFF2196F3),
            icon: Icons.save,
            label: 'Simpan ke Lokal',
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required VoidCallback? onPressed,
    required Color backgroundColor,
    required IconData icon,
    required String label,
  }) {
    return SizedBox(
      width: double.infinity,
      height: 54,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: backgroundColor,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 2,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 20),
            const SizedBox(width: 12),
            Text(
              label,
              style: GoogleFonts.poppins(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProgressIndicator() {
    return Column(
      children: [
        const SizedBox(height: 16),
        LinearProgressIndicator(
          value: _progressPercentage,
          backgroundColor: Colors.grey[300],
          valueColor: const AlwaysStoppedAnimation<Color>(Colors.green),
        ),
        const SizedBox(height: 8),
        Text(
          'Mengompres file $_processedCount dari $_totalFiles (${(_progressPercentage * 100).toStringAsFixed(1)}%)',
          style: GoogleFonts.poppins(fontSize: 14, color: Colors.grey[600]),
        ),
      ],
    );
  }

  Future<void> _handleCompressFolder(BuildContext context) async {
    setState(() {
      _isProcessing = true;
      _processedCount = 0;
      _progressPercentage = 0.0;
    });

    final folderName = _getDefaultFolderName();
    final tempDir = await getTemporaryDirectory();
    final zipFile = File('${tempDir.path}/$folderName.zip');

    try {
      await _createZipFile(zipFile);
      _compressedFile = zipFile;
      setState(() {
        _isCompressed = true;
        _isProcessing = false;
      });
      _showSnackBar(context, 'Folder berhasil dikompres');
    } catch (e) {
      _showSnackBar(context, 'Error saat mengompres folder: $e');
      setState(() => _isProcessing = false);
    }
  }

  Future<void> _handleShareCompressed(BuildContext context) async {
    final folderName = _folderNameController.text.isNotEmpty
        ? _folderNameController.text
        : _getDefaultFolderName();

    if (_compressedFile != null && await _compressedFile!.exists()) {
      final tempDir = await getTemporaryDirectory();
      final newZipPath = '${tempDir.path}/$folderName.zip';

      await _compressedFile!.rename(newZipPath);

      await Share.shareXFiles([XFile(newZipPath)],
          subject: 'Sharing $folderName');
    } else {
      _showSnackBar(context, 'File kompres tidak ditemukan');
    }
  }

  Future<void> _handleSaveToLocal(BuildContext context) async {
    final folderName = _folderNameController.text.isNotEmpty
        ? _folderNameController.text
        : _getDefaultFolderName();

    if (_compressedFile != null && await _compressedFile!.exists()) {
      final downloadsDir = Directory('/storage/emulated/0/Download');
      final newZipPath = path.join(downloadsDir.path, '$folderName.zip');

      await _compressedFile!.copy(newZipPath);

      _showSnackBar(context, 'File berhasil disimpan di $newZipPath');
    } else {
      _showSnackBar(context, 'File kompres tidak ditemukan');
    }
  }

  Future<void> _createZipFile(File zipFile) async {
    final zipEncoder = ZipFileEncoder();
    zipEncoder.create(zipFile.path);

    const chunkSize = 50;
    for (var i = 0; i < widget.processedFiles.length; i += chunkSize) {
      final end = (i + chunkSize < widget.processedFiles.length)
          ? i + chunkSize
          : widget.processedFiles.length;
      final chunk = widget.processedFiles.sublist(i, end);

      await Future.forEach(chunk, (File file) async {
        final img.Image? originalImage =
            img.decodeImage(await file.readAsBytes());
        if (originalImage != null) {
          final img.Image resizedImage = img.copyResize(originalImage,
              width: (originalImage.width * 0.7).toInt(),
              height: (originalImage.height * 0.7).toInt());
          final compressedFile = File('${file.path}.jpg')
            ..writeAsBytesSync(img.encodeJpg(resizedImage, quality: 90));
          await zipEncoder.addFile(compressedFile);
          await file.delete();
        }

        setState(() {
          _processedCount++;
          _progressPercentage = _processedCount / _totalFiles;
        });
      });
      await Future.delayed(Duration.zero);
      var _ = await compute(_dummyCompute, 0);
    }

    await zipEncoder.close();
  }

  static int _dummyCompute(int value) => value;

  void _handleCancel(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Konfirmasi',
              style: GoogleFonts.poppins(
                  fontWeight: FontWeight.w600, fontSize: 17)),
          content: Text(
              'Apakah Anda yakin ingin kembali ke halaman utama? Semua perubahan akan hilang.',
              style: GoogleFonts.poppins()),
          actions: [
            TextButton(
              child: Text('Batal', style: GoogleFonts.poppins()),
              onPressed: () => Navigator.of(context).pop(),
            ),
            ElevatedButton(
              child: Text('Ya', style: GoogleFonts.poppins()),
              onPressed: () {
                _deleteTempFiles();
                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(builder: (context) => const HomePage()),
                  (Route<dynamic> route) => false,
                );
              },
            ),
          ],
        );
      },
    );
  }

  Future<void> _deleteTempFiles() async {
    for (File file in widget.processedFiles) {
      try {
        if (await file.exists()) {
          await file.delete();
        }
      } catch (e) {
        // Handle error silently
      }
    }
    if (_compressedFile != null && await _compressedFile!.exists()) {
      await _compressedFile!.delete();
    }
  }

  void _showSnackBar(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: GoogleFonts.poppins()),
        backgroundColor: Colors.green,
      ),
    );
  }
}
