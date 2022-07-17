import 'package:absensi_app/src/faceModule/face_recognition_model.dart';
import 'package:absensi_app/src/faceModule/face_recognition_service.dart';
import 'package:absensi_app/src/faceModule/image_helper.dart';
import 'package:absensi_app/src/repositories/user_repository.dart';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:google_ml_kit/google_ml_kit.dart';
import 'package:quiver/collection.dart';
import '../faceModule/face_detector_painter.dart';
import '../faceModule/user.dart';

class FaceRecognitionPage extends StatefulWidget {
  final bool isLogin;
  const FaceRecognitionPage({
    Key? key,
    this.isLogin = false,
  }) : super(key: key);

  @override
  State<FaceRecognitionPage> createState() => _FaceRecognitionPageState();
}

class _FaceRecognitionPageState extends State<FaceRecognitionPage>
    with WidgetsBindingObserver {
  late final FaceRecognitionService faceRecognitionService;
  late final CameraController cameraController;
  late final UserRepository userRepository;
  final nameController = TextEditingController();

  Multimap<String, Face> scanResults = Multimap<String, Face>();
  List currentFacePoint = [];
  User? user;
  bool isDetecting = false;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    userRepository = UserRepository();

    start();
  }

  void initFaceRecognitionService() async {
    final interpreter = await FaceRecognitionModel.initInterpreter();

    faceRecognitionService = FaceRecognitionService(
      interpreter: interpreter,
      imageHelper: ImageHelper(),
      faceDetector: GoogleMlKit.vision.faceDetector(
        const FaceDetectorOptions(mode: FaceDetectorMode.accurate),
      ),
    );
  }

  void start() {
    initCamera();
    initFaceRecognitionService();
  }

  Future<CameraDescription> getCamera(CameraLensDirection dir) async {
    return await availableCameras().then(
      (List<CameraDescription> cameras) => cameras.firstWhere(
        (CameraDescription camera) => camera.lensDirection == dir,
      ),
    );
  }

  void initCamera() async {
    CameraDescription description = await getCamera(CameraLensDirection.front);

    cameraController = CameraController(
      description,
      ResolutionPreset.low,
      enableAudio: false,
      imageFormatGroup: ImageFormatGroup.yuv420,
    );
    await cameraController.initialize();
    isLoading = false;

    cameraController.startImageStream((CameraImage image) async {
      if (isDetecting) return;

      isDetecting = true;
      final finalResult = Multimap<String, Face>();

      if (widget.isLogin) {
        user = await userRepository.getUser();
      }

      final detectResult = await faceRecognitionService.detect(
        image: image,
        description: cameraController.description,
      );

      String res;

      for (Face face in detectResult) {
        final recogResult = faceRecognitionService.recognize(
          image: image,
          face: face,
        );
        currentFacePoint = recogResult;

        res = faceRecognitionService.compare(recogResult, user);

        finalResult.add(res, face);
      }

      print('FACE: $currentFacePoint');

      scanResults = finalResult;
      isDetecting = false;
      setState(() {});

      if (widget.isLogin) {
        await Future.delayed(const Duration(seconds: 3));
        disposeCamera();

        if (mounted) {
          Navigator.of(context).pop();
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
      appBar: AppBar(
        title: const Text('Face Recognition'),
      ),
      body: isLoading
          ? const Center(
              child: CircularProgressIndicator(),
            )
          : Stack(
              fit: StackFit.expand,
              children: <Widget>[
                CameraPreview(cameraController),
                _buildFaceDetectorPainter(),
              ],
            ),
      floatingActionButton: FloatingActionButton(
          onPressed: () {
            showDialog(
                context: context,
                builder: (context) {
                  return AlertDialog(
                    content: Column(children: [
                      TextField(
                        controller: nameController,
                      ),
                      ElevatedButton(
                          onPressed: () async {
                            Navigator.of(context).pop();
                            userRepository.saveUser(
                              User(
                                name: nameController.text,
                                facePoint: currentFacePoint,
                              ),
                            );
                            Navigator.pop(context);
                          },
                          child: const Text('Simpan'))
                    ]),
                  );
                });
          },
          child: const Icon(Icons.add)),
    );
  }

  Widget _buildFaceDetectorPainter() {
    final Size imageSize = Size(
      cameraController.value.previewSize!.height,
      cameraController.value.previewSize!.width,
    );
    final painter = FaceDetectorPainter(imageSize, scanResults);
    return CustomPaint(
      painter: painter,
    );
  }

  void disposeCamera() async {
    if (cameraController.value.isStreamingImages) {
      await cameraController.stopImageStream();
      await Future.delayed(const Duration(milliseconds: 400));
      await cameraController.dispose();
      await Future.delayed(const Duration(milliseconds: 400));
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);

    disposeCamera();
    super.dispose();
  }
}
