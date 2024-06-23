import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:logger/logger.dart';
import 'package:object_detection/bndbox.dart';
import 'dart:math' as math;
import 'package:tflite_v2/tflite_v2.dart';

import 'models.dart';

// Main CameraView widget
class CameraView extends StatefulWidget {
  final List<CameraDescription> cameras; // List of available cameras
  final Model model; // Chosen model for object detection

  // Constructor with required cameras and model parameters
  const CameraView({super.key, required this.cameras, required this.model});

  @override
  State<CameraView> createState() => _CameraViewState();
}

// State class for CameraView
class _CameraViewState extends State<CameraView> {
  List<dynamic> _recognitions = []; // To store recognition results
  late CameraController
      controller; // Camera controller to manage camera operations
  bool isDetecting = false; // Flag to indicate if detection is in progress
  bool isFlashOn = false;

  final Logger _logger = Logger(); // Logger for logging messages

  // Function to set recognition results
  void setRecognitions(recognitions) {
    if (mounted) {
      setState(() {
        _recognitions = recognitions;
      });
    }
  }

  // Function to load the TFLite model
  Future<void> loadModel(Model model) async {
    Tflite.close(); // Close any previously loaded model

    String? res;
    // Load the appropriate model based on the selected model type
    switch (model) {
      case Model.yolo:
        res = await Tflite.loadModel(
          model: "assets/yolov2_tiny.tflite",
          labels: "assets/yolov2_tiny.txt",
        );
        break;
      default:
        res = await Tflite.loadModel(
            model: "assets/ssd_mobilenet.tflite",
            labels: "assets/ssd_mobilenet.txt");
    }
    _logger.i(res); // Log the result of the model loading
  }

  @override
  void initState() {
    super.initState(); // Call the superclass method

    // Load TFLite model
    loadModel(widget.model);

    // Check if there are any cameras available
    if (widget.cameras.isEmpty) {
      _logger.i('No camera is found');
    } else {
      // Initialize the camera controller with the first camera
      controller = CameraController(
        widget.cameras[0],
        ResolutionPreset.high,
      );
      controller.initialize().then((_) {
        if (!mounted) {
          return;
        }
        setState(() {});
        controller.setFlashMode(FlashMode.auto); // Set flash mode to auto

        // Start the image stream for object detection
        controller.startImageStream((CameraImage img) {
          if (!isDetecting) {
            isDetecting = true; // Set detecting flag to true

            int startTime =
                DateTime.now().millisecondsSinceEpoch; // Record start time

            // Run object detection on the current frame
            Tflite.detectObjectOnFrame(
              bytesList: img.planes.map((plane) => plane.bytes).toList(),
              model: widget.model == Model.yolo ? "YOLO" : "SSDMobileNet",
              imageHeight: img.height,
              imageWidth: img.width,
              imageMean: widget.model == Model.yolo ? 0 : 127.5,
              imageStd: widget.model == Model.yolo ? 255.0 : 127.5,
              numResultsPerClass: 1,
              threshold: widget.model == Model.yolo ? 0.2 : 0.4,
            ).then((List<dynamic>? recognitions) {
              int endTime =
                  DateTime.now().millisecondsSinceEpoch; // Record end time
              print("Detection took ${endTime - startTime} ms");

              // If recognitions are found, update the state
              if (recognitions != null && recognitions.isNotEmpty) {
                setRecognitions(recognitions);
              }

              isDetecting = false; // Reset detecting flag
            });
          }
        });
      });
    }
  }

  @override
  void dispose() {
    controller.dispose(); // Dispose the camera controller
    super.dispose(); // Call the superclass method
  }

  @override
  Widget build(BuildContext context) {
    Size tmp = MediaQuery.of(context).size; // Get the screen size
    double screenH = math.max(tmp.height, tmp.width);
    double screenW = math.min(tmp.height, tmp.width);
    tmp = controller.value.previewSize ?? const Size(0, 0);
    double previewH = math.max(tmp.height, tmp.width);
    double previewW = math.min(tmp.height, tmp.width);
    double screenRatio = screenH / screenW;
    double previewRatio = previewH / previewW;

    return Scaffold(
      body: !controller.value.isInitialized
          ? const Center(
              child: Text(
                  "Loading")) // Show loading text if the camera is not initialized
          : Stack(
              children: [
                OverflowBox(
                  maxHeight: screenRatio > previewRatio
                      ? screenH
                      : screenW / previewW * previewH,
                  maxWidth: screenRatio > previewRatio
                      ? screenH / previewH * previewW
                      : screenW,
                  child:
                      CameraPreview(controller), // Display the camera preview
                ),
                BndBox(
                  results: _recognitions,
                  previewH: previewH,
                  previewW: previewW,
                  screenH: screenH,
                  screenW: screenW,
                ), // Display bounding boxes for recognized objects
              ],
            ),
      floatingActionButton: Container(
        decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.5),
            borderRadius: BorderRadius.circular(50)),
        child: IconButton(
          onPressed: () {
            setState(() {
              isFlashOn = !isFlashOn;
            });
            isFlashOn
                ? controller.setFlashMode(FlashMode.torch)
                : controller.setFlashMode(FlashMode.off);
          },
          icon: Icon(
              !isFlashOn ? Icons.flash_on_outlined : Icons.flash_off_outlined),
        ),
      ),
    );
  }
}
