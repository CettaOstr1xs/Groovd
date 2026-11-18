import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:groovd/core/theme/app_colors.dart';
import 'package:groovd/core/theme/app_typography.dart';
import 'package:groovd/data/services/artwork_download_service.dart';
import 'package:groovd/presentation/widgets/brutalist_button.dart';

/// Neo-brutalist archival confirmation modal displayed prior to saving cover artwork to the device gallery.
class ArtworkDownloadModal extends StatefulWidget {
  final String imageUrl;
  final String title;
  final String artist;
  final String? year;
  final String? typeLabel;
  final ArtworkDownloadService? service;

  const ArtworkDownloadModal({
    super.key,
    required this.imageUrl,
    required this.title,
    required this.artist,
    this.year,
    this.typeLabel,
    this.service,
  });

  /// Displays the modal dialog as a centered neo-brutalist archival dossier.
  static Future<void> show(
    BuildContext context, {
    required String imageUrl,
    required String title,
    required String artist,
    String? year,
    String? typeLabel,
    ArtworkDownloadService? service,
  }) {
    return showDialog(
      context: context,
      barrierDismissible: true,
      barrierColor: Colors.black.withValues(alpha: 0.85),
      builder: (_) => ArtworkDownloadModal(
        imageUrl: imageUrl,
        title: title,
        artist: artist,
        year: year,
        typeLabel: typeLabel,
        service: service,
      ),
    );
  }

  @override
  State<ArtworkDownloadModal> createState() => _ArtworkDownloadModalState();
}

class _ArtworkDownloadModalState extends State<ArtworkDownloadModal> {
  bool _isDownloading = false;

  Future<void> _handleDownload() async {
    if (_isDownloading) return;
    setState(() => _isDownloading = true);

    final success = await ArtworkDownloadHelper.downloadAndNotify(
      context: context,
      imageUrl: widget.imageUrl,
      title: widget.title,
      artist: widget.artist,
      service: widget.service,
    );

    if (mounted) {
      setState(() => _isDownloading = false);
      if (success) {
        Navigator.of(context).pop();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final yearText = widget.year?.isNotEmpty == true ? widget.year! : null;
    final typeText = widget.typeLabel?.isNotEmpty == true ? widget.typeLabel! : 'RELEASE';
    final badgeLabel = yearText != null ? '$typeText // $yearText' : typeText;

    return Center(
      child: Material(
        color: Colors.transparent,
        child: Container(
          width: double.infinity,
          constraints: const BoxConstraints(maxWidth: 400),
          margin: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: AppColors.surfaceElevated,
            border: Border.all(color: AppColors.pureBlack, width: 2.5),
            borderRadius: BorderRadius.zero,
            boxShadow: const [
              BoxShadow(
                color: AppColors.acidLime,
                offset: Offset(4, 4),
                blurRadius: 0,
              ),
              BoxShadow(
                color: AppColors.pureBlack,
                offset: Offset(7, 7),
                blurRadius: 0,
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. Industrial Top Bar
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                color: AppColors.pureBlack,
                child: Row(
                  children: [
                    Container(
                      width: 7,
                      height: 7,
                      margin: const EdgeInsets.only(right: 8),
                      color: AppColors.acidLime,
                    ),
                    Expanded(
                      child: Text(
                        'ARCHIVE DISPATCH // DOWNLOAD ARTWORK',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTypography.monoLabel(
                          color: AppColors.acidLime,
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const Divider(height: 1, thickness: 2.0, color: AppColors.pureBlack),

              // 2. Hero Artwork & Metadata
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Hero Artwork Preview
                    Center(
                      child: Container(
                        width: 220,
                        height: 220,
                        decoration: BoxDecoration(
                          color: AppColors.pureBlack,
                          border: Border.all(color: AppColors.pureBlack, width: 2.0),
                          boxShadow: const [
                            BoxShadow(
                              color: AppColors.pureBlack,
                              offset: Offset(3, 3),
                              blurRadius: 0,
                            ),
                          ],
                        ),
                        child: widget.imageUrl.isNotEmpty
                            ? CachedNetworkImage(
                                imageUrl: widget.imageUrl,
                                fit: BoxFit.cover,
                                placeholder: (_, _) => Container(
                                  color: AppColors.surfaceElevated,
                                  child: const Center(
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: AppColors.acidLime,
                                    ),
                                  ),
                                ),
                                errorWidget: (_, _, _) => Container(
                                  color: AppColors.surfaceElevated,
                                  child: const Icon(
                                    Icons.broken_image,
                                    color: AppColors.textMuted,
                                    size: 48,
                                  ),
                                ),
                              )
                            : const Icon(
                                Icons.album,
                                color: AppColors.textMuted,
                                size: 48,
                              ),
                      ),
                    ),

                    const SizedBox(height: 14),

                    // Centered Release Metadata
                    Text(
                      widget.title.toUpperCase(),
                      maxLines: 2,
                      textAlign: TextAlign.center,
                      overflow: TextOverflow.ellipsis,
                      style: AppTypography.displaySmall(fontSize: 15),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      widget.artist.toUpperCase(),
                      maxLines: 1,
                      textAlign: TextAlign.center,
                      overflow: TextOverflow.ellipsis,
                      style: AppTypography.monoLabel(
                        color: AppColors.textSecondary,
                        fontSize: 11.5,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      badgeLabel.toUpperCase(),
                      maxLines: 1,
                      textAlign: TextAlign.center,
                      overflow: TextOverflow.ellipsis,
                      style: AppTypography.monoLabel(
                        color: AppColors.textMuted,
                        fontSize: 10,
                        fontWeight: FontWeight.w500,
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Split Action Buttons
                    Row(
                      children: [
                        // Primary Download Button
                        Expanded(
                          flex: 7,
                          child: BrutalistButton(
                            label: _isDownloading ? 'SAVING...' : 'SAVE TO GALLERY ?',
                            backgroundColor: AppColors.acidLime,
                            textColor: AppColors.pureBlack,
                            icon: _isDownloading ? null : Icons.download,
                            leading: _isDownloading
                                ? const SizedBox(
                                    width: 14,
                                    height: 14,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: AppColors.pureBlack,
                                    ),
                                  )
                                : null,
                            onPressed: _isDownloading ? () {} : _handleDownload,
                          ),
                        ),
                        const SizedBox(width: 8),
                        // Secondary Cancel Button
                        Expanded(
                          flex: 3,
                          child: BrutalistButton(
                            label: 'CANCEL',
                            backgroundColor: AppColors.surfaceCard,
                            textColor: AppColors.textPrimary,
                            onPressed: () => Navigator.of(context).pop(),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
