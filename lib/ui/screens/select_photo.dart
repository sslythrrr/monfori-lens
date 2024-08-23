import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';
import 'package:monforilens/ui/screens/preview.dart';
import 'package:photo_manager/photo_manager.dart';

class SelectPhoto extends StatefulWidget {
  const SelectPhoto({super.key});

  @override
  State<SelectPhoto> createState() => _SelectPhotoState();
}

class _SelectPhotoState extends State<SelectPhoto> {
  List<AssetEntity> _photos = [];
  List<AssetPathEntity> _albums = [];
  final Map<String, List<AssetEntity>> _groupedPhotos = {};
  final ScrollController _scrollController = ScrollController();
  bool _isLoading = false;
  int _currentPage = 0;
  final int _pageSize = 100;
  final ValueNotifier<Set<AssetEntity>> _selectedPhotos = ValueNotifier<Set<AssetEntity>>({});
  final Map<String, Uint8List?> _thumbnailCache = {};

  final PageController _pageController = PageController();
  int _currentTabIndex = 0;

  Future<void> _navigateToPreview(List<AssetEntity> selectedPhotos) async {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => Preview(sortedPhotos: selectedPhotos),
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    _loadAlbums();
    _scrollController.addListener(_scrollListener);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_scrollListener);
    _scrollController.dispose();
    _selectedPhotos.dispose();
    super.dispose();
  }

  void _scrollListener() {
    if (_scrollController.offset >= _scrollController.position.maxScrollExtent &&
        !_scrollController.position.outOfRange) {
      _loadMorePhotos();
    }
  }

  Future<void> _loadAlbums() async {
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
      _albums = albums;
      _loadPhotosFromAlbum(albums.first);
    } else {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _loadPhotosFromAlbum(AssetPathEntity album) async {
    setState(() {
      _isLoading = true;
      _photos.clear();
      _groupedPhotos.clear();
    });

    final List<AssetEntity> photos = await album.getAssetListPaged(page: 0, size: _pageSize);
    setState(() {
      _photos = photos;
      _groupPhotos(photos);
      _isLoading = false;
      _currentPage = 1;
    });
  }

  Future<void> _loadMorePhotos() async {
    if (_isLoading) return;

    setState(() {
      _isLoading = true;
    });

    final AssetPathEntity album = _albums[_currentTabIndex];
    final List<AssetEntity> morePhotos = await album.getAssetListPaged(page: _currentPage, size: _pageSize);
    setState(() {
      _photos.addAll(morePhotos);
      _groupPhotos(morePhotos);
      _isLoading = false;
      _currentPage++;
    });
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

  void _selectPhoto(AssetEntity photo) {
    final selectedPhotos = _selectedPhotos.value;
    if (selectedPhotos.contains(photo)) {
      selectedPhotos.remove(photo);
    } else {
      selectedPhotos.add(photo);
    }
    _selectedPhotos.value = Set.from(selectedPhotos); // Notify listeners
  }

  void _selectAll() {
    if (_selectedPhotos.value.length == _photos.length) {
      _selectedPhotos.value = {};
    } else {
      _selectedPhotos.value = Set.from(_photos);
    }
  }

  Future<void> _navigateToAlbumView(AssetPathEntity album) async {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AlbumPhotoGridView(album: album),
      ),
    );
  }

  Future<Uint8List?> _getThumbnail(AssetEntity photo) async {
    final String cacheKey = photo.id;
    if (_thumbnailCache.containsKey(cacheKey)) {
      return _thumbnailCache[cacheKey];
    }
    final Uint8List? thumbnail = await photo.thumbnailDataWithSize(const ThumbnailSize(200, 200));
    _thumbnailCache[cacheKey] = thumbnail;
    return thumbnail;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: const Text('Select Photos', style: TextStyle(color: Colors.white)),
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          ValueListenableBuilder<Set<AssetEntity>>(
            valueListenable: _selectedPhotos,
            builder: (context, selectedPhotos, child) {
              return TextButton(
                onPressed: _selectAll,
                child: Text(
                  selectedPhotos.length == _photos.length ? "Deselect All" : "Select All",
                  style: const TextStyle(color: Colors.white),
                ),
              );
            },
          ),
          ValueListenableBuilder<Set<AssetEntity>>(
            valueListenable: _selectedPhotos,
            builder: (context, selectedPhotos, child) {
              return TextButton(
                onPressed: selectedPhotos.isEmpty ? null : () => _navigateToPreview(selectedPhotos.toList()),
                child: Text(
                  "Next (${selectedPhotos.length})",
                  style: TextStyle(color: selectedPhotos.isEmpty ? Colors.grey : Colors.white),
                ),
              );
            },
          ),
        ],
      ),
      body: PageView(
        controller: _pageController,
        onPageChanged: (index) {
          setState(() {
            _currentTabIndex = index;
          });
        },
        children: [
          _buildPhotoGrid(),
          AlbumGridView(
            albums: _albums,
            onAlbumTapped: _navigateToAlbumView,
          ),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        backgroundColor: const Color(0x000000ff),
        currentIndex: _currentTabIndex,
        onTap: (index) {
          _pageController.animateToPage(index, duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);
        },
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.photo_library),
            label: 'Photos',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.photo_album),
            label: 'Albums',
          ),
        ],
      ),
    );
  }

  Widget _buildPhotoGrid() {
    return GridView.builder(
      controller: _scrollController,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 4,
        crossAxisSpacing: 2,
        mainAxisSpacing: 2,
      ),
      itemCount: _photos.length,
      itemBuilder: (context, index) {
        final photo = _photos[index];
        return FutureBuilder<Uint8List?>(
          future: _getThumbnail(photo),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.done && snapshot.data != null) {
              final isSelected = _selectedPhotos.value.contains(photo);
              return GestureDetector(
                onTap: () => _selectPhoto(photo),
                child: Stack(
                  children: [
                    Positioned.fill(
                      child: Image.memory(snapshot.data!, fit: BoxFit.cover),
                    ),
                    if (isSelected)
                      const Positioned(
                        right: 4,
                        top: 4,
                        child: Icon(
                          Icons.check_circle,
                          color: Colors.green,
                        ),
                      ),
                  ],
                ),
              );
            } else {
              return const Center(child: CircularProgressIndicator());
            }
          },
        );
      },
    );
  }
}

class AlbumGridView extends StatelessWidget {
  final List<AssetPathEntity> albums;
  final Function(AssetPathEntity) onAlbumTapped;

  const AlbumGridView({
    super.key,
    required this.albums,
    required this.onAlbumTapped,
  });

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 2,
        mainAxisSpacing: 2,
      ),
      itemCount: albums.length,
      itemBuilder: (context, index) {
        final album = albums[index];
        return FutureBuilder<Uint8List?>(
          future: album.getAssetListRange(start: 0, end: 1).then((value) => value.first.thumbnailData),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.done && snapshot.data != null) {
              return GestureDetector(
                onTap: () => onAlbumTapped(album),
                child: Stack(
                  children: [
                    Image.memory(snapshot.data!, fit: BoxFit.cover),
                    Positioned(
                      bottom: 0,
                      left: 0,
                      right: 0,
                      child: Container(
                        color: Colors.black54,
                        padding: const EdgeInsets.all(4.0),
                        child: Text(
                          album.name,
                          style: const TextStyle(color: Colors.white),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            } else {
              return const Center(child: CircularProgressIndicator());
            }
          },
        );
      },
    );
  }
}

class AlbumPhotoGridView extends StatefulWidget {
  final AssetPathEntity album;

  const AlbumPhotoGridView({
    super.key,
    required this.album,
  });

  @override
  State<AlbumPhotoGridView> createState() => _AlbumPhotoGridViewState();
}

class _AlbumPhotoGridViewState extends State<AlbumPhotoGridView> {
  List<AssetEntity> _photos = [];
  final ScrollController _scrollController = ScrollController();
  bool _isLoading = false;
  int _currentPage = 0;
  final int _pageSize = 100;
  final ValueNotifier<Set<AssetEntity>> _selectedPhotos = ValueNotifier<Set<AssetEntity>>({});
  final Map<String, Uint8List?> _thumbnailCache = {};

  @override
  void initState() {
    super.initState();
    _loadPhotosFromAlbum();
    _scrollController.addListener(_scrollListener);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_scrollListener);
    _scrollController.dispose();
    _selectedPhotos.dispose();
    super.dispose();
  }

  void _scrollListener() {
    if (_scrollController.offset >= _scrollController.position.maxScrollExtent &&
        !_scrollController.position.outOfRange) {
      _loadMorePhotos();
    }
  }

  Future<void> _loadPhotosFromAlbum() async {
    setState(() {
      _isLoading = true;
      _photos.clear();
    });

    final List<AssetEntity> photos = await widget.album.getAssetListPaged(page: 0, size: _pageSize);
    setState(() {
      _photos = photos;
      _isLoading = false;
      _currentPage = 1;
    });
  }

  Future<void> _loadMorePhotos() async {
    if (_isLoading) return;

    setState(() {
      _isLoading = true;
    });

    final List<AssetEntity> morePhotos = await widget.album.getAssetListPaged(page: _currentPage, size: _pageSize);
    setState(() {
      _photos.addAll(morePhotos);
      _isLoading = false;
      _currentPage++;
    });
  }

  void _selectPhoto(AssetEntity photo) {
    final selectedPhotos = _selectedPhotos.value;
    if (selectedPhotos.contains(photo)) {
      selectedPhotos.remove(photo);
    } else {
      selectedPhotos.add(photo);
    }
    _selectedPhotos.value = Set.from(selectedPhotos); // Notify listeners
  }

  void _selectAll() {
    if (_selectedPhotos.value.length == _photos.length) {
      _selectedPhotos.value = {};
    } else {
      _selectedPhotos.value = Set.from(_photos);
    }
  }

  Future<void> _navigateToPreview(List<AssetEntity> selectedPhotos) async {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => Preview(sortedPhotos: selectedPhotos),
      ),
    );
  }

  Future<Uint8List?> _getThumbnail(AssetEntity photo) async {
    final String cacheKey = photo.id;
    if (_thumbnailCache.containsKey(cacheKey)) {
      return _thumbnailCache[cacheKey];
    }
    final Uint8List? thumbnail = await photo.thumbnailDataWithSize(const ThumbnailSize(200, 200));
    _thumbnailCache[cacheKey] = thumbnail;
    return thumbnail;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: Text(widget.album.name, style: const TextStyle(color: Colors.white)),
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          ValueListenableBuilder<Set<AssetEntity>>(
            valueListenable: _selectedPhotos,
            builder: (context, selectedPhotos, child) {
              return TextButton(
                onPressed: _selectAll,
                child: Text(
                  selectedPhotos.length == _photos.length ? "Deselect All" : "Select All",
                  style: const TextStyle(color: Colors.white),
                ),
              );
            },
          ),
          ValueListenableBuilder<Set<AssetEntity>>(
            valueListenable: _selectedPhotos,
            builder: (context, selectedPhotos, child) {
              return TextButton(
                onPressed: selectedPhotos.isEmpty ? null : () => _navigateToPreview(selectedPhotos.toList()),
                child: Text(
                  "Next (${selectedPhotos.length})",
                  style: TextStyle(color: selectedPhotos.isEmpty ? Colors.grey : Colors.white),
                ),
              );
            },
          ),
        ],
      ),
      body: GridView.builder(
        controller: _scrollController,
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 4,
          crossAxisSpacing: 2,
          mainAxisSpacing: 2,
        ),
        itemCount: _photos.length,
        itemBuilder: (context, index) {
          final photo = _photos[index];
          return FutureBuilder<Uint8List?>(
            future: _getThumbnail(photo),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.done && snapshot.data != null) {
                final isSelected = _selectedPhotos.value.contains(photo);
                return GestureDetector(
                  onTap: () => _selectPhoto(photo),
                  child: Stack(
                    children: [
                      Positioned.fill(
                        child: Image.memory(snapshot.data!, fit: BoxFit.cover),
                      ),
                      if (isSelected)
                        const Positioned(
                          right: 4,
                          top: 4,
                          child: Icon(
                            Icons.check_circle,
                            color: Colors.green,
                          ),
                        ),
                    ],
                  ),
                );
              } else {
                return const Center(child: CircularProgressIndicator());
              }
            },
          );
        },
      ),
    );
  }
}