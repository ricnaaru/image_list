import 'dart:typed_data';

import 'package:image_list/data/media.dart';

class ImageData extends MediaData {
  ImageData({
    required String? albumId,
    required String assetId,
    required String? uri,
    required Uint8List? imageData,
  }) : super(
          albumId: albumId,
          assetId: assetId,
          uri: uri,
          type: MediaType.image,
          imageData: imageData,
        );

  static ImageData fromJson(Map json) {
    return ImageData(
      albumId: json['albumId'] as String?,
      assetId: json['assetId'] as String,
      uri: json['uri'] as String?,
      imageData: json['imageData'] as Uint8List?,
    );
  }
}
