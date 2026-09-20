import 'package:flutter/material.dart';

class HomePlaceMark extends StatelessWidget {
  const HomePlaceMark({
    required this.size,
    this.lightOnDark,
    this.semanticLabel = 'HomePlace',
    super.key,
  });

  final double size;
  final bool? lightOnDark;
  final String semanticLabel;

  @override
  Widget build(BuildContext context) {
    final useWhite =
        lightOnDark ?? Theme.of(context).brightness == Brightness.dark;
    return Image.asset(
      useWhite
          ? 'assets/branding/catbox_white.png'
          : 'assets/branding/catbox_black.png',
      width: size,
      height: size,
      fit: BoxFit.contain,
      semanticLabel: semanticLabel,
      filterQuality: FilterQuality.high,
    );
  }
}
