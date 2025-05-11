import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

class QRScannerApp extends StatelessWidget {
  const QRScannerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      home: QRScannerPage(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class QRScannerPage extends StatefulWidget {
  const QRScannerPage({super.key});

  @override
  State<QRScannerPage> createState() => _QRScannerPageState();
}

class _QRScannerPageState extends State<QRScannerPage> {
  String? scannedCode;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Web QR Code Scanner'),
      ),
      body: Stack(
        children: [
          // Camera Preview
          MobileScanner(
            onDetect: (capture) {
              final List<Barcode> barcodes = capture.barcodes;
              if (barcodes.isEmpty) {
                debugPrint('Failed to scan Barcode');
              } else {
                final String code = barcodes.first.rawValue ?? '';
                debugPrint('QR Code Found: $code');
                setState(() {
                  scannedCode = code;
                });
              }
            },
          ),

          // Display scanned QR code
          if (scannedCode != null)
            Center(
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white70,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  'Scanned: $scannedCode',
                  style: const TextStyle(fontSize: 18),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
