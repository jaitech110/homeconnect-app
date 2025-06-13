import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../../main.dart';

class MaintenanceApprovalScreen extends StatefulWidget {
  final int userId;
  
  const MaintenanceApprovalScreen({
    super.key, 
    required this.userId,
  });

  @override
  State<MaintenanceApprovalScreen> createState() => _MaintenanceApprovalScreenState();
}

class _MaintenanceApprovalScreenState extends State<MaintenanceApprovalScreen> {
  List<Map<String, dynamic>> pendingPayments = [];
  bool isLoading = false;
  String? errorMessage;

  @override
  void initState() {
    super.initState();
    // Not fetching pending payments since systems are disconnected
  }

  Future<void> fetchPendingPayments() async {
    // This method is now a placeholder since systems are disconnected
    setState(() {
      isLoading = false;
      pendingPayments = [];
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Maintenance Payments'),
        backgroundColor: Colors.deepPurple,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.sync_disabled,
              size: 80,
              color: Colors.grey,
            ),
            const SizedBox(height: 20),
            const Text(
              'System Disconnected',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 40),
              child: Text(
                'The resident maintenance payment system is currently disconnected from the union incharge system.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
