import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/utils/helpers.dart';
import '../../../shared/widgets/empty_state.dart';
import '../controller/sos_controller.dart';
import '../model/sos_alert_model.dart';

class AdminSosDashboard extends StatefulWidget {
  const AdminSosDashboard({super.key});

  @override
  State<AdminSosDashboard> createState() => _AdminSosDashboardState();
}

class _AdminSosDashboardState extends State<AdminSosDashboard> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<SosController>().fetchAdminActiveAlerts();
    });
  }

  IconData _getEmergencyIcon(String type) {
    switch (type) {
      case 'Road Accident':
        return Icons.car_crash_rounded;
      case 'Landslide':
        return Icons.terrain_rounded;
      case 'Snow Blockage':
        return Icons.ac_unit_rounded;
      case 'Flood':
        return Icons.water_rounded;
      case 'Medical Emergency':
        return Icons.medical_services_rounded;
      default:
        return Icons.emergency_rounded;
    }
  }

  Color _getEmergencyColor(String type) {
    switch (type) {
      case 'Road Accident':
        return const Color(0xFFEF4444);
      case 'Landslide':
        return const Color(0xFFD97706);
      case 'Snow Blockage':
        return const Color(0xFF2563EB);
      case 'Flood':
        return const Color(0xFF06B6D4);
      case 'Medical Emergency':
        return const Color(0xFF10B981);
      default:
        return const Color(0xFF6B7280);
    }
  }

  void _showResolveConfirmDialog(BuildContext context, SosAlertModel alert, SosController sosController) {
    final isLight = Theme.of(context).brightness == Brightness.light;
    final textPrim = isLight ? const Color(0xFF0F172A) : AppColors.textPrimary;
    final cardBg = isLight ? Colors.white : AppColors.surfaceElevated;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: cardBg,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Row(
          children: [
            const Icon(Icons.check_circle_outline_rounded, color: Color(0xFF10B981), size: 28),
            const SizedBox(width: 10),
            Text(
              "Resolve SOS Alert",
              style: TextStyle(fontWeight: FontWeight.bold, color: textPrim, fontSize: 18),
            ),
          ],
        ),
        content: Text(
          "Are you sure you want to resolve this SOS alert? This indicates that search and rescue or clearing operations are completed for ${alert.userName}'s distress signal.",
          style: TextStyle(color: isLight ? const Color(0xFF475569) : AppColors.textSecondary, fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(
              "Cancel",
              style: TextStyle(color: isLight ? const Color(0xFF475569) : AppColors.textSecondary, fontWeight: FontWeight.bold),
            ),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await sosController.resolveSosAlert(alert.id);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF10B981),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            ),
            child: const Text("Resolve SOS", style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final sosController = context.watch<SosController>();
    final isLight = Theme.of(context).brightness == Brightness.light;

    // Premium UI design tokens
    final bgCol = isLight ? const Color(0xFFF8FAFC) : AppColors.background;
    final textPrim = isLight ? const Color(0xFF0F172A) : AppColors.textPrimary;
    final textSec = isLight ? const Color(0xFF475569) : AppColors.textSecondary;
    final textMut = isLight ? const Color(0xFF94A3B8) : AppColors.textMuted;
    final cardBg = isLight ? Colors.white : AppColors.surface;
    final borderCol = isLight ? const Color(0xFFE2E8F0) : AppColors.border;

    return Scaffold(
      backgroundColor: bgCol,
      appBar: AppBar(
        backgroundColor: isLight ? Colors.white : AppColors.background,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded, color: textPrim, size: 18),
          onPressed: () => Navigator.pop(context),
        ),
        title: Row(
          children: [
            Text(
              "Admin SOS Control",
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: textPrim,
                letterSpacing: -0.5,
              ),
            ),
            const SizedBox(width: 10),
            if (!sosController.isLoading && sosController.adminActiveAlerts.isNotEmpty)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.statusDanger.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  "${sosController.adminActiveAlerts.length} ACTIVE",
                  style: const TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.w900,
                    color: AppColors.statusDanger,
                  ),
                ),
              ),
          ],
        ),
        actions: [
          IconButton(
            onPressed: () => sosController.fetchAdminActiveAlerts(),
            icon: Icon(Icons.sync_rounded, color: textPrim),
          ),
        ],
      ),
      body: SafeArea(
        child: sosController.isLoading && sosController.adminActiveAlerts.isEmpty
            ? const Center(child: CircularProgressIndicator())
            : RefreshIndicator(
                onRefresh: () => sosController.fetchAdminActiveAlerts(),
                child: sosController.adminActiveAlerts.isEmpty
                    ? ListView(
                        children: [
                          SizedBox(
                            height: MediaQuery.of(context).size.height * 0.75,
                            child: EmptyState(
                              title: "All Regions Secure",
                              description: "No active SOS coordinates or satellite beacons detected in Gilgit-Baltistan.",
                              icon: Icons.shield_rounded,
                              onAction: () => sosController.fetchAdminActiveAlerts(),
                              actionText: "Reload Dashboard",
                            ),
                          ),
                        ],
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.all(20.0),
                        itemCount: sosController.adminActiveAlerts.length,
                        itemBuilder: (context, index) {
                          final alert = sosController.adminActiveAlerts[index];
                          final color = _getEmergencyColor(alert.emergencyType);

                          return Container(
                            margin: const EdgeInsets.only(bottom: 18),
                            decoration: BoxDecoration(
                              color: cardBg,
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: borderCol, width: 1.2),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(isLight ? 0.03 : 0.15),
                                  blurRadius: 10,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(18.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // User profile section
                                  Row(
                                    children: [
                                      CircleAvatar(
                                        radius: 20,
                                        backgroundImage: NetworkImage(alert.userAvatar ??
                                            'https://ui-avatars.com/api/?name=Traveler&background=0284C7&color=fff&bold=true'),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              alert.userName ?? 'Karakoram Traveler',
                                              style: TextStyle(
                                                fontWeight: FontWeight.bold,
                                                color: textPrim,
                                                fontSize: 14,
                                              ),
                                            ),
                                            Text(
                                              alert.userEmail ?? 'traveler@karakoram.com',
                                              style: TextStyle(
                                                color: textMut,
                                                fontSize: 11,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                        decoration: BoxDecoration(
                                          color: color.withOpacity(0.1),
                                          borderRadius: BorderRadius.circular(20),
                                        ),
                                        child: Row(
                                          children: [
                                            Icon(_getEmergencyIcon(alert.emergencyType), color: color, size: 12),
                                            const SizedBox(width: 4),
                                            Text(
                                              alert.emergencyType.toUpperCase(),
                                              style: TextStyle(
                                                fontSize: 9,
                                                fontWeight: FontWeight.w900,
                                                color: color,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                  const Divider(height: 24),

                                  // Location coords & time details
                                  Row(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const Icon(Icons.my_location_rounded, color: AppColors.statusDanger, size: 16),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              "COORDINATES",
                                              style: TextStyle(fontSize: 10, color: textMut, fontWeight: FontWeight.bold, letterSpacing: 0.5),
                                            ),
                                            const SizedBox(height: 2),
                                            Text(
                                              "Lat: ${alert.latitude.toStringAsFixed(6)}, Lng: ${alert.longitude.toStringAsFixed(6)}",
                                              style: TextStyle(fontSize: 13, color: textSec, fontWeight: FontWeight.bold),
                                            ),
                                          ],
                                        ),
                                      ),
                                      Text(
                                        AppHelpers.formatTimeAgo(alert.createdAt),
                                        style: TextStyle(color: textMut, fontSize: 11),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 12),

                                  if (alert.description != null && alert.description!.isNotEmpty) ...[
                                    Container(
                                      padding: const EdgeInsets.all(12),
                                      width: double.infinity,
                                      decoration: BoxDecoration(
                                        color: isLight ? const Color(0xFFF1F5F9) : AppColors.surfaceElevated,
                                        borderRadius: BorderRadius.circular(12),
                                        border: Border.all(color: borderCol, width: 0.8),
                                      ),
                                      child: Text(
                                        alert.description!,
                                        style: TextStyle(fontSize: 13, color: textSec, height: 1.4),
                                      ),
                                    ),
                                    const SizedBox(height: 16),
                                  ],

                                  // Action resolution row
                                  SizedBox(
                                    width: double.infinity,
                                    child: ElevatedButton.icon(
                                      onPressed: () => _showResolveConfirmDialog(context, alert, sosController),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: const Color(0xFF10B981),
                                        foregroundColor: Colors.white,
                                        elevation: 0,
                                        padding: const EdgeInsets.symmetric(vertical: 12),
                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                      ),
                                      icon: const Icon(Icons.check_circle_rounded, size: 16),
                                      label: const Text(
                                        "MARK AS RESOLVED",
                                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, letterSpacing: 0.5),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
              ),
      ),
    );
  }
}
