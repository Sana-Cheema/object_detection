import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:object_detection/camera_view.dart';
import 'package:object_detection/guide_screen.dart';

import 'models.dart';

class HomePage extends StatefulWidget {
  final List<CameraDescription> cameras;

  const HomePage(this.cameras, {super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  gotoCameraView(Model model) {
    Navigator.push(
        context,
        MaterialPageRoute(
            builder: (context) => CameraView(
                  cameras: widget.cameras,
                  model: model,
                )));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: const Text("Realtime Object Detection"),
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              ElevatedButton(
                child: const Text("SSD"),
                onPressed: () => gotoCameraView(Model.ssd),
              ),
              ElevatedButton(
                child: const Text('YOLO'),
                onPressed: () => gotoCameraView(Model.ssd),
              ),
              ElevatedButton(
                child: const Text('Guide'),
                onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => const GuideScreen())),
              ),
            ],
          ),
        ));
  }
}
