// Copyright 2018 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

part of image_list;

/// Controller for a single GoogleMap instance running on the host platform.
class ImageListController {
  ImageListController._(
    this.channel,
    this._imageListState,
  ) {
    channel.setMethodCallHandler(_handleMethodCall);
  }

  static Future<ImageListController> init(
    int id,
    _ImageListState imageListState,
  ) async {
    final MethodChannel channel =
        MethodChannel('plugins.flutter.io/image_list/$id');

    await channel.invokeMethod('waitForList');
    return ImageListController._(
      channel,
      imageListState,
    );
  }

  @visibleForTesting
  final MethodChannel channel;

  final _ImageListState _imageListState;

  Future<dynamic> _handleMethodCall(MethodCall call) async {
    switch (call.method) {
      case 'onImageTapped':
        int count = call.arguments['count'] as int;
        _imageListState.onImageTapped(count);
        break;
      default:
        throw MissingPluginException();
    }
  }

  /// Reload album with same / different albumId
  ///
  /// The returned [Future] completes after the change has been started on the
  /// platform side.
  Future<void> reloadAlbum(String albumId) async {
    await channel.invokeMethod('reloadAlbum', <String, dynamic>{
      'albumId': albumId,
    });
  }

  Future<void> setMaxImage(int? maxImage) async {
    await channel.invokeMethod('setMaxImage', <String, dynamic>{
      'maxImage': maxImage,
    });
  }

  Future<List<MediaData>?> getSelectedMedia() async {
    List<MediaData>? result;
    List<dynamic>? raw = await channel.invokeMethod('getSelectedMedia', null);

    if (raw != null) {
      result = raw.map((map) {
        return MediaData.fromJson(map);
      }).toList();
    }
    return result;
  }
}