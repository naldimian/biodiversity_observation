import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:timeago/timeago.dart' as timeago;
import '../helper/map_launcher.dart';

class ObservationCard extends StatelessWidget {
  final Map<String, dynamic> data;

  const ObservationCard({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    final latitude = data['Latitude'];
    final longitude = data['Longitude'];
    final imageUrl = data['ImageURL'];
    final timestamp = data['Timestamp'];

    String formattedTime = 'Unknown time';
    if (timestamp != null) {
      final uploadDate = timestamp.toDate();
      final now = DateTime.now();
      final difference = now.difference(uploadDate);
      formattedTime = difference.inHours > 23
          ? DateFormat('d MMMM yyyy').format(uploadDate)
          : timeago.format(uploadDate);
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("${data['CommonName']} (${data['SpeciesName']})",
                style: const TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: CachedNetworkImage(
                    imageUrl: imageUrl,
                    height: 150,
                    width: 150,
                    fit: BoxFit.cover,
                    placeholder: (context, url) =>
                    const Center(child: CircularProgressIndicator()),
                    errorWidget: (context, url, error) => const Icon(Icons.error),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text("${data['OrganismType']}"),
                      Text("${data['UserEmail']}"),
                      Text(latitude != null && longitude != null
                          ? "Location: $latitude, $longitude"
                          : "Location: Not available"),
                      Text("$formattedTime"),
                      const SizedBox(height: 25),
                      if (latitude != null && longitude != null)
                        TextButton.icon(
                          icon: const Icon(Icons.location_on, color: Colors.red),
                          label: const Text("Open in Maps"),
                          onPressed: () {
                            MapLauncher.openInGoogleMaps(latitude, longitude);
                          },
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
