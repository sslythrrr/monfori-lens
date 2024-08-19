import 'package:flutter/material.dart';
import 'package:monforilens/models/media.dart';
import 'package:monforilens/ui/components/media_item.dart';

class MediasGridView extends StatelessWidget {
  final List<Media> medias;
  final List<Media> selectedMedias;
  final Function(Media) selectMedia;
  final ScrollController scrollController;
  final Function(Media) onTap;

  const MediasGridView({
    super.key,
    required this.medias,
    required this.selectedMedias,
    required this.selectMedia,
    required this.scrollController,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 3.0),
      child: GridView.builder(
        controller: scrollController,
        physics: const BouncingScrollPhysics(),
        itemCount: medias.length,
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3,
          mainAxisSpacing: 3,
          crossAxisSpacing: 3,
        ),
        itemBuilder: (context, index) => GestureDetector(
          onTap: () => onTap(medias[index]),
          child: MediaItem(
            media: medias[index],
            isSelected: selectedMedias.any((element) =>
                element.assetEntity.id == medias[index].assetEntity.id),
            selectMedia: selectMedia,
          ),
        ),
      ),
    );
  }
}