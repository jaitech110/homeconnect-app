import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../../main.dart'; // Import for getBaseUrl function

class UnionInchargeDetailScreen extends StatefulWidget {
  final Map<String, dynamic> user;

  const UnionInchargeDetailScreen({
    Key? key,
    required this.user,
  }) : super(key: key);

  @override
  State<UnionInchargeDetailScreen> createState() => _UnionInchargeDetailScreenState();
}

class _UnionInchargeDetailScreenState extends State<UnionInchargeDetailScreen> {
  bool isLoading = false;

  Future<void> _approveUser() async {
    setState(() => isLoading = true);
    
    try {
      final response = await http.put(
        Uri.parse('${getBaseUrl()}/admin/union-approvals/${widget.user['id']}/approve'),
        headers: {'Content-Type': 'application/json'},
      );
      
      setState(() => isLoading = false);
      
      if (response.statusCode == 200) {
        if (!mounted) return;
        
        // Show a dialog informing about the next steps
        await showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Union Incharge Approved'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('${widget.user['first_name']} ${widget.user['last_name']} has been approved successfully.'),
                const SizedBox(height: 10),
                const Text(
                  'This Union Incharge can now log in to the system and will be visible in the "Manage Union Incharge" section if you need to remove them in the future.',
                  style: TextStyle(fontSize: 14),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('OK'),
              ),
            ],
          ),
        );
        
        Navigator.pop(context, 'approved'); // Return 'approved' to indicate approval
      } else {
        // Try to parse as JSON, but handle plain text responses
        String errorMessage;
        try {
          final data = jsonDecode(response.body);
          errorMessage = data['message'] ?? 'Failed to approve user';
        } catch (e) {
          // If JSON parsing fails, use the raw response body
          errorMessage = response.body.isNotEmpty ? response.body : 'Failed to approve user';
        }
        throw Exception(errorMessage);
      }
    } catch (e) {
      setState(() => isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }

  Future<void> _rejectUser() async {
    // Show confirmation dialog
    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Rejection'),
        content: const Text(
          'Are you sure you want to reject this Union Incharge? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Reject'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    setState(() => isLoading = true);

    try {
      final response = await http.put(
        Uri.parse('${getBaseUrl()}/admin/union-approvals/${widget.user['id']}/reject'),
        headers: {'Content-Type': 'application/json'},
      );
      
      setState(() => isLoading = false);
      
      if (response.statusCode == 200) {
        if (!mounted) return;
        
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Union Incharge rejected')),
        );
        
        Navigator.pop(context, 'rejected'); // Return 'rejected' to indicate rejection
      } else {
        // Try to parse as JSON, but handle plain text responses
        String errorMessage;
        try {
          final data = jsonDecode(response.body);
          errorMessage = data['message'] ?? 'Failed to reject user';
        } catch (e) {
          // If JSON parsing fails, use the raw response body
          errorMessage = response.body.isNotEmpty ? response.body : 'Failed to reject user';
        }
        throw Exception(errorMessage);
      }
    } catch (e) {
      setState(() => isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    // Responsive design variables
    final screenWidth = MediaQuery.of(context).size.width;
    final isWebLayout = screenWidth > 800;
    final isTabletLayout = screenWidth > 600 && screenWidth <= 800;
    final isMobileLayout = screenWidth <= 600;
    
    // Responsive constraints
    final maxContentWidth = isWebLayout ? 800.0 : double.infinity;
    final horizontalPadding = isWebLayout ? 24.0 : (isTabletLayout ? 20.0 : 16.0);
    final verticalSpacing = isWebLayout ? 24.0 : (isTabletLayout ? 20.0 : 16.0);
    
    return Scaffold(
      backgroundColor: Colors.grey[50], // Light background for better contrast
      appBar: AppBar(
        title: Text(
          'Union Incharge Details',
          style: TextStyle(
            fontSize: isWebLayout ? 20 : (isTabletLayout ? 18 : 16),
            fontWeight: FontWeight.bold,
            color: Colors.white, // Ensure white text on purple background
          ),
        ),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white, // Ensure all app bar elements are white
        elevation: isWebLayout ? 4 : 2,
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : Center(
              child: ConstrainedBox(
                constraints: BoxConstraints(maxWidth: maxContentWidth),
                child: SingleChildScrollView(
                  padding: EdgeInsets.all(horizontalPadding),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                  // Profile header card
                  Card(
                    elevation: isWebLayout ? 6 : 4,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(isWebLayout ? 16 : 12),
                    ),
                    child: Container(
                      padding: EdgeInsets.all(isWebLayout ? 24 : (isTabletLayout ? 20 : 16)),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Colors.deepPurple, Colors.purple],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(isWebLayout ? 16 : 12),
                      ),
                      child: isMobileLayout
                          ? Column(
                              children: [
                                CircleAvatar(
                                  radius: 50,
                                  backgroundColor: Colors.white,
                                  child: Text(
                                    '${widget.user['first_name'][0]}${widget.user['last_name'][0]}',
                                    style: TextStyle(
                                      fontSize: 28,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.deepPurple,
                                    ),
                                  ),
                                ),
                                SizedBox(height: 16),
                                Column(
                                  children: [
                                    Text(
                                      '${widget.user['first_name']} ${widget.user['last_name']}',
                                      style: TextStyle(
                                        fontSize: 20,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                      ),
                                      textAlign: TextAlign.center,
                                    ),
                                    SizedBox(height: 8),
                                    Text(
                                      'Union Incharge',
                                      style: TextStyle(
                                        fontSize: 16,
                                        color: Colors.white.withOpacity(0.8),
                                      ),
                                      textAlign: TextAlign.center,
                                    ),
                                  ],
                                ),
                              ],
                            )
                          : Row(
                              children: [
                                CircleAvatar(
                                  radius: isWebLayout ? 50 : 40,
                                  backgroundColor: Colors.white,
                                  child: Text(
                                    '${widget.user['first_name'][0]}${widget.user['last_name'][0]}',
                                    style: TextStyle(
                                      fontSize: isWebLayout ? 28 : 24,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.deepPurple,
                                    ),
                                  ),
                                ),
                                SizedBox(width: isWebLayout ? 24 : 20),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        '${widget.user['first_name']} ${widget.user['last_name']}',
                                        style: TextStyle(
                                          fontSize: isWebLayout ? 28 : 24,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.white,
                                        ),
                                      ),
                                      SizedBox(height: 8),
                                      Text(
                                        'Union Incharge',
                                        style: TextStyle(
                                          fontSize: isWebLayout ? 18 : 16,
                                          color: Colors.white.withOpacity(0.8),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                    ),
                  ),
                  
                  SizedBox(height: verticalSpacing),
                  
                  // Personal Information
                  _buildSectionHeader('Personal Information', isWebLayout, isTabletLayout),
                  SizedBox(height: verticalSpacing * 0.5),
                  _buildInfoCard([
                    _buildInfoItem('Email', widget.user['email'] ?? 'Not provided'),
                    _buildInfoItem('Phone', widget.user['phone'] ?? 'Not provided'),
                    _buildInfoItem('Address', widget.user['address'] ?? 'Not provided'),
                  ]),
                  
                  SizedBox(height: verticalSpacing),
                  
                  // Property Information
                  _buildSectionHeader('Property Information', isWebLayout, isTabletLayout),
                  SizedBox(height: verticalSpacing * 0.5),
                  _buildInfoCard([
                    _buildInfoItem('Type', widget.user['category'] ?? 'Not specified'),
                    _buildInfoItem('Name', widget.user['building_name'] ?? 'Not provided'),
                  ]),
                  
                  SizedBox(height: verticalSpacing),
                  
                  // CNIC Image
                  _buildSectionHeader('Identity Verification', isWebLayout, isTabletLayout),
                  SizedBox(height: verticalSpacing * 0.5),
                  Card(
                    elevation: isWebLayout ? 4 : 2,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(isWebLayout ? 12 : 8),
                    ),
                    child: Padding(
                      padding: EdgeInsets.all(isWebLayout ? 20 : (isTabletLayout ? 18 : 16)),
                      child: widget.user['cnic_image_url'] != null
                          ? Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    const Text(
                                      'CNIC Image',
                                      style: TextStyle(fontWeight: FontWeight.bold),
                                    ),
                                    Text(
                                      'Image URL: ${widget.user['cnic_image_url'] is String ? 'Valid' : 'Invalid'}',
                                      style: TextStyle(
                                        fontSize: 12, 
                                        color: Colors.deepPurple[600], // Better contrast
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Container(
                                  height: isWebLayout ? 300 : (isTabletLayout ? 250 : 200),
                                  width: double.infinity,
                                  decoration: BoxDecoration(
                                    border: Border.all(color: Colors.grey),
                                    borderRadius: BorderRadius.circular(isWebLayout ? 12 : 8),
                                  ),
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(8),
                                    child: _buildCnicImage(widget.user['cnic_image_url']),
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Standard size: 35x45 mm',
                                  style: TextStyle(
                                    fontStyle: FontStyle.italic, 
                                    color: Colors.grey[700], // Darker for better readability
                                    fontSize: 13,
                                  ),
                                ),
                                TextButton(
                                  onPressed: () => _checkImageUrl(widget.user['id']),
                                  child: const Text('Debug Image'),
                                ),
                              ],
                            )
                          : Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Center(
                                  child: Padding(
                                    padding: EdgeInsets.all(16),
                                    child: Text(
                                      'No CNIC image provided',
                                      style: TextStyle(
                                        color: Colors.grey[700], // Better readability
                                        fontSize: 16,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ),
                                ),
                                TextButton(
                                  onPressed: () => _checkImageUrl(widget.user['id']),
                                  child: const Text('Check Image Status'),
                                ),
                              ],
                            ),
                    ),
                  ),
                  
                  SizedBox(height: verticalSpacing * 1.5),
                  
                  // Action Buttons
                  _buildActionButtons(isWebLayout, isTabletLayout, isMobileLayout),
                  
                  SizedBox(height: verticalSpacing * 1.2),
                ],
                  ),
                ),
              ),
            ),
    );
  }

  Widget _buildSectionHeader(String title, bool isWebLayout, bool isTabletLayout) {
    return Container(
      padding: EdgeInsets.symmetric(
        vertical: isWebLayout ? 8 : 4,
        horizontal: isWebLayout ? 12 : 8,
      ),
      decoration: BoxDecoration(
        color: Colors.deepPurple.withOpacity(0.1),
        borderRadius: BorderRadius.circular(isWebLayout ? 8 : 6),
        border: Border.all(
          color: Colors.deepPurple.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.info_outline,
            color: Colors.deepPurple,
            size: isWebLayout ? 20 : 18,
          ),
          SizedBox(width: isWebLayout ? 10 : 8),
          Text(
            title,
            style: TextStyle(
              fontSize: isWebLayout ? 20 : (isTabletLayout ? 18 : 16),
              fontWeight: FontWeight.bold,
              color: Colors.deepPurple,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons(bool isWebLayout, bool isTabletLayout, bool isMobileLayout) {
    final buttonPadding = EdgeInsets.symmetric(
      vertical: isWebLayout ? 16 : (isTabletLayout ? 14 : 12),
      horizontal: isWebLayout ? 24 : (isTabletLayout ? 20 : 16),
    );
    
    final buttonTextStyle = TextStyle(
      fontSize: isWebLayout ? 18 : (isTabletLayout ? 16 : 14),
      fontWeight: FontWeight.bold,
    );
    
    if (isMobileLayout) {
      return Column(
        children: [
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _approveUser,
              icon: Icon(
                Icons.check_circle,
                size: 20,
                color: Colors.white,
              ),
              label: Text(
                'Approve Union Incharge',
                style: buttonTextStyle,
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
                padding: buttonPadding,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 4,
              ),
            ),
          ),
          SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _rejectUser,
              icon: Icon(
                Icons.cancel,
                size: 20,
                color: Colors.white,
              ),
              label: Text(
                'Reject Application',
                style: buttonTextStyle,
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
                padding: buttonPadding,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 4,
              ),
            ),
          ),
        ],
      );
    }
    
    return Row(
      children: [
        Expanded(
          child: ElevatedButton.icon(
            onPressed: _approveUser,
            icon: Icon(
              Icons.check_circle,
              size: isWebLayout ? 22 : 20,
              color: Colors.white,
            ),
            label: Text(
              'Approve',
              style: buttonTextStyle,
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
              padding: buttonPadding,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(isWebLayout ? 12 : 8),
              ),
              elevation: isWebLayout ? 6 : 4,
            ),
          ),
        ),
        SizedBox(width: isWebLayout ? 20 : 16),
        Expanded(
          child: ElevatedButton.icon(
            onPressed: _rejectUser,
            icon: Icon(
              Icons.cancel,
              size: isWebLayout ? 22 : 20,
              color: Colors.white,
            ),
            label: Text(
              'Reject',
              style: buttonTextStyle,
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
              padding: buttonPadding,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(isWebLayout ? 12 : 8),
              ),
              elevation: isWebLayout ? 6 : 4,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildInfoCard(List<Widget> children) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isWebLayout = screenWidth > 800;
    final isTabletLayout = screenWidth > 600 && screenWidth <= 800;
    
    return Card(
      elevation: isWebLayout ? 4 : 2,
      color: Colors.white, // Ensure white background for proper contrast
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(isWebLayout ? 12 : 8),
      ),
      child: Padding(
        padding: EdgeInsets.all(isWebLayout ? 20 : (isTabletLayout ? 18 : 16)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: children,
        ),
      ),
    );
  }

  Widget _buildInfoItem(String label, String value) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isWebLayout = screenWidth > 800;
    final isTabletLayout = screenWidth > 600 && screenWidth <= 800;
    final isMobileLayout = screenWidth <= 600;
    
    if (isMobileLayout) {
      return Padding(
        padding: EdgeInsets.symmetric(vertical: 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: Colors.deepPurple[600], // Good contrast on white background
              ),
            ),
            SizedBox(height: 4),
            Text(
              value,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600, // Slightly bolder for better readability
                color: Colors.grey[700], // Good contrast on white background
              ),
            ),
          ],
        ),
      );
    }
    
    return Padding(
      padding: EdgeInsets.symmetric(vertical: isWebLayout ? 10 : 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: isWebLayout ? 140 : 100,
            child: Text(
              label,
              style: TextStyle(
                fontSize: isWebLayout ? 15 : 14,
                fontWeight: FontWeight.bold,
                color: Colors.deepPurple[600], // Good contrast on white background
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontSize: isWebLayout ? 16 : 15,
                fontWeight: FontWeight.w600, // Bolder for better readability
                color: Colors.grey[700], // Good contrast on white background
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCnicImage(String? imageUrl) {
    if (imageUrl == null) {
      return Center(
        child: Text(
          'Failed to load CNIC image',
          style: TextStyle(
            color: Colors.red[700], // Error color for better visibility
            fontSize: 16,
            fontWeight: FontWeight.w500,
          ),
        ),
      );
    }

    return Image.network(
      imageUrl,
      fit: BoxFit.contain,
      errorBuilder: (context, error, stackTrace) => Center(
        child: Text(
          'Failed to load CNIC image',
          style: TextStyle(
            color: Colors.red[700], // Error color for better visibility
            fontSize: 16,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
      loadingBuilder: (context, child, loadingProgress) {
        if (loadingProgress == null) return child;
        return Center(
          child: CircularProgressIndicator(
            value: loadingProgress.expectedTotalBytes != null
                ? loadingProgress.cumulativeBytesLoaded /
                    loadingProgress.expectedTotalBytes!
                : null,
          ),
        );
      },
    );
  }

  Future<void> _checkImageUrl(int userId) async {
    setState(() => isLoading = true);
    
    try {
      final response = await http.get(
        Uri.parse('${getBaseUrl()}/debug/cnic/$userId'),
      );
      
      setState(() => isLoading = false);
      
      if (response.statusCode == 200) {
        if (!mounted) return;
        
        final data = jsonDecode(response.body);
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('CNIC Image Debug Info'),
            content: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('User ID: ${data['id']}'),
                  Text('Name: ${data['name']}'),
                  const Divider(),
                  Text('CNIC URL: ${data['cnic_url'] ?? 'Not set'}'),
                  const Divider(),
                  Text('Uploads directory exists: ${data['uploads_exist']}'),
                  const Text('Uploads directory contents:'),
                  ...data['uploads_content'].map<Widget>((file) => Text('- $file')),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Close'),
              ),
              if (data['cnic_url'] != null)
                TextButton(
                  onPressed: () {
                    Navigator.pop(context);
                    _openImageInNewScreen(data['cnic_url']);
                  },
                  child: const Text('View Image'),
                ),
            ],
          ),
        );
      } else {
        throw Exception('Failed to check image URL');
      }
    } catch (e) {
      setState(() => isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }
  
  void _openImageInNewScreen(String imageUrl) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => Scaffold(
          appBar: AppBar(
            title: const Text('CNIC Image'),
            backgroundColor: Colors.deepPurple,
          ),
          body: Center(
            child: Image.network(
              imageUrl,
              fit: BoxFit.contain,
              errorBuilder: (context, error, stackTrace) => const Center(
                child: Text('Failed to load image'),
              ),
            ),
          ),
        ),
      ),
    );
  }
} 