import 'package:flutter/material.dart';

class AdminBankDetailsScreen extends StatefulWidget {
  const AdminBankDetailsScreen({super.key});

  @override
  State<AdminBankDetailsScreen> createState() => _AdminBankDetailsScreenState();
}

class _AdminBankDetailsScreenState extends State<AdminBankDetailsScreen> {
  final TextEditingController _accountTitleController = TextEditingController();
  final TextEditingController _accountNumberController = TextEditingController();
  final TextEditingController _bankNameController = TextEditingController();
  final TextEditingController _ibanController = TextEditingController();

  bool _isSaved = false;

  void _saveDetails() {
    if (_accountTitleController.text.isEmpty ||
        _accountNumberController.text.isEmpty ||
        _bankNameController.text.isEmpty ||
        _ibanController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('All fields are required')),
      );
      return;
    }

    setState(() {
      _isSaved = true;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Bank details saved successfully')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Bank Details'),
        backgroundColor: Colors.deepPurple,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: SingleChildScrollView(
          child: Column(
            children: [
              _buildTextField(_accountTitleController, 'Account Title'),
              const SizedBox(height: 16),
              _buildTextField(_accountNumberController, 'Account Number'),
              const SizedBox(height: 16),
              _buildTextField(_bankNameController, 'Bank Name'),
              const SizedBox(height: 16),
              _buildTextField(_ibanController, 'IBAN'),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _saveDetails,
                style: ElevatedButton.styleFrom(backgroundColor: Colors.deepPurple),
                child: const Text('Save Bank Details'),
              ),
              if (_isSaved) ...[
                const SizedBox(height: 32),
                const Divider(),
                const Text('Current Bank Info', style: TextStyle(fontWeight: FontWeight.bold)),
                ListTile(
                  title: const Text('Account Title'),
                  subtitle: Text(_accountTitleController.text),
                ),
                ListTile(
                  title: const Text('Account Number'),
                  subtitle: Text(_accountNumberController.text),
                ),
                ListTile(
                  title: const Text('Bank Name'),
                  subtitle: Text(_bankNameController.text),
                ),
                ListTile(
                  title: const Text('IBAN'),
                  subtitle: Text(_ibanController.text),
                ),
              ]
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField(TextEditingController controller, String label) {
    return TextField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
      ),
    );
  }
}
