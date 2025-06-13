import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../main.dart';
import 'dart:async';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:image_picker/image_picker.dart';
import '../services/supabase_service.dart';

class ResidentSignupPage extends StatefulWidget {
  const ResidentSignupPage({super.key});

  @override
  State<ResidentSignupPage> createState() => _ResidentSignupPageState();
}

class _ResidentSignupPageState extends State<ResidentSignupPage> {
  final _formKey = GlobalKey<FormState>();
  final firstNameController = TextEditingController();
  final lastNameController = TextEditingController();
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final phoneController = TextEditingController();
  final addressController = TextEditingController();
  final usernameController = TextEditingController();
  final buildingController = TextEditingController();
  final flatNumberController = TextEditingController();
  final confirmPasswordController = TextEditingController();
  
  bool _isSubmitting = false;

  String residentType = 'Owner';
  String category = 'Apartment';
  String? selectedHouseCategory;
  String? selectedBuilding;
  String? selectedPropertyType;
  Uint8List? cnicImageBytes;
  String? cnicImageName;

  List<String> registeredApartments = [];
  List<String> registeredSocieties = [];
  bool isLoadingBuildings = true;
  String? buildingsError;
  Timer? _refreshTimer;
  
  List<String> houseCategoryOptions = ['Apartment', 'Society'];
  List<String> propertyTypeOptions = ['Rent', 'Owned'];

  @override
  void initState() {
    super.initState();
    fetchBuildings();
    // Set up periodic refresh every 30 seconds
    _refreshTimer = Timer.periodic(const Duration(seconds: 30), (timer) {
      fetchBuildings();
    });
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }

  Future<void> fetchBuildings() async {
    try {
      setState(() {
        isLoadingBuildings = true;
        buildingsError = null;
      });

      print("🏢 Fetching buildings from Supabase...");
      final buildings = await SupabaseService.getBuildings();
      
      // Process buildings data to separate apartments and societies
      List<String> apartments = [];
      List<String> societies = [];
      
      for (var building in buildings) {
        final name = building['name']?.toString() ?? '';
        final category = building['category']?.toString()?.toLowerCase() ?? '';
        
        if (name.isNotEmpty) {
          if (category.contains('apartment')) {
            apartments.add(name);
          } else if (category.contains('society')) {
            societies.add(name);
          } else {
            // Default to apartment if category is unclear
            apartments.add(name);
          }
        }
      }
      
      setState(() {
        registeredApartments = apartments;
        registeredSocieties = societies;
        isLoadingBuildings = false;
        buildingsError = null;
      });
      
      print("✅ Loaded ${apartments.length} apartments and ${societies.length} societies from Supabase");
    } catch (e) {
      print("❌ Error fetching buildings from Supabase: $e");
      setState(() {
        registeredApartments = [];
        registeredSocieties = [];
        isLoadingBuildings = false;
        buildingsError = "Failed to load buildings: ${e.toString()}";
      });
    }
  }

  Future<void> _pickCNICImage() async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1920,
        maxHeight: 1080,
        imageQuality: 85,
      );

      if (image != null) {
        final Uint8List imageBytes = await image.readAsBytes();
        setState(() {
          cnicImageBytes = imageBytes;
          cnicImageName = image.name;
        });
        print("✅ CNIC image selected: ${image.name} (${imageBytes.length} bytes)");
      }
    } catch (e) {
      print("❌ Error picking CNIC image: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error selecting image: $e')),
      );
    }
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) return;

    if (selectedHouseCategory == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select house category (Apartment/Society)')),
      );
      return;
    }

    if (selectedBuilding == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please select your ${selectedHouseCategory!.toLowerCase()}')),
      );
      return;
    }

    if (selectedPropertyType == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select property type (Rent/Owned)')),
      );
      return;
    }

    if (cnicImageBytes == null || cnicImageName == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please upload your CNIC image')),
      );
      return;
    }

    final String base64Image = base64Encode(cnicImageBytes!);
    print("🖼️ CNIC image prepared for upload: ${cnicImageName} (${cnicImageBytes!.length} bytes)");

    try {
      setState(() => _isSubmitting = true);
      
      // Send the signup data directly to Supabase (no separate image upload needed)
      print("📝 Submitting resident signup data to Supabase...");
      
      final result = await SupabaseService.signUp(
        email: emailController.text.trim(),
        password: passwordController.text,
        firstName: firstNameController.text.trim(),
        lastName: lastNameController.text.trim(),
        role: 'resident',
        phone: phoneController.text.trim(),
        building: selectedBuilding!,
        flatNo: flatNumberController.text.trim(),
        category: selectedHouseCategory!,
      );

      setState(() => _isSubmitting = false);
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
                Text('Your resident application has been submitted successfully!'),
                SizedBox(height: 12),
                Text(
                  'Next steps:',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                Text('• Wait for union incharge approval'),
                Text('• You will receive notification once approved'),
                Text('• Then you can access all community features'),
              ],
            ),
            actions: [
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                  Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => LoginPage()));
                },
                style: ElevatedButton.styleFrom(backgroundColor: Colors.blue[600]),
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
      setState(() => _isSubmitting = false);
      print('❌ Exception during signup: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
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
          'Resident Registration',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: isWebLayout ? 22 : 20,
          ),
        ),
        backgroundColor: Colors.blue[600],
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
                          Colors.blue[600]!,
                          Colors.blue[800]!,
                        ],
                      ),
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.blue.withOpacity(0.3),
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
                            Icons.home,
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
                                'Join Your Community',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: isWebLayout ? 20 : 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              SizedBox(height: isWebLayout ? 8 : 4),
                              Text(
                                'Connect with your residential community',
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
                    Colors.blue[600]!,
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
                  
                  // Residential Information Section
                  _buildFormSection(
                    'Residential Information',
                    Icons.location_city,
                    Colors.orange[600]!,
                    [
                      _buildDropdownField(
                        label: 'House Category',
                        value: selectedHouseCategory,
                        items: houseCategoryOptions,
                        icon: Icons.category,
                        onChanged: (value) {
                          setState(() {
                            selectedHouseCategory = value;
                            selectedBuilding = null; // Reset building selection
                          });
                        },
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please select house category';
                          }
                          return null;
                        },
                        isWebLayout: isWebLayout,
                      ),
                      if (selectedHouseCategory != null) ...[
                        _buildDropdownField(
                          label: selectedHouseCategory == 'Apartment' 
                              ? 'Select Apartment' 
                              : 'Select Society',
                          value: selectedBuilding,
                          items: selectedHouseCategory == 'Apartment' 
                              ? registeredApartments 
                              : registeredSocieties,
                          icon: selectedHouseCategory == 'Apartment' 
                              ? Icons.apartment 
                              : Icons.location_city,
                          onChanged: (value) {
                            setState(() {
                              selectedBuilding = value;
                            });
                          },
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please select your ${selectedHouseCategory?.toLowerCase()}';
                            }
                            return null;
                          },
                          isWebLayout: isWebLayout,
                          isLoading: isLoadingBuildings,
                          errorMessage: buildingsError,
                        ),
                      ],
                      _buildDropdownField(
                        label: 'Property Type',
                        value: selectedPropertyType,
                        items: propertyTypeOptions,
                        icon: Icons.home_outlined,
                        onChanged: (value) {
                          setState(() {
                            selectedPropertyType = value;
                          });
                        },
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please select property type (Rent/Owned)';
                          }
                          return null;
                        },
                        isWebLayout: isWebLayout,
                      ),
                      _buildFormField(
                        controller: flatNumberController,
                        label: selectedHouseCategory == 'Apartment' 
                            ? 'Flat/Apartment Number'
                            : 'House Number',
                        icon: Icons.home_work,
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Please enter your ${selectedHouseCategory == 'Apartment' ? 'flat' : 'house'} number';
                          }
                          return null;
                        },
                        isWebLayout: isWebLayout,
                      ),
                      _buildFormField(
                        controller: addressController,
                        label: 'Complete Address',
                        icon: Icons.location_on,
                        maxLines: 3,
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Please enter your address';
                          }
                          return null;
                        },
                        isWebLayout: isWebLayout,
                      ),
                      _buildCNICUploadField(isWebLayout),
                    ],
                    isWebLayout,
                  ),
                  
                  SizedBox(height: isWebLayout ? 24 : 20),
                  
                  // Security Section
                  _buildFormSection(
                    'Account Security',
                    Icons.security,
                    Colors.green[600]!,
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
                            Icons.person_add,
                            size: isWebLayout ? 20 : 18,
                          ),
                      label: Text(
                        _isSubmitting ? 'Creating Account...' : 'Create Resident Account',
                        style: TextStyle(
                          fontSize: isWebLayout ? 16 : 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue[600],
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
                        color: Colors.blue[600],
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
          borderSide: BorderSide(color: Colors.blue[600]!, width: 2),
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
    bool isLoading = false,
    String? errorMessage,
  }) {
    if (isLoading) {
      return Container(
        height: isWebLayout ? 60 : 56,
        decoration: BoxDecoration(
          color: Colors.grey[50],
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey[300]!),
        ),
        child: Row(
          children: [
            if (icon != null) ...[
              SizedBox(width: isWebLayout ? 16 : 12),
              Icon(icon, color: Colors.grey[600], size: isWebLayout ? 22 : 20),
              SizedBox(width: isWebLayout ? 12 : 8),
            ],
            Expanded(
              child: Row(
                children: [
                  SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.blue[600]!),
                    ),
                  ),
                  SizedBox(width: 12),
                  Text(
                    'Loading...',
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: isWebLayout ? 15 : 13,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    if (errorMessage != null) {
      return Container(
        width: double.infinity,
        padding: EdgeInsets.all(isWebLayout ? 16 : 12),
        decoration: BoxDecoration(
          color: Colors.red[50],
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.red[300]!),
        ),
        child: Row(
          children: [
            Icon(Icons.error_outline, color: Colors.red[600], size: 20),
            SizedBox(width: 8),
            Expanded(
              child: Text(
                errorMessage,
                style: TextStyle(
                  color: Colors.red[600],
                  fontSize: isWebLayout ? 14 : 12,
                ),
              ),
            ),
          ],
        ),
      );
    }

    if (items.isEmpty) {
      return Container(
        width: double.infinity,
        padding: EdgeInsets.all(isWebLayout ? 16 : 12),
        decoration: BoxDecoration(
          color: Colors.orange[50],
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.orange[300]!),
        ),
        child: Row(
          children: [
            Icon(Icons.info_outline, color: Colors.orange[600], size: 20),
            SizedBox(width: 8),
            Expanded(
              child: Text(
                'No ${label.toLowerCase()} available',
                style: TextStyle(
                  color: Colors.orange[600],
                  fontSize: isWebLayout ? 14 : 12,
                ),
              ),
            ),
          ],
        ),
      );
    }

    return DropdownButtonFormField<String>(
      value: (value != null && value.isNotEmpty && items.contains(value)) ? value : null,
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
          borderSide: BorderSide(color: Colors.blue[600]!, width: 2),
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

  Widget _buildCNICUploadField(bool isWebLayout) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(isWebLayout ? 16 : 12),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: cnicImageBytes != null ? Colors.green[300]! : Colors.grey[300]!,
          width: cnicImageBytes != null ? 2 : 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.credit_card,
                color: cnicImageBytes != null ? Colors.green[600] : Colors.grey[600],
                size: isWebLayout ? 22 : 20,
              ),
              SizedBox(width: isWebLayout ? 12 : 8),
              Text(
                'CNIC Image Upload',
                style: TextStyle(
                  fontSize: isWebLayout ? 15 : 13,
                  fontWeight: FontWeight.w500,
                  color: cnicImageBytes != null ? Colors.green[600] : Colors.grey[600],
                ),
              ),
              if (cnicImageBytes != null) ...[
                SizedBox(width: 8),
                Icon(
                  Icons.check_circle,
                  color: Colors.green[600],
                  size: 18,
                ),
              ],
            ],
          ),
          
          SizedBox(height: isWebLayout ? 12 : 8),
          
          if (cnicImageBytes != null) ...[
            Container(
              width: double.infinity,
              padding: EdgeInsets.all(isWebLayout ? 12 : 8),
              decoration: BoxDecoration(
                color: Colors.green[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.green[200]!),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.image,
                    color: Colors.green[600],
                    size: isWebLayout ? 20 : 18,
                  ),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      cnicImageName ?? 'CNIC Image Selected',
                      style: TextStyle(
                        fontSize: isWebLayout ? 14 : 12,
                        color: Colors.green[600],
                        fontWeight: FontWeight.w500,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  TextButton.icon(
                    onPressed: () {
                      setState(() {
                        cnicImageBytes = null;
                        cnicImageName = null;
                      });
                    },
                    icon: Icon(
                      Icons.close,
                      size: 16,
                      color: Colors.red[600],
                    ),
                    label: Text(
                      'Remove',
                      style: TextStyle(
                        fontSize: isWebLayout ? 12 : 11,
                        color: Colors.red[600],
                      ),
                    ),
                    style: TextButton.styleFrom(
                      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: isWebLayout ? 8 : 6),
          ],
          
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _pickCNICImage,
              icon: Icon(
                cnicImageBytes != null ? Icons.refresh : Icons.upload,
                size: isWebLayout ? 18 : 16,
              ),
              label: Text(
                cnicImageBytes != null ? 'Change CNIC Image' : 'Upload CNIC Image',
                style: TextStyle(
                  fontSize: isWebLayout ? 14 : 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: cnicImageBytes != null ? Colors.orange[600] : Colors.blue[600],
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(
                  vertical: isWebLayout ? 12 : 10,
                  horizontal: isWebLayout ? 16 : 12,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                elevation: 2,
              ),
            ),
          ),
          
          if (cnicImageBytes == null) ...[
            SizedBox(height: isWebLayout ? 8 : 6),
            Text(
              '* Please upload a clear image of your CNIC (front side)',
              style: TextStyle(
                fontSize: isWebLayout ? 12 : 11,
                color: Colors.grey[600],
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
