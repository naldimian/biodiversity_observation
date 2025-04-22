import 'dart:io';
import 'dart:async';
import 'package:exif/exif.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';

class ExifHelper {
  final cacheManager = DefaultCacheManager(); // Cache manager instance
  Timer? _debounceTimer;

  // Fetch the EXIF data with cache and throttle support
  Future<Map<String, IfdTag>> getExifDataWithCacheAndThrottle(File imageFile) async {
    final filePath = imageFile.path;

    // Return a Future that will complete after the debounce timer
    final Completer<Map<String, IfdTag>> completer = Completer();

    // Throttle multiple requests for the same image
    if (_debounceTimer?.isActive ?? false) {
      _debounceTimer?.cancel(); // Cancel the previous timer
    }

    // Delay the metadata extraction to prevent spamming
    _debounceTimer = Timer(Duration(milliseconds: 500), () async {
      // Check if EXIF data is cached for the image
      final cachedFile = await cacheManager.getFileFromCache(filePath);

      Map<String, IfdTag> tags;
      if (cachedFile != null) {
        // If cached, use cached data
        tags = await compute(parseExifInBackground, cachedFile.file.path);
      } else {
        // If not cached, process and cache the EXIF data
        tags = await compute(parseExifInBackground, filePath);
        cacheManager.putFile(filePath, await imageFile.readAsBytes()); // Cache the file
      }

      // Complete the future with the EXIF data
      completer.complete(tags);
    });

    return completer.future; // Return the Future to the caller
  }

  // This method runs in the background thread via compute
  static Future<Map<String, IfdTag>> parseExifInBackground(String filePath) async {
    final file = File(filePath);
    final bytes = await file.readAsBytes(); // Asynchronous file reading
    final tags = await readExifFromBytes(bytes); // Process EXIF data (async)
    return tags ?? {}; // Return empty map if tags are null
  }

  static List<double> extractDMS(IfdTag? tag) {
    if (tag == null || tag.values.length != 3) {
      throw const FormatException("Invalid GPS DMS tag.");
    }

    final values = tag.values.toList(); // Convert IfdValues to List

    return values.map((value) {
      final str = value.toString();
      if (str.contains('/')) {
        final parts = str.split('/');
        return double.tryParse(parts[0])! / double.tryParse(parts[1])!;
      }
      return double.tryParse(str)!;
    }).toList();
  }

  static double convertToDecimal(List<double> dms, String ref) {
    double decimal = dms[0] + (dms[1] / 60.0) + (dms[2] / 3600.0);
    if (ref == 'S' || ref == 'W') decimal *= -1;
    return decimal;
  }
}
