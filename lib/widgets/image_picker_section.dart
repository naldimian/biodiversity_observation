// image_picker_section.dart
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:exif/exif.dart';

class ImagePickerSection extends StatelessWidget {
  final File? imageFile;
  final Function(File? image, double? lat, double? lon) onImageSelected;

  const ImagePickerSection({
    super.key,
    required this.imageFile,
    required this.onImageSelected,
  });

  Future<void> _pickImage(BuildContext context) async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery);
    if (picked == null) {
      onImageSelected(null, null, null);
      return;
    }

    final bytes = await picked.readAsBytes();
    final tags = await readExifFromBytes(bytes);

    if (tags.containsKey('GPS GPSLatitude') &&
        tags.containsKey('GPS GPSLatitudeRef') &&
        tags.containsKey('GPS GPSLongitude') &&
        tags.containsKey('GPS GPSLongitudeRef')) {
      final latValues = _extractDMS(tags['GPS GPSLatitude']);
      final lonValues = _extractDMS(tags['GPS GPSLongitude']);
      final latRef = tags['GPS GPSLatitudeRef']!.printable;
      final lonRef = tags['GPS GPSLongitudeRef']!.printable;

      double lat = _convertToDecimal(latValues, latRef);
      double lon = _convertToDecimal(lonValues, lonRef);

      if (lat < -90 || lat > 90 || lon < -180 || lon > 180) {
        _showErrorDialog(context, "Invalid Location", "⚠️ Extracted coordinates are out of valid range.");
        onImageSelected(null, null, null);
        return;
      }

      _showErrorDialog(context, "Location Found", "📍 Location: $lat, $lon");
      onImageSelected(File(picked.path), lat, lon);
    } else {
      _showErrorDialog(context, "Missing Location Info", "❌ This image does not contain GPS location metadata.");
      onImageSelected(null, null, null);
    }
  }

  List<double> _extractDMS(IfdTag? tag) {
    if (tag == null || tag.values.length != 3) {
      throw const FormatException("Invalid GPS DMS tag.");
    }

    final dmsList = <double>[];
    for (var value in tag.values.toList()) {
      final valueStr = value.toString();
      if (valueStr.contains('/')) {
        final parts = valueStr.split('/');
        final numerator = double.tryParse(parts[0]) ?? 0;
        final denominator = double.tryParse(parts[1]) ?? 1;
        dmsList.add(numerator / denominator);
      } else {
        dmsList.add(double.tryParse(valueStr) ?? 0);
      }
    }
    return dmsList;
  }

  double _convertToDecimal(List<double> dms, String ref) {
    double decimal = dms[0] + (dms[1] / 60.0) + (dms[2] / 3600.0);
    if (ref == 'S' || ref == 'W') decimal *= -1;
    return decimal;
  }

  void _showErrorDialog(BuildContext context, String title, String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("OK"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        ElevatedButton.icon(
          icon: const Icon(Icons.image),
          label: const Text("Select Image"),
          onPressed: () => _pickImage(context),
        ),
        const SizedBox(height: 10),
        imageFile != null
            ? ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Image.file(imageFile!, height: 150),
        )
            : const Text("No image selected."),
      ],
    );
  }
}
