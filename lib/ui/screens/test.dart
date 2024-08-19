// ignore_for_file: library_private_types_in_public_api, use_build_context_synchronously

import 'dart:typed_data';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:monforilens/ui/screens/camera.dart';
import 'package:monforilens/ui/screens/album.dart';
import 'package:monforilens/ui/screens/photos.dart';
import 'package:monforilens/models/media.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> with SingleTickerProviderStateMixin {
  List<AssetEntity> _recentPhotos = [];
  List<AssetPathEntity> _albums = [];
  final List<Media> _selectedMedias = [];
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
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
          title: const Text('Permission Required'),
          content: const Text('This app needs access to your gallery to display photos.'),
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
      final assets = await recentAlbum.getAssetListPaged(page: 0, size: 30);
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
    setState(() {
      _albums = albums;
    });
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

  void _openPhotosPage() async {
    final List<Media>? result = await Navigator.push<List<Media>>(
      context,
      MaterialPageRoute(
        builder: (context) => PhotosPage(selectedMedias: _selectedMedias),
      ),
    );
    if (result != null) {
      setState(() {
        _selectedMedias.clear();
        _selectedMedias.addAll(result);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 200.0,
            floating: false,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              title: const Text('Media Gallery',
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              background: Stack(
                fit: StackFit.expand,
                children: [
                  Image.network(
                    'https://source.unsplash.com/random/?photography',
                    fit: BoxFit.cover,
                  ),
                  BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
                    child: Container(
                      color: Colors.black.withOpacity(0.3),
                    ),
                  ),
                ],
              ),
            ),
          ),
          SliverPersistentHeader(
            delegate: _SliverAppBarDelegate(
              TabBar(
                controller: _tabController,
                tabs: const [
                  Tab(icon: Icon(Icons.photo_library), text: "Recent"),
                  Tab(icon: Icon(Icons.album), text: "Albums"),
                ],
                indicatorColor: Colors.white,
                labelColor: Colors.white,
                unselectedLabelColor: Colors.white60,
              ),
            ),
            pinned: true,
          ),
          SliverFillRemaining(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildRecentPhotosGrid(),
                _buildAlbumsGrid(),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _openCamera,
        backgroundColor: Colors.deepPurple,
        child: const Icon(Icons.camera_alt),
      ),
    );
  }

  Widget _buildRecentPhotosGrid() {
  return MasonryGridView.count(
    crossAxisCount: 4,
    itemCount: _recentPhotos.length + 1,
    itemBuilder: (BuildContext context, int index) {
      if (index == 0) {
        return GestureDetector(
          onTap: _openPhotosPage,
          child: Container(
            color: Colors.deepPurple,
            height: 200, // Sesuaikan tinggi sesuai kebutuhan
            child: const Center(
              child: Text(
                'View All',
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
              ),
            ),
          ),
        );
      }
      final photo = _recentPhotos[index - 1];
      return FutureBuilder<Uint8List?>(
        future: photo.thumbnailDataWithSize(const ThumbnailSize(200, 200)),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.done && snapshot.data != null) {
            return Image.memory(
              snapshot.data!,
              fit: BoxFit.cover,
            );
          }
          return Container(color: Colors.grey[300]);
        },
      );
    },
    mainAxisSpacing: 4.0,
    crossAxisSpacing: 4.0,
  );
}

  Widget _buildAlbumsGrid() {
    return GridView.builder(
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 1,
      ),
      itemCount: _albums.length,
      itemBuilder: (context, index) {
        return FutureBuilder<AssetEntity?>(
          future: _albums[index].getAssetListRange(start: 0, end: 1).then((list) => list.isNotEmpty ? list.first : null),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.done && snapshot.data != null) {
              return GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => AlbumPage(album: _albums[index]),
                    ),
                  );
                },
                child: Card(
                  elevation: 5,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Expanded(
                        child: ClipRRect(
                          borderRadius: const BorderRadius.vertical(top: Radius.circular(15)),
                          child: FutureBuilder<Uint8List?>(
                            future: snapshot.data!.thumbnailDataWithSize(const ThumbnailSize(300, 300)),
                            builder: (context, thumbnailSnapshot) {
                              if (thumbnailSnapshot.connectionState == ConnectionState.done && thumbnailSnapshot.data != null) {
                                return Image.memory(thumbnailSnapshot.data!, fit: BoxFit.cover);
                              }
                              return Container(color: Colors.grey[300]);
                            },
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Text(
                          _albums[index].name,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                          textAlign: TextAlign.center,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }
            return Container(color: Colors.grey[300]);
          },
        );
      },
    );
  }
}

class _SliverAppBarDelegate extends SliverPersistentHeaderDelegate {
  _SliverAppBarDelegate(this._tabBar);

  final TabBar _tabBar;

  @override
  double get minExtent => _tabBar.preferredSize.height;
  @override
  double get maxExtent => _tabBar.preferredSize.height;

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    return Container(
      color: Colors.deepPurple,
      child: _tabBar,
    );
  }

  @override
  bool shouldRebuild(_SliverAppBarDelegate oldDelegate) {
    return false;
  }
}