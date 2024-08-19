import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:monforilens/ui/screens/finalaction.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:reorderable_grid_view/reorderable_grid_view.dart';

class Preview extends StatefulWidget {
  final List<File> sortedPhotos; // Ubah ini menjadi List<File>

  const Preview({super.key, required this.sortedPhotos});

  @override
  State<Preview> createState() => _PreviewState();
}

class _PreviewState extends State<Preview> {
  List<File> _photos = []; // Sesuaikan ini juga

  @override
  void initState() {
    super.initState();
    _photos = widget.sortedPhotos;
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
          setState(() {
            if (newIndex > oldIndex) {
              newIndex -= 1;
            }
            final item = _photos.removeAt(oldIndex);
            _photos.insert(newIndex, item);
          });
        },
     ),
);
}
}
