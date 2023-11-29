import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:face_liveness/antiSpoofing.dart';
import 'package:face_liveness/appconstants.dart';
import 'package:face_liveness/faceMatchView.dart';
import 'package:face_liveness/viewModel/faceMatchingViewModel.dart';
import 'package:flutter/material.dart';

import 'package:face_camera/face_camera.dart';
import 'package:image/image.dart' as img;
import 'package:provider/provider.dart';
import 'package:tflite_flutter/tflite_flutter.dart' as tflite;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await FaceCamera.initialize();

  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  File? faceRecog;
  Face? detectedFace;
  File? cropSaveFile;
  tflite.Interpreter? interpreter;

  static const int INPUT_IMAGE_SIZE = 256;
  static const double THRESHOLD = 0.8;
  static const int LAPLACE_THRESHOLD = 50;
  static const int LAPLACIAN_THRESHOLD = 250;
  double? antiSpoofingScore;

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (context) => FaceMatchingViewModel(),
        ),
      ],
      child: MaterialApp(
        home: Scaffold(
            appBar: AppBar(
              title: const Text('FaceCamera example app'),
            ),
            body: Builder(builder: (context) {
              if (faceRecog != null) {
                return Center(
                  child: Stack(
                    alignment: Alignment.bottomCenter,
                    children: [
                      Image.file(
                        //_capturedImage
                        faceRecog!,
                        width: double.maxFinite,
                        fit: BoxFit.fitWidth,
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          ElevatedButton(
                            onPressed: () async {
                           Navigator.push(context, MaterialPageRoute(builder: (context)=>FaceMatchView(cropSaveFile: cropSaveFile,)));
                            },
                            child: Text("Face Matching"),
                            /* onPressed: () => setState(() => faceRecog = null),
                              child: const Text(
                                'Capture Again',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                    fontSize: 14, fontWeight: FontWeight.w700),
                              ) */
                          ),
                          Text(
                            "$antiSpoofingScore",
                            style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: Colors.white),
                          ),
                        ],
                      )
                    ],
                  ),
                );
              }
              return SmartFaceCamera(
                  autoCapture: true,
                  defaultCameraLens: CameraLens.front,
                  onCapture: (File? image) async {
                    //setState(() => _capturedImage = image);
                    await cropImage(image, context);
                    print("source image id ${Appconstants.sourceFile}");
                    setState(() {});
                  },
                  onFaceDetected: (Face? face) {
                    print("Face detected $face");
                    setState(() {
                      detectedFace = face;
                    });
                    //Do something
                  },
                  messageBuilder: (context, face) {
                    if (face == null) {
                      return _message('Place your face in the camera');
                    }
                    if (!face.wellPositioned) {
                      return _message('Center your face in the square');
                    }
                    return const SizedBox.shrink();
                  });
            })),
      ),
    );
  }

  Widget _message(String msg) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 55, vertical: 15),
        child: Text(msg,
            textAlign: TextAlign.center,
            style: const TextStyle(
                fontSize: 14, height: 1.5, fontWeight: FontWeight.w400)),
      );
  cropImage(File? _capturedImage, context) async {
    img.Image capturedImage =
        img.decodeImage(File(_capturedImage?.path ?? "").readAsBytesSync())!;
    if (detectedFace != null && detectedFace!.boundingBox != null) {
      img.Image faceCrop = img.copyCrop(
        capturedImage,
        x: detectedFace!.boundingBox.left.toInt(),
        y: detectedFace!.boundingBox.top.toInt() + 50,
        width: detectedFace!.boundingBox.width.toInt(),
        height: detectedFace!.boundingBox.height.toInt(),
      );
      final jpg = img.encodeJpg(faceCrop);
      cropSaveFile = File(_capturedImage?.path ?? "");
      await cropSaveFile?.writeAsBytes(jpg);
      var laplacianScore = laplacian(cropSaveFile!);
      if (laplacianScore < LAPLACIAN_THRESHOLD) {
        print("Please place your face in the camera");
      } else {
        FaceAntiSpoofing faceAntiSpoofing = FaceAntiSpoofing();
        antiSpoofingScore = await faceAntiSpoofing.loadModel(cropSaveFile);
        print("antiSpoofingScoreeeeeeeeeeeee ${antiSpoofingScore}");
        setState(() {});
        if (antiSpoofingScore! < THRESHOLD) {
          faceRecog = cropSaveFile;
          File localFace = File(AssetImage("assets/sri.jpg").assetName);
          //faceRecog = localFace;
          print("localFacee ${localFace}");
          print("face recognised!!!!!!!!!!!!!!");
        } else {
          print("spoofing detected!!!!!!!!!!!!!!!!!");
          return showDialog(
              context: context,
              builder: (context) => AlertDialog(
                    title: Text("Spoofing Detected"),
                    content: Text("Please place your face in the camera"),
                    actions: [
                      TextButton(
                          onPressed: () {
                            faceRecog = null;
                            Navigator.pop(context);
                          },
                          child: Text("OK"))
                    ],
                  ));
        }
      }
    }
  }

  Future<Image> convertFileToImage(File picture) async {
    List<int> imageBase64 = picture.readAsBytesSync();
    String imageAsString = base64Encode(imageBase64);
    Uint8List uint8list = base64.decode(imageAsString);
    Image image = Image.memory(uint8list);
    print("converted image ${image}");
    return image;
  }

  int laplacian(File imageFile) {
    img.Image capturedImage =
        img.decodeImage(File(imageFile.path).readAsBytesSync())!;

    // Size of the Laplacian filter
    int score = 0;
    const List<List<int>> laplace = [
      [0, 1, 0],
      [1, -4, 1],
      [0, 1, 0],
    ];
    int size = laplace.length;
    int height = capturedImage.height;
    int width = capturedImage.width;

    for (int x = 0; x < height - size + 1; x++) {
      for (int y = 0; y < width - size + 1; y++) {
        double result = 0;

        // Convolution operation in the size x size region
        for (int i = 0; i < size; i++) {
          for (int j = 0; j < size; j++) {
            img.Pixel pixelValue = getPixel(capturedImage, x + i, y + j);
            if (x + i < capturedImage.height && y + j < capturedImage.width) {
              result += pixelValue.r * laplace[i][j];
              result += pixelValue.g * laplace[i][j];
              result += pixelValue.b * laplace[i][j];
            }
          }
        }
        // Cast result to int before using it in the comparison
        if (result.toInt() > LAPLACE_THRESHOLD) {
          score++;
        }
      }
    }
    print("scoreeeeeeeeeeeeeeeeeeeeeeeeee ${score}");
    return score;
  }

  img.Pixel getPixel(img.Image image, int x, int y) {
    return image.getPixel(x, y);
  }
}
