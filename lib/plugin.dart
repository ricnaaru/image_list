import 'package:flutter/services.dart';

class ImageListPlugin {
  static const MethodChannel _channel = const MethodChannel('image_list');

  static Future<dynamic> getAlbums() async {
    final List<dynamic> images = await _channel.invokeMethod('getAlbums');
    List<Album> albums = List<Album>();
    for (var element in images) {
      albums.add(Album.fromJson(element));
    }
    return albums;
  }
}

class Album {
  final String name;
  final String identifier;

  Album(this.name, this.identifier);

  factory Album.fromJson(Map<dynamic, dynamic> raw) {
    return Album(raw["name"], raw["identifier"]);
  }

  Album copyWith({
    String name, String identifier,
  }) {
    return Album(
      name ?? this.name,
      identifier ?? this.identifier,
    );
  }

  @override
  String toString() {
    return "Album(name: $name, identifier: $identifier)";
  }


}