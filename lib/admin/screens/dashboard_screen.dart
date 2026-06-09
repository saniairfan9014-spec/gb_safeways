import 'package:flutter/material.dart';
import '../widgets/admin_sidebar.dart';
import '../widgets/admin_topbar.dart';
import '../widgets/dashboard_card.dart';
import '../providers/dashboard_provider.dart';
import 'users_screen.dart';
import 'sos_screen.dart';
import 'roads_screen.dart';
import 'reports_screen.dart';

class DashboardHome extends StatefulWidget {
  const DashboardHome({super.key});

  @override
  State<DashboardHome> createState() => _DashboardHomeState();
}

class _DashboardHomeState extends State<DashboardHome> {
  final provider = DashboardProvider();

  @override
  void initState() {
    super.initState();
    provider.addListener(() {
      if (mounted) setState(() {});
    });
    provider.loadData();
  }

  @override
  void dispose() {
    provider.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (provider.loading) {
      return const Center(child: CircularProgressIndicator());
    }

    return Padding(
      padding: const EdgeInsets.all(20),
      child: GridView.count(
        crossAxisCount: 4,
        crossAxisSpacing: 15,
        mainAxisSpacing: 15,
        childAspectRatio: 2.5,
        children: [
          DashboardCard(
            title: "Total Users",
            value: provider.users.toString(),
            icon: Icons.people,
            color: Colors.blue,
          ),
          DashboardCard(
            title: "SOS Alerts",
            value: provider.sos.toString(),
            icon: Icons.warning,
            color: Colors.red,
          ),
          DashboardCard(
            title: "Roads",
            value: provider.roads.toString(),
            icon: Icons.edit_road,
            color: Colors.orange,
          ),
          DashboardCard(
            title: "Reports",
            value: provider.reports.toString(),
            icon: Icons.report,
            color: Colors.green,
          ),
        ],
      ),
    );
  }
}

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  int selectedIndex = 0;

  final screens = const [
    DashboardHome(),
    UsersScreen(),
    SosScreen(),
    RoadsScreen(),
    ReportsScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Row(
        children: [
          AdminSidebar(
            selectedIndex: selectedIndex,
            onTap: (index) {
              setState(() {
                selectedIndex = index;
              });
            },
          ),
          Expanded(
            child: Column(
              children: [
                const AdminTopbar(),
                Expanded(
                  child: screens[selectedIndex],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
