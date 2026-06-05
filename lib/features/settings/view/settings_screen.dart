import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/services/notification_service.dart';
import '../../auth/controller/auth_controller.dart';
import '../controller/settings_controller.dart';
import '../../../routes/route_names.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  void _showEditProfileDialog(BuildContext context, AuthController authController, bool isDark) {
    final user = authController.currentUser;
    if (user == null) return;

    final nameController = TextEditingController(text: user.fullName);
    final emailController = TextEditingController(text: user.email);
    final phoneController = TextEditingController(text: user.phoneNumber);

    final textPrim = isDark ? AppColors.textPrimary : const Color(0xFF0F172A);
    final cardBg = isDark ? AppColors.surfaceElevated : Colors.white;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        backgroundColor: cardBg,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Text(
          "Edit Profile Info",
          style: TextStyle(fontWeight: FontWeight.bold, color: textPrim, fontSize: 18),
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                style: TextStyle(color: textPrim),
                decoration: const InputDecoration(
                  labelText: "Full Name",
                  prefixIcon: Icon(Icons.person_rounded),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: emailController,
                style: TextStyle(color: textPrim),
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(
                  labelText: "Email Address",
                  prefixIcon: Icon(Icons.email_rounded),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: phoneController,
                style: TextStyle(color: textPrim),
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(
                  labelText: "Phone Number",
                  prefixIcon: Icon(Icons.phone_rounded),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text("Cancel", style: TextStyle(color: isDark ? Colors.white70 : Colors.black54)),
          ),
          ElevatedButton(
            onPressed: () async {
              final navigator = Navigator.of(ctx);
              final success = await authController.updateProfile(
                fullName: nameController.text.trim(),
                email: emailController.text.trim(),
                phoneNumber: phoneController.text.trim(),
              );
              if (success && ctx.mounted) {
                navigator.pop();
              }
            },
            child: const Text("Save Changes"),
          ),
        ],
      ),
    );
  }

  void _showLanguageDialog(BuildContext context, SettingsController settingsController, bool isDark) {
    final textPrim = isDark ? AppColors.textPrimary : const Color(0xFF0F172A);
    final cardBg = isDark ? AppColors.surfaceElevated : Colors.white;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: cardBg,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          "Select App Language",
          style: TextStyle(fontWeight: FontWeight.bold, color: textPrim, fontSize: 18),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: ["English", "Urdu"].map((lang) {
            final isSelected = settingsController.selectedLanguage == lang;
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
                settingsController.setLanguage(lang);
                Navigator.pop(ctx);
                NotificationService.instance.showSuccessSnackbar("Language updated to $lang.");
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
    final settingsController = context.watch<SettingsController>();
    final user = authController.currentUser;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (user == null) {
      return const Scaffold(
        body: Center(child: Text("User session not found.")),
      );
    }

    // Modern Material 3 harmonized tokens
    final bgCol = isDark ? AppColors.background : const Color(0xFFF8FAFC);
    final textPrim = isDark ? AppColors.textPrimary : const Color(0xFF0F172A);
    final textSec = isDark ? AppColors.textSecondary : const Color(0xFF475569);
    final textMut = isDark ? AppColors.textMuted : const Color(0xFF94A3B8);
    final cardBg = isDark ? AppColors.surface : Colors.white;
    final borderCol = isDark ? AppColors.border : const Color(0xFFF1F5F9);

    return Scaffold(
      backgroundColor: bgCol,
      appBar: AppBar(
        backgroundColor: isDark ? AppColors.surface : Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded, color: textPrim, size: 18),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          "Settings & Controls",
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
          padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // 1. Profile Section Card
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: cardBg,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: borderCol, width: 1.0),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(isDark ? 0.08 : 0.02),
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
                          child: Text(
                            user.badge.toUpperCase(),
                            style: const TextStyle(
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
                      user.email,
                      style: TextStyle(fontSize: 13, color: textSec),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      user.phoneNumber,
                      style: TextStyle(fontSize: 13, color: textSec, fontWeight: FontWeight.w500),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton.icon(
                      onPressed: () => _showEditProfileDialog(context, authController, isDark),
                      icon: const Icon(Icons.edit_rounded, size: 16),
                      label: const Text("Edit Profile Info", style: TextStyle(fontSize: 13)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF0284C7).withOpacity(0.08),
                        foregroundColor: const Color(0xFF0284C7),
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // 2. Safety Options Section
              _buildSectionHeader("SAFETY"),
              Container(
                margin: const EdgeInsets.only(top: 8, bottom: 20),
                decoration: BoxDecoration(
                  color: cardBg,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: borderCol, width: 1.0),
                ),
                child: Column(
                  children: [
                    ListTile(
                      leading: _buildLeadingIcon(Icons.contact_phone_rounded, Colors.redAccent, isDark),
                      title: Text("Emergency Contacts", style: TextStyle(fontWeight: FontWeight.bold, color: textPrim)),
                      subtitle: Text("Manage your personal safety contacts", style: TextStyle(color: textSec, fontSize: 12)),
                      trailing: Icon(Icons.chevron_right_rounded, color: textMut),
                      onTap: () {
                        Navigator.pushNamed(context, RouteNames.emergencyContacts);
                      },
                    ),
                    Divider(color: borderCol, height: 1),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              _buildLeadingIcon(Icons.sos_rounded, Colors.red, isDark),
                              const SizedBox(width: 12),
                              Text("SOS Preferences", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: textPrim)),
                            ],
                          ),
                          const SizedBox(height: 8),
                          SwitchListTile.adaptive(
                            contentPadding: EdgeInsets.zero,
                            title: Text("Auto Call SOS", style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: textPrim)),
                            subtitle: Text("Automatically triggers telephone call during active SOS", style: TextStyle(fontSize: 11, color: textSec)),
                            value: settingsController.autoCallSos,
                            activeColor: const Color(0xFF0284C7),
                            onChanged: (val) => settingsController.toggleAutoCallSos(val),
                          ),
                          SwitchListTile.adaptive(
                            contentPadding: EdgeInsets.zero,
                            title: Text("Auto SMS SOS", style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: textPrim)),
                            subtitle: Text("Dispatches silent SMS distress beacons to patrol centers", style: TextStyle(fontSize: 11, color: textSec)),
                            value: settingsController.autoSmsSos,
                            activeColor: const Color(0xFF0284C7),
                            onChanged: (val) => settingsController.toggleAutoSmsSos(val),
                          ),
                          SwitchListTile.adaptive(
                            contentPadding: EdgeInsets.zero,
                            title: Text("Share Live Location During SOS", style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: textPrim)),
                            subtitle: Text("Allows rescuers to track you in real-time until cancelled", style: TextStyle(fontSize: 11, color: textSec)),
                            value: settingsController.shareLiveLocation,
                            activeColor: const Color(0xFF0284C7),
                            onChanged: (val) => settingsController.toggleShareLiveLocation(val),
                          ),
                          const SizedBox(height: 8),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text("SOS Countdown Timer", style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: textPrim)),
                              DropdownButton<int>(
                                value: settingsController.sosCountdownTimer,
                                dropdownColor: cardBg,
                                style: TextStyle(color: textPrim, fontWeight: FontWeight.bold, fontSize: 13),
                                underline: const SizedBox.shrink(),
                                icon: Icon(Icons.arrow_drop_down, color: textMut),
                                items: [5, 10, 15].map((seconds) {
                                  return DropdownMenuItem<int>(
                                    value: seconds,
                                    child: Text("${seconds}s"),
                                  );
                                }).toList(),
                                onChanged: (val) {
                                  if (val != null) {
                                    settingsController.setSosCountdownTimer(val);
                                  }
                                },
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // 3. Notifications Section
              _buildSectionHeader("NOTIFICATIONS"),
              Container(
                margin: const EdgeInsets.only(top: 8, bottom: 20),
                decoration: BoxDecoration(
                  color: cardBg,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: borderCol, width: 1.0),
                ),
                child: Column(
                  children: [
                    SwitchListTile.adaptive(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                      title: Text("Push Notifications", style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: textPrim)),
                      subtitle: Text("Toggle master settings for push broadcasts", style: TextStyle(fontSize: 12, color: textSec)),
                      value: settingsController.pushNotifications,
                      activeColor: const Color(0xFF0284C7),
                      onChanged: (val) => settingsController.togglePushNotifications(val),
                    ),
                    Divider(color: borderCol, height: 1),
                    SwitchListTile.adaptive(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                      title: Text("Road Closure Alerts", style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: textPrim)),
                      value: settingsController.roadClosureAlerts,
                      activeColor: const Color(0xFF0284C7),
                      onChanged: settingsController.pushNotifications
                          ? (val) => settingsController.toggleRoadClosureAlerts(val)
                          : null,
                    ),
                    Divider(color: borderCol, height: 1),
                    SwitchListTile.adaptive(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                      title: Text("Weather Alerts", style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: textPrim)),
                      value: settingsController.weatherAlerts,
                      activeColor: const Color(0xFF0284C7),
                      onChanged: settingsController.pushNotifications
                          ? (val) => settingsController.toggleWeatherAlerts(val)
                          : null,
                    ),
                    Divider(color: borderCol, height: 1),
                    SwitchListTile.adaptive(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                      title: Text("Emergency Alerts", style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: textPrim)),
                      value: settingsController.emergencyAlerts,
                      activeColor: const Color(0xFF0284C7),
                      onChanged: settingsController.pushNotifications
                          ? (val) => settingsController.toggleEmergencyAlerts(val)
                          : null,
                    ),
                  ],
                ),
              ),

              // 4. Appearance Section
              _buildSectionHeader("APPEARANCE"),
              Container(
                margin: const EdgeInsets.only(top: 8, bottom: 20),
                decoration: BoxDecoration(
                  color: cardBg,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: borderCol, width: 1.0),
                ),
                child: SwitchListTile.adaptive(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                  title: Text("Dark Mode", style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: textPrim)),
                  subtitle: Text("Toggle dark or light theme interface", style: TextStyle(fontSize: 12, color: textSec)),
                  value: settingsController.isDarkMode,
                  activeColor: const Color(0xFF0284C7),
                  onChanged: (val) => settingsController.toggleDarkMode(val),
                ),
              ),

              // 5. Language Section
              _buildSectionHeader("LANGUAGE"),
              Container(
                margin: const EdgeInsets.only(top: 8, bottom: 20),
                decoration: BoxDecoration(
                  color: cardBg,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: borderCol, width: 1.0),
                ),
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  leading: _buildLeadingIcon(Icons.language_rounded, Colors.teal, isDark),
                  title: Text("Language Selector", style: TextStyle(fontWeight: FontWeight.bold, color: textPrim)),
                  subtitle: Text("Choose your preferred native translation", style: TextStyle(color: textSec, fontSize: 12)),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(settingsController.selectedLanguage, style: TextStyle(color: textSec, fontSize: 13, fontWeight: FontWeight.bold)),
                      const SizedBox(width: 4),
                      Icon(Icons.chevron_right_rounded, color: textMut),
                    ],
                  ),
                  onTap: () => _showLanguageDialog(context, settingsController, isDark),
                ),
              ),

              // 6. Support Section
              _buildSectionHeader("SUPPORT"),
              Container(
                margin: const EdgeInsets.only(top: 8, bottom: 20),
                decoration: BoxDecoration(
                  color: cardBg,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: borderCol, width: 1.0),
                ),
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  leading: _buildLeadingIcon(Icons.help_outline_rounded, Colors.purple, isDark),
                  title: Text("Help & Support Screen", style: TextStyle(fontWeight: FontWeight.bold, color: textPrim)),
                  subtitle: Text("Read FAQs or contact our technical support", style: TextStyle(color: textSec, fontSize: 12)),
                  trailing: Icon(Icons.chevron_right_rounded, color: textMut),
                  onTap: () {
                    Navigator.pushNamed(context, RouteNames.helpSupport);
                  },
                ),
              ),

              // 7. Account Section
              _buildSectionHeader("ACCOUNT"),
              const SizedBox(height: 8),
              ElevatedButton(
                onPressed: () {
                  showDialog(
                    context: context,
                    builder: (ctx) => AlertDialog(
                      backgroundColor: isDark ? AppColors.surfaceElevated : Colors.white,
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
                            Navigator.pop(context); // Go back from settings
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

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 4.0),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w900,
          color: Color(0xFF94A3B8),
          letterSpacing: 1.0,
        ),
      ),
    );
  }

  Widget _buildLeadingIcon(IconData icon, Color color, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        shape: BoxShape.circle,
      ),
      child: Icon(icon, color: color, size: 18),
    );
  }
}
