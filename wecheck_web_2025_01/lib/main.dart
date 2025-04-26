// main.dart
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:image_picker/image_picker.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:file_picker/file_picker.dart';
import 'package:web_browser_detect/web_browser_detect.dart';
import 'package:universal_html/html.dart' as html;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:qr_code_scanner/qr_code_scanner.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Web Features Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: const HomePage(),
      routes: {
        '/qr_scanner': (context) => const QRViewExample(),
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

  void _checkWebCompatibility() {
    if (kIsWeb) {
      final browser = Browser();
      String browserWarning = '';

      // if (!browser..isChrome() && !browser.isFirefox() && !browser.isEdge()) {
      //   browserWarning =
      //       'For best experience, use Chrome, Firefox, or Edge browsers.';
      // }

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
  }

  Future<void> _getLocation() async {
    setState(() {
      locationData = "Requesting location...";
    });

    try {
      // For web, we need to explicitly request permission
      if (kIsWeb) {
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
                  "Location permission denied. Please enable it in your browser settings.";
            });
            return;
          }
        }

        if (permission == LocationPermission.deniedForever) {
          setState(() {
            locationData =
                "Location permissions permanently denied. Please enable in browser settings.";
          });
          return;
        }
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
        if (kIsWeb) {
          setState(() {
            fileData =
                "Selected file: ${result.files.single.name}, Size: ${(result.files.single.size / 1024).toStringAsFixed(2)} KB";
          });
        } else {
          String path = result.files.single.path ?? '';
          // For non-web
          setState(() {
            fileData =
                "Selected file: ${result.files.single.name}, Path: $path";
          });
        }
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
      if (kIsWeb) {
        setState(() {
          imageData =
              "Opening camera... Please allow camera access if prompted.";
        });
      }

      final XFile? photo = await picker.pickImage(
        source: ImageSource.camera,
        preferredCameraDevice: CameraDevice.front,
      );

      if (photo != null) {
        if (kIsWeb) {
          final bytes = await photo.readAsBytes();
          setState(() {
            imageData = "Image captured: ${photo.name}";
            imageBytes = bytes;
          });
        } else {
          setState(() {
            imageData = "Image captured: ${photo.path}";
          });
        }
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
    if (kIsWeb) {
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
              Text('3. For best experience, try Chrome or Edge')
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
    } else {
      // For non-web platforms, use normal QR scanner
      Navigator.pushNamed(context, '/qr_scanner').then((value) {
        if (value != null) {
          setState(() {
            qrText = value.toString();
          });
        }
      });
    }
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
        title: const Text('Flutter Web Features Demo'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (kIsWeb)
              Container(
                padding: const EdgeInsets.all(8),
                margin: const EdgeInsets.only(bottom: 16),
                color: Colors.amber.shade100,
                child: const Text(
                  'Note: Some features might require permission grants in your browser. '
                  'For the best experience, use Chrome or Edge.',
                  style: TextStyle(fontSize: 14),
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

class QRViewExample extends StatefulWidget {
  const QRViewExample({Key? key}) : super(key: key);

  @override
  State<StatefulWidget> createState() => _QRViewExampleState();
}

class _QRViewExampleState extends State<QRViewExample> {
  Barcode? result;
  QRViewController? controller;
  final GlobalKey qrKey = GlobalKey(debugLabel: 'QR');

  // In order to get hot reload to work we need to pause the camera if the platform
  // is android, or resume the camera if the platform is iOS.
  @override
  void reassemble() {
    super.reassemble();
    if (!kIsWeb) {
      controller?.pauseCamera();
      controller?.resumeCamera();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('QR Scanner'),
      ),
      body: Column(
        children: <Widget>[
          Expanded(flex: 4, child: _buildQrView(context)),
          Expanded(
            flex: 1,
            child: FittedBox(
              fit: BoxFit.contain,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: <Widget>[
                  if (result != null)
                    Text('Data: ${result!.code}')
                  else
                    const Text('Scan a code'),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: <Widget>[
                      Container(
                        margin: const EdgeInsets.all(8),
                        child: ElevatedButton(
                          onPressed: () async {
                            await controller?.toggleFlash();
                            setState(() {});
                          },
                          child: FutureBuilder(
                            future: controller?.getFlashStatus(),
                            builder: (context, snapshot) {
                              return Text('Flash: ${snapshot.data}');
                            },
                          ),
                        ),
                      ),
                      Container(
                        margin: const EdgeInsets.all(8),
                        child: ElevatedButton(
                          onPressed: () async {
                            await controller?.flipCamera();
                            setState(() {});
                          },
                          child: FutureBuilder(
                            future: controller?.getCameraInfo(),
                            builder: (context, snapshot) {
                              if (snapshot.data != null) {
                                return const Text('Flip Camera');
                              } else {
                                return const Text('Loading...');
                              }
                            },
                          ),
                        ),
                      )
                    ],
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: <Widget>[
                      Container(
                        margin: const EdgeInsets.all(8),
                        child: ElevatedButton(
                          onPressed: () {
                            Navigator.pop(context, result?.code ?? 'No data');
                          },
                          child: const Text('Done',
                              style: TextStyle(fontSize: 20)),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          )
        ],
      ),
    );
  }

  Widget _buildQrView(BuildContext context) {
    // For this example we check how width or tall the device is and change the scanArea and overlay accordingly.
    var scanArea = (MediaQuery.of(context).size.width < 400 ||
            MediaQuery.of(context).size.height < 400)
        ? 150.0
        : 300.0;
    // To ensure the Scanner view is properly sizes after rotation
    // we need to listen for Flutter SizeChanged notification and update controller
    return QRView(
      key: qrKey,
      onQRViewCreated: _onQRViewCreated,
      overlay: QrScannerOverlayShape(
          borderColor: Colors.red,
          borderRadius: 10,
          borderLength: 30,
          borderWidth: 10,
          cutOutSize: scanArea),
      onPermissionSet: (ctrl, p) => _onPermissionSet(context, ctrl, p),
    );
  }

  void _onQRViewCreated(QRViewController controller) {
    setState(() {
      this.controller = controller;
    });
    controller.scannedDataStream.listen((scanData) {
      setState(() {
        result = scanData;
        // Pop automatically when a code is found
        if (result != null && result!.code != null) {
          Navigator.pop(context, result!.code);
        }
      });
    });
  }

  void _onPermissionSet(BuildContext context, QRViewController ctrl, bool p) {
    if (!p) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No camera permission')),
      );
    }
  }

  @override
  void dispose() {
    controller?.dispose();
    super.dispose();
  }
}
