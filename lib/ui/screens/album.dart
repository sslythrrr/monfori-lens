// ignore_for_file: library_private_types_in_public_api, use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:monforilens/models/media.dart';
import 'package:monforilens/ui/screens/view_photo.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:intl/intl.dart';

class AlbumPage extends StatefulWidget {
  final AssetPathEntity album;

  const AlbumPage({super.key, required this.album});

  @override
  _AlbumPageState createState() => _AlbumPageState();
}

class _AlbumPageState extends State<AlbumPage> {
  List<AssetEntity> _photos = [];
  final Map<String, List<AssetEntity>> _groupedPhotos = {};
  final ScrollController _scrollController = ScrollController();
  bool _isLoading = false;
  int _currentPage = 0;
  final int _pageSize = 100;

  @override
  void initState() {
    super.initState();
    _loadAlbumPhotos();
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

  Future<void> _loadAlbumPhotos() async {
    setState(() {
      _isLoading = true;
    });

    final assets = await widget.album.getAssetListPaged(page: 0, size: _pageSize);
    if (mounted) {
      setState(() {
        _photos = assets;
        _groupPhotos(assets);
        _isLoading = false;
        _currentPage = 1;
      });
    }
  }

  Future<void> _loadMorePhotos() async {
    if (_isLoading) return;

    setState(() {
      _isLoading = true;
    });

    final morePhotos = await widget.album.getAssetListPaged(page: _currentPage, size: _pageSize);
    if (mounted) {
      setState(() {
        _photos.addAll(morePhotos);
        _groupPhotos(morePhotos);
        _isLoading = false;
        _currentPage++;
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

  void _openPhotoDetail(AssetEntity photo) async {
    final Uint8List? thumbnailData = await photo.thumbnailDataWithSize(const ThumbnailSize(500, 500));
    if (thumbnailData != null) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ViewPhotoScreen(
            media: Media(
              assetEntity: photo,
              widget: Image.memory(thumbnailData),
            ),
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: Text(widget.album.name, style: const TextStyle(color: Colors.white)),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: _isLoading && _photos.isEmpty
          ? const Center(child: CircularProgressIndicator(color: Colors.white))
          : ListView.builder(
              controller: _scrollController,
              itemCount: _groupedPhotos.length + (_isLoading ? 1 : 0),
              itemBuilder: (context, index) {
                if (index == _groupedPhotos.length) {
                  return const Center(
                    child: Padding(
                      padding: EdgeInsets.all(8.0),
                      child: CircularProgressIndicator(color: Colors.white),
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
                                onTap: () => _openPhotoDetail(photos[photoIndex]),
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