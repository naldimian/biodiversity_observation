import 'dart:io';

import 'package:flutter/material.dart';
import 'package:cubaankedua/widgets/image_picker_section.dart';
import 'package:cubaankedua/widgets/dropdown_section.dart';
import 'package:cubaankedua/widgets/upload_button_section.dart';
import 'package:cubaankedua/helper/upload_service.dart';

class UploadForm extends StatefulWidget {
  final String userId;
  final String username;

  const UploadForm({super.key, required this.userId, required this.username});

  @override
  State<UploadForm> createState() => _UploadFormState();
}

class _UploadFormState extends State<UploadForm> {
  String _selectedType = 'Mammal';
  File? _imageFile;
  double? _latitude;
  double? _longitude;
  bool _isUploading = false;

  // Update _setImage to handle latitude and longitude as well
  void _setImage(File? file, double? lat, double? lon) {
    setState(() {
      _imageFile = file;
      _latitude = lat;
      _longitude = lon;
    });
  }

  void _setType(String? value) =>
      setState(() => _selectedType = value ?? _selectedType);

  Future<void> _upload() async {
    if (_imageFile == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please select an image first.")),
      );
      return;
    }

    setState(() => _isUploading = true);

    try {
      await UploadService.uploadImage(
        imageFile: _imageFile!,
        userId: widget.userId,
        username: widget.username,
        selectedType: _selectedType,
      );

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Upload successful!")),
      );

      setState(() {
        _imageFile = null;
        _selectedType = 'Mammal';
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Upload failed: $e")),
      );
    } finally {
      setState(() => _isUploading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        ImagePickerSection(
          imageFile: _imageFile,
          onImageSelected: _setImage, // Passing the updated callback
        ),
        const SizedBox(height: 16),
        DropdownSection(selectedType: _selectedType, onChanged: _setType),
        const SizedBox(height: 16),
        UploadButtonSection(isUploading: _isUploading, onPressed: _upload),
      ],
    );
  }
}
