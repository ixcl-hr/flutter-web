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

// First, let's update the QR scanner page implementation
class _QRViewExampleState extends State<QRViewExample> {
  Barcode? result;
  QRViewController? controller;
  final GlobalKey qrKey = GlobalKey(debugLabel: 'QR');
  bool processingCode = false;

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
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context, 'Scan cancelled'),
        ),
      ),
      body: Stack(
        children: <Widget>[
          Expanded(child: _buildQrView(context)),
          Positioned(
            bottom: 10,
            left: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              color: Colors.black54,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  if (result != null)
                    Text(
                      'Data: ${result!.code}',
                      style: const TextStyle(color: Colors.white),
                    )
                  else
                    const Text(
                      'Scan a QR code',
                      style: TextStyle(color: Colors.white),
                    ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: <Widget>[
                      IconButton(
                        icon: const Icon(Icons.flash_on, color: Colors.white),
                        onPressed: () async {
                          await controller?.toggleFlash();
                          setState(() {});
                        },
                      ),
                      IconButton(
                        icon: const Icon(Icons.flip_camera_ios,
                            color: Colors.white),
                        onPressed: () async {
                          await controller?.flipCamera();
                          setState(() {});
                        },
                      ),
                      if (kIsWeb)
                        IconButton(
                          icon: const Icon(Icons.refresh, color: Colors.white),
                          onPressed: () async {
                            // Try to restart the camera on web
                            await controller?.pauseCamera();
                            await Future.delayed(
                                const Duration(milliseconds: 300));
                            await controller?.resumeCamera();
                          },
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          if (processingCode)
            Container(
              color: Colors.black54,
              child: const Center(
                child: CircularProgressIndicator(color: Colors.white),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildQrView(BuildContext context) {
    // Adjust scan area based on device size
    double scanArea = (MediaQuery.of(context).size.width < 400 ||
            MediaQuery.of(context).size.height < 400)
        ? 150.0
        : 300.0;

    return QRView(
      key: qrKey,
      onQRViewCreated: _onQRViewCreated,
      overlay: QrScannerOverlayShape(
        borderColor: Colors.blue,
        borderRadius: 10,
        borderLength: 30,
        borderWidth: 10,
        cutOutSize: scanArea,
      ),
      onPermissionSet: (ctrl, p) => _onPermissionSet(context, ctrl, p),
      formatsAllowed: const [BarcodeFormat.qrcode], // Focus on QR codes only
    );
  }

  void _onQRViewCreated(QRViewController controller) {
    setState(() {
      this.controller = controller;
    });

    // Listen for scanned codes
    controller.scannedDataStream.listen((scanData) {
      // Prevent multiple callbacks for the same QR code
      if (!processingCode &&
          scanData.code != null &&
          scanData.code!.isNotEmpty) {
        setState(() {
          processingCode = true;
          result = scanData;
        });

        // Give a small visual feedback before returning
        Future.delayed(const Duration(milliseconds: 500), () {
          if (mounted) {
            Navigator.pop(context, scanData.code);
          }
        });
      }
    });

    // For web specifically
    if (kIsWeb) {
      // Force camera permission dialog and handle initialization
      Future.delayed(const Duration(milliseconds: 500), () async {
        try {
          await controller.resumeCamera();
        } catch (e) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Camera initialization error: $e'),
                duration: const Duration(seconds: 3),
              ),
            );
          }
        }
      });
    }
  }

  void _onPermissionSet(BuildContext context, QRViewController ctrl, bool p) {
    if (!p) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
              'Camera permission denied. QR scanning requires camera access.'),
          duration: Duration(seconds: 3),
        ),
      );

      // Return to previous screen with error message if no permission
      Future.delayed(const Duration(seconds: 1), () {
        if (mounted) {
          Navigator.pop(context, 'Camera permission denied');
        }
      });
    }
  }

  @override
  void dispose() {
    controller?.dispose();
    super.dispose();
  }
}

// Extension methods for HomePage QR functionality
extension QRFeatures on _HomePageState {
  void _handleQRScan(BuildContext context) {
    if (kIsWeb) {
      // For web platforms, we need a different approach
      _showQROptions();
    } else {
      // For mobile platforms
      Navigator.pushNamed(context, '/qr_scanner').then((value) {
        if (value != null &&
            value.toString() != 'Scan cancelled' &&
            value.toString() != 'Camera permission denied') {
          setState(() {
            qrText = value.toString();
          });
        }
      });
    }
  }

  void _showQROptions() {
    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return SafeArea(
          child: Wrap(
            children: <Widget>[
              ListTile(
                leading: const Icon(Icons.camera_alt),
                title: const Text('Try Camera Scan'),
                subtitle: const Text('Works in Chrome and Edge with HTTPS'),
                onTap: () {
                  Navigator.pop(context);
                  _attemptCameraQR();
                },
              ),
              ListTile(
                leading: const Icon(Icons.image),
                title: const Text('Upload QR Image'),
                subtitle: const Text('Select an image with a QR code'),
                onTap: () {
                  Navigator.pop(context);
                  _pickImageQR();
                },
              ),
              // Add HTML5 QR option specifically for web
              if (kIsWeb)
                ListTile(
                  leading: const Icon(Icons.web),
                  title: const Text('Use Web QR Scanner'),
                  subtitle: const Text(
                      'HTML5 based scanner (better web compatibility)'),
                  onTap: () {
                    Navigator.pop(context);
                    _useWebQRScanner();
                  },
                ),
            ],
          ),
        );
      },
    );
  }

  void _useWebQRScanner() {
    if (kIsWeb) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Web QR Scanner'),
          content: SizedBox(
            width: 300,
            height: 300,
            child: Column(
              children: [
                const Text('For a production app, implement:'),
                const SizedBox(height: 10),
                const Text('1. HTML5 QR scanner using js_interop'),
                const Text('2. Or use a web-specific package'),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context);
                    _simulateWebQRScan();
                  },
                  child: const Text('Simulate Scan (Demo)'),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
          ],
        ),
      );
    }
  }

  void _simulateWebQRScan() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Dialog(
        child: Padding(
          padding: EdgeInsets.all(20.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text('Scanning...'),
            ],
          ),
        ),
      ),
    );

    Future.delayed(const Duration(seconds: 2), () {
      Navigator.pop(context);
      setState(() {
        qrText = "Example QR Code: https://flutter.dev";
      });
    });
  }
}
