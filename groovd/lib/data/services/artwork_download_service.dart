import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';

/// Result object for artwork download and gallery save operations.
class ArtworkDownloadResult {
  final bool isSuccess;
  final String? filePath;
  final String? fileName;
  final String? errorMessage;

  const ArtworkDownloadResult({
    required this.isSuccess,
    this.filePath,
    this.fileName,
    this.errorMessage,
  });
}

/// Service managing high-res artwork resolution, fetching, and native MediaStore gallery saving.
class ArtworkDownloadService {
  static const MethodChannel _channel = MethodChannel('com.example.groovd/instagram_stories');

  final http.Client _client;
  final Future<String> Function(Uint8List bytes, String fileName)? customSaver;

  ArtworkDownloadService({
    http.Client? client,
    this.customSaver,
  }) : _client = client ?? http.Client();

  /// Converts image CDN URLs (specifically Deezer) to master high-resolution assets (1000x1000).
  static String getHighResArtworkUrl(String rawUrl) {
    if (rawUrl.isEmpty) return '';

    // Deezer CDN covers typically contain patterns like /250x250- or /500x500- or /250x250.jpg
    if (rawUrl.contains('dzcdn.net')) {
      return rawUrl.replaceAllMapped(
        RegExp(r'/\d+x\d+(-|\.jpg)'),
        (match) => '/1000x1000${match.group(1)}',
      );
    }

    return rawUrl;
  }

  /// Cleans artist and release title into a safe, alphanumeric filename with bounded component length.
  static String sanitizeFileName({
    required String artist,
    required String title,
    int maxComponentLength = 40,
  }) {
    String clean(String input) {
      final sanitized = input
          .replaceAll(RegExp(r'[/\\:*?"<>|]'), '')
          .replaceAll(RegExp(r'\s+'), '_')
          .trim();
      if (sanitized.length > maxComponentLength) {
        return sanitized.substring(0, maxComponentLength);
      }
      return sanitized;
    }

    final safeArtist = clean(artist).isEmpty ? 'Artist' : clean(artist);
    final safeTitle = clean(title).isEmpty ? 'Release' : clean(title);
    final timestamp = DateTime.now().millisecondsSinceEpoch;

    return 'Groovd_${safeArtist}_${safeTitle}_$timestamp.jpg';
  }

  /// Downloads artwork from [imageUrl] and saves it into the device's public photo gallery.
  Future<ArtworkDownloadResult> downloadArtwork({
    required String imageUrl,
    required String title,
    required String artist,
  }) async {
    final highResUrl = getHighResArtworkUrl(imageUrl);
    if (highResUrl.isEmpty) {
      return const ArtworkDownloadResult(
        isSuccess: false,
        errorMessage: 'EMPTY_URL',
      );
    }

    try {
      final response = await _client.get(Uri.parse(highResUrl));
      if (response.statusCode != 200 || response.bodyBytes.isEmpty) {
        return ArtworkDownloadResult(
          isSuccess: false,
          errorMessage: 'HTTP_STATUS_${response.statusCode}',
        );
      }

      final fileName = sanitizeFileName(artist: artist, title: title);
      final bytes = response.bodyBytes;

      if (customSaver != null) {
        final path = await customSaver!(bytes, fileName);
        return ArtworkDownloadResult(
          isSuccess: true,
          filePath: path,
          fileName: fileName,
        );
      }

      // Platform check
      if (!kIsWeb && Platform.isAndroid) {
        try {
          final uri = await _channel.invokeMethod<String>('saveImageToGallery', {
            'bytes': bytes,
            'fileName': fileName,
            'mimeType': 'image/jpeg',
          });
          return ArtworkDownloadResult(
            isSuccess: true,
            filePath: uri ?? fileName,
            fileName: fileName,
          );
        } on PlatformException catch (pe) {
          return ArtworkDownloadResult(
            isSuccess: false,
            errorMessage: 'GALLERY_SAVE_FAILED: ${pe.message ?? pe.code}',
          );
        }
      } else {
        // Desktop / testing fallback
        final localPath = await _saveToLocalDirectory(bytes, fileName);
        return ArtworkDownloadResult(
          isSuccess: true,
          filePath: localPath,
          fileName: fileName,
        );
      }
    } catch (e) {
      return ArtworkDownloadResult(
        isSuccess: false,
        errorMessage: e.toString(),
      );
    }
  }

  Future<String> _saveToLocalDirectory(Uint8List bytes, String fileName) async {
    try {
      final dir = await getApplicationDocumentsDirectory();
      final targetDir = Directory('${dir.path}/Groovd_Pictures');
      if (!await targetDir.exists()) {
        await targetDir.create(recursive: true);
      }
      final file = File('${targetDir.path}/$fileName');
      await file.writeAsBytes(bytes);
      return file.path;
    } catch (_) {
      final temp = await getTemporaryDirectory();
      final file = File('${temp.path}/$fileName');
      await file.writeAsBytes(bytes);
      return file.path;
    }
  }
}

/// Helper coordinating UI feedback, haptic pulses, and SnackBar alerts for artwork downloads.
class ArtworkDownloadHelper {
  static Future<bool> downloadAndNotify({
    required BuildContext context,
    required String imageUrl,
    required String title,
    required String artist,
    ArtworkDownloadService? service,
  }) async {
    if (imageUrl.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: AppColors.surfaceElevated,
          content: Text(
            '> NO_COVER_ARTWORK_AVAILABLE',
            style: AppTypography.monoBadge(color: AppColors.electricPink),
          ),
          duration: const Duration(seconds: 2),
        ),
      );
      return false;
    }

    HapticFeedback.lightImpact();

    try {
      final downloader = service ?? ArtworkDownloadService();
      final result = await downloader.downloadArtwork(
        imageUrl: imageUrl,
        title: title,
        artist: artist,
      );

      if (!context.mounted) return result.isSuccess;

      if (result.isSuccess) {
        HapticFeedback.mediumImpact();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: AppColors.surfaceElevated,
            content: Text(
              '> ARTWORK_SAVED // ${artist.toUpperCase()} - ${title.toUpperCase()}.JPG',
              style: AppTypography.monoBadge(color: AppColors.acidLime),
            ),
            duration: const Duration(seconds: 3),
          ),
        );
        return true;
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: AppColors.surfaceElevated,
            content: Text(
              '> DOWNLOAD_FAILED // ${result.errorMessage ?? 'UNKNOWN_ERROR'}',
              style: AppTypography.monoBadge(color: AppColors.electricPink),
            ),
            duration: const Duration(seconds: 3),
          ),
        );
        return false;
      }
    } catch (e) {
      if (!context.mounted) return false;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: AppColors.surfaceElevated,
          content: Text(
            '> DOWNLOAD_ERROR // $e',
            style: AppTypography.monoBadge(color: AppColors.electricPink),
          ),
          duration: const Duration(seconds: 3),
        ),
      );
      return false;
    }
  }
}
