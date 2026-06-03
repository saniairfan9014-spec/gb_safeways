import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/services/location_service.dart';
import '../../../core/services/notification_service.dart';
import '../../auth/controller/auth_controller.dart';
import '../controller/sos_controller.dart';

class EmergencyDetailsScreen extends StatefulWidget {
  const EmergencyDetailsScreen({super.key});

  @override
  State<EmergencyDetailsScreen> createState() => _EmergencyDetailsScreenState();
}

class _EmergencyDetailsScreenState extends State<EmergencyDetailsScreen> {
  final _formKey = GlobalKey<FormState>();
  final _descriptionController = TextEditingController();
  
  String _selectedType = 'Road Accident';
  Position? _currentPosition;
  bool _fetchingLocation = true;
  String _locationError = '';

  final List<Map<String, dynamic>> _emergencyTypes = [
    {
      'name': 'Road Accident',
      'icon': Icons.car_crash_rounded,
      'color': const Color(0xFFEF4444),
    },
    {
      'name': 'Landslide',
      'icon': Icons.terrain_rounded,
      'color': const Color(0xFFD97706),
    },
    {
      'name': 'Snow Blockage',
      'icon': Icons.ac_unit_rounded,
      'color': const Color(0xFF2563EB),
    },
    {
      'name': 'Flood',
      'icon': Icons.water_rounded,
      'color': const Color(0xFF06B6D4),
    },
    {
      'name': 'Medical Emergency',
      'icon': Icons.medical_services_rounded,
      'color': const Color(0xFF10B981),
    },
    {
      'name': 'Other',
      'icon': Icons.emergency_rounded,
      'color': const Color(0xFF6B7280),
    },
  ];

  @override
  void initState() {
    super.initState();
    _fetchGpsLocation();
  }

  @override
  void dispose() {
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _fetchGpsLocation() async {
    setState(() {
      _fetchingLocation = true;
      _locationError = '';
    });

    try {
      final position = await LocationService.instance.getCurrentLocation();
      if (position != null) {
        setState(() {
          _currentPosition = position;
          _fetchingLocation = false;
        });
      } else {
        setState(() {
          _locationError = 'Unable to access high-accuracy GPS services. Check permissions.';
          _fetchingLocation = false;
        });
      }
    } catch (e) {
      setState(() {
        _locationError = 'GPS acquisition failure: ${e.toString()}';
        _fetchingLocation = false;
      });
    }
  }

  Future<void> _submitAlert() async {
    if (!_formKey.currentState!.validate()) return;

    final authController = context.read<AuthController>();
    final sosController = context.read<SosController>();

    final user = authController.currentUser;
    if (user == null) {
      NotificationService.instance.showErrorSnackbar("You must be logged in to submit an SOS.");
      return;
    }

    // Default to Gilgit City (HQ) coordinates if GPS was unavailable
    final lat = _currentPosition?.latitude ?? 35.9208;
    final lng = _currentPosition?.longitude ?? 74.3089;

    if (_currentPosition == null) {
      NotificationService.instance.showWarningBanner(
        title: "⚠️ Offline/Fallback Location Used",
        message: "Your actual coordinates could not be loaded. Operating on regional backup coordinates.",
      );
    }

    final success = await sosController.submitSosAlert(
      userId: user.id,
      emergencyType: _selectedType,
      description: _descriptionController.text.trim().isEmpty ? null : _descriptionController.text.trim(),
      latitude: lat,
      longitude: lng,
    );

    if (success && mounted) {
      // Show confirmation dialog before popping back
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (ctx) => AlertDialog(
          backgroundColor: Theme.of(context).brightness == Brightness.light ? Colors.white : AppColors.surface,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Row(
            children: [
              Icon(Icons.check_circle_rounded, color: AppColors.statusOpen, size: 28),
              SizedBox(width: 10),
              Text("SOS Broadcasted", style: TextStyle(fontWeight: FontWeight.bold)),
            ],
          ),
          content: const Text(
            "Your SOS signal has been registered and broadcast to active rescue channels. Stay calm, help is on the way.",
            style: TextStyle(fontSize: 14),
          ),
          actions: [
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryDark,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              onPressed: () {
                Navigator.pop(ctx); // Close dialog
                Navigator.pop(context); // Pop back to HomeScreen
              },
              child: const Text("Understood", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
            ),
          ],
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final sosController = context.watch<SosController>();
    final isLight = Theme.of(context).brightness == Brightness.light;

    // Premium UI design tokens
    final bgCol = isLight ? const Color(0xFFF8FAFC) : AppColors.background;
    final textPrim = isLight ? const Color(0xFF0F172A) : AppColors.textPrimary;
    final textSec = isLight ? const Color(0xFF475569) : AppColors.textSecondary;
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
          "Emergency SOS Details",
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
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // 1. Live GPS Coordination Card
                Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: cardBg,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: borderCol, width: 1.2),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(isLight ? 0.02 : 0.1),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      _buildLocationIndicator(),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "SATELLITE GPS STATUS",
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w900,
                                color: isLight ? const Color(0xFF64748B) : AppColors.textMuted,
                                letterSpacing: 0.8,
                              ),
                            ),
                            const SizedBox(height: 4),
                            _buildLocationCoordinatesText(textPrim, textSec),
                          ],
                        ),
                      ),
                      if (!_fetchingLocation)
                        IconButton(
                          onPressed: _fetchGpsLocation,
                          icon: const Icon(Icons.refresh_rounded, color: Color(0xFF0284C7)),
                          tooltip: "Retry GPS fetch",
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // 2. Select Emergency Type Grid
                Text(
                  "SELECT EMERGENCY TYPE",
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w900,
                    color: isLight ? const Color(0xFF64748B) : AppColors.textMuted,
                    letterSpacing: 0.8,
                  ),
                ),
                const SizedBox(height: 12),
                GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    mainAxisSpacing: 12,
                    crossAxisSpacing: 12,
                    childAspectRatio: 1.6,
                  ),
                  itemCount: _emergencyTypes.length,
                  itemBuilder: (context, index) {
                    final type = _emergencyTypes[index];
                    final isSelected = _selectedType == type['name'];
                    final color = type['color'] as Color;

                    return InkWell(
                      onTap: () {
                        setState(() {
                          _selectedType = type['name'];
                        });
                      },
                      borderRadius: BorderRadius.circular(16),
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: isSelected 
                              ? color.withOpacity(0.12)
                              : cardBg,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: isSelected ? color : borderCol,
                            width: isSelected ? 2.0 : 1.2,
                          ),
                          boxShadow: isSelected
                              ? [BoxShadow(color: color.withOpacity(0.15), blurRadius: 8, offset: const Offset(0, 3))]
                              : [],
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Icon(
                              type['icon'] as IconData,
                              color: isSelected ? color : (isLight ? const Color(0xFF64748B) : AppColors.textSecondary),
                              size: 26,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              type['name'] as String,
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: isSelected ? color : textPrim,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 24),

                // 3. Optional description text input
                Text(
                  "DESCRIPTION / ADVISORY DETAILS",
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w900,
                    color: isLight ? const Color(0xFF64748B) : AppColors.textMuted,
                    letterSpacing: 0.8,
                  ),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _descriptionController,
                  maxLines: 4,
                  maxLength: 250,
                  style: TextStyle(color: textPrim, fontSize: 14),
                  decoration: InputDecoration(
                    hintText: "Add specific instructions, e.g., 'Trapped by landslide debris near checkpoint, 2 travelers with minor injuries.'",
                    hintStyle: const TextStyle(color: Color(0xFF94A3B8), fontSize: 13),
                    filled: true,
                    fillColor: cardBg,
                    contentPadding: const EdgeInsets.all(16),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide(color: borderCol, width: 1.2),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide(color: borderCol, width: 1.2),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: const BorderSide(color: Color(0xFF0284C7), width: 1.5),
                    ),
                  ),
                ),
                const SizedBox(height: 28),

                // 4. Submit SOS Button
                ElevatedButton(
                  onPressed: sosController.isLoading ? null : _submitAlert,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.statusDanger,
                    foregroundColor: Colors.white,
                    disabledBackgroundColor: AppColors.statusDanger.withOpacity(0.5),
                    elevation: 4,
                    shadowColor: AppColors.statusDanger.withOpacity(0.4),
                    padding: const EdgeInsets.symmetric(vertical: 18),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  child: sosController.isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.5,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.wifi_tethering_rounded, size: 20),
                            SizedBox(width: 10),
                            Text(
                              "BROADCAST DISTRESS SIGNAL",
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ],
                        ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLocationIndicator() {
    if (_fetchingLocation) {
      return const _PulsingLocationIcon(color: Color(0xFFF59E0B));
    }
    if (_currentPosition == null) {
      return const _PulsingLocationIcon(color: Color(0xFFEF4444), icon: Icons.location_off_rounded);
    }
    return const _PulsingLocationIcon(color: Color(0xFF10B981), icon: Icons.gps_fixed_rounded);
  }

  Widget _buildLocationCoordinatesText(Color textPrim, Color textSec) {
    if (_fetchingLocation) {
      return const Text(
        "Acquiring high-accuracy coordinates...",
        style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Color(0xFFF59E0B)),
      );
    }
    if (_currentPosition == null) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "GPS Signal Failed",
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFFEF4444)),
          ),
          const SizedBox(height: 2),
          Text(
            _locationError.isNotEmpty ? _locationError : "Will fallback to regional hub (Gilgit).",
            style: const TextStyle(fontSize: 11, color: Color(0xFF64748B)),
          ),
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Latitude: ${_currentPosition!.latitude.toStringAsFixed(6)}",
          style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: textPrim),
        ),
        const SizedBox(height: 2),
        Text(
          "Longitude: ${_currentPosition!.longitude.toStringAsFixed(6)}",
          style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: textPrim),
        ),
      ],
    );
  }
}

class _PulsingLocationIcon extends StatefulWidget {
  final Color color;
  final IconData icon;

  const _PulsingLocationIcon({
    required this.color,
    this.icon = Icons.gps_not_fixed_rounded,
  });

  @override
  State<_PulsingLocationIcon> createState() => _PulsingLocationIconState();
}

class _PulsingLocationIconState extends State<_PulsingLocationIcon> with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _pulseController,
      builder: (context, child) {
        return Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: widget.color.withOpacity(0.08 + (_pulseController.value * 0.1)),
            shape: BoxShape.circle,
            border: Border.all(
              color: widget.color.withOpacity(0.2 + (_pulseController.value * 0.4)),
              width: 1.5,
            ),
          ),
          child: Icon(
            widget.icon,
            color: widget.color,
            size: 24,
          ),
        );
      },
    );
  }
}
