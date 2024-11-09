import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'dart:io';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final cameras = await availableCameras();
  runApp(MyApp(cameras));
}

class MyApp extends StatelessWidget {
  final List<CameraDescription> cameras;

  MyApp(this.cameras);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Photo Upload App',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: PhotoUploadScreen(cameras),
    );
  }
}

class PhotoUploadScreen extends StatefulWidget {
  final List<CameraDescription> cameras;

  PhotoUploadScreen(this.cameras);

  @override
  _PhotoUploadScreenState createState() => _PhotoUploadScreenState();
}

class _PhotoUploadScreenState extends State<PhotoUploadScreen> {
  late CameraController _controller;
  late Future<void> _initializeControllerFuture;
  File? _image;
  final TextEditingController _commentController = TextEditingController();
  bool _isPreviewing = false;

  @override
  void initState() {
    super.initState();
    _controller = CameraController(
      widget.cameras[0],
      ResolutionPreset.high,
    );
    _initializeControllerFuture = _controller.initialize();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _takePicture() async {
    await _initializeControllerFuture;
    final image = await _controller.takePicture();
    setState(() {
      _image = File(image.path);
      _isPreviewing = true;
    });
  }

  Future<void> _uploadPhoto() async {
    if (_image == null) return;

    LocationPermission permission = await Geolocator.requestPermission();
    if (permission == LocationPermission.denied) return;

    Position position = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
    double latitude = position.latitude;
    double longitude = position.longitude;

    var request = http.MultipartRequest(
      'POST',
      Uri.parse('https://flutter-sandbox.free.beeceptor.com/upload_photo/'),
    );

    request.fields['comment'] = _commentController.text;
    request.fields['latitude'] = latitude.toString();
    request.fields['longitude'] = longitude.toString();
    request.files.add(await http.MultipartFile.fromPath('photo', _image!.path));

    request.send().then((response) {
      if (response.statusCode == 200) {
        print("Photo uploaded successfully");
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Photo uploaded successfully')));
      } else {
        print("Failed to upload photo");
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to upload photo')));
      }
    }).catchError((error) {
      print("Error uploading photo: $error");
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error uploading photo')));
    });

    setState(() {
      _isPreviewing = false;
      _image = null;
      _commentController.clear();
    });
  }

  void _cancelPreview() {
    setState(() {
      _isPreviewing = false;
      _image = null;
      _commentController.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Upload Photo'),
      ),
      body: FutureBuilder<void>(
        future: _initializeControllerFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.done) {
            return SingleChildScrollView(
              child: Column(
                children: [
                  _isPreviewing
                      ? Column(
                          children: [
                            Image.file(
                              _image!,
                              height: 300, 
                              width: double.infinity,
                              fit: BoxFit.cover,
                            ),
                            Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: TextField(
                                controller: _commentController,
                                decoration: InputDecoration(labelText: 'Comment'),
                              ),
                            ),
                            SizedBox(height: 20),
                            ElevatedButton(
                              onPressed: _uploadPhoto,
                              child: Text('Upload Photo'),
                            ),
                            ElevatedButton(
                              onPressed: _cancelPreview,
                              child: Text('Retake Picture'),
                            ),
                          ],
                        )
                      : Column(
                          children: [
                            AspectRatio(
                              aspectRatio: 1 / 1,
                              child: CameraPreview(_controller),
                            ),
                            ElevatedButton(
                              onPressed: _takePicture,
                              child: Text('Take Picture'),
                            ),
                          ],
                        ),
                ],
              ),
            );
          } else {
            return Center(child: CircularProgressIndicator());
          }
        },
      ),
    );
  }
}
