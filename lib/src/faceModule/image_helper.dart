import 'dart:typed_data';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:google_ml_kit/google_ml_kit.dart';
import 'package:image/image.dart' as imglib;

class ImageHelper {
  InputImageData buildMetaData({
    required CameraImage image,
    required InputImageRotation rotation,
  }) {
    final inputImageFormat =
        InputImageFormatMethods.fromRawValue(image.format.raw);

    final planes = image.planes.map(
      (plane) {
        return InputImagePlaneMetadata(
          bytesPerRow: plane.bytesPerRow,
          height: plane.height,
          width: plane.width,
        );
      },
    ).toList();

    return InputImageData(
      size: Size(image.width.toDouble(), image.height.toDouble()),
      imageRotation: rotation,
      inputImageFormat: inputImageFormat ?? InputImageFormat.NV21,
      planeData: planes,
    );
  }

  InputImage getInputImage(CameraImage image, InputImageData metaData) {
    return InputImage.fromBytes(
      bytes: image.planes[0].bytes,
      inputImageData: metaData,
    );
  }

  Float32List imageToByteListFloat32(
      imglib.Image image, int inputSize, double mean, double std) {
    var convertedBytes = Float32List(1 * inputSize * inputSize * 3);
    var buffer = Float32List.view(convertedBytes.buffer);
    int pixelIndex = 0;
    for (var i = 0; i < inputSize; i++) {
      for (var j = 0; j < inputSize; j++) {
        var pixel = image.getPixel(j, i);
        buffer[pixelIndex++] = (imglib.getRed(pixel) - mean) / std;
        buffer[pixelIndex++] = (imglib.getGreen(pixel) - mean) / std;
        buffer[pixelIndex++] = (imglib.getBlue(pixel) - mean) / std;
      }
    }
    return convertedBytes.buffer.asFloat32List();
  }

  InputImageRotation rotationIntToImageRotation(int rotation) {
    switch (rotation) {
      case 0:
        return InputImageRotation.Rotation_0deg;
      case 90:
        return InputImageRotation.Rotation_90deg;
      case 180:
        return InputImageRotation.Rotation_180deg;
      default:
        assert(rotation == 270);
        return InputImageRotation.Rotation_270deg;
    }
  }

  imglib.Image convertCameraImage(CameraImage image) {
    int width = image.width;
    int height = image.height;

    final img = imglib.Image(width, height);
    const int hexFF = 0xFF000000;
    final int uvyButtonStride = image.planes[1].bytesPerRow;
    final int? uvPixelStride = image.planes[1].bytesPerPixel;
    for (int x = 0; x < width; x++) {
      for (int y = 0; y < height; y++) {
        final int uvIndex = uvPixelStride! * (x / 2).floor() +
            uvyButtonStride * (y / 2).floor();
        final int index = y * width + x;
        final yp = image.planes[0].bytes[index];
        final up = image.planes[1].bytes[uvIndex];
        final vp = image.planes[2].bytes[uvIndex];

        int r = (yp + vp * 1436 / 1024 - 179).round().clamp(0, 255);
        int g = (yp - up * 46549 / 131072 + 44 - vp * 93604 / 131072 + 91)
            .round()
            .clamp(0, 255);
        int b = (yp + up * 1814 / 1024 - 227).round().clamp(0, 255);
        img.data[index] = hexFF | (b << 16) | (g << 8) | r;
      }
    }
    final rotatedImage = imglib.copyRotate(img, -90);
    return rotatedImage;
  }

  imglib.Image cropImage({required imglib.Image image, required Face face}) {
    final x = (face.boundingBox.left - 10);
    final y = (face.boundingBox.top - 10);
    final w = (face.boundingBox.width + 10);
    final h = (face.boundingBox.height + 10);

    imglib.Image croppedImage = imglib.copyCrop(
      image,
      x.round(),
      y.round(),
      w.round(),
      h.round(),
    );
    croppedImage = imglib.copyResizeCropSquare(croppedImage, 112);

    return croppedImage;
  }
}
