// ignore_for_file: library_private_types_in_public_api

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:monforilens/ui/screens/preview.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:intl/intl.dart';

class SelectPhoto extends StatefulWidget {
  const SelectPhoto({super.key});

  @override
  State<SelectPhoto> createState() => _SelectPhotoState();
}

class _SelectPhotoState extends State<SelectPhoto> {
  List<AssetEntity> _photos = [];
  List<AssetPathEntity> _albums = [];
  final ScrollController _scrollController = ScrollController();
  bool _isLoading = false;
  int _currentPage = 0;
  final int _pageSize = 100;
  Set<AssetEntity> _selectedPhotos = {};
  final Map<String, Uint8List?> _thumbnailCache = {};
  final Map<String, List<AssetEntity>> _groupedPhotos = {};

  final PageController _pageController = PageController();
  int _currentTabIndex = 0;

  @override
  void initState() {
    super.initState();
    _resetState();
    _loadAlbums();
    _scrollController.addListener(_scrollListener);
  }

  void _resetState() {
    _photos.clear();
    _selectedPhotos.clear();
    _thumbnailCache.clear();
    _groupedPhotos.clear();
    _currentPage = 0;
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
    final List<Map<String, dynamic>> albumWithDates = [];
    AssetPathEntity? recentAlbum;

    for (var album in albums) {
      if (album.name == "Recent") {
        recentAlbum = album;
        continue;
      }
    }

      for (var album in albums) {
        final recentAssets = await album.getAssetListRange(start: 0, end: 1);
        DateTime? lastModified;
        if (recentAssets.isNotEmpty) {
          lastModified = recentAssets.first.modifiedDateTime;
        } else {
          lastModified = DateTime(1970);
        }
        albumWithDates.add({'album': album, 'lastModified': lastModified});
      }

      albumWithDates.sort((a, b) {
        if (a['album'].name == "Recent") return -1;
        if (b['album'].name == "Recent") return 1;
        return b['lastModified'].compareTo(a['lastModified']);
      });

       final sortedAlbums = albumWithDates.map((item) => item['album'] as AssetPathEntity).toList();
    
    if (recentAlbum != null) {
      sortedAlbums.insert(0, recentAlbum);
    }

    setState(() {
      _albums = sortedAlbums;
    });

    await _loadPhotosFromAlbum(sortedAlbums.first);
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
    _groupPhotos(photos);
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

    final AssetPathEntity album = _albums[_currentTabIndex];
    final List<AssetEntity> morePhotos = await album.getAssetListPaged(page: _currentPage, size: _pageSize);
    _groupPhotos(morePhotos);
    setState(() {
      _photos.addAll(morePhotos);
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
  }

  

  void _selectPhoto(AssetEntity photo) {
    setState(() {
      if (_selectedPhotos.contains(photo)) {
        _selectedPhotos.remove(photo);
      } else {
        _selectedPhotos.add(photo);
      }
    });
  }

  void _selectAll() {
    setState(() {
      if (_selectedPhotos.length == _photos.length) {
        _selectedPhotos.clear();
      } else {
        _selectedPhotos = Set.from(_photos);
      }
    });
  }

  Future<void> _navigateToPreview(List<AssetEntity> selectedPhotos) async {
  List<AssetEntity> sortedPhotos = List.from(selectedPhotos);
  sortedPhotos.sort((a, b) {
    // Prioritaskan pengurutan berdasarkan nama file
    int filenameCompare = _compareFilenames(a.title ?? '', b.title ?? '');
    if (filenameCompare != 0) return filenameCompare;
    
    // Jika nama file sama, urutkan berdasarkan waktu pembuatan
    return a.createDateTime.compareTo(b.createDateTime);
  });

  Navigator.push(
    context,
    MaterialPageRoute(
      builder: (context) => Preview(sortedPhotos: sortedPhotos),
    ),
  );
}

int _compareFilenames(String a, String b) {
  // Pisahkan nama file dan ekstensi
  List<String> partsA = a.split('.');
  List<String> partsB = b.split('.');
  
  // Bandingkan nama file tanpa ekstensi
  String nameA = partsA.length > 1 ? partsA.sublist(0, partsA.length - 1).join('.') : a;
  String nameB = partsB.length > 1 ? partsB.sublist(0, partsB.length - 1).join('.') : b;
  
  // Coba ekstrak angka dari nama file (jika ada)
  RegExp numericRegex = RegExp(r'\d+');
  Match? matchA = numericRegex.firstMatch(nameA);
  Match? matchB = numericRegex.firstMatch(nameB);
  
  if (matchA != null && matchB != null) {
    // Jika kedua nama mengandung angka, bandingkan angka tersebut
    int numA = int.parse(matchA.group(0)!);
    int numB = int.parse(matchB.group(0)!);
    if (numA != numB) return numA.compareTo(numB);
  }
  
  // Jika tidak ada angka atau angka sama, lakukan perbandingan string biasa
  int nameCompare = nameA.compareTo(nameB);
  if (nameCompare != 0) return nameCompare;
  
  // Jika nama file sama, bandingkan ekstensi 
  String extA = partsA.length > 1 ? partsA.last : '';
  String extB = partsB.length > 1 ? partsB.last : '';
  return extA.compareTo(extB);
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
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white70,
        title: const Text('Pilih Gambar', style: TextStyle(color: Colors.black)),
        iconTheme: const IconThemeData(color: Colors.black),
        actions: [
          TextButton(
            onPressed: _selectAll,
            child: Text(
              _selectedPhotos.length == _photos.length ? "Batalkan Pilih" : "Pilih Semua",
              style: const TextStyle(color: Colors.black),
            ),
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
      bottomNavigationBar: BottomAppBar(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            IconButton(
              icon: Icon(Icons.photo_library, color: _currentTabIndex == 0 ? Colors.lightBlue : Colors.grey),
              onPressed: () => _pageController.animateToPage(0, duration: const Duration(milliseconds: 300), curve: Curves.easeInOut),
            ),
            IconButton(
              icon: Icon(Icons.photo_album, color: _currentTabIndex == 1 ? Colors.lightBlue : Colors.grey),
              onPressed: () => _pageController.animateToPage(1, duration: const Duration(milliseconds: 300), curve: Curves.easeInOut),
            ),
            ElevatedButton(
              onPressed: _selectedPhotos.isEmpty ? null : () => _navigateToPreview(_selectedPhotos.toList()),
              style: ElevatedButton.styleFrom(
                foregroundColor: Colors.white, backgroundColor: Colors.green,
              ),
              child: Text("Proses (${_selectedPhotos.length})"),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPhotoGrid() {
    return ListView.builder(
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
                  color: Colors.black,
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
                final photo = photos[photoIndex];
                return PhotoThumbnail(
                  photo: photo,
                  onTap: () => _selectPhoto(photo),
                  isSelected: _selectedPhotos.contains(photo),
                  getThumbnail: _getThumbnail,
                );
              },
            ),
          ],
        );
      },
    );
  }
}

class PhotoThumbnail extends StatefulWidget {
  final AssetEntity photo;
  final VoidCallback onTap;
  final bool isSelected;
  final Future<Uint8List?> Function(AssetEntity) getThumbnail;

  const PhotoThumbnail({
    super.key,
    required this.photo,
    required this.onTap,
    required this.isSelected,
    required this.getThumbnail,
  });

  @override
  _PhotoThumbnailState createState() => _PhotoThumbnailState();
}

class _PhotoThumbnailState extends State<PhotoThumbnail> {
  Uint8List? _thumbnail;

  @override
  void initState() {
    super.initState();
    _loadThumbnail();
  }

  Future<void> _loadThumbnail() async {
    final thumbnail = await widget.getThumbnail(widget.photo);
    if (mounted) {
      setState(() {
        _thumbnail = thumbnail;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onTap,
      child: Stack(
        fit: StackFit.expand,
        children: [
          if (_thumbnail != null)
            Image.memory(
              _thumbnail!,
              fit: BoxFit.cover,
            )
          else
            const Center(child: CircularProgressIndicator()),
          if (widget.isSelected)
            Positioned(
              right: 4,
              top: 4,
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.7),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.check_circle,
                  color: Colors.green,
                  size: 24,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class AlbumGridView extends StatefulWidget {
  final List<AssetPathEntity> albums;
  final Function(AssetPathEntity) onAlbumTapped;

  const AlbumGridView({
    super.key,
    required this.albums,
    required this.onAlbumTapped,
  });

  @override
  _AlbumGridViewState createState() => _AlbumGridViewState();
}

class _AlbumGridViewState extends State<AlbumGridView> {
  final Map<String, Uint8List?> _thumbnailCache = {};

  Future<Uint8List?> _getAlbumThumbnail(AssetPathEntity album) async {
    if (_thumbnailCache.containsKey(album.id)) {
      return _thumbnailCache[album.id];
    }

    final List<AssetEntity> recentAssets = await album.getAssetListRange(start: 0, end: 1);
    if (recentAssets.isNotEmpty) {
      final Uint8List? thumbnail = await recentAssets.first.thumbnailDataWithSize(const ThumbnailSize(300, 300));
      _thumbnailCache[album.id] = thumbnail;
      return thumbnail;
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final displayedAlbums = widget.albums.where((album) => album.name != "Recent").toList();

    return GridView.builder(
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
      ),
      padding: const EdgeInsets.all(8),
      itemCount: displayedAlbums.length,
      itemBuilder: (context, index) {
        final album = displayedAlbums[index];
        return FutureBuilder<Uint8List?>(
          future: _getAlbumThumbnail(album),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.done) {
              return GestureDetector(
                onTap: () => widget.onAlbumTapped(album),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      if (snapshot.data != null)
                        Image.memory(
                          snapshot.data!,
                          fit: BoxFit.cover,
                        )
                      else
                        Container(color: Colors.grey[300]),
                      Positioned(
                        bottom: 0,
                        left: 0,
                        right: 0,
                        child: Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.bottomCenter,
                              end: Alignment.topCenter,
                              colors: [Colors.black.withOpacity(0.8), Colors.transparent],
                            ),
                          ),
                          padding: const EdgeInsets.all(8.0),
                          child: Text(
                            album.name,
                            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ),
                    ],
                  ),
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
  Set<AssetEntity> _selectedPhotos = {};
  final Map<String, Uint8List?> _thumbnailCache = {};
  final Map<String, List<AssetEntity>> _groupedPhotos = {};
  

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
      _groupedPhotos.clear();
    });

    final List<AssetEntity> photos = await widget.album.getAssetListPaged(page: 0, size: _pageSize);
    _groupPhotos(photos);
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
    _groupPhotos(morePhotos);
    setState(() {
      _photos.addAll(morePhotos);
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
  }

  void _selectPhoto(AssetEntity photo) {
    setState(() {
      if (_selectedPhotos.contains(photo)) {
        _selectedPhotos.remove(photo);
      } else {
        _selectedPhotos.add(photo);
      }
    });
  }

  void _selectAll() {
    setState(() {
      if (_selectedPhotos.length == _photos.length) {
        _selectedPhotos.clear();
      } else {
        _selectedPhotos = Set.from(_photos);
      }
    });
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
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        title: Text(widget.album.name, style: const TextStyle(color: Colors.black)),
        iconTheme: const IconThemeData(color: Colors.black),
        actions: [
          TextButton(
            onPressed: _selectAll,
            child: Text(
              _selectedPhotos.length == _photos.length ? "Deselect All" : "Select All",
              style: const TextStyle(color: Colors.green),
            ),
          ),
        ],
      ),
      body: ListView.builder(
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
                    color: Colors.black,
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
                  final photo = photos[photoIndex];
                  return PhotoThumbnail(
                    photo: photo,
                    onTap: () => _selectPhoto(photo),
                    isSelected: _selectedPhotos.contains(photo),
                    getThumbnail: _getThumbnail,
                  );
                },
              ),
            ],
          );
        },
      ),
      bottomNavigationBar: BottomAppBar(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton(
              onPressed: _selectedPhotos.isEmpty ? null : () => _navigateToPreview(_selectedPhotos.toList()),
              style: ElevatedButton.styleFrom(
                foregroundColor: Colors.white, backgroundColor: Colors.green,
              ),
              child: Text("Process (${_selectedPhotos.length})"),
            ),
          ],
        ),
      ),
    );
  }
}
