import 'dart:io';

import 'package:face_camera/face_camera.dart';
import 'package:face_liveness/antiSpoofing.dart';
import 'package:face_liveness/face_matching_local.dart';

import 'package:face_liveness/res/routes/app_routes.dart';
import 'package:face_liveness/viewModel/faceMatchingViewModel.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:image/image.dart' as img;
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
import 'package:tflite_flutter/tflite_flutter.dart' as tflite;

class FaceRecognitionView extends StatefulWidget {
  const FaceRecognitionView({super.key});

  @override
  State<FaceRecognitionView> createState() => _FaceRecognitionViewState();
}

class _FaceRecognitionViewState extends State<FaceRecognitionView> {
  File? faceRecog;
  Face? detectedFace;
  File? cropSaveFile;
  File? _capturedImage;
  tflite.Interpreter? interpreter;

  static const int INPUT_IMAGE_SIZE = 256;
  static const double THRESHOLD = 0.8;
  static const int LAPLACE_THRESHOLD = 50;
  static const int LAPLACIAN_THRESHOLD = 250;
  double? antiSpoofingScore;
  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: const Text('FaceCamera example app'),
        ),
        body: Builder(builder: (context) {
          return SmartFaceCamera(
              autoCapture: true,
              defaultCameraLens: CameraLens.front,
              onCapture: (File? image) async {
                if (image != null) {
                  // Replace the captured image with the new one
                  _capturedImage = image;

                  print("captured image path is ${image.path}");
                  await cropImage(_capturedImage, context);

                  setState(() {});
                }
              },
              /* onCapture: (File? image) async {
                //setState(() => _capturedImage = image);
                print("captured image path is 111111111111 ${image?.parent}");
                await cropImage(image, context);
                print("source image id ${Appconstants.sourceFile}");
                setState(() {});
              }, */
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
        }));
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
          File profile = await getProfile();
          FaceMatching faceMatching = FaceMatching();
          double faceMatchResult =
              await faceMatching.loadModel(cropSaveFile!, profile);
          if (faceMatchResult > THRESHOLD) {
            print("Face Matched!!!!!!!!!!!!!!");
          } else {
            print("Face Not Matched!!!!!!!!!!!!!!");
          }

          /*  await faceMatchingProvider.faceMatchingApiCall(
              context, cropSaveFile!); */
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
                            Navigator.pushReplacementNamed(
                                context, AppRoutes.FaceDetectView);
                          },
                          child: Text("OK"))
                    ],
                  ));
        }
      }
    }
  }

/*   int laplacian(File imageFile) {
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
            int pixelX = x + i;
            int pixelY = y + j;

            // Check if the pixel coordinates are within bounds
            if (pixelX < 0 ||
                pixelX >= height ||
                pixelY < 0 ||
                pixelY >= width) {
              continue;
            }
            img.Pixel pixelValue = getPixel(capturedImage, pixelX, pixelY);
            result += pixelValue.r * laplace[i][j];
            result += pixelValue.g * laplace[i][j];
            result += pixelValue.b * laplace[i][j];
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
 */
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

    for (int x = 0; x < height; x++) {
      for (int y = 0; y < width; y++) {
        double result = 0;

        // Convolution operation in the size x size region
        for (int i = 0; i < size; i++) {
          for (int j = 0; j < size; j++) {
            int pixelX = x + i - (size ~/ 2);
            int pixelY = y + j - (size ~/ 2);

            // Check if the pixel coordinates are within bounds
            if (pixelX < 0 ||
                pixelX >= height ||
                pixelY < 0 ||
                pixelY >= width) {
              continue;
            }
            img.Pixel pixelValue = getPixel(capturedImage, pixelX, pixelY);
            result += pixelValue.r * laplace[i][j];
            result += pixelValue.g * laplace[i][j];
            result += pixelValue.b * laplace[i][j];
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

  Future<File> getProfile() async {
    File downloadedFile = await urlToFile(
        "http://uat9.cgg.gov.in/virtuosuite/EmployeeProfileIcon/2251employeeimage20230724114703_610.png");
    return downloadedFile;
  }

  Future<File> urlToFile(String imageUrl) async {
    try {
      Directory tempDir = await getTemporaryDirectory();
      String tempPath = tempDir.path;
      File file = File('$tempPath/profile.jpg');
      http.Client client = http.Client();
      http.Response response = await client.get(Uri.parse(imageUrl));
      if (response.statusCode == 200) {
        await file.writeAsBytes(response.bodyBytes);
        if (await isFileReadableAndAccessible(file)) {
          print("readable and accessible ${file.path}");
          img.Image? originalImage = img.decodeImage(file.readAsBytesSync());
          File reducedSizeFile = await compressImage(originalImage, 1000);
          return reducedSizeFile;
        } else {
          print("File not readable or accessible.");
          throw FileSystemException('File not readable or accessible.');
        }
      } else {
        print("Failed to load image, status code ${response.statusCode}");
        throw http.ClientException(
            'Failed to load image, status code: ${response.statusCode}');
      }
    } catch (e) {
      print('Error creating file from URL: $e');
      throw e;
    }
  }

  Future<bool> isFileReadableAndAccessible(File file) async {
    try {
      return file.existsSync() && await file.readAsBytes() != null;
    } catch (e) {
      print('Error checking file readability: $e');
      return false;
    }
  }

  Future<File> compressImage(
      img.Image? originalImage, int targetFileSizeKB) async {
    int quality = 90; // Initial quality setting
    List<int> compressedBytes = img.encodeJpg(originalImage!, quality: quality);
    while (compressedBytes.length > targetFileSizeKB * 1024 && quality > 0) {
      quality -= 10;
      compressedBytes = img.encodeJpg(originalImage, quality: quality);
    }
    Directory tempDir = await getTemporaryDirectory();
    String tempPath = tempDir.path;
    File compressedFile = File('$tempPath/reduced_size.jpg');
    await compressedFile.writeAsBytes(compressedBytes);
    File croppedProfile = await cropToFace(compressedFile);
    return croppedProfile;
    // return compressedFile;
  }

  Future<File> cropToFace(File originalImageFile) async {
    img.Image originalImage =
        img.decodeImage(originalImageFile.readAsBytesSync())!;

    // Crop image to the first detected face

    img.Image croppedImage = img.copyCrop(
      originalImage,
      x: detectedFace!.boundingBox.left.toInt(),
      y: detectedFace!.boundingBox.top.toInt(),
      width: detectedFace!.boundingBox.width.toInt(),
      height: detectedFace!.boundingBox.height.toInt(),
    );

    // Save the cropped image to a new file
    Directory tempDir = await getTemporaryDirectory();
    String tempPath = tempDir.path;
    File croppedFile = File('$tempPath/cropped_face.jpg');
    await croppedFile.writeAsBytes(img.encodeJpg(croppedImage));

    return croppedFile;
  }
}
