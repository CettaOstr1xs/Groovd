import 'package:flutter/material.dart';
import 'package:groovd/core/theme/app_colors.dart';
import 'package:groovd/core/theme/app_typography.dart';

/// Neo-Brutalist markdown renderer for GROOVD AI responses.
/// Supports bold (**), tilt/italics (* or _), headers (###), bullet lists, and inline code.
class GroovdMarkdownText extends StatelessWidget {
  final String text;
  final TextStyle? baseStyle;

  const GroovdMarkdownText({
    super.key,
    required this.text,
    this.baseStyle,
  });

  static final _emojiRegex = RegExp(
    r'[\u{1F300}-\u{1FAFF}\u{2600}-\u{27BF}\u{1F000}-\u{1F2FF}\u{1F900}-\u{1F9FF}\u{1F600}-\u{1F64F}\u{1F680}-\u{1F6FF}]',
    unicode: true,
  );

  @override
  Widget build(BuildContext context) {
    final cleanText = text.replaceAll(_emojiRegex, '');
    if (cleanText.isEmpty) {
      return Text('...', style: baseStyle ?? _defaultBaseStyle);
    }

    final lines = cleanText.split('\n');
    final widgets = <Widget>[];

    for (var i = 0; i < lines.length; i++) {
      final line = lines[i];
      final trimmed = line.trim();

      if (trimmed.isEmpty) {
        widgets.add(const SizedBox(height: 6));
        continue;
      }

      // Check Header
      if (trimmed.startsWith('### ') || trimmed.startsWith('## ') || trimmed.startsWith('# ')) {
        final headerText = trimmed.replaceFirst(RegExp(r'^#{1,3}\s*'), '');
        widgets.add(
          Padding(
            padding: const EdgeInsets.only(top: 6, bottom: 4),
            child: Text(
              headerText.toUpperCase(),
              style: AppTypography.displaySmall(fontSize: 13).copyWith(
                color: AppColors.acidLime,
                letterSpacing: 0.8,
              ),
            ),
          ),
        );
        continue;
      }

      // Check Bullet item
      if (trimmed.startsWith('- ') || trimmed.startsWith('* ') || trimmed.startsWith('• ')) {
        final bulletContent = trimmed.substring(2).trim();
        widgets.add(
          Padding(
            padding: const EdgeInsets.only(top: 2, bottom: 2, left: 4),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  margin: const EdgeInsets.only(top: 6, right: 8),
                  width: 4,
                  height: 4,
                  decoration: const BoxDecoration(
                    color: AppColors.acidLime,
                    borderRadius: BorderRadius.zero,
                  ),
                ),
                Expanded(
                  child: RichText(
                    text: TextSpan(
                      children: _parseInlineMarkdown(bulletContent),
                      style: baseStyle ?? _defaultBaseStyle,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
        continue;
      }

      // Standard Paragraph
      widgets.add(
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 2),
          child: RichText(
            text: TextSpan(
              children: _parseInlineMarkdown(line),
              style: baseStyle ?? _defaultBaseStyle,
            ),
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: widgets,
    );
  }

  static TextStyle get _defaultBaseStyle =>
      AppTypography.monoLabel(fontSize: 12.5, color: AppColors.textPrimary).copyWith(
        height: 1.5,
        letterSpacing: 0.2,
      );

  /// Parses inline markdown tokens: bold (**), italic (* or _), code (`), bold-italic (***).
  List<InlineSpan> _parseInlineMarkdown(String rawText) {
    final spans = <InlineSpan>[];
    // Regex matching bold-italic, bold, italic, code
    final pattern = RegExp(
      r'(\*\*\*([^*]+)\*\*\*)|(\*\*([^*]+)\*\*)|(\*([^*]+)\*)|(_([^_]+)_)|(`([^`]+)`)',
    );

    var currentIndex = 0;
    for (final match in pattern.allMatches(rawText)) {
      if (match.start > currentIndex) {
        spans.add(TextSpan(
          text: rawText.substring(currentIndex, match.start),
        ));
      }

      if (match.group(1) != null) {
        // ***bold-italic***
        spans.add(TextSpan(
          text: match.group(2),
          style: const TextStyle(
            fontWeight: FontWeight.w800,
            fontStyle: FontStyle.italic,
            color: AppColors.acidLime,
          ),
        ));
      } else if (match.group(3) != null) {
        // **bold**
        spans.add(TextSpan(
          text: match.group(4),
          style: const TextStyle(
            fontWeight: FontWeight.w800,
            color: AppColors.white,
          ),
        ));
      } else if (match.group(5) != null) {
        // *italic*
        spans.add(TextSpan(
          text: match.group(6),
          style: const TextStyle(
            fontStyle: FontStyle.italic,
            color: AppColors.textPrimary,
          ),
        ));
      } else if (match.group(7) != null) {
        // _italic_
        spans.add(TextSpan(
          text: match.group(8),
          style: const TextStyle(
            fontStyle: FontStyle.italic,
            color: AppColors.textPrimary,
          ),
        ));
      } else if (match.group(9) != null) {
        // `code`
        spans.add(WidgetSpan(
          alignment: PlaceholderAlignment.middle,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
            decoration: BoxDecoration(
              color: AppColors.surfaceElevated,
              borderRadius: BorderRadius.zero,
              border: Border.all(color: AppColors.border, width: 1),
            ),
            child: Text(
              match.group(10) ?? '',
              style: AppTypography.monoLabel(fontSize: 10.5, color: AppColors.acidLime),
            ),
          ),
        ));
      }

      currentIndex = match.end;
    }

    if (currentIndex < rawText.length) {
      spans.add(TextSpan(
        text: rawText.substring(currentIndex),
      ));
    }

    return spans;
  }
}

