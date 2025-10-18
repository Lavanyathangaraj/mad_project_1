import 'package:flutter/material.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Profile'),
        backgroundColor: Colors.green,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () {
              // Logout and return to login screen
              Navigator.pushReplacementNamed(context, '/login');
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ListView(
          children: [
            const CircleAvatar(
              radius: 50,
              backgroundColor: Colors.green,
              child: Icon(Icons.person, size: 60, color: Colors.white),
            ),
            const SizedBox(height: 16),
            const Center(
              child: Text(
                'Bala Pavani Lakshmi Priya Koppuravuri',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(height: 8),
            const Center(
              child: Text(
                'bkoppuravuri1@student.gsu.edu',
                style: TextStyle(color: Colors.grey),
              ),
            ),
            const Divider(height: 40, thickness: 1),

            // Token balance
            ListTile(
              leading: const Icon(Icons.token, color: Colors.green),
              title: const Text('Swap Token Balance'),
              subtitle: const Text('50 Tokens'),
              trailing: const Icon(Icons.arrow_forward_ios),
              onTap: () {
                // future navigation
              },
            ),

            // Posted items
            ListTile(
              leading: const Icon(Icons.list_alt, color: Colors.green),
              title: const Text('My Listings'),
              subtitle: const Text('View your posted items'),
              trailing: const Icon(Icons.arrow_forward_ios),
              onTap: () {
                // Navigate to user’s listings
              },
            ),

            // Wishlist
            ListTile(
              leading: const Icon(Icons.favorite, color: Colors.green),
              title: const Text('Wishlist'),
              subtitle: const Text('View your saved items'),
              trailing: const Icon(Icons.arrow_forward_ios),
              onTap: () {
                // Navigate to wishlist
              },
            ),

            // Transaction History
            ListTile(
              leading: const Icon(Icons.history, color: Colors.green),
              title: const Text('Transaction History'),
              subtitle: const Text('Track your swaps and pickups'),
              trailing: const Icon(Icons.arrow_forward_ios),
              onTap: () {
                // Navigate to transaction history
              },
            ),
          ],
        ),
      ),
    );
  }
}
