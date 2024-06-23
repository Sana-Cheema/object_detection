import 'dart:async';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:logger/logger.dart';
import 'home.dart';

List<CameraDescription> cameras = [];
Logger _logger = Logger();
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    cameras = await availableCameras();
  } on CameraException catch (e) {
    _logger.e(
      e.code,
      time: DateTime.now(),
      error: e.description,
    );
  }
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'tflite real-time detection',
      theme: ThemeData(
        brightness: Brightness.dark,
      ),
      home: HomePage(cameras),
    );
  }
}
