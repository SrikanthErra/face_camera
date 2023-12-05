import 'package:face_liveness/faceDetectView.dart';

import 'package:face_liveness/res/routes/app_routes.dart';
import 'package:face_liveness/view/GenerateQrView.dart';
import 'package:face_liveness/view/faceRecognitionView.dart';
import 'package:flutter/material.dart';

class AppPages {
  static Map<String, WidgetBuilder> get routes {
    return {
      //AppRoutes.initial: ((context) => FaceDetectView()),
      AppRoutes.FaceDetectView: ((context) => FaceDetectView()),
      AppRoutes.FaceRecognitionView: ((context) => FaceRecognitionView()),
      AppRoutes.qrgenerator: ((context) => GenerateQR()),
    };
  }
}
