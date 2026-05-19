import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/services/notification_service.dart';
import '../../auth/controller/auth_controller.dart';
import '../../reports/controller/report_controller.dart';
import '../../../routes/route_names.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  bool _pushNotifications = true;
  String _selectedLanguage = "English";

  void _showLanguageDialog(BuildContext context, bool isLight) {
    final textPrim = isLight ? const Color(0xFF0F172A) : AppColors.textPrimary;
    final textSec = isLight ? const Color(0xFF475569) : AppColors.textSecondary;
    final cardBg = isLight ? Colors.white : AppColors.surface;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: cardBg,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          "Select Language",
          style: TextStyle(fontWeight: FontWeight.bold, color: textPrim),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: ["English", "Urdu (اردو)", "Balti / Shina"].map((lang) {
            final isSelected = _selectedLanguage.startsWith(lang.split(' ')[0]);
            return ListTile(
              title: Text(lang, style: TextStyle(color: textPrim, fontWeight: isSelected ? FontWeight.bold : FontWeight.normal)),
              trailing: isSelected ? const Icon(Icons.check_circle_rounded, color: Color(0xFF0284C7)) : null,
              onTap: () {
                setState(() {
                  _selectedLanguage = lang.split(' ')[0];
                });
                Navigator.pop(ctx);
                NotificationService.instance.showSuccessSnackbar("Language updated to $_selectedLanguage.");
              },
            );
          }).toList(),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final authController = context.watch<AuthController>();
    final reportController = context.watch<ReportController>();
    final user = authController.currentUser;
    final isLight = Theme.of(context).brightness == Brightness.light;

    if (user == null) {
      return const Scaffold(
        body: Center(child: Text("User session not found.")),
      );
    }

    // Dynamic stats
    final reportsCount = user.contributionsCount;
    // Alerts received can be estimated dynamically
    final alertsCount = (reportController.reports.length * 6) + 12;

    // Adaptive tokens
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
        title: Text(
          "My Profile",
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w800,
            color: textPrim,
            letterSpacing: -0.5,
          ),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // 1. User Avatar and Name at Top
              Center(
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: const Color(0xFF0284C7), width: 3),
                      ),
                      child: CircleAvatar(
                        radius: 54,
                        backgroundImage: NetworkImage(user.avatarUrl),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      user.fullName,
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: textPrim,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFF0284C7).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        user.badge.toUpperCase(),
                        style: const TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF0284C7),
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 28),

              // 2. Stats Section
              Text(
                "Stats Section",
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: textMut,
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  // Reports Stat
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: cardBg,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: borderCol, width: 1.2),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(isLight ? 0.03 : 0.1),
                            blurRadius: 8,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: const [
                              Text(
                                "Reports Made",
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF64748B),
                                ),
                              ),
                              Icon(Icons.report_problem_rounded, color: Color(0xFFF59E0B), size: 16),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Text(
                            "$reportsCount",
                            style: TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.w900,
                              color: textPrim,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),

                  // Alerts Received Stat
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: cardBg,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: borderCol, width: 1.2),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(isLight ? 0.03 : 0.1),
                            blurRadius: 8,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: const [
                              Text(
                                "Alerts Received",
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF64748B),
                                ),
                              ),
                              Icon(Icons.notifications_active_rounded, color: Color(0xFF0284C7), size: 16),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Text(
                            "$alertsCount",
                            style: TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.w900,
                              color: textPrim,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 28),

              // 3. Settings List
              Text(
                "Settings List",
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: textMut,
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 12),
              Container(
                decoration: BoxDecoration(
                  color: cardBg,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: borderCol, width: 1.2),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(isLight ? 0.03 : 0.1),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    // Notifications Row
                    ListTile(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                      leading: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: const Color(0xFF0284C7).withOpacity(0.08),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.notifications_outlined, color: Color(0xFF0284C7), size: 20),
                      ),
                      title: Text(
                        "Notifications",
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: textPrim),
                      ),
                      trailing: Switch(
                        value: _pushNotifications,
                        onChanged: (val) {
                          setState(() {
                            _pushNotifications = val;
                          });
                          NotificationService.instance.showSuccessSnackbar(
                            val ? "Notifications activated." : "Notifications muted.",
                          );
                        },
                        activeColor: const Color(0xFF0284C7),
                      ),
                    ),
                    Divider(color: borderCol, height: 1, thickness: 1),

                    // Language Row
                    ListTile(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                      leading: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: const Color(0xFF0284C7).withOpacity(0.08),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.language_outlined, color: Color(0xFF0284C7), size: 20),
                      ),
                      title: Text(
                        "Language",
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: textPrim),
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            _selectedLanguage,
                            style: TextStyle(color: textSec, fontSize: 13, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(width: 4),
                          Icon(Icons.chevron_right_rounded, color: textMut, size: 18),
                        ],
                      ),
                      onTap: () => _showLanguageDialog(context, isLight),
                    ),
                    Divider(color: borderCol, height: 1, thickness: 1),

                    // Emergency Contacts Row
                    ListTile(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                      leading: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: const Color(0xFF0284C7).withOpacity(0.08),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.contact_phone_outlined, color: Color(0xFF0284C7), size: 20),
                      ),
                      title: Text(
                        "Emergency Contacts",
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: textPrim),
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            "1122 & Highway",
                            style: TextStyle(color: textSec, fontSize: 13, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(width: 4),
                          Icon(Icons.chevron_right_rounded, color: textMut, size: 18),
                        ],
                      ),
                      onTap: () {
                        Navigator.pop(context);
                        NotificationService.instance.showSuccessSnackbar("Emergency contacts are active. To make SOS dials, select the Emergency SOS tab.");
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 36),

              // 4. Logout Button
              OutlinedButton(
                onPressed: () {
                  Navigator.pop(context);
                  authController.logout();
                },
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Color(0xFFEF4444), width: 1.5),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: const [
                    Icon(Icons.logout_rounded, color: Color(0xFFEF4444), size: 18),
                    SizedBox(width: 8),
                    Text(
                      "Log Out",
                      style: TextStyle(
                        color: Color(0xFFEF4444),
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
