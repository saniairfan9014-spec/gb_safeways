import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_strings.dart';
import '../../../shared/widgets/custom_button.dart';
import '../../auth/controller/auth_controller.dart';
import '../../roads/controller/road_controller.dart';
import '../controller/report_controller.dart';

class ReportScreen extends StatefulWidget {
  const ReportScreen({super.key});

  @override
  State<ReportScreen> createState() => _ReportScreenState();
}

class _ReportScreenState extends State<ReportScreen> {
  final _formKey = GlobalKey<FormState>();
  final _descriptionController = TextEditingController();
  final _customRoadController = TextEditingController();
  final _imageUrlController = TextEditingController();
  
  String? _selectedRoadId;
  String _selectedHazard = AppStrings.hazardLandslide;
  String _selectedSeverity = "High";
  bool _useGPS = true;

  @override
  void dispose() {
    _descriptionController.dispose();
    _customRoadController.dispose();
    _imageUrlController.dispose();
    super.dispose();
  }

  void _handleSubmit() async {
    if (_formKey.currentState!.validate() && _selectedRoadId != null) {
      final authController = context.read<AuthController>();
      final roadController = context.read<RoadController>();
      final reportController = context.read<ReportController>();

      String roadId;
      String roadName;

      if (_selectedRoadId == 'road-other') {
        roadId = 'road-other';
        roadName = _customRoadController.text.trim();
      } else {
        final selectedRoad = roadController.roads.firstWhere((r) => r.id == _selectedRoadId);
        roadId = selectedRoad.id;
        roadName = selectedRoad.name;
      }

      final success = await reportController.submitReport(
        roadId: roadId,
        roadName: roadName,
        hazardType: _selectedHazard,
        description: _descriptionController.text.trim(),
        severity: _selectedSeverity,
        imageUrl: _imageUrlController.text.trim().isNotEmpty ? _imageUrlController.text.trim() : null,
        authController: authController,
        roadController: roadController,
      );

      if (success && mounted) {
        _descriptionController.clear();
        _customRoadController.clear();
        _imageUrlController.clear();
        setState(() {
          _selectedRoadId = null;
          _selectedHazard = AppStrings.hazardLandslide;
          _selectedSeverity = "High";
        });
      }
    } else if (_selectedRoadId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Please select the affected mountain highway."),
          backgroundColor: AppColors.statusDanger,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final roadController = context.watch<RoadController>();
    final reportController = context.watch<ReportController>();

    final hazardTypes = [
      AppStrings.hazardLandslide,
      AppStrings.hazardAvalanche,
      AppStrings.hazardRockfall,
      AppStrings.hazardMudslide,
      AppStrings.hazardAccident,
      AppStrings.hazardBlockage,
      AppStrings.hazardConstruction,
    ];

    return Container(
      decoration: const BoxDecoration(
        gradient: AppColors.darkGradient,
      ),
      child: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Header Title
                const Text(
                  "Report Mountain Hazard",
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  "Submit real-time updates to safeguard other mountain travelers.",
                  style: TextStyle(
                    fontSize: 13,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 24),

                // Report Container
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: AppColors.border, width: 1.5),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Select Road Dropdown
                      const Text(
                        "Affected Route",
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.textSecondary),
                      ),
                      const SizedBox(height: 8),
                      DropdownButtonFormField<String>(
                        value: _selectedRoadId,
                        hint: const Text("Choose Highway / Valley Road", style: TextStyle(color: AppColors.textMuted)),
                        dropdownColor: AppColors.surfaceElevated,
                        items: roadController.roads.map((road) {
                          return DropdownMenuItem<String>(
                            value: road.id,
                            child: Text(road.name, style: const TextStyle(fontSize: 13, color: Colors.white)),
                          );
                        }).toList(),
                        onChanged: (val) {
                          setState(() {
                            _selectedRoadId = val;
                          });
                        },
                        decoration: const InputDecoration(
                          contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        ),
                      ),
                      
                      // Animated Custom Road Name Input field (if selected "Other / Custom Road")
                      AnimatedSize(
                        duration: const Duration(milliseconds: 250),
                        curve: Curves.fastOutSlowIn,
                        child: _selectedRoadId == 'road-other'
                            ? Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  const SizedBox(height: 16),
                                  const Text(
                                    "Custom Route / Valley Name",
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                      color: AppColors.textSecondary,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  TextFormField(
                                    controller: _customRoadController,
                                    style: const TextStyle(fontSize: 13, color: Colors.white),
                                    decoration: const InputDecoration(
                                      hintText: "e.g. Nagar Valley Road, Hunza-Shimshal Road",
                                      prefixIcon: Icon(Icons.edit_road_rounded, color: AppColors.textMuted, size: 18),
                                    ),
                                    validator: (value) {
                                      if (_selectedRoadId == 'road-other' && (value == null || value.trim().isEmpty)) {
                                        return "Please specify the custom road name";
                                      }
                                      return null;
                                    },
                                  ),
                                ],
                              )
                            : const SizedBox.shrink(),
                      ),
                      const SizedBox(height: 20),

                      // Select Hazard Dropdown
                      const Text(
                        "Hazard Category",
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.textSecondary),
                      ),
                      const SizedBox(height: 8),
                      DropdownButtonFormField<String>(
                        value: _selectedHazard,
                        dropdownColor: AppColors.surfaceElevated,
                        items: hazardTypes.map((hazard) {
                          return DropdownMenuItem<String>(
                            value: hazard,
                            child: Text(hazard, style: const TextStyle(fontSize: 13, color: Colors.white)),
                          );
                        }).toList(),
                        onChanged: (val) {
                          if (val != null) {
                            setState(() {
                              _selectedHazard = val;
                            });
                          }
                        },
                        decoration: const InputDecoration(
                          contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Severity chips row
                      const Text(
                        "Incident Severity",
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.textSecondary),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: ["Low", "Medium", "High"].map((level) {
                          final isSelected = _selectedSeverity == level;
                          final color = level == "High"
                              ? AppColors.statusDanger
                              : level == "Medium"
                                  ? AppColors.statusCaution
                                  : AppColors.statusOpen;

                          return Expanded(
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 4.0),
                              child: ChoiceChip(
                                label: Text(
                                  level,
                                  style: TextStyle(
                                    color: isSelected ? Colors.white : AppColors.textSecondary,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 12,
                                  ),
                                ),
                                selected: isSelected,
                                selectedColor: color,
                                backgroundColor: AppColors.surfaceElevated,
                                checkmarkColor: Colors.white,
                                onSelected: (_) {
                                  setState(() {
                                    _selectedSeverity = level;
                                  });
                                },
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                  side: BorderSide(
                                    color: isSelected ? Colors.transparent : AppColors.border,
                                    width: 1.5,
                                  ),
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 24),

                      // Description input
                      const Text(
                        "Describe Road Obstruction",
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.textSecondary),
                      ),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _descriptionController,
                        maxLines: 4,
                        decoration: const InputDecoration(
                          hintText: "State the block details (e.g. Shengus point blocked by 4 large rocks. Landslide still minor. GBDMA contacted).",
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return "Please describe the hazard";
                          }
                          if (value.length < 10) {
                            return "Description should be at least 10 characters";
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 20),

                      // Photo Attachment / Hazard Image
                      const Text(
                        "Attach Hazard Photo (Optional)",
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.textSecondary),
                      ),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _imageUrlController,
                        style: const TextStyle(fontSize: 13, color: Colors.white),
                        decoration: const InputDecoration(
                          hintText: "Paste an image URL or choose a template below...",
                          prefixIcon: Icon(Icons.link_rounded, color: AppColors.textMuted, size: 18),
                        ),
                        onChanged: (val) {
                          setState(() {});
                        },
                      ),
                      const SizedBox(height: 12),
                      
                      // Preset template thumbnails
                      Row(
                        children: [
                          _buildPresetImageChip(
                            label: "Landslide",
                            url: "https://images.unsplash.com/photo-1464822759023-fed622ff2c3b?auto=format&fit=crop&w=400&q=80",
                          ),
                          const SizedBox(width: 8),
                          _buildPresetImageChip(
                            label: "Snow Pass",
                            url: "https://images.unsplash.com/photo-1544816155-12df9643f363?auto=format&fit=crop&w=400&q=80",
                          ),
                          const SizedBox(width: 8),
                          _buildPresetImageChip(
                            label: "Rockfall",
                            url: "https://images.unsplash.com/photo-1518098268026-4e43a1a009de?auto=format&fit=crop&w=400&q=80",
                          ),
                          const SizedBox(width: 8),
                          _buildPresetImageChip(
                            label: "Traffic",
                            url: "https://images.unsplash.com/photo-1494783367193-149034c05e8f?auto=format&fit=crop&w=400&q=80",
                          ),
                        ],
                      ),
                      
                      // Live Image Preview if filled
                      if (_imageUrlController.text.trim().isNotEmpty) ...[
                        const SizedBox(height: 16),
                        Container(
                          height: 140,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: AppColors.border),
                            image: DecorationImage(
                              image: NetworkImage(_imageUrlController.text.trim()),
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),
                      ],
                      const SizedBox(height: 20),

                      // Location coordinates tagging card
                      Row(
                        children: [
                          Checkbox(
                            value: _useGPS,
                            onChanged: (val) {
                              if (val != null) {
                                setState(() {
                                  _useGPS = val;
                                });
                              }
                            },
                            activeColor: AppColors.primary,
                          ),
                          const Expanded(
                            child: Text(
                              "Auto-tag live GPS Coordinates",
                              style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),

                      // Submit button
                      CustomButton(
                        text: "Submit Alert Report",
                        onPressed: _handleSubmit,
                        isLoading: reportController.isLoading,
                        icon: Icons.send_rounded,
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

  Widget _buildPresetImageChip({required String label, required String url}) {
    final isSelected = _imageUrlController.text.trim() == url;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() {
            _imageUrlController.text = url;
          });
        },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 6),
          decoration: BoxDecoration(
            color: isSelected ? AppColors.primary : AppColors.surfaceElevated,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: isSelected ? Colors.white : AppColors.border,
              width: isSelected ? 1.5 : 1.0,
            ),
          ),
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.bold,
                color: isSelected ? Colors.white : AppColors.textSecondary,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
