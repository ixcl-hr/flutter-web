// import 'package:cross_file/cross_file.dart';
// import 'package:flutter/foundation.dart';
import 'package:camera_camera/camera_camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter_picture_taker/flutter_picture_taker.dart';
import 'package:gap/gap.dart';
import 'package:image_picker/image_picker.dart';
import 'package:universal_html/js_util.dart' as photos;

class Takecamera extends StatefulWidget {
  const Takecamera({super.key});

  @override
  State<Takecamera> createState() => _TakecameraState();
}

class _TakecameraState extends State<Takecamera> {
  XFile? _image;

  @override
  Widget build(BuildContext context) => Scaffold(
        body: CameraCamera(
          // onFile: (file) => print(file),
          onFile: (file) {
            //photos.add(file);
            Navigator.pop(context);
            setState(() {});
          },
        ),
        // floatingActionButton: FloatingActionButton(
        //   onPressed: () {
        //     Navigator.push(
        //         context,
        //         MaterialPageRoute(
        //             builder: (_) => CameraCamera(
        //                   onFile: (file) {
        //                     photos.add(file, null);
        //                     //When take foto you should close camera
        //                     Navigator.pop(context);
        //                     setState(() {});
        //                   },
        //                 )));
        //   },
        //   child: Icon(Icons.camera_alt),
        // ),
      );
}
