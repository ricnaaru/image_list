library image_list;

import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

part 'controller.dart';

typedef void ListCreatedCallback(ImageListController controller);
typedef void ImageTappedCallback(int count);

class ImageList extends StatefulWidget {
  final String albumId;
  final int maxImages;
  final List<ImageData> selections;
  final ListCreatedCallback onListCreated;
  final ImageTappedCallback onImageTapped;

  ImageList({this.albumId, this.maxImages, this.selections, this.onListCreated, this.onImageTapped});

  @override
  _ImageListState createState() => _ImageListState();
}

class _ImageListState extends State<ImageList> {
  Set<Factory<OneSequenceGestureRecognizer>> gestureRecognizers;

  @override
  Widget build(BuildContext context) {
    final Map<String, dynamic> creationParams = <String, dynamic>{
      "albumId": widget.albumId ?? "",
      "maxImage": widget.maxImages,
      "selections": widget.selections == null ? null : widget.selections.map((imageData) => imageData.toMap()).toList(),
    };

    if (defaultTargetPlatform == TargetPlatform.android) {
      return AndroidView(
        viewType: 'plugins.flutter.io/image_list',
        onPlatformViewCreated: onPlatformViewCreated,
        gestureRecognizers: gestureRecognizers,
        creationParams: creationParams,
        creationParamsCodec: const StandardMessageCodec(),
      );
    } else if (defaultTargetPlatform == TargetPlatform.iOS) {
      return UiKitView(
        viewType: 'plugins.flutter.io/image_list',
        onPlatformViewCreated: onPlatformViewCreated,
        gestureRecognizers: gestureRecognizers,
        creationParams: creationParams,
        creationParamsCodec: const StandardMessageCodec(),
      );
    }
  }

  Future<void> onPlatformViewCreated(int id) async {
    final ImageListController controller = await ImageListController.init(
      id,
      this,
    );

    if (widget.onListCreated != null) {
      widget.onListCreated(controller);
    }
  }

  void onImageTapped(int count) {
    if (widget.onImageTapped != null) {
      widget.onImageTapped(count);
    }
  }
}
