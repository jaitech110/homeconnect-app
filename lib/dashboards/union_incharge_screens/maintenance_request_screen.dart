import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../../main.dart';
import '../../utils/payment_proof_service.dart';
import 'dart:typed_data';
import '../union_incharge_dashboard.dart';

class MaintenanceRequestScreen extends StatefulWidget {
  final String unionId;
  final String? buildingName;
  
  const MaintenanceRequestScreen({
    super.key,
    required this.unionId,
    this.buildingName,
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
    _tabController = TabController(length: 2, vsync: this);
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
        title: const Text('Maintenance Management'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (context) => UnionInchargeDashboard(
                  user: {
                    'id': widget.unionId,
                    'building_name': widget.buildingName,
                    'first_name': 'Union Incharge',
                  },
                ),
              ),
            );
          },
        ),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Payment Proofs'),
            Tab(text: 'Resident Records'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          PaymentProofsTab(
            unionId: widget.unionId,
            buildingName: widget.buildingName,
          ),
          ResidentRecordsTab(
            unionId: widget.unionId,
            buildingName: widget.buildingName,
          ),
        ],
      ),
    );
  }
}

class PaymentProofsTab extends StatefulWidget {
  final String? unionId;
  final String? buildingName;

  const PaymentProofsTab({
    super.key,
    this.unionId,
    this.buildingName,
  });

  @override
  State<PaymentProofsTab> createState() => _PaymentProofsTabState();
}

class _PaymentProofsTabState extends State<PaymentProofsTab> {
  List<Map<String, dynamic>> pendingProofs = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadPendingProofs();
  }

  Future<void> _loadPendingProofs() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final String buildingName = widget.buildingName ?? 'Demo Building';
      final String unionId = widget.unionId ?? 'demo_union';
      
      final allPayments = await PaymentProofService.instance.getPaymentProofsByBuildingAndUnion(
        buildingName,
        unionId,
      );
      
      final pending = allPayments.where((payment) => 
        payment['status']?.toLowerCase() == 'pending'
      ).toList();
      
      setState(() {
        pendingProofs = pending;
        _isLoading = false;
      });
      
      print('✅ Loaded ${pending.length} pending proofs');
    } catch (e) {
      print('❌ Error loading pending proofs: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _updatePaymentStatus(String paymentId, String status, String notes) async {
    try {
      await PaymentProofService.instance.updatePaymentProofStatus(
        paymentId,
        status,
        notes: notes,
      );
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Payment $status successfully'),
          backgroundColor: status == 'approved' ? Colors.green : Colors.red,
        ),
      );
      
      _loadPendingProofs();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error updating payment: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // Helper method to build payment proof image from base64 data
  Widget _buildPaymentProofImage(String base64Data) {
    try {
      final Uint8List imageBytes = base64Decode(base64Data);
      return Image.memory(
        imageBytes,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          print('❌ Error displaying image: $error');
          return Container(
            color: Colors.grey[100],
            child: const Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.broken_image, size: 30, color: Colors.grey),
                SizedBox(height: 4),
                Text('Error loading image', style: TextStyle(color: Colors.grey, fontSize: 10)),
              ],
            ),
          );
        },
      );
    } catch (e) {
      print('❌ Error decoding base64 image: $e');
      return Container(
        color: Colors.grey[100],
        child: const Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.broken_image, size: 30, color: Colors.grey),
            SizedBox(height: 4),
            Text('Invalid image data', style: TextStyle(color: Colors.grey, fontSize: 10)),
          ],
        ),
      );
    }
  }

  // Show full-screen image view for pending proofs
  void _showFullScreenImage(Map<String, dynamic> proof) {
    if (proof['image_data'] == null || proof['image_data'].toString().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No image available'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.black,
        child: Stack(
          children: [
            Center(
              child: InteractiveViewer(
                panEnabled: true,
                boundaryMargin: const EdgeInsets.all(20),
                minScale: 0.5,
                maxScale: 4,
                child: _buildPaymentProofImage(proof['image_data']),
              ),
            ),
            Positioned(
              top: 40,
              left: 20,
              right: 20,
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.7),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  children: [
                    Text(
                      'Pending Payment Proof',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '${proof['payment_type'] ?? 'Unknown'} - ${proof['amount'] ?? '0'}',
                      style: const TextStyle(color: Colors.white70),
                    ),
                    Text(
                      'House Number: ${proof['flat_number'] ?? 'Unknown'}',
                      style: const TextStyle(
                        color: Colors.white, 
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Positioned(
              top: 40,
              right: 20,
              child: IconButton(
                onPressed: () => Navigator.of(context).pop(),
                icon: const Icon(Icons.close, color: Colors.white, size: 30),
              ),
            ),
            Positioned(
              bottom: 40,
              left: 20,
              right: 20,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  ElevatedButton.icon(
                    onPressed: () {
                      Navigator.of(context).pop();
                      _updatePaymentStatus(
                        proof['id'], 
                        'approved',
                        'Payment approved by union incharge after reviewing image',
                      );
                    },
                    icon: const Icon(Icons.check),
                    label: const Text('Approve'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                    ),
                  ),
                  ElevatedButton.icon(
                    onPressed: () {
                      Navigator.of(context).pop();
                      _updatePaymentStatus(
                        proof['id'], 
                        'rejected',
                        'Payment rejected by union incharge after reviewing image',
                      );
                    },
                    icon: const Icon(Icons.close),
                    label: const Text('Reject'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return _isLoading
        ? const Center(child: CircularProgressIndicator())
        : pendingProofs.isEmpty
            ? const Center(
                child: Text(
                  'No pending payment proofs',
                  style: TextStyle(fontSize: 18),
                ),
              )
            : ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: pendingProofs.length,
                itemBuilder: (context, index) {
                  final proof = pendingProofs[index];
                  
                  return Card(
                    margin: const EdgeInsets.only(bottom: 16),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            proof['payment_type'] ?? 'Unknown Payment',
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text('Amount: ${proof['amount'] ?? '0'}'),
                          Text(
                            'House Number: ${proof['flat_number'] ?? 'Unknown'}',
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.blue,
                            ),
                          ),
                          
                          // Image Display Section
                          if (proof['image_data'] != null && proof['image_data'].toString().isNotEmpty) ...[
                            const SizedBox(height: 16),
                            const Text(
                              'Payment Proof Image:',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 8),
                            GestureDetector(
                              onTap: () => _showFullScreenImage(proof),
                              child: Container(
                                height: 200,
                                width: double.infinity,
                                decoration: BoxDecoration(
                                  border: Border.all(color: Colors.grey[300]!),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(8),
                                  child: _buildPaymentProofImage(proof['image_data']),
                                ),
                              ),
                            ),
                            const SizedBox(height: 4),
                            const Text(
                              'Tap image to view full screen',
                              style: TextStyle(color: Colors.grey, fontSize: 12),
                            ),
                          ] else ...[
                            const SizedBox(height: 16),
                            Container(
                              height: 100,
                              width: double.infinity,
                              decoration: BoxDecoration(
                                color: Colors.grey[200],
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: Colors.grey[300]!),
                              ),
                              child: const Center(
                                child: Text(
                                  'No Image Available',
                                  style: TextStyle(color: Colors.grey),
                                ),
                              ),
                            ),
                          ],
                          
                          const SizedBox(height: 16),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: [
                              ElevatedButton.icon(
                                onPressed: () => _updatePaymentStatus(
                                  proof['id'], 
                                  'approved',
                                  'Payment approved by union incharge',
                                ),
                                icon: const Icon(Icons.check),
                                label: const Text('Approve'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.green,
                                  foregroundColor: Colors.white,
                                ),
                              ),
                              ElevatedButton.icon(
                                onPressed: () => _updatePaymentStatus(
                                  proof['id'], 
                                  'rejected',
                                  'Payment rejected by union incharge',
                                ),
                                icon: const Icon(Icons.close),
                                label: const Text('Reject'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.red,
                                  foregroundColor: Colors.white,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  );
                },
              );
  }
}

class ResidentRecordsTab extends StatefulWidget {
  final String? unionId;
  final String? buildingName;
  
  const ResidentRecordsTab({
    super.key,
    this.unionId,
    this.buildingName,
  });

  @override
  State<ResidentRecordsTab> createState() => _ResidentRecordsTabState();
}

class _ResidentRecordsTabState extends State<ResidentRecordsTab> {
  List<Map<String, dynamic>> approvedRecords = [];
  bool _isLoading = true;
  String? selectedMonth;
  int selectedYear = DateTime.now().year;
  
  final List<String> months = [
    'January', 'February', 'March', 'April', 'May', 'June',
    'July', 'August', 'September', 'October', 'November', 'December'
  ];

  @override
  void initState() {
    super.initState();
    _loadApprovedRecords();
  }

  Future<void> _loadApprovedRecords() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final String buildingName = widget.buildingName ?? 'Demo Building';
      final String unionId = widget.unionId ?? 'demo_union';
      
      final allPayments = await PaymentProofService.instance.getPaymentProofsByBuildingAndUnion(
        buildingName,
        unionId,
      );
      
      final approved = allPayments.where((payment) => 
        payment['status']?.toLowerCase() == 'approved'
      ).toList();
      
      setState(() {
        approvedRecords = approved;
        _isLoading = false;
      });
      
      print('✅ Loaded ${approved.length} approved records');
    } catch (e) {
      print('❌ Error loading approved records: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  List<Map<String, dynamic>> _getFilteredRecords() {
    return approvedRecords.where((record) {
      bool matchesMonth = selectedMonth == null || 
        record['month']?.toString().toLowerCase() == selectedMonth?.toLowerCase();
      bool matchesYear = record['year']?.toString() == selectedYear.toString();
      return matchesMonth && matchesYear;
    }).toList();
  }

  String _formatDate(String dateString) {
    try {
      final DateTime date = DateTime.parse(dateString);
      return '${date.day}/${date.month}/${date.year}';
    } catch (e) {
      return dateString;
    }
  }

  // Helper method to build payment proof image from base64 data
  Widget _buildPaymentProofImage(String base64Data) {
    try {
      final Uint8List imageBytes = base64Decode(base64Data);
      return Image.memory(
        imageBytes,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          print('❌ Error displaying image: $error');
          return Container(
            color: Colors.grey[100],
            child: const Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.broken_image, size: 30, color: Colors.grey),
                SizedBox(height: 4),
                Text('Error loading image', style: TextStyle(color: Colors.grey, fontSize: 10)),
              ],
            ),
          );
        },
      );
    } catch (e) {
      print('❌ Error decoding base64 image: $e');
      return Container(
        color: Colors.grey[100],
        child: const Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.broken_image, size: 30, color: Colors.grey),
            SizedBox(height: 4),
            Text('Invalid image data', style: TextStyle(color: Colors.grey, fontSize: 10)),
          ],
        ),
      );
    }
  }

  // Show full-screen image view for approved records
  void _showFullScreenImage(Map<String, dynamic> record) {
    if (record['image_data'] == null || record['image_data'].toString().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No image available'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.black,
        child: Stack(
          children: [
            Center(
              child: InteractiveViewer(
                panEnabled: true,
                boundaryMargin: const EdgeInsets.all(20),
                minScale: 0.5,
                maxScale: 4,
                child: _buildPaymentProofImage(record['image_data']),
              ),
            ),
            Positioned(
              top: 40,
              left: 20,
              right: 20,
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.7),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  children: [
                    Text(
                      'Approved Payment Proof',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '${record['payment_type'] ?? 'Unknown'} - ${record['amount'] ?? '0'}',
                      style: const TextStyle(color: Colors.white70),
                    ),
                    Text(
                      'House Number: ${record['flat_number'] ?? 'Unknown'}',
                      style: const TextStyle(
                        color: Colors.white, 
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.green,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Text(
                        'APPROVED',
                        style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Positioned(
              top: 40,
              right: 20,
              child: IconButton(
                onPressed: () => Navigator.of(context).pop(),
                icon: const Icon(Icons.close, color: Colors.white, size: 30),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final filteredRecords = _getFilteredRecords();

    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Approved Payment Records',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    flex: 2,
                    child: DropdownButtonFormField<String>(
                      value: selectedMonth,
                      decoration: const InputDecoration(
                        labelText: 'Month',
                        border: OutlineInputBorder(),
                      ),
                      items: [
                        const DropdownMenuItem<String>(
                          value: null,
                          child: Text('All Months'),
                        ),
                        ...months.map((month) {
                          return DropdownMenuItem<String>(
                            value: month,
                            child: Text(month),
                          );
                        }),
                      ],
                      onChanged: (value) {
                        setState(() {
                          selectedMonth = value;
                        });
                      },
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    flex: 1,
                    child: DropdownButtonFormField<int>(
                      value: selectedYear,
                      decoration: const InputDecoration(
                        labelText: 'Year',
                        border: OutlineInputBorder(),
                      ),
                      items: List.generate(5, (index) {
                        final year = DateTime.now().year - index;
                        return DropdownMenuItem<int>(
                          value: year,
                          child: Text(year.toString()),
                        );
                      }),
                      onChanged: (value) {
                        if (value != null) {
                          setState(() {
                            selectedYear = value;
                          });
                        }
                      },
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        Expanded(
          child: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : filteredRecords.isEmpty
                  ? const Center(
                      child: Text('No approved records found'),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: filteredRecords.length,
                      itemBuilder: (context, index) {
                        final record = filteredRecords[index];
                        
                        return Card(
                          margin: const EdgeInsets.only(bottom: 12),
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    CircleAvatar(
                                      backgroundColor: Colors.green[600],
                                      child: const Icon(Icons.check, color: Colors.white),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            record['payment_type'] ?? 'Unknown Payment',
                                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                          ),
                                                                    Text('Amount: ${record['amount'] ?? '0'}'),
                                          if (record['flat_number'] != null)
                                            Text(
                                              'House Number: ${record['flat_number']}',
                                              style: const TextStyle(
                                                fontSize: 18,
                                                fontWeight: FontWeight.bold,
                                                color: Colors.blue,
                                              ),
                                            ),
                                        ],
                                      ),
                                    ),
                                    const Icon(Icons.verified, color: Colors.green),
                                  ],
                                ),
                                
                                // Payment Proof Image Display
                                if (record['image_data'] != null && record['image_data'].toString().isNotEmpty) ...[
                                  const SizedBox(height: 12),
                                  const Text(
                                    'Payment Proof:',
                                    style: TextStyle(fontWeight: FontWeight.bold),
                                  ),
                                  const SizedBox(height: 8),
                                  GestureDetector(
                                    onTap: () => _showFullScreenImage(record),
                                    child: Container(
                                      height: 120,
                                      width: double.infinity,
                                      decoration: BoxDecoration(
                                        border: Border.all(color: Colors.grey[300]!),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: ClipRRect(
                                        borderRadius: BorderRadius.circular(8),
                                        child: _buildPaymentProofImage(record['image_data']),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  const Text(
                                    'Tap to view full size',
                                    style: TextStyle(color: Colors.grey, fontSize: 12),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        );
                      },
                    ),
        ),
      ],
    );
  }
} 