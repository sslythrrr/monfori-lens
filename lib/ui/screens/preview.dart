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
  List<File> _photos = [];

  @override
  void initState() {
    super.initState();
    _photos = widget.sortedPhotos;
  }

  void _swapFiles(int oldIndex, int newIndex) {
    setState(() {
      // Tukar file
      final temp = _photos[oldIndex];
      _photos[oldIndex] = _photos[newIndex];
      _photos[newIndex] = temp;

      // Rename file sesuai dengan urutan baru
      for (int i = 0; i < _photos.length; i++) {
        String newName = '${path.basenameWithoutExtension(_photos[i].path)}_${_getRomanNumeral(i + 1)}${path.extension(_photos[i].path)}';
        String newPath = path.join(path.dirname(_photos[i].path), newName);
        _photos[i] = _photos[i].renameSync(newPath);
      }
    });
  }

  String _getRomanNumeral(int number) {
    const romanNumerals = {
      1: 'I', 2: 'II', 3: 'III', 4: 'IV', 5: 'V', 6: 'VI', 7: 'VII', 8: 'VIII', 9: 'IX', 10: 'X'
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
          crossAxisCount: 4,
          crossAxisSpacing: 2,
          mainAxisSpacing: 2,
        ),
        itemCount: _photos.length,
        itemBuilder: (context, index) {
          return Image.file(
            _photos[index],
            fit: BoxFit.cover,
          );
        },
        onReorder: (oldIndex, newIndex) {
          _swapFiles(oldIndex, newIndex);
        },
      ),
    );
  }
}
