import 'package:flutter/material.dart';
import '../features/auth/view/login_screen.dart';
import '../features/auth/view/signup_screen.dart';
import '../features/home/view/home_screen.dart';
import '../features/auth/view/profile_screen.dart';
import '../features/roads/view/road_status_screen.dart';
import '../features/reports/view/report_screen.dart';
import '../features/reports/view/alerts_screen.dart';
import '../features/emergency/view/emergency_screen.dart';
import 'route_names.dart';

class AppRoutes {
  AppRoutes._();

  static Route<dynamic> generateRoute(RouteSettings settings) {
    switch (settings.name) {
      case RouteNames.initial:
        // By default, home screen will handle checking auth session,
        // returning login if not authenticated, or the dashboard.
        return MaterialPageRoute(builder: (_) => const HomeScreen());
      
      case RouteNames.login:
        return MaterialPageRoute(builder: (_) => const LoginScreen());
      
      case RouteNames.signup:
        return MaterialPageRoute(builder: (_) => const SignupScreen());


      case RouteNames.home:
        return MaterialPageRoute(builder: (_) => const HomeScreen());

      case RouteNames.roadStatus:
        return MaterialPageRoute(builder: (_) => const RoadStatusScreen());

      case RouteNames.addReport:
        return MaterialPageRoute(builder: (_) => const ReportScreen());

      case RouteNames.emergency:
        return MaterialPageRoute(builder: (_) => const EmergencyScreen());

      case RouteNames.alerts:
        return MaterialPageRoute(builder: (_) => const AlertsScreen());

      case RouteNames.profile:
        return MaterialPageRoute(builder: (_) => const ProfileScreen());

      default:
        return MaterialPageRoute(
          builder: (_) => Scaffold(
            body: Center(
              child: Text('No route defined for ${settings.name}'),
            ),
          ),
        );
    }
  }
}
