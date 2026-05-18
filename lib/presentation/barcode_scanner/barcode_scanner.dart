import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:sizer/sizer.dart';

import '../../core/app_export.dart';
import '../../widgets/custom_icon_widget.dart';
import './widgets/scan_history_item.dart';
import './widgets/scan_result_bottom_sheet.dart';

class BarcodeScanner extends StatefulWidget {
  const BarcodeScanner({super.key});

  @override
  State<BarcodeScanner> createState() => _BarcodeScannerState();
}

class _BarcodeScannerState extends State<BarcodeScanner>
    with SingleTickerProviderStateMixin {
  MobileScannerController? _scannerController;
  bool _isFlashOn = false;
  bool _isScanning = true;
  String? _lastScannedCode;
  late AnimationController _animationController;
  late Animation<double> _animation;

  // Mock scan history
  final List<Map<String, dynamic>> _scanHistory = [
    {
      "code": "3760074380213",
      "format": "EAN-13",
      "timestamp": DateTime.now().subtract(const Duration(minutes: 5)),
      "context": "Vérification stock",
    },
    {
      "code": "8901234567890",
      "format": "EAN-13",
      "timestamp": DateTime.now().subtract(const Duration(hours: 1)),
      "context": "Ajout commande",
    },
    {
      "code": "QR-ORD-2024-001",
      "format": "QR Code",
      "timestamp": DateTime.now().subtract(const Duration(hours: 2)),
      "context": "Réception",
    },
  ];

  // Mock product database
  final Map<String, Map<String, dynamic>> _productDatabase = {
    "3760074380213": {
      "name": "Coca-Cola Original 330ml",
      "sku": "COC-330-001",
      "stock": 245,
      "price": "450 CDF",
      "image":
          "https://images.unsplash.com/photo-1675599591199-7bced32f7f97",
      "semanticLabel":
          "Red Coca-Cola can with white logo on white background, classic 330ml size",
      "category": "Boissons gazeuses",
      "location": "Entrepôt A - Allée 3",
    },
    "8901234567890": {
      "name": "Sprite Citron 500ml",
      "sku": "SPR-500-002",
      "stock": 189,
      "price": "550 CDF",
      "image":
          "https://images.unsplash.com/photo-1592860893757-84536a1c9b82",
      "semanticLabel":
          "Green Sprite bottle with lemon-lime graphics, 500ml plastic bottle",
      "category": "Boissons gazeuses",
      "location": "Entrepôt A - Allée 4",
    },
    "QR-ORD-2024-001": {
      "name": "Commande #2024-001",
      "sku": "ORD-2024-001",
      "stock": 0,
      "price": "125 000 CDF",
      "image":
          "https://images.unsplash.com/photo-1644507881446-41ed9ee2c928",
      "semanticLabel":
          "Cardboard boxes stacked on warehouse pallet with shipping labels",
      "category": "Commande",
      "location": "Zone de réception",
    },
  };

  @override
  void initState() {
    super.initState();
    _initializeScanner();
    _animationController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat(reverse: true);
    _animation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
  }

  Future<void> _initializeScanner() async {
    try {
      _scannerController = MobileScannerController(
        detectionSpeed: DetectionSpeed.normal,
        facing: CameraFacing.back,
        torchEnabled: false,
      );
      await _scannerController!.start();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur d\'initialisation de la caméra: $e'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    }
  }

  @override
  void dispose() {
    _scannerController?.dispose();
    _animationController.dispose();
    super.dispose();
  }

  void _toggleFlash() {
    setState(() {
      _isFlashOn = !_isFlashOn;
    });
    _scannerController?.toggleTorch();
  }

  void _showScanHistory() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _buildScanHistorySheet(),
    );
  }

  void _showManualInput() {
    final TextEditingController controller = TextEditingController();
    showDialog(
      context: context,
      builder: (context) {
        final theme = Theme.of(context);
        return AlertDialog(
          title: Text(
            'Saisie manuelle',
            style: theme.textTheme.titleLarge,
          ),
          content: TextField(
            controller: controller,
            decoration: const InputDecoration(
              labelText: 'Code-barres ou SKU',
              hintText: 'Entrez le code...',
            ),
            keyboardType: TextInputType.text,
            textCapitalization: TextCapitalization.characters,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Annuler'),
            ),
            ElevatedButton(
              onPressed: () {
                if (controller.text.isNotEmpty) {
                  Navigator.pop(context);
                  _handleScanResult(controller.text, 'Manuel');
                }
              },
              child: const Text('Rechercher'),
            ),
          ],
        );
      },
    );
  }

  void _handleScanResult(String code, String format) {
    if (_lastScannedCode == code) return;

    setState(() {
      _lastScannedCode = code;
      _isScanning = false;
    });

    // Haptic feedback
    HapticFeedback.mediumImpact();

    // Audio confirmation would go here
    // For now, we'll just show the result

    final product = _productDatabase[code];
    if (product != null) {
      _showProductBottomSheet(product, code, format);
    } else {
      _showProductNotFound(code, format);
    }
  }

  void _showProductBottomSheet(
      Map<String, dynamic> product, String code, String format) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => ScanResultBottomSheet(
        product: product,
        code: code,
        format: format,
        onAddToOrder: () {
          Navigator.pop(context);
          _navigateToSalesOrder(product);
        },
        onViewDetails: () {
          Navigator.pop(context);
          _navigateToProductDetails(product);
        },
        onAdjustStock: () {
          Navigator.pop(context);
          _navigateToStockAdjustment(product);
        },
        onScanAnother: () {
          Navigator.pop(context);
          setState(() {
            _isScanning = true;
            _lastScannedCode = null;
          });
        },
      ),
    );
  }

  void _showProductNotFound(String code, String format) {
    final theme = Theme.of(context);
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        padding: EdgeInsets.all(4.w),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 12.w,
              height: 0.5.h,
              decoration: BoxDecoration(
                color: theme.colorScheme.outline,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            SizedBox(height: 3.h),
            CustomIconWidget(
              iconName: 'search_off',
              size: 48,
              color: theme.colorScheme.error,
            ),
            SizedBox(height: 2.h),
            Text(
              'Produit non trouvé',
              style: theme.textTheme.titleLarge,
            ),
            SizedBox(height: 1.h),
            Text(
              'Code: $code',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            Text(
              'Format: $format',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            SizedBox(height: 3.h),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () {
                      Navigator.pop(context);
                      setState(() {
                        _isScanning = true;
                        _lastScannedCode = null;
                      });
                    },
                    child: const Text('Scanner à nouveau'),
                  ),
                ),
                SizedBox(width: 2.w),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context);
                      Navigator.pushNamed(context, '/product-catalog');
                    },
                    child: const Text('Catalogue'),
                  ),
                ),
              ],
            ),
            SizedBox(height: 2.h),
          ],
        ),
      ),
    );
  }

  Widget _buildScanHistorySheet() {
    final theme = Theme.of(context);
    return Container(
      height: 70.h,
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          Container(
            padding: EdgeInsets.all(4.w),
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(
                  color: theme.colorScheme.outline.withValues(alpha: 0.2),
                ),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    'Historique des scans',
                    style: theme.textTheme.titleLarge,
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: CustomIconWidget(
                    iconName: 'close',
                    size: 24,
                    color: theme.colorScheme.onSurface,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: _scanHistory.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CustomIconWidget(
                          iconName: 'history',
                          size: 48,
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                        SizedBox(height: 2.h),
                        Text(
                          'Aucun scan récent',
                          style: theme.textTheme.bodyLarge?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  )
                : ListView.separated(
                    padding: EdgeInsets.all(4.w),
                    itemCount: _scanHistory.length,
                    separatorBuilder: (context, index) => SizedBox(height: 2.h),
                    itemBuilder: (context, index) {
                      final scan = _scanHistory[index];
                      return ScanHistoryItem(
                        code: scan["code"] as String,
                        format: scan["format"] as String,
                        timestamp: scan["timestamp"] as DateTime,
                        context: scan["context"] as String,
                        onTap: () {
                          Navigator.pop(context);
                          _handleScanResult(
                              scan["code"] as String, scan["format"] as String);
                        },
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  void _navigateToSalesOrder(Map<String, dynamic> product) {
    Navigator.pushNamed(
      context,
      '/sales-order-processing',
      arguments: {'product': product},
    );
  }

  void _navigateToProductDetails(Map<String, dynamic> product) {
    Navigator.pushNamed(
      context,
      '/product-catalog',
      arguments: {'productId': product['sku']},
    );
  }

  void _navigateToStockAdjustment(Map<String, dynamic> product) {
    Navigator.pushNamed(
      context,
      '/inventory-management',
      arguments: {'product': product, 'action': 'adjust'},
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // Camera preview
          if (_scannerController != null)
            MobileScanner(
              controller: _scannerController,
              onDetect: (capture) {
                if (!_isScanning) return;
                final List<Barcode> barcodes = capture.barcodes;
                if (barcodes.isNotEmpty) {
                  final barcode = barcodes.first;
                  if (barcode.rawValue != null) {
                    _handleScanResult(
                      barcode.rawValue!,
                      barcode.format.name,
                    );
                  }
                }
              },
            ),

          // Top overlay with controls
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withValues(alpha: 0.7),
                    Colors.transparent,
                  ],
                ),
              ),
              child: SafeArea(
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 2.h),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: CustomIconWidget(
                          iconName: 'close',
                          size: 28,
                          color: Colors.white,
                        ),
                      ),
                      Text(
                        'Scanner un code',
                        style: theme.textTheme.titleLarge?.copyWith(
                          color: Colors.white,
                        ),
                      ),
                      Row(
                        children: [
                          IconButton(
                            onPressed: _toggleFlash,
                            icon: CustomIconWidget(
                              iconName: _isFlashOn ? 'flash_on' : 'flash_off',
                              size: 28,
                              color: Colors.white,
                            ),
                          ),
                          IconButton(
                            onPressed: _showScanHistory,
                            icon: CustomIconWidget(
                              iconName: 'history',
                              size: 28,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),

          // Center scanning reticle with animation
          Center(
            child: AnimatedBuilder(
              animation: _animation,
              builder: (context, child) {
                return Container(
                  width: 70.w,
                  height: 70.w,
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: _isScanning
                          ? theme.colorScheme.primary
                              .withValues(alpha: 0.3 + (_animation.value * 0.7))
                          : theme.colorScheme.primary,
                      width: 3,
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Stack(
                    children: [
                      // Corner indicators
                      Positioned(
                        top: -2,
                        left: -2,
                        child: Container(
                          width: 8.w,
                          height: 8.w,
                          decoration: BoxDecoration(
                            border: Border(
                              top: BorderSide(
                                  color: theme.colorScheme.primary, width: 4),
                              left: BorderSide(
                                  color: theme.colorScheme.primary, width: 4),
                            ),
                          ),
                        ),
                      ),
                      Positioned(
                        top: -2,
                        right: -2,
                        child: Container(
                          width: 8.w,
                          height: 8.w,
                          decoration: BoxDecoration(
                            border: Border(
                              top: BorderSide(
                                  color: theme.colorScheme.primary, width: 4),
                              right: BorderSide(
                                  color: theme.colorScheme.primary, width: 4),
                            ),
                          ),
                        ),
                      ),
                      Positioned(
                        bottom: -2,
                        left: -2,
                        child: Container(
                          width: 8.w,
                          height: 8.w,
                          decoration: BoxDecoration(
                            border: Border(
                              bottom: BorderSide(
                                  color: theme.colorScheme.primary, width: 4),
                              left: BorderSide(
                                  color: theme.colorScheme.primary, width: 4),
                            ),
                          ),
                        ),
                      ),
                      Positioned(
                        bottom: -2,
                        right: -2,
                        child: Container(
                          width: 8.w,
                          height: 8.w,
                          decoration: BoxDecoration(
                            border: Border(
                              bottom: BorderSide(
                                  color: theme.colorScheme.primary, width: 4),
                              right: BorderSide(
                                  color: theme.colorScheme.primary, width: 4),
                            ),
                          ),
                        ),
                      ),
                      // Scanning line animation
                      if (_isScanning)
                        Positioned(
                          top: _animation.value * 70.w,
                          left: 0,
                          right: 0,
                          child: Container(
                            height: 2,
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  Colors.transparent,
                                  theme.colorScheme.primary,
                                  Colors.transparent,
                                ],
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                );
              },
            ),
          ),

          // Bottom overlay with instructions
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                  colors: [
                    Colors.black.withValues(alpha: 0.8),
                    Colors.transparent,
                  ],
                ),
              ),
              child: SafeArea(
                child: Padding(
                  padding: EdgeInsets.all(4.w),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        _isScanning
                            ? 'Placez le code-barres dans le cadre'
                            : 'Scan en pause',
                        style: theme.textTheme.titleMedium?.copyWith(
                          color: Colors.white,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      SizedBox(height: 1.h),
                      Text(
                        'Formats supportés: EAN-13, Code 128, QR Code',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: Colors.white.withValues(alpha: 0.7),
                        ),
                        textAlign: TextAlign.center,
                      ),
                      SizedBox(height: 3.h),
                      ElevatedButton.icon(
                        onPressed: _showManualInput,
                        icon: CustomIconWidget(
                          iconName: 'keyboard',
                          size: 20,
                          color: theme.colorScheme.onPrimary,
                        ),
                        label: const Text('Saisie manuelle'),
                        style: ElevatedButton.styleFrom(
                          padding: EdgeInsets.symmetric(
                            horizontal: 6.w,
                            vertical: 1.5.h,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
