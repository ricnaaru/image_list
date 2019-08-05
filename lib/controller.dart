// Copyright 2018 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

part of image_list;

/// Controller for a single GoogleMap instance running on the host platform.
class ImageListController {
  ImageListController._(
      this.channel,
      this._imageListState,
      ) : assert(channel != null) {
    channel.setMethodCallHandler(_handleMethodCall);
  }

  static Future<ImageListController> init(
      int id,
      _ImageListState imageListState,
      ) async {
    assert(id != null);
    final MethodChannel channel =
    MethodChannel('plugins.flutter.io/image_list/$id');
    // TODO(amirh): remove this on when the invokeMethod update makes it to stable Flutter.
    // https://github.com/flutter/flutter/issues/26431
    // ignore: strong_mode_implicit_dynamic_method
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
        _imageListState.onImageTapped(count ?? 0);
        break;
      default:
        throw MissingPluginException();
    }
  }

  /// Reload album with same / different albumName
  ///
  /// The returned [Future] completes after the change has been started on the
  /// platform side.
  Future<void> reloadAlbum(String albumName) async {
    // TODO(amirh): remove this on when the invokeMethod update makes it to stable Flutter.
    // https://github.com/flutter/flutter/issues/26431
    // ignore: strong_mode_implicit_dynamic_method
    await channel.invokeMethod('reloadAlbum', <String, dynamic>{
      'albumName': albumName,
    });
  }
}
