import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class CompletedJobsScreen extends StatefulWidget {
  final String providerId;

  const CompletedJobsScreen({super.key, required this.providerId});

  @override
  State<CompletedJobsScreen> createState() => _CompletedJobsScreenState();
}

class _CompletedJobsScreenState extends State<CompletedJobsScreen> {
  List completedJobs = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchCompletedJobs();
  }

  Future<void> fetchCompletedJobs() async {
    final url = Uri.parse('http://localhost:5000/provider/completed_jobs/${widget.providerId}');

    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          completedJobs = data['completed_jobs'];
          isLoading = false;
        });
      } else {
        throw Exception('Failed to load completed jobs');
      }
    } catch (e) {
      print(e);
      setState(() => isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error loading completed jobs')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Completed Jobs'),
        backgroundColor: Colors.deepPurple,
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : completedJobs.isEmpty
          ? const Center(child: Text('No completed jobs found'))
          : ListView.builder(
        itemCount: completedJobs.length,
        itemBuilder: (context, index) {
          final job = completedJobs[index];
          return Card(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: ListTile(
              title: Text(job['service_type'] ?? 'Service'),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(job['description'] ?? ''),
                  Text('Resident: ${job['first_name']} ${job['last_name']}'),
                  Text('Requested on: ${job['requested_at']?.toString().substring(0, 10)}'),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
