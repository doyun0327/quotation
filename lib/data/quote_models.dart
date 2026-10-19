import 'package:flutter/material.dart';
import 'package:quotation/widgets/pixel_icons.dart';

class Quote {
  const Quote({
    required this.id,
    required this.text,
    this.author = '작가 미상',
    this.featured = false,
  });

  final String id;
  final String text;
  final String author;
  final bool featured;
}

class SubCategory {
  const SubCategory({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.bannerText,
    required this.icon,
    required this.iconColor,
    required this.iconBackground,
    required this.quotes,
  });

  final String id;
  final String title;
  final String subtitle;
  final String bannerText;
  final IconData icon;
  final Color iconColor;
  final Color iconBackground;
  final List<Quote> quotes;
}

class MainCategory {
  const MainCategory({
    required this.id,
    required this.title,
    required this.lines,
    required this.bannerText,
    required this.background,
    required this.accent,
    required this.border,
    required this.bannerColor,
    required this.pixelIcon,
    required this.subCategories,
  });

  final String id;
  final String title;
  final List<String> lines;
  final String bannerText;
  final Color background;
  final Color accent;
  final Color border;
  final Color bannerColor;
  final PixelIconKind pixelIcon;
  final List<SubCategory> subCategories;

  List<Quote> get allQuotes => [
        for (final sub in subCategories) ...sub.quotes,
      ];
}
