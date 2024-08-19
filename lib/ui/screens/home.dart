// ignore_for_file: library_private_types_in_public_api, use_build_context_synchronously

import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:monforilens/ui/screens/view_photo.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:monforilens/ui/screens/camera.dart';
import 'package:monforilens/ui/screens/album.dart';
import 'package:monforilens/ui/screens/photos.dart';
import 'package:monforilens/models/media.dart';
import 'package:shimmer/shimmer.dart';
import 'package:intl/intl.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  List<AssetEntity> _recentPhotos = [];
  List<AssetPathEntity> _albums = [];
  final List<Media> _selectedMedias = [];
  final PageController _pageController = PageController();
  int _currentPage = 0;

  @override
  void initState() {
    super.initState();
    _checkPermissionAndLoadData();
  }

  Future<void> _checkPermissionAndLoadData() async {
    final hasPermission = await _handlePermission();
    if (hasPermission) {
      await _loadRecentPhotos();
      await _loadAlbums();
    }
  }

  Future<bool> _handlePermission() async {
    final PermissionState ps = await PhotoManager.requestPermissionExtend();
    if (ps.isAuth) {
      return true;
    } else {
      await showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Izin Diperlukan'),
          content: const Text('Aplikasi ini memerlukan izin untuk mengakses galeri Anda untuk menampilkan foto-foto.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('OK'),
            ),
          ],
        ),
      );
      return false;
    }
  }

  Future<void> _loadRecentPhotos() async {
    final albums = await PhotoManager.getAssetPathList(type: RequestType.image);
    if (albums.isNotEmpty) {
      final recentAlbum = albums.first;
      final assets = await recentAlbum.getAssetListPaged(page: 0, size: 10);
      setState(() {
        _recentPhotos = assets;
      });
    }
  }

  Future<void> _loadAlbums() async {
    final albums = await PhotoManager.getAssetPathList(
      type: RequestType.image,
      filterOption: FilterOptionGroup(
        imageOption: const FilterOption(
          sizeConstraint: SizeConstraint(minWidth: 0, maxWidth: 100000, minHeight: 0, maxHeight: 100000),
        ),
        createTimeCond: DateTimeCond(
          min: DateTime(1970),
          max: DateTime.now(),
        ),
      ),
    );
    albums.sort((a, b) {
      final aModified = a.lastModified ?? DateTime(1970);
      final bModified = b.lastModified ?? DateTime(1970);
      return bModified.compareTo(aModified);
    });
    // Remove the "Recent" album
    albums.removeWhere((album) => album.name == "Recent");
    setState(() {
      _albums = albums;
    });
  }

  void _updateSelectedMedias(List<Media> medias) {
    setState(() {
      _selectedMedias.clear();
      _selectedMedias.addAll(medias);
    });
  }

  Future<void> _openPhotosPage() async {
    final List<Media>? result = await Navigator.push<List<Media>>(
      context,
      MaterialPageRoute(
        builder: (context) => PhotosPage(selectedMedias: _selectedMedias),
      ),
    );
    if (result != null) {
      _updateSelectedMedias(result);
    }
  }

  void _openCamera() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const CameraPage()),
    );
    if (result == true) {
      _loadRecentPhotos();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.black,
        title: const Text('MonforiLens', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w500)),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings, color: Colors.white),
            onPressed: () {
              // Implementasi halaman pengaturan
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: PageView(
              controller: _pageController,
              onPageChanged: (int page) {
                setState(() {
                  _currentPage = page;
                });
              },
              children: [
                _buildEmptyPage(),
                _buildContentPage(),
              ],
            ),
          ),
          _buildPageIndicator(),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _openCamera,
        backgroundColor: Colors.blue,
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: const Icon(Icons.camera_alt, color: Colors.white),
      ),
    );
  }

  Widget _buildEmptyPage() {
    return const Center(
      child: Text('Halaman Kosong', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white)),
    );
  }

  Widget _buildContentPage() {
    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(
          child: _buildRecentPhotos(),
        ),
        const SliverToBoxAdapter(
          child: Padding(
            padding: EdgeInsets.fromLTRB(16, 24, 16, 8),
            child: Text(
              'Album',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: Colors.white),
            ),
          ),
        ),
        _buildAlbums(),
      ],
    );
  }

  Widget _buildPageIndicator() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: List<Widget>.generate(2, (int index) {
          return AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            width: _currentPage == index ? 16.0 : 8.0,
            height: 8.0,
            margin: const EdgeInsets.symmetric(horizontal: 4.0),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(4),
              color: _currentPage == index ? Colors.blue : Colors.grey.withOpacity(0.5),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildRecentPhotos() {
  return SizedBox(
    height: 180,
    child: Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: Text(
            'Foto Terbaru',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: Colors.white),
          ),
        ),
        Expanded(
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: _recentPhotos.length + 1,
            itemBuilder: (context, index) {
              if (index == _recentPhotos.length) {
                return Center(
                  child: TextButton(
                    onPressed: _openPhotosPage,
                    child: const Text('Lihat Semua', style: TextStyle(color: Colors.blue)),
                  ),
                );
              }
              return FutureBuilder<Uint8List?>(
                future: _recentPhotos[index].thumbnailDataWithSize(const ThumbnailSize(200, 200)),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.done && snapshot.data != null) {
                    return Padding(
                      padding: const EdgeInsets.only(left: 16),
                      child: GestureDetector(
                        onTap: () => _openPhotoDetail(_recentPhotos[index], index, _recentPhotos),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: Image.memory(snapshot.data!, width: 100, height: 100, fit: BoxFit.cover),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              DateFormat('dd MMM').format(_recentPhotos[index].createDateTime),
                              style: const TextStyle(color: Colors.white70, fontSize: 12),
                            ),
                          ],
                        ),
                      ),
                    );
                  }
                  return Container(width: 100, height: 100, color: Colors.grey[800]);
                },
              );
            },
          ),
        ),
      ],
    ),
  );
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

  Widget _buildAlbums() {
    return SliverGrid(
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 1,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
      ),
      delegate: SliverChildBuilderDelegate(
        (context, index) {
          return FutureBuilder<AssetEntity?>(
            future: _albums[index]
                .getAssetListRange(start: 0, end: 1)
                .then((list) => list.isNotEmpty ? list.first : null),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return _buildShimmerEffect();
              } else if (snapshot.hasError) {
                return const Center(child: Icon(Icons.error, color: Colors.red));
              } else if (!snapshot.hasData || snapshot.data == null) {
                return const Center(child: Icon(Icons.image_not_supported, color: Colors.grey));
              } else {
                return FutureBuilder<Uint8List?>(
                  future: snapshot.data!.thumbnailDataWithSize(const ThumbnailSize(300, 300)),
                  builder: (context, thumbnailSnapshot) {
                    if (thumbnailSnapshot.connectionState == ConnectionState.waiting) {
                      return _buildShimmerEffect();
                    } else if (thumbnailSnapshot.hasError) {
                      return const Center(child: Icon(Icons.error, color: Colors.red));
                    } else if (!thumbnailSnapshot.hasData || thumbnailSnapshot.data == null) {
                      return const Center(child: Icon(Icons.image_not_supported, color: Colors.grey));
                    } else {
                      return InkWell(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => AlbumPage(album: _albums[index]),
                            ),
                          );
                        },
                        child: Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.3),
                                blurRadius: 5,
                                offset: const Offset(0, 3),
                              ),
                            ],
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: Stack(
                              fit: StackFit.expand,
                              children: [
                                Image.memory(thumbnailSnapshot.data!, fit: BoxFit.cover),
                                Container(
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      begin: Alignment.topCenter,
                                      end: Alignment.bottomCenter,
                                      colors: [
                                        Colors.transparent,
                                        Colors.black.withOpacity(0.7),
                                      ],
                                    ),
                                  ),
                                ),
                                Positioned(
                                  left: 8,
                                  right: 8,
                                  bottom: 8,
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        _albums[index].name,
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.w600,
                                          fontSize: 16,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      const SizedBox(height: 4),
                                      FutureBuilder<int>(
                                        future: _albums[index].assetCountAsync,
                                        builder: (context, snapshot) {
                                          if (snapshot.hasData) {
                                            return Text(
                                              '${snapshot.data} items',
                                              style: const TextStyle(color: Colors.white70, fontSize: 12),
                                            );
                                          }
                                          return const SizedBox.shrink();
                                        },
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    }
                  },
                );
              }
            },
          );
        },
        childCount: _albums.length,
      ),
    );
  }

  Widget _buildShimmerEffect() {
    return Shimmer.fromColors(
      baseColor: Colors.grey[800]!,
      highlightColor: Colors.grey[700]!,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.black,
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }
} 