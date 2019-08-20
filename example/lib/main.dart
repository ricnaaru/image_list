import 'package:flutter/material.dart';
import 'dart:async';

import 'package:flutter/services.dart';
import 'package:image_list/plugin.dart';
import 'package:image_list/image_list.dart';

void main() => runApp(MyApp());

class MyApp extends StatefulWidget {
  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  List<Album> albums;
  ImageListController controller;
  Album currentAlbum;
  List<ImageData> _selections;
  bool multipleMode = false;

  @override
  void initState() {
    super.initState();
    ImageListPlugin.getAlbums().then((albums) {
      setState(() {
        this.albums = albums;
        this.currentAlbum = albums.first;
      });
    });
//    initPlatformState();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          title: const Text('Plugin example app'),
        ),
        body: albums == null
            ? Center(child: CircularProgressIndicator())
            : Column(
                children: [
                  DropdownButton<Album>(
                    value: currentAlbum,
                    onChanged: (Album newAlbum) {
                      this.currentAlbum = newAlbum;
                      setState(() {
                        this.controller.reloadAlbum(currentAlbum.identifier);
                      });
                    },
                    items: albums.map<DropdownMenuItem<Album>>((Album value) {
                      return DropdownMenuItem<Album>(
                        value: value,
                        child: Text(value.name),
                      );
                    }).toList(),
                  ),
                  FlatButton(
                    child: Text(multipleMode ? "Set Single" : "Set Multiple"),
                    onPressed: () {
                      setState(() {
                        multipleMode = !multipleMode;
                        if (this.controller != null) this.controller.setMaxImage(multipleMode ? null : 1);
                      });
                    },
                  ),
                  Expanded(
                    child: InkWell(
                      child: ImageList(
                        maxImages: 1,
                        albumId: currentAlbum?.identifier,
                        onImageTapped: (count) {
                          print("onImageTapped => $count");
                        },
                        onListCreated: (controller) {
                          this.controller = controller;
                        },
                        selections: _selections,
                      ),
                      onTap: () {
                        print("aduh di tap");
                      },
                    ),
                  ),
                  Padding(
                    child: FlatButton(
                      child: Text("Submit"),
                      onPressed: () {
                        this.controller.getSelectedImage().then((res) {
                          print("res => ${res.runtimeType}");
//                          _selections = res.map((map) {
//                            return ImageData.fromJson(map);
//                          }).toList();
                        });
                      },
                    ),
                    padding: EdgeInsets.all(16.0),
                  )
                ],
              ),
      ),
    );
  }
}
