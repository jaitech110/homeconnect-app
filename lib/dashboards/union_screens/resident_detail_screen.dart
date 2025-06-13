import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../../main.dart'; // Import for getBaseUrl function

class ResidentDetailScreen extends StatelessWidget {
  final Map<String, dynamic> residentData;
  final VoidCallback onApproval;

  const ResidentDetailScreen({
    super.key,
    required this.residentData,
    required this.onApproval,
  });

  Future<void> _approveResident(BuildContext context, int userId) async {
    final response = await http.post(
      Uri.parse('${getBaseUrl()}/union/approve_resident/$userId'),
    );

    if (response.statusCode == 200) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Resident approved')),
      );
      onApproval();
      Navigator.pop(context);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to approve')),
      );
    }
  }

  Future<void> _rejectResident(BuildContext context, int userId) async {
    final response = await http.delete(
      Uri.parse('${getBaseUrl()}/union/reject_resident/$userId'),
    );

    if (response.statusCode == 200) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Resident rejected')),
      );
      onApproval();
      Navigator.pop(context);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to reject')),
      );
    }
  }

  void _openFullImage(BuildContext context, String imageUrl) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => Scaffold(
          appBar: AppBar(
            title: const Text('CNIC Image'),
            backgroundColor: Colors.black,
          ),
          body: Container(
            color: Colors.black,
            child: Center(
              child: InteractiveViewer(
                minScale: 0.5,
                maxScale: 4.0,
                child: Image.network(
                  imageUrl,
                  fit: BoxFit.contain,
                  errorBuilder: (context, error, stackTrace) => const Center(
                    child: Text('Failed to load image', style: TextStyle(color: Colors.white)),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final String name =
        '${residentData['first_name'] ?? 'N/A'} ${residentData['last_name'] ?? ''}';
    final String email = residentData['email'] ?? 'Not provided';
    final String phone = residentData['phone'] ?? 'Not provided';
    final String username = residentData['username'] ?? 'Not provided';
    final String address = residentData['address'] ?? 'Not provided';
    final String? cnicImageUrl = residentData['cnic_image_url'];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Resident Details'),
        backgroundColor: Colors.deepPurple,
      ),
      backgroundColor: const Color(0xFF1C1C1E),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            CircleAvatar(
              radius: 60,
              backgroundImage: cnicImageUrl != null && cnicImageUrl.isNotEmpty
                  ? NetworkImage(cnicImageUrl)
                  : const AssetImage('assets/images/resident.png') as ImageProvider,
              backgroundColor: Colors.grey[300],
            ),
            const SizedBox(height: 20),
            _buildDetailRow('Name', name),
            _buildDetailRow('Email', email),
            _buildDetailRow('Phone', phone),
            _buildDetailRow('Flat/House No.', username),
            _buildDetailRow('Address', address),
            
            // CNIC Image Section
            const SizedBox(height: 30),
            const Divider(color: Colors.grey),
            const SizedBox(height: 10),
            
            const Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Identity Verification',
                style: TextStyle(
                  fontSize: 18, 
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
            
            const SizedBox(height: 15),
            
            if (cnicImageUrl != null && cnicImageUrl.isNotEmpty)
              Card(
                color: const Color(0xFF2A2A2A),
                elevation: 4,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'CNIC Image',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          Text(
                            'Tap to view full image',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[400],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      InkWell(
                        onTap: () => _openFullImage(context, cnicImageUrl),
                        child: Container(
                          height: 200,
                          width: double.infinity,
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey[600]!),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Image.network(
                              cnicImageUrl,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) => const Center(
                                child: Text(
                                  'Failed to load CNIC image',
                                  style: TextStyle(color: Colors.white70),
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
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              )
            else
              Card(
                color: const Color(0xFF2A2A2A),
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Center(
                    child: Column(
                      children: [
                        const Icon(
                          Icons.image_not_supported,
                          size: 50,
                          color: Colors.grey,
                        ),
                        const SizedBox(height: 10),
                        const Text(
                          'No CNIC image provided',
                          style: TextStyle(color: Colors.white70),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            
            const SizedBox(height: 30),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton.icon(
                  onPressed: () => _approveResident(context, residentData['id']),
                  icon: const Icon(Icons.check),
                  label: const Text('Approve'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: () => _rejectResident(context, residentData['id']),
                  icon: const Icon(Icons.close),
                  label: const Text('Reject'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  ),
                ),
              ],
            )
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '$label: ',
            style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(color: Colors.white70),
            ),
          ),
        ],
      ),
    );
  }
}
