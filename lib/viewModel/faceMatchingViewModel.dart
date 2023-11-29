import 'dart:io';
import 'dart:math';
import 'package:http/http.dart' as http;
import 'package:dio/dio.dart';
import 'package:path_provider/path_provider.dart';
import 'package:face_liveness/repository/faceMatchingRepository.dart';
import 'package:flutter/material.dart';
import 'package:path/path.dart' as path;
import 'package:shared_preferences/shared_preferences.dart';

class FaceMatchingViewModel with ChangeNotifier {
  final _faceMatchingRepository = FaceMatchingRepository();

  File sourceImageFile = File("");
  File targetImageFile = File("");

  Future<void> faceMatchingApiCall(BuildContext context, File file) async {
    try {
      changeLoaderState(true);

  
      File downloadedFile = await urlToFile(
          "https://virtuo.cgg.gov.in/EmployeeProfileIcon/2254employeeimage20231113172753_052.png");
      

      // targetImageFile = File(res);
      SharedPreferences prefs = await SharedPreferences.getInstance();
      if (sourceImageFile != null || targetImageFile != null) {
        final response = await _faceMatchingRepository.FaceMatchingInfoNew(
            file, downloadedFile, context);
        print("------------- ${response.message}");
        if (response != "" || response != []) {
          if (response.result != null) {
            changeLoaderState(false);
            response.result?.forEach((element) {
              print("responseeeeeee ${element.sourceImageFace}");
            });
            notifyListeners();
          } else {
            /*   changeLoaderState(false);
          Alerts.showAlertDialog(context, response.statusMessage,
              Title: "app_name".tr(), onpressed: () {
            Navigator.pop(context);
          }, buttontext: "ok".tr()); */
          }
        } else {
          /*  changeLoaderState(false);
        Alerts.showAlertDialog(
            context, "${"server_not".tr()}, ${"try_again".tr()}.",
            Title: "app_name".tr(), onpressed: () {
          Navigator.pop(context);
        }, buttontext: "ok".tr()); */
        }
      }
    } catch (e) {
      /*   changeLoaderState(false);
      Alerts.showAlertDialog(
          context, "${"server_not".tr()}, ${"try_again".tr()}.",
          Title: "app_name".tr(), onpressed: () {
        Navigator.pop(context);
      }, buttontext: "ok".tr()); */
    }
  }

  bool isLoaderVisible = false;
  changeLoaderState(bool state) {
    isLoaderVisible = state;
    notifyListeners();
  }

  String extractFileNameFromUrl(String url) {
    Uri uri = Uri.parse(url);

    String fileName = path.basename(uri.path);
    // print("file nameee ${fileName}");
    return fileName;
  }

  Future<File> urlToFile(String imageUrl) async {
  
    var rng = new Random();
  
    Directory tempDir = await getTemporaryDirectory();
  
    String tempPath = tempDir.path;
   
    File file = new File('$tempPath/' + (rng.nextInt(100)).toString() + '.png');
    
    Uri uri = Uri.parse(imageUrl);
    // call http.get method and pass Uri instead of String.
    http.Response response = await http.get(uri);
    // write bodyBytes received in response to file.
    await file.writeAsBytes(response.bodyBytes);
    // now return the file which is created with a random name in
    // the temporary directory, and image bytes from the response are written to that file.
    return file;
  }

  Future<String> downloadFile(String url, String baseFileName, context) async {
    print('Downloading file from $url');
    Directory? externalDir;
    externalDir = Directory('/data/user/0/com.example.face_liveness/cache');
    print('External Storage Directory: ${externalDir.path}');
    int counter = 0;
    String fileName = baseFileName;

    while (await File('${externalDir.path}/$fileName').exists()) {
      counter++;
      String extension = path.extension(baseFileName);
      String fileNameWithoutExtension =
          path.basenameWithoutExtension(baseFileName);
      fileName = '$fileNameWithoutExtension($counter)$extension';
    }

    final filePath = '${externalDir.path}/$fileName';
    print('File path to download: $filePath');

    final dio = Dio();

    try {
      await dio.download(url, filePath,
          onReceiveProgress: (actualBytes, totalBytes) {
        var percentage = actualBytes / totalBytes * 100;
        if (percentage < 100) {
          //EasyLoading.showProgress(percentage, status: "Downloading...");
        } else {
          return;
          //EasyLoading.dismiss;
          //AppToast().showToast("$fileName is downloaded in Download Folder");
        }
      });
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) {
        print('Error downloading file: File not found');
      } else {
        print('Error downloading file: ${e.message}');
      }
      return "";
    } catch (error) {
      print('Error downloading file: $error');
      return "";
    }

    print('File downloaded to $filePath');
    notifyListeners();
    return filePath;
  }
}
