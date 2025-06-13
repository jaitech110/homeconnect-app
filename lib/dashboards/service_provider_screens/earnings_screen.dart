import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class EarningsScreen extends StatefulWidget {
  final String providerId;

  const EarningsScreen({super.key, required this.providerId});

  @override
  State<EarningsScreen> createState() => _EarningsScreenState();
}

class _EarningsScreenState extends State<EarningsScreen> {
  double totalEarnings = 0.0;
  List<dynamic> jobs = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchEarnings();
  }

  Future<void> fetchEarnings() async {
    final url = Uri.parse('http://localhost:5000/provider/earnings/${widget.providerId}');

    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          totalEarnings = data['total_earnings'] ?? 0.0;
          jobs = data['jobs'] ?? [];
          isLoading = false;
        });
      } else {
        throw Exception("Failed to load earnings");
      }
    } catch (e) {
      setState(() => isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error: ${e.toString()}")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Earnings"), backgroundColor: Colors.deepPurple),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              "Total Earnings: Rs. ${totalEarnings.toStringAsFixed(2)}",
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ),
          const Divider(),
          Expanded(
            child: jobs.isEmpty
                ? const Center(child: Text("No completed jobs yet."))
                : ListView.builder(
              itemCount: jobs.length,
              itemBuilder: (context, index) {
                final job = jobs[index];
                return Card(
                  margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  child: ListTile(
                    title: Text(job['service_type'] ?? ''),
                    subtitle: Text(job['description'] ?? ''),
                    trailing: Text("Rs. ${job['amount'] ?? 0}"),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
