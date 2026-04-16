/*
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cached_network_image/cached_network_image.dart';

class AllObservationsMapPage extends StatefulWidget {
  // NEW: Optional parameters to focus on a specific observation
  final Map<String, dynamic>? focusObservation;
  final String? focusDocId;

  const AllObservationsMapPage({
    super.key,
    this.focusObservation,
    this.focusDocId,
  });

  @override
  State<AllObservationsMapPage> createState() => _AllObservationsMapPageState();
}

class _AllObservationsMapPageState extends State<AllObservationsMapPage> {
  late GoogleMapController mapController;
  Map<String, dynamic>? selectedObservation;

  // Default fallback position (Johor bounds)
  LatLng initialCameraPosition = const LatLng(1.5535, 103.6356);
  double initialZoom = 8.0;

  @override
  void initState() {
    super.initState();

    // NEW: If we navigated here from a specific observation, center on it!
    if (widget.focusObservation != null) {
      selectedObservation = widget.focusObservation;

      final lat = widget.focusObservation!['Latitude'] as double?;
      final lon = widget.focusObservation!['Longitude'] as double?;

      if (lat != null && lon != null) {
        initialCameraPosition = LatLng(lat, lon);
        initialZoom = 16.0; // Zoom in tight on the specific subject
      }
    }
  }

  void _onMapCreated(GoogleMapController controller) {
    mapController = controller;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Observation Map"),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('observations').snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return const Center(child: Text("Error loading map data."));
          }

          final observations = snapshot.data?.docs ?? [];
          Set<Marker> markers = {};

          for (var doc in observations) {
            final data = doc.data() as Map<String, dynamic>;
            final lat = data['Latitude'] as double?;
            final lon = data['Longitude'] as double?;

            if (lat != null && lon != null && lat >= -90 && lat <= 90 && lon >= -180 && lon <= 180) {

              // Highlight the targeted marker slightly differently if desired
              final isFocused = widget.focusDocId == doc.id;

              markers.add(
                Marker(
                  markerId: MarkerId(doc.id),
                  position: LatLng(lat, lon),
                  // Optional: Change color if it's the focused marker
                  icon: isFocused
                      ? BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueAzure)
                      : BitmapDescriptor.defaultMarker,
                  onTap: () {
                    setState(() {
                      selectedObservation = data;
                    });
                    mapController.animateCamera(
                      CameraUpdate.newLatLng(LatLng(lat, lon)),
                    );
                  },
                ),
              );
            }
          }

          return Stack(
            children: [
              GoogleMap(
                mapType: MapType.hybrid,
                initialCameraPosition: CameraPosition(
                  target: initialCameraPosition,
                  zoom: initialZoom,
                ),
                onMapCreated: _onMapCreated,
                markers: markers,
                myLocationEnabled: true,
                myLocationButtonEnabled: true,
                zoomControlsEnabled: false,
                onTap: (_) {
                  setState(() {
                    selectedObservation = null;
                  });
                },
              ),

              if (selectedObservation != null)
                Positioned(
                  bottom: 30,
                  left: 16,
                  right: 16,
                  child: Card(
                    elevation: 8,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    color: Theme.of(context).colorScheme.surface,
                    child: Padding(
                      padding: const EdgeInsets.all(12.0),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(10),
                            child: CachedNetworkImage(
                              imageUrl: selectedObservation!['ImageURL'] ?? '',
                              height: 80,
                              width: 80,
                              fit: BoxFit.cover,
                              placeholder: (context, url) => Container(
                                height: 80,
                                width: 80,
                                color: Theme.of(context).colorScheme.surfaceVariant,
                                child: const Center(child: CircularProgressIndicator()),
                              ),
                              errorWidget: (context, url, error) => const Icon(Icons.broken_image),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  selectedObservation!['CommonName'] ?? 'Unknown',
                                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  selectedObservation!['SpeciesName'] ?? 'Unknown',
                                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    fontStyle: FontStyle.italic,
                                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: Theme.of(context).colorScheme.primaryContainer,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    selectedObservation!['OrganismType'] ?? 'Unknown',
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color: Theme.of(context).colorScheme.onPrimaryContainer,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.close),
                            onPressed: () {
                              setState(() {
                                selectedObservation = null;
                              });
                            },
                          )
                        ],
                      ),
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
  */

import 'dart:async';
import 'dart:ui';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart' hide ClusterManager, Cluster;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cached_network_image/cached_network_image.dart';

// NEW IMPORT HERE
import 'package:google_maps_cluster_manager_2/google_maps_cluster_manager_2.dart';

class ObservationItem with ClusterItem {
  final String id;
  final LatLng latLng;
  final Map<String, dynamic> data;

  ObservationItem({
    required this.id,
    required this.latLng,
    required this.data,
  });

  @override
  LatLng get location => latLng;
}
class AllObservationsMapPage extends StatefulWidget {
  final Map<String, dynamic>? focusObservation;
  final String? focusDocId;

  const AllObservationsMapPage({
    super.key,
    this.focusObservation,
    this.focusDocId,
  });

  @override
  State<AllObservationsMapPage> createState() => _AllObservationsMapPageState();
}

class _AllObservationsMapPageState extends State<AllObservationsMapPage> {
  late GoogleMapController mapController;
  late ClusterManager _manager;

  Set<Marker> markers = {};
  Map<String, dynamic>? selectedObservation;
  StreamSubscription<QuerySnapshot>? _obsSubscription;

  LatLng initialCameraPosition = const LatLng(1.5535, 103.6356);
  double initialZoom = 8.0;

  @override
  void initState() {
    super.initState();

    // Initialize the Cluster Manager
    _manager = ClusterManager<ObservationItem>(
      [], // Initially empty, will be filled by the Firestore stream
      _updateMarkers,
      markerBuilder: _markerBuilder,
    );

    // Focus on specific observation if navigated from the list
    if (widget.focusObservation != null) {
      selectedObservation = widget.focusObservation;
      final lat = widget.focusObservation!['Latitude'] as double?;
      final lon = widget.focusObservation!['Longitude'] as double?;
      if (lat != null && lon != null) {
        initialCameraPosition = LatLng(lat, lon);
        initialZoom = 17.0;
      }
    }

    // Listen to Firestore in the background (Performance Boost over StreamBuilder)
    _obsSubscription = FirebaseFirestore.instance
        .collection('observations')
        .snapshots()
        .listen((snapshot) {
      List<ObservationItem> items = [];
      for (var doc in snapshot.docs) {
        final data = doc.data();
        final lat = data['Latitude'] as double?;
        final lon = data['Longitude'] as double?;

        if (lat != null && lon != null && lat >= -90 && lat <= 90 && lon >= -180 && lon <= 180) {
          items.add(ObservationItem(id: doc.id, latLng: LatLng(lat, lon), data: data));
        }
      }
      // Feed the new data to the Cluster Manager
      _manager.setItems(items);
    });
  }

  @override
  void dispose() {
    // Prevent memory leaks
    _obsSubscription?.cancel();
    super.dispose();
  }

  void _onMapCreated(GoogleMapController controller) {
    mapController = controller;
    _manager.setMapId(controller.mapId);
  }

  void _updateMarkers(Set<Marker> markers) {
    setState(() {
      this.markers = markers;
    });
  }

  // 2. Defines what a marker looks like (Cluster Bubble vs. Single Pin)
  Future<Marker> Function(Cluster<ObservationItem>) get _markerBuilder =>
          (cluster) async {
        return Marker(
          markerId: MarkerId(cluster.getId()),
          position: cluster.location,
          onTap: () async {
            if (cluster.isMultiple) {
              // Tap a cluster: Zoom in to break it apart
              final zoom = await mapController.getZoomLevel();
              mapController.animateCamera(CameraUpdate.newLatLngZoom(cluster.location, zoom + 2));
            } else {
              // Tap a single item: Show the observation card
              setState(() {
                selectedObservation = cluster.items.first.data;
              });
              mapController.animateCamera(CameraUpdate.newLatLng(cluster.location));
            }
          },
          // Use a custom bubble for clusters, and the default red pin for single observations
          icon: cluster.isMultiple
              ? await _getClusterBitmap(cluster.count.toString())
              : BitmapDescriptor.defaultMarker,
        );
      };

  // 3. Custom Canvas drawing for the Cluster Bubble
  Future<BitmapDescriptor> _getClusterBitmap(String text) async {
    const int size = 120;
    final PictureRecorder pictureRecorder = PictureRecorder();
    final Canvas canvas = Canvas(pictureRecorder);
    final Paint paint = Paint()..color = Theme.of(context).colorScheme.primary.withOpacity(0.9);

    canvas.drawCircle(const Offset(size / 2, size / 2), size / 2.0, paint);

    TextPainter painter = TextPainter(textDirection: TextDirection.ltr);
    painter.text = TextSpan(
      text: text,
      style: const TextStyle(
        fontSize: 40,
        color: Colors.white,
        fontWeight: FontWeight.bold,
      ),
    );
    painter.layout();
    painter.paint(
      canvas,
      Offset(size / 2 - painter.width / 2, size / 2 - painter.height / 2),
    );

    final img = await pictureRecorder.endRecording().toImage(size, size);
    final data = await img.toByteData(format: ImageByteFormat.png);
    return BitmapDescriptor.fromBytes(data!.buffer.asUint8List());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Observation Map"),
      ),
      body: Stack(
        children: [
          GoogleMap(
            mapType: MapType.hybrid,
            initialCameraPosition: CameraPosition(
              target: initialCameraPosition,
              zoom: initialZoom,
            ),
            onMapCreated: _onMapCreated,
            markers: markers, // Provided by the Cluster Manager
            onCameraMove: _manager.onCameraMove, // Crucial: updates clusters when swiping
            onCameraIdle: _manager.updateMap,    // Crucial: repaints clusters when stopped
            myLocationEnabled: true,
            myLocationButtonEnabled: true,
            zoomControlsEnabled: false,
            onTap: (_) {
              // Tap the empty map to hide the card
              setState(() {
                selectedObservation = null;
              });
            },
          ),

          // The Observation Info Card Overlay
          if (selectedObservation != null)
            Positioned(
              bottom: 30,
              left: 16,
              right: 16,
              child: Card(
                elevation: 8,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                color: Theme.of(context).colorScheme.surface,
                child: Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: CachedNetworkImage(
                          imageUrl: selectedObservation!['ImageURL'] ?? '',
                          height: 80,
                          width: 80,
                          fit: BoxFit.cover,
                          placeholder: (context, url) => Container(
                            height: 80,
                            width: 80,
                            color: Theme.of(context).colorScheme.surfaceVariant,
                            child: const Center(child: CircularProgressIndicator()),
                          ),
                          errorWidget: (context, url, error) => const Icon(Icons.broken_image),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              selectedObservation!['CommonName'] ?? 'Unknown',
                              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              selectedObservation!['SpeciesName'] ?? 'Unknown',
                              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                fontStyle: FontStyle.italic,
                                color: Theme.of(context).colorScheme.onSurfaceVariant,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: Theme.of(context).colorScheme.primaryContainer,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                selectedObservation!['OrganismType'] ?? 'Unknown',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: Theme.of(context).colorScheme.onPrimaryContainer,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () {
                          setState(() {
                            selectedObservation = null;
                          });
                        },
                      )
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}