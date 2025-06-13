import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../../main.dart';
import '../../services/enhanced_persistence_service.dart';

class UnionInchargeDetailsScreen extends StatefulWidget {
  final String userId;
  final String? buildingName;
  final String? unionId;
  
  const UnionInchargeDetailsScreen({
    super.key,
    required this.userId,
    this.buildingName,
    this.unionId,
  });

  @override
  State<UnionInchargeDetailsScreen> createState() => _UnionInchargeDetailsScreenState();
}

class _UnionInchargeDetailsScreenState extends State<UnionInchargeDetailsScreen> {
  bool _isLoading = false;
  Map<String, dynamic>? _unionInchargeDetails;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadUnionInchargeDetails();
  }

  Future<void> _loadUnionInchargeDetails() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // First try to get details from backend
      await _fetchFromBackend();
      
      // If no backend data, try local storage
      if (_unionInchargeDetails == null) {
        await _loadFromLocalStorage();
      }
    } catch (e) {
      print('Error loading union incharge details: $e');
      setState(() {
        _errorMessage = 'Failed to load union incharge details';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _fetchFromBackend() async {
    try {
      final baseUrl = getBaseUrl();
      String url;
      
      if (widget.unionId != null && widget.unionId!.isNotEmpty) {
        // If we have union ID, use it directly
        url = '$baseUrl/union_incharges/${widget.unionId}';
      } else {
        // Otherwise, search by building name
        url = '$baseUrl/union_incharges/by_building?building_name=${Uri.encodeComponent(widget.buildingName ?? '')}';
      }
      
      print('🔗 Fetching union incharge details from: $url');
      print('👤 Resident building: ${widget.buildingName}');
      
      final response = await http.get(
        Uri.parse(url),
        headers: {'Content-Type': 'application/json'},
      ).timeout(const Duration(seconds: 10));

      print('📥 Response status: ${response.statusCode}');
      print('📥 Response body: ${response.body}');
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        
        // Security check: Only show details if union incharge is for the same building
        if (data['building_name'] != null && 
            widget.buildingName != null &&
            data['building_name'].toString().toLowerCase() == widget.buildingName!.toLowerCase()) {
          
          setState(() {
            _unionInchargeDetails = data;
          });
          
          // Cache the data locally
          await _cacheToLocalStorage(data);
          
          print('✅ Union incharge details loaded from backend for building: ${data['building_name']}');
        } else {
          print('❌ Security check failed: Union incharge building (${data['building_name']}) does not match resident building (${widget.buildingName})');
          setState(() {
            _errorMessage = 'Union incharge not found for your building';
          });
        }
      } else {
        print('⚠️ Failed to load from backend: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ Error fetching from backend: $e');
    }
  }

  Future<void> _loadFromLocalStorage() async {
    try {
      // Try enhanced persistence service first
      if (widget.unionId != null && widget.buildingName != null) {
        final enhancedService = EnhancedPersistenceService.instance;
        final details = await enhancedService.loadUnionInchargeDetails(
          unionId: widget.unionId!,
          buildingName: widget.buildingName!,
        );
        
        if (details != null) {
          // Security check: Only show details if union incharge is for the same building
          if (details['building_name'] != null && 
              widget.buildingName != null &&
              details['building_name'].toString().toLowerCase() == widget.buildingName!.toLowerCase()) {
            
            setState(() {
              _unionInchargeDetails = details;
            });
            print('✅ Union incharge details loaded from enhanced persistence service');
            return;
          }
        }
      }
      
      // Fallback to original method
      final prefs = await SharedPreferences.getInstance();
      
      // Try multiple keys to find union incharge data
      List<String> keysToTry = [];
      
      if (widget.unionId != null && widget.unionId!.isNotEmpty) {
        keysToTry.add('union_incharge_${widget.unionId}');
      }
      
      if (widget.buildingName != null) {
        final buildingKey = widget.buildingName!.replaceAll(' ', '_').toLowerCase();
        keysToTry.addAll([
          'union_incharge_building_$buildingKey',
          'union_incharge_building_${widget.buildingName}',
          'resident_access_union_$buildingKey',
          'union_for_building_${widget.buildingName}',
        ]);
      }
      
      for (String key in keysToTry) {
        final userData = prefs.getString(key);
        if (userData != null) {
          final data = jsonDecode(userData);
          
          print('🔍 Found data with key: $key');
          print('🏢 Data building: ${data['building_name']}');
          print('🏢 Resident building: ${widget.buildingName}');
          
          // Security check: Only show details if union incharge is for the same building
          if (data['building_name'] != null && 
              widget.buildingName != null &&
              data['building_name'].toString().toLowerCase() == widget.buildingName!.toLowerCase()) {
            
            setState(() {
              _unionInchargeDetails = data;
            });
            print('✅ Union incharge details loaded from local storage for building: ${data['building_name']}');
            return;
          } else {
            print('⚠️ Building mismatch for key $key: ${data['building_name']} != ${widget.buildingName}');
          }
        }
      }
      
      print('ℹ️ No matching union incharge details found in local storage');
      setState(() {
        _errorMessage = 'Union incharge has not provided their details yet.\nPlease ask them to update their profile information.';
      });
    } catch (e) {
      print('❌ Error loading from local storage: $e');
    }
  }

  Future<void> _cacheToLocalStorage(Map<String, dynamic> data) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // Cache with multiple keys for different lookup methods
      if (data['id'] != null) {
        await prefs.setString('union_incharge_${data['id']}', jsonEncode(data));
      }
      
      if (data['building_name'] != null) {
        final buildingKey = data['building_name']
            .toString()
            .replaceAll(' ', '_')
            .toLowerCase();
        await prefs.setString('union_incharge_building_$buildingKey', jsonEncode(data));
        
        // Also cache with original building name
        await prefs.setString('union_incharge_building_${data['building_name']}', jsonEncode(data));
      }
      
      print('✅ Union incharge details cached locally with building: ${data['building_name']}');
    } catch (e) {
      print('❌ Error caching to local storage: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isWebLayout = screenWidth > 600;
    
    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: Column(
        children: [
          // Custom header
          _buildHeader(context, isWebLayout),
          // Main content
          Expanded(
            child: Center(
              child: Container(
                constraints: BoxConstraints(
                  maxWidth: isWebLayout ? 600 : double.infinity,
                ),
                child: _buildContent(isWebLayout),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context, bool isWebLayout) {
    return Container(
      height: isWebLayout ? 100 : 120,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFFFF6B35), // Orange
            Color(0xFFF7931E), // Lighter orange
          ],
        ),
      ),
      child: SafeArea(
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: isWebLayout ? 40 : 20,
            vertical: 10,
          ),
          child: Row(
            children: [
              GestureDetector(
                onTap: () => Navigator.pop(context),
                child: Icon(
                  Icons.arrow_back,
                  color: Colors.white,
                  size: isWebLayout ? 28 : 24,
                ),
              ),
              const SizedBox(width: 20),
              Text(
                'Union Incharge Details',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: isWebLayout ? 28 : 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              GestureDetector(
                onTap: _loadUnionInchargeDetails,
                child: Icon(
                  Icons.refresh,
                  color: Colors.white,
                  size: isWebLayout ? 28 : 24,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildContent(bool isWebLayout) {
    if (_isLoading) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Loading union incharge details...'),
          ],
        ),
      );
    }

    if (_errorMessage != null || _unionInchargeDetails == null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.error_outline,
                size: 64,
                color: Colors.grey[400],
              ),
              const SizedBox(height: 16),
              Text(
                _errorMessage ?? 'Union incharge has not provided their details yet.\nPlease ask them to update their profile information.',
                style: const TextStyle(
                  fontSize: 16,
                  color: Colors.grey,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              ElevatedButton.icon(
                onPressed: _loadUnionInchargeDetails,
                icon: const Icon(Icons.refresh),
                label: const Text('Try Again'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFFF6B35),
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          ),
        ),
      );
    }

         return SingleChildScrollView(
       padding: EdgeInsets.all(isWebLayout ? 30 : 20),
       child: Column(
         crossAxisAlignment: CrossAxisAlignment.start,
         children: [
           // Info note
           Container(
             padding: const EdgeInsets.all(16),
             margin: const EdgeInsets.only(bottom: 20),
             decoration: BoxDecoration(
               color: const Color(0xFFFF6B35).withOpacity(0.1),
               borderRadius: BorderRadius.circular(12),
               border: Border.all(
                 color: const Color(0xFFFF6B35).withOpacity(0.3),
               ),
             ),
             child: Row(
               children: [
                 Icon(
                   Icons.info_outline,
                   color: const Color(0xFFFF6B35),
                   size: 20,
                 ),
                 const SizedBox(width: 12),
                 Expanded(
                   child: Column(
                     crossAxisAlignment: CrossAxisAlignment.start,
                     children: [
                       Text(
                         'These details are maintained by your Union Incharge',
                         style: TextStyle(
                           color: const Color(0xFFFF6B35),
                           fontSize: 14,
                           fontWeight: FontWeight.w500,
                         ),
                       ),
                       if (_unionInchargeDetails?['updated_at'] != null) ...[
                         const SizedBox(height: 4),
                         Text(
                           'Last updated: ${_formatLastUpdated(_unionInchargeDetails!['updated_at'])}',
                           style: TextStyle(
                             color: const Color(0xFFFF6B35).withOpacity(0.7),
                             fontSize: 12,
                           ),
                         ),
                       ],
                     ],
                   ),
                 ),
               ],
             ),
           ),
           // Profile section
           _buildProfileSection(isWebLayout),
           const SizedBox(height: 30),
           
           // Personal Info - matching union incharge "My Details" structure
           _buildSectionCard(
             'Personal Info',
             [
               _buildDetailRow('Full Name', _getFullName(), Icons.person_outline),
               _buildDetailRow('Phone Number', _unionInchargeDetails!['phone'] ?? 'N/A', Icons.phone_outlined),
               _buildDetailRow('Email', _unionInchargeDetails!['email'] ?? 'N/A', Icons.email_outlined),
             ],
             isWebLayout,
           ),
           
           const SizedBox(height: 30),
           
           // Bank Details - matching union incharge "My Details" structure
           _buildSectionCard(
             'Bank Details',
             [
               _buildDetailRow('Bank Name', _unionInchargeDetails!['bank_name'] ?? 'Not provided', Icons.account_balance_outlined),
               _buildDetailRow('Account Number', _unionInchargeDetails!['account_number'] ?? 'Not provided', Icons.credit_card_outlined),
               _buildDetailRow('Account Title', _unionInchargeDetails!['account_title'] ?? 'Not provided', Icons.account_circle_outlined),
             ],
             isWebLayout,
           ),
         ],
      ),
    );
  }

  Widget _buildProfileSection(bool isWebLayout) {
    final fullName = _getFullName();
    
    return Container(
      padding: EdgeInsets.all(isWebLayout ? 30 : 24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            width: isWebLayout ? 120 : 100,
            height: isWebLayout ? 120 : 100,
            decoration: BoxDecoration(
              color: const Color(0xFFFF6B35).withOpacity(0.1),
              borderRadius: BorderRadius.circular(60),
            ),
            child: Icon(
              Icons.person,
              size: isWebLayout ? 60 : 50,
              color: const Color(0xFFFF6B35),
            ),
          ),
          const SizedBox(height: 20),
          Text(
            fullName.isEmpty ? 'Union Incharge' : fullName,
            style: TextStyle(
              fontSize: isWebLayout ? 24 : 20,
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
          ),
          const SizedBox(height: 8),
                     Text(
             _unionInchargeDetails!['building_name'] ?? widget.buildingName ?? 'Building',
             style: TextStyle(
               fontSize: isWebLayout ? 16 : 14,
               color: Colors.grey[600],
               fontWeight: FontWeight.w500,
             ),
           ),
           const SizedBox(height: 8),
           Text(
             'Union Incharge',
             style: TextStyle(
               fontSize: isWebLayout ? 14 : 12,
               color: const Color(0xFFFF6B35),
               fontWeight: FontWeight.w600,
             ),
           ),
        ],
      ),
    );
  }

  Widget _buildSectionCard(String title, List<Widget> children, bool isWebLayout) {
    return Container(
      padding: EdgeInsets.all(isWebLayout ? 30 : 24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: isWebLayout ? 20 : 18,
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
          ),
          const SizedBox(height: 20),
          ...children,
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Colors.black,
            ),
          ),
          const SizedBox(height: 8),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 16,
            ),
            decoration: BoxDecoration(
              color: Colors.grey[50],
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey[200]!),
            ),
            child: Row(
              children: [
                Icon(icon, color: Colors.grey[600], size: 20),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    value,
                    style: const TextStyle(
                      fontSize: 16,
                      color: Colors.black,
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

    String _getFullName() {
    if (_unionInchargeDetails == null) return '';
    final firstName = _unionInchargeDetails!['first_name'] ?? '';
    final lastName = _unionInchargeDetails!['last_name'] ?? '';
    return '$firstName $lastName'.trim();
  }

  String _formatLastUpdated(String? dateString) {
    if (dateString == null) return 'Unknown';
    try {
      final date = DateTime.parse(dateString);
      final now = DateTime.now();
      final difference = now.difference(date);
      
      if (difference.inDays > 0) {
        return '${difference.inDays} days ago';
      } else if (difference.inHours > 0) {
        return '${difference.inHours} hours ago';
      } else if (difference.inMinutes > 0) {
        return '${difference.inMinutes} minutes ago';
      } else {
        return 'Just now';
      }
    } catch (e) {
      return 'Unknown';
    }
  }

 
  }