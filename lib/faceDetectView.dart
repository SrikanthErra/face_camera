import 'package:face_liveness/res/routes/app_routes.dart';
import 'package:flutter/material.dart';

class FaceDetectView extends StatefulWidget {
  const FaceDetectView({
    super.key,
  });

  @override
  State<FaceDetectView> createState() => _FaceMatchViewState();
}

class _FaceMatchViewState extends State<FaceDetectView> {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        color: Colors.white,
        height: double.infinity,
        width: double.infinity,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(
              color: Colors.amber,
              child: TextButton(
                onPressed: () async {
              Navigator.pushNamed(context, AppRoutes.FaceRecognitionView);
                },
                child: Text("Face Match"),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
