// import 'package:cross_file/cross_file.dart';
// import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_picture_taker/flutter_picture_taker.dart';
import 'package:gap/gap.dart';
import 'package:image_picker/image_picker.dart';

class Takecamera extends StatefulWidget {
  const Takecamera({super.key});

  @override
  State<Takecamera> createState() => _TakecameraState();
}

class _TakecameraState extends State<Takecamera> {
  XFile? _image;

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('Take a picture')),
        body: Center(
          child: Column(
            children: [
              OutlinedButton(
                onPressed: _takePicture,
                child: const Text('Take picture02'),
              ),
              // const Gap(8),
              // Text(_image?.name ?? 'No name'),
              // const Gap(8),
              // Text(_image?.path ?? 'No path'),
              // const Gap(8),
              // Text(_image?.mimeType ?? 'No mime type'),
              // const Gap(8),
              // if (_image != null) Image.network(_image!.path)
            ],
          ),
        ),
      );

  Future<void> _takePicture() async {
    final image = await showStillCameraDialog(context);
    if (image != null) setState(() => _image = image);
  }
}
