// ignore_for_file: library_private_types_in_public_api, use_build_context_synchronously

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:monforilens/ui/screens/view_photo.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';

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
  Set<AssetEntity> _selectedPhotos = {};
  bool _isSelectionMode = false;

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

  void _togglePhotoSelection(AssetEntity photo) {
    setState(() {
      if (_selectedPhotos.contains(photo)) {
        _selectedPhotos.remove(photo);
      } else {
        _selectedPhotos.add(photo);
      }
      _isSelectionMode = _selectedPhotos.isNotEmpty;
    });
  }

  void _selectAllPhotos() {
    setState(() {
      _selectedPhotos = Set.from(_photos);
      _isSelectionMode = true;
    });
  }

  void _deselectAllPhotos() {
    setState(() {
      _selectedPhotos.clear();
      _isSelectionMode = false;
    });
  }

  Future<void> _shareSelectedPhotos() async {
    final files = await Future.wait(_selectedPhotos.map((photo) => photo.file));
    final xFiles = files.whereType<File>().map((file) => XFile(file.path)).toList();
    await Share.shareXFiles(xFiles);
  }

  Future<void> _deleteSelectedPhotos() async {
    final result = await PhotoManager.editor.deleteWithIds(_selectedPhotos.map((p) => p.id).toList());
    if (result.isNotEmpty) {
      setState(() {
        _photos.removeWhere((p) => _selectedPhotos.contains(p));
        _groupedPhotos.forEach((date, photos) {
          photos.removeWhere((p) => _selectedPhotos.contains(p));
        });
        _groupedPhotos.removeWhere((date, photos) => photos.isEmpty);
        _selectedPhotos.clear();
        _isSelectionMode = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Selected photos deleted successfully')),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to delete selected photos')),
      );
    }
  }

  void _openPhotoDetail(AssetEntity photo, int index, List<AssetEntity> photos) {
    if (_isSelectionMode) {
      _togglePhotoSelection(photo);
    } else {
      List<AssetEntity> allPhotos = _getAllPhotos();
      int overallIndex = allPhotos.indexOf(photo);

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ViewPhotoScreen(
            photoList: allPhotos,
            initialIndex: overallIndex,
          ),
        ),
      );
    }
  }

  List<AssetEntity> _getAllPhotos() {
    List<AssetEntity> allPhotos = [];
    for (var photos in _groupedPhotos.values) {
      allPhotos.addAll(photos);
    }
    return allPhotos;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white70,
        title: Text(_isSelectionMode ? '${_selectedPhotos.length} selected' : widget.album.name, 
                    style: const TextStyle(color: Colors.black)),
        iconTheme: const IconThemeData(color: Colors.black),
        actions: _isSelectionMode
            ? [
                IconButton(
                  icon: const Icon(Icons.share),
                  onPressed: _shareSelectedPhotos,
                ),
                IconButton(
                  icon: const Icon(Icons.delete),
                  onPressed: _deleteSelectedPhotos,
                ),
                IconButton(
                  icon: const Icon(Icons.select_all),
                  onPressed: _selectAllPhotos,
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: _deselectAllPhotos,
                ),
              ]
            : null,
      ),
      body: _isLoading && _photos.isEmpty
          ? const Center(child: CircularProgressIndicator(color: Colors.black))
          : ListView.builder(
              controller: _scrollController,
              itemCount: _groupedPhotos.length + (_isLoading ? 1 : 0),
              itemBuilder: (context, index) {
                if (index == _groupedPhotos.length) {
                  return const Center(
                    child: Padding(
                      padding: EdgeInsets.all(8.0),
                      child: CircularProgressIndicator(color: Colors.black),
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
                        return GestureDetector(
                          onTap: () => _openPhotoDetail(photo, photoIndex, photos),
                          onLongPress: () => _togglePhotoSelection(photo),
                          child: Stack(
                            fit: StackFit.expand,
                            children: [
                              FutureBuilder<Uint8List?>(
                                future: photo.thumbnailDataWithSize(const ThumbnailSize(200, 200)),
                                builder: (context, snapshot) {
                                  if (snapshot.connectionState == ConnectionState.done && snapshot.data != null) {
                                    return Image.memory(snapshot.data!, fit: BoxFit.cover);
                                  }
                                  return Container(color: Colors.grey[800]);
                                },
                              ),
                              if (_selectedPhotos.contains(photo))
                                Positioned.fill(
                                  child: Container(
                                    color: Colors.white.withOpacity(0.7),
                                    child: const Icon(Icons.check, color: Colors.green),
                                  ),
                                ),
                            ],
                          ),
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