import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../../main.dart'; // Import for getBaseUrl function
import 'vote_detail_screen.dart'; // Import the voting detail screen

class VotingScreen extends StatefulWidget {
  final String userName;
  final String userId;  // Changed from int to String to handle UUIDs

  const VotingScreen({super.key, required this.userName, required this.userId});

  @override
  State<VotingScreen> createState() => _VotingScreenState();
}

class _VotingScreenState extends State<VotingScreen> {
  List polls = [];
  bool isLoading = true;
  String? errorMessage;

  @override
  void initState() {
    super.initState();
    fetchPolls();
  }

  Future<void> fetchPolls() async {
    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    // Use getBaseUrl() and the correct endpoint with userId
    final url = Uri.parse('${getBaseUrl()}/resident/elections?resident_id=${widget.userId}');
    
    print('🗳️ Fetching elections from: $url');

    try {
      final response = await http.get(url);
      print('📝 Election response status: ${response.statusCode}');
      print('📝 Election response body: ${response.body}');
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        print('📝 Election data: ${data['elections']}');
        setState(() {
          polls = data['elections'] ?? [];
          isLoading = false;
        });
        
        if (polls.isEmpty) {
          print('📝 No elections found for resident ${widget.userId}');
        } else {
          print('📝 Found ${polls.length} elections for resident');
        }
      } else {
        print('❌ Failed to load elections: ${response.statusCode} - ${response.body}');
        setState(() {
          isLoading = false;
          errorMessage = 'Failed to load elections: ${response.statusCode}';
        });
      }
    } catch (e) {
      print('❌ Exception in fetchPolls: $e');
      setState(() {
        isLoading = false;
        errorMessage = 'Error loading elections: $e';
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading elections: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Community Elections'),
        backgroundColor: Colors.deepPurple,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: fetchPolls,
            tooltip: 'Refresh Elections',
          ),
        ],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : errorMessage != null
          ? _buildErrorView()
          : polls.isEmpty
          ? _buildEmptyView()
          : _buildElectionsList(),
    );
  }

  Widget _buildErrorView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.error_outline,
            size: 64,
            color: Colors.red,
          ),
          const SizedBox(height: 16),
          const Text(
            'Error Loading Elections',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            errorMessage ?? 'Unknown error occurred',
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.grey),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: fetchPolls,
            icon: const Icon(Icons.refresh),
            label: const Text('Try Again'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.deepPurple,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.how_to_vote_outlined,
            size: 64,
            color: Colors.grey,
          ),
          const SizedBox(height: 16),
          const Text(
            'No Active Elections',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          const Text(
            'There are no elections available for voting at the moment.\nCheck back later or contact your Union Incharge.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: fetchPolls,
            icon: const Icon(Icons.refresh),
            label: const Text('Check for New Elections'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.deepPurple,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildElectionsList() {
    return RefreshIndicator(
      onRefresh: fetchPolls,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: polls.length,
        itemBuilder: (context, index) {
          final poll = polls[index];
          final hasVoted = poll['has_voted'] ?? false;
          final resultsPublished = poll['results_published'] ?? false;
          final title = poll['title'] ?? 'Election';
          final description = poll['description'] ?? '';
          final createdBy = poll['created_by'] ?? 'Union Incharge';
          final createdAt = poll['created_at'] ?? '';
          
          return Card(
            margin: const EdgeInsets.only(bottom: 16),
            elevation: 3,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: InkWell(
              onTap: () async {
                // Navigate to VoteDetailScreen for voting
                final result = await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => VoteDetailScreen(
                      userId: widget.userId,
                      election: poll,
                    ),
                  ),
                );
                
                // Refresh polls list if vote was cast
                if (result == true) {
                  fetchPolls();
                }
              },
              borderRadius: BorderRadius.circular(12),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          hasVoted 
                            ? (resultsPublished ? Icons.poll : Icons.access_time)
                            : Icons.how_to_vote,
                          color: hasVoted 
                            ? (resultsPublished ? Colors.green : Colors.orange)
                            : Colors.deepPurple,
                          size: 24,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            title,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: hasVoted 
                              ? (resultsPublished ? Colors.green : Colors.orange)
                              : Colors.deepPurple,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            hasVoted 
                              ? (resultsPublished ? 'Results Available' : 'Voted')
                              : 'Active',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                    if (description.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Text(
                        description,
                        style: const TextStyle(
                          color: Colors.grey,
                          fontSize: 14,
                        ),
                      ),
                    ],
                    const SizedBox(height: 12),
                    if (hasVoted) ...[
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.check_circle,
                              color: Colors.green,
                              size: 20,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'You voted: ${poll['selected_choice'] ?? 'Unknown'}',
                                style: const TextStyle(
                                  fontWeight: FontWeight.w500,
                                  color: Colors.black87,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ] else ...[
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.deepPurple.shade50,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.how_to_vote,
                              color: Colors.deepPurple,
                              size: 20,
                            ),
                            const SizedBox(width: 8),
                            const Expanded(
                              child: Text(
                                'Tap to cast your vote',
                                style: TextStyle(
                                  fontWeight: FontWeight.w500,
                                  color: Colors.deepPurple,
                                ),
                              ),
                            ),
                            const Icon(
                              Icons.arrow_forward_ios,
                              color: Colors.deepPurple,
                              size: 16,
                            ),
                          ],
                        ),
                      ),
                    ],
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(Icons.person, color: Colors.grey.shade600, size: 16),
                        const SizedBox(width: 4),
                        Text(
                          'Created by: $createdBy',
                          style: TextStyle(
                            color: Colors.grey.shade600,
                            fontSize: 12,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Icon(Icons.access_time, color: Colors.grey.shade600, size: 16),
                        const SizedBox(width: 4),
                        Text(
                          createdAt.isNotEmpty ? createdAt.split('T')[0] : 'Unknown',
                          style: TextStyle(
                            color: Colors.grey.shade600,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
