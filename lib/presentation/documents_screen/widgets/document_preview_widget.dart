import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:share_plus/share_plus.dart';
import '../../../services/document_service.dart';
import '../../../widgets/custom_app_bar.dart';

/// Widget for previewing document content
class DocumentPreviewWidget extends StatefulWidget {
  final Map<String, dynamic> document;

  const DocumentPreviewWidget({
    super.key,
    required this.document,
  });

  @override
  State<DocumentPreviewWidget> createState() => _DocumentPreviewWidgetState();
}

class _DocumentPreviewWidgetState extends State<DocumentPreviewWidget> {
  final _documentService = DocumentService();
  String? _signedUrl;
  bool _isLoading = true;
  bool _hasError = false;
  bool _isSharing = false;

  @override
  void initState() {
    super.initState();
    _loadSignedUrl();
  }

  Future<void> _loadSignedUrl() async {
    setState(() {
      _isLoading = true;
      _hasError = false;
    });

    try {
      final url = await _documentService.getDocumentUrl(
        widget.document['file_path'] as String,
      );
      if (!mounted) return;
      setState(() {
        _signedUrl = url;
        _isLoading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _hasError = true;
        _isLoading = false;
      });
    }
  }

  Future<void> _shareDocument() async {
    if (_isSharing) return;
    setState(() => _isSharing = true);
    try {
      final document = widget.document;
      final bytes = await _documentService.downloadDocument(
        document['file_path'] as String,
      );
      if (!mounted) return;
      await SharePlus.instance.share(ShareParams(
        files: [XFile.fromData(bytes, mimeType: document['mime_type'] as String)],
        fileNameOverrides: [document['file_name'] as String],
      ));
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Impossible de récupérer le document.')),
      );
    } finally {
      if (mounted) setState(() => _isSharing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final fileName = widget.document['file_name'] as String;
    final mimeType = widget.document['mime_type'] as String;

    return Scaffold(
      appBar: CustomAppBar(
        title: fileName,
        actions: [
          if (_signedUrl != null)
            IconButton(
              tooltip: 'Partager le fichier',
              icon: const Icon(Icons.share),
              onPressed: _isSharing ? null : _shareDocument,
            ),
        ],
      ),
      body: _buildBody(mimeType),
    );
  }

  Widget _buildBody(String mimeType) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_hasError) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: Colors.red),
            const SizedBox(height: 16),
            const Text('Impossible de charger le document.'),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadSignedUrl,
              child: const Text('Réessayer'),
            ),
          ],
        ),
      );
    }

    if (_signedUrl == null) {
      return const Center(child: Text('URL non disponible'));
    }

    // Image preview
    if (mimeType.startsWith('image/')) {
      return Center(
        child: InteractiveViewer(
          child: CachedNetworkImage(
            imageUrl: _signedUrl!,
            placeholder: (context, url) => const CircularProgressIndicator(),
            errorWidget: (context, url, error) => const Icon(
              Icons.error,
              size: 64,
              color: Colors.red,
            ),
          ),
        ),
      );
    }

    // PDF or other document types
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            mimeType == 'application/pdf'
                ? Icons.picture_as_pdf
                : Icons.description,
            size: 64,
            color: Colors.grey,
          ),
          const SizedBox(height: 16),
          const Text(
            'Aperçu non disponible pour ce type de fichier',
            style: TextStyle(fontSize: 16),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: _isSharing ? null : _shareDocument,
            icon: const Icon(Icons.share),
            label: const Text('Partager le fichier'),
          ),
        ],
      ),
    );
  }
}
