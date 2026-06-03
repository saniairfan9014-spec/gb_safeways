import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/utils/helpers.dart';
import '../../../shared/widgets/empty_state.dart';
import '../../auth/controller/auth_controller.dart';
import '../controller/sos_controller.dart';
import '../model/sos_alert_model.dart';

class SosHistoryScreen extends StatefulWidget {
  const SosHistoryScreen({super.key});

  @override
  State<SosHistoryScreen> createState() => _SosHistoryScreenState();
}

class _SosHistoryScreenState extends State<SosHistoryScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final user = context.read<AuthController>().currentUser;
      if (user != null) {
        context.read<SosController>().fetchMyHistory(user.id);
      }
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

  @override
  Widget build(BuildContext context) {
    final sosController = context.watch<SosController>();
    final user = context.watch<AuthController>().currentUser;
    final isLight = Theme.of(context).brightness == Brightness.light;

    // Premium UI design tokens
    final bgCol = isLight ? const Color(0xFFF8FAFC) : AppColors.background;
    final textPrim = isLight ? const Color(0xFF0F172A) : AppColors.textPrimary;
    final textSec = isLight ? const Color(0xFF475569) : AppColors.textSecondary;
    final cardBg = isLight ? Colors.white : AppColors.surface;
    final borderCol = isLight ? const Color(0xFFE2E8F0) : AppColors.border;

    if (user == null) {
      return const Scaffold(
        body: Center(child: Text("Please login to view SOS history.")),
      );
    }

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
        title: Text(
          "My SOS History",
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w800,
            color: textPrim,
            letterSpacing: -0.5,
          ),
        ),
      ),
      body: SafeArea(
        child: sosController.isLoading
            ? const Center(child: CircularProgressIndicator())
            : RefreshIndicator(
                onRefresh: () => sosController.fetchMyHistory(user.id),
                child: sosController.myHistory.isEmpty
                    ? ListView(
                        children: [
                          SizedBox(
                            height: MediaQuery.of(context).size.height * 0.7,
                            child: EmptyState(
                              title: "No SOS Broadcasts",
                              description: "You have not broadcasted any emergency SOS requests yet.",
                              icon: Icons.safety_check_rounded,
                              onAction: () => sosController.fetchMyHistory(user.id),
                              actionText: "Refresh List",
                            ),
                          ),
                        ],
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.all(20.0),
                        itemCount: sosController.myHistory.length,
                        itemBuilder: (context, index) {
                          final alert = sosController.myHistory[index];
                          final isActive = alert.status == 'active';
                          final color = _getEmergencyColor(alert.emergencyType);

                          return Container(
                            margin: const EdgeInsets.only(bottom: 16),
                            decoration: BoxDecoration(
                              color: cardBg,
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: isActive ? AppColors.statusDanger : borderCol,
                                width: isActive ? 2.0 : 1.2,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: isActive
                                      ? AppColors.statusDanger.withOpacity(0.08)
                                      : Colors.black.withOpacity(isLight ? 0.03 : 0.1),
                                  blurRadius: 12,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(18.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Top emergency icon & status badge
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Row(
                                        children: [
                                          Container(
                                            padding: const EdgeInsets.all(8),
                                            decoration: BoxDecoration(
                                              color: color.withOpacity(0.1),
                                              shape: BoxShape.circle,
                                            ),
                                            child: Icon(
                                              _getEmergencyIcon(alert.emergencyType),
                                              color: color,
                                              size: 20,
                                            ),
                                          ),
                                          const SizedBox(width: 12),
                                          Text(
                                            alert.emergencyType,
                                            style: TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.bold,
                                              color: textPrim,
                                            ),
                                          ),
                                        ],
                                      ),
                                      _buildStatusBadge(isActive, isLight),
                                    ],
                                  ),
                                  const Divider(height: 24),
                                  
                                  // Time and Location Coordinates details
                                  Row(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const Icon(Icons.access_time_rounded, color: Color(0xFF64748B), size: 16),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              "Broadcast Time",
                                              style: TextStyle(fontSize: 11, color: isLight ? const Color(0xFF64748B) : AppColors.textMuted, fontWeight: FontWeight.bold),
                                            ),
                                            const SizedBox(height: 2),
                                            Text(
                                              AppHelpers.formatDate(alert.createdAt),
                                              style: TextStyle(fontSize: 13, color: textSec, fontWeight: FontWeight.w500),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 12),

                                  Row(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const Icon(Icons.pin_drop_rounded, color: Color(0xFF64748B), size: 16),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              "GPS Coordinates",
                                              style: TextStyle(fontSize: 11, color: isLight ? const Color(0xFF64748B) : AppColors.textMuted, fontWeight: FontWeight.bold),
                                            ),
                                            const SizedBox(height: 2),
                                            Text(
                                              "Lat: ${alert.latitude.toStringAsFixed(6)}, Lng: ${alert.longitude.toStringAsFixed(6)}",
                                              style: TextStyle(fontSize: 13, color: textSec, fontWeight: FontWeight.w500),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                  
                                  if (alert.description != null && alert.description!.isNotEmpty) ...[
                                    const SizedBox(height: 16),
                                    Container(
                                      padding: const EdgeInsets.all(12),
                                      width: double.infinity,
                                      decoration: BoxDecoration(
                                        color: isLight ? const Color(0xFFF1F5F9) : AppColors.surfaceElevated,
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      child: Text(
                                        alert.description!,
                                        style: TextStyle(fontSize: 13, color: textSec, height: 1.4, fontStyle: FontStyle.italic),
                                      ),
                                    ),
                                  ],

                                  if (!isActive && alert.resolvedAt != null) ...[
                                    const Divider(height: 24),
                                    Row(
                                      children: [
                                        const Icon(Icons.check_circle_outline_rounded, color: Color(0xFF10B981), size: 16),
                                        const SizedBox(width: 8),
                                        Text(
                                          "Resolved on ${AppHelpers.formatDate(alert.resolvedAt!)}",
                                          style: const TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.bold,
                                            color: Color(0xFF10B981),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
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

  Widget _buildStatusBadge(bool isActive, bool isLight) {
    final bg = isActive
        ? AppColors.statusDanger.withOpacity(0.12)
        : const Color(0xFF10B981).withOpacity(0.12);
    final text = isActive ? AppColors.statusDanger : const Color(0xFF10B981);
    final label = isActive ? "ACTIVE SOS" : "RESOLVED";

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: text.withOpacity(0.3), width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (isActive) ...[
            const _ActiveDotPulse(),
            const SizedBox(width: 6),
          ],
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w900,
              color: text,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }
}

class _ActiveDotPulse extends StatefulWidget {
  const _ActiveDotPulse();

  @override
  State<_ActiveDotPulse> createState() => _ActiveDotPulseState();
}

class _ActiveDotPulseState extends State<_ActiveDotPulse> with SingleTickerProviderStateMixin {
  late AnimationController _pulse;

  @override
  void initState() {
    super.initState();
    _pulse = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _pulse,
      builder: (context, child) {
        return Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: AppColors.statusDanger.withOpacity(0.4 + (_pulse.value * 0.6)),
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: AppColors.statusDanger.withOpacity(0.2 * _pulse.value),
                blurRadius: 4,
                spreadRadius: 2 * _pulse.value,
              ),
            ],
          ),
        );
      },
    );
  }
}
