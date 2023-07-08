import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'TakePictureScreen.dart';


Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final cameras = await availableCameras();
  final firstCamera = cameras.first;

  runApp(
    MaterialApp(
      /*showSemanticsDebugger: true,*/
      theme: ThemeData.dark(),
      debugShowCheckedModeBanner: false,
      home: RecognizingScreen(
        // Pass the appropriate camera to the TakePictureScreen widget.
        camera: firstCamera,
      )
    ),
  );
}

