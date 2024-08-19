import 'dart:io';
import 'package:flutter/material.dart';
import 'package:monforilens/ui/screens/finalaction.dart';
import 'package:reorderable_grid_view/reorderable_grid_view.dart';
import 'package:path/path.dart' as path;

class Preview extends StatefulWidget {
  final List<File> sortedPhotos;

  const Preview({super.key, required this.sortedPhotos});

  @override
  State<Preview> createState() => _PreviewState();
}

class _PreviewState extends State<Preview> {
  late List<File> _photos;

  @override
  void initState() {
    super.initState();
    _photos = List.from(widget.sortedPhotos);
  }

  void _swapFiles(int oldIndex, int newIndex) {
    setState(() {
      if (oldIndex < newIndex) {
        newIndex -= 1;
      }
      final File item = _photos.removeAt(oldIndex);
      _photos.insert(newIndex, item);

      // Rename files based on new order
      _renameFiles();
    });
  }

  void _renameFiles() {
    for (int i = 0; i < _photos.length; i++) {
      File photo = _photos[i];
      String oldPath = photo.path;
      String fileName = path.basenameWithoutExtension(oldPath);
      String extension = path.extension(oldPath);
      
      // Extract the prefix (everything before the last underscore)
      List<String> parts = fileName.split('_');
      String prefix = parts.sublist(0, parts.length - 1).join('_');
      
      // Create new name with updated Roman numeral
      String newName = '${prefix}_${_getRomanNumeral(i + 1)}$extension';
      String newPath = path.join(path.dirname(oldPath), newName);
      
      // Rename the file
      File renamedFile = photo.renameSync(newPath);
      _photos[i] = renamedFile;
    }
  }

  String _getRomanNumeral(int number) {
    const romanNumerals = {
      1: 'I', 2: 'II', 3: 'III', 4: 'IV', 5: 'V', 6: 'VI', 7: 'VII', 8: 'VIII', 9: 'IX', 10: 'X'
    };
    return romanNumerals[number] ?? number.toString();
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
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const FinalActionScreen(),
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
          return Container(
            key: ValueKey(_photos[index].path),
            child: Image.file(
              _photos[index],
              fit: BoxFit.cover,
            ),
          );
        },
        onReorder: _swapFiles,
      ),
    );
  }
}