import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../../main.dart'; // Import for getBaseUrl function

class RateResidentsScreen extends StatefulWidget {
  final String providerId;
  const RateResidentsScreen({super.key, required this.providerId});

  @override
  State<RateResidentsScreen> createState() => _RateResidentsScreenState();
}

class _RateResidentsScreenState extends State<RateResidentsScreen> {
  List<dynamic> residents = [];
  bool isLoading = true;
  final Map<int, double> ratings = {};
  final Map<int, TextEditingController> reviewControllers = {};

  @override
  void initState() {
    super.initState();
    fetchResidents();
  }

  Future<void> fetchResidents() async {
    final url = Uri.parse('${getBaseUrl()}/provider/completed_jobs/${widget.providerId}');

    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          residents = data['completed_jobs'];
          for (var r in residents) {
            reviewControllers[r['id']] = TextEditingController();
          }
          isLoading = false;
        });
      } else {
        throw Exception('Failed to load residents');
      }
    } catch (e) {
      setState(() => isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading residents: $e')),
      );
    }
  }

  Future<void> submitRating(int residentId, int requestId) async {
    final url = Uri.parse('${getBaseUrl()}/provider/rate_resident');
    final rating = ratings[requestId];
    final review = reviewControllers[requestId]?.text ?? '';

    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'provider_id': widget.providerId,
        'resident_id': residentId,
        'rating': rating,
        'review': review,
      }),
    );

    if (response.statusCode == 201) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Rating submitted!')),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed: ${response.body}')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Rate Residents')),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: residents.length,
        itemBuilder: (context, index) {
          final r = residents[index];
          final residentName = "${r['first_name']} ${r['last_name']}";
          final requestId = r['id'];

          return Card(
            elevation: 2,
            margin: const EdgeInsets.symmetric(vertical: 10),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(residentName,
                      style: const TextStyle(
                          fontSize: 16, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Row(
                    children: List.generate(5, (star) {
                      return IconButton(
                        icon: Icon(
                          (ratings[requestId] ?? 0) > star
                              ? Icons.star
                              : Icons.star_border,
                          color: Colors.orange,
                        ),
                        onPressed: () {
                          setState(() {
                            ratings[requestId] = star + 1.0;
                          });
                        },
                      );
                    }),
                  ),
                  TextField(
                    controller: reviewControllers[requestId],
                    decoration:
                    const InputDecoration(labelText: 'Write a review'),
                  ),
                  const SizedBox(height: 10),
                  ElevatedButton(
                    onPressed: () => submitRating(r['id'], requestId),
                    child: const Text('Submit'),
                  )
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
