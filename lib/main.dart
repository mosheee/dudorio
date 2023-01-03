import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    print('in build');
    return MaterialApp(
      theme: ThemeData.dark(),
      home: const MyHomePage(),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key});
  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  late Timer timer;
  var imageData = [];
  final String getLocalBlobsURLs = 'http://localhost:4000/blobs';
  final String getpublicBlobsURLs = 'https://macamv3.azurewebsites.net/blob';

  Future getBlobsMetadata() async {
    final blobs = await http.get(Uri.parse(getpublicBlobsURLs));
    final blobsDecode = json.decode(blobs.body);
    return blobsDecode;
  }

  httpInLoop() async {
    List newDetections = await getBlobsMetadata();
    if (newDetections.isNotEmpty) {
      imageData = imageData + newDetections;
      setState(() {});
    }
  }

  void startTimer() {
    timer = Timer.periodic(
        const Duration(milliseconds: 500), (timer) => httpInLoop());
  }

  @override
  void initState() {
    super.initState();
    startTimer();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: const Text(
          "דמו - מכם אלקטרו אופטי",
          style: TextStyle(
              fontSize: 30, letterSpacing: 5, fontWeight: FontWeight.bold),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 80, vertical: 40),
        child: Center(
            child: GridView.count(
          crossAxisCount: 3,
          primary: false,
          mainAxisSpacing: 250,
          crossAxisSpacing: 250,
          children: imageData
              .map((data) => Detect(
                  imageName: data['name'],
                  lan: data['lan'],
                  lat: data['lat'],
                  type: data['type']))
              .toList(),
        )),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          List newDetections = await getBlobsMetadata();
          if (newDetections.isNotEmpty) {
            imageData = imageData + newDetections;
            setState(() {});
          }
        },
        tooltip: 'Increment',
        child: const Icon(Icons.add),
      ), // This trailing comma makes auto-formatting nicer for build methods.
    );
  }
}

class Detect extends StatefulWidget {
  final String type;
  final String lan;
  final String lat;
  final String imageName;
  const Detect(
      {super.key,
      required this.imageName,
      required this.lan,
      required this.lat,
      required this.type});

  @override
  State<Detect> createState() => _DetectState();
}

class _DetectState extends State<Detect> {
  bool tap = false;

  Future<Uint8List> clickOnLocation(String imageName) async {
    Uint8List imageData = await _downloadImage(imageName);
    // final response = await deleteDetectionFromBlobStorage(imageName);
    return imageData;
  }

  Future<Uint8List> _downloadImage(String imageName) async {
    final imageURI =
        'https://dudoriostorage.blob.core.windows.net/moshe-container/$imageName';
    var response = await http.get(Uri.parse(imageURI));
    return response.bodyBytes;
  }

  // deleteDetectionFromBlobStorage(String imageName) async{
  //   await http.post(Uri.parse('http://localhost:4000/deleteBlob?name=$imageName'));
  //   return;
  // }

  @override
  Widget build(BuildContext context) {
    return tap
        ? FutureBuilder<Uint8List>(
            future: clickOnLocation(widget.imageName),
            builder: (context, snapshot) {
              if (snapshot.hasError) {
                print(snapshot.error);
              }
              if (snapshot.hasData) {
                return Column(
                  children: [
                    Image.memory(snapshot.data!),
                    Text(widget.type),
                    Text('lan: ${widget.lan}, lat: ${widget.lat}')
                  ],
                );
              } else {
                return const Padding(
                  padding: EdgeInsets.all(120.0),
                  child: CircularProgressIndicator(),
                );
              }
            })
        : Column(
            children: [
              IconButton(
                  onPressed: () {
                    setState(() {
                      tap = true;
                    });
                  },
                  icon: const Icon(
                    Icons.location_on,
                    color: Colors.amber,
                  )),
              Text(widget.type),
              Text('lan: ${widget.lan}, lat: ${widget.lat}')
            ],
          );
  }
}
