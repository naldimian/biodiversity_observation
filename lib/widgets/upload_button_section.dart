import 'package:flutter/material.dart';

class UploadButtonSection extends StatelessWidget {
  final bool isUploading;
  final VoidCallback onPressed;

  const UploadButtonSection({
    super.key,
    required this.isUploading,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: isUploading ? null : onPressed,
      child: isUploading
          ? const CircularProgressIndicator(color: Colors.white)
          : const Text("Upload"),
    );
  }
}
