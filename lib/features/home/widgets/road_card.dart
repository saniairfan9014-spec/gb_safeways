import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/utils/helpers.dart';
import '../../roads/model/road_model.dart';

class RoadCard extends StatelessWidget {
  final RoadModel road;
  final VoidCallback? onTap;

  const RoadCard({
    super.key,
    required this.road,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isLight = Theme.of(context).brightness == Brightness.light;
    final statusColor = AppHelpers.getStatusColor(road.status);
    final statusIcon = AppHelpers.getStatusIcon(road.status);

    // Adaptive design tokens
    final cardBg = isLight ? Colors.white : AppColors.surface;
    final borderCol = isLight ? const Color(0xFFE2E8F0) : AppColors.border;
    final textPrim = isLight ? const Color(0xFF0F172A) : AppColors.textPrimary;
    final textSec = isLight ? const Color(0xFF475569) : AppColors.textSecondary;
    final textMut = isLight ? const Color(0xFF94A3B8) : AppColors.textMuted;
    final dividerCol = isLight ? const Color(0xFFF1F5F9) : AppColors.border;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderCol, width: 1.2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isLight ? 0.04 : 0.15),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Title and Status Badge
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(
                        road.name,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: textPrim,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: statusColor.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(30),
                        border: Border.all(color: statusColor.withOpacity(0.4), width: 1),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(statusIcon, size: 14, color: statusColor),
                          const SizedBox(width: 4),
                          Text(
                            road.status.toUpperCase(),
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: statusColor,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),

                // Route Origin -> Destination
                Row(
                  children: [
                    Icon(Icons.location_on_outlined, size: 14, color: textSec),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        "${road.origin} ➔ ${road.destination} • ${road.distanceKm} km",
                        style: TextStyle(
                          fontSize: 12,
                          color: textSec,
                        ),
                      ),
                    ),
                  ],
                ),
                Divider(color: dividerCol, height: 24, thickness: 1),

                // Latest Travel Advice
                Text(
                  road.description,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 13,
                    color: textSec,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 14),

                // Footer: Weather, Safety score, Last Updated
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Weather Tag
                    Row(
                      children: [
                        Icon(
                          _getWeatherIcon(road.weather),
                          size: 14,
                          color: const Color(0xFF0284C7),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          road.weather,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                            color: textSec,
                          ),
                        ),
                      ],
                    ),

                    // Safety Rating
                    Row(
                      children: [
                        const Icon(Icons.security_rounded, size: 14, color: Color(0xFFF472B6)),
                        const SizedBox(width: 4),
                        Text(
                          "Safety: ${road.safetyRating.toStringAsFixed(1)}/5.0",
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: textSec,
                          ),
                        ),
                      ],
                    ),

                    // Last Updated Time
                    Text(
                      AppHelpers.formatTimeAgo(road.lastUpdated),
                      style: TextStyle(
                        fontSize: 11,
                        color: textMut,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  IconData _getWeatherIcon(String weather) {
    final w = weather.toLowerCase();
    if (w.contains('clear') || w.contains('sun')) {
      return Icons.wb_sunny_rounded;
    } else if (w.contains('snow') || w.contains('blizzard') || w.contains('cold')) {
      return Icons.ac_unit_rounded;
    } else if (w.contains('rain') || w.contains('drizzle')) {
      return Icons.umbrella_rounded;
    } else if (w.contains('fog') || w.contains('mist')) {
      return Icons.cloudy_snowing;
    } else if (w.contains('wind')) {
      return Icons.air_rounded;
    }
    return Icons.wb_cloudy_rounded;
  }
}
