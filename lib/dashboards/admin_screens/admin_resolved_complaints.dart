import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class AdminResolvedComplaintsScreen extends StatefulWidget {
  const AdminResolvedComplaintsScreen({super.key});

  @override
  State<AdminResolvedComplaintsScreen> createState() => _AdminResolvedComplaintsScreenState();
}

class _AdminResolvedComplaintsScreenState extends State<AdminResolvedComplaintsScreen> {
  final List<Map<String, dynamic>> resolvedComplaints = [
    {
      'title': 'Water Leakage in Basement',
      'submittedBy': 'Union Incharge - Block A',
      'resolvedAt': DateTime.now().subtract(Duration(days: 1)),
    },
    {
      'title': 'Security Light Issue',
      'submittedBy': 'Service Provider - Electrician',
      'resolvedAt': DateTime.now().subtract(Duration(days: 2)),
    },
    {
      'title': 'Uncollected Trash',
      'submittedBy': 'Union Incharge - Block B',
      'resolvedAt': DateTime.now().subtract(Duration(days: 4)),
    },
  ];

  @override
  void initState() {
    super.initState();
    _cleanUpOldResolvedComplaints();
  }

  void _cleanUpOldResolvedComplaints() {
    final now = DateTime.now();
    resolvedComplaints.removeWhere((complaint) =>
    now.difference(complaint['resolvedAt']).inDays >= 3);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Resolved Complaints'),
        backgroundColor: Colors.deepPurple,
      ),
      body: resolvedComplaints.isEmpty
          ? const Center(child: Text('No resolved complaints to display.'))
          : ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: resolvedComplaints.length,
        itemBuilder: (context, index) {
          final complaint = resolvedComplaints[index];
          return Card(
            elevation: 3,
            margin: const EdgeInsets.symmetric(vertical: 8),
            child: ListTile(
              leading: const Icon(Icons.check_circle, color: Colors.green),
              title: Text(complaint['title']),
              subtitle: Text(
                '${complaint['submittedBy']}\nResolved on: ${DateFormat.yMMMd().format(complaint['resolvedAt'])}',
              ),
            ),
          );
        },
      ),
    );
  }
}