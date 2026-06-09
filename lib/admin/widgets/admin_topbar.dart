import 'package:flutter/material.dart';

class AdminTopbar extends StatelessWidget implements PreferredSizeWidget {
  const AdminTopbar({super.key});

  @override
  Widget build(BuildContext context) {
    return AppBar(
      title: const Text('Admin Dashboard'),
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}
