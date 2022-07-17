import 'package:tflite_flutter/tflite_flutter.dart' as tfl;

class FaceRecognitionModel {
  static Future<tfl.Interpreter> initInterpreter() async {
    final gpuDelegateV2 = tfl.GpuDelegateV2(
      options: tfl.GpuDelegateOptionsV2(
        isPrecisionLossAllowed: false,
        inferencePreference: tfl.TfLiteGpuInferenceUsage.fastSingleAnswer,
        inferencePriority1: tfl.TfLiteGpuInferencePriority.minMemoryUsage,
        inferencePriority2: tfl.TfLiteGpuInferencePriority.minLatency,
        inferencePriority3: tfl.TfLiteGpuInferencePriority.auto,
        maxDelegatePartitions: 1,
      ),
    );

    final interpreterOptions = tfl.InterpreterOptions()
      ..addDelegate(gpuDelegateV2);

    final interpreter = await tfl.Interpreter.fromAsset(
      'mobilefacenet.tflite',
      options: interpreterOptions,
    );

    return interpreter;
  }
}
