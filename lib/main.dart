import 'package:flutter/material.dart';
import 'screens/login_screen.dart';
import 'screens/item_listings_screen.dart';
import 'screens/profile_screen.dart';

void main() {
  runApp(const CampusSwapApp());
}

class CampusSwapApp extends StatelessWidget {
  const CampusSwapApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Campus Swap & Freecycle',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(primarySwatch: Colors.green),
      initialRoute: '/login',
      routes: {
        '/login': (context) => const LoginScreen(),
        '/home': (context) => const ItemListingsScreen(),
        '/profile': (context) => const ProfileScreen(),
      },
    );
  }
}
