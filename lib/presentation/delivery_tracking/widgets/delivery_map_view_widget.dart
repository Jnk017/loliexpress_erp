import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';

class DeliveryMapViewWidget extends StatefulWidget {
  final List<Map<String, dynamic>> deliveries;
  final Position? currentPosition;
  final Function(GoogleMapController) onMapCreated;
  final Function(Map<String, dynamic>) onDeliveryTap;

  const DeliveryMapViewWidget({
    super.key,
    required this.deliveries,
    required this.currentPosition,
    required this.onMapCreated,
    required this.onDeliveryTap,
  });

  @override
  State<DeliveryMapViewWidget> createState() => _DeliveryMapViewWidgetState();
}

class _DeliveryMapViewWidgetState extends State<DeliveryMapViewWidget> {
  final Set<Marker> _markers = {};
  final Set<Polyline> _polylines = {};

  @override
  void initState() {
    super.initState();
    _createMarkers();
    _createRoute();
  }

  void _createMarkers() {
    // Add current location marker
    if (widget.currentPosition != null) {
      _markers.add(
        Marker(
          markerId: const MarkerId('current_location'),
          position: LatLng(
            widget.currentPosition!.latitude,
            widget.currentPosition!.longitude,
          ),
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
          infoWindow: const InfoWindow(title: 'Ma Position'),
        ),
      );
    }

    // Add delivery markers
    for (var delivery in widget.deliveries) {
      final status = delivery["status"] as String;
      BitmapDescriptor markerColor;

      if (status == "completed") {
        markerColor =
            BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen);
      } else if (status == "in_progress") {
        markerColor =
            BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueOrange);
      } else {
        markerColor =
            BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed);
      }

      _markers.add(
        Marker(
          markerId: MarkerId(delivery["id"] as String),
          position: LatLng(
            delivery["latitude"] as double,
            delivery["longitude"] as double,
          ),
          icon: markerColor,
          infoWindow: InfoWindow(
            title: delivery["customerName"] as String,
            snippet: delivery["timeWindow"] as String,
          ),
          onTap: () => widget.onDeliveryTap(delivery),
        ),
      );
    }
  }

  void _createRoute() {
    if (widget.currentPosition == null || widget.deliveries.isEmpty) return;

    final List<LatLng> routePoints = [
      LatLng(
        widget.currentPosition!.latitude,
        widget.currentPosition!.longitude,
      ),
    ];

    // Add delivery points in order
    final sortedDeliveries = List<Map<String, dynamic>>.from(widget.deliveries)
      ..sort((a, b) =>
          (a["orderNumber"] as int).compareTo(b["orderNumber"] as int));

    for (var delivery in sortedDeliveries) {
      if (delivery["status"] != "completed") {
        routePoints.add(
          LatLng(
            delivery["latitude"] as double,
            delivery["longitude"] as double,
          ),
        );
      }
    }

    _polylines.add(
      Polyline(
        polylineId: const PolylineId('delivery_route'),
        points: routePoints,
        color: Colors.blue,
        width: 4,
        patterns: [PatternItem.dash(20), PatternItem.gap(10)],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final initialPosition = widget.currentPosition != null
        ? LatLng(
            widget.currentPosition!.latitude,
            widget.currentPosition!.longitude,
          )
        : const LatLng(5.3599, -4.0083); // Default to Abidjan

    return GoogleMap(
      initialCameraPosition: CameraPosition(
        target: initialPosition,
        zoom: 13,
      ),
      markers: _markers,
      polylines: _polylines,
      myLocationEnabled: true,
      myLocationButtonEnabled: true,
      mapType: MapType.normal,
      zoomControlsEnabled: false,
      onMapCreated: widget.onMapCreated,
    );
  }
}
