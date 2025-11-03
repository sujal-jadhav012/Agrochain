import 'package:agrochain_app/Auth/AgroLoginScreen.dart';
import 'package:agrochain_app/Auth/signup_page.dart';
import 'package:agrochain_app/ui/Screens/farmer_dashboard_screen.dart';
import 'package:agrochain_app/ui/Screens/role_selection_page.dart';
import 'package:flutter/material.dart';

void main() {
  runApp(const AgroChainApp());
}

class AgroChainApp extends StatelessWidget {
  const AgroChainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'AgroChain',
      debugShowCheckedModeBanner: false,
      initialRoute: '/role',
      routes: {
        '/role': (context) => const RoleSelectionPage(),
        '/login': (context) => const AgroLoginScreen(),
        '/signup': (context) => const AgroSignupScreen(),
        '/farmerDashboard': (context) => const FarmerDashboardScreen(),
      },
    );
  }
}
