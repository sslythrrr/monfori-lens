import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:crypto/crypto.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/material.dart';
import 'package:monforilens/ui/results.dart';
import 'package:reorderable_grid_view/reorderable_grid_view.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';

class Preview extends StatefulWidget {
  final List<AssetEntity> sortedPhotos;

  const Preview({super.key, required this.sortedPhotos});

  @override
  State<Preview> createState() => _PreviewState();
}

class _PreviewState extends State<Preview> {
  late List<AssetEntity> _photos;
  List<Uint8List?> _thumbnails = [];
  bool _isProcessing = false;
  late String _uniqueCode;

  @override
  void initState() {
    super.initState();
    _photos = List.from(widget.sortedPhotos);
    _loadThumbnails();
    _loadUniqueCode();
  }

  Future<void> _loadUniqueCode() async {
    final prefs = await SharedPreferences.getInstance();
    String storedCode = prefs.getString('user_code') ?? '';

    if (storedCode.isEmpty) {
      storedCode = await _getDeviceUniqueCode();
      await prefs.setString('user_code', storedCode);
    }

    setState(() {
      _uniqueCode = storedCode;
    });
  }

  Future<String> _getDeviceUniqueCode() async {
    DeviceInfoPlugin deviceInfo = DeviceInfoPlugin();
    String deviceId = '';

    if (Platform.isAndroid) {
      AndroidDeviceInfo androidInfo = await deviceInfo.androidInfo;
      deviceId = androidInfo.id;
    } else if (Platform.isIOS) {
      IosDeviceInfo iosInfo = await deviceInfo.iosInfo;
      deviceId = iosInfo.identifierForVendor ?? '';
    }

    var bytes = utf8.encode(deviceId);
    var digest = sha256.convert(bytes);
    return digest.toString().substring(0, 8);
  }

  Future<void> _loadThumbnails() async {
    final thumbnails = await Future.wait(_photos.map(
        (photo) => photo.thumbnailDataWithSize(const ThumbnailSize(200, 200))));
    setState(() {
      _thumbnails = thumbnails;
    });
  }

  void _reorderPhotos(int oldIndex, int newIndex) {
    setState(() {
      final item = _photos.removeAt(oldIndex);
      _photos.insert(newIndex, item);
      final thumbnail = _thumbnails.removeAt(oldIndex);
      _thumbnails.insert(newIndex, thumbnail);
    });
  }

  Future<String> _getAppDirectory() async {
    final directory = await getExternalStorageDirectory();
    return directory?.path ?? (await getApplicationDocumentsDirectory()).path;
  }

  Future<List<File>> _processAndRenamePhotos() async {
    List<File> renamedFiles = [];
    String appDir = await _getAppDirectory();
    String targetDir = '$appDir/Monforilens/.temp';

    await Directory(targetDir).create(recursive: true);

    for (int i = 0; i < _photos.length; i++) {
      AssetEntity photo = _photos[i];
      File? file = await photo.file;
      DateTime waktu = photo.createDateTime;
      String dateTime =
          '${waktu.year}${waktu.month.toString().padLeft(2, '0')}${waktu.day.toString().padLeft(2, '0')}_'
          '${waktu.hour.toString().padLeft(2, '0')}${waktu.minute.toString().padLeft(2, '0')}${waktu.second.toString().padLeft(2, '0')}';
      String mfCode = 'mf${(i + 1).toString().padLeft(3, '0')}';
      String newName =
          '${_uniqueCode}_${mfCode}_$dateTime${path.extension(file.path)}';
      String newPath = path.join(targetDir, newName);
      File renamedFile = await file.copy(newPath);
      renamedFiles.add(renamedFile);
    }
    return renamedFiles;
  }

  void _showProcessingDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.green)),
              const SizedBox(height: 24),
              Text(
                'Memproses foto...',
                style: GoogleFonts.poppins(
                    fontSize: 17, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),
              Text(
                'Mohon tunggu sebentar',
                style:
                    GoogleFonts.poppins(fontSize: 13, color: Colors.grey[600]),
              ),
            ],
          ),
        );
      },
    );
  }

  void _navigateToResults(List<File> processedFiles) {
    Navigator.of(context).pop(); // Close processing dialog
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ResultsScreen(processedFiles: processedFiles),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        title: Text(
          'Penyesuaian Akhir',
          style: GoogleFonts.poppins(
              color: Colors.black, fontWeight: FontWeight.w500, fontSize: 18),
        ),
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: _thumbnails.isEmpty
          ? Center(
              child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.green)),
                const SizedBox(height: 24),
                Text(
                  'Memuat foto...',
                  style: GoogleFonts.poppins(
                      fontSize: 16, fontWeight: FontWeight.w600),
                ),
              ],
            ))
          : Column(
              children: [
                Expanded(
                  child: ReorderableGridView.builder(
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 3,
                      crossAxisSpacing: 8,
                      mainAxisSpacing: 8,
                    ),
                    padding: const EdgeInsets.all(16),
                    itemCount: _photos.length,
                    itemBuilder: (context, index) {
                      return _buildPhotoItem(index);
                    },
                    onReorder: _reorderPhotos,
                    dragWidgetBuilder: (index, child) {
                      return Container(
                        decoration: BoxDecoration(
                          boxShadow: [
                            BoxShadow(
                              color: Colors.green.withOpacity(0.5),
                              blurRadius: 8,
                              spreadRadius: 2,
                            ),
                          ],
                        ),
                        child: child,
                      );
                    },
                  ),
                ),
                _buildBottomBar(),
              ],
            ),
    );
  }

  Widget _buildPhotoItem(int index) {
    return Card(
      key: ValueKey(_photos[index].id),
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Stack(
        fit: StackFit.expand,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Image.memory(
              _thumbnails[index]!,
              fit: BoxFit.cover,
            ),
          ),
          Positioned(
            right: 8,
            bottom: 8,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.green.withOpacity(0.8),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                '${index + 1}',
                style: GoogleFonts.poppins(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.w400,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomBar() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        child: Row(
          children: [
            Expanded(
              child: Text(
                '${_photos.length} foto dipilih',
                style: GoogleFonts.poppins(
                    fontSize: 14, fontWeight: FontWeight.w500),
              ),
            ),
            ElevatedButton(
              onPressed: _isProcessing
                  ? null
                  : () async {
                      setState(() => _isProcessing = true);
                      _showProcessingDialog();
                      List<File> processedFiles =
                          await _processAndRenamePhotos();
                      setState(() => _isProcessing = false);
                      _navigateToResults(processedFiles);
                    },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30)),
              ),
              child: Text(
                "Konfirmasi",
                style: GoogleFonts.poppins(
                    fontSize: 16, fontWeight: FontWeight.w500),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
