import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/services/notification_service.dart';
import '../../auth/controller/auth_controller.dart';
import '../../reports/controller/report_controller.dart';
import '../../emergency/controller/emergency_controller.dart';
import '../../../routes/route_names.dart';
import '../../reports/view/admin_reports_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AuthController>().loadUserStats();
    });
  }

  // Local state for toggles and settings
  bool _pushNotifications = true;
  String _selectedLanguage = "English";

  // Privacy preferences states
  bool _shareLocation = true;
  bool _anonymousReports = false;
  bool _publicVisibility = true;

  // Language Dialog
  void _showLanguageDialog(BuildContext context, bool isLight) {
    final textPrim = isLight ? const Color(0xFF0F172A) : AppColors.textPrimary;
    final cardBg = isLight ? Colors.white : AppColors.surface;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: cardBg,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          "Select Language",
          style: TextStyle(fontWeight: FontWeight.bold, color: textPrim, fontSize: 18),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: ["English", "Urdu (اردو)", "Balti / Shina"].map((lang) {
            final isSelected = _selectedLanguage == lang.split(' ')[0];
            return ListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(
                lang,
                style: TextStyle(
                  color: textPrim,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                ),
              ),
              trailing: isSelected
                  ? const Icon(Icons.check_circle_rounded, color: Color(0xFF0284C7))
                  : null,
              onTap: () {
                setState(() {
                  _selectedLanguage = lang.split(' ')[0];
                });
                Navigator.pop(ctx);
                NotificationService.instance.showSuccessSnackbar(
                  "Language updated to $_selectedLanguage.",
                );
              },
            );
          }).toList(),
        ),
      ),
    );
  }

  // Emergency Contacts Modal Bottom Sheet
  void _showEmergencyContactsSheet(BuildContext context, bool isLight) {
    final emergencyController = context.read<EmergencyController>();
    final textPrim = isLight ? const Color(0xFF0F172A) : AppColors.textPrimary;
    final textSec = isLight ? const Color(0xFF475569) : AppColors.textSecondary;
    final cardBg = isLight ? Colors.white : AppColors.surface;
    final borderCol = isLight ? const Color(0xFFF1F5F9) : AppColors.border;

    showModalBottomSheet(
      context: context,
      backgroundColor: cardBg,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(
                  child: Container(
                    width: 38,
                    height: 4,
                    decoration: BoxDecoration(
                      color: isLight ? const Color(0xFFE2E8F0) : AppColors.border,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  "Mountain Patrol Contacts",
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: textPrim,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  "Direct hotline calls to search & rescue command centers",
                  style: TextStyle(fontSize: 13, color: textSec),
                ),
                const SizedBox(height: 16),
                Flexible(
                  child: ListView.separated(
                    shrinkWrap: true,
                    itemCount: emergencyController.contacts.take(4).length,
                    separatorBuilder: (_, __) => Divider(color: borderCol, height: 1),
                    itemBuilder: (context, index) {
                      final contact = emergencyController.contacts[index];
                      return ListTile(
                        contentPadding: const EdgeInsets.symmetric(vertical: 4),
                        leading: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: const Color(0xFFEF4444).withOpacity(0.08),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(contact.icon, color: const Color(0xFFEF4444), size: 18),
                        ),
                        title: Text(
                          contact.name,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                            color: textPrim,
                          ),
                        ),
                        subtitle: Text(
                          "${contact.location} • ${contact.phone}",
                          style: TextStyle(fontSize: 12, color: textSec),
                        ),
                        trailing: IconButton(
                          icon: const Icon(Icons.phone_forwarded_rounded, color: Color(0xFF0284C7), size: 18),
                          onPressed: () {
                            Navigator.pop(ctx);
                            emergencyController.makeCall(contact.phone);
                          },
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // Privacy Settings Modal Bottom Sheet
  void _showPrivacySettingsSheet(BuildContext context, bool isLight) {
    final textPrim = isLight ? const Color(0xFF0F172A) : AppColors.textPrimary;
    final textSec = isLight ? const Color(0xFF475569) : AppColors.textSecondary;
    final cardBg = isLight ? Colors.white : AppColors.surface;

    showModalBottomSheet(
      context: context,
      backgroundColor: cardBg,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Center(
                      child: Container(
                        width: 38,
                        height: 4,
                        decoration: BoxDecoration(
                          color: isLight ? const Color(0xFFE2E8F0) : AppColors.border,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      "Privacy Preferences",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: textPrim,
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      "Manage your safety tracking and dispatch details",
                      style: TextStyle(fontSize: 13, color: textSec),
                    ),
                    const SizedBox(height: 16),
                    
                    // Share Location Toggle
                    SwitchListTile.adaptive(
                      contentPadding: EdgeInsets.zero,
                      title: Text(
                        "Live Dispatch Tracking",
                        style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: textPrim),
                      ),
                      subtitle: Text(
                        "Share live GPS location with rescuers during active SOS triggers.",
                        style: TextStyle(fontSize: 12, color: textSec),
                      ),
                      value: _shareLocation,
                      activeColor: const Color(0xFF0284C7),
                      onChanged: (val) {
                        setModalState(() => _shareLocation = val);
                        setState(() => _shareLocation = val);
                        NotificationService.instance.showSuccessSnackbar(
                          val ? "Emergency tracking enabled." : "Emergency tracking disabled.",
                        );
                      },
                    ),
                    const Divider(height: 16),

                    // Anonymous Toggle
                    SwitchListTile.adaptive(
                      contentPadding: EdgeInsets.zero,
                      title: Text(
                        "Anonymous Reporting",
                        style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: textPrim),
                      ),
                      subtitle: Text(
                        "Hide your name on community landslide or road blockage alerts.",
                        style: TextStyle(fontSize: 12, color: textSec),
                      ),
                      value: _anonymousReports,
                      activeColor: const Color(0xFF0284C7),
                      onChanged: (val) {
                        setModalState(() => _anonymousReports = val);
                        setState(() => _anonymousReports = val);
                        NotificationService.instance.showSuccessSnackbar(
                          val ? "Reports set to anonymous." : "Reports linked to profile.",
                        );
                      },
                    ),
                    const Divider(height: 16),

                    // Public Profile Visibility
                    SwitchListTile.adaptive(
                      contentPadding: EdgeInsets.zero,
                      title: Text(
                        "Guide Directory Visibility",
                        style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: textPrim),
                      ),
                      subtitle: Text(
                        "Allow certified high-altitude guides to see your route history.",
                        style: TextStyle(fontSize: 12, color: textSec),
                      ),
                      value: _publicVisibility,
                      activeColor: const Color(0xFF0284C7),
                      onChanged: (val) {
                        setModalState(() => _publicVisibility = val);
                        setState(() => _publicVisibility = val);
                        NotificationService.instance.showSuccessSnackbar(
                          val ? "Profile visible to rescue guides." : "Profile set to private.",
                        );
                      },
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final authController = context.watch<AuthController>();
    final reportController = context.watch<ReportController>();
    final emergencyController = context.watch<EmergencyController>();
    final user = authController.currentUser;
    final isLight = Theme.of(context).brightness == Brightness.light;

    if (user == null) {
      return const Scaffold(
        body: Center(child: Text("User session not found.")),
      );
    }

    // Adaptive token styles (optimized for high readability and mountainous usage)
    final bgCol = isLight ? const Color(0xFFF8FAFC) : AppColors.background;
    final textPrim = isLight ? const Color(0xFF0F172A) : AppColors.textPrimary;
    final textSec = isLight ? const Color(0xFF475569) : AppColors.textSecondary;
    final textMut = isLight ? const Color(0xFF94A3B8) : AppColors.textMuted;
    final cardBg = isLight ? Colors.white : AppColors.surface;
    final borderCol = isLight ? const Color(0xFFF1F5F9) : AppColors.border;

    // SOS Requests: Dynamic check if currently triggered, else standard mock
    final sosCount = authController.emergenciesCount > 0 
        ? authController.emergenciesCount 
        : (emergencyController.sosTriggered ? 3 : 2);

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
          "GB SafeRoute",
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
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // 1. Top Identity Section (User Avatar, Name, Email/Phone)
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: cardBg,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: borderCol, width: 1.0),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(isLight ? 0.02 : 0.08),
                      blurRadius: 16,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    Stack(
                      alignment: Alignment.bottomRight,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(color: const Color(0xFF0284C7), width: 3),
                          ),
                          child: CircleAvatar(
                            radius: 46,
                            backgroundColor: const Color(0xFF0284C7).withOpacity(0.1),
                            backgroundImage: NetworkImage(user.avatarUrl),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: const Color(0xFF0284C7),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: cardBg, width: 2),
                          ),
                          child: const Text(
                            "ACTIVE",
                            style: TextStyle(
                              fontSize: 8,
                              fontWeight: FontWeight.w900,
                              color: Colors.white,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      user.fullName,
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: textPrim,
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      user.badge,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF0284C7),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Divider(color: borderCol, height: 1),
                    const SizedBox(height: 12),
                    
                    // Email Info Row
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.email_outlined, size: 16, color: Color(0xFF0284C7)),
                        const SizedBox(width: 8),
                        Text(
                          user.email,
                          style: TextStyle(fontSize: 13, color: textSec),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    
                    // Phone Info Row
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.phone_iphone_rounded, size: 16, color: Color(0xFF0284C7)),
                        const SizedBox(width: 8),
                        Text(
                          user.phoneNumber,
                          style: TextStyle(fontSize: 13, color: textSec, fontWeight: FontWeight.w500),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // 2. Stats Section Cards
              Row(
                children: [
                  // Total Reports Sent Card
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: cardBg,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: borderCol, width: 1.0),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(isLight ? 0.02 : 0.08),
                            blurRadius: 16,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                "Total Reports",
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: textSec,
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.all(4),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFF59E0B).withOpacity(0.08),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(Icons.campaign_rounded, color: Color(0xFFF59E0B), size: 16),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            "${user.contributionsCount}",
                            style: TextStyle(
                              fontSize: 26,
                              fontWeight: FontWeight.w900,
                              color: textPrim,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            "Safety contributions",
                            style: TextStyle(fontSize: 10, color: textMut),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),

                  // Emergency SOS Requests Card
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: cardBg,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: borderCol, width: 1.0),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(isLight ? 0.02 : 0.08),
                            blurRadius: 16,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                "SOS Beacons",
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: textSec,
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.all(4),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFEF4444).withOpacity(0.08),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(Icons.sensors_rounded, color: Color(0xFFEF4444), size: 16),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            "$sosCount",
                            style: TextStyle(
                              fontSize: 26,
                              fontWeight: FontWeight.w900,
                              color: textPrim,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            "Total requests made",
                            style: TextStyle(fontSize: 10, color: textMut),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // 3. Settings List
              Text(
                "PREFERENCES & CONTROL",
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w900,
                  color: textMut,
                  letterSpacing: 1.0,
                ),
              ),
              const SizedBox(height: 10),
              Container(
                decoration: BoxDecoration(
                  color: cardBg,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: borderCol, width: 1.0),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(isLight ? 0.02 : 0.08),
                      blurRadius: 16,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    // Notifications Row
                    ListTile(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
                      leading: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: const Color(0xFF0284C7).withOpacity(0.08),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.notifications_active_outlined, color: Color(0xFF0284C7), size: 18),
                      ),
                      title: Text(
                        "Safety Notifications",
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: textPrim),
                      ),
                      trailing: Switch.adaptive(
                        value: _pushNotifications,
                        onChanged: (val) {
                          setState(() {
                            _pushNotifications = val;
                          });
                          NotificationService.instance.showSuccessSnackbar(
                            val ? "Road hazard alerts activated." : "Alerts muted. Stay cautious!",
                          );
                        },
                        activeColor: const Color(0xFF0284C7),
                      ),
                    ),
                    Divider(color: borderCol, height: 1, thickness: 1),

                    // Language Row
                    ListTile(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
                      leading: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: const Color(0xFF0284C7).withOpacity(0.08),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.translate_rounded, color: Color(0xFF0284C7), size: 18),
                      ),
                      title: Text(
                        "Language Selection",
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
                      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
                      leading: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: const Color(0xFF0284C7).withOpacity(0.08),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.emergency_outlined, color: Color(0xFF0284C7), size: 18),
                      ),
                      title: Text(
                        "Emergency Patrol Contacts",
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: textPrim),
                      ),
                      trailing: Icon(Icons.chevron_right_rounded, color: textMut, size: 18),
                      onTap: () => _showEmergencyContactsSheet(context, isLight),
                    ),
                    Divider(color: borderCol, height: 1, thickness: 1),

                    // Privacy Settings Row
                    ListTile(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
                      leading: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: const Color(0xFF0284C7).withOpacity(0.08),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.shield_outlined, color: Color(0xFF0284C7), size: 18),
                      ),
                      title: Text(
                        "Privacy & Tracking Settings",
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: textPrim),
                      ),
                      trailing: Icon(Icons.chevron_right_rounded, color: textMut, size: 18),
                      onTap: () => _showPrivacySettingsSheet(context, isLight),
                    ),
                    Divider(color: borderCol, height: 1, thickness: 1),

                    // My SOS History Row
                    ListTile(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
                      leading: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: const Color(0xFFEF4444).withOpacity(0.08),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.history_toggle_off_rounded, color: Color(0xFFEF4444), size: 18),
                      ),
                      title: Text(
                        "My SOS History",
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: textPrim),
                      ),
                      subtitle: const Text(
                        "View your historical satellite distress beacons",
                        style: TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                      ),
                      trailing: Icon(Icons.chevron_right_rounded, color: textMut, size: 18),
                      onTap: () {
                        Navigator.pushNamed(context, RouteNames.sosHistory);
                      },
                    ),
                    Divider(color: borderCol, height: 1, thickness: 1),

                    // Admin Verification Portal Row
                    ListTile(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
                      leading: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: const Color(0xFF10B981).withOpacity(0.08),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.admin_panel_settings_outlined, color: Color(0xFF10B981), size: 18),
                      ),
                      title: Text(
                        "Admin Verification Portal",
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: textPrim),
                      ),
                      subtitle: const Text(
                        "Review hazard alerts and change highway status",
                        style: TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                      ),
                      trailing: Icon(Icons.chevron_right_rounded, color: textMut, size: 18),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const AdminReportsScreen(),
                          ),
                        );
                      },
                    ),
                    Divider(color: borderCol, height: 1, thickness: 1),

                    // Admin SOS Dashboard Row
                    ListTile(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
                      leading: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: const Color(0xFFEF4444).withOpacity(0.08),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.admin_panel_settings_outlined, color: Color(0xFFEF4444), size: 18),
                      ),
                      title: Text(
                        "Admin SOS Dashboard",
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: textPrim),
                      ),
                      subtitle: const Text(
                        "Monitor real-time active valley SOS alerts",
                        style: TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                      ),
                      trailing: Icon(Icons.chevron_right_rounded, color: textMut, size: 18),
                      onTap: () {
                        Navigator.pushNamed(context, RouteNames.sosAdmin);
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 36),

              // 4. Logout Button (highlighted but minimal)
              ElevatedButton(
                onPressed: () {
                  // Standard confirm logout dialog
                  showDialog(
                    context: context,
                    builder: (ctx) => AlertDialog(
                      backgroundColor: cardBg,
                      surfaceTintColor: Colors.transparent,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                      title: Text(
                        "Sign Out",
                        style: TextStyle(fontWeight: FontWeight.bold, color: textPrim, fontSize: 18),
                      ),
                      content: Text(
                        "Are you sure you want to log out from GB SafeRoute? Direct disaster alerts will be inactive.",
                        style: TextStyle(color: textSec, fontSize: 14),
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(ctx),
                          child: Text("Cancel", style: TextStyle(color: textSec, fontWeight: FontWeight.bold)),
                        ),
                        ElevatedButton(
                          onPressed: () {
                            Navigator.pop(ctx); // Close dialog
                            Navigator.pop(context); // Go back from profile
                            authController.logout();
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFEF4444),
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                          ),
                          child: const Text("Log Out", style: TextStyle(fontWeight: FontWeight.bold)),
                        ),
                      ],
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFEF4444).withOpacity(0.06),
                  foregroundColor: const Color(0xFFEF4444),
                  elevation: 0,
                  shadowColor: Colors.transparent,
                  side: BorderSide(color: const Color(0xFFEF4444).withOpacity(0.12), width: 1.0),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: const [
                    Icon(Icons.logout_rounded, color: Color(0xFFEF4444), size: 18),
                    SizedBox(width: 8),
                    Text(
                      "Log Out Account",
                      style: TextStyle(
                        color: Color(0xFFEF4444),
                        fontWeight: FontWeight.w800,
                        fontSize: 14,
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
