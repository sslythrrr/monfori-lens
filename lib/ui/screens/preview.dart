// ignore_for_file: use_build_context_synchronously

import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:monforilens/ui/screens/results.dart';
import 'package:reorderable_grid_view/reorderable_grid_view.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:path/path.dart' as path;

class Preview extends StatefulWidget {
  final List<AssetEntity> sortedPhotos;

  const Preview({super.key, required this.sortedPhotos});

  @override
  State<Preview> createState() => _PreviewState();
}

class _PreviewState extends State<Preview> {
  late List<AssetEntity> _photos;

  @override
  void initState() {
    super.initState();
    _photos = List.from(widget.sortedPhotos);
  }

  void _reorderPhotos(int oldIndex, int newIndex) {
    setState(() {
      final item = _photos.removeAt(oldIndex);
      _photos.insert(newIndex, item);
    });
  }

  Future<List<File>> _processAndRenamePhotos() async {
    List<File> renamedFiles = [];
    for (int i = 0; i < _photos.length; i++) {
      AssetEntity photo = _photos[i];
      File? file = await photo.file;
      if (file != null) {
        String suffix = 'mf${(i + 1).toString().padLeft(2, '0')}_';
        String newName = '$suffix${path.basenameWithoutExtension(file.path)}${path.extension(file.path)}';

        String targetDir = '/storage/emulated/0/Monforilens/.temp';
        Directory directory = Directory(targetDir);
        if (!directory.existsSync()) {
          directory.createSync(recursive: true);
        }

        String newPath = path.join(targetDir, newName);
        File renamedFile = await file.copy(newPath);
        renamedFiles.add(renamedFile);
      }
    }
    return renamedFiles;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: const Text(
          'Pratinjau Hasil',
          style: TextStyle(color: Colors.white),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          TextButton(
            onPressed: () async {
              List<File> processedFiles = await _processAndRenamePhotos();
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => ResultsScreen(processedFiles: processedFiles),
                ),
              );
            },
            child: const Text(
              "Konfirmasi",
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
      body: ReorderableGridView.builder(
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 4,
          crossAxisSpacing: 4,
          mainAxisSpacing: 4,
        ),
        itemCount: _photos.length,
        itemBuilder: (context, index) {
          return FutureBuilder<Uint8List?>(
            key: ValueKey(_photos[index].id),
            future: _photos[index].thumbnailDataWithSize(const ThumbnailSize(300, 300)),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.done && snapshot.data != null) {
                return Stack(
                  fit: StackFit.expand,
                  children: [
                    Image.memory(
                      snapshot.data!,
                      fit: BoxFit.cover,
                    ),
                    Positioned(
                      right: 4,
                      bottom: 4,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.5),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          '${index + 1}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ),
                  ],
                );
              } else {
                return const Center(child: CircularProgressIndicator());
              }
            },
          );
        },
        onReorder: _reorderPhotos,
        dragWidgetBuilder: (index, child) {
          return Container(
            decoration: BoxDecoration(
              boxShadow: [
                BoxShadow(
                  color: Colors.blue.withOpacity(0.5),
                  blurRadius: 8,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: child,
          );
        },
      ),
    );
  }
}