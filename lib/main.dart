// main.dart
import 'package:flutter/material.dart';
import 'screens/kitchen_dashboard.dart';
import 'config/app_theme.dart';

void main() => runApp(BarajaKitchenApp());

class BarajaKitchenApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Baraja Kitchen',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.theme,
      home: KitchenDashboard(),
    );
  }
}