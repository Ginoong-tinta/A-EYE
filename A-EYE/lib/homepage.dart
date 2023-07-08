import 'package:capstone/responsive_layout.dart';
import 'package:flutter/material.dart';
import 'TakePictureScreen.dart';

class HomePage extends StatefulWidget {
  const HomePage({Key key}) : super(key: key);

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: ResponsiveLayout(
        mobileBody: RecognizingScreen(camera: null),
      ),
    );
  }
}