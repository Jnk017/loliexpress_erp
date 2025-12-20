import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../../core/app_export.dart';
import '../../widgets/custom_app_bar.dart';
import '../../widgets/custom_icon_widget.dart';
import './widgets/delivery_list_item_widget.dart';
import './widgets/delivery_map_view_widget.dart';
import './widgets/route_header_widget.dart';

class DeliveryTracking extends StatefulWidget {
  const DeliveryTracking({super.key});

  @override
  State<DeliveryTracking> createState() => _DeliveryTrackingState();
}

class _DeliveryTrackingState extends State<DeliveryTracking> {
  GoogleMapController? _mapController;
  Position? _currentPosition;
  bool _isMapView = true;
  String _selectedRoute = 'Route A - Centre Ville';
  DateTime _selectedDate = DateTime.now();
  bool _isSyncing = false;
  final DraggableScrollableController _sheetController =
      DraggableScrollableController();

  // Mock delivery data
  final List<Map<String, dynamic>> _deliveries = [
    {
      "id": "DEL-001",
      "customerName": "Café Le Parisien",
      "address": "15 Avenue de la République, Abidjan",
      "timeWindow": "08:00 - 10:00",
      "status": "pending",
      "estimatedArrival": "08:45",
      "packageCount": 12,
      "paymentRequired": true,
      "paymentAmount": "\$450.00",
      "notes": "Livraison par l'entrée arrière",
      "phone": "+225 07 12 34 56 78",
      "latitude": 5.3599,
      "longitude": -4.0083,
      "orderNumber": 1,
    },
    {
      "id": "DEL-002",
      "customerName": "Restaurant La Belle Époque",
      "address": "28 Rue des Jardins, Abidjan",
      "timeWindow": "10:00 - 12:00",
      "status": "in_progress",
      "estimatedArrival": "10:30",
      "packageCount": 8,
      "paymentRequired": false,
      "notes": "Demander Monsieur Kouassi",
      "phone": "+225 07 23 45 67 89",
      "latitude": 5.3650,
      "longitude": -4.0120,
      "orderNumber": 2,
    },
    {
      "id": "DEL-003",
      "customerName": "Bar Le Tropical",
      "address": "42 Boulevard de la Marina, Abidjan",
      "timeWindow": "12:00 - 14:00",
      "status": "pending",
      "estimatedArrival": "12:15",
      "packageCount": 15,
      "paymentRequired": true,
      "paymentAmount": "\$680.00",
      "notes": "Signature requise",
      "phone": "+225 07 34 56 78 90",
      "latitude": 5.3700,
      "longitude": -4.0150,
      "orderNumber": 3,
    },
    {
      "id": "DEL-004",
      "customerName": "Hôtel Ivoire",
      "address": "Boulevard Hassan II, Abidjan",
      "timeWindow": "14:00 - 16:00",
      "status": "completed",
      "estimatedArrival": "14:45",
      "packageCount": 20,
      "paymentRequired": false,
      "notes": "Livraison effectuée",
      "phone": "+225 07 45 67 89 01",
      "latitude": 5.3750,
      "longitude": -4.0180,
      "orderNumber": 4,
      "completedAt": "14:30",
    },
  ];

  @override
  void initState() {
    super.initState();
    _getCurrentLocation();
  }

  @override
  void dispose() {
    _mapController?.dispose();
    _sheetController.dispose();
    super.dispose();
  }

  Future<void> _getCurrentLocation() async {
    try {
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.whileInUse ||
          permission == LocationPermission.always) {
        Position position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high,
        );
        setState(() {
          _currentPosition = position;
        });
      }
    } catch (e) {
      // Handle error silently
    }
  }

  Future<void> _syncDeliveries() async {
    setState(() {
      _isSyncing = true;
    });

    await Future.delayed(const Duration(seconds: 2));

    setState(() {
      _isSyncing = false;
    });
  }

  void _navigateToDelivery(Map<String, dynamic> delivery) {
    // Navigate to delivery location
  }

  void _callCustomer(String phone) {
    // Implement phone call functionality
  }

  void _markDelivered(String deliveryId) {
    setState(() {
      final index = _deliveries.indexWhere((d) => d["id"] == deliveryId);
      if (index != -1) {
        _deliveries[index]["status"] = "completed";
        _deliveries[index]["completedAt"] =
            "${DateTime.now().hour}:${DateTime.now().minute.toString().padLeft(2, '0')}";
      }
    });
  }

  void _reportIssue(String deliveryId) {
    // Show issue reporting dialog
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Signaler un problème'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              decoration: const InputDecoration(
                labelText: 'Description du problème',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
            },
            child: const Text('Envoyer'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: CustomAppBar(
        title: 'Suivi des Livraisons',
        variant: CustomAppBarVariant.sync,
        showSyncStatus: true,
        isSyncing: _isSyncing,
        lastSyncTime: DateTime.now().subtract(const Duration(minutes: 5)),
        actions: [
          IconButton(
            icon: CustomIconWidget(
              iconName: 'refresh',
              color: theme.colorScheme.primary,
              size: 24,
            ),
            onPressed: _syncDeliveries,
            tooltip: 'Synchroniser',
          ),
        ],
      ),
      body: Stack(
        children: [
          // Map or List View
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 300),
            child: _isMapView
                ? DeliveryMapViewWidget(
                    key: const ValueKey('map'),
                    deliveries: _deliveries,
                    currentPosition: _currentPosition,
                    onMapCreated: (controller) {
                      _mapController = controller;
                    },
                    onDeliveryTap: (delivery) {
                      _sheetController.animateTo(
                        0.6,
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.easeInOut,
                      );
                    },
                  )
                : Container(
                    key: const ValueKey('list'),
                    color: theme.scaffoldBackgroundColor,
                    child: Column(
                      children: [
                        RouteHeaderWidget(
                          selectedRoute: _selectedRoute,
                          selectedDate: _selectedDate,
                          onRouteChanged: (route) {
                            setState(() {
                              _selectedRoute = route;
                            });
                          },
                          onDateChanged: (date) {
                            setState(() {
                              _selectedDate = date;
                            });
                          },
                        ),
                        Expanded(
                          child: ListView.builder(
                            padding: const EdgeInsets.all(16),
                            itemCount: _deliveries.length,
                            itemBuilder: (context, index) {
                              return DeliveryListItemWidget(
                                delivery: _deliveries[index],
                                onNavigate: () =>
                                    _navigateToDelivery(_deliveries[index]),
                                onCall: () => _callCustomer(
                                    _deliveries[index]["phone"] as String),
                                onMarkDelivered: () => _markDelivered(
                                    _deliveries[index]["id"] as String),
                                onReportIssue: () => _reportIssue(
                                    _deliveries[index]["id"] as String),
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
          ),

          // Draggable Bottom Sheet (only in map view)
          if (_isMapView)
            DraggableScrollableSheet(
              controller: _sheetController,
              initialChildSize: 0.3,
              minChildSize: 0.1,
              maxChildSize: 0.8,
              builder: (context, scrollController) {
                return Container(
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surface,
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(20),
                      topRight: Radius.circular(20),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: theme.shadowColor.withValues(alpha: 0.1),
                        blurRadius: 10,
                        offset: const Offset(0, -2),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      // Handle
                      Container(
                        margin: const EdgeInsets.symmetric(vertical: 12),
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color:
                              theme.colorScheme.outline.withValues(alpha: 0.3),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),

                      // Route Header
                      RouteHeaderWidget(
                        selectedRoute: _selectedRoute,
                        selectedDate: _selectedDate,
                        onRouteChanged: (route) {
                          setState(() {
                            _selectedRoute = route;
                          });
                        },
                        onDateChanged: (date) {
                          setState(() {
                            _selectedDate = date;
                          });
                        },
                      ),

                      // Delivery List
                      Expanded(
                        child: ListView.builder(
                          controller: scrollController,
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          itemCount: _deliveries.length,
                          itemBuilder: (context, index) {
                            return DeliveryListItemWidget(
                              delivery: _deliveries[index],
                              onNavigate: () =>
                                  _navigateToDelivery(_deliveries[index]),
                              onCall: () => _callCustomer(
                                  _deliveries[index]["phone"] as String),
                              onMarkDelivered: () => _markDelivered(
                                  _deliveries[index]["id"] as String),
                              onReportIssue: () => _reportIssue(
                                  _deliveries[index]["id"] as String),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          setState(() {
            _isMapView = !_isMapView;
          });
        },
        icon: CustomIconWidget(
          iconName: _isMapView ? 'list' : 'map',
          color: theme.colorScheme.onPrimary,
          size: 24,
        ),
        label: Text(
          _isMapView ? 'Liste' : 'Carte',
          style: theme.textTheme.labelLarge?.copyWith(
            color: theme.colorScheme.onPrimary,
          ),
        ),
      ),
    );
  }
}
