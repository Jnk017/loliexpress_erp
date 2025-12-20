import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../services/document_service.dart';
import '../../../widgets/custom_app_bar.dart';

/// Widget for previewing document content
class DocumentPreviewWidget extends StatefulWidget {
  final Map<String, dynamic> document;

  const DocumentPreviewWidget({
    Key? key,
    required this.document,
  }) : super(key: key);

  @override
  State<DocumentPreviewWidget> createState() => _DocumentPreviewWidgetState();
}

class _DocumentPreviewWidgetState extends State<DocumentPreviewWidget> {
  final _documentService = DocumentService();
  String? _signedUrl;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadSignedUrl();
  }

  Future<void> _loadSignedUrl() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final url = await _documentService.getDocumentUrl(
        widget.document['file_path'] as String,
      );
      setState(() {
        _signedUrl = url;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
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
              icon: const Icon(Icons.download),
              onPressed: () {
                // TODO: Implement download functionality
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Téléchargement non encore implémenté'),
                  ),
                );
              },
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

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: Colors.red),
            const SizedBox(height: 16),
            Text('Erreur: $_error'),
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
            onPressed: () {
              // TODO: Open in external viewer or download
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Ouverture externe non encore implémentée'),
                ),
              );
            },
            icon: const Icon(Icons.open_in_new),
            label: const Text('Ouvrir dans une application externe'),
          ),
        ],
      ),
    );
  }
}
