import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/utils/helpers.dart';
import '../../../shared/widgets/empty_state.dart';
import '../controller/road_controller.dart';
import '../../home/widgets/road_card.dart';

class RoadStatusScreen extends StatefulWidget {
  const RoadStatusScreen({super.key});

  @override
  State<RoadStatusScreen> createState() => _RoadStatusScreenState();
}

class _RoadStatusScreenState extends State<RoadStatusScreen> {
  final _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _showRoadDetailsSheet(BuildContext context, dynamic road) {
    final isLight = Theme.of(context).brightness == Brightness.light;
    final statusColor = AppHelpers.getStatusColor(road.status);
    final statusIcon = AppHelpers.getStatusIcon(road.status);

    // Adaptive tokens
    final sheetBg = isLight ? Colors.white : AppColors.surface;
    final textPrim = isLight ? const Color(0xFF0F172A) : AppColors.textPrimary;
    final textSec = isLight ? const Color(0xFF475569) : AppColors.textSecondary;
    final textMut = isLight ? const Color(0xFF94A3B8) : AppColors.textMuted;
    final borderCol = isLight ? const Color(0xFFE2E8F0) : AppColors.border;
    final boxBg = isLight ? const Color(0xFFF8FAFC) : AppColors.surfaceElevated;

    showModalBottomSheet(
      context: context,
      backgroundColor: sheetBg,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                // Top Notch decoration
                Center(
                  child: Container(
                    width: 40,
                    height: 5,
                    decoration: BoxDecoration(
                      color: borderCol,
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                // Name and Status
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        road.name,
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: textPrim,
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: statusColor.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(30),
                        border: Border.all(color: statusColor.withOpacity(0.4)),
                      ),
                      child: Row(
                        children: [
                          Icon(statusIcon, size: 14, color: statusColor),
                          const SizedBox(width: 4),
                          Text(
                            road.status.toUpperCase(),
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: statusColor,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),

                // Origin & Destination
                Text(
                  "Route: ${road.origin} to ${road.destination}",
                  style: TextStyle(color: textSec, fontSize: 14),
                ),
                const SizedBox(height: 4),
                Text(
                  "Distance: ${road.distanceKm} km  |  Last update: ${AppHelpers.formatDate(road.lastUpdated)}",
                  style: TextStyle(color: textMut, fontSize: 12),
                ),
                Divider(color: borderCol, height: 32),

                // Safety Indicators
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildMetricBox(
                      icon: Icons.wb_cloudy_outlined,
                      label: "WEATHER",
                      value: road.weather,
                      isLight: isLight,
                    ),
                    _buildMetricBox(
                      icon: Icons.security_outlined,
                      label: "SAFETY INDEX",
                      value: "${road.safetyRating.toStringAsFixed(1)} / 5.0",
                      isLight: isLight,
                      valueColor: road.safetyRating >= 4.0
                          ? AppColors.statusOpen
                          : road.safetyRating >= 2.5
                              ? AppColors.statusCaution
                              : AppColors.statusDanger,
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // Description
                Text(
                  "Latest Travel Advisory",
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: textPrim,
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: boxBg,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: borderCol),
                  ),
                  child: Text(
                    road.description,
                    style: TextStyle(
                      color: textSec,
                      fontSize: 13,
                      height: 1.5,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildMetricBox({
    required IconData icon,
    required String label,
    required String value,
    required bool isLight,
    Color? valueColor,
  }) {
    return Column(
      children: [
        Icon(icon, size: 24, color: const Color(0xFF0284C7)),
        const SizedBox(height: 6),
        Text(
          label,
          style: TextStyle(
            fontSize: 10, 
            color: isLight ? const Color(0xFF94A3B8) : AppColors.textMuted, 
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: valueColor ?? (isLight ? const Color(0xFF0F172A) : AppColors.textPrimary),
          ),
        ),
      ],
    );
  }

  Widget _buildFilterButton(String label, bool isSelected, VoidCallback onTap, bool isLight) {
    Color activeBg;
    Color inactiveBg;
    Color activeFg = Colors.white;
    Color inactiveFg;

    if (label == "All") {
      activeBg = const Color(0xFF0284C7); // Sky Blue
      inactiveBg = isLight ? const Color(0xFFF1F5F9) : const Color(0xFF1E293B);
      inactiveFg = isLight ? const Color(0xFF475569) : const Color(0xFF94A3B8);
    } else if (label == "Open") {
      activeBg = const Color(0xFF10B981); // Emerald Green
      inactiveBg = isLight ? const Color(0xFFE6F4EA) : const Color(0xFF064E3B).withOpacity(0.3);
      inactiveFg = const Color(0xFF10B981);
    } else { // Closed
      activeBg = const Color(0xFFEF4444); // Crimson Red
      inactiveBg = isLight ? const Color(0xFFFCE8E6) : const Color(0xFF7F1D1D).withOpacity(0.3);
      inactiveFg = const Color(0xFFEF4444);
    }

    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isSelected ? activeBg : inactiveBg,
            borderRadius: BorderRadius.circular(30),
            border: Border.all(
              color: isSelected 
                  ? activeBg 
                  : (isLight ? const Color(0xFFE2E8F0) : const Color(0xFF334155)),
              width: 1,
            ),
          ),
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: isSelected ? activeFg : inactiveFg,
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final roadController = context.watch<RoadController>();
    final isLight = Theme.of(context).brightness == Brightness.light;

    // Adaptive tokens
    final bgCol = isLight ? const Color(0xFFF8FAFC) : AppColors.background;
    final textPrim = isLight ? const Color(0xFF0F172A) : AppColors.textPrimary;
    final textSec = isLight ? const Color(0xFF475569) : AppColors.textSecondary;

    return Container(
      color: bgCol,
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 12.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header title
              Text(
                "Road Status",
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                  color: textPrim,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                "Live mountain highway logs and checkpoints",
                style: TextStyle(
                  fontSize: 13,
                  color: textSec,
                ),
              ),
              const SizedBox(height: 16),

              // Search Bar
              TextField(
                controller: _searchController,
                onChanged: (val) => roadController.updateSearchQuery(val),
                style: TextStyle(color: textPrim, fontSize: 14),
                decoration: InputDecoration(
                  hintText: "Search roads, passes, or checkpoints...",
                  hintStyle: TextStyle(color: isLight ? const Color(0xFF94A3B8) : AppColors.textMuted),
                  prefixIcon: Icon(Icons.search_rounded, color: isLight ? const Color(0xFF64748B) : AppColors.textSecondary),
                  filled: true,
                  fillColor: isLight ? Colors.white : AppColors.surfaceElevated,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: isLight ? const Color(0xFFE2E8F0) : AppColors.border, width: 1.2),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: isLight ? const Color(0xFFE2E8F0) : AppColors.border, width: 1.2),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Color(0xFF0284C7), width: 1.5),
                  ),
                  suffixIcon: _searchController.text.isNotEmpty
                      ? IconButton(
                          icon: Icon(Icons.clear_rounded, color: isLight ? const Color(0xFF64748B) : AppColors.textSecondary),
                          onPressed: () {
                            _searchController.clear();
                            roadController.updateSearchQuery("");
                          },
                        )
                      : null,
                ),
              ),
              const SizedBox(height: 16),

              // Filter Row
              Row(
                children: [
                  _buildFilterButton("All", roadController.statusFilter == "All", () {
                    roadController.setFilter("All");
                  }, isLight),
                  const SizedBox(width: 10),
                  _buildFilterButton("Open", roadController.statusFilter == "Open", () {
                    roadController.setFilter("Open");
                  }, isLight),
                  const SizedBox(width: 10),
                  _buildFilterButton("Closed", roadController.statusFilter == "Closed", () {
                    roadController.setFilter("Closed");
                  }, isLight),
                ],
              ),
              const SizedBox(height: 20),

              // Roads List
              Expanded(
                child: roadController.isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : roadController.filteredRoads.isEmpty
                        ? EmptyState(
                            title: "No Routes Found",
                            description: "Try adjusting your search criteria or filters.",
                            icon: Icons.directions_off_rounded,
                            onAction: () {
                              _searchController.clear();
                              roadController.updateSearchQuery("");
                              roadController.setFilter("All");
                            },
                            actionText: "Reset Filters",
                          )
                        : ListView.builder(
                            itemCount: roadController.filteredRoads.length,
                            itemBuilder: (context, index) {
                              final road = roadController.filteredRoads[index];
                              return RoadCard(
                                road: road,
                                onTap: () => _showRoadDetailsSheet(context, road),
                              );
                            },
                          ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
