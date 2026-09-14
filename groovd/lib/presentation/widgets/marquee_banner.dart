import 'package:flutter/material.dart';
import 'package:groovd/core/theme/app_colors.dart';
import 'package:groovd/core/theme/app_typography.dart';

class MarqueeBanner extends StatelessWidget {
  final String text;
  final Color backgroundColor;
  final Color textColor;
  final double height;

  const MarqueeBanner({
    super.key,
    required this.text,
    this.backgroundColor = AppColors.acidLime,
    this.textColor = AppColors.pureBlack,
    this.height = 34,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: height,
      decoration: BoxDecoration(
        color: backgroundColor,
        border: const Border.symmetric(
          horizontal: BorderSide(color: AppColors.pureBlack, width: 1.5),
        ),
      ),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        physics: const NeverScrollableScrollPhysics(),
        itemBuilder: (context, index) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Row(
                children: [
                  Text(
                    text.toUpperCase(),
                    style: AppTypography.monoBadge(
                      color: textColor,
                      fontSize: 11,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Text(
                    '★',
                    style: TextStyle(color: textColor, fontSize: 10),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
