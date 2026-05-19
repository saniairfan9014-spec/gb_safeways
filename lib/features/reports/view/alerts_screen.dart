import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/utils/helpers.dart';
import '../../../shared/widgets/empty_state.dart';
import '../controller/report_controller.dart';
import '../../roads/controller/road_controller.dart';

class AlertsScreen extends StatefulWidget {
  const AlertsScreen({super.key});

  @override
  State<AlertsScreen> createState() => _AlertsScreenState();
}

class _AlertsScreenState extends State<AlertsScreen> {
  bool _notificationsEnabled = true;

  // Static high-level system alerts to combine with community hazard reports
  final List<Map<String, dynamic>> _systemAlerts = [
    {
      'id': 'sys-alert-1',
      'type': 'Emergency',
      'title': 'Severe Weather Warning: Avalanches',
      'description': 'Extreme snowfall and active avalanche warnings issued for Babusar Pass and higher elevations of Khunjerab. GBDMA has closed the passes until further notice. Do not attempt travel.',
      'timestamp': DateTime.now().subtract(const Duration(minutes: 8)),
      'severity': 'High',
    },
    {
      'id': 'sys-alert-2',
      'type': 'Weather',
      'title': 'Strong Winds Advisory: Karakoram',
      'description': 'Advisory: High-altitude winds exceeding 50+ mph expected around Sust and Tashkurgan highway checkpoints. Secure all light cargo and exercise caution.',
      'timestamp': DateTime.now().subtract(const Duration(minutes: 25)),
      'severity': 'Medium',
    }
  ];

  void _toggleNotifications(bool value) {
    setState(() {
      _notificationsEnabled = value;
    });
    final snackBar = SnackBar(
      content: Text(
        value
            ? "🔔 Push notifications enabled for active Karakoram & Baltistan routes."
            : "🔕 Push notifications muted.",
        style: const TextStyle(fontWeight: FontWeight.bold),
      ),
      backgroundColor: value ? const Color(0xFF0284C7) : const Color(0xFF64748B),
      duration: const Duration(seconds: 2),
    );
    ScaffoldMessenger.of(context).showSnackBar(snackBar);
  }

  @override
  Widget build(BuildContext context) {
    final reportController = context.watch<ReportController>();
    final roadController = context.watch<RoadController>();
    final isLight = Theme.of(context).brightness == Brightness.light;

    // Adaptive tokens
    final bgCol = isLight ? const Color(0xFFF8FAFC) : AppColors.background;
    final textPrim = isLight ? const Color(0xFF0F172A) : AppColors.textPrimary;
    final textSec = isLight ? const Color(0xFF475569) : AppColors.textSecondary;
    final cardBg = isLight ? Colors.white : AppColors.surface;
    final borderCol = isLight ? const Color(0xFFE2E8F0) : AppColors.border;

    // Merge system alerts with dynamic community reports
    final allAlerts = <Map<String, dynamic>>[];

    // Add system alerts
    for (final sys in _systemAlerts) {
      allAlerts.add(sys);
    }

    // Add active community reports as "Road Block" alerts
    for (final report in reportController.activeReports) {
      allAlerts.add({
        'id': report.id,
        'type': 'Road Block',
        'title': '${report.hazardType}: ${report.roadName}',
        'description': report.description,
        'timestamp': report.createdAt,
        'severity': report.severity,
        'isReport': true,
        'upvotes': report.upvotes,
        'reportRef': report,
      });
    }

    // Sort by timestamp (newest first)
    allAlerts.sort((a, b) => (b['timestamp'] as DateTime).compareTo(a['timestamp'] as DateTime));

    return Scaffold(
      backgroundColor: bgCol,
      appBar: AppBar(
        backgroundColor: isLight ? Colors.white : AppColors.background,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        title: Text(
          "Safety Alerts",
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w800,
            color: textPrim,
            letterSpacing: -0.5,
          ),
        ),
        actions: [
          // Notification Toggle Row
          Row(
            children: [
              Icon(
                _notificationsEnabled ? Icons.notifications_active_rounded : Icons.notifications_off_rounded,
                color: _notificationsEnabled ? const Color(0xFF0284C7) : textSec,
                size: 20,
              ),
              const SizedBox(width: 4),
              Switch(
                value: _notificationsEnabled,
                onChanged: _toggleNotifications,
                activeColor: const Color(0xFF0284C7),
                activeTrackColor: const Color(0xFF0284C7).withOpacity(0.16),
              ),
              const SizedBox(width: 16),
            ],
          ),
        ],
      ),
      body: SafeArea(
        child: allAlerts.isEmpty
            ? Center(
                child: EmptyState(
                  title: "Clear Blue Skies",
                  description: "There are currently no active highway warnings or weather alerts reported.",
                  icon: Icons.wb_sunny_rounded,
                  onAction: () => reportController.loadReports(),
                  actionText: "Refresh Alerts",
                ),
              )
            : ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 12.0),
                itemCount: allAlerts.length,
                itemBuilder: (context, index) {
                  final alert = allAlerts[index];
                  final severity = alert['severity'] as String;
                  final isHigh = severity == 'High';
                  final isReport = alert['isReport'] == true;
                  final timeAgo = AppHelpers.formatTimeAgo(alert['timestamp'] as DateTime);

                  // Setup type badges
                  IconData typeIcon;
                  Color badgeColor;
                  String badgeText;

                  if (alert['type'] == 'Emergency') {
                    typeIcon = Icons.error_rounded;
                    badgeColor = const Color(0xFFEF4444);
                    badgeText = "Emergency Warning";
                  } else if (alert['type'] == 'Weather') {
                    typeIcon = Icons.cloudy_snowing;
                    badgeColor = const Color(0xFF0284C7);
                    badgeText = "Weather Alert";
                  } else {
                    typeIcon = Icons.block_flipped;
                    badgeColor = const Color(0xFFF59E0B);
                    badgeText = "Road Block";
                  }

                  // Priority Alerts get glowing border and soft gradient background
                  final BoxDecoration cardDecoration = isHigh
                      ? BoxDecoration(
                          color: cardBg,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: const Color(0xFFEF4444).withOpacity(0.8), width: 1.5),
                          gradient: LinearGradient(
                            colors: isLight
                                ? [const Color(0xFFFCE8E6).withOpacity(0.4), Colors.white]
                                : [const Color(0xFF7F1D1D).withOpacity(0.12), AppColors.surface],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFFEF4444).withOpacity(isLight ? 0.04 : 0.1),
                              blurRadius: 12,
                              spreadRadius: 2,
                            ),
                          ],
                        )
                      : BoxDecoration(
                          color: cardBg,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: borderCol, width: 1.2),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(isLight ? 0.02 : 0.08),
                              blurRadius: 8,
                              offset: const Offset(0, 3),
                            ),
                          ],
                        );

                  return Container(
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: cardDecoration,
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Header: Badge & Timestamp
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              // Badge
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: badgeColor.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(color: badgeColor.withOpacity(0.3), width: 1),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(typeIcon, color: badgeColor, size: 14),
                                    const SizedBox(width: 4),
                                    Text(
                                      badgeText,
                                      style: TextStyle(
                                        color: badgeColor,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 10,
                                        letterSpacing: 0.5,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              // Timestamp
                              Text(
                                timeAgo,
                                style: TextStyle(
                                  fontSize: 11,
                                  color: isLight ? const Color(0xFF64748B) : AppColors.textMuted,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),

                          // Title Description
                          Text(
                            alert['title'] as String,
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                              color: textPrim,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            alert['description'] as String,
                            style: TextStyle(
                              fontSize: 13,
                              color: textSec,
                              height: 1.4,
                            ),
                          ),

                          // Dynamic report action bar (if contributed by traveller)
                          if (isReport) ...[
                            const SizedBox(height: 12),
                            Divider(color: borderCol, height: 16, thickness: 1),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                // Contributed By
                                Row(
                                  children: [
                                    CircleAvatar(
                                      radius: 9,
                                      backgroundImage: NetworkImage(alert['reportRef'].userAvatar),
                                    ),
                                    const SizedBox(width: 6),
                                    Text(
                                      alert['reportRef'].userName,
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: isLight ? const Color(0xFF64748B) : AppColors.textMuted,
                                      ),
                                    ),
                                  ],
                                ),

                                // Upvote Actions
                                Row(
                                  children: [
                                    InkWell(
                                      onTap: () => reportController.upvoteReport(alert['id']),
                                      borderRadius: BorderRadius.circular(12),
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                        decoration: BoxDecoration(
                                          color: isLight ? const Color(0xFFF1F5F9) : AppColors.surfaceElevated,
                                          borderRadius: BorderRadius.circular(12),
                                        ),
                                        child: Row(
                                          children: [
                                            const Icon(Icons.thumb_up_alt_outlined, size: 12, color: Color(0xFF0284C7)),
                                            const SizedBox(width: 4),
                                            Text(
                                              "Upvote (${alert['upvotes']})",
                                              style: const TextStyle(
                                                fontSize: 11,
                                                fontWeight: FontWeight.bold,
                                                color: Color(0xFF0284C7),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                    // Warden Resolve option (if logged in, allows testing clear states)
                                    const SizedBox(width: 8),
                                    InkWell(
                                      onTap: () => reportController.resolveReport(alert['id'], roadController),
                                      borderRadius: BorderRadius.circular(12),
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFF10B981).withOpacity(0.08),
                                          borderRadius: BorderRadius.circular(12),
                                        ),
                                        child: Row(
                                          children: const [
                                            Icon(Icons.check_circle_outline_rounded, size: 12, color: Color(0xFF10B981)),
                                            SizedBox(width: 4),
                                            Text(
                                              "Clear",
                                              style: TextStyle(
                                                fontSize: 11,
                                                fontWeight: FontWeight.bold,
                                                color: Color(0xFF10B981),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ],
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
    );
  }
}
