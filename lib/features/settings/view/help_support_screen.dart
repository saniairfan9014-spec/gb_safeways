import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/utils/logger.dart';
import '../../emergency/controller/emergency_controller.dart';

class HelpSupportScreen extends StatelessWidget {
  const HelpSupportScreen({super.key});

  final List<Map<String, String>> faqs = const [
    {
      "q": "How does the offline mode work?",
      "a": "GB SafeRoute keeps a local database on your device. Every time you have active internet coverage, the app caches the latest highway blockages, landslide statuses, and emergency checkpoints. You can view this cached data even when you are completely offline in remote passes."
    },
    {
      "q": "How do I trigger an emergency SOS alert?",
      "a": "Navigate to the Emergency SOS tab and press & hold the large red SOS button for 3 seconds. A 5-second countdown will start, after which your GPS location coordinates and profile info will be sent to search & rescue hubs. If offline, the app will prepare an SMS dispatch."
    },
    {
      "q": "Are the road hazard blockages verified?",
      "a": "Yes. Every hazard report submitted by travelers goes to our verification queue. Admin dispatchers and local highway police check details before marking them as 'Verified'. Verified blockages will immediately impact the status of the highway."
    },
    {
      "q": "Can I submit a report when offline?",
      "a": "Yes. If you submit a landslide or rockfall report while offline, the app saves the request locally with your GPS location stamp. The moment your device detects network signal, it will synchronize and submit the report automatically."
    },
    {
      "q": "Who operates the rescue patrols?",
      "a": "Patrol responses are coordinated by Rescue 1122 Gilgit-Baltistan, GBDMA (Gilgit-Baltistan Disaster Management Authority), and regional police checkpoints along the Karakoram Highway (KKH)."
    }
  ];

  Future<void> _launchEmail(String email) async {
    final Uri emailUri = Uri(
      scheme: 'mailto',
      path: email,
      queryParameters: {
        'subject': 'GB SafeRoute Support Request',
      },
    );
    try {
      if (await canLaunchUrl(emailUri)) {
        await launchUrl(emailUri);
      } else {
        AppLogger.warn("Cannot launch email client.");
      }
    } catch (e) {
      AppLogger.error("Failed to launch email", e);
    }
  }

  Future<void> _launchWhatsApp(String phone) async {
    final Uri waUri = Uri.parse("https://wa.me/$phone");
    try {
      if (await canLaunchUrl(waUri)) {
        await launchUrl(waUri, mode: LaunchMode.externalApplication);
      } else {
        AppLogger.warn("Cannot launch WhatsApp.");
      }
    } catch (e) {
      AppLogger.error("Failed to launch WhatsApp", e);
    }
  }

  @override
  Widget build(BuildContext context) {
    final emergencyController = context.read<EmergencyController>();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final bgCol = isDark ? AppColors.background : const Color(0xFFF8FAFC);
    final textPrim = isDark ? AppColors.textPrimary : const Color(0xFF0F172A);
    final textSec = isDark ? AppColors.textSecondary : const Color(0xFF475569);
    final borderCol = isDark ? AppColors.border : const Color(0xFFF1F5F9);
    final cardBg = isDark ? AppColors.surface : Colors.white;

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
          "Help & Support",
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
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // FAQ Header
              Text(
                "FREQUENTLY ASKED QUESTIONS",
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w900,
                  color: isDark ? AppColors.textMuted : const Color(0xFF94A3B8),
                  letterSpacing: 1.0,
                ),
              ),
              const SizedBox(height: 10),

              // FAQ List
              Container(
                decoration: BoxDecoration(
                  color: cardBg,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: borderCol, width: 1.0),
                ),
                child: ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: faqs.length,
                  separatorBuilder: (context, index) => Divider(color: borderCol, height: 1),
                  itemBuilder: (context, index) {
                    final faq = faqs[index];
                    return Theme(
                      data: Theme.of(context).copyWith(
                        dividerColor: Colors.transparent,
                      ),
                      child: ExpansionTile(
                        iconColor: const Color(0xFF0284C7),
                        collapsedIconColor: isDark ? Colors.white54 : Colors.black54,
                        title: Text(
                          faq["q"]!,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: textPrim,
                          ),
                        ),
                        children: [
                          Padding(
                            padding: const EdgeInsets.only(left: 16.0, right: 16.0, bottom: 16.0),
                            child: Text(
                              faq["a"]!,
                              style: TextStyle(
                                fontSize: 13,
                                color: textSec,
                                height: 1.5,
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 32),

              // Contact Channels Section
              Text(
                "STILL NEED HELP?",
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w900,
                  color: isDark ? AppColors.textMuted : const Color(0xFF94A3B8),
                  letterSpacing: 1.0,
                ),
              ),
              const SizedBox(height: 10),

              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: cardBg,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: borderCol, width: 1.0),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      "Emergency Rescue Line",
                      style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: textPrim),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      "Direct call connection to GBDMA control headquarters.",
                      style: TextStyle(fontSize: 12, color: textSec),
                    ),
                    const SizedBox(height: 12),
                    ElevatedButton.icon(
                      onPressed: () => emergencyController.makeCall("05811920874"),
                      icon: const Icon(Icons.phone_in_talk_rounded),
                      label: const Text("Call Disaster Control Hotline"),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.redAccent,
                        foregroundColor: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 20),
                    const Divider(),
                    const SizedBox(height: 16),
                    Text(
                      "General Support Inquiries",
                      style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: textPrim),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      "Reach out to our development and dispatch team via email or messaging.",
                      style: TextStyle(fontSize: 12, color: textSec),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () => _launchEmail("support@gbsafeway.gov.pk"),
                            icon: const Icon(Icons.email_outlined, size: 18),
                            label: const Text("Email Us", style: TextStyle(fontSize: 12)),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: const Color(0xFF0284C7),
                              side: const BorderSide(color: Color(0xFF0284C7)),
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () => _launchWhatsApp("923554567890"),
                            icon: const Icon(Icons.chat_bubble_outline_rounded, size: 18),
                            label: const Text("WhatsApp", style: TextStyle(fontSize: 12)),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: const Color(0xFF10B981),
                              side: const BorderSide(color: Color(0xFF10B981)),
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                          ),
                        ),
                      ],
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
