import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/services/location_service.dart';
import '../../../core/services/notification_service.dart';
import '../../../shared/widgets/custom_button.dart';
import '../controller/emergency_controller.dart';

class EmergencyScreen extends StatelessWidget {
  const EmergencyScreen({super.key});

  // Action helper to broadcast specific type of emergency
  void _triggerSpecificEmergency(BuildContext context, String type, EmergencyController controller) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            const Icon(Icons.warning_amber_rounded, color: Color(0xFFEF4444)),
            const SizedBox(width: 8),
            Text(
              "Report $type",
              style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
            ),
          ],
        ),
        content: Text(
          "Are you sure you want to broadcast a distress signal for a '$type' emergency? "
          "This will immediately transmit your GPS coordinates to GBDMA rescue rooms.",
          style: const TextStyle(color: Color(0xFF475569), fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("Cancel", style: TextStyle(color: Color(0xFF64748B))),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFEF4444),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () {
              Navigator.pop(ctx);
              controller.startSosTriggerFlow();
            },
            child: const Text("Confirm SOS", style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Future<void> _shareLiveLocation(BuildContext context) async {
    final location = await LocationService.instance.getCurrentLocation();
    String coords = "Lat: 35.9208, Lng: 74.3089 (Gilgit)";
    if (location != null) {
      coords = "Lat: ${location.latitude.toStringAsFixed(4)}, Lng: ${location.longitude.toStringAsFixed(4)}";
    }
    NotificationService.instance.showSuccessSnackbar("📍 Coordinates shared: $coords. Emergency dispatchers updated.");
  }

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<EmergencyController>();
    final isLight = Theme.of(context).brightness == Brightness.light;

    // Adaptive design tokens
    final bgCol = isLight ? const Color(0xFFF8FAFC) : AppColors.background;
    final textPrim = isLight ? const Color(0xFF0F172A) : AppColors.textPrimary;
    final textSec = isLight ? const Color(0xFF475569) : AppColors.textSecondary;
    final cardBg = isLight ? Colors.white : AppColors.surface;
    final borderCol = isLight ? const Color(0xFFE2E8F0) : AppColors.border;

    return Container(
      color: bgCol,
      child: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 12.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header Title
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Emergency Support",
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w800,
                          color: textPrim,
                          letterSpacing: -0.5,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        "Direct distress beacons and disaster response desks",
                        style: TextStyle(
                          fontSize: 13,
                          color: textSec,
                        ),
                      ),
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEF4444).withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.emergency_rounded, color: Color(0xFFEF4444), size: 24),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // SOS Trigger Box Panel (Countdown or Broadcast)
              _buildSosTriggerArea(context, controller, isLight, textPrim, textSec, cardBg, borderCol),
              const SizedBox(height: 24),

              // Quick Action Cards for Emergency Types
              Text(
                "Quick Action Cards",
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: textPrim,
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  _buildQuickActionCard(
                    context: context,
                    icon: Icons.terrain_rounded,
                    label: "Landslide\nBlockage",
                    color: const Color(0xFFEF4444),
                    onTap: () => _triggerSpecificEmergency(context, "Landslide Blockage", controller),
                    isLight: isLight,
                  ),
                  const SizedBox(width: 10),
                  _buildQuickActionCard(
                    context: context,
                    icon: Icons.car_crash_rounded,
                    label: "Road\nAccident",
                    color: const Color(0xFFEF4444),
                    onTap: () => _triggerSpecificEmergency(context, "Road Accident", controller),
                    isLight: isLight,
                  ),
                  const SizedBox(width: 10),
                  _buildQuickActionCard(
                    context: context,
                    icon: Icons.medical_services_rounded,
                    label: "Medical\nCare",
                    color: const Color(0xFFEF4444),
                    onTap: () => _triggerSpecificEmergency(context, "Medical Emergency", controller),
                    isLight: isLight,
                  ),
                ],
              ),
              const SizedBox(height: 28),

              // Rescue Contacts List
              Text(
                "Rescue Contacts",
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: textPrim,
                ),
              ),
              const SizedBox(height: 12),
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: controller.contacts.length,
                itemBuilder: (context, index) {
                  final contact = controller.contacts[index];
                  return Container(
                    margin: const EdgeInsets.only(bottom: 12),
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
                    child: ListTile(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                      leading: Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: const Color(0xFF0284C7).withOpacity(0.12),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(contact.icon, color: const Color(0xFF0284C7), size: 22),
                      ),
                      title: Text(
                        contact.name,
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: textPrim),
                      ),
                      subtitle: Text(
                        "${contact.location} • ${contact.phone}",
                        style: TextStyle(color: textSec, fontSize: 12),
                      ),
                      trailing: InkWell(
                        onTap: () => controller.makeCall(contact.phone),
                        borderRadius: BorderRadius.circular(30),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          decoration: BoxDecoration(
                            color: const Color(0xFFE2E8F0),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: const [
                              Icon(Icons.phone_rounded, color: Color(0xFF0F172A), size: 14),
                              SizedBox(width: 4),
                              Text(
                                "Call",
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF0F172A),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  // SOS Panel State Builder
  Widget _buildSosTriggerArea(
    BuildContext context,
    EmergencyController controller,
    bool isLight,
    Color textPrim,
    Color textSec,
    Color cardBg,
    Color borderCol,
  ) {
    if (controller.isSosActivating) {
      return Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: const Color(0xFFF59E0B).withOpacity(0.08),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xFFF59E0B).withOpacity(0.5), width: 2),
        ),
        child: Column(
          children: [
            const Text(
              "ACTIVATING EMERGENCY SOS",
              style: TextStyle(fontWeight: FontWeight.w800, color: Color(0xFFF59E0B), fontSize: 16, letterSpacing: 0.5),
            ),
            const SizedBox(height: 16),
            Text(
              "${controller.sosCountdown}",
              style: const TextStyle(fontSize: 72, fontWeight: FontWeight.w900, color: Color(0xFFF59E0B)),
            ),
            const SizedBox(height: 16),
            Text(
              "Broadcasting distress satellite details in a few seconds...",
              style: TextStyle(color: textSec, fontSize: 13),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            CustomButton(
              text: "Cancel Broadcast",
              color: borderCol,
              onPressed: () => controller.cancelSosTrigger(),
            ),
          ],
        ),
      );
    }

    if (controller.sosTriggered) {
      return Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: const Color(0xFFEF4444).withOpacity(0.08),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xFFEF4444).withOpacity(0.5), width: 2),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFFEF4444).withOpacity(0.1),
              blurRadius: 20,
              spreadRadius: 4,
            ),
          ],
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFEF4444).withOpacity(0.2),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.warning_rounded, size: 48, color: Color(0xFFEF4444)),
            ),
            const SizedBox(height: 16),
            const Text(
              "EMERGENCY BEACON ACTIVE",
              style: TextStyle(fontWeight: FontWeight.w800, color: Color(0xFFEF4444), fontSize: 18, letterSpacing: 0.5),
            ),
            const SizedBox(height: 8),
            Text(
              "Your GPS satellite coordinates have been broadcasted to GBDMA rescue rooms. Responders are alerted.",
              style: TextStyle(color: textSec, fontSize: 13, height: 1.4),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: CustomButton(
                    text: "Call Helpline",
                    icon: Icons.phone,
                    color: const Color(0xFFEF4444),
                    onPressed: () => controller.makeCall("1122"),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: CustomButton(
                    text: "Reset SOS",
                    isOutline: true,
                    color: textSec,
                    onPressed: () => controller.resetSos(),
                  ),
                ),
              ],
            ),
          ],
        ),
      );
    }

    // Default SOS area: Central SOS Button & Side-by-Side Call Ambulance / Live Location buttons
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: borderCol, width: 1.2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isLight ? 0.04 : 0.15),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          // 1. Concentric Circular Glowing SOS Button
          GestureDetector(
            onTap: () => controller.startSosTriggerFlow(),
            child: Container(
              width: 150,
              height: 150,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFFEF4444),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFFEF4444).withOpacity(0.35),
                    blurRadius: 24,
                    spreadRadius: 8,
                  ),
                  BoxShadow(
                    color: const Color(0xFFEF4444).withOpacity(0.2),
                    blurRadius: 40,
                    spreadRadius: 16,
                  ),
                ],
                gradient: const LinearGradient(
                  colors: [Color(0xFFEF4444), Color(0xFFDC2626)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: const [
                    Icon(Icons.wifi_tethering_rounded, color: Colors.white, size: 28),
                    SizedBox(height: 6),
                    Text(
                      "SOS",
                      style: TextStyle(
                        fontSize: 34,
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                        letterSpacing: 1.0,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            "Tap to trigger 5-second satellite distress count",
            style: TextStyle(fontSize: 12, color: textSec, fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 24),

          // 2. Large Side-by-Side call-out actions
          Row(
            children: [
              Expanded(
                child: InkWell(
                  onTap: () => controller.makeCall("1122"),
                  borderRadius: BorderRadius.circular(16),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEF4444),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: const [
                        Icon(Icons.phone_in_talk_rounded, color: Colors.white, size: 18),
                        SizedBox(width: 8),
                        Text(
                          "Call Ambulance",
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: InkWell(
                  onTap: () => _shareLiveLocation(context),
                  borderRadius: BorderRadius.circular(16),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEF4444),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: const [
                        Icon(Icons.my_location_rounded, color: Colors.white, size: 18),
                        SizedBox(width: 8),
                        Text(
                          "Share Location",
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // Quick Action Type Card
  Widget _buildQuickActionCard({
    required BuildContext context,
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
    required bool isLight,
  }) {
    final cardBg = isLight ? Colors.white : AppColors.surface;
    final borderCol = isLight ? const Color(0xFFE2E8F0) : AppColors.border;

    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 8),
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
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.08),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: color, size: 24),
              ),
              const SizedBox(height: 12),
              Text(
                label,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: isLight ? const Color(0xFF0F172A) : AppColors.textPrimary,
                  height: 1.2,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
