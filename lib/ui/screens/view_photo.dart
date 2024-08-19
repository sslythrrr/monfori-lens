// ignore_for_file: use_build_context_synchronously

import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:monforilens/models/media.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:photo_view/photo_view.dart';
import 'package:share_plus/share_plus.dart';

class ViewPhotoScreen extends StatelessWidget {
  final Media media;

  const ViewPhotoScreen({super.key, required this.media});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
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
      body: FutureBuilder<Uint8List?>(
        future: media.assetEntity.originBytes,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.done && snapshot.data != null) {
            return PhotoView(
              imageProvider: MemoryImage(snapshot.data!),
              minScale: PhotoViewComputedScale.contained,
              maxScale: PhotoViewComputedScale.covered * 2,
              backgroundDecoration: const BoxDecoration(color: Colors.black),
            );
          } else {
            return const Center(child: CircularProgressIndicator());
          }
        },
      ),
    );
  }

  void _showPhotoDetails(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return Container(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Nama file: ${media.assetEntity.title}'),
              Text('Tanggal: ${media.assetEntity.createDateTime}'),
              Text('Ukuran: ${media.assetEntity.size} bytes'),
              // Tambahkan detail lainnya sesuai kebutuhan
            ],
          ),
        );
      },
    );
  }

  void _sharePhoto() async {
    final file = await media.assetEntity.file;
    if (file != null) {
      await Share.shareXFiles([XFile(file.path)]);
    }
  }

  void _deletePhoto(BuildContext context) {
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
                final result = await PhotoManager.editor.deleteWithIds([media.assetEntity.id]);
                if (result.isNotEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Foto berhasil dihapus')),
                  );
                  Navigator.of(context).pop(); // Tutup dialog
                  Navigator.of(context).pop(); // Kembali ke halaman sebelumnya
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