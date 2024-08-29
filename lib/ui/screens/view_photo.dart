// ignore_for_file: library_private_types_in_public_api, use_build_context_synchronously

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
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white70,
        elevation: 0,
        title: Text(
          widget.photoList[_currentIndex].title ?? 'Untitled',
          style: const TextStyle(color: Colors.black, fontSize: 18),
        ),
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: SafeArea(
        child: PhotoViewGallery.builder(
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
            child: CircularProgressIndicator(
              value: event == null ? 0 : event.cumulativeBytesLoaded / event.expectedTotalBytes!,
              valueColor: const AlwaysStoppedAnimation<Color>(Colors.green),
            ),
          ),
          backgroundDecoration: const BoxDecoration(color: Colors.white),
          pageController: _pageController,
          onPageChanged: _onPageChanged,
        ),
      ),
      bottomNavigationBar: BottomAppBar(
        color: Colors.white70,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            mainAxisSize: MainAxisSize.min,
            children: [
              Flexible(child: _buildBottomBarItem(Icons.info, 'Info', () => _showPhotoDetails(context))),
              Flexible(child: _buildBottomBarItem(Icons.share, 'Share', _sharePhoto)),
              Flexible(child: _buildBottomBarItem(Icons.delete, 'Delete', () => _deletePhoto(context))),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBottomBarItem(IconData icon, String label, VoidCallback onPressed) {
    return InkWell(
      onTap: onPressed,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Colors.green),
          const SizedBox(height: 4),
          Text(label, style: const TextStyle(color: Colors.black, fontSize: 12)),
        ],
      ),
    );
  }

  void _showPhotoDetails(BuildContext context) async {
    final currentPhoto = widget.photoList[_currentIndex];
    final file = await currentPhoto.file;
    final fileSizeInBytes = file?.lengthSync() ?? 0;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (BuildContext context) {
        return Container(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('File Name: ${currentPhoto.title}',
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              const SizedBox(height: 10),
              Text('Date: ${currentPhoto.createDateTime}',
                  style: const TextStyle(fontSize: 14)),
              const SizedBox(height: 5),
              Text(
                'Size: ${(fileSizeInBytes / 1024 / 1024).toStringAsFixed(2)} MB',
                style: const TextStyle(fontSize: 14),
              ),
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
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Delete Photo', style: TextStyle(color: Colors.black)),
          content: const Text('Are you sure you want to delete this photo?'),
          actions: [
            TextButton(
              child: const Text('Cancel', style: TextStyle(color: Colors.blue)),
              onPressed: () => Navigator.of(context).pop(),
            ),
            TextButton(
              child: const Text('Delete', style: TextStyle(color: Colors.red)),
              onPressed: () async {
                try {
                  final result = await PhotoManager.editor.deleteWithIds([widget.photoList[_currentIndex].id]);
                  if (result.isNotEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Photo deleted successfully')),
                    );
                    Navigator.of(context).pop();
                    if (widget.photoList.length > 1) {
                      setState(() {
                        widget.photoList.removeAt(_currentIndex);
                        if (_currentIndex == widget.photoList.length) {
                          _currentIndex--;
                          _pageController.jumpToPage(_currentIndex);
                        }
                      });
                    } else {
                      Navigator.of(context).pop();
                    }
                  } else {
                    throw Exception('Failed to delete photo');
                  }
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Failed to delete photo: ${e.toString()}')),
                  );
                  Navigator.of(context).pop();
                }
              },
            ),
          ],
        );
      },
    );
  }
}
