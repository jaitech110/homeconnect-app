import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../../main.dart'; // Import for getBaseUrl function

class VoteDetailScreen extends StatefulWidget {
  final String userId;
  final Map<String, dynamic> election;
  
  const VoteDetailScreen({
    super.key, 
    required this.userId, 
    required this.election
  });

  @override
  State<VoteDetailScreen> createState() => _VoteDetailScreenState();
}

class _VoteDetailScreenState extends State<VoteDetailScreen> {
  String? selectedChoice;
  bool isSubmitting = false;
  
  @override
  void initState() {
    super.initState();
    
    // Set initial value if user has already voted
    if (widget.election['has_voted'] == true) {
      selectedChoice = widget.election['selected_choice'];
    }
  }
  
  Future<void> submitVote() async {
    if (selectedChoice == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select an option to vote')),
      );
      return;
    }
    
    setState(() => isSubmitting = true);
    
    final url = Uri.parse('${getBaseUrl()}/resident/vote');
    
    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'resident_id': widget.userId,
          'election_id': widget.election['id'],
          'choice': selectedChoice,
        }),
      );
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(data['message'] ?? 'Vote submitted successfully')),
        );
        Navigator.pop(context, true); // Return true to indicate success
      } else {
        final data = jsonDecode(response.body);
        throw Exception(data['error'] ?? 'Failed to submit vote');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    } finally {
      setState(() => isSubmitting = false);
    }
  }
  
  @override
  Widget build(BuildContext context) {
    final bool hasVoted = widget.election['has_voted'] ?? false;
    final bool resultsPublished = widget.election['results_published'] ?? false;
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Cast Your Vote'),
        backgroundColor: Colors.deepPurple,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Election title
            Card(
              elevation: 4,
              margin: const EdgeInsets.only(bottom: 24),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.election['title'] ?? 'Election',
                      style: const TextStyle(
                        fontSize: 22, 
                        fontWeight: FontWeight.bold
                      ),
                    ),
                    if (hasVoted)
                      Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Text(
                          'You voted: ${widget.election['selected_choice']}',
                          style: const TextStyle(
                            color: Colors.green,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
            
            const Text(
              'Select your choice:',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            
            // Election choices
            ...List.generate(
              (widget.election['choices'] as List? ?? []).length,
              (index) {
                final choice = (widget.election['choices'] as List)[index];
                return Card(
                  elevation: 2,
                  margin: const EdgeInsets.only(bottom: 12),
                  child: RadioListTile<String>(
                    title: Text(choice),
                    value: choice,
                    groupValue: selectedChoice,
                    onChanged: hasVoted 
                      ? null // Disable if already voted
                      : (value) {
                          setState(() => selectedChoice = value);
                        },
                    activeColor: Colors.deepPurple,
                  ),
                );
              },
            ),
            
            const SizedBox(height: 24),
            
            // Submit button
            if (!hasVoted)
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: isSubmitting ? null : submitVote,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.deepPurple,
                  ),
                  child: isSubmitting
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text(
                        'Submit Vote',
                        style: TextStyle(fontSize: 16),
                      ),
                ),
              ),
              
            // Results section if published
            if (resultsPublished)
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Divider(height: 40),
                  const Text(
                    'Results:',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  
                  if (widget.election['results'] != null)
                    ...List.generate(
                      (widget.election['results'] as Map).length,
                      (index) {
                        final entry = (widget.election['results'] as Map).entries.elementAt(index);
                        final choice = entry.key;
                        final votes = entry.value;
                        final totalVotes = widget.election['total_votes'] ?? 1;
                        
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '$choice: $votes votes',
                                style: TextStyle(
                                  fontWeight: choice == widget.election['selected_choice'] 
                                    ? FontWeight.bold 
                                    : FontWeight.normal,
                                ),
                              ),
                              const SizedBox(height: 4),
                              LinearProgressIndicator(
                                value: totalVotes > 0 ? votes / totalVotes : 0,
                                backgroundColor: Colors.grey[300],
                                color: Colors.deepPurple,
                                minHeight: 10,
                              ),
                            ],
                          ),
                        );
                      },
                    )
                  else
                    const Text('Results will be available soon'),
                ],
              ),
          ],
        ),
      ),
    );
  }
} 