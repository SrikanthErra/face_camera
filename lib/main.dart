import 'dart:io';
import 'package:face_liveness/antiSpoofing.dart';
import 'package:face_liveness/appconstants.dart';
import 'package:face_liveness/res/routes/app_pages.dart';
import 'package:face_liveness/res/routes/app_routes.dart';
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
  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (context) => FaceMatchingViewModel(),
        ),
      ],
      child: MaterialApp(
        title: 'FaceRecognition sample app',
        initialRoute: AppRoutes.initial,
        routes: AppPages.routes,
        debugShowCheckedModeBanner: false,
      ),
    );
  }
}
