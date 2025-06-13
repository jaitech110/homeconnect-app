import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'resident_detail_screen.dart'; // 👈 import the detail screen

class ApproveResidentsScreen extends StatefulWidget {
  const ApproveResidentsScreen({super.key});

  @override
  State<ApproveResidentsScreen> createState() => _ApproveResidentsScreenState();
}

class _ApproveResidentsScreenState extends State<ApproveResidentsScreen> {
  List<Map<String, dynamic>> residents = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchPendingResidents();
  }

  Future<void> fetchPendingResidents() async {
    try {
      final response = await http.get(Uri.parse('http://192.168.18.16:5000/union/pending_residents'));
      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        setState(() {
          residents = List<Map<String, dynamic>>.from(data);
          isLoading = false;
        });
      } else {
        throw Exception('Failed to load residents');
      }
    } catch (e) {
      print('❌ Error fetching residents: $e');
      setState(() => isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error loading residents')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Approve Residents'),
        backgroundColor: Colors.deepPurple,
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : residents.isEmpty
          ? const Center(child: Text('No pending residents'))
          : ListView.builder(
        itemCount: residents.length,
        itemBuilder: (context, index) {
          final resident = residents[index];
          final cnicImageUrl = resident['cnic_image_url'];
          return Card(
            color: Colors.black,
            margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            child: ListTile(
              leading: CircleAvatar(
                radius: 30,
                backgroundColor: Colors.white,
                backgroundImage: cnicImageUrl != null && cnicImageUrl.isNotEmpty
                    ? NetworkImage(cnicImageUrl)
                    : const AssetImage('assets/images/resident.png') as ImageProvider,
              ),
              title: Text(
                '${resident['first_name']} ${resident['last_name']}',
                style: const TextStyle(color: Colors.white),
              ),
              subtitle: Text(
                'Tap to view details',
                style: const TextStyle(color: Colors.white70),
              ),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => ResidentDetailScreen(
                      residentData: resident,
                      onApproval: fetchPendingResidents,
                    ),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}
