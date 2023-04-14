import 'dart:typed_data';

import 'package:image_list/data/image.dart';
import 'package:image_list/data/video.dart';

enum MediaType { image, video }

class MediaData {
  final String? albumId;
  final String assetId;
  final MediaType type;
  final String? uri;
  final Uint8List? imageData;

  MediaData({
    required this.albumId,
    required this.assetId,
    required this.uri,
    required this.type,
    required this.imageData,
  });

  Map toMap() {
    return {
      "albumId": albumId,
      "assetId": assetId,
      "type": type == MediaType.image ? "IMAGE" : "VIDEO",
      "uri": uri,
      "imageData": imageData,
    };
  }

  static MediaData fromJson(Map json) {
    String? type = json['type'] as String?;

    if (type == "IMAGE") {
      return ImageData.fromJson(json);
    } else {
      return VideoData.fromJson(json);
    }
  }
}
