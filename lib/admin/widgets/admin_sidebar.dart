import 'package:flutter/material.dart';

class AdminSidebar extends StatelessWidget {
  const AdminSidebar({super.key});

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: ListView(
        children: const [
          DrawerHeader(
            child: Text('Admin Panel'),
          ),
          ListTile(title: Text('Dashboard')),
        ],
      ),
    );
  }
}
