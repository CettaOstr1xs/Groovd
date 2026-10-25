import 'dart:convert';
import 'dart:io';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';

/// A universal Neo-Brutalist critic avatar widget.
///
/// Reliably handles:
/// - Remote/Network URLs (e.g. Google profile photos `https://...`) via [CachedNetworkImage]
/// - Base64 data URIs and strings
/// - Local file paths (e.g. cropped gallery images) via [Image.file] with existsSync safety
/// - Graceful monogram fallback on missing files, load errors, or null paths
class CriticAvatar extends StatelessWidget {
  final String? avatarPath;
  final String fallbackInitial;
  final double size;
  final double borderWidth;
  final Color borderColor;
  final Color fallbackBgColor;
  final Color fallbackTextColor;
  final double borderRadius;
  final List<BoxShadow>? boxShadow;

  const CriticAvatar({
    super.key,
    this.avatarPath,
    required this.fallbackInitial,
    this.size = 28,
    this.borderWidth = 1.5,
    this.borderColor = AppColors.acidLime,
    this.fallbackBgColor = AppColors.pureBlack,
    this.fallbackTextColor = AppColors.pureWhite,
    this.borderRadius = 2,
    this.boxShadow,
  });

  bool get _hasValidPath => avatarPath != null && avatarPath!.trim().isNotEmpty;
  bool get _isNetwork =>
      _hasValidPath &&
      (avatarPath!.trim().startsWith('http://') || avatarPath!.trim().startsWith('https://'));
  bool get _isDataUri =>
      _hasValidPath && avatarPath!.trim().startsWith('data:');
  bool get _isRawBase64 =>
      _hasValidPath &&
      !_isNetwork &&
      !_isDataUri &&
      !avatarPath!.trim().startsWith('/') &&
      avatarPath!.trim().length > 100;

  @override
  Widget build(BuildContext context) {
    final cleanInitial = fallbackInitial.trim();
    final letter = cleanInitial.isNotEmpty ? cleanInitial[0].toUpperCase() : 'C';

    Widget? imageWidget;

    if (_hasValidPath) {
      final path = avatarPath!.trim();
      if (_isNetwork) {
        imageWidget = CachedNetworkImage(
          imageUrl: path,
          width: size,
          height: size,
          fit: BoxFit.cover,
          fadeInDuration: Duration.zero,
          fadeOutDuration: Duration.zero,
          placeholder: (_, _) => _buildFallback(letter),
          errorWidget: (_, _, _) => _buildFallback(letter),
        );
      } else if (_isDataUri || _isRawBase64) {
        try {
          final base64Content = _isDataUri ? path.split(',').last : path;
          final bytes = base64Decode(base64Content);
          imageWidget = Image.memory(
            bytes,
            width: size,
            height: size,
            fit: BoxFit.cover,
            errorBuilder: (_, _, _) => _buildFallback(letter),
          );
        } catch (_) {
          imageWidget = _buildFallback(letter);
        }
      } else {
        final file = File(path);
        if (file.existsSync()) {
          imageWidget = Image.file(
            file,
            width: size,
            height: size,
            fit: BoxFit.cover,
            errorBuilder: (_, _, _) => _buildFallback(letter),
          );
        } else {
          imageWidget = _buildFallback(letter);
        }
      }
    }

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: fallbackBgColor,
        borderRadius: BorderRadius.circular(borderRadius),
        border: Border.all(color: borderColor, width: borderWidth),
        boxShadow: boxShadow,
      ),
      clipBehavior: Clip.hardEdge,
      alignment: Alignment.center,
      child: imageWidget ?? _buildFallback(letter),
    );
  }

  Widget _buildFallback(String letter) {
    return Center(
      child: Text(
        letter,
        style: AppTypography.monoBadge(
          color: fallbackTextColor,
          fontSize: size * 0.42,
        ),
      ),
    );
  }
}
