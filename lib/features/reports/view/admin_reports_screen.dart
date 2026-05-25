import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/utils/helpers.dart';
import '../../../shared/widgets/empty_state.dart';
import '../../roads/controller/road_controller.dart';
import '../controller/report_controller.dart';
import '../model/report_model.dart';

class AdminReportsScreen extends StatefulWidget {
  const AdminReportsScreen({super.key});

  @override
  State<AdminReportsScreen> createState() => _AdminReportsScreenState();
}

class _AdminReportsScreenState extends State<AdminReportsScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _showVerifyDialog(BuildContext context, ReportModel report, ReportController reportController, RoadController roadController) {
    String selectedRoadStatus = 'Blocked';
    final isLight = Theme.of(context).brightness == Brightness.light;
    final textPrim = isLight ? const Color(0xFF0F172A) : AppColors.textPrimary;
    final cardBg = isLight ? Colors.white : AppColors.surfaceElevated;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) {
          return AlertDialog(
            backgroundColor: cardBg,
            surfaceTintColor: Colors.transparent,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
            title: Text(
              "Verify Hazard Report",
              style: TextStyle(fontWeight: FontWeight.bold, color: textPrim, fontSize: 18),
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  "Confirming this report will set its status to verified. Please choose the updated status for ${report.roadName}:",
                  style: TextStyle(color: isLight ? const Color(0xFF475569) : AppColors.textSecondary, fontSize: 13),
                ),
                const SizedBox(height: 20),
                ...['Blocked', 'Closed', 'Slow', 'Under Construction', 'Open'].map((status) {
                  final isSelected = selectedRoadStatus == status;
                  return RadioListTile<String>(
                    title: Text(status, style: TextStyle(color: textPrim, fontSize: 14, fontWeight: isSelected ? FontWeight.bold : FontWeight.normal)),
                    value: status,
                    groupValue: selectedRoadStatus,
                    activeColor: const Color(0xFF0284C7),
                    contentPadding: EdgeInsets.zero,
                    onChanged: (val) {
                      if (val != null) {
                        setDialogState(() {
                          selectedRoadStatus = val;
                        });
                      }
                    },
                  );
                }).toList(),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: Text("Cancel", style: TextStyle(color: isLight ? const Color(0xFF475569) : AppColors.textSecondary, fontWeight: FontWeight.bold)),
              ),
              ElevatedButton(
                onPressed: () async {
                  Navigator.pop(ctx);
                  final mappedStatus = selectedRoadStatus == 'Under Construction'
                      ? 'under_construction'
                      : selectedRoadStatus.toLowerCase();
                  
                  final success = await reportController.verifyReport(
                    report: report,
                    newRoadStatus: mappedStatus,
                    roadController: roadController,
                  );

                  if (success && mounted) {
                    // Refresh roads & reports in backend
                    roadController.loadRoads();
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF10B981),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                ),
                child: const Text("Verify & Apply", style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ],
          );
        },
      ),
    );
  }

  void _showRejectDialog(BuildContext context, ReportModel report, ReportController reportController) {
    final isLight = Theme.of(context).brightness == Brightness.light;
    final textPrim = isLight ? const Color(0xFF0F172A) : AppColors.textPrimary;
    final cardBg = isLight ? Colors.white : AppColors.surfaceElevated;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: cardBg,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Text(
          "Reject Hazard Report",
          style: TextStyle(fontWeight: FontWeight.bold, color: textPrim, fontSize: 18),
        ),
        content: Text(
          "Are you sure you want to reject this safety report? Rejected reports are flagged as invalid and will not impact highway statuses.",
          style: TextStyle(color: isLight ? const Color(0xFF475569) : AppColors.textSecondary, fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text("Cancel", style: TextStyle(color: isLight ? const Color(0xFF475569) : AppColors.textSecondary, fontWeight: FontWeight.bold)),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await reportController.rejectReport(reportId: report.id);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFEF4444),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            ),
            child: const Text("Reject", style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final reportController = context.watch<ReportController>();
    final roadController = context.watch<RoadController>();
    final isLight = Theme.of(context).brightness == Brightness.light;

    // Premium UI design tokens
    final bgCol = isLight ? const Color(0xFFF8FAFC) : AppColors.background;
    final textPrim = isLight ? const Color(0xFF0F172A) : AppColors.textPrimary;
    final textSec = isLight ? const Color(0xFF475569) : AppColors.textSecondary;
    final textMut = isLight ? const Color(0xFF94A3B8) : AppColors.textMuted;
    final cardBg = isLight ? Colors.white : AppColors.surface;
    final borderCol = isLight ? const Color(0xFFE2E8F0) : AppColors.border;

    final pendingReports = reportController.reports.where((r) => r.status == 'pending').toList();
    final verifiedReports = reportController.reports.where((r) => r.status == 'verified').toList();
    final rejectedReports = reportController.reports.where((r) => r.status == 'rejected').toList();

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
          "Admin Verification Control",
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w800,
            color: textPrim,
            letterSpacing: -0.5,
          ),
        ),
        bottom: TabBar(
          controller: _tabController,
          labelColor: const Color(0xFF0284C7),
          unselectedLabelColor: textSec,
          indicatorColor: const Color(0xFF0284C7),
          tabs: [
            Tab(text: "Pending (${pendingReports.length})"),
            Tab(text: "Verified (${verifiedReports.length})"),
            Tab(text: "Rejected (${rejectedReports.length})"),
          ],
        ),
      ),
      body: SafeArea(
        child: reportController.isLoading
            ? const Center(child: CircularProgressIndicator())
            : TabBarView(
                controller: _tabController,
                children: [
                  _buildReportsList(pendingReports, "pending", reportController, roadController, isLight, textPrim, textSec, textMut, cardBg, borderCol),
                  _buildReportsList(verifiedReports, "verified", reportController, roadController, isLight, textPrim, textSec, textMut, cardBg, borderCol),
                  _buildReportsList(rejectedReports, "rejected", reportController, roadController, isLight, textPrim, textSec, textMut, cardBg, borderCol),
                ],
              ),
      ),
    );
  }

  Widget _buildReportsList(
    List<ReportModel> list,
    String type,
    ReportController reportController,
    RoadController roadController,
    bool isLight,
    Color textPrim,
    Color textSec,
    Color textMut,
    Color cardBg,
    Color borderCol,
  ) {
    if (list.isEmpty) {
      return RefreshIndicator(
        onRefresh: () => reportController.loadReports(),
        child: ListView(
          children: [
            SizedBox(
              height: MediaQuery.of(context).size.height * 0.6,
              child: EmptyState(
                title: "No $type Reports",
                description: "Everything looks tidy in this section.",
                icon: Icons.safety_check_rounded,
                onAction: () => reportController.loadReports(),
                actionText: "Reload Reports",
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () => reportController.loadReports(),
      child: ListView.builder(
        padding: const EdgeInsets.all(20.0),
        itemCount: list.length,
        itemBuilder: (context, index) {
          final report = list[index];
          final severityColor = report.severity == 'High'
              ? const Color(0xFFEF4444)
              : report.severity == 'Medium'
                  ? const Color(0xFFF59E0B)
                  : const Color(0xFF10B981);

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
                  // Reporter Profile Info & time
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 18,
                        backgroundImage: NetworkImage(report.userAvatar),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              report.userName,
                              style: TextStyle(fontWeight: FontWeight.bold, color: textPrim, fontSize: 13),
                            ),
                            Text(
                              AppHelpers.formatTimeAgo(report.createdAt),
                              style: TextStyle(color: textMut, fontSize: 11),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: severityColor.withOpacity(0.08),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          report.severity.toUpperCase(),
                          style: TextStyle(fontSize: 9, fontWeight: FontWeight.w900, color: severityColor),
                        ),
                      ),
                    ],
                  ),
                  Divider(color: borderCol, height: 24),

                  // Affected Road details
                  Text(
                    "ROUTE: ${report.roadName}",
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: const Color(0xFF0284C7)),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    "Hazard: ${report.hazardType}",
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: textPrim),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    report.description,
                    style: TextStyle(fontSize: 13, color: textSec, height: 1.4),
                  ),

                  // Image attachment if available
                  if (report.imageUrl != null && report.imageUrl!.isNotEmpty) ...[
                    const SizedBox(height: 14),
                    Container(
                      height: 130,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        image: DecorationImage(
                          image: NetworkImage(report.imageUrl!),
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                  ],

                  // Action Buttons for PENDING tab
                  if (type == "pending") ...[
                    const SizedBox(height: 18),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            style: OutlinedButton.styleFrom(
                              foregroundColor: const Color(0xFFEF4444),
                              side: const BorderSide(color: Color(0xFFEF4444), width: 1.2),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              padding: const EdgeInsets.symmetric(vertical: 12),
                            ),
                            onPressed: () => _showRejectDialog(context, report, reportController),
                            icon: const Icon(Icons.close_rounded, size: 16),
                            label: const Text("Reject", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF10B981),
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              elevation: 0,
                            ),
                            onPressed: () => _showVerifyDialog(context, report, reportController, roadController),
                            icon: const Icon(Icons.check_rounded, size: 16),
                            label: const Text("Verify & Action", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
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
    );
  }
}
