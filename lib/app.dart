import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'core/services/notification_service.dart';
import 'features/auth/controller/auth_controller.dart';
import 'features/roads/controller/road_controller.dart';
import 'features/reports/controller/report_controller.dart';
import 'features/emergency/controller/emergency_controller.dart';
import 'features/emergency/controller/sos_controller.dart';
import 'features/settings/controller/settings_controller.dart';
import 'routes/app_routes.dart';
import 'routes/route_names.dart';
import 'shared/theme/app_theme.dart';

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthController()),
        ChangeNotifierProvider(create: (_) => RoadController()),
        ChangeNotifierProvider(create: (_) => ReportController()),
        ChangeNotifierProvider(create: (_) => EmergencyController()),
        ChangeNotifierProvider(create: (_) => SosController()),
        ChangeNotifierProvider(create: (_) => SettingsController()),
      ],
      child: Consumer<SettingsController>(
        builder: (context, settingsController, _) {
          return MaterialApp(
            title: 'GB Safeway Alert',
            theme: AppTheme.lightTheme,
            darkTheme: AppTheme.darkTheme,
            themeMode: settingsController.isDarkMode ? ThemeMode.dark : ThemeMode.light,
            scaffoldMessengerKey: NotificationService.instance.messengerKey,
            initialRoute: RouteNames.initial,
            onGenerateRoute: AppRoutes.generateRoute,
            debugShowCheckedModeBanner: false,
          );
        },
      ),
    );
  }
}
