// ignore_for_file: use_build_context_synchronously

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';
import 'package:monforilens/ui/screens/preview.dart';
import 'package:monforilens/ui/screens/process_photo.dart';
import 'package:photo_manager/photo_manager.dart';

class SelectPhoto extends StatefulWidget {
  const SelectPhoto({super.key});

  @override
  State<SelectPhoto> createState() => _SelectPhotoState();
}

class _SelectPhotoState extends State<SelectPhoto> {
  List<AssetEntity> _photos = [];
  final Map<String, List<AssetEntity>> _groupedPhotos = {};
  final ScrollController _scrollController = ScrollController();
  bool _isLoading = false;
  int _currentPage = 0;
  final int _pageSize = 100;
  final ValueNotifier<Set<AssetEntity>> _selectedPhotos = ValueNotifier<Set<AssetEntity>>({});
  final Map<String, Uint8List?> _thumbnailCache = {};

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
    _selectedPhotos.dispose();
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

  Future<void> _processAndNavigate() async {
    final progressController = StreamController<double>();

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ProcessScreen(progressStream: progressController.stream),
      ),
    );

    try {
      List<AssetEntity> sortedPhotos = await compute(_sortPhotos, _selectedPhotos.value.toList());

      for (int i = 0; i < sortedPhotos.length; i++) {
        progressController.add((i + 1) / sortedPhotos.length);
        await Future.delayed(const Duration(milliseconds: 1));
      }

      await progressController.close();

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => Preview(sortedPhotos: sortedPhotos)),
      );
    } catch (e) {
      await progressController.close();
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error processing photos: $e')),
      );
    }
  }

  static List<AssetEntity> _sortPhotos(List<AssetEntity> selectedPhotos) {
    selectedPhotos.sort((a, b) => a.createDateTime.compareTo(b.createDateTime));
    return selectedPhotos;
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
                onPressed: selectedPhotos.isEmpty ? null : _processAndNavigate,
                child: Text(
                  "Next (${selectedPhotos.length})",
                  style: TextStyle(color: selectedPhotos.isEmpty ? Colors.grey : Colors.white),
                ),
              );
            },
          ),
        ],
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
                        final photo = photos[photoIndex];
                        return FutureBuilder<Uint8List?>(
                          future: _getThumbnail(photo),
                          builder: (context, snapshot) {
                            if (snapshot.connectionState == ConnectionState.done && snapshot.data != null) {
                              return ValueListenableBuilder<Set<AssetEntity>>(
                                valueListenable: _selectedPhotos,
                                builder: (context, selectedPhotos, child) {
                                  final isSelected = selectedPhotos.contains(photo);
                                  return GestureDetector(
                                    onTap: () => _selectPhoto(photo),
                                    child: Stack(
                                      fit: StackFit.expand,
                                      children: [
                                        Image.memory(snapshot.data!, fit: BoxFit.cover),
                                        AnimatedSwitcher(
                                          duration: const Duration(milliseconds: 200),
                                          child: isSelected
                                              ? Container(
                                                  key: ValueKey(photo),
                                                  color: Colors.blue.withOpacity(0.5),
                                                  child: const Icon(Icons.check, color: Colors.white),
                                                )
                                              : const SizedBox.shrink(),
                                        ),
                                      ],
                                    ),
                                  );
                                },
                              );
                            } else {
                              return const Center(child: CircularProgressIndicator());
                            }
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