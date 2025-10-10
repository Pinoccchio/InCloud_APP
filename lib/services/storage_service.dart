import 'dart:io';
import 'package:supabase_flutter/supabase_flutter.dart';

class StorageService {
  static final _client = Supabase.instance.client;
  static const String _proofOfPaymentBucket = 'proof-of-payment';

  /// Upload proof of payment image to Supabase Storage
  /// Returns the public URL of the uploaded file
  static Future<String?> uploadProofOfPayment({
    required String orderId,
    required File imageFile,
  }) async {
    try {
      // Generate unique filename
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final extension = imageFile.path.split('.').last;
      final fileName = 'proof_${orderId}_$timestamp.$extension';
      final filePath = '$orderId/$fileName';

      // Upload file to Supabase Storage
      await _client.storage
          .from(_proofOfPaymentBucket)
          .upload(
            filePath,
            imageFile,
            fileOptions: const FileOptions(
              cacheControl: '3600',
              upsert: false,
            ),
          );

      // Get public URL
      final publicUrl = _client.storage
          .from(_proofOfPaymentBucket)
          .getPublicUrl(filePath);

      return publicUrl;
    } catch (e) {
      print('Error uploading proof of payment: $e');
      return null;
    }
  }

  /// Delete proof of payment image from Supabase Storage
  static Future<bool> deleteProofOfPayment(String imageUrl) async {
    try {
      // Extract file path from URL
      final uri = Uri.parse(imageUrl);
      final pathSegments = uri.pathSegments;

      // Find the bucket name and file path
      final bucketIndex = pathSegments.indexOf(_proofOfPaymentBucket);
      if (bucketIndex == -1 || bucketIndex == pathSegments.length - 1) {
        return false;
      }

      final filePath = pathSegments.sublist(bucketIndex + 1).join('/');

      // Delete file from storage
      await _client.storage
          .from(_proofOfPaymentBucket)
          .remove([filePath]);

      return true;
    } catch (e) {
      print('Error deleting proof of payment: $e');
      return false;
    }
  }

  /// Get proof of payment image URL
  static String? getProofOfPaymentUrl(String? storedUrl) {
    if (storedUrl == null || storedUrl.isEmpty) return null;

    // If it's already a full URL, return it
    if (storedUrl.startsWith('http')) return storedUrl;

    // Otherwise, construct the full URL
    return _client.storage
        .from(_proofOfPaymentBucket)
        .getPublicUrl(storedUrl);
  }
}
