import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../../../main.dart';

class ResidentElectionsScreen extends StatefulWidget {
  final String residentId;
  
  const ResidentElectionsScreen({
    super.key,
    required this.residentId,
  });

  @override
  State<ResidentElectionsScreen> createState() => _ResidentElectionsScreenState();
}

class _ResidentElectionsScreenState extends State<ResidentElectionsScreen> {
  List<dynamic> _elections = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _fetchElections();
  }

  Future<void> _fetchElections() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final response = await http.get(
        Uri.parse('${getBaseUrl()}/resident/elections?resident_id=${widget.residentId}'),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        print('📊 Elections data: ${data['elections']}'); // Debug print
        
        final allElections = List<dynamic>.from(data['elections'] ?? []);
        
        // Separate active elections and published results
        final activeElections = allElections.where((election) => 
          election['status'] == 'active' || election['status'] == 'ongoing'
        ).toList();
        
        final publishedResults = allElections.where((election) =>
          election['status'] == 'published' && 
          election['results_published'] == true &&
          !(election['acknowledgments']?.containsKey(widget.residentId) ?? false)
        ).toList();
        
        setState(() {
          _elections = [...activeElections, ...publishedResults];
          _isLoading = false;
        });
        
        // Debug - check if any elections were received
        if (_elections.isEmpty) {
          print('⚠️ No elections found for resident ID: ${widget.residentId}');
        } else {
          print('✅ Found ${_elections.length} elections for resident (${activeElections.length} active, ${publishedResults.length} published results)');
        }
      } else {
        final error = jsonDecode(response.body)['error'] ?? 'Failed to load elections';
        setState(() {
          _error = error;
          _isLoading = false;
        });
        print('❌ Error loading elections: $error');
      }
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
      print('❌ Exception in _fetchElections: $e');
    }
  }

  Future<void> _submitVote(String electionId, String choice) async {
    try {
      print('🗳️ Submitting vote: electionId=$electionId, choice=$choice, residentId=${widget.residentId}');
      
      final response = await http.post(
        Uri.parse('${getBaseUrl()}/resident/vote'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'election_id': electionId,
          'resident_id': widget.residentId,
          'choice': choice,
        }),
      );

      print('📤 Vote submission response: ${response.statusCode} - ${response.body}');

      if (response.statusCode == 201) {
        // Refresh elections to update UI
        _fetchElections();
        
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Vote submitted successfully'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        final error = jsonDecode(response.body)['error'] ?? 'Failed to submit vote';
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(error),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      print('❌ Exception in _submitVote: $e');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString()),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _acknowledgeResults(String electionId) async {
    try {
      print('✅ Acknowledging results for election: $electionId, resident: ${widget.residentId}');
      
      final response = await http.post(
        Uri.parse('${getBaseUrl()}/resident/elections/$electionId/acknowledge'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'resident_id': widget.residentId,
        }),
      );

      print('📤 Acknowledge response: ${response.statusCode} - ${response.body}');

      if (response.statusCode == 200) {
        // Remove the election from local list
        setState(() {
          _elections.removeWhere((e) => e['id'].toString() == electionId);
        });
        
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Thank you for reviewing the results!'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        final error = jsonDecode(response.body)['error'] ?? 'Failed to acknowledge results';
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(error),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      print('❌ Exception in _acknowledgeResults: $e');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _showVotingDialog(Map<String, dynamic> election) {
    if (election['has_voted']) {
      _showResultsDialog(election);
      return;
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(election['title']),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Please select your choice:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            ...election['choices'].map<Widget>((choice) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context);
                    _submitVote(election['id'].toString(), choice);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.deepPurple,
                  ),
                  child: Text(choice),
                ),
              );
            }).toList(),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }

  void _showResultsDialog(Map<String, dynamic> election) {
    final bool isPublishedResult = election['status'] == 'published';
    final bool resultsPublished = election['results_published'] == true;
    final bool hasVoted = election['has_voted'] == true;
    
    // Show results if it's a published election OR if results are published for a voted election
    if (!isPublishedResult && !resultsPublished) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Results have not been published yet'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    // Determine if this should show the acknowledge button (OK button)
    final bool shouldShowAcknowledgeButton = isPublishedResult || (resultsPublished && hasVoted);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(election['title']),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (hasVoted && !isPublishedResult) ...[
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.green.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.green.withOpacity(0.3)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.check_circle, color: Colors.green, size: 20),
                      const SizedBox(width: 8),
                      Text(
                        'Your Choice: ${election['selected_choice']}',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
              ],
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.poll, color: Colors.blue, size: 20),
                        const SizedBox(width: 8),
                        const Text(
                          'Election Results',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    ...election['results'].entries.map<Widget>((entry) {
                      final voteCount = entry.value is int ? entry.value : 0;
                      final totalVotes = election['total_votes'] is int ? election['total_votes'] : 0;
                      final percentage = totalVotes > 0 
                          ? (voteCount / totalVotes * 100).toStringAsFixed(1)
                          : '0.0';
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '${entry.key}: $voteCount votes ($percentage%)',
                              style: const TextStyle(fontWeight: FontWeight.w600),
                            ),
                            const SizedBox(height: 4),
                            LinearProgressIndicator(
                              value: totalVotes > 0 ? (voteCount / totalVotes) : 0,
                              backgroundColor: Colors.grey[300],
                              valueColor: AlwaysStoppedAnimation<Color>(Colors.deepPurple),
                              minHeight: 8,
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                    const Divider(),
                    Text(
                      'Total Votes: ${election['total_votes']}',
                      style: const TextStyle(fontWeight: FontWeight.w500, color: Colors.grey, fontSize: 14),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        actions: [
          if (shouldShowAcknowledgeButton) ...[
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Close'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                // Call acknowledge function for published results
                _acknowledgeResults(election['id'].toString());
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.deepPurple,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
              child: const Text('OK', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ] else ...[
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Close'),
            ),
          ],
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isLargeScreen = screenWidth > 800;
    final maxWidth = screenWidth > 1200 ? 900.0 : screenWidth > 800 ? 700.0 : screenWidth;
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Community Elections'),
        backgroundColor: Colors.deepPurple,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _fetchElections,
            tooltip: 'Refresh Elections',
          ),
        ],
      ),
      body: Center(
        child: Container(
          constraints: BoxConstraints(maxWidth: maxWidth),
          child: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _error != null
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.error_outline, size: 48, color: Colors.red),
                          const SizedBox(height: 16),
                          Text(
                            'Error loading elections',
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            _error!,
                            style: Theme.of(context).textTheme.bodyMedium,
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 24),
                          ElevatedButton.icon(
                            onPressed: _fetchElections,
                            icon: const Icon(Icons.refresh),
                            label: const Text('Try Again'),
                          ),
                        ],
                      ),
                    )
                  : _elections.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.how_to_vote_outlined, size: 64, color: Colors.grey),
                              const SizedBox(height: 16),
                              Text(
                                'No Active Elections',
                                style: Theme.of(context).textTheme.titleLarge,
                              ),
                              const SizedBox(height: 8),
                              const Text(
                                'There are no active elections at the moment',
                                style: TextStyle(color: Colors.grey),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        )
                      : ListView.builder(
                          itemCount: _elections.length,
                          padding: EdgeInsets.all(isLargeScreen ? 24 : 16),
                          itemBuilder: (context, index) {
                            final election = _elections[index];
                            final hasVoted = election['has_voted'] == true;
                            final resultsPublished = election['results_published'] == true;
                            final isPublishedResult = election['status'] == 'published';
                            
                            String subtitle;
                            Icon trailingIcon;
                            Color? cardColor;
                            
                            if (isPublishedResult) {
                              subtitle = 'Results Published - Tap to view and acknowledge';
                              trailingIcon = Icon(Icons.poll, color: Colors.blue, size: 24);
                              cardColor = Colors.blue.shade50;
                            } else if (hasVoted) {
                              if (resultsPublished) {
                                subtitle = 'You voted: ${election['selected_choice']} - Results available!';
                                trailingIcon = Icon(Icons.check_circle, color: Colors.green, size: 24);
                                cardColor = Colors.green.shade50;
                              } else {
                                subtitle = 'You voted: ${election['selected_choice']} - Awaiting results';
                                trailingIcon = Icon(Icons.access_time, color: Colors.orange, size: 24);
                              }
                            } else {
                              subtitle = 'Tap to vote';
                              trailingIcon = Icon(Icons.how_to_vote, color: Colors.deepPurple, size: 24);
                            }
                            
                            return Card(
                              margin: EdgeInsets.only(bottom: isLargeScreen ? 20 : 16),
                              color: cardColor,
                              elevation: isPublishedResult ? 4 : 2,
                              child: InkWell(
                                onTap: () => _showVotingDialog(election),
                                borderRadius: BorderRadius.circular(8),
                                child: Padding(
                                  padding: EdgeInsets.all(isLargeScreen ? 20 : 16),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Expanded(
                                            child: Text(
                                              election['title'],
                                              style: TextStyle(
                                                fontWeight: isPublishedResult ? FontWeight.bold : FontWeight.w600,
                                                fontSize: isLargeScreen ? 18 : 16,
                                                color: isPublishedResult ? Colors.blue.shade800 : null,
                                              ),
                                            ),
                                          ),
                                          trailingIcon,
                                        ],
                                      ),
                                      const SizedBox(height: 8),
                                      Text(
                                        subtitle,
                                        style: TextStyle(
                                          color: Colors.grey.shade600,
                                          fontSize: isLargeScreen ? 16 : 14,
                                        ),
                                      ),
                                      if (isPublishedResult) ...[
                                        const SizedBox(height: 8),
                                        Container(
                                          padding: EdgeInsets.symmetric(
                                            horizontal: isLargeScreen ? 12 : 8, 
                                            vertical: isLargeScreen ? 6 : 4,
                                          ),
                                          decoration: BoxDecoration(
                                            color: Colors.blue,
                                            borderRadius: BorderRadius.circular(12),
                                          ),
                                          child: Text(
                                            'Results Available',
                                            style: TextStyle(
                                              color: Colors.white,
                                              fontSize: isLargeScreen ? 14 : 12,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ],
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
        ),
      ),
    );
  }
} 