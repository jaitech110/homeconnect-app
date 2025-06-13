import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'dart:convert';
import 'dart:typed_data';
import '../../main.dart'; // Import for getBaseUrl function
import '../../utils/payment_proof_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

class MaintenanceScreen extends StatefulWidget {
  final String userId;
  final String userName;
  final String? buildingName;
  final String? unionId;
  
  const MaintenanceScreen({
    super.key, 
    required this.userId,
    required this.userName,
    this.buildingName,
    this.unionId,
  });

  @override
  State<MaintenanceScreen> createState() => _MaintenanceScreenState();
}

class _MaintenanceScreenState extends State<MaintenanceScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    
    // Debug: Print the building and union information
    print('🏠 Resident Maintenance Screen initialized:');
    print('   • User ID: ${widget.userId}');
    print('   • Building Name: ${widget.buildingName}');
    print('   • Union ID: ${widget.unionId}');
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
        title: const Text('Maintenance'),
        backgroundColor: Colors.deepPurple,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          tabs: const [
            Tab(
              icon: Icon(Icons.upload_file),
              text: 'Upload Payment',
            ),
            Tab(
              icon: Icon(Icons.history),
              text: 'Payment Records',
            ),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          UploadPaymentTab(
            userId: widget.userId,
            userName: widget.userName,
            buildingName: widget.buildingName,
            unionId: widget.unionId,
          ),
          PaymentRecordsTab(userId: widget.userId),
        ],
      ),
    );
  }
}

class UploadPaymentTab extends StatefulWidget {
  final String userId;
  final String userName;
  final String? buildingName;
  final String? unionId;
  const UploadPaymentTab({
    super.key, 
    required this.userId,
    required this.userName,
    this.buildingName,
    this.unionId,
  });

  @override
  State<UploadPaymentTab> createState() => _UploadPaymentTabState();
}

class _UploadPaymentTabState extends State<UploadPaymentTab> {
  final _formKey = GlobalKey<FormState>();
  final ImagePicker _picker = ImagePicker();
  XFile? _selectedImage;
  final _amountController = TextEditingController();
  final _flatNumberController = TextEditingController();
  bool _isLoading = false;

  String? selectedPaymentType;
  String? selectedMonth;
  int selectedYear = DateTime.now().year;

  final List<String> paymentTypes = [
    'Monthly Maintenance',
    'Water Bill',
    'Electricity Bill',
    'Security Fee',
    'Cleaning Fee',
    'Garden Maintenance',
    'Gas Bill',
    'Other'
  ];

  final List<String> months = [
    'January', 'February', 'March', 'April', 'May', 'June',
    'July', 'August', 'September', 'October', 'November', 'December'
  ];

  Future<void> _pickImage() async {
    try {
      print('📱 Opening gallery to pick image...');
      
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1920,
        maxHeight: 1080,
        imageQuality: 85,
      );
      
      if (image != null) {
        print('📸 Image selected: ${image.name}');
        
        try {
          // Get file size using XFile methods instead of File
          final fileSize = await image.length();
          print('📏 File size: $fileSize bytes');
          
          if (fileSize > 0) {
            // Test if we can read the file bytes
            final bytes = await image.readAsBytes();
            if (bytes.isNotEmpty) {
              print('✅ Image is readable and valid (${bytes.length} bytes)');
              
      setState(() {
                _selectedImage = image;
              });
              
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('✅ Image selected (${(fileSize / 1024).toStringAsFixed(1)} KB)'),
                  backgroundColor: Colors.green,
                  duration: const Duration(seconds: 2),
                ),
              );
            } else {
              throw Exception('Image file contains no data');
            }
          } else {
            throw Exception('Selected image file is empty');
          }
    } catch (e) {
          throw Exception('Cannot read image file: $e');
        }
      } else {
        print('ℹ️ No image selected by user');
      }
    } catch (e) {
      print('❌ Error picking image: $e');
      setState(() {
        _selectedImage = null;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('❌ Error selecting image: Please try again'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  Future<void> _takePicture() async {
    try {
      print('📷 Opening camera to take picture...');
      
      final XFile? image = await _picker.pickImage(
        source: ImageSource.camera,
        maxWidth: 1920,
        maxHeight: 1080,
        imageQuality: 85,
      );
      
      if (image != null) {
        print('📸 Picture taken: ${image.name}');
        
        try {
          // Get file size using XFile methods instead of File
          final fileSize = await image.length();
          print('📏 File size: $fileSize bytes');
          
          if (fileSize > 0) {
            // Test if we can read the file bytes
            final bytes = await image.readAsBytes();
            if (bytes.isNotEmpty) {
              print('✅ Picture is readable and valid (${bytes.length} bytes)');
              
            setState(() {
                _selectedImage = image;
              });
              
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
                  content: Text('✅ Picture captured (${(fileSize / 1024).toStringAsFixed(1)} KB)'),
              backgroundColor: Colors.green,
              duration: const Duration(seconds: 2),
            ),
          );
            } else {
              throw Exception('Captured picture contains no data');
            }
          } else {
            throw Exception('Captured picture is empty');
          }
        } catch (e) {
          throw Exception('Cannot read picture file: $e');
        }
      } else {
        print('ℹ️ No picture taken by user');
      }
    } catch (e) {
      print('❌ Error taking picture: $e');
      setState(() {
        _selectedImage = null;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('❌ Error taking picture: Please try again'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  Future<void> _uploadPaymentProof() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedImage == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a payment proof image')),
      );
      return;
    }
    if (selectedMonth == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select the month')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // Verify image file using XFile methods
      final fileSize = await _selectedImage!.length();
      final imageBytes = await _selectedImage!.readAsBytes();
      
      if (fileSize == 0 || imageBytes.isEmpty) {
        throw Exception('Selected image file is empty or corrupted');
      }
      
      print('📸 Preparing to upload image: ${_selectedImage!.name}');
      print('📏 File size: $fileSize bytes (${imageBytes.length} bytes read)');
      
      // For demo purposes, let's try the backend first, but fall back to local storage
      bool uploadedToBackend = false;
      String paymentId = DateTime.now().millisecondsSinceEpoch.toString();
      
      try {
        final url = Uri.parse('${getBaseUrl()}/upload-payment-proof');
        
        // Create multipart request
        var request = http.MultipartRequest('POST', url);
        
        // Add headers
        request.headers.addAll({
          'Content-Type': 'multipart/form-data',
        });
        
        // Add text fields
        request.fields['user_id'] = widget.userId;
        request.fields['payment_type'] = selectedPaymentType ?? '';
        request.fields['amount'] = _amountController.text;
        request.fields['month'] = selectedMonth ?? '';
        request.fields['year'] = selectedYear.toString();
        request.fields['payment_for'] = '$selectedMonth $selectedYear';
        request.fields['flat_number'] = _flatNumberController.text;
        
        // Create multipart file from bytes
        var multipartFile = http.MultipartFile.fromBytes(
          'payment_proof',
          imageBytes,
          filename: _selectedImage!.name.isNotEmpty 
              ? _selectedImage!.name 
              : 'payment_proof_${DateTime.now().millisecondsSinceEpoch}.jpg',
        );
        
        request.files.add(multipartFile);
        
        print('🚀 Attempting backend upload...');
        
        // Send request with timeout
        var streamedResponse = await request.send().timeout(const Duration(seconds: 10));
        var response = await http.Response.fromStream(streamedResponse);
        
        print('📥 Response status: ${response.statusCode}');
        
        if (response.statusCode == 201 || response.statusCode == 200) {
          final responseData = jsonDecode(response.body);
          paymentId = responseData['payment_id'] ?? paymentId;
          uploadedToBackend = true;
          print('✅ Successfully uploaded to backend');
        } else {
          throw Exception('Backend error: ${response.statusCode}');
        }
      } catch (e) {
        print('⚠️ Backend upload failed: $e');
        print('💾 Falling back to local storage for demo...');
      }
      
      // Store data locally for demo purposes (whether backend worked or not)
      await _storePaymentProofLocally(
        paymentId: paymentId,
        userId: widget.userId,
        userName: widget.userName,
        paymentType: selectedPaymentType ?? '',
        amount: _amountController.text,
        month: selectedMonth ?? '',
        year: selectedYear.toString(),
        paymentFor: '$selectedMonth $selectedYear',
        imageBytes: imageBytes,
        fileName: _selectedImage!.name.isNotEmpty ? _selectedImage!.name : 'payment_proof_$paymentId.jpg',
        uploadedToBackend: uploadedToBackend,
      );
      
      // Clear form on success
      _amountController.clear();
      _flatNumberController.clear();
      setState(() {
        _selectedImage = null;
        selectedPaymentType = null;
        selectedMonth = null;
        selectedYear = DateTime.now().year;
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Column(
            mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
              const Text('✅ Payment proof uploaded successfully!'),
              const SizedBox(height: 4),
              Text('📋 ID: $paymentId'),
              Text('💾 Storage: ${uploadedToBackend ? 'Backend + Local' : 'Local (Demo)'}'),
              const Text('⏳ Status: Pending union incharge approval'),
            ],
          ),
          backgroundColor: Colors.green,
          duration: const Duration(seconds: 4),
        ),
      );
      
    } catch (e) {
      print('❌ Upload error: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Column(
            mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
              const Text('❌ Failed to upload payment proof'),
              const SizedBox(height: 4),
              Text('Error: ${e.toString()}'),
              const SizedBox(height: 4),
              const Text('Please try again or contact support'),
            ],
          ),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 5),
        ),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _storePaymentProofLocally({
    required String paymentId,
    required String userId,
    required String userName,
    required String paymentType,
    required String amount,
    required String month,
    required String year,
    required String paymentFor,
    required Uint8List imageBytes,
    required String fileName,
    required bool uploadedToBackend,
  }) async {
    try {
      // Get building and union info with better fallbacks
      String buildingName = widget.buildingName ?? 'Demo Building';
      String unionId = widget.unionId ?? 'demo_union';
      
      // If we don't have proper building/union info, use demo values that work
      if (buildingName == 'Demo Building' || buildingName.isEmpty) {
        buildingName = 'Demo Building'; // Consistent demo building name
      }
      
      if (unionId == 'default_union' || unionId.isEmpty) {
        unionId = 'demo_union'; // Consistent demo union ID
      }
      
      print('📤 Uploading payment proof with:');
      print('   • Building: "$buildingName"');
      print('   • Union ID: "$unionId"');
      print('   • User ID: "$userId"');
      
      // Use PaymentProofService instead of direct SharedPreferences
      await PaymentProofService.instance.uploadPaymentProof(
        userId: userId,
        userName: userName,
        paymentType: paymentType,
        amount: amount,
        month: month,
        year: year,
        paymentFor: paymentFor,
        fileBytes: imageBytes,
        fileName: fileName,
        flatNumber: _flatNumberController.text,
        buildingName: buildingName, // Use consistent building name
        unionId: unionId, // Use consistent union ID
      );
      
      print('✅ Payment proof uploaded via PaymentProofService for building: $buildingName, union: $unionId');
      
    } catch (e) {
      print('❌ Error storing payment proof via service: $e');
      rethrow;
    }
  }

  @override
  Widget build(BuildContext context) {
    double screenWidth = MediaQuery.of(context).size.width;
    
    return SingleChildScrollView(
      padding: EdgeInsets.all(screenWidth > 1200 ? 40 : screenWidth > 800 ? 24 : 16),
      child: Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: screenWidth > 1200 ? 900 : screenWidth > 800 ? 700 : double.infinity,
          ),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Card(
                  child: Padding(
                    padding: EdgeInsets.all(screenWidth > 800 ? 24 : 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Upload Payment Proof',
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontSize: screenWidth > 800 ? 24 : null,
                          ),
                        ),
                        SizedBox(height: screenWidth > 800 ? 24 : 16),
                        
                        // Payment Type Dropdown
                        DropdownButtonFormField<String>(
                          value: selectedPaymentType,
                          decoration: const InputDecoration(
                            labelText: 'What kind of fees are you paying?',
                            border: OutlineInputBorder(),
                            prefixIcon: Icon(Icons.category),
                          ),
                          items: paymentTypes.map((type) {
                            return DropdownMenuItem(value: type, child: Text(type));
                          }).toList(),
                          onChanged: (val) => setState(() => selectedPaymentType = val),
                          validator: (value) => value == null ? 'Please select payment type' : null,
                        ),
                        SizedBox(height: screenWidth > 800 ? 24 : 16),
                        
                        // Amount Field
                        TextFormField(
                          controller: _amountController,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(
                            labelText: 'Amount Paid',
                            border: OutlineInputBorder(),
                            prefixIcon: Icon(Icons.currency_exchange),
                            prefixText: 'PKR ',
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter amount';
                            }
                            if (double.tryParse(value) == null) {
                              return 'Please enter valid amount';
                            }
                            return null;
                          },
                        ),
                        SizedBox(height: screenWidth > 800 ? 24 : 16),

                        // Month and Year Selection Row
                        Row(
                          children: [
                            // Month Dropdown
                            Expanded(
                              flex: 2,
                              child: DropdownButtonFormField<String>(
                                value: selectedMonth,
                                decoration: const InputDecoration(
                                  labelText: 'Month',
                                  border: OutlineInputBorder(),
                                  prefixIcon: Icon(Icons.calendar_month),
                                ),
                                items: months.map((month) {
                                  return DropdownMenuItem(value: month, child: Text(month));
                                }).toList(),
                                onChanged: (val) => setState(() => selectedMonth = val),
                                validator: (value) => value == null ? 'Select month' : null,
                              ),
                            ),
                            const SizedBox(width: 16),
                            // Year Dropdown
                            Expanded(
                              flex: 1,
                              child: DropdownButtonFormField<int>(
                                value: selectedYear,
                                decoration: const InputDecoration(
                                  labelText: 'Year',
                                  border: OutlineInputBorder(),
                                  prefixIcon: Icon(Icons.calendar_today),
                                ),
                                items: List.generate(3, (index) {
                                  final year = DateTime.now().year - index;
                                  return DropdownMenuItem(
                                    value: year,
                                    child: Text(year.toString()),
                                  );
                                }),
                                onChanged: (val) => setState(() => selectedYear = val!),
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: screenWidth > 800 ? 32 : 24),

                        // House Number Field
                        TextFormField(
                          controller: _flatNumberController,
                          keyboardType: TextInputType.text,
                          decoration: const InputDecoration(
                            labelText: 'House Number',
                            border: OutlineInputBorder(),
                            prefixIcon: Icon(Icons.house),
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter house number';
                            }
                            if (value.trim().length < 1) {
                              return 'Please enter valid house number';
                            }
                            return null;
                          },
                        ),
                        SizedBox(height: screenWidth > 800 ? 24 : 16),
                        
                        // Image Selection Section
                        Text(
                          'Payment Proof Picture',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontSize: screenWidth > 800 ? 18 : null,
                          ),
                        ),
                        const SizedBox(height: 8),
                        
                        if (_selectedImage != null)
                          Container(
                            height: screenWidth > 800 ? 300 : 200,
                            width: double.infinity,
                            decoration: BoxDecoration(
                              border: Border.all(color: Colors.grey),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: FutureBuilder<Uint8List>(
                                future: _selectedImage!.readAsBytes(),
                                builder: (context, snapshot) {
                                  if (snapshot.connectionState == ConnectionState.waiting) {
                                    return const Center(
                                      child: CircularProgressIndicator(),
                                    );
                                  }
                                  
                                  if (snapshot.hasError || !snapshot.hasData || snapshot.data!.isEmpty) {
                                    return Container(
                                      color: Colors.grey[200],
                                      child: const Center(
                                        child: Column(
                                          mainAxisAlignment: MainAxisAlignment.center,
                                          children: [
                                            Icon(Icons.error, size: 40, color: Colors.red),
                                            SizedBox(height: 8),
                                            Text('Error loading image'),
                                          ],
                                        ),
                                      ),
                                    );
                                  }
                                  
                                  return Image.memory(
                                    snapshot.data!,
                                    fit: BoxFit.cover,
                                    errorBuilder: (context, error, stackTrace) {
                                      return Container(
                                        color: Colors.grey[200],
                                        child: const Center(
                                          child: Column(
                                            mainAxisAlignment: MainAxisAlignment.center,
                                            children: [
                                              Icon(Icons.broken_image, size: 40, color: Colors.grey),
                                              SizedBox(height: 8),
                                              Text('Cannot display image'),
                                            ],
                                          ),
                                        ),
                                      );
                                    },
                                  );
                                },
                              ),
                            ),
                          )
                        else
                          Container(
                            height: screenWidth > 800 ? 200 : 150,
                            decoration: BoxDecoration(
                              border: Border.all(color: Colors.grey, style: BorderStyle.solid),
                              borderRadius: BorderRadius.circular(8),
                              color: Colors.grey[100],
                            ),
                            child: const Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.image, size: 50, color: Colors.grey),
                                  SizedBox(height: 8),
                                  Text('No image selected'),
                                ],
                              ),
                            ),
                          ),
                          
                        SizedBox(height: screenWidth > 800 ? 24 : 16),
                        
                        // Image Selection Buttons
                        if (screenWidth > 800)
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              SizedBox(
                                width: 180,
                                child: ElevatedButton.icon(
                                  onPressed: _pickImage,
                                  icon: const Icon(Icons.photo_library),
                                  label: const Text('Gallery'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.blue,
                                    foregroundColor: Colors.white,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 16),
                              SizedBox(
                                width: 180,
                                child: ElevatedButton.icon(
                                  onPressed: _takePicture,
                                  icon: const Icon(Icons.camera_alt),
                                  label: const Text('Camera'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.green,
                                    foregroundColor: Colors.white,
                                  ),
                                ),
                              ),
                            ],
                          )
                        else
                          Row(
                            children: [
                              Expanded(
                                child: ElevatedButton.icon(
                                  onPressed: _pickImage,
                                  icon: const Icon(Icons.photo_library),
                                  label: const Text('Gallery'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.blue,
                                    foregroundColor: Colors.white,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: ElevatedButton.icon(
                                  onPressed: _takePicture,
                                  icon: const Icon(Icons.camera_alt),
                                  label: const Text('Camera'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.green,
                                    foregroundColor: Colors.white,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        
                        if (_selectedImage != null) ...[
                          SizedBox(height: screenWidth > 800 ? 24 : 16),
                          Center(
                            child: SizedBox(
                              width: screenWidth > 800 ? 200 : double.infinity,
                              child: ElevatedButton.icon(
                                onPressed: () => setState(() => _selectedImage = null),
                                icon: const Icon(Icons.clear),
                                label: const Text('Remove Image'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.red,
                                  foregroundColor: Colors.white,
                                ),
                              ),
                            ),
                          ),
                        ],
                        
                        SizedBox(height: screenWidth > 800 ? 32 : 24),
                        
                        // Upload Button
                        SizedBox(
                          height: screenWidth > 800 ? 60 : 50,
                          child: ElevatedButton(
                            onPressed: _isLoading ? null : _uploadPaymentProof,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.deepPurple,
                              foregroundColor: Colors.white,
                            ),
                            child: _isLoading
                              ? const Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                      ),
                                    ),
                                    SizedBox(width: 12),
                                    Text('Uploading...'),
                                  ],
                                )
                              : Text(
                                  'Submit Payment Proof',
                                  style: TextStyle(fontSize: screenWidth > 800 ? 18 : 16),
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
        ),
      ),
    );
  }

  @override
  void dispose() {
    _amountController.dispose();
    _flatNumberController.dispose();
    super.dispose();
  }
}

class PaymentRecordsTab extends StatefulWidget {
  final String userId;
  const PaymentRecordsTab({super.key, required this.userId});

  @override
  State<PaymentRecordsTab> createState() => _PaymentRecordsTabState();
}

class _PaymentRecordsTabState extends State<PaymentRecordsTab> {
  List<Map<String, dynamic>> paymentRecords = [];
  bool _isLoading = true;
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    _fetchPaymentRecords();
  }

  Future<void> _fetchPaymentRecords() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      // Get only approved payment records for this user from PaymentProofService
      final approvedPayments = await PaymentProofService.instance.getApprovedPayments();
      
      // Filter by current user ID
      final userApprovedPayments = approvedPayments.where((payment) => 
        payment['user_id'] == widget.userId
      ).toList();
      
      setState(() {
        paymentRecords = userApprovedPayments;
        _isLoading = false;
      });
      
      print('✅ Loaded ${paymentRecords.length} approved payment records for user: ${widget.userId}');
      
    } catch (e) {
      print('❌ Error loading approved payment records: $e');
      setState(() {
        _errorMessage = 'Error loading payment records: ${e.toString()}';
        _isLoading = false;
      });
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

  @override
  Widget build(BuildContext context) {
    double screenWidth = MediaQuery.of(context).size.width;
    
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (_errorMessage.isNotEmpty) {
      return Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: screenWidth > 1200 ? 600 : screenWidth > 800 ? 500 : double.infinity,
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error, size: screenWidth > 800 ? 80 : 64, color: Colors.red),
              SizedBox(height: screenWidth > 800 ? 24 : 16),
              Text(
                _errorMessage,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.red,
                  fontSize: screenWidth > 800 ? 18 : null,
                ),
              ),
              SizedBox(height: screenWidth > 800 ? 24 : 16),
              ElevatedButton(
                onPressed: _fetchPaymentRecords,
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    if (paymentRecords.isEmpty) {
      return Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: screenWidth > 1200 ? 600 : screenWidth > 800 ? 500 : double.infinity,
          ),
          child: Padding(
            padding: EdgeInsets.all(screenWidth > 800 ? 32 : 16),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.verified, size: screenWidth > 800 ? 80 : 64, color: Colors.green[300]),
                SizedBox(height: screenWidth > 800 ? 24 : 16),
                Text(
                  'No approved payment records found',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: Colors.black87,
                    fontWeight: FontWeight.bold,
                    fontSize: screenWidth > 800 ? 20 : null,
                  ),
                ),
                SizedBox(height: screenWidth > 800 ? 16 : 8),
                Text(
                  'Approved payment proofs by union incharge will appear here',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.grey[600],
                    fontSize: screenWidth > 800 ? 16 : null,
                  ),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: screenWidth > 800 ? 8 : 4),
                Text(
                  'Submit payment proofs and wait for union incharge approval',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Colors.grey[500],
                    fontStyle: FontStyle.italic,
                    fontSize: screenWidth > 800 ? 14 : null,
                  ),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: screenWidth > 800 ? 24 : 16),
                ElevatedButton.icon(
                  onPressed: _fetchPaymentRecords,
                  icon: const Icon(Icons.refresh),
                  label: const Text('Refresh'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }
    
    return RefreshIndicator(
      onRefresh: _fetchPaymentRecords,
      child: Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: screenWidth > 1200 ? 900 : screenWidth > 800 ? 700 : double.infinity,
          ),
          child: ListView.builder(
            padding: EdgeInsets.all(screenWidth > 1200 ? 40 : screenWidth > 800 ? 24 : 16),
            itemCount: paymentRecords.length,
            itemBuilder: (context, index) {
              final record = paymentRecords[index];
              
              return Card(
                margin: EdgeInsets.only(bottom: screenWidth > 800 ? 16 : 12),
                child: ListTile(
                  contentPadding: EdgeInsets.all(screenWidth > 800 ? 24 : 16),
                  leading: CircleAvatar(
                    backgroundColor: _getStatusColor(record['status'] ?? 'pending'),
                    radius: screenWidth > 800 ? 30 : 25,
                    child: Icon(
                      record['status']?.toLowerCase() == 'approved' 
                        ? Icons.check 
                        : record['status']?.toLowerCase() == 'rejected'
                          ? Icons.close
                          : Icons.hourglass_empty,
                      color: Colors.white,
                      size: screenWidth > 800 ? 24 : 20,
                    ),
                  ),
                  title: Text(
                    record['payment_type'] ?? 'Unknown Payment',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: screenWidth > 800 ? 18 : null,
                    ),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(height: screenWidth > 800 ? 8 : 4),
                      Text(
                        'Amount: ${record['amount'] ?? '0'}',
                        style: TextStyle(fontSize: screenWidth > 800 ? 16 : null),
                      ),
                      Text(
                        'Date: ${_formatDate(record['upload_date'] ?? '')}',
                        style: TextStyle(fontSize: screenWidth > 800 ? 16 : null),
                      ),
                      if (record['reference_number'] != null && record['reference_number'].isNotEmpty)
                        Text(
                          'Ref: ${record['reference_number']}',
                          style: TextStyle(fontSize: screenWidth > 800 ? 16 : null),
                        ),
                      SizedBox(height: screenWidth > 800 ? 12 : 8),
                      Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: screenWidth > 800 ? 12 : 8,
                          vertical: screenWidth > 800 ? 6 : 4,
                        ),
                        decoration: BoxDecoration(
                          color: _getStatusColor(record['status'] ?? 'pending'),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          record['status']?.toUpperCase() ?? 'PENDING',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: screenWidth > 800 ? 14 : 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  trailing: record['payment_proof_url'] != null
                    ? Icon(
                        Icons.image, 
                        color: Colors.blue,
                        size: screenWidth > 800 ? 28 : 24,
                      )
                    : null,
                  onTap: () {
                    // Show detailed view in a dialog
                    _showPaymentDetails(context, record);
                  },
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  void _showPaymentDetails(BuildContext context, Map<String, dynamic> record) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(record['payment_type'] ?? 'Payment Details'),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                                  _buildDetailRow('Amount', '${record['amount'] ?? '0'}'),
                _buildDetailRow('Date', _formatDate(record['upload_date'] ?? '')),
                if (record['reference_number'] != null && record['reference_number'].isNotEmpty)
                  _buildDetailRow('Reference', record['reference_number']),
                if (record['description'] != null && record['description'].isNotEmpty)
                  _buildDetailRow('Description', record['description']),
                _buildDetailRow('Status', record['status']?.toUpperCase() ?? 'PENDING'),
                if (record['admin_notes'] != null && record['admin_notes'].isNotEmpty)
                  _buildDetailRow('Admin Notes', record['admin_notes']),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Close'),
            ),
          ],
        );
      },
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
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
} 