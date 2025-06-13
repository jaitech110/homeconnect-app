import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../../main.dart'; // Import for getBaseUrl function

class MaintenanceRequestScreen extends StatefulWidget {
  final String unionId;
  final String buildingName;

  const MaintenanceRequestScreen({
    super.key,
    required this.unionId,
    required this.buildingName,
  });

  @override
  State<MaintenanceRequestScreen> createState() => _MaintenanceRequestScreenState();
}

class _MaintenanceRequestScreenState extends State<MaintenanceRequestScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Maintenance Request'),
        backgroundColor: Colors.green,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          tabs: const [
            Tab(
              icon: Icon(Icons.image),
              text: 'Payment Proofs',
            ),
            Tab(
              icon: Icon(Icons.account_balance),
              text: 'Bank Details',
            ),
            Tab(
              icon: Icon(Icons.search),
              text: 'Resident Search',
            ),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          PaymentProofsTab(unionId: widget.unionId, buildingName: widget.buildingName),
          BankDetailsManagementTab(unionId: widget.unionId),
          ResidentSearchTab(unionId: widget.unionId, buildingName: widget.buildingName),
        ],
      ),
    );
  }
}

// Tab 1: Payment Proofs Tab
class PaymentProofsTab extends StatefulWidget {
  final String unionId;
  final String buildingName;

  const PaymentProofsTab({
    super.key,
    required this.unionId,
    required this.buildingName,
  });

  @override
  State<PaymentProofsTab> createState() => _PaymentProofsTabState();
}

class _PaymentProofsTabState extends State<PaymentProofsTab> {
  List<Map<String, dynamic>> paymentProofs = [];
  bool _isLoading = true;
  String _errorMessage = '';
  String _selectedStatus = 'all';

  final List<String> statusOptions = ['all', 'pending', 'approved', 'rejected'];

  @override
  void initState() {
    super.initState();
    _fetchPaymentProofs();
  }

  Future<void> _fetchPaymentProofs() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      final url = Uri.parse('${getBaseUrl()}/union/payment-proofs/${widget.unionId}');
      
      final response = await http.get(
        url,
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          paymentProofs = List<Map<String, dynamic>>.from(data['payment_proofs'] ?? []);
          _isLoading = false;
        });
      } else {
        throw Exception('Failed to load payment proofs');
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Error loading payment proofs: ${e.toString()}';
        _isLoading = false;
      });
    }
  }

  Future<void> _updatePaymentStatus(String paymentId, String status, String? notes) async {
    try {
      final url = Uri.parse('${getBaseUrl()}/union/update-payment-status');
      
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'payment_id': paymentId,
          'status': status,
          'union_id': widget.unionId,
          'admin_notes': notes ?? '',
        }),
      );

      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Payment status updated to ${status.toUpperCase()}'),
            backgroundColor: Colors.green,
          ),
        );
        _fetchPaymentProofs(); // Refresh the list
      } else {
        throw Exception('Failed to update payment status');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error updating status: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  List<Map<String, dynamic>> get filteredPaymentProofs {
    if (_selectedStatus == 'all') {
      return paymentProofs;
    }
    return paymentProofs.where((proof) => 
      proof['status']?.toLowerCase() == _selectedStatus).toList();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_errorMessage.isNotEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error, size: 64, color: Colors.red),
            const SizedBox(height: 16),
            Text(_errorMessage, textAlign: TextAlign.center),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _fetchPaymentProofs,
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _fetchPaymentProofs,
      child: Column(
        children: [
          // Status Filter
          Container(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                const Text('Filter by status: ', style: TextStyle(fontWeight: FontWeight.bold)),
                Expanded(
                  child: DropdownButton<String>(
                    value: _selectedStatus,
                    isExpanded: true,
                    items: statusOptions.map((status) {
                      return DropdownMenuItem(
                        value: status,
                        child: Text(status.toUpperCase()),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setState(() {
                        _selectedStatus = value!;
                      });
                    },
                  ),
                ),
              ],
            ),
          ),
          // Payment Proofs List
          Expanded(
            child: filteredPaymentProofs.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.image_not_supported, size: 64, color: Colors.grey),
                        const SizedBox(height: 16),
                        Text('No payment proofs found for ${_selectedStatus.toUpperCase()} status'),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: filteredPaymentProofs.length,
                    itemBuilder: (context, index) {
                      final proof = filteredPaymentProofs[index];
                      return _buildPaymentProofCard(proof);
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentProofCard(Map<String, dynamic> proof) {
    final status = proof['status']?.toLowerCase() ?? 'pending';
    Color statusColor = Colors.orange;
    if (status == 'approved') statusColor = Colors.green;
    if (status == 'rejected') statusColor = Colors.red;

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    proof['resident_name'] ?? 'Unknown Resident',
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: statusColor,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    status.toUpperCase(),
                    style: const TextStyle(color: Colors.white, fontSize: 12),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Payment Type: ${proof['payment_type'] ?? 'N/A'}',
                        style: const TextStyle(fontWeight: FontWeight.w500),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Amount: PKR ${proof['amount'] ?? '0'}',
                        style: const TextStyle(fontWeight: FontWeight.w500, color: Colors.green),
                      ),
                      const SizedBox(height: 4),
                      if (proof['payment_for'] != null && proof['payment_for'].isNotEmpty)
                        Text(
                          'Payment For: ${proof['payment_for']}',
                          style: const TextStyle(fontWeight: FontWeight.w500, color: Colors.blue),
                        )
                      else if (proof['month'] != null && proof['year'] != null)
                        Text(
                          'Payment For: ${proof['month']} ${proof['year']}',
                          style: const TextStyle(fontWeight: FontWeight.w500, color: Colors.blue),
                        ),
                      const SizedBox(height: 4),
                      Text(
                        'Uploaded: ${_formatDate(proof['upload_date'] ?? '')}',
                        style: const TextStyle(color: Colors.grey),
                      ),
                      if (proof['flat_number'] != null && proof['flat_number'].isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(
                          'Flat: ${proof['flat_number']}',
                          style: const TextStyle(fontWeight: FontWeight.w500, color: Colors.deepPurple),
                        ),
                      ],
                    ],
                  ),
                ),
                if (proof['payment_proof_url'] != null)
                  GestureDetector(
                    onTap: () => _showPaymentProofDialog(proof),
                    child: Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey),
                        borderRadius: BorderRadius.circular(8),
                        color: Colors.blue[50],
                      ),
                      child: const Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.image, size: 30, color: Colors.blue),
                          SizedBox(height: 4),
                          Text(
                            'View',
                            style: TextStyle(fontSize: 12, color: Colors.blue),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
            
            if (status == 'pending') ...[
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => _showApproveDialog(proof),
                      icon: const Icon(Icons.check, color: Colors.white),
                      label: const Text('Approve', style: TextStyle(color: Colors.white)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => _showRejectDialog(proof),
                      icon: const Icon(Icons.close, color: Colors.white),
                      label: const Text('Reject', style: TextStyle(color: Colors.white)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                ],
              ),
            ],
            
            // Show admin notes if any
            if (proof['admin_notes'] != null && proof['admin_notes'].isNotEmpty) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey[300]!),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Admin Notes:',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      proof['admin_notes'],
                      style: const TextStyle(fontSize: 12),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  void _showPaymentProofDialog(Map<String, dynamic> proof) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Payment Proof - ${proof['resident_name']}'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Image placeholder (would show actual image in production)
              Container(
                height: 300,
                width: double.infinity,
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.image, size: 60, color: Colors.grey),
                      SizedBox(height: 8),
                      Text(
                        'Payment Proof Image',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      SizedBox(height: 4),
                      Text(
                        '(Image display will be implemented with backend)',
                        style: TextStyle(fontSize: 12, color: Colors.grey),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              
              // Payment Details
              _buildDetailRow('Resident', proof['resident_name'] ?? 'Unknown'),
              if (proof['flat_number'] != null && proof['flat_number'].isNotEmpty)
                _buildDetailRow('Flat Number', proof['flat_number']),
              _buildDetailRow('Payment Type', proof['payment_type'] ?? 'N/A'),
              _buildDetailRow('Amount', 'PKR ${proof['amount'] ?? '0'}'),
              
              if (proof['payment_for'] != null && proof['payment_for'].isNotEmpty)
                _buildDetailRow('Payment For', proof['payment_for'])
              else if (proof['month'] != null && proof['year'] != null)
                _buildDetailRow('Payment For', '${proof['month']} ${proof['year']}'),
                
              _buildDetailRow('Upload Date', _formatDate(proof['upload_date'] ?? '')),
              _buildDetailRow('Status', proof['status']?.toUpperCase() ?? 'PENDING'),
              
              if (proof['admin_notes'] != null && proof['admin_notes'].isNotEmpty)
                _buildDetailRow('Admin Notes', proof['admin_notes']),
            ],
          ),
        ),
        actions: [
          if (proof['status']?.toLowerCase() == 'pending') ...[
            TextButton.icon(
              onPressed: () {
                Navigator.pop(context);
                _showApproveDialog(proof);
              },
              icon: const Icon(Icons.check, color: Colors.green),
              label: const Text('Approve', style: TextStyle(color: Colors.green)),
            ),
            TextButton.icon(
              onPressed: () {
                Navigator.pop(context);
                _showRejectDialog(proof);
              },
              icon: const Icon(Icons.close, color: Colors.red),
              label: const Text('Reject', style: TextStyle(color: Colors.red)),
            ),
          ],
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              '$label:',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(
            child: Text(value),
          ),
        ],
      ),
    );
  }

  void _showApproveDialog(Map<String, dynamic> proof) {
    final notesController = TextEditingController();
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Approve Payment'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Approve payment from ${proof['resident_name']}?'),
            const SizedBox(height: 16),
            TextField(
              controller: notesController,
              decoration: const InputDecoration(
                labelText: 'Notes (Optional)',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _updatePaymentStatus(proof['id'].toString(), 'approved', notesController.text);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
            child: const Text('Approve'),
          ),
        ],
      ),
    );
  }

  void _showRejectDialog(Map<String, dynamic> proof) {
    final notesController = TextEditingController();
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reject Payment'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Reject payment from ${proof['resident_name']}?'),
            const SizedBox(height: 16),
            TextField(
              controller: notesController,
              decoration: const InputDecoration(
                labelText: 'Reason for Rejection*',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              if (notesController.text.trim().isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Please provide a reason for rejection')),
                );
                return;
              }
              Navigator.pop(context);
              _updatePaymentStatus(proof['id'].toString(), 'rejected', notesController.text);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Reject'),
          ),
        ],
      ),
    );
  }

  String _formatDate(String dateString) {
    try {
      final DateTime date = DateTime.parse(dateString);
      return '${date.day}/${date.month}/${date.year}';
    } catch (e) {
      return dateString;
    }
  }
}

// Tab 2: Bank Details Management Tab
class BankDetailsManagementTab extends StatefulWidget {
  final String unionId;

  const BankDetailsManagementTab({super.key, required this.unionId});

  @override
  State<BankDetailsManagementTab> createState() => _BankDetailsManagementTabState();
}

class _BankDetailsManagementTabState extends State<BankDetailsManagementTab> {
  final _formKey = GlobalKey<FormState>();
  final _bankNameController = TextEditingController();
  final _accountNumberController = TextEditingController();
  final _ifscController = TextEditingController();
  final _accountHolderController = TextEditingController();
  final _branchController = TextEditingController();
  final _upiIdController = TextEditingController();
  bool _isLoading = false;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _loadBankDetails();
  }

  Future<void> _loadBankDetails() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final url = Uri.parse('${getBaseUrl()}/union/bank-details/${widget.unionId}');
      
      final response = await http.get(
        url,
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final bankDetails = data['bank_details'];
        
        if (bankDetails != null) {
          _bankNameController.text = bankDetails['bank_name'] ?? '';
          _accountNumberController.text = bankDetails['account_number'] ?? '';
          _ifscController.text = bankDetails['ifsc_code'] ?? '';
          _accountHolderController.text = bankDetails['account_holder_name'] ?? '';
          _branchController.text = bankDetails['branch_name'] ?? '';
          _upiIdController.text = bankDetails['upi_id'] ?? '';
        }
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading bank details: ${e.toString()}')),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _saveBankDetails() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isSaving = true;
    });

    try {
      final url = Uri.parse('${getBaseUrl()}/union/save-bank-details');
      
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'union_id': widget.unionId,
          'bank_name': _bankNameController.text,
          'account_number': _accountNumberController.text,
          'ifsc_code': _ifscController.text,
          'account_holder_name': _accountHolderController.text,
          'branch_name': _branchController.text,
          'upi_id': _upiIdController.text,
        }),
      );

      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Bank details saved successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        throw Exception('Failed to save bank details');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error saving bank details: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        _isSaving = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Bank Account Details',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 16),
                    
                    TextFormField(
                      controller: _bankNameController,
                      decoration: const InputDecoration(
                        labelText: 'Bank Name*',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.business),
                      ),
                      validator: (value) => value?.isEmpty == true ? 'Bank name is required' : null,
                    ),
                    const SizedBox(height: 16),
                    
                    TextFormField(
                      controller: _accountNumberController,
                      decoration: const InputDecoration(
                        labelText: 'Account Number*',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.account_balance_wallet),
                      ),
                      validator: (value) => value?.isEmpty == true ? 'Account number is required' : null,
                    ),
                    const SizedBox(height: 16),
                    
                    TextFormField(
                      controller: _ifscController,
                      decoration: const InputDecoration(
                        labelText: 'IFSC Code*',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.code),
                      ),
                      validator: (value) => value?.isEmpty == true ? 'IFSC code is required' : null,
                    ),
                    const SizedBox(height: 16),
                    
                    TextFormField(
                      controller: _accountHolderController,
                      decoration: const InputDecoration(
                        labelText: 'Account Holder Name*',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.person),
                      ),
                      validator: (value) => value?.isEmpty == true ? 'Account holder name is required' : null,
                    ),
                    const SizedBox(height: 16),
                    
                    TextFormField(
                      controller: _branchController,
                      decoration: const InputDecoration(
                        labelText: 'Branch Name',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.location_on),
                      ),
                    ),
                    const SizedBox(height: 16),
                    
                    TextFormField(
                      controller: _upiIdController,
                      decoration: const InputDecoration(
                        labelText: 'UPI ID (Optional)',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.payment),
                      ),
                    ),
                    const SizedBox(height: 24),
                    
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        onPressed: _isSaving ? null : _saveBankDetails,
                        style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                        child: _isSaving
                            ? const CircularProgressIndicator(color: Colors.white)
                            : const Text(
                                'Save Bank Details',
                                style: TextStyle(fontSize: 16, color: Colors.white),
                              ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _bankNameController.dispose();
    _accountNumberController.dispose();
    _ifscController.dispose();
    _accountHolderController.dispose();
    _branchController.dispose();
    _upiIdController.dispose();
    super.dispose();
  }
}

// Tab 3: Resident Search Tab
class ResidentSearchTab extends StatefulWidget {
  final String unionId;
  final String buildingName;

  const ResidentSearchTab({
    super.key,
    required this.unionId,
    required this.buildingName,
  });

  @override
  State<ResidentSearchTab> createState() => _ResidentSearchTabState();
}

class _ResidentSearchTabState extends State<ResidentSearchTab> {
  List<Map<String, dynamic>> residents = [];
  Map<String, dynamic>? selectedResident;
  int selectedYear = DateTime.now().year;
  bool _isLoading = true;
  List<Map<String, dynamic>> searchResults = [];

  @override
  void initState() {
    super.initState();
    _loadResidents();
  }

  Future<void> _loadResidents() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final url = Uri.parse('${getBaseUrl()}/union/residents/${widget.unionId}');
      
      final response = await http.get(
        url,
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          residents = List<Map<String, dynamic>>.from(data['residents'] ?? []);
          _isLoading = false;
        });
      } else {
        throw Exception('Failed to load residents');
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading residents: ${e.toString()}')),
      );
    }
  }

  Future<void> _searchPaymentRecords() async {
    if (selectedResident == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a resident first')),
      );
      return;
    }

    try {
      final url = Uri.parse('${getBaseUrl()}/union/resident-payments');
      
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'resident_id': selectedResident!['id'],
          'year': selectedYear,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          searchResults = List<Map<String, dynamic>>.from(data['payments'] ?? []);
        });
      } else {
        throw Exception('Failed to search payment records');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error searching records: ${e.toString()}')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Search Payment Records',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 16),
                  
                  // Resident Dropdown
                  DropdownButtonFormField<Map<String, dynamic>>(
                    value: selectedResident,
                    decoration: const InputDecoration(
                      labelText: 'Select Resident',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.person),
                    ),
                    items: residents.map((resident) {
                      return DropdownMenuItem(
                        value: resident,
                        child: Text('${resident['first_name']} ${resident['last_name']} - ${resident['flat_number']}'),
                      );
                    }).toList(),
                    onChanged: (resident) {
                      setState(() {
                        selectedResident = resident;
                        searchResults = []; // Clear previous results
                      });
                    },
                  ),
                  const SizedBox(height: 16),
                  
                  // Year Dropdown
                  DropdownButtonFormField<int>(
                    value: selectedYear,
                    decoration: const InputDecoration(
                      labelText: 'Select Year',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.calendar_today),
                    ),
                    items: List.generate(5, (index) {
                      final year = DateTime.now().year - index;
                      return DropdownMenuItem(
                        value: year,
                        child: Text(year.toString()),
                      );
                    }),
                    onChanged: (year) {
                      setState(() {
                        selectedYear = year!;
                        searchResults = []; // Clear previous results
                      });
                    },
                  ),
                  const SizedBox(height: 24),
                  
                  // Search Button
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton.icon(
                      onPressed: _searchPaymentRecords,
                      icon: const Icon(Icons.search),
                      label: const Text('Search Payment Records'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          
          const SizedBox(height: 16),
          
          // Search Results
          if (searchResults.isNotEmpty) ...[
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Payment Records for ${selectedResident!['first_name']} ${selectedResident!['last_name']} ($selectedYear)',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 16),
                    
                    ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: searchResults.length,
                      separatorBuilder: (context, index) => const Divider(),
                      itemBuilder: (context, index) {
                        final payment = searchResults[index];
                        return ListTile(
                          leading: CircleAvatar(
                            backgroundColor: _getStatusColor(payment['status'] ?? 'pending'),
                            child: Icon(
                              payment['status']?.toLowerCase() == 'approved' 
                                  ? Icons.check 
                                  : payment['status']?.toLowerCase() == 'rejected'
                                    ? Icons.close
                                    : Icons.hourglass_empty,
                              color: Colors.white,
                            ),
                          ),
                          title: Text(payment['payment_type'] ?? 'Unknown Payment'),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Amount: ₹${payment['amount'] ?? '0'}'),
                              Text('Date: ${_formatDate(payment['upload_date'] ?? '')}'),
                              if (payment['reference_number'] != null)
                                Text('Ref: ${payment['reference_number']}'),
                            ],
                          ),
                          trailing: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: _getStatusColor(payment['status'] ?? 'pending'),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              payment['status']?.toUpperCase() ?? 'PENDING',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
          ] else if (selectedResident != null && searchResults.isEmpty) ...[
            Card(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Center(
                  child: Column(
                    children: [
                      Icon(Icons.search_off, size: 64, color: Colors.grey),
                      const SizedBox(height: 16),
                      Text(
                        'No payment records found for the selected criteria',
                        style: Theme.of(context).textTheme.titleMedium,
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'approved':
        return Colors.green;
      case 'pending':
        return Colors.orange;
      case 'rejected':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  String _formatDate(String dateString) {
    try {
      final DateTime date = DateTime.parse(dateString);
      return '${date.day}/${date.month}/${date.year}';
    } catch (e) {
      return dateString;
    }
  }
} 