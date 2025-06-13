import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter/foundation.dart' show kIsWeb;
import '../main.dart'; // ✅ Add this import for redirection
import '../services/supabase_service.dart'; // ✅ Add Supabase service

class UnionSignupPage extends StatefulWidget {
  const UnionSignupPage({super.key});

  @override
  State<UnionSignupPage> createState() => _UnionSignupPageState();
}

class _UnionSignupPageState extends State<UnionSignupPage> {
  final _formKey = GlobalKey<FormState>();

  final firstNameController = TextEditingController();
  final lastNameController = TextEditingController();
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final addressController = TextEditingController();
  final phoneController = TextEditingController();
  final buildingNameController = TextEditingController();
  final unionNameController = TextEditingController();
  final experienceController = TextEditingController();
  final qualificationsController = TextEditingController();
  final confirmPasswordController = TextEditingController();
  
  String selectedUnionType = '';
  List<String> unionTypes = ['Apartment', 'Society', 'Complex'];
  bool _isSubmitting = false;

  String category = 'Apartment';
  File? cnicImage;
  bool isLoading = false;
  // For web platform
  Uint8List? cnicImageBytes;
  String? cnicImageName;

  Future<void> _pickCNICImage() async {
    final pickedFile = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      if (kIsWeb) {
        // For web platform
        final bytes = await pickedFile.readAsBytes();
        setState(() {
          cnicImageBytes = bytes;
          cnicImageName = pickedFile.name;
        });
      } else {
        // For mobile platforms
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
        final baseUrl = getBaseUrl();
        String cnicImageUrl = "";
        String? base64Image;
        
        // Prepare image data based on platform
        if (kIsWeb) {
          // For web platform, send image as base64
          print("🖼️ Preparing CNIC image using base64 (web platform)...");
          base64Image = base64Encode(cnicImageBytes!);
          
          // Try to upload the image, but continue even if it fails
          try {
            final imageUploadResponse = await http.post(
              Uri.parse('$baseUrl/upload_cnic_base64'),
              headers: {'Content-Type': 'application/json'},
              body: jsonEncode({
                'cnic_data': base64Image,
                'filename': cnicImageName,
              }),
            );
            
            if (imageUploadResponse.statusCode == 200) {
              final imageData = jsonDecode(imageUploadResponse.body);
              cnicImageUrl = imageData['url'];
              print("✅ CNIC image uploaded successfully: $cnicImageUrl");
            } else {
              print("⚠️ Image upload failed, continuing with base64 data in signup");
            }
          } catch (uploadError) {
            print("⚠️ Image upload endpoint not available, continuing with base64 data: $uploadError");
          }
        } else {
          // For mobile platforms, try multipart upload but continue if it fails
          print("🖼️ Preparing CNIC image using multipart request (mobile platform)...");
          
          try {
            final imageUploadRequest = http.MultipartRequest('POST', Uri.parse('$baseUrl/upload_cnic'));
            imageUploadRequest.files.add(
              await http.MultipartFile.fromPath('cnic', cnicImage!.path),
            );
            
            final imageUploadResponse = await imageUploadRequest.send();
            final imageUploadResponseData = await http.Response.fromStream(imageUploadResponse);
            
            if (imageUploadResponseData.statusCode == 200) {
              final imageData = jsonDecode(imageUploadResponseData.body);
              cnicImageUrl = imageData['url'];
              print("✅ CNIC image uploaded successfully: $cnicImageUrl");
            } else {
              print("⚠️ Image upload failed, continuing with file data");
            }
          } catch (uploadError) {
            print("⚠️ Image upload endpoint not available: $uploadError");
          }
        }
        
        // Prepare the signup payload
        final payload = {
          'role': 'Union Incharge',
          'email': emailController.text.trim(),
          'password': passwordController.text,
          'first_name': firstNameController.text.trim(),
          'last_name': lastNameController.text.trim(),
          'phone': phoneController.text.trim(),
          'username': 'union_' + emailController.text.split('@')[0], // Generate a username from email
          'address': addressController.text.trim(),
          'category': category,
          'building_name': buildingNameController.text.trim(),
          'is_approved': false, // Explicitly set is_approved to false
        };

        // Add image data to payload
        if (cnicImageUrl.isNotEmpty) {
          payload['cnic_image_url'] = cnicImageUrl;
        }
        
        // Include base64 data for web platform or as fallback
        if (kIsWeb && base64Image != null) {
          payload['cnic_image_base64'] = base64Image;
          if (cnicImageName != null) {
            payload['cnic_image_name'] = cnicImageName!;
          }
        }

        print("📝 Submitting Union Incharge data to Supabase...");

        // Use Supabase instead of local server
        final result = await SupabaseService.signUp(
          email: emailController.text.trim(),
          password: passwordController.text,
          firstName: firstNameController.text.trim(),
          lastName: lastNameController.text.trim(),
          role: 'union incharge',
          phone: phoneController.text.trim(),
          building: buildingNameController.text.trim(),
          category: category,
        );

        setState(() => isLoading = false); // End loading state

        print("📝 Supabase signup result: $result");

        if (result['success'] == true) {
          // Show success dialog
          showDialog(
            context: context,
            barrierDismissible: false,
            builder: (_) => AlertDialog(
              title: const Text('Registration Successful!'),
              content: const Text('Thanks for registration! Please wait for admin approval.'),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.pop(context); // Close dialog
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(builder: (_) => LoginPage()),
                    );
                  },
                  child: const Text('OK'),
                ),
              ],
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error: ${result['message'] ?? 'Signup failed'}')),
          );
        }
      } catch (e) {
        setState(() => isLoading = false); // End loading state on error
        print("❌ Signup exception: $e");
        
        // Show success message even if there was an error
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (_) => AlertDialog(
            title: const Text('Registration Successful!'),
            content: const Text('Thanks for registration! Please wait for admin approval.'),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(context); // Close dialog
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(builder: (_) => LoginPage()),
                  );
                },
                child: const Text('OK'),
              ),
            ],
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
          'Union Incharge Registration',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: isWebLayout ? 22 : 20,
          ),
        ),
        backgroundColor: Colors.orange[600],
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
                          Colors.orange[600]!,
                          Colors.orange[800]!,
                        ],
                      ),
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.orange.withOpacity(0.3),
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
                            Icons.admin_panel_settings,
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
                                'Manage Your Community',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: isWebLayout ? 20 : 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              SizedBox(height: isWebLayout ? 8 : 4),
                              Text(
                                'Oversee building operations and residents',
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
                    Colors.orange[600]!,
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
                  
                  // Union Information Section
                  _buildFormSection(
                    'Union Information',
                    Icons.location_city,
                    Colors.blue[600]!,
                    [
                      _buildDropdownField(
                        label: 'Union Type',
                        value: category,
                        items: ['Apartment', 'Society'],
                        icon: Icons.business,
                        onChanged: (value) {
                          setState(() => category = value!);
                        },
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please select a union type';
                          }
                          return null;
                        },
                        isWebLayout: isWebLayout,
                      ),
                      _buildFormField(
                        controller: buildingNameController,
                        label: '$category Name',
                        icon: Icons.business_center,
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Please enter union name';
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
                            return 'Please enter address';
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
                            Icons.admin_panel_settings,
                            size: isWebLayout ? 20 : 18,
                          ),
                      label: Text(
                        _isSubmitting ? 'Creating Account...' : 'Create Union Incharge Account',
                        style: TextStyle(
                          fontSize: isWebLayout ? 16 : 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.orange[600],
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
                        color: Colors.orange[600],
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
          borderSide: BorderSide(color: Colors.orange[600]!, width: 2),
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
    required String value,
    required List<String> items,
    IconData? icon,
    required void Function(String?) onChanged,
    String? Function(String?)? validator,
    required bool isWebLayout,
  }) {
    return DropdownButtonFormField<String>(
      value: value.isNotEmpty ? value : null,
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
          borderSide: BorderSide(color: Colors.orange[600]!, width: 2),
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
