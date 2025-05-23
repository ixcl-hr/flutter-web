// main.dart
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:image_picker/image_picker.dart';
import 'package:image_picker_for_web/image_picker_for_web.dart'
    show ImagePickerPlugin;
import 'package:qr_flutter/qr_flutter.dart';
import 'package:file_picker/file_picker.dart';
import 'package:web_browser_detect/web_browser_detect.dart';
import 'package:universal_html/html.dart' as html;
// import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:qr_code_scanner/qr_code_scanner.dart';
import 'package:wecheck_web_2025_01/main.dart';

import 'widget/QRScanner.dart';
import 'widget/TakeCamera.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'We Check',
      theme: ThemeData(
        primarySwatch: Colors.orange,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: const HomePage(),
      routes: {
        '/qr_scanner': (context) => const QRScannerApp(),
        '/take_camera': (context) => const Takecamera(),
      },
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  String qrText = "No QR code scanned";
  String locationData = "Location not determined";
  String fileData = "No file selected";
  String imageData = "No image captured";
  Uint8List? imageBytes;

  @override
  void initState() {
    super.initState();
    _checkWebCompatibility();
  }

  void _checkWebCompatibility() async {
    final browser = Browser();
    String browserWarning = '';
    final currentUrl = html.window.location.href;

    // if (!browser..isChrome() && !browser.isFirefox() && !browser.isEdge()) {
    //   browserWarning =
    //       'For best experience, use Chrome, Firefox, or Edge browsers.';
    // }
    browserWarning = currentUrl;

    if (browserWarning.isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(browserWarning),
            duration: const Duration(seconds: 5),
          ),
        );
      });
    }
  }

  Future<void> _getLocation() async {
    setState(() {
      locationData = "Requesting location...";
    });

    try {
      // For web, we need to explicitly request permission

      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        setState(() {
          locationData = "Location services are disabled.";
        });
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          setState(() {
            locationData =
                "Location permission denied. Please enable it in your settings.";
          });
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        setState(() {
          locationData =
              "Location permissions permanently denied. Please enable in settings.";
        });
        return;
      }

      // Get current position
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      setState(() {
        locationData =
            "Latitude: ${position.latitude}, Longitude: ${position.longitude}";
      });
    } catch (e) {
      setState(() {
        locationData = "Error getting location: $e";
      });
    }
  }

  Future<void> _pickFile() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles();

      if (result != null) {
        setState(() {
          fileData =
              "Selected file: ${result.files.single.name}, Size: ${(result.files.single.size / 1024).toStringAsFixed(2)} KB";
        });
      }
    } catch (e) {
      setState(() {
        fileData = "Error picking file: $e";
      });
    }
  }

  Future<void> _takePicture() async {
    try {
      final ImagePicker picker = ImagePicker();

      // For web, we need to explicitly set camera facing mode and enable camera access
      // if (kIsWeb) {
      //   setState(() {
      //     imageData =
      //         "Opening camera... Please allow camera access if prompted.";
      //   });
      // }

      XFile? photo;

      try {
        photo = await ImagePickerPlugin().getImage(
          source: ImageSource.camera,
          //preferredCameraDevice: CameraDevice.front,
        );
      } catch (e) {
        setState(() {
          imageData = "Error accessing camera: $e";
          AlertDialog(
            title: const Text('Camera Access Denied'),
            content: Text(imageData),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                },
                child: const Text('OK'),
              ),
            ],
          );
        });
      }

      final Image image;
      image = Image.network(photo!.path);

      if (photo != null) {
        Image.network(photo.path);
        final bytes = await photo.readAsBytes();
        setState(() {
          imageData = "Image captured: ${photo!.name}";
          imageBytes = bytes;
        });
      } else {
        setState(() {
          imageData = "No image selected or camera access denied";
        });
      }
    } catch (e) {
      setState(() {
        imageData = "Error capturing image: $e";
      });
    }
  }

  void _scanQR() {
    // For web, provide alternative solution
    // Show an info dialog explaining browser limitations
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('QR Code Scanning on Web'),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
                'QR scanning on web has limitations due to browser security. Options:'),
            SizedBox(height: 10),
            Text('1. Upload a QR code image'),
            Text('2. Allow camera access when prompted'),
            // Text('3. For best experience, try Chrome or Edge')
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _pickImageQR();
            },
            child: const Text('Upload QR Image'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _attemptCameraQR();
            },
            child: const Text('Try Camera'),
          ),
        ],
      ),
    );
  }

  void _attemptCameraQR() {
    Navigator.pushNamed(context, '/qr_scanner').then((value) {
      if (value != null) {
        setState(() {
          qrText = value.toString();
        });
      }
    });
  }

  void _pickImageQR() async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? pickedFile = await picker.pickImage(
        source: ImageSource.gallery,
      );

      if (pickedFile != null) {
        // Show a success message but note that actual QR parsing from image
        // requires additional libraries in a real implementation
        setState(() {
          qrText = "QR code from image would be processed here";
        });
      }
    } catch (e) {
      setState(() {
        qrText = "Error processing QR from image: $e";
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('We Check'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              margin: const EdgeInsets.only(bottom: 16),
              color: Colors.amber.shade100,
              child: Text(
                html.window.location.href,
                style: const TextStyle(fontSize: 14),
              ),
            ),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text("Location",
                        style: TextStyle(
                            fontSize: 18, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    Text(locationData),
                    const SizedBox(height: 8),
                    ElevatedButton(
                      onPressed: _getLocation,
                      child: const Text("Get Location"),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text("QR Code Scanner",
                        style: TextStyle(
                            fontSize: 18, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    Text(qrText),
                    const SizedBox(height: 8),
                    ElevatedButton(
                      onPressed: _scanQR,
                      child: const Text("Scan QR Code"),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text("File Upload",
                        style: TextStyle(
                            fontSize: 18, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    Text(fileData),
                    const SizedBox(height: 8),
                    ElevatedButton(
                      onPressed: _pickFile,
                      child: const Text("Upload File"),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text("CameraNew",
                        style: TextStyle(
                            fontSize: 18, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    Text(imageData),
                    if (imageBytes != null)
                      Image.memory(imageBytes!, height: 200),
                    const SizedBox(height: 8),
                    ElevatedButton(
                      onPressed: () {
                        Navigator.pushNamed(context, '/take_camera')
                            .then((value) {
                          if (value != null) {
                            setState(() {
                              qrText = value.toString();
                            });
                          }
                        });
                      },
                      child: const Text("Take Picture"),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text("Camera",
                        style: TextStyle(
                            fontSize: 18, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    Text(imageData),
                    if (imageBytes != null)
                      Image.memory(imageBytes!, height: 200),
                    const SizedBox(height: 8),
                    ElevatedButton(
                      onPressed: _takePicture,
                      child: const Text("Take Picture"),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
