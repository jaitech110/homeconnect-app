import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../../../main.dart';

class CreateElectionScreen extends StatefulWidget {
  final String unionInchargeId;
  
  const CreateElectionScreen({
    super.key,
    required this.unionInchargeId,
  });

  @override
  State<CreateElectionScreen> createState() => _CreateElectionScreenState();
}

class _CreateElectionScreenState extends State<CreateElectionScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _choiceController = TextEditingController();
  final List<String> _choices = [];
  bool _isLoading = false;
  String? _error;

  void _addChoice(String choice) {
    if (choice.isNotEmpty && !_choices.contains(choice)) {
      setState(() {
        _choices.add(choice);
      });
    }
  }

  void _addCustomChoice() {
    final choice = _choiceController.text.trim();
    if (choice.isNotEmpty && !_choices.contains(choice)) {
      setState(() {
        _choices.add(choice);
        _choiceController.clear();
      });
    }
  }

  void _removeChoice(String choice) {
    setState(() {
      _choices.remove(choice);
    });
  }

  Future<void> _createElection() async {
    if (!_formKey.currentState!.validate()) return;
    if (_choices.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please add at least one choice')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      print('🗳️ Creating election with union_incharge_id: ${widget.unionInchargeId}');
      
      final response = await http.post(
        Uri.parse('${getBaseUrl()}/union/create_election'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'title': _titleController.text,
          'description': 'Community election created by union incharge',
          'choices': _choices,
          'union_incharge_id': widget.unionInchargeId,
        }),
      );

      print('🗳️ Election creation response: ${response.statusCode}');
      print('🗳️ Response body: ${response.body}');

      if (response.statusCode == 201) {
        final responseData = jsonDecode(response.body);
        if (!mounted) return;
        Navigator.pop(context, true);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Election created successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        final errorData = jsonDecode(response.body);
        final error = errorData['error'] ?? 'Failed to create election';
        setState(() => _error = error);
        print('❌ Election creation failed: $error');
      }
    } catch (e) {
      setState(() => _error = e.toString());
      print('❌ Election creation error: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Create Election'),
        backgroundColor: Colors.deepPurple,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (_error != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: Text(
                    _error!,
                    style: const TextStyle(color: Colors.red),
                  ),
                ),
              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(
                  labelText: 'Election Title',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter an election title';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 24),
              const Text(
                'Add Choices',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _choiceController,
                      decoration: const InputDecoration(
                        labelText: 'Custom Choice',
                        hintText: 'Enter your custom choice',
                        border: OutlineInputBorder(),
                      ),
                      onFieldSubmitted: (_) => _addCustomChoice(),
                    ),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: _addCustomChoice,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.deepPurple,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: const Text('Add'),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              const Text(
                'Quick Options:',
                style: TextStyle(fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: [
                  ActionChip(
                    label: const Text('Add Yes'),
                    onPressed: () => _addChoice('Yes'),
                  ),
                  ActionChip(
                    label: const Text('Add No'),
                    onPressed: () => _addChoice('No'),
                  ),
                  ActionChip(
                    label: const Text('Add None'),
                    onPressed: () => _addChoice('None'),
                  ),
                  ActionChip(
                    label: const Text('Add Abstain'),
                    onPressed: () => _addChoice('Abstain'),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              if (_choices.isNotEmpty) ...[
                const Text(
                  'Added Choices:',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey.shade300),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _choices.map((choice) {
                      return Chip(
                        label: Text(choice),
                        onDeleted: () => _removeChoice(choice),
                        backgroundColor: Colors.deepPurple.shade50,
                      );
                    }).toList(),
                  ),
                ),
              ],
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _isLoading ? null : _createElection,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.deepPurple,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: _isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : const Text('Create Election'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _titleController.dispose();
    _choiceController.dispose();
    super.dispose();
  }
} 