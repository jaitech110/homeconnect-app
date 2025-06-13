import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import '../main.dart'; // ✅ Adjust path if needed
import '../services/supabase_service.dart';

class ServiceProviderSignupPage extends StatefulWidget {
  const ServiceProviderSignupPage({super.key});

  @override
  State<ServiceProviderSignupPage> createState() => _ServiceProviderSignupPageState();
}

class _ServiceProviderSignupPageState extends State<ServiceProviderSignupPage> {
  final _formKey = GlobalKey<FormState>();

  final firstNameController = TextEditingController();
  final lastNameController = TextEditingController();
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final phoneController = TextEditingController();
  final businessNameController = TextEditingController();
  final shopAddressController = TextEditingController();
  final postalCodeController = TextEditingController();
  final companyController = TextEditingController();
  final experienceController = TextEditingController();
  final descriptionController = TextEditingController();
  final addressController = TextEditingController();
  final pricingController = TextEditingController();
  final confirmPasswordController = TextEditingController();

  File? cnicImage;
  Uint8List? cnicImageBytes;
  String? cnicImageName;
  bool isLoading = false;
  String? selectedBusinessCategory;
  String selectedCategory = '';
  List<String> serviceCategories = [
    'Home & Utility Service',
    'Food & Catering',
    'Transport & Mobility'
  ];
  bool _isSubmitting = false;

  final List<String> businessCategories = [
    'Home & Utility Service',
    'Food & Catering',
    'Transport & Mobility',
  ];

  Future<void> _pickCNICImage() async {
    if (kIsWeb) {
      // Web platform - use file picker
      final ImagePicker picker = ImagePicker();
      final XFile? pickedFile = await picker.pickImage(source: ImageSource.gallery);
      
      if (pickedFile != null) {
        final bytes = await pickedFile.readAsBytes();
        setState(() {
          cnicImageBytes = bytes;
          cnicImageName = pickedFile.name;
        });
      }
    } else {
      // Mobile platform - use existing implementation
      final pickedFile = await ImagePicker().pickImage(source: ImageSource.gallery);
      if (pickedFile != null) {
        setState(() => cnicImage = File(pickedFile.path));
      }
    }
  }

  Future<void> _submitForm() async {
    if (_formKey.currentState!.validate()) {
      // Check if image is selected based on platform
      if (kIsWeb && cnicImageBytes == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please upload your CNIC image')),
        );
        return;
      } else if (!kIsWeb && cnicImage == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please upload your CNIC image')),
        );
        return;
      }

      setState(() => isLoading = true);

      try {
        print("📝 Submitting Service Provider data to Supabase...");

        // Use Supabase for signup (no separate image upload needed)
        final result = await SupabaseService.signUp(
          email: emailController.text.trim(),
          password: passwordController.text,
          firstName: firstNameController.text.trim(),
          lastName: lastNameController.text.trim(),
          role: 'service provider',
          phone: phoneController.text.trim(),
          businessName: companyController.text.trim(),
          category: selectedBusinessCategory ?? 'Home & Utility Service',
        );

        setState(() => isLoading = false);
        print("📝 Supabase signup result: $result");

        if (result['success'] == true) {
          showDialog(
            context: context,
            barrierDismissible: false,
            builder: (_) => AlertDialog(
              title: Row(
                children: [
                  Icon(Icons.check_circle, color: Colors.green, size: 28),
                  SizedBox(width: 12),
                  Text('Registration Successful'),
                ],
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Your service provider application has been submitted successfully!'),
                  SizedBox(height: 12),
                  Text(
                    'Next steps:',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  Text('• Wait for admin approval'),
                  Text('• You will receive notification once approved'),
                  Text('• Then you can start offering services to residents'),
                ],
              ),
              actions: [
                ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context);
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(builder: (_) => LoginPage()),
                    );
                  },
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.green[600]),
                  child: const Text('Go to Login'),
                ),
              ],
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(result['message'] ?? 'Signup failed'),
              backgroundColor: Colors.red,
            ),
          );
        }
      } catch (e) {
        setState(() => isLoading = false);
        print("❌ Signup exception: $e");
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isWebLayout = screenWidth > 600;
    final maxWidth = screenWidth > 1200 ? 800.0 : 
                     screenWidth > 800 ? 600.0 : 
                     screenWidth > 600 ? 500.0 : double.infinity;
    
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: Text(
          'Service Provider Registration',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: isWebLayout ? 22 : 20,
          ),
        ),
        backgroundColor: Colors.green[600],
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
      ),
      body: Center(
        child: Container(
          constraints: BoxConstraints(maxWidth: maxWidth),
          child: SingleChildScrollView(
            padding: EdgeInsets.all(isWebLayout ? 32 : 20),
            child: Form(
              key: _formKey,
              child: Column(
                children: [
                  // Header Info Card
                  Container(
                    padding: EdgeInsets.all(isWebLayout ? 24 : 20),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          Colors.green[600]!,
                          Colors.green[800]!,
                        ],
                      ),
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.green.withOpacity(0.3),
                          blurRadius: 15,
                          offset: const Offset(0, 5),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: EdgeInsets.all(isWebLayout ? 16 : 12),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(
                            Icons.work,
                            color: Colors.white,
                            size: isWebLayout ? 32 : 28,
                          ),
                        ),
                        SizedBox(width: isWebLayout ? 20 : 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Grow Your Business',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: isWebLayout ? 20 : 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              SizedBox(height: isWebLayout ? 8 : 4),
                              Text(
                                'Offer professional services to residents',
                                style: TextStyle(
                                  color: Colors.white70,
                                  fontSize: isWebLayout ? 16 : 14,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  SizedBox(height: isWebLayout ? 32 : 24),
                  
                  // Personal Information Section
                  _buildFormSection(
                    'Personal Information',
                    Icons.person,
                    Colors.green[600]!,
                    [
                      _buildFormField(
                        controller: firstNameController,
                        label: 'First Name',
                        icon: Icons.person_outline,
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Please enter your first name';
                          }
                          return null;
                        },
                        isWebLayout: isWebLayout,
                      ),
                      _buildFormField(
                        controller: lastNameController,
                        label: 'Last Name',
                        icon: Icons.person_outline,
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Please enter your last name';
                          }
                          return null;
                        },
                        isWebLayout: isWebLayout,
                      ),
                      _buildFormField(
                        controller: emailController,
                        label: 'Email Address',
                        icon: Icons.email,
                        keyboardType: TextInputType.emailAddress,
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Please enter your email';
                          }
                          if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
                            return 'Please enter a valid email';
                          }
                          return null;
                        },
                        isWebLayout: isWebLayout,
                      ),
                      _buildFormField(
                        controller: phoneController,
                        label: 'Phone Number',
                        icon: Icons.phone,
                        keyboardType: TextInputType.phone,
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Please enter your phone number';
                          }
                          return null;
                        },
                        isWebLayout: isWebLayout,
                      ),
                    ],
                    isWebLayout,
                  ),
                  
                  SizedBox(height: isWebLayout ? 24 : 20),
                  
                  // CNIC Upload Section
                  _buildFormSection(
                    'Identity Verification',
                    Icons.credit_card,
                    Colors.red[600]!,
                    [
                      _buildCNICUploadField(isWebLayout),
                    ],
                    isWebLayout,
                  ),
                  
                  SizedBox(height: isWebLayout ? 24 : 20),
                  
                  // Business Information Section
                  _buildFormSection(
                    'Business Information',
                    Icons.business,
                    Colors.orange[600]!,
                    [
                      _buildDropdownField(
                        label: 'Service Category',
                        value: selectedBusinessCategory,
                        items: serviceCategories,
                        icon: Icons.category,
                        onChanged: (value) {
                          setState(() => selectedBusinessCategory = value!);
                        },
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please select a service category';
                          }
                          return null;
                        },
                        isWebLayout: isWebLayout,
                      ),
                      _buildFormField(
                        controller: companyController,
                        label: 'Company/Business Name',
                        icon: Icons.business_center,
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Please enter your business name';
                          }
                          return null;
                        },
                        isWebLayout: isWebLayout,
                      ),

                      _buildFormField(
                        controller: descriptionController,
                        label: 'Service Description',
                        icon: Icons.description,
                        maxLines: 3,
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Please enter service description';
                          }
                          return null;
                        },
                        isWebLayout: isWebLayout,
                      ),
                    ],
                    isWebLayout,
                  ),
                  
                  SizedBox(height: isWebLayout ? 24 : 20),
                  
                  // Address & Pricing Section
                  _buildFormSection(
                    'Business Details',
                    Icons.location_on,
                    Colors.blue[600]!,
                    [
                      _buildFormField(
                        controller: addressController,
                        label: 'Business Address',
                        icon: Icons.location_on,
                        maxLines: 2,
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Please enter your business address';
                          }
                          return null;
                        },
                        isWebLayout: isWebLayout,
                      ),
                      _buildFormField(
                        controller: pricingController,
                        label: 'Pricing Information',
                        icon: Icons.attach_money,
                        maxLines: 2,
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Please enter pricing information';
                          }
                          return null;
                        },
                        isWebLayout: isWebLayout,
                      ),
                    ],
                    isWebLayout,
                  ),
                  
                  SizedBox(height: isWebLayout ? 24 : 20),
                  
                  // Security Section
                  _buildFormSection(
                    'Account Security',
                    Icons.security,
                    Colors.purple[600]!,
                    [
                      _buildFormField(
                        controller: passwordController,
                        label: 'Password',
                        icon: Icons.lock,
                        isPassword: true,
                        validator: (value) {
                          if (value == null || value.length < 6) {
                            return 'Password must be at least 6 characters';
                          }
                          return null;
                        },
                        isWebLayout: isWebLayout,
                      ),
                      _buildFormField(
                        controller: confirmPasswordController,
                        label: 'Confirm Password',
                        icon: Icons.lock_outline,
                        isPassword: true,
                        validator: (value) {
                          if (value != passwordController.text) {
                            return 'Passwords do not match';
                          }
                          return null;
                        },
                        isWebLayout: isWebLayout,
                      ),
                    ],
                    isWebLayout,
                  ),
                  
                  SizedBox(height: isWebLayout ? 32 : 24),
                  
                  // Submit Button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _isSubmitting ? null : _submitForm,
                      icon: _isSubmitting 
                        ? SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          )
                        : Icon(
                            Icons.business_center,
                            size: isWebLayout ? 20 : 18,
                          ),
                      label: Text(
                        _isSubmitting ? 'Creating Account...' : 'Create Service Provider Account',
                        style: TextStyle(
                          fontSize: isWebLayout ? 16 : 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green[600],
                        foregroundColor: Colors.white,
                        padding: EdgeInsets.symmetric(
                          vertical: isWebLayout ? 18 : 16,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 4,
                      ),
                    ),
                  ),
                  
                  SizedBox(height: isWebLayout ? 20 : 16),
                  
                  // Login Link
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: Text(
                      'Already have an account? Login here',
                      style: TextStyle(
                        color: Colors.green[600],
                        fontSize: isWebLayout ? 14 : 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFormSection(
    String title, 
    IconData icon, 
    Color color, 
    List<Widget> fields,
    bool isWebLayout,
  ) {
    return Container(
      padding: EdgeInsets.all(isWebLayout ? 24 : 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
        border: Border.all(
          color: color.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section Header
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(isWebLayout ? 12 : 8),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  icon,
                  color: color,
                  size: isWebLayout ? 24 : 20,
                ),
              ),
              SizedBox(width: isWebLayout ? 12 : 8),
              Text(
                title,
                style: TextStyle(
                  fontSize: isWebLayout ? 18 : 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
          
          SizedBox(height: isWebLayout ? 20 : 16),
          
          // Form Fields
          ...fields.map((field) => Padding(
            padding: EdgeInsets.only(bottom: isWebLayout ? 16 : 12),
            child: field,
          )).toList(),
        ],
      ),
    );
  }

  Widget _buildFormField({
    required TextEditingController controller,
    required String label,
    IconData? icon,
    bool isPassword = false,
    TextInputType? keyboardType,
    int maxLines = 1,
    String? Function(String?)? validator,
    required bool isWebLayout,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: isPassword,
      keyboardType: keyboardType,
      maxLines: maxLines,
      style: TextStyle(
        fontSize: isWebLayout ? 16 : 14,
        color: Colors.black87,
      ),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(
          color: Colors.grey[600],
          fontSize: isWebLayout ? 15 : 13,
        ),
        prefixIcon: icon != null 
          ? Icon(
              icon,
              color: Colors.grey[600],
              size: isWebLayout ? 22 : 20,
            )
          : null,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey[300]!),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey[300]!),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.green[600]!, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.red[600]!, width: 2),
        ),
        filled: true,
        fillColor: Colors.grey[50],
        contentPadding: EdgeInsets.symmetric(
          horizontal: isWebLayout ? 16 : 12,
          vertical: isWebLayout ? 16 : 14,
        ),
      ),
      validator: validator,
    );
  }

  Widget _buildDropdownField({
    required String label,
    required String? value,
    required List<String> items,
    IconData? icon,
    required void Function(String?) onChanged,
    String? Function(String?)? validator,
    required bool isWebLayout,
  }) {
    return DropdownButtonFormField<String>(
      value: (value != null && value.isNotEmpty) ? value : null,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(
          color: Colors.grey[600],
          fontSize: isWebLayout ? 15 : 13,
        ),
        prefixIcon: icon != null 
          ? Icon(
              icon,
              color: Colors.grey[600],
              size: isWebLayout ? 22 : 20,
            )
          : null,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey[300]!),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey[300]!),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.green[600]!, width: 2),
        ),
        filled: true,
        fillColor: Colors.grey[50],
        contentPadding: EdgeInsets.symmetric(
          horizontal: isWebLayout ? 16 : 12,
          vertical: isWebLayout ? 16 : 14,
        ),
      ),
      dropdownColor: Colors.white,
      icon: Icon(Icons.keyboard_arrow_down, color: Colors.grey[600]),
      style: TextStyle(
        fontSize: isWebLayout ? 16 : 14,
        color: Colors.black87,
      ),
      items: items.map((item) {
        return DropdownMenuItem<String>(
          value: item,
          child: Text(
            item,
            style: TextStyle(
              fontSize: isWebLayout ? 16 : 14,
              fontWeight: FontWeight.w500,
            ),
          ),
        );
      }).toList(),
      onChanged: onChanged,
      validator: validator,
    );
  }

  InputDecoration _fieldDecoration(String label) {
    return InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(color: Colors.white),
      border: const OutlineInputBorder(),
      enabledBorder: const OutlineInputBorder(
        borderSide: BorderSide(color: Colors.white),
      ),
      focusedBorder: const OutlineInputBorder(
        borderSide: BorderSide(color: Colors.blueAccent),
      ),
    );
  }

  Widget _buildPostalCodeField() {
    return TextFormField(
      controller: postalCodeController,
      style: const TextStyle(color: Colors.white),
      keyboardType: TextInputType.number,
      decoration: _fieldDecoration('Postal Code'),
      validator: (value) {
        if (value == null || value.isEmpty) return 'Enter postal code';
        // Pakistani postal code validation (5 digits)
        final postalCodeReg = RegExp(r'^[0-9]{5}$');
        if (!postalCodeReg.hasMatch(value.trim())) {
          return 'Enter valid 5-digit postal code';
        }
        return null;
      },
    );
  }
  
  Widget _buildCNICUploadField(bool isWebLayout) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey[300]!),
        borderRadius: BorderRadius.circular(12),
        color: Colors.grey[50],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ListTile(
            leading: Icon(
              Icons.credit_card,
              color: Colors.red[600],
              size: isWebLayout ? 28 : 24,
            ),
            title: Text(
              'CNIC Picture',
              style: TextStyle(
                fontSize: isWebLayout ? 16 : 14,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
            subtitle: Text(
              'Upload a clear photo of your CNIC',
              style: TextStyle(
                fontSize: isWebLayout ? 14 : 12,
                color: Colors.grey[600],
              ),
            ),
            trailing: ElevatedButton.icon(
              onPressed: _pickCNICImage,
              icon: Icon(
                Icons.camera_alt,
                size: isWebLayout ? 18 : 16,
              ),
              label: Text(
                'Upload',
                style: TextStyle(
                  fontSize: isWebLayout ? 14 : 12,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red[600],
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(
                  horizontal: isWebLayout ? 16 : 12,
                  vertical: isWebLayout ? 12 : 8,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ),
          
          // Show selected image preview
          if ((kIsWeb && cnicImageBytes != null) || (!kIsWeb && cnicImage != null))
            Container(
              margin: EdgeInsets.all(isWebLayout ? 16 : 12),
              padding: EdgeInsets.all(isWebLayout ? 12 : 8),
              decoration: BoxDecoration(
                color: Colors.green[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.green[200]!),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.check_circle,
                    color: Colors.green[600],
                    size: isWebLayout ? 20 : 18,
                  ),
                  SizedBox(width: isWebLayout ? 8 : 6),
                  Expanded(
                    child: Text(
                      kIsWeb 
                        ? 'CNIC image selected: ${cnicImageName ?? 'Unknown'}'
                        : 'CNIC image selected: ${cnicImage!.path.split('/').last}',
                      style: TextStyle(
                        color: Colors.green[700],
                        fontSize: isWebLayout ? 14 : 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
