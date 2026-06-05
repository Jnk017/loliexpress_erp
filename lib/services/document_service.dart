import 'dart:io';
import 'package:file_picker/file_picker.dart';
import './supabase_service.dart';

/// Service for managing document attachments in the ERP system
class DocumentService {
  final _client = SupabaseService.instance.client;

  /// Upload a document to Supabase storage and create metadata record
  Future<String> uploadDocument({
    required String entityType,
    required String entityId,
    required File file,
    String? description,
  }) async {
    try {
      final user = _client.auth.currentUser;
      if (user == null) throw Exception('User not authenticated');

      final fileName = file.path.split('/').last;
      final fileSize = await file.length();
      final fileExtension = fileName.split('.').last.toLowerCase();

      // Map file extension to MIME type
      String mimeType;
      switch (fileExtension) {
        case 'pdf':
          mimeType = 'application/pdf';
          break;
        case 'jpg':
        case 'jpeg':
          mimeType = 'image/jpeg';
          break;
        case 'png':
          mimeType = 'image/png';
          break;
        case 'webp':
          mimeType = 'image/webp';
          break;
        case 'docx':
          mimeType =
              'application/vnd.openxmlformats-officedocument.wordprocessingml.document';
          break;
        default:
          mimeType = 'application/octet-stream';
      }

      // Generate unique file path
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final filePath = '${user.id}/$entityType/${timestamp}_$fileName';

      // Storage and PostgreSQL cannot share a transaction. Remove the object if
      // metadata validation/RLS fails so an orphaned private file is not left behind.
      await _client.storage.from('erp-documents').upload(filePath, file);
      try {
        final response = await _client
            .from('document_attachments')
            .insert({
              'entity_type': entityType,
              'entity_id': entityId,
              'file_name': fileName,
              'file_path': filePath,
              'file_size': fileSize,
              'mime_type': mimeType,
              'uploaded_by': user.id,
              'description': description,
            })
            .select()
            .single();
        return response['id'];
      } catch (_) {
        await _client.storage.from('erp-documents').remove([filePath]);
        rethrow;
      }
    } catch (e) {
      throw Exception('Failed to upload document: $e');
    }
  }

  /// Pick and upload a document
  Future<String?> pickAndUploadDocument({
    required String entityType,
    required String entityId,
    String? description,
  }) async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf', 'jpg', 'jpeg', 'png', 'webp', 'docx'],
      );

      if (result != null && result.files.isNotEmpty) {
        final file = File(result.files.single.path!);
        return await uploadDocument(
          entityType: entityType,
          entityId: entityId,
          file: file,
          description: description,
        );
      }
      return null;
    } catch (e) {
      throw Exception('Failed to pick and upload document: $e');
    }
  }

  /// Get documents for a specific entity
  Future<List<Map<String, dynamic>>> getEntityDocuments({
    required String entityType,
    required String entityId,
  }) async {
    try {
      final response = await _client
          .from('document_attachments')
          .select(
              '*, uploaded_by_profile:user_profiles!uploaded_by(full_name, email)')
          .eq('entity_type', entityType)
          .eq('entity_id', entityId)
          .order('uploaded_at', ascending: false);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      throw Exception('Failed to fetch documents: $e');
    }
  }

  Future<List<Map<String, dynamic>>> getMyDocuments() async {
    try {
      final user = _client.auth.currentUser;
      if (user == null) return [];
      final response = await _client
          .from('document_attachments')
          .select('*')
          .eq('uploaded_by', user.id)
          .order('uploaded_at', ascending: false);
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      throw Exception('Failed to fetch user documents: $e');
    }
  }

  /// Get signed URL for private document
  Future<String> getDocumentUrl(String filePath) async {
    try {
      final signedUrl = await _client.storage
          .from('erp-documents')
          .createSignedUrl(filePath, 3600); // 1 hour expiry

      return signedUrl;
    } catch (e) {
      throw Exception('Failed to get document URL: $e');
    }
  }

  /// Delete a document
  Future<void> deleteDocument(String documentId, String filePath) async {
    try {
      // Delete from storage
      await _client.storage.from('erp-documents').remove([filePath]);

      // Delete metadata
      await _client.from('document_attachments').delete().eq('id', documentId);
    } catch (e) {
      throw Exception('Failed to delete document: $e');
    }
  }

  /// Get total storage used by user
  Future<int> getUserStorageUsed() async {
    try {
      final user = _client.auth.currentUser;
      if (user == null) return 0;

      final response = await _client
          .from('document_attachments')
          .select('file_size')
          .eq('uploaded_by', user.id);

      int totalSize = 0;
      for (var doc in response) {
        totalSize += (doc['file_size'] as int);
      }
      return totalSize;
    } catch (e) {
      return 0;
    }
  }

  /// Format file size for display
  String formatFileSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }
}
