import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/utils/helpers.dart';
import '../../auth/controller/auth_controller.dart';
import '../../roads/controller/road_controller.dart';
import '../../reports/controller/report_controller.dart';
import '../../../routes/route_names.dart';

// Import sub screens to display inside the Tab Shell
import '../../roads/view/road_status_screen.dart';
import '../../reports/view/report_screen.dart';
import '../../emergency/view/emergency_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentTab = 0;

  final List<Widget> _tabs = [
    const DashboardView(),
    const RoadStatusScreen(),
    const ReportScreen(),
    const EmergencyScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    final authController = context.watch<AuthController>();

    // Route guard: Redirect to Login if not authenticated
    if (!authController.isAuthenticated && !authController.isLoading) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Navigator.pushReplacementNamed(context, RouteNames.login);
      });
      return Scaffold(
        body: Container(
          decoration: BoxDecoration(gradient: AppColors.darkGradient),
          child: const Center(child: CircularProgressIndicator()),
        ),
      );
    }

    return Scaffold(
      body: authController.isLoading 
          ? Container(
              decoration: BoxDecoration(gradient: AppColors.darkGradient),
              child: const Center(child: CircularProgressIndicator()),
            )
          : _tabs[_currentTab],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentTab,
        onTap: (index) {
          setState(() {
            _currentTab = index;
          });
        },
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.dashboard_outlined),
            activeIcon: Icon(Icons.dashboard),
            label: "Dashboard",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.add_road_outlined),
            activeIcon: Icon(Icons.add_road),
            label: "Roads",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.report_problem_outlined),
            activeIcon: Icon(Icons.report_problem),
            label: "Report Alert",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.emergency_outlined),
            activeIcon: Icon(Icons.emergency),
            label: "Emergency SOS",
          ),
        ],
      ),
    );
  }
}

class DashboardView extends StatefulWidget {
  const DashboardView({super.key});

  @override
  State<DashboardView> createState() => _DashboardViewState();
}

class _DashboardViewState extends State<DashboardView> {
  final _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authController = context.watch<AuthController>();
    final roadController = context.watch<RoadController>();
    final reportController = context.watch<ReportController>();
    final user = authController.currentUser;

    if (user == null) return const SizedBox.shrink();

    // Filter reports/updates if search query is present
    final searchQuery = _searchController.text.trim().toLowerCase();
    final updates = reportController.activeReports.where((report) {
      if (searchQuery.isEmpty) return true;
      return report.roadName.toLowerCase().contains(searchQuery) ||
          report.hazardType.toLowerCase().contains(searchQuery) ||
          report.description.toLowerCase().contains(searchQuery);
    }).toList();

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC), // soft white background
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async {
            await roadController.loadRoads();
            await reportController.loadReports();
          },
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 1. Top Bar: App Name & Location (Gilgit)
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              "GB SafeRoute",
                              style: TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.w800,
                                color: Color(0xFF0284C7), // Blue primary
                                letterSpacing: -0.5,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: const Color(0xFF0284C7).withOpacity(0.1),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: const Row(
                                children: [
                                  Icon(Icons.wifi_off_rounded, size: 10, color: Color(0xFF0284C7)),
                                  SizedBox(width: 3),
                                  Text(
                                    "OFFLINE READ",
                                    style: TextStyle(fontSize: 8, fontWeight: FontWeight.bold, color: Color(0xFF0284C7)),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: const [
                            Icon(Icons.location_on_rounded, size: 14, color: Color(0xFF64748B)),
                            SizedBox(width: 4),
                            Text(
                              "Gilgit, Pakistan",
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF64748B), // Slate gray location label
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    // User Avatar with contribution badge tooltip
                    GestureDetector(
                      onTap: () {
                        Navigator.pushNamed(context, RouteNames.profile);
                      },
                      child: Container(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: const Color(0xFFE2E8F0), width: 2),
                        ),
                        child: CircleAvatar(
                          radius: 20,
                          backgroundImage: NetworkImage(user.avatarUrl),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // 2. Large Search Bar for roads
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.03),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: TextField(
                    controller: _searchController,
                    onChanged: (val) {
                      setState(() {});
                    },
                    decoration: InputDecoration(
                      hintText: "Search routes, passes, or checkpoints...",
                      hintStyle: const TextStyle(color: Color(0xFF94A3B8), fontSize: 14),
                      prefixIcon: const Icon(Icons.search_rounded, color: Color(0xFF0284C7), size: 22),
                      filled: true,
                      fillColor: Colors.white,
                      contentPadding: const EdgeInsets.symmetric(vertical: 16),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide.none,
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide.none,
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: const BorderSide(color: Color(0xFF0284C7), width: 1.5),
                      ),
                      suffixIcon: _searchController.text.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear_rounded, color: Color(0xFF94A3B8), size: 18),
                              onPressed: () {
                                _searchController.clear();
                                setState(() {});
                              },
                            )
                          : null,
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // 3. Three Main Feature Cards
                Row(
                  children: [
                    // Card 1: Road Status
                    Expanded(
                      child: _buildFeatureCard(
                        context,
                        title: "Road Status",
                        description: "Live traffic & conditions",
                        icon: Icons.alt_route_rounded,
                        accentColor: const Color(0xFF0284C7),
                        onTap: () {
                          final homeState = context.findAncestorStateOfType<_HomeScreenState>();
                          if (homeState != null) {
                            homeState.setState(() {
                              homeState._currentTab = 1;
                            });
                          }
                        },
                      ),
                    ),
                    const SizedBox(width: 10),

                    // Card 2: Emergency (Red Alert)
                    Expanded(
                      child: _buildFeatureCard(
                        context,
                        title: "Emergency",
                        description: "Instant help & contacts",
                        icon: Icons.sos_rounded,
                        accentColor: const Color(0xFFEF4444), // Crimson Emergency RED
                        isEmergency: true,
                        onTap: () {
                          final homeState = context.findAncestorStateOfType<_HomeScreenState>();
                          if (homeState != null) {
                            homeState.setState(() {
                              homeState._currentTab = 3;
                            });
                          }
                        },
                      ),
                    ),
                    const SizedBox(width: 10),

                    // Card 3: Alerts
                    Expanded(
                      child: _buildFeatureCard(
                        context,
                        title: "Alerts",
                        description: "Critical notifications",
                        icon: Icons.notifications_active_rounded,
                        accentColor: const Color(0xFFF59E0B), // Warning Amber
                        badgeCount: updates.length,
                        onTap: () {
                          Navigator.pushNamed(context, RouteNames.alerts);
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 32),

                // 4. Below Section: Latest Updates feed in card style
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      "Latest Updates",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF0F172A),
                      ),
                    ),
                    TextButton(
                      onPressed: () {
                        // Navigate to Roads tab
                        final homeState = context.findAncestorStateOfType<_HomeScreenState>();
                        if (homeState != null) {
                          homeState.setState(() {
                            homeState._currentTab = 1;
                          });
                        }
                      },
                      child: const Text(
                        "See All",
                        style: TextStyle(color: Color(0xFF0284C7), fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),

                // Feed List
                reportController.isLoading
                    ? const Center(
                        child: Padding(
                          padding: EdgeInsets.all(32.0),
                          child: CircularProgressIndicator(),
                        ),
                      )
                    : updates.isEmpty
                        ? Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(32),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: const Color(0xFFE2E8F0)),
                            ),
                            child: Column(
                              children: const [
                                Icon(Icons.check_circle_outline_rounded, color: Color(0xFF10B981), size: 40),
                                SizedBox(height: 12),
                                Text(
                                  "No active travel blockages",
                                  style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
                                ),
                                SizedBox(height: 4),
                                Text(
                                  "All valley networks operating clear.",
                                  style: TextStyle(color: Color(0xFF64748B), fontSize: 12),
                                  textAlign: TextAlign.center,
                                ),
                              ],
                            ),
                          )
                        : ListView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: updates.length,
                            itemBuilder: (context, index) {
                              final report = updates[index];
                              final severityColor = report.severity == 'High'
                                  ? const Color(0xFFEF4444)
                                  : report.severity == 'Medium'
                                      ? const Color(0xFFF59E0B)
                                      : const Color(0xFF10B981);

                              return Container(
                                margin: const EdgeInsets.only(bottom: 16),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(20), // 16-20 rounded corners
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.03),
                                      blurRadius: 16,
                                      spreadRadius: 0,
                                      offset: const Offset(0, 8), // Soft elegant shadow
                                    ),
                                  ],
                                  border: Border.all(color: const Color(0xFFF1F5F9), width: 1.0),
                                ),
                                child: Padding(
                                  padding: const EdgeInsets.all(18.0),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      // Top road identity & time ago
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                            decoration: BoxDecoration(
                                              color: const Color(0xFF0284C7).withOpacity(0.08),
                                              borderRadius: BorderRadius.circular(8),
                                            ),
                                            child: Text(
                                              report.roadName.split(' ')[0], // KKH / Skardu / Astore
                                              style: TextStyle(
                                                fontSize: 11,
                                                fontWeight: FontWeight.w800,
                                                color: Color(0xFF0284C7),
                                              ),
                                            ),
                                          ),
                                          Text(
                                            AppHelpers.formatTimeAgo(report.createdAt),
                                            style: const TextStyle(
                                              fontSize: 12,
                                              color: Color(0xFF94A3B8),
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 12),

                                      // Hazard title
                                      Text(
                                        "${report.hazardType} at ${report.roadName.contains('(') ? report.roadName.split('(')[0].trim() : report.roadName}",
                                        style: const TextStyle(
                                          fontSize: 15,
                                          fontWeight: FontWeight.bold,
                                          color: Color(0xFF0F172A),
                                        ),
                                      ),
                                      const SizedBox(height: 6),

                                      // Advisory description
                                      Text(
                                        report.description,
                                        style: const TextStyle(
                                          fontSize: 13,
                                          color: Color(0xFF475569),
                                          height: 1.4,
                                        ),
                                      ),
                                      const SizedBox(height: 14),

                                      // Action panel (Upvote Confirmations & Severity status badge)
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                            decoration: BoxDecoration(
                                              color: severityColor.withOpacity(0.1),
                                              borderRadius: BorderRadius.circular(30),
                                            ),
                                            child: Row(
                                              children: [
                                                Container(
                                                  width: 6,
                                                  height: 6,
                                                  decoration: BoxDecoration(color: severityColor, shape: BoxShape.circle),
                                                ),
                                                const SizedBox(width: 6),
                                                Text(
                                                  report.severity.toUpperCase(),
                                                  style: TextStyle(
                                                    fontSize: 10,
                                                    fontWeight: FontWeight.w800,
                                                    color: severityColor,
                                                    letterSpacing: 0.5,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                          ElevatedButton.icon(
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor: const Color(0xFFF1F5F9),
                                              foregroundColor: const Color(0xFF334155),
                                              elevation: 0,
                                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                              minimumSize: Size.zero,
                                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                            ),
                                            onPressed: () => reportController.upvoteReport(report.id),
                                            icon: const Icon(Icons.thumb_up_rounded, size: 12, color: Color(0xFF0284C7)),
                                            label: Text(
                                              "Confirm (${report.upvotes})",
                                              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFeatureCard(
    BuildContext context, {
    required String title,
    required String description,
    required IconData icon,
    required Color accentColor,
    bool isEmergency = false,
    int? badgeCount,
    required VoidCallback onTap,
  }) {
    return Container(
      height: 140,
      decoration: BoxDecoration(
        color: isEmergency ? accentColor : Colors.white, // Red emergency bg, white for others
        borderRadius: BorderRadius.circular(18), // 16-20 rounded corners
        border: Border.all(
          color: isEmergency ? Colors.transparent : const Color(0xFFF1F5F9),
          width: 1.0,
        ),
        boxShadow: [
          BoxShadow(
            color: isEmergency
                ? accentColor.withOpacity(0.2)
                : Colors.black.withOpacity(0.02),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(18),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(18),
          child: Padding(
            padding: const EdgeInsets.all(14.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Top Row: Styled icon and badge if present
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: isEmergency 
                            ? Colors.white.withOpacity(0.2)
                            : accentColor.withOpacity(0.08),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        icon,
                        color: isEmergency ? Colors.white : accentColor,
                        size: 24,
                      ),
                    ),
                    if (badgeCount != null && badgeCount > 0)
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: const BoxDecoration(
                          color: Color(0xFFEF4444),
                          shape: BoxShape.circle,
                        ),
                        child: Text(
                          "$badgeCount",
                          style: const TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                  ],
                ),
                // Bottom content: Title and short description
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: isEmergency ? Colors.white : const Color(0xFF0F172A),
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      description,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 10,
                        color: isEmergency
                            ? Colors.white.withOpacity(0.8)
                            : const Color(0xFF64748B),
                        height: 1.2,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

