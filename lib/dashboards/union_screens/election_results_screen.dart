import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../../../main.dart';

class ElectionResultsScreen extends StatefulWidget {
  final String unionInchargeId;
  
  const ElectionResultsScreen({
    super.key,
    required this.unionInchargeId,
  });

  @override
  State<ElectionResultsScreen> createState() => _ElectionResultsScreenState();
}

class _ElectionResultsScreenState extends State<ElectionResultsScreen> {
  List<dynamic> _elections = [];
  bool _isLoading = true;
  String? _error;
  Map<String, int> _totalResidentsMap = {};

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
      // Get elections with corrected parameter name to match backend
      final response = await http.get(
        Uri.parse('${getBaseUrl()}/union/elections?union_id=${widget.unionInchargeId}'),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final elections = data['elections'] ?? [];
        
        // Fetch total residents for each election property
        final Map<String, int> residentsCountMap = {};
        
        // Process elections and get property IDs
        for (var election in elections) {
          if (election['property_id'] != null) {
            // Fetch resident count if not already fetched for this property
            if (!residentsCountMap.containsKey(election['property_id'])) {
              try {
                final residentCountResponse = await http.get(
                  Uri.parse('${getBaseUrl()}/property/${election['property_id']}/resident_count'),
                );
                
                if (residentCountResponse.statusCode == 200) {
                  final countData = jsonDecode(residentCountResponse.body);
                  residentsCountMap[election['property_id']] = countData['count'] ?? 0;
                }
              } catch (e) {
                print('Failed to get resident count: $e');
                // Default to 0 if count fetch fails
                residentsCountMap[election['property_id']] = 0;
              }
            }
            
            // Map election ID to resident count for this property
            _totalResidentsMap[election['id']] = residentsCountMap[election['property_id']] ?? 0;
          }
        }
        
        setState(() {
          _elections = elections;
          _isLoading = false;
        });
        
        print('✅ Found ${_elections.length} elections for results screen');
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

  Future<void> _publishResults(String electionId) async {
    try {
      // Publish the results through the API
      final publishResponse = await http.post(
        Uri.parse('${getBaseUrl()}/union/elections/$electionId/publish_results'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'union_id': widget.unionInchargeId}),
      );

      if (publishResponse.statusCode == 200) {
        // Refresh the elections list
        _fetchElections();

        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Results published successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        final error = jsonDecode(publishResponse.body)['error'] ?? 'Failed to publish results';
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(error),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      print('❌ Error publishing results: $e');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _showResultsDialog(Map<String, dynamic> election) {
    // Calculate voting progress
    final totalVotes = election['total_votes'] ?? 0;
    final electionId = election['id']?.toString() ?? '';
    final totalResidents = _totalResidentsMap[electionId] ?? 0;
    final double votingProgress = totalResidents > 0 ? totalVotes / totalResidents : 0;
    final votingPercentage = (votingProgress * 100).toStringAsFixed(1);
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(election['title']),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (totalResidents > 0) ...[
              Text('Voting Status: $totalVotes of $totalResidents residents have voted ($votingPercentage%)'),
              const SizedBox(height: 8),
              LinearProgressIndicator(
                value: votingProgress,
                backgroundColor: Colors.grey[200],
                valueColor: AlwaysStoppedAnimation<Color>(
                  votingProgress < 0.5 ? Colors.orange : Colors.green,
                ),
              ),
              const SizedBox(height: 16),
            ] else ...[
              Text('Total Votes: $totalVotes'),
              const SizedBox(height: 16),
            ],
            const Text(
              'Results:',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 8),
            ...((election['results'] as Map<String, dynamic>?) ?? {}).entries.map<Widget>((entry) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${entry.key}: ${entry.value}%',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    LinearProgressIndicator(
                      value: entry.value / 100,
                      backgroundColor: Colors.grey[200],
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.deepPurple),
                    ),
                  ],
                ),
              );
            }).toList(),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _publishResults(electionId);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.deepPurple,
            ),
            child: const Text('Publish & Close'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Election Results'),
        backgroundColor: Colors.deepPurple,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _fetchElections,
            tooltip: 'Refresh Results',
          ),
        ],
      ),
      body: _isLoading
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
                          Text(
                            'Create a new election to get started',
                            style: Theme.of(context).textTheme.bodyMedium,
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      itemCount: _elections.length,
                      padding: const EdgeInsets.all(16),
                      itemBuilder: (context, index) {
                        final election = _elections[index];
                        final totalVotes = election['total_votes'] ?? 0;
                        final totalResidents = _totalResidentsMap[election['id']] ?? 0;
                        
                        return Card(
                          margin: const EdgeInsets.only(bottom: 16),
                          child: ListTile(
                            title: Text(election['title']),
                            subtitle: Text(
                              'Created: ${election['created_at']}\nVotes: $totalVotes of $totalResidents residents',
                            ),
                            trailing: const Icon(Icons.chevron_right),
                            onTap: () => _showResultsDialog(election),
                          ),
                        );
                      },
                    ),
    );
  }
} 