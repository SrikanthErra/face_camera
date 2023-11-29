import 'dart:io';

import 'package:face_liveness/viewModel/faceMatchingViewModel.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class FaceMatchView extends StatefulWidget {
  const FaceMatchView({super.key, this.cropSaveFile});
  final File? cropSaveFile;

  @override
  State<FaceMatchView> createState() => _FaceMatchViewState();
}

class _FaceMatchViewState extends State<FaceMatchView> {
  @override
  Widget build(BuildContext context) {
    final faceMatchingProvider =
        Provider.of<FaceMatchingViewModel>(context, listen: false);
    return Container(
        child: TextButton(
      onPressed: () async {
        await faceMatchingProvider.faceMatchingApiCall(context, widget.cropSaveFile!);
      },
      child: Text("Face Match"),
    ));
  }

  
}
