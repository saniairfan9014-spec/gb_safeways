import 'package:flutter/material.dart';
import '../services/dashboard_service.dart';

class DashboardProvider extends ChangeNotifier {
  final service = DashboardService();

  int users = 0;
  int sos = 0;
  int roads = 0;
  int reports = 0;

  bool loading = true;

  Future<void> loadData() async {
    loading = true;
    notifyListeners();

    users = await service.getUsersCount();
    sos = await service.getSosCount();
    roads = await service.getRoadsCount();
    reports = await service.getReportsCount();

    loading = false;
    notifyListeners();
  }
}
