import 'package:flutter/material.dart';

/// Menu items for the ReportActivity landing screen.
class ReportMenuItemData {
  final String title;
  final String imageAsset;
  final IconData fallbackIcon;
  final Color fallbackBg;
  final Color fallbackIconColor;
  final bool hasBorderOnFallback;

  const ReportMenuItemData({
    required this.title,
    required this.imageAsset,
    required this.fallbackIcon,
    required this.fallbackBg,
    required this.fallbackIconColor,
    this.hasBorderOnFallback = false,
  });
}

/// Landing page menu items for Report & Activity.
const List<ReportMenuItemData> defaultReportMenuItems = [
  ReportMenuItemData(
    title: 'Report 1',
    imageAsset: 'assets/images/taskchat_report_logo.png',
    fallbackIcon: Icons.bar_chart_rounded,
    fallbackBg: Color(0xFFDCFCE7),
    fallbackIconColor: Color(0xFF036838),
  ),
  ReportMenuItemData(
    title: 'Activity',
    imageAsset: 'assets/images/taskchat_activity_logo.png',
    fallbackIcon: Icons.handshake_outlined,
    fallbackBg: Color(0xFFFEF3C7),
    fallbackIconColor: Color(0xFF0D9488),
    hasBorderOnFallback: true,
  ),
];
