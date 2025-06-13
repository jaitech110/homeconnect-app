import 'package:flutter/material.dart';
import 'package:homeconnect_app/main.dart';

class UnionScreenDashboard extends StatefulWidget {
  final int userId;
  
  const UnionScreenDashboard({Key? key, required this.userId}) : super(key: key);

  @override
  State<UnionScreenDashboard> createState() => _UnionScreenDashboardState();
}

class _UnionScreenDashboardState extends State<UnionScreenDashboard> {
  int _selectedIndex = 0;
  late List<Widget> _pages;
  
  @override
  void initState() {
    super.initState();
    _pages = [
      // Add your other pages here
      // Example:
      // HomeScreen(),
      // SettingsScreen(),
      const Center(child: Text('Welcome to Union Dashboard')), // Placeholder
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Union Dashboard'),
        backgroundColor: Colors.deepPurple,
      ),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            const DrawerHeader(
              decoration: BoxDecoration(
                color: Colors.deepPurple,
              ),
              child: Text(
                'Menu',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                ),
              ),
            ),
            // Add logout option
            ListTile(
              leading: const Icon(Icons.logout),
              title: const Text('Logout'),
              onTap: () {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (_) => LoginPage()),
                );
              },
            ),
          ],
        ),
      ),
      body: _pages[_selectedIndex],
    );
  }
} 