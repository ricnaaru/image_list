import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_list/data/media.dart';
import 'package:image_list/image_list.dart';
import 'package:image_list/plugin.dart';
import 'package:image_list_example/image_preview.dart';
import 'package:image_list_example/video_preview.dart';

void main() => runApp(MyApp());

class MyApp extends StatefulWidget {
  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  List<Album>? albums;
  ImageListController? controller;
  Album? currentAlbum;
  List<MediaData>? _selections;
  bool multipleMode = false;
  bool loading = true;
  List<MediaType> types = <MediaType>[MediaType.image, MediaType.video];

  @override
  void initState() {
    super.initState();
    getAlbums();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(home: Builder(
      builder: (BuildContext context) {
        return Scaffold(
          appBar: AppBar(
            title: const Text('Image List Example'),
          ),
          body: loading
              ? Center(child: CircularProgressIndicator())
              : albums == null
                  ? Center(child: Text('Could not load images'))
                  : Column(
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: CheckboxListTile(
                                title: Text("Get Images"),
                                value: types.contains(MediaType.image),
                                onChanged: (newValue) {
                                  setState(() {
                                    loading = true;
                                    if (types.contains(MediaType.image))
                                      types.remove(MediaType.image);
                                    else
                                      types.add(MediaType.image);

                                    getAlbums();
                                  });
                                },
                                controlAffinity: ListTileControlAffinity
                                    .leading, //  <-- leading Checkbox
                              ),
                            ),
                            Expanded(
                              child: CheckboxListTile(
                                title: Text("Get Videos"),
                                value: types.contains(MediaType.video),
                                onChanged: (newValue) {
                                  setState(() {
                                    loading = true;
                                    if (types.contains(MediaType.video))
                                      types.remove(MediaType.video);
                                    else
                                      types.add(MediaType.video);

                                    getAlbums();
                                  });
                                },
                                controlAffinity: ListTileControlAffinity
                                    .leading, //  <-- leading Checkbox
                              ),
                            ),
                          ],
                        ),
                        if (currentAlbum != null)
                          DropdownButton<Album>(
                            value: currentAlbum,
                            onChanged: (Album? newAlbum) {
                              this.currentAlbum = newAlbum;
                              setState(() {
                                if (controller != null && currentAlbum != null)
                                  this
                                      .controller!
                                      .reloadAlbum(currentAlbum!.identifier);
                              });
                            },
                            items: albums!
                                .map<DropdownMenuItem<Album>>((Album value) {
                              return DropdownMenuItem<Album>(
                                value: value,
                                child: Container(
                                  width:
                                      MediaQuery.of(context).size.width - 100,
                                  child: Text("${value.name} (${value.count})",
                                      maxLines: 2),
                                ),
                              );
                            }).toList(),
                          ),
                        TextButton(
                          child: Text(
                              multipleMode ? "Set Single" : "Set Multiple"),
                          onPressed: () {
                            setState(() {
                              multipleMode = !multipleMode;
                              if (this.controller != null)
                                this
                                    .controller!
                                    .setMaxImage(multipleMode ? null : 1);
                            });
                          },
                        ),
                        Expanded(
                          child: ImageList(
                            types: types,
                            maxImages: 1,
                            albumId: currentAlbum?.identifier ?? "",
                            onImageTapped: (count, selectedMedias) {
                              if (!multipleMode) {
                                submit(context);
                              }
                            },
                            onListCreated: (controller) {
                              this.controller = controller;
                            },
                            selections: _selections,
                            fileNamePrefix: "AdvImageExample",
                          ),
                        ),
                        Padding(
                          padding: EdgeInsets.all(16.0),
                          child: TextButton(
                            child: Text("Submit"),
                            onPressed: () => submit(context),
                          ),
                        )
                      ],
                    ),
        );
      },
    ));
  }

  Future<void> submit(BuildContext context) async {
    if (this.controller != null)
      this.controller!.getSelectedMedia().then((res) {
        if (res == null) return;

        ImageListPlugin.getThumbnail(size: 100, imageUri: res.first.uri!).then((value) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (BuildContext context) {
                return Scaffold(
                  appBar: AppBar(
                    title: Text("lalala"),
                  ),
                  body: Center(child: Image.memory(value)),
                );
              },
            ),
          );
        });

        // File f = File(res.first.assetId);
        // late Widget preview;
        //
        // if (res.first.type == MediaType.video) {
        //   preview = VideoPreview(videoFile: f);
        // } else {
        //   preview = ImagePreview(file: f);
        // }
        //
        // Navigator.push(
        //   context,
        //   MaterialPageRoute(
        //     builder: (BuildContext context) {
        //       return preview;
        //     },
        //   ),
        // );
      });
  }

  void getAlbums() {
    ImageListPlugin.getAlbums(types: types).then((albums) {
      if (this.mounted)
        setState(() {
          this.loading = false;
          this.albums = albums;
          if (this.albums != null && this.albums!.isNotEmpty)
            this.currentAlbum = albums.first;
          if (controller != null && currentAlbum != null)
            this.controller!.reloadAlbum(currentAlbum!.identifier);
        });
    });
  }
}
