import 'package:flutter/material.dart';

class AdminTopbar extends StatelessWidget {
  const AdminTopbar({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 60,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      color: Colors.white,
      child: const Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            "Admin Dashboard",
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          CircleAvatar(
            child: Icon(Icons.person),
          )
        ],
      ),
    );
  }
}
