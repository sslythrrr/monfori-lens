// ignore_for_file: use_build_context_synchronously

import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:monforilens/models/media.dart';
import 'package:monforilens/ui/screens/view_photo.dart';
import 'package:intl/intl.dart';

class PhotosPage extends StatefulWidget {
  final List<Media> selectedMedias;

  const PhotosPage({super.key, required this.selectedMedias});

  @override
  State<PhotosPage> createState() => _PhotosPageState();
}

class _PhotosPageState extends State<PhotosPage> {
  List<AssetEntity> _photos = [];
  final Map<String, List<AssetEntity>> _groupedPhotos = {};
  final ScrollController _scrollController = ScrollController();
  bool _isLoading = false;
  int _currentPage = 0;
  final int _pageSize = 100;

  @override
  void initState() {
    super.initState();
    _loadPhotos();
    _scrollController.addListener(_scrollListener);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_scrollListener);
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollListener() {
    if (_scrollController.offset >= _scrollController.position.maxScrollExtent &&
        !_scrollController.position.outOfRange) {
      _loadMorePhotos();
    }
  }

  Future<void> _loadPhotos() async {
  setState(() {
    _isLoading = true;
  });

  final PermissionState ps = await PhotoManager.requestPermissionExtend();
  if (ps != PermissionState.authorized && ps != PermissionState.limited) {
    if (!mounted) return;
    setState(() {
      _isLoading = false;
    });
    return;
  }

  final List<AssetPathEntity> albums = await PhotoManager.getAssetPathList(type: RequestType.image);
  if (albums.isNotEmpty) {
    final List<AssetEntity> allPhotos = await albums[0].getAssetListPaged(page: 0, size: _pageSize);
    if (!mounted) return;
    setState(() {
      _photos = allPhotos;
      _groupPhotos(allPhotos);
      _isLoading = false;
      _currentPage = 1;
    });
  } else {
    if (!mounted) return;
    setState(() {
      _isLoading = false;
    });
  }
}

Future<void> _loadMorePhotos() async {
  if (_isLoading) return;

  setState(() {
    _isLoading = true;
  });

  final List<AssetPathEntity> albums = await PhotoManager.getAssetPathList(type: RequestType.image);
  if (albums.isNotEmpty) {
    final List<AssetEntity> morePhotos = await albums[0].getAssetListPaged(page: _currentPage, size: _pageSize);
    if (!mounted) return;
    setState(() {
      _photos.addAll(morePhotos);
      _groupPhotos(morePhotos);
      _isLoading = false;
      _currentPage++;
    });
  } else {
    if (!mounted) return;
    setState(() {
      _isLoading = false;
    });
  }
}


  void _groupPhotos(List<AssetEntity> photos) {
    for (var photo in photos) {
      final String date = DateFormat('dd MMMM yyyy').format(photo.createDateTime);
      if (_groupedPhotos.containsKey(date)) {
        _groupedPhotos[date]!.add(photo);
      } else {
        _groupedPhotos[date] = [photo];
      }
    }
    setState(() {});
  }

  void _openPhotoDetail(AssetEntity photo, int index, List<AssetEntity> photoList) {
  Navigator.push(
    context,
    MaterialPageRoute(
      builder: (context) => ViewPhotoScreen(
        photoList: photoList,
        initialIndex: index,
      ),
    ),
  );
}

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: const Text('All Photos', style: TextStyle(color: Colors.white)),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: _isLoading && _photos.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
              controller: _scrollController,
              itemCount: _groupedPhotos.length + (_isLoading ? 1 : 0),
              itemBuilder: (context, index) {
                if (index == _groupedPhotos.length) {
                  return const Center(
                    child: Padding(
                      padding: EdgeInsets.all(8.0),
                      child: CircularProgressIndicator(),
                    ),
                  );
                }
                final date = _groupedPhotos.keys.elementAt(index);
                final photos = _groupedPhotos[date]!;
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Text(
                        date,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                        ),
                      ),
                    ),
                    GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 4,
                        crossAxisSpacing: 2,
                        mainAxisSpacing: 2,
                      ),
                      itemCount: photos.length,
                      itemBuilder: (context, photoIndex) {
                        return FutureBuilder<Uint8List?>(
                          future: photos[photoIndex].thumbnailDataWithSize(const ThumbnailSize(200, 200)),
                          builder: (context, snapshot) {
                            if (snapshot.connectionState == ConnectionState.done && snapshot.data != null) {
                              return GestureDetector(
                                onTap: () => _openPhotoDetail(photos[photoIndex], photoIndex, photos),
                                child: Image.memory(snapshot.data!, fit: BoxFit.cover),
                              );
                            }
                            return Container(color: Colors.grey[800]);
                          },
                        );
                      },
                    ),
                  ],
                );
              },
            ),
    );
  }
}