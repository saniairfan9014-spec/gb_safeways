import 'package:flutter/material.dart';

class AdminSidebar extends StatelessWidget {
  final int selectedIndex;
  final Function(int) onTap;

  const AdminSidebar({super.key, required this.selectedIndex, required this.onTap});

  final items = const [
    "Dashboard",
    "Users",
    "SOS",
    "Roads",
    "Reports"
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 220,
      color: Colors.black,
      child: Column(
        children: List.generate(items.length, (index) {
          return ListTile(
            title: Text(
              items[index],
              style: TextStyle(
                color: selectedIndex == index ? Colors.white : Colors.grey,
              ),
            ),
            onTap: () => onTap(index),
          );
        }),
      ),
    );
  }
}
