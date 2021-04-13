import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_list/image_list.dart';
import 'package:image_list/plugin.dart';

void main() => runApp(MyApp());

class MyApp extends StatefulWidget {
  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  List<Album>? albums;
  ImageListController? controller;
  Album? currentAlbum;
  List<ImageData>? _selections;
  bool multipleMode = false;
  bool initialized = false;

  @override
  void initState() {
    super.initState();
    print("ImageListPlugin.getAlbums()");

    ImageListPlugin.getAlbums().then((albums) {
      print("albums => $albums");
      if (this.mounted)
        setState(() {
          this.initialized = true;
          this.albums = albums;
          if (this.albums != null && this.albums!.isNotEmpty)
            this.currentAlbum = albums.first;
        });
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(home: Builder(
      builder: (BuildContext context) {
        return Scaffold(
          appBar: AppBar(
            title: const Text('Image List Example'),
          ),
          body: !initialized
              ? Center(child: CircularProgressIndicator())
              : albums == null
              ? Center(child: Text('Could not load images'))
              : Column(
                  children: [
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
                        items:
                            albums!.map<DropdownMenuItem<Album>>((Album value) {
                          return DropdownMenuItem<Album>(
                            value: value,
                            child: Container(
                              width: MediaQuery.of(context).size.width - 100,
                              child: Text(value.name, maxLines: 2),
                            ),
                          );
                        }).toList(),
                      ),
                    TextButton(
                      child: Text(multipleMode ? "Set Single" : "Set Multiple"),
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
                        maxImages: 1,
                        albumId: currentAlbum?.identifier ?? "",
                        onImageTapped: (count) {
                          print("onImageTapped => $count");
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
                        onPressed: () {
                          if (this.controller != null)
                            this.controller!.getSelectedImage().then((res) {
                              if (res == null) return;

                              File f = File(res.first.assetId!);

                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (BuildContext context) {
                                    return ResultPreviewPage(file: f);
                                  },
                                ),
                              );
                            });
                        },
                      ),
                    )
                  ],
                ),
        );
      },
    ));
  }
}

class ResultPreviewPage extends StatelessWidget {
  final File file;

  const ResultPreviewPage({Key? key, required this.file}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(title: Text("Result")),
        body: Center(child: Image.file(file)));
  }
}
