import 'package:flutter/material.dart';

class ItemListingsScreen extends StatelessWidget {
  const ItemListingsScreen({super.key});

  final List<Map<String, String>> items = const [
    {
      'title': 'Textbook - Math 101',
      'description': 'Used, good condition',
    },
    {
      'title': 'Desk Chair',
      'description': 'Comfortable, minor scratches',
    },
    {
      'title': 'Laptop Stand',
      'description': 'Metal, adjustable height',
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Items Available"),
        backgroundColor: Colors.green,
        actions: [
          IconButton(
            icon: const Icon(Icons.person),
            onPressed: () {
              Navigator.pushNamed(context, '/profile');
            },
          ),
        ],
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(10),
        itemCount: items.length,
        itemBuilder: (context, index) {
          final item = items[index];
          return Card(
            margin: const EdgeInsets.symmetric(vertical: 8),
            child: ListTile(
              title: Text(item['title']!),
              subtitle: Text(item['description']!),
              trailing: const Icon(Icons.arrow_forward_ios),
              onTap: () {
                // TODO: Navigate to item details screen
              },
            ),
          );
        },
      ),
    );
  }
}
