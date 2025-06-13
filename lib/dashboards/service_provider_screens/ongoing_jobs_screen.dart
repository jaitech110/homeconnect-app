import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class OngoingJobsScreen extends StatefulWidget {
  final String providerId;
  const OngoingJobsScreen({super.key, required this.providerId});

  @override
  State<OngoingJobsScreen> createState() => _OngoingJobsScreenState();
}

class _OngoingJobsScreenState extends State<OngoingJobsScreen> {
  List<dynamic> ongoingJobs = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchOngoingJobs();
  }

  Future<void> fetchOngoingJobs() async {
    final url = Uri.parse('http://localhost:5000/provider/ongoing_jobs/${widget.providerId}');
    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          ongoingJobs = data['ongoing_jobs'];
          isLoading = false;
        });
      } else {
        throw Exception('Failed to load ongoing jobs');
      }
    } catch (e) {
      setState(() => isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  Future<void> markCompleted(int requestId) async {
    final url = Uri.parse('http://localhost:5000/provider/complete_job/$requestId');
    try {
      final response = await http.post(url);
      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Job marked as completed')),
        );
        fetchOngoingJobs();
      } else {
        throw Exception('Failed to mark job as completed');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Ongoing Jobs')),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : ongoingJobs.isEmpty
          ? const Center(child: Text('No ongoing jobs found'))
          : ListView.builder(
        itemCount: ongoingJobs.length,
        itemBuilder: (context, index) {
          final job = ongoingJobs[index];
          return Card(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: ListTile(
              title: Text('${job['service_type']} for ${job['first_name']} ${job['last_name']}'),
              subtitle: Text(job['description'] ?? ''),
              trailing: ElevatedButton(
                onPressed: () => markCompleted(job['id']),
                child: const Text('Complete'),
              ),
            ),
          );
        },
      ),
    );
  }
}
