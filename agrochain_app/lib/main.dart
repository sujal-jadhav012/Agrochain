import 'package:agrochain_app/Auth/signup_page.dart';
import 'package:agrochain_app/firebase_options.dart';
import 'package:agrochain_app/ui/Screens/consumer_dashboard_screen.dart';
import 'package:agrochain_app/ui/Screens/distributor_dashboard_screen.dart';
import 'package:agrochain_app/ui/Screens/retailer_dashboard_screen.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:agrochain_app/Auth/AgroLoginScreen.dart';

import 'package:agrochain_app/ui/Screens/farmer_dashboard_screen.dart';
import 'package:agrochain_app/ui/Screens/role_selection_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase safely
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

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
        // ✅ Main routes setup
        '/role': (context) => const RoleSelectionPage(),
        '/login': (context) => const AgroLoginScreen(),

        // ✅ Signup route (no direct role here)
        '/signup': (context) => const AgroSignupScreen(),

        // ✅ Farmer Dashboard route
        '/farmerDashboard': (context) => const FarmerDashboardScreen(),

        '/distributorDashboard': (context) => const DistributorDashboardScreen(),

        '/retailerDashboard': (context) => const RetailerDashboardScreen(),

       '/consumerDashboard': (context) => ConsumerTraceScreen(),
      },
    );
  }
}

