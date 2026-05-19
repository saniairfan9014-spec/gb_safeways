import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../core/constants/app_colors.dart';

class AppHelpers {
  AppHelpers._();

  static Color getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'open':
      case 'safe':
        return AppColors.statusOpen;
      case 'caution':
      case 'one-way':
      case 'partial':
      case 'under construction':
        return AppColors.statusCaution;
      case 'closed':
      case 'blocked':
      case 'danger':
      case 'hazard':
        return AppColors.statusDanger;
      default:
        return AppColors.statusUnknown;
    }
  }

  static IconData getStatusIcon(String status) {
    switch (status.toLowerCase()) {
      case 'open':
      case 'safe':
        return Icons.check_circle_outline;
      case 'caution':
      case 'one-way':
      case 'partial':
      case 'under construction':
        return Icons.warning_amber_rounded;
      case 'closed':
      case 'blocked':
      case 'danger':
      case 'hazard':
        return Icons.block_flipped;
      default:
        return Icons.help_outline;
    }
  }

  static String formatDate(DateTime dateTime) {
    return DateFormat('MMM dd, yyyy - hh:mm a').format(dateTime);
  }

  static String formatTimeAgo(DateTime dateTime) {
    final difference = DateTime.now().difference(dateTime);
    if (difference.inDays > 7) {
      return DateFormat('MMM dd').format(dateTime);
    } else if (difference.inDays >= 1) {
      return '${difference.inDays}d ago';
    } else if (difference.inHours >= 1) {
      return '${difference.inHours}h ago';
    } else if (difference.inMinutes >= 1) {
      return '${difference.inMinutes}m ago';
    } else {
      return 'Just now';
    }
  }

  static String getRandomAvatarUrl(String name) {
    final cleanName = name.replaceAll(' ', '+');
    return 'https://ui-avatars.com/api/?name=$cleanName&background=0EA5E9&color=fff&bold=true';
  }
}
