import 'dart:math';

import 'package:absensi_app/src/faceModule/image_helper.dart';
import 'package:absensi_app/src/faceModule/user.dart';
import 'package:camera/camera.dart';
import 'package:google_ml_kit/google_ml_kit.dart';
import 'package:tflite_flutter/tflite_flutter.dart' as tfl;
import 'package:image/image.dart' as imglib;

class FaceRecognitionService {
  final tfl.Interpreter interpreter;
  final ImageHelper imageHelper;
  final FaceDetector faceDetector;

  FaceRecognitionService({
    required this.interpreter,
    required this.imageHelper,
    required this.faceDetector,
  });

  List<dynamic> recognize({
    required CameraImage image,
    required Face face,
  }) {
    imglib.Image convertedImage = imageHelper.convertCameraImage(image);

    final croppedImage =
        imageHelper.cropImage(image: convertedImage, face: face);

    final input = imageHelper
        .imageToByteListFloat32(croppedImage, 112, 128, 128)
        .reshape([1, 112, 112, 3]);

    final output =
        List.filled(1 * 192, null, growable: false).reshape([1, 192]);

    interpreter.run(input, output);

    final reshapedOutput = output.reshape([192]);

    return List.from(reshapedOutput);
  }

  Future<List<Face>> detect({
    required CameraImage image,
    required CameraDescription description,
  }) async {
    final rotation = imageHelper.rotationIntToImageRotation(
      description.sensorOrientation,
    );

    final metaData = imageHelper.buildMetaData(
      image: image,
      rotation: rotation,
    );

    final faces = faceDetector.processImage(InputImage.fromBytes(
      bytes: image.planes[0].bytes,
      inputImageData: metaData,
    ));

    return faces;
  }

  String compare(List camFacePoint, User? user) {
    double threshold = 1.0;
    double minDist = 999;
    double currDist = 0.0;

    print('CURRENT USER: ${user?.name}');

    String name = "Tidak dikenali";

    if (user == null) return name;

    currDist = euclideanDistance(user.facePoint, camFacePoint);
    if (currDist <= threshold && currDist < minDist) {
      minDist = currDist;
      name = user.name;
    }
    return name;
  }

  double euclideanDistance(List e1, List e2) {
    double sum = 0.0;
    for (int i = 0; i < e1.length; i++) {
      sum += pow((e1[i] - e2[i]), 2);
    }
    return sqrt(sum);
  }
}
