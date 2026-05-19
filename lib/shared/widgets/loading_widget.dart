import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';

class LoadingWidget extends StatelessWidget {
  final String message;

  const LoadingWidget({
    super.key,
    this.message = "Securing mountain route data...",
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          Stack(
            alignment: Alignment.center,
            children: [
              const SizedBox(
                width: 70,
                height: 70,
                child: CircularProgressIndicator(
                  strokeWidth: 3,
                  valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
                ),
              ),
              // Beautiful snow mountain peak outline inside the circle
              Icon(
                Icons.terrain_rounded,
                size: 32,
                color: AppColors.primary.withOpacity(0.8),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Text(
            message,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 14,
              fontWeight: FontWeight.w500,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }
}
