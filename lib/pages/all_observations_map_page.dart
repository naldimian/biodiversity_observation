/*
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
// The Observation Info Card Overlay (Centered, Large)
          if (selectedObservation != null)
            Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0),
                child: Card(
                  elevation: 12,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                  clipBehavior: Clip.antiAlias, // Ensures the image respects the card's rounded corners
                  color: Theme.of(context).colorScheme.surface,
                  child: Stack(
                    children: [
                      Column(
                        mainAxisSize: MainAxisSize.min, // Wraps content tightly
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          // 1. Large Image on Top
                          CachedNetworkImage(
                            imageUrl: selectedObservation!['ImageURL'] ?? '',
                            height: 250, // Much larger image height
                            fit: BoxFit.cover,
                            placeholder: (context, url) => Container(
                              height: 250,
                              color: Theme.of(context).colorScheme.surfaceVariant,
                              child: const Center(child: CircularProgressIndicator()),
                            ),
                            errorWidget: (context, url, error) => Container(
                              height: 250,
                              color: Theme.of(context).colorScheme.surfaceVariant,
                              child: const Icon(Icons.broken_image, size: 50),
                            ),
                          ),

                          // 2. Text Details Below
                          Padding(
                            padding: const EdgeInsets.all(20.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  selectedObservation!['CommonName'] ?? 'Unknown',
                                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  selectedObservation!['SpeciesName'] ?? 'Unknown',
                                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                    fontStyle: FontStyle.italic,
                                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                                  ),
                                ),
                                const SizedBox(height: 16),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                  decoration: BoxDecoration(
                                    color: Theme.of(context).colorScheme.primaryContainer,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    selectedObservation!['OrganismType'] ?? 'Unknown',
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                      color: Theme.of(context).colorScheme.onPrimaryContainer,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),

                      // 3. Close Button (Floating Top Right)
                      Positioned(
                        top: 8,
                        right: 8,
                        child: Container(
                          decoration: const BoxDecoration(
                            color: Colors.black45, // Semi-transparent so it's always visible over the image
                            shape: BoxShape.circle,
                          ),
                          child: IconButton(
                            icon: const Icon(Icons.close, color: Colors.white),
                            onPressed: () {
                              setState(() {
                                selectedObservation = null;
                              });
                            },
                          ),
                        ),
                      ),
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

 */
import 'dart:async';
import 'dart:ui';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart' hide ClusterManager, Cluster;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cached_network_image/cached_network_image.dart';

// NEW IMPORTS
import 'package:google_maps_cluster_manager_2/google_maps_cluster_manager_2.dart';
import 'package:intl/intl.dart' hide TextDirection;
import 'package:geocoding/geocoding.dart';

import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart'; // NEW: Required for the interactive map

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

  // NEW: State for the mini-map address
  String _currentAddress = "Loading location...";

  @override
  void initState() {
    super.initState();

    _manager = ClusterManager<ObservationItem>(
      [],
      _updateMarkers,
      markerBuilder: _markerBuilder,
    );

    if (widget.focusObservation != null) {
      selectedObservation = widget.focusObservation;
      final lat = widget.focusObservation!['Latitude'] as double?;
      final lon = widget.focusObservation!['Longitude'] as double?;
      if (lat != null && lon != null) {
        initialCameraPosition = LatLng(lat, lon);
        initialZoom = 17.0;
        _fetchAddress(lat, lon); // Fetch address on load
      }
    }

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
      _manager.setItems(items);
    });
  }

  @override
  void dispose() {
    _obsSubscription?.cancel();
    super.dispose();
  }

  // NEW: Helper method to format the Timestamp
  String _formatTimestamp(dynamic timestamp) {
    if (timestamp == null) return "Unknown Date";
    DateTime date;
    if (timestamp is Timestamp) {
      date = timestamp.toDate();
    } else {
      return "Unknown Date";
    }
    return DateFormat('MMM d • HH:mm').format(date);
  }

  // NEW: Helper method to get the address string from coordinates
  Future<void> _fetchAddress(double lat, double lon) async {
    try {
      List<Placemark> placemarks = await placemarkFromCoordinates(lat, lon);
      if (placemarks.isNotEmpty) {
        final place = placemarks.first;
        setState(() {
          // Creates a clean string like "Walkerton, ON, Canada"
          _currentAddress = [place.locality, place.administrativeArea, place.country]
              .where((e) => e != null && e!.isNotEmpty)
              .join(', ');
        });
      }
    } catch (e) {
      setState(() {
        _currentAddress = "${lat.toStringAsFixed(5)}, ${lon.toStringAsFixed(5)}";
      });
    }
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

  Future<Marker> Function(Cluster<ObservationItem>) get _markerBuilder =>
          (cluster) async {
        return Marker(
          markerId: MarkerId(cluster.getId()),
          position: cluster.location,
          onTap: () async {
            if (cluster.isMultiple) {
              final zoom = await mapController.getZoomLevel();
              mapController.animateCamera(CameraUpdate.newLatLngZoom(cluster.location, zoom + 2));
            } else {
              final data = cluster.items.first.data;
              setState(() {
                selectedObservation = data;
                _currentAddress = "Loading location..."; // Reset address string
              });

              // Fetch the address for the mini-map
              _fetchAddress(data['Latitude'], data['Longitude']);

              mapController.animateCamera(CameraUpdate.newLatLng(cluster.location));
            }
          },
          icon: cluster.isMultiple
              ? await _getClusterBitmap(cluster.count.toString())
              : BitmapDescriptor.defaultMarker,
        );
      };

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
      appBar: selectedObservation != null
          ? null // Hide main app bar if overlay is showing
          : AppBar(title: const Text("Observation Map")),
      body: Stack(
        children: [
          // Background Global Map
          GoogleMap(
            mapType: MapType.hybrid,
            initialCameraPosition: CameraPosition(
              target: initialCameraPosition,
              zoom: initialZoom,
            ),
            onMapCreated: _onMapCreated,
            markers: markers,
            onCameraMove: _manager.onCameraMove,
            onCameraIdle: _manager.updateMap,
            myLocationEnabled: true,
            myLocationButtonEnabled: true,
            zoomControlsEnabled: false,
            onTap: (_) {
              setState(() => selectedObservation = null);
            },
          ),

          // -----------------------------------------------------
          // NEW FULL-SCREEN OBSERVATION OVERLAY
          // -----------------------------------------------------
// -----------------------------------------------------
        // NEW MODERN PARALLAX OBSERVATION OVERLAY
        // -----------------------------------------------------
        if (selectedObservation != null)
    Positioned.fill(
      child: Scaffold(
        backgroundColor: Theme.of(context).colorScheme.surface,
        body: CustomScrollView(
          slivers: [
            // 1. Parallax Image Header
            SliverAppBar(
              expandedHeight: 350.0,
              pinned: true,
              elevation: 0,
              backgroundColor: Theme.of(context).colorScheme.surface,
              leading: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Container(
                  decoration: const BoxDecoration(
                    color: Colors.black54,
                    shape: BoxShape.circle,
                  ),
                  child: IconButton(
                    icon: const Icon(Icons.arrow_back, color: Colors.white),
                    onPressed: () => setState(() => selectedObservation = null),
                  ),
                ),
              ),
              flexibleSpace: FlexibleSpaceBar(
                background: Stack(
                  fit: StackFit.expand,
                  children: [
                    CachedNetworkImage(
                      imageUrl: selectedObservation!['ImageURL'] ?? '',
                      fit: BoxFit.cover,
                      placeholder: (context, url) => Container(
                        color: Theme.of(context).colorScheme.surfaceVariant,
                        child: const Center(child: CircularProgressIndicator()),
                      ),
                      errorWidget: (context, url, error) => Container(
                        color: Theme.of(context).colorScheme.surfaceVariant,
                        child: const Icon(Icons.broken_image, size: 50),
                      ),
                    ),
                    // Smooth gradient so the image fades nicely into the content
                    const DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [Colors.black45, Colors.transparent, Colors.black87],
                          stops: [0.0, 0.5, 1.0],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // 2. Scrollable Content Area
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Species Headers (No Arrow Icon)
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                selectedObservation!['CommonName'] ?? 'Unknown',
                                style: const TextStyle(
                                  fontSize: 28,
                                  fontWeight: FontWeight.bold,
                                  height: 1.2,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                selectedObservation!['SpeciesName'] ?? 'Unknown',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontStyle: FontStyle.italic,
                                  color: Theme.of(context).colorScheme.primary,
                                ),
                              ),
                            ],
                          ),
                        ),
                        // Organism Type Badge
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.secondaryContainer,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            selectedObservation!['OrganismType'] ?? '',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Theme.of(context).colorScheme.onSecondaryContainer,
                            ),
                          ),
                        )
                      ],
                    ),

                    const SizedBox(height: 24),

                    // Modern User Info Card
                    const SizedBox(height: 24),

                    // -----------------------------------------------------
                    // NEW: BIODIVERSITY & FIELD DATA SECTION
                    // -----------------------------------------------------
                    const Text(
                      "Field Data",
                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 12),

                    Row(
                      children: [
                        // Validation Badge (AI vs Manual)
                        Expanded(
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
                            decoration: BoxDecoration(
                              color: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.4),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Theme.of(context).colorScheme.outlineVariant.withOpacity(0.5)),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  selectedObservation!['ClassificationMethod'] == 'Auto-Classified'
                                      ? Icons.auto_awesome
                                      : Icons.person,
                                  color: selectedObservation!['ClassificationMethod'] == 'Auto-Classified'
                                      ? Colors.amber.shade700
                                      : Colors.blue.shade700,
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const Text("Verification", style: TextStyle(fontSize: 11, color: Colors.grey)),
                                      Text(
                                        selectedObservation!['ClassificationMethod'] ?? 'Manual',
                                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),

                        // Count Badge
                        Expanded(
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
                            decoration: BoxDecoration(
                              color: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.4),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Theme.of(context).colorScheme.outlineVariant.withOpacity(0.5)),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.group, color: Colors.teal),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const Text("Count", style: TextStyle(fontSize: 11, color: Colors.grey)),
                                      Text(
                                        "${selectedObservation!['Count'] ?? 1} Observed",
                                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),

                    // Field Notes (Only show if notes exist)
                    if (selectedObservation!['Notes'] != null && selectedObservation!['Notes'].toString().isNotEmpty) ...[
                      const SizedBox(height: 12),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.3),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Theme.of(context).colorScheme.outlineVariant.withOpacity(0.5)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Row(
                              children: [
                                Icon(Icons.notes, size: 16, color: Colors.grey),
                                SizedBox(width: 6),
                                Text("Observer Notes", style: TextStyle(fontSize: 12, color: Colors.grey, fontWeight: FontWeight.bold)),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text(
                              selectedObservation!['Notes'],
                              style: const TextStyle(fontSize: 15, height: 1.5, fontStyle: FontStyle.italic),
                            ),
                          ],
                        ),
                      ),
                    ],

                    const SizedBox(height: 32),
                    /*Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.5),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
                      ),
                      child: Row(
                        children: [
                          CircleAvatar(
                            radius: 22,
                            backgroundColor: Theme.of(context).colorScheme.primary,
                            child: const Icon(Icons.person, color: Colors.white),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  "Observed by",
                                  style: TextStyle(fontSize: 12, color: Colors.grey),
                                ),
                                Text(
                                  selectedObservation!['UserEmail']?.split('@').first ?? 'Unknown',
                                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                                ),
                              ],
                            ),
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              const Icon(Icons.calendar_today, size: 14, color: Colors.grey),
                              const SizedBox(height: 4),
                              Text(
                                _formatTimestamp(selectedObservation!['Timestamp']),
                                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),*/

                    const SizedBox(height: 32),

                    // Location Section
                    const Text(
                      "Location Details",
                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),

                    // Address Text
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(Icons.location_on, color: Theme.of(context).colorScheme.primary, size: 20),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            _currentAddress,
                            style: const TextStyle(fontSize: 15, height: 1.4),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 16),

                    // Interactive Mini-Map
                    SizedBox(
                      height: 250,
                      width: double.infinity,
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: GoogleMap(
                          mapType: MapType.normal,
                          initialCameraPosition: CameraPosition(
                            target: LatLng(
                              selectedObservation!['Latitude'] ?? 0.0,
                              selectedObservation!['Longitude'] ?? 0.0,
                            ),
                            zoom: 15,
                          ),
                          markers: {
                            Marker(
                              markerId: const MarkerId('detail_map_marker'),
                              position: LatLng(
                                selectedObservation!['Latitude'] ?? 0.0,
                                selectedObservation!['Longitude'] ?? 0.0,
                              ),
                            )
                          },
                          // This enables full interaction!
                          liteModeEnabled: false,
                          myLocationButtonEnabled: false,
                          zoomControlsEnabled: true,
                          // CRITICAL: This allows the user to pan the map vertically
                          // without accidentally scrolling the entire page up and down.
                          gestureRecognizers: {
                            Factory<OneSequenceGestureRecognizer>(
                                  () => EagerGestureRecognizer(),
                            ),
                          },
                        ),
                      ),
                    ),

                    // Extra padding at the bottom so you can scroll comfortably past the map
                    const SizedBox(height: 80),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    ),

        ],
      ),
    );
  }
}