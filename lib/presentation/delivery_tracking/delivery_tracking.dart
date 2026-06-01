import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:sizer/sizer.dart';

import '../../core/app_export.dart';
import '../../services/delivery_service.dart';
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
  String _selectedRoute = 'Toutes les tournées';
  DateTime _selectedDate = DateTime.now();
  bool _isSyncing = false;
  bool _isLoading = true;
  String? _error;
  final DraggableScrollableController _sheetController =
      DraggableScrollableController();

  List<Map<String, dynamic>> _deliveries = [];

  @override
  void initState() {
    super.initState();
    _getCurrentLocation();
    _loadDeliveries();
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
          locationSettings:
              const LocationSettings(accuracy: LocationAccuracy.high),
        );
        if (!mounted) return;
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

    await _loadDeliveries();

    setState(() {
      _isSyncing = false;
    });
  }

  Future<void> _loadDeliveries() async {
    try {
      final deliveries = await DeliveryService.instance.getDeliveries();
      if (!mounted) return;
      setState(() {
        _deliveries = deliveries.map(_mapDelivery).toList();
        _isLoading = false;
        _error = null;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _error = e.toString();
      });
    }
  }

  Map<String, dynamic> _mapDelivery(Map<String, dynamic> row) {
    final order = row['sales_orders'] as Map<String, dynamic>?;
    final customer = order?['customers'] as Map<String, dynamic>?;
    final route = row['delivery_routes'] as Map<String, dynamic>?;
    final status = row['status'] as String? ?? 'pending';
    return {
      "id": row['id'] as String? ?? '',
      "customerName": customer?['company_name'] as String? ?? 'Client inconnu',
      "address": row['delivery_address'] as String? ?? '',
      "timeWindow": _formatTimeWindow(row['estimated_time'] as String?),
      "status": _mapDeliveryStatus(status),
      "estimatedArrival": _formatTime(row['estimated_time'] as String?),
      "packageCount": 1,
      "paymentRequired": order?['payment_status'] != 'paid',
      "paymentAmount": '${order?['total_amount'] ?? 0} CDF',
      "notes": row['notes'] as String? ?? '',
      "phone": customer?['phone'] as String? ?? '',
      "latitude": (row['latitude'] as num?)?.toDouble() ?? 0.0,
      "longitude": (row['longitude'] as num?)?.toDouble() ?? 0.0,
      "orderNumber": order?['order_number'] ?? row['id'],
      "routeName": route?['route_name'] ?? 'Tournée non assignée',
      if (row['actual_delivery_time'] != null)
        "completedAt": _formatTime(row['actual_delivery_time'] as String?),
    };
  }

  String _mapDeliveryStatus(String status) {
    switch (status) {
      case 'delivered':
        return 'completed';
      case 'in_transit':
        return 'in_progress';
      case 'failed':
        return 'failed';
      default:
        return 'pending';
    }
  }

  String _formatTimeWindow(String? value) {
    final time = _formatTime(value);
    return time == '--:--' ? 'Non planifiée' : time;
  }

  String _formatTime(String? value) {
    if (value == null) return '--:--';
    final parsed = DateTime.tryParse(value);
    if (parsed == null) return '--:--';
    return '${parsed.hour.toString().padLeft(2, '0')}:${parsed.minute.toString().padLeft(2, '0')}';
  }

  void _navigateToDelivery(Map<String, dynamic> delivery) {
    // Navigate to delivery location
  }

  void _callCustomer(String phone) {
    // Implement phone call functionality
  }

  Future<void> _markDelivered(String deliveryId) async {
    await DeliveryService.instance
        .updateDeliveryStatus(deliveryId, 'delivered');
    if (!mounted) return;
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
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Padding(
                    padding: EdgeInsets.all(6.w),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.error_outline,
                            color: theme.colorScheme.error, size: 48),
                        SizedBox(height: 2.h),
                        Text('Erreur de chargement des livraisons',
                            style: theme.textTheme.titleMedium),
                        SizedBox(height: 1.h),
                        Text(_error!, textAlign: TextAlign.center),
                        SizedBox(height: 2.h),
                        ElevatedButton(
                          onPressed: _loadDeliveries,
                          child: const Text('Réessayer'),
                        ),
                      ],
                    ),
                  ),
                )
              : Stack(
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
                                          onNavigate: () => _navigateToDelivery(
                                              _deliveries[index]),
                                          onCall: () => _callCustomer(
                                              _deliveries[index]["phone"]
                                                  as String),
                                          onMarkDelivered: () => _markDelivered(
                                              _deliveries[index]["id"]
                                                  as String),
                                          onReportIssue: () => _reportIssue(
                                              _deliveries[index]["id"]
                                                  as String),
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
                                  color:
                                      theme.shadowColor.withValues(alpha: 0.1),
                                  blurRadius: 10,
                                  offset: const Offset(0, -2),
                                ),
                              ],
                            ),
                            child: Column(
                              children: [
                                // Handle
                                Container(
                                  margin:
                                      const EdgeInsets.symmetric(vertical: 12),
                                  width: 40,
                                  height: 4,
                                  decoration: BoxDecoration(
                                    color: theme.colorScheme.outline
                                        .withValues(alpha: 0.3),
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
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 16),
                                    itemCount: _deliveries.length,
                                    itemBuilder: (context, index) {
                                      return DeliveryListItemWidget(
                                        delivery: _deliveries[index],
                                        onNavigate: () => _navigateToDelivery(
                                            _deliveries[index]),
                                        onCall: () => _callCustomer(
                                            _deliveries[index]["phone"]
                                                as String),
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
