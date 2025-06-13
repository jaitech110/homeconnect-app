import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../../main.dart'; // Import for getBaseUrl function

class HandleComplaintsScreen extends StatefulWidget {
  const HandleComplaintsScreen({super.key});

  @override
  State<HandleComplaintsScreen> createState() => _HandleComplaintsScreenState();
}

class _HandleComplaintsScreenState extends State<HandleComplaintsScreen> {
  List complaints = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchComplaints();
  }

  Future<void> fetchComplaints() async {
    final url = Uri.parse('${getBaseUrl()}/union/complaints');

    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        setState(() {
          complaints = jsonDecode(response.body);
          isLoading = false;
        });
      } else {
        throw Exception('Failed to load complaints');
      }
    } catch (e) {
      setState(() => isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: ${e.toString()}')),
      );
    }
  }

  Future<void> resolveComplaint(int id) async {
    final url = Uri.parse('${getBaseUrl()}/union/resolve_complaint/$id');
    try {
      final response = await http.post(url);
      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Complaint resolved')),
        );
        fetchComplaints();
      } else {
        throw Exception('Failed to resolve complaint');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: ${e.toString()}')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Handle Complaints'),
        backgroundColor: Colors.deepPurple,
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : complaints.isEmpty
          ? const Center(child: Text('No complaints available'))
          : ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: complaints.length,
        itemBuilder: (context, index) {
          final complaint = complaints[index];
          return Card(
            elevation: 2,
            margin: const EdgeInsets.symmetric(vertical: 8),
            child: ListTile(
              title: Text('Category: ${complaint['category']}'),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Description: ${complaint['description']}'),
                  Text('Status: ${complaint['status']}')
                ],
              ),
              trailing: ElevatedButton(
                onPressed: () => resolveComplaint(complaint['id']),
                style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                child: const Text('Resolve'),
              ),
            ),
          );
        },
      ),
    );
  }
}
