// ignore_for_file: library_private_types_in_public_api

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:monforilens/ui/preview.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:intl/intl.dart';
import 'package:google_fonts/google_fonts.dart';

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
    if (_scrollController.offset >=
            _scrollController.position.maxScrollExtent &&
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

    final List<AssetPathEntity> albums =
        await PhotoManager.getAssetPathList(type: RequestType.image);

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

      final sortedAlbums = albumWithDates
          .map((item) => item['album'] as AssetPathEntity)
          .toList();

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

    final List<AssetEntity> photos =
        await album.getAssetListPaged(page: 0, size: _pageSize);
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
    final List<AssetEntity> morePhotos =
        await album.getAssetListPaged(page: _currentPage, size: _pageSize);
    _groupPhotos(morePhotos);
    setState(() {
      _photos.addAll(morePhotos);
      _isLoading = false;
      _currentPage++;
    });
  }

  void _groupPhotos(List<AssetEntity> photos) {
    for (var photo in photos) {
      final String date =
          DateFormat('dd MMMM yyyy').format(photo.createDateTime);
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

  List<AssetEntity> mergeSort(List<AssetEntity> photos) {
    if (photos.length <= 1) {
      return photos;
    }

    int mid = photos.length ~/ 2;
    List<AssetEntity> left = mergeSort(photos.sublist(0, mid));
    List<AssetEntity> right = mergeSort(photos.sublist(mid));

    return merge(left, right);
  }

  List<AssetEntity> merge(List<AssetEntity> left, List<AssetEntity> right) {
    List<AssetEntity> result = [];
    int i = 0, j = 0;

    while (i < left.length && j < right.length) {
      int filenameCompare =
          _compareFilenames(left[i].title ?? '', right[j].title ?? '');
      if (filenameCompare != 0) {
        if (filenameCompare < 0) {
          result.add(left[i]);
          i++;
        } else {
          result.add(right[j]);
          j++;
        }
      } else {
        if (left[i].createDateTime.isBefore(right[j].createDateTime)) {
          result.add(left[i]);
          i++;
        } else {
          result.add(right[j]);
          j++;
        }
      }
    }

    result.addAll(left.sublist(i));
    result.addAll(right.sublist(j));

    return result;
  }

  Future<void> _navigateToPreview() async {
    List<AssetEntity> sortedPhotos = mergeSort(List.from(_selectedPhotos));

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => Preview(sortedPhotos: sortedPhotos),
      ),
    );
  }

  int _compareFilenames(String a, String b) {
    List<String> partsA = a.split('.');
    List<String> partsB = b.split('.');

    String nameA =
        partsA.length > 1 ? partsA.sublist(0, partsA.length - 1).join('.') : a;
    String nameB =
        partsB.length > 1 ? partsB.sublist(0, partsB.length - 1).join('.') : b;

    RegExp numericRegex = RegExp(r'\d+');
    Match? matchA = numericRegex.firstMatch(nameA);
    Match? matchB = numericRegex.firstMatch(nameB);

    if (matchA != null && matchB != null) {
      int numA = int.parse(matchA.group(0)!);
      int numB = int.parse(matchB.group(0)!);
      if (numA != numB) return numA.compareTo(numB);
    }

    int nameCompare = nameA.compareTo(nameB);
    if (nameCompare != 0) return nameCompare;

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
    final Uint8List? thumbnail =
        await photo.thumbnailDataWithSize(const ThumbnailSize(200, 200));
    _thumbnailCache[cacheKey] = thumbnail;
    return thumbnail;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromRGBO(245, 245, 245, 1),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        title: Text(
          'Pilih Gambar',
          style: GoogleFonts.poppins(
              color: Colors.black, fontWeight: FontWeight.w500, fontSize: 18),
        ),
        iconTheme: const IconThemeData(color: Colors.black),
        actions: [
          TextButton(
            onPressed: _selectAll,
            child: Text(
              _selectedPhotos.length == _photos.length
                  ? "Batalkan Pilih"
                  : "Pilih Semua",
              style: GoogleFonts.poppins(
                  color: Colors.green,
                  fontWeight: FontWeight.w600,
                  fontSize: 12),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          _buildTabBar(),
          Expanded(
            child: PageView(
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
          ),
        ],
      ),
      bottomNavigationBar: _buildBottomBar(),
    );
  }

  Widget _buildTabBar() {
    return Container(
      color: Colors.white,
      child: Row(
        children: [
          _buildTab(0, Icons.photo_library, "Semua Foto"),
          _buildTab(1, Icons.photo_album, "Album"),
        ],
      ),
    );
  }

  Widget _buildTab(int index, IconData icon, String label) {
    final isSelected = _currentTabIndex == index;
    return Expanded(
      child: InkWell(
        onTap: () => _pageController.animateToPage(
          index,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
        ),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(
                color: isSelected ? Colors.green : Colors.transparent,
                width: 2,
              ),
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: isSelected ? Colors.green : Colors.grey),
              const SizedBox(width: 8),
              Text(
                label,
                style: GoogleFonts.poppins(
                    color: isSelected ? Colors.green : Colors.grey,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                    fontSize: 14),
              ),
            ],
          ),
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
              padding: EdgeInsets.all(16.0),
              child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.green)),
            ),
          );
        }
        final date = _groupedPhotos.keys.elementAt(index);
        final photos = _groupedPhotos[date]!;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text(
                date,
                style: GoogleFonts.poppins(
                  color: Colors.black,
                  fontWeight: FontWeight.w500,
                  fontSize: 15,
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

  Widget _buildBottomBar() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        child: Row(
          children: [
            Expanded(
              child: Text(
                '${_selectedPhotos.length} foto dipilih',
                style: GoogleFonts.poppins(
                    fontSize: 14, fontWeight: FontWeight.w500),
              ),
            ),
            ElevatedButton(
              onPressed: _selectedPhotos.isEmpty ? null : _navigateToPreview,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30)),
              ),
              child: Text(
                "Proses",
                style: GoogleFonts.poppins(
                    fontSize: 16, fontWeight: FontWeight.w500),
              ),
            ),
          ],
        ),
      ),
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
            const Center(
                child: CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.green))),
          if (widget.isSelected)
            Container(
              color: Colors.green.withOpacity(0.3),
              child: const Icon(
                Icons.check,
                color: Colors.white,
                size: 30,
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

    final List<AssetEntity> recentAssets =
        await album.getAssetListRange(start: 0, end: 1);
    if (recentAssets.isNotEmpty) {
      final Uint8List? thumbnail = await recentAssets.first
          .thumbnailDataWithSize(const ThumbnailSize(300, 300));
      _thumbnailCache[album.id] = thumbnail;
      return thumbnail;
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final displayedAlbums =
        widget.albums.where((album) => album.name != "Recent").toList();

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
                              colors: [
                                Colors.black.withOpacity(0.8),
                                Colors.transparent
                              ],
                            ),
                          ),
                          padding: const EdgeInsets.all(8.0),
                          child: Text(
                            album.name,
                            style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold),
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
    if (_scrollController.offset >=
            _scrollController.position.maxScrollExtent &&
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

    final List<AssetEntity> photos =
        await widget.album.getAssetListPaged(page: 0, size: _pageSize);
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

    final List<AssetEntity> morePhotos = await widget.album
        .getAssetListPaged(page: _currentPage, size: _pageSize);
    _groupPhotos(morePhotos);
    setState(() {
      _photos.addAll(morePhotos);
      _isLoading = false;
      _currentPage++;
    });
  }

  void _groupPhotos(List<AssetEntity> photos) {
    for (var photo in photos) {
      final String date =
          DateFormat('dd MMMM yyyy').format(photo.createDateTime);
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
    final Uint8List? thumbnail =
        await photo.thumbnailDataWithSize(const ThumbnailSize(200, 200));
    _thumbnailCache[cacheKey] = thumbnail;
    return thumbnail;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        title: Text(widget.album.name,
            style:
                GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.w600)),
        iconTheme: const IconThemeData(color: Colors.black),
        actions: [
          TextButton(
            onPressed: _selectAll,
            child: Text(
              _selectedPhotos.length == _photos.length
                  ? "Batalkan Pilih"
                  : "Pilih Semua",
              style: GoogleFonts.poppins(
                  color: Colors.green,
                  fontWeight: FontWeight.w600,
                  fontSize: 12),
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
                  style: GoogleFonts.poppins(
                    color: Colors.black,
                    fontWeight: FontWeight.w500,
                    fontSize: 15,
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
          children: [
            Expanded(
              child: Text(
                '${_selectedPhotos.length} foto dipilih',
                style: GoogleFonts.poppins(
                    fontSize: 14, fontWeight: FontWeight.w500),
              ),
            ),
            ElevatedButton(
              onPressed: _selectedPhotos.isEmpty
                  ? null
                  : () => _navigateToPreview(_selectedPhotos.toList()),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30)),
              ),
              child: Text(
                "Proses",
                style: GoogleFonts.poppins(
                    fontSize: 16, fontWeight: FontWeight.w500),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
