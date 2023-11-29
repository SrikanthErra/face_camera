import 'dart:io';

import 'package:dio/dio.dart';
import 'package:face_liveness/data/baseApiClient.dart';
import 'package:face_liveness/model/faceMatchingResponse.dart';
import 'package:flutter/material.dart';

class FaceMatchingRepository {
  final _baseClient = BaseApiClient();
  Future<FaceMatchingResponse> FaceMatchingInfoNew(
      File sourceImageFile, File targetImageFile, BuildContext context) async {
    print("repositoryyy file ${sourceImageFile.path}, ${targetImageFile.path}");
    FormData? formData;
    Map<String, dynamic> payload = {};
    try {
      formData = FormData.fromMap(
        {
          'source_image': await MultipartFile.fromFile(
            sourceImageFile.path,
            filename: sourceImageFile.path.split('/').last,
          ),
          'target_image': await MultipartFile.fromFile(
            targetImageFile.path,
            filename: targetImageFile.path.split('/').last,
          ),
        },
      );
      

      print("formdata ${formData.files.first.value}");
    } catch (e) {
      print("Error creating FormData: $e");
    }
    //print("formdata ${formData}");
    try {
      if (formData != null) {
        final faceMatchResponse =
            await _baseClient.postCall(context, "Face/Facematch", formData);

        return FaceMatchingResponse.fromJson(faceMatchResponse);
      } else {
        print("formdata is null");
      }
      return FaceMatchingResponse();
    } catch (e) {
      // Handle errors here
      print("Error: $e");
      return FaceMatchingResponse(); // Re-throw the error for the calling code to handle if needed
    }
  }
}
