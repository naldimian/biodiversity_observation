import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:geolocator/geolocator.dart';
import 'package:heif_converter/heif_converter.dart';
import 'package:path/path.dart' as p;

import 'package:cubaankedua/helper/exif_helper.dart';

class UploadService {
  static Future<void> uploadImage({
    required File imageFile,
    required String userId,
    required String username,
    required String selectedType,
  }) async {
    final exifHelper = ExifHelper();

    File finalImageFile = imageFile;

    // STEP 1: Extract GPS from original file
    final gpsTags = await exifHelper.getExifDataWithCacheAndThrottle(imageFile);
    if (!gpsTags.containsKey('GPSLatitude') || !gpsTags.containsKey('GPSLongitude')) {
      throw Exception("Image does not contain GPS metadata.");
    }

    // STEP 2: Convert HEIC to JPG if needed
    final isHeic = imageFile.path.toLowerCase().endsWith('.heic');
    if (isHeic) {
      final convertedPath = await HeifConverter.convert(imageFile.path);
      if (convertedPath == null) throw Exception("Failed to convert HEIC to JPG");
      finalImageFile = File(convertedPath);
    }

    // STEP 3: Extract decimal lat/lng
    final latitude = ExifHelper.convertToDecimal(
      ExifHelper.extractDMS(gpsTags['GPSLatitude']),
      gpsTags['GPSLatitudeRef']?.printable ?? 'N',
    );
    final longitude = ExifHelper.convertToDecimal(
      ExifHelper.extractDMS(gpsTags['GPSLongitude']),
      gpsTags['GPSLongitudeRef']?.printable ?? 'E',
    );

    // STEP 4: Upload image to Firebase Storage
    final fileName = '${DateTime.now().millisecondsSinceEpoch}.jpg';
    final storageRef = FirebaseStorage.instance.ref().child('uploads/$fileName');
    final snapshot = await storageRef.putFile(finalImageFile);
    final imageUrl = await snapshot.ref.getDownloadURL();

    // STEP 5: Store metadata to Firestore
    final data = {
      'imageUrl': imageUrl,
      'type': selectedType,
      'timestamp': FieldValue.serverTimestamp(),
      'location': GeoPoint(latitude, longitude),
      'userId': userId,
      'username': username,
    };

    await FirebaseFirestore.instance.collection('uploads').add(data);
  }
}
