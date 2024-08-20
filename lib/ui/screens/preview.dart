// ignore_for_file: use_build_context_synchronously

import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:monforilens/ui/screens/finalaction.dart';
import 'package:reorderable_grid_view/reorderable_grid_view.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:path/path.dart' as path;
import 'package:intl/intl.dart';

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

  void _swapPhotos(int oldIndex, int newIndex) {
    setState(() {
      if (oldIndex < newIndex) {
        newIndex -= 1;
      }
      final AssetEntity item = _photos.removeAt(oldIndex);
      _photos.insert(newIndex, item);
    });
  }

  Future<List<File>> _processAndRenamePhotos() async {
    List<File> renamedFiles = [];
    for (int i = 0; i < _photos.length; i++) {
      AssetEntity photo = _photos[i];
      File? file = await photo.file;
      if (file != null) {
        String formattedDate = DateFormat('MMdd').format(photo.createDateTime);
        String suffix = 'mf$formattedDate${_getRomanNumeral(i + 1)}_';
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

  String _getRomanNumeral(int number) {
    const romanNumerals = {
      1: 'I', 2: 'II', 3: 'III', 4: 'IV', 5: 'V',
      6: 'VI', 7: 'VII', 8: 'VIII', 9: 'IX', 10: 'X'
    };
    return romanNumerals[number] ?? '';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: const Text(
          'Preview and Adjust',
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
                  builder: (context) => FinalActionScreen(processedFiles: processedFiles),
                ),
              );
            },
            child: const Text(
              "Confirm",
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
      body: ReorderableGridView.builder(
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3,
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
                return Image.memory(
                  snapshot.data!,
                  fit: BoxFit.cover,
                );
              } else {
                return const Center(child: CircularProgressIndicator());
              }
            },
          );
        },
        onReorder: _swapPhotos,
      ),
    );
  }
}