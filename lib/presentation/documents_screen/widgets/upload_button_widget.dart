import 'package:flutter/material.dart';

/// Floating action button for uploading documents
class UploadButtonWidget extends StatelessWidget {
  final VoidCallback onUpload;

  const UploadButtonWidget({
    super.key,
    required this.onUpload,
  });

  @override
  Widget build(BuildContext context) {
    return FloatingActionButton.extended(
      onPressed: onUpload,
      backgroundColor: Theme.of(context).primaryColor,
      icon: const Icon(Icons.upload_file, color: Colors.white),
      label: const Text(
        'Ajouter',
        style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
      ),
    );
  }
}
