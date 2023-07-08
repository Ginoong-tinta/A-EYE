import 'package:camera/camera.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:tflite/tflite.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'dart:io';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vibration/vibration.dart';

int total = 0;

class RecognizingScreen extends StatefulWidget {
  final CameraDescription camera;
  const RecognizingScreen({
    Key key,
    @required this.camera,
  }) : super(key: key);

  @override
  _RecognizingScreenState createState() => _RecognizingScreenState();
}

class _RecognizingScreenState extends State<RecognizingScreen> {
  CameraController _controller;
  Future<void> _initializeControllerFuture;
  FlutterTts flutterTts;
  bool flash = false;
  bool firstLaunch = true;
  bool startRecognizing = false;


  @override
  void initState() {
    super.initState();
    flutterTts = new FlutterTts();
    _controller = CameraController(
      widget.camera,
      ResolutionPreset.high,
    );
    _initializeControllerFuture = _controller.initialize();

    checkFirstLaunch();

  }

  @override
  void dispose() {
    if (!firstLaunch)
      flutterTts.stop();
    _controller.dispose();
    super.dispose();

  }

  Future<void> checkFirstLaunch() async {
    final prefs = await SharedPreferences.getInstance();
    final isFirstLaunch = prefs.getBool('isFirstLaunch') ?? true;
    if (isFirstLaunch) {
      await flutterTts.speak('Welcome to the app. To start recognizing, please double tap the screen.');
      prefs.setBool('isFirstLaunch', false);
      setState(() {
        firstLaunch = false;
      });
    }

  }

  @override
  Widget build(BuildContext context) {

    return Scaffold(
      body: FutureBuilder<void>(
        future: _initializeControllerFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.done) {
            return CameraPreview(_controller);
          } else {
            return Center(
                child: CircularProgressIndicator()
            );
          }
        },
      ),
      floatingActionButton: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Flexible(
              child: Container(
                height: 800.0,
                width: 900.0,
                child: Semantics(
                  button: true,
                  label: "Double tap to capture",
                  child: InkWell(

                    onTap: () async {


                      try {

                        await Vibration.vibrate();

                        setState(() {
                          flash = !flash;

                        });
                        flash
                            ?_controller.setFlashMode(FlashMode.always)
                            : _controller.setFlashMode(FlashMode.off);

                        await _initializeControllerFuture;

                        String speakString = "Capturing";
                        await flutterTts.setSpeechRate(0.5);
                        await flutterTts.awaitSpeakCompletion(true);
                        await flutterTts.setLanguage("en-US");
                        await flutterTts.speak(speakString);


                        XFile path = await _controller.takePicture();

                        String speakOutput = "Image captured";
                        await flutterTts.speak(speakOutput);


                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => DisplayPictureScreen(path.path, widget.camera),
                          ),
                        );
                      } on PlatformException catch (e) {
                        print(e);
                      }},
                  ),
                )
              )
            ),
          ]
      ),
    );
  }
}

class DisplayPictureScreen extends StatefulWidget {
  final String imagePath;
  final CameraDescription camera;
  DisplayPictureScreen(this.imagePath, this.camera);
  @override
  _DisplayPictureScreenState createState() => _DisplayPictureScreenState();
}


class _DisplayPictureScreenState extends State<DisplayPictureScreen> {
  List recognitions;
  Image img;
  FlutterTts flutterTts;


  @override
  void initState() {
    super.initState();
    flutterTts = new FlutterTts();
    loadModel().then((value) {
      setState(() {});
    });
    img = Image.file(File(widget.imagePath));
    classifyImage(widget.imagePath);
  }

  @override
  Widget build(BuildContext context) {


    return MergeSemantics(
      child: Scaffold(
          body: Container(
            child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  Flexible(
                      child: Semantics(
                        hidden: true,
                        child: Container(
                          child: InkWell(
                            onTap: () {


                              setState(() {
                              });
                              Navigator.of(context).pop();
                              Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                      builder: (context) => RecognizingScreen(camera: widget.camera)));
                            },
                            onLongPress: () {


                              setState(() {
                                total = 0;

                              });
                              Navigator.of(context).pop();
                              Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                      builder: (context) => RecognizingScreen(camera: widget.camera)));
                              print ("long pressed");

                            },

                            child: Image.file(File(widget.imagePath)),

                          ),
                        )
                      )
                  )
              ]
            ),
          ),
      ),
    );
  }

  void vibrate(int times) {
    for (int i = 0; i < times; i++) {
      HapticFeedback.vibrate();
    }
  }


  Future<void> runTextToSpeech(String outputMoney, int totalMoney) async {

    void speakAndSetOptions(String speakString1, String speakString2, double speechRate) async {
      await flutterTts.speak(speakString1);
      await flutterTts.speak(speakString2);
      await flutterTts.setSpeechRate(speechRate);
      await flutterTts.awaitSpeakCompletion(true);
      await flutterTts.setLanguage("en-US");
    }


    if (outputMoney == "20 pesos") {
      String tot = totalMoney.toString();
      String speakString1 = "Twenty Pesos, Your total is now $tot pesos....";
      String speakString2 = ('Do you want to continue recognizing without resetting the total? If yes, double-tap the screen. If no, one tap and long-press the screen.');
      speakAndSetOptions(speakString1, speakString2, 0.5);

    }
    if (outputMoney == "50 pesos") {
      String tot = totalMoney.toString();
      String speakString1 = "Fifty Pesos, Your total is now $tot pesos....";
      String speakString2 = ('Do you want to continue recognizing without resetting the total? If yes, double-tap the screen. If no, one tap and long-press the screen.');
      speakAndSetOptions(speakString1, speakString2, 0.5);
    }
    if (outputMoney == "100 pesos") {
      String tot = totalMoney.toString();
      String speakString1 = "One Hundred Pesos, Your total is now $tot pesos....";
      String speakString2 = ('Do you want to continue recognizing without resetting the total? If yes, double-tap the screen. If no, one tap and long-press the screen.');
      speakAndSetOptions(speakString1, speakString2, 0.5);
    }
    if (outputMoney == "200 pesos") {
      String tot = totalMoney.toString();
      String speakString1 = "Two Hundred Pesos, Your total is now $tot pesos....";
      String speakString2 = ('Do you want to continue recognizing without resetting the total? If yes, double-tap the screen. If no, one tap and long-press the screen.');
      speakAndSetOptions(speakString1, speakString2, 0.5);
    }
    if (outputMoney == "500 pesos") {
      String tot = totalMoney.toString();
      String speakString1 = "Five Hundred Pesos, Your total is now $tot pesos....";
      String speakString2 = ('Do you want to continue recognizing without resetting the total? If yes, double-tap the screen. If no, one tap and long-press the screen.');
      speakAndSetOptions(speakString1, speakString2, 0.5);
    }
    if (outputMoney == "1000 pesos") {
      String tot = totalMoney.toString();
      String speakString1 = "One Thousand Pesos, Your total is now $tot pesos....";
      String speakString2 = ('Do you want to continue recognizing without resetting the total? If yes, double-tap the screen. If no, one tap and long-press the screen.');
      speakAndSetOptions(speakString1, speakString2, 0.5);
    }
    if (outputMoney == "no banknote") {
      String tot = totalMoney.toString();
      String speakString1 = "Sorry, but NO BANKNOTE WAS FOUND... Your total is still $tot pesos";
      String speakString2 = ('Do you want to continue recognizing without resetting the total? If yes, double-tap the screen. If no, one tap and long-press the screen.');
      speakAndSetOptions(speakString1, speakString2, 0.5);
    }
  }

  classifyImage(String image) async {
    var output = await Tflite.runModelOnImage(
      path: image,
      numResults: 1,
      threshold: 0.6,
      imageMean: 127.5,
      imageStd: 127.5,
    );

    if (output != null && output.isNotEmpty) {
      var label = output[0]['label'];
      var confidence = output[0]['confidence'];

      print('Label: $label');
      print('Confidence: $confidence');
    }

    recognitions = output;

    if (recognitions != null) {
      if (recognitions[0]["label"] == "20 pesos") {
        total += 20;
        runTextToSpeech("20 pesos", total);
        print("20 pesos");
      }
      if (recognitions[0]["label"] == "50 pesos") {
        total += 50;
        runTextToSpeech("50 pesos", total);
        print("50 pesos");
      }
      if (recognitions[0]["label"] == "100 pesos") {
        total += 100;
        runTextToSpeech("100 pesos", total);
        print("100 pesos");
      }
      if (recognitions[0]["label"] == "200 pesos") {
        total += 200;
        runTextToSpeech("200 pesos", total);
        print("200 pesos");
      }
      if (recognitions[0]["label"] == "500 pesos") {
        total += 500;
        runTextToSpeech("500 pesos", total);
        print("500 pesos");
      }
      if (recognitions[0]["label"] == "1000 pesos") {
        total += 1000;
        runTextToSpeech("1000 pesos", total);
      }
      else if (recognitions[0]["label"] == "no banknote") {
        runTextToSpeech("no banknote", total);
        print("no banknote was found");
      }
    }
  }

  loadModel() async {
    await Tflite.loadModel(
        model: "assets/model_unquant.tflite",
        labels: "assets/labels.txt");
  }


  @override
  void dispose() {
    flutterTts.stop();
    Tflite.close();
    super.dispose();
  }
}


