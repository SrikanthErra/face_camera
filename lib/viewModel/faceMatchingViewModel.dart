import 'dart:io';
import 'package:face_camera/face_camera.dart';
import 'package:face_liveness/face_matching.dart';
import 'package:face_liveness/res/components/alertComponent.dart';
import 'package:face_liveness/res/routes/app_routes.dart';
import 'package:http/http.dart' as http;
import 'package:image/image.dart' as img;
import 'package:path_provider/path_provider.dart';
import 'package:face_liveness/repository/faceMatchingRepository.dart';
import 'package:flutter/material.dart';

class FaceMatchingViewModel with ChangeNotifier {
  final _faceMatchingRepository = FaceMatchingRepository();
  final FaceDetector _faceDetector = FaceDetector(
    options: FaceDetectorOptions(
      enableContours: true,
      enableLandmarks: true,
    ),
  );
  File? cropSaveFile;
  Future<void> faceMatchingApiCall(
      BuildContext buildContext, File file, Face? detectedFace) async {
    File downloadedFile = await urlToFile(
        "https://virtuo.cgg.gov.in/EmployeeProfileIcon/2251employeeimage20230925121121_280.png");
    File capturedEnhancedFile = await _enhanceImage(file);
    File downloadedEnhancedFile = await _enhanceProfileImage(downloadedFile);
    final inputImage = InputImage.fromFilePath(downloadedFile.path);
    final faces = await _faceDetector.processImage(inputImage);
    cropProfile(faces[0], downloadedEnhancedFile);
    print("enhanced file ${capturedEnhancedFile.path}");

    double faceMatchScore = await FaceMatching()
        .loadModel(capturedEnhancedFile, downloadedEnhancedFile);
    print("faceMatchScore ${faceMatchScore}");

    if (faceMatchScore > 0.9) {
      Alerts.showAlertDialog(buildContext, "Face Matched Successfully.",
          imagePath: "assets/assets_correct.png",
          Title: "Face Recognition", onpressed: () {
        Navigator.pushReplacementNamed(buildContext, AppRoutes.FaceDetectView);
      }, buttontext: "ok", buttoncolor: Colors.green);
    } else {
      Alerts.showAlertDialog(buildContext, "Face Not Matched",
          imagePath: "assets/assets_error.png",
          Title: "Face Recognition", onpressed: () {
        Navigator.pushReplacementNamed(buildContext, AppRoutes.FaceDetectView);
      }, buttontext: "ok");
      // Campreefee api call
      /*   print("campreefee api call----------------");
      final response = await _faceMatchingRepository.FaceMatchingInfoNew(
          capturedEnhancedFile, downloadedFile, context);
      print(
          "response in view model ${response.result?[0].faceMatches?[0].similarity}");
      if (response != "" || response != []) {
        if (response.result != null) {
          if (response.result != null &&
              response.result!.isNotEmpty &&
              response.result![0].faceMatches != null &&
              response.result![0].faceMatches!.isNotEmpty &&
              response.result![0].faceMatches![0].similarity != null &&
              response.result![0].faceMatches![0].similarity! > 0.9) {
            Alerts.showAlertDialog(context, "Face Matched Successfully.",
                imagePath: "assets/assets_correct.png",
                Title: "Face Recognition", onpressed: () {
              Navigator.pushReplacementNamed(context, AppRoutes.FaceDetectView);
            }, buttontext: "ok", buttoncolor: Colors.green);
          } else {
            Alerts.showAlertDialog(context, "Face Not Matched.",
                imagePath: "assets/assets_error.png",
                Title: "Face Recognition", onpressed: () {
              Navigator.pushReplacementNamed(context, AppRoutes.FaceDetectView);
            }, buttontext: "ok");
          }
        } else {
          Alerts.showAlertDialog(context, response.message,
              imagePath: "assets/assets_error.png",
              Title: "Face Recognition", onpressed: () {
            Navigator.pushReplacementNamed(context, AppRoutes.FaceDetectView);
          }, buttontext: "ok");
        }
      } else {
        Alerts.showAlertDialog(
            context, "Something Went Wrong, Please Try Again Later.",
            imagePath: "assets/assets_error.png",
            Title: "Face Recognition", onpressed: () {
          Navigator.pushReplacementNamed(context, AppRoutes.FaceDetectView);
        }, buttontext: "ok");
      } */
    }
  }

  bool isLoaderVisible = false;
  changeLoaderState(bool state) {
    isLoaderVisible = state;
    notifyListeners();
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

    return compressedFile;
  }

  Future<File> _enhanceImage(File? file) async {
    img.Image? image = img.decodeImage(await file!.readAsBytes());
    // Example: Increase brightness and contrast
    img.adjustColor(
      image!,
      brightness: 1.2,
    );
    // Save the enhanced image
    Directory tempDir = await getTemporaryDirectory();
    File enhancedFile = File('${tempDir.path}/enhanced_image.jpg');
    enhancedFile.writeAsBytesSync(img.encodeJpg(image));
    return enhancedFile;
  }

  Future<File> _enhanceProfileImage(File? file) async {
    img.Image? image = img.decodeImage(await file!.readAsBytes());
    // Example: Increase brightness and contrast
    img.adjustColor(
      image!,
      brightness: 1.2,
    );
    // Save the enhanced image
    Directory tempDir = await getTemporaryDirectory();
    File enhancedFile = File('${tempDir.path}/enhancedProfileImage.jpg');
    enhancedFile.writeAsBytesSync(img.encodeJpg(image));
    return enhancedFile;
  }

  cropProfile(Face? detectedFace, File? profileImage) async {
    img.Image capturedImage =
        img.decodeImage(File(profileImage?.path ?? "").readAsBytesSync())!;
    if (detectedFace != null && detectedFace.boundingBox != null) {
      img.Image faceCrop = img.copyCrop(
        capturedImage,
        x: detectedFace.boundingBox.left.toInt() - 50,
        y: detectedFace.boundingBox.top.toInt() - 100,
        width: detectedFace.boundingBox.width.toInt() + 120,
        height: detectedFace.boundingBox.height.toInt() + 120,
      );
      final jpg = img.encodeJpg(faceCrop);
      cropSaveFile = File(profileImage?.path ?? "");
      await cropSaveFile?.writeAsBytes(jpg);
      print("cropSaveFile path ${cropSaveFile?.path}");
    }
  }
}
