// ignore_for_file: use_build_context_synchronously, library_private_types_in_public_api

import 'package:flutter/material.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:photo_manager_image_provider/photo_manager_image_provider.dart';
import 'package:photo_view/photo_view.dart';
import 'package:photo_view/photo_view_gallery.dart';
import 'package:share_plus/share_plus.dart';

class ViewPhotoScreen extends StatefulWidget {
  final List<AssetEntity> photoList;
  final int initialIndex;

  const ViewPhotoScreen({
    super.key,
    required this.photoList,
    required this.initialIndex,
  });

  @override
  _ViewPhotoScreenState createState() => _ViewPhotoScreenState();
}

class _ViewPhotoScreenState extends State<ViewPhotoScreen> {
  late PageController _pageController;
  late int _currentIndex;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _pageController = PageController(initialPage: _currentIndex);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _onPageChanged(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () {
              // TODO: Implementasi fungsi edit
            },
          ),
          IconButton(
            icon: const Icon(Icons.info),
            onPressed: () {
              _showPhotoDetails(context);
            },
          ),
          IconButton(
            icon: const Icon(Icons.share),
            onPressed: () {
              _sharePhoto();
            },
          ),
          IconButton(
            icon: const Icon(Icons.delete),
            onPressed: () {
              _deletePhoto(context);
            },
          ),
        ],
      ),
      body: PhotoViewGallery.builder(
        scrollPhysics: const BouncingScrollPhysics(),
        builder: (BuildContext context, int index) {
          return PhotoViewGalleryPageOptions(
            imageProvider: AssetEntityImageProvider(widget.photoList[index]),
            initialScale: PhotoViewComputedScale.contained,
            minScale: PhotoViewComputedScale.contained,
            maxScale: PhotoViewComputedScale.covered * 2,
            heroAttributes: PhotoViewHeroAttributes(tag: widget.photoList[index].id),
          );
        },
        itemCount: widget.photoList.length,
        loadingBuilder: (context, event) => Center(
          child: SizedBox(
            width: 20.0,
            height: 20.0,
            child: CircularProgressIndicator(
              value: event == null
                  ? 0
                  : event.cumulativeBytesLoaded / event.expectedTotalBytes!,
            ),
          ),
        ),
        backgroundDecoration: const BoxDecoration(color: Colors.black),
        pageController: _pageController,
        onPageChanged: _onPageChanged,
      ),
    );
  }

  void _showPhotoDetails(BuildContext context) {
    final currentPhoto = widget.photoList[_currentIndex];
    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return Container(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Nama file: ${currentPhoto.title}'),
              Text('Tanggal: ${currentPhoto.createDateTime}'),
              Text('Ukuran: ${currentPhoto.size} bytes'),
              // Tambahkan detail lainnya sesuai kebutuhan
            ],
          ),
        );
      },
    );
  }

  void _sharePhoto() async {
    final currentPhoto = widget.photoList[_currentIndex];
    final file = await currentPhoto.file;
    if (file != null) {
      await Share.shareXFiles([XFile(file.path)]);
    }
  }

  void _deletePhoto(BuildContext context) {
    final currentPhoto = widget.photoList[_currentIndex];
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Hapus Foto'),
          content: const Text('Apakah Anda yakin ingin menghapus foto ini?'),
          actions: [
            TextButton(
              child: const Text('Batal'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: const Text('Hapus'),
              onPressed: () async {
                try {
                  final result = await PhotoManager.editor.deleteWithIds([currentPhoto.id]);
                  if (result.isNotEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Foto berhasil dihapus')),
                    );
                    Navigator.of(context).pop(); // Tutup dialog
                    if (widget.photoList.length > 1) {
                      setState(() {
                        widget.photoList.removeAt(_currentIndex);
                        if (_currentIndex == widget.photoList.length) {
                          _currentIndex--;
                          _pageController.jumpToPage(_currentIndex);
                        }
                      });
                    } else {
                      Navigator.of(context).pop(); // Kembali ke halaman sebelumnya jika tidak ada foto lagi
                    }
                  } else {
                    throw Exception('Gagal menghapus foto');
                  }
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Gagal menghapus foto: ${e.toString()}')),
                  );
                  Navigator.of(context).pop(); // Tutup dialog
                }
              },
            ),
          ],
        );
      },
    );
  }
}
