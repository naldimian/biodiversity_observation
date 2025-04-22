import 'package:url_launcher/url_launcher.dart';

class MapLauncher {
  static Future<void> openInGoogleMaps(double lat, double lon) async {
    final url = Uri.parse("https://www.google.com/maps/search/?api=1&query=$lat,$lon");
    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    } else {
      throw Exception("Could not launch Google Maps.");
    }
  }
}
