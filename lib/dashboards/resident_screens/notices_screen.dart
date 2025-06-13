import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../../main.dart';

class NoticesScreen extends StatefulWidget {
  final String userId;
  final String? buildingName;
  const NoticesScreen({super.key, required this.userId, this.buildingName});

  @override
  State<NoticesScreen> createState() => _NoticesScreenState();
}

class _NoticesScreenState extends State<NoticesScreen> {
  List<dynamic> notices = [];
  bool isLoading = true;
  String? errorMessage;
  Set<int> markingAsRead = {}; // Track which notices are being marked as read

  @override
  void initState() {
    super.initState();
    fetchNotices();
  }

  Future<void> _clearAllLocalNotices() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final keys = prefs.getKeys();
      
      // Remove all notice-related keys
      for (String key in keys) {
        if (key.contains('building_notices') || key.contains('notices')) {
          await prefs.remove(key);
          print('🧹 Removed cached key: $key');
        }
      }
      
      setState(() {
        notices.clear();
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('All local notices cleared successfully!'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );
      }
      
      print('🧹 All local notices cleared successfully');
    } catch (e) {
      print('❌ Error clearing local notices: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error clearing notices: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> fetchNotices() async {
    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    try {
      // Clear any old cached notices first to ensure fresh data
      await _clearOldCachedNotices();
      
      // Try to fetch from backend API first
      await _fetchNoticesFromBackend();
    } catch (e) {
      print('⚠️ Backend fetch failed, falling back to local storage: $e');
      try {
        await _fetchNoticesFromLocalStorage();
      } catch (localError) {
        print('❌ Both backend and local storage failed: $localError');
        setState(() {
          isLoading = false;
          errorMessage = 'Failed to load notices from both backend and local storage';
        });
      }
    }
  }

  Future<void> _clearOldCachedNotices() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String buildingKey = (widget.buildingName ?? 'unknown')
          .replaceAll(' ', '_')
          .toLowerCase();
      final String originalBuildingKey = widget.buildingName ?? 'unknown';
      
      // Clear ALL possible notice keys to remove any dummy data
      final keys = prefs.getKeys();
      for (String key in keys) {
        if (key.contains('building_notices') || key.contains('notices')) {
          await prefs.remove(key);
          print('🧹 Removed cached key: $key');
        }
      }
      
      print('🧹 Cleared ALL cached notices to remove dummy data');
    } catch (e) {
      print('❌ Error clearing old cached notices: $e');
    }
  }

  Future<void> _fetchNoticesFromBackend() async {
    try {
      final baseUrl = getBaseUrl();
      final url = '$baseUrl/resident/notices?user_id=${widget.userId}&building_name=${Uri.encodeComponent(widget.buildingName ?? '')}';
      
      print('🔗 Connecting to backend: $url');
      print('👤 User ID: ${widget.userId}');
      print('🏢 Building Name: ${widget.buildingName}');
      
      final response = await http.get(
        Uri.parse(url),
        headers: {'Content-Type': 'application/json'},
      ).timeout(const Duration(seconds: 10));

      print('📥 Backend response status: ${response.statusCode}');
      print('📥 Backend response body: ${response.body}');

      if (response.statusCode == 200) {
        final List<dynamic> backendNotices = jsonDecode(response.body);
        
        print('📝 Raw backend notices: ${backendNotices.length}');
        for (var notice in backendNotices) {
          print('   - ${notice['title']} (Building: ${notice['buildingName']})');
        }
        
        // Filter notices that haven't been read by this user
        final List<dynamic> unreadNotices = backendNotices.where((notice) {
          final readBy = List<String>.from(notice['readBy'] ?? []);
          return !readBy.contains(widget.userId);
        }).toList();
        
        setState(() {
          notices = unreadNotices;
          isLoading = false;
        });
        
        // Cache the data locally for offline use
        await _cacheNoticesLocally(backendNotices);
        
        print('✅ Fetched ${notices.length} unread notices from backend for building: ${widget.buildingName}');
        print('📊 Total notices from backend: ${backendNotices.length}');
      } else {
        throw Exception('Backend returned status: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      print('❌ Failed to fetch notices from backend: $e');
      rethrow;
    }
  }

  Future<void> _fetchNoticesFromLocalStorage() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String buildingKey = (widget.buildingName ?? 'unknown')
          .replaceAll(' ', '_')
          .toLowerCase();
      final String originalBuildingKey = widget.buildingName ?? 'unknown';
      
      // Try to get notices using original building name first, then normalized
      String noticesData = prefs.getString('building_notices_$originalBuildingKey') ?? '[]';
      if (noticesData == '[]') {
        noticesData = prefs.getString('building_notices_$buildingKey') ?? '[]';
      }
      
      final List<dynamic> allNotices = jsonDecode(noticesData);
      
      // Filter notices that haven't been read by this user
      final List<dynamic> unreadNotices = allNotices.where((notice) {
        final readBy = List<String>.from(notice['readBy'] ?? []);
        return !readBy.contains(widget.userId);
      }).toList();
      
      setState(() {
        notices = unreadNotices;
        isLoading = false;
      });
      
      print('📱 Fetched ${notices.length} unread notices from local storage for building: $buildingKey');
      print('📊 Total notices from local storage: ${allNotices.length}');
    } catch (e) {
      setState(() {
        isLoading = false;
        errorMessage = e.toString();
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: ${e.toString()}')),
      );
    }
  }

  Future<void> _cacheNoticesLocally(List<dynamic> backendNotices) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String buildingKey = (widget.buildingName ?? 'unknown')
          .replaceAll(' ', '_')
          .toLowerCase();
      
      // Save backend data to local storage
      await prefs.setString('building_notices_$buildingKey', jsonEncode(backendNotices));
      print('💾 Cached ${backendNotices.length} notices locally for offline use');
    } catch (e) {
      print('❌ Failed to cache notices locally: $e');
    }
  }

  Future<void> markNoticeAsRead(int noticeId) async {
    // Prevent multiple concurrent mark as read operations on the same notice
    if (markingAsRead.contains(noticeId)) {
      return;
    }

    setState(() {
      markingAsRead.add(noticeId);
    });

    try {
      // First try to update backend
      try {
        await _markNoticeAsReadInBackend(noticeId);
        print('✅ Notice marked as read in backend');
      } catch (backendError) {
        print('⚠️ Backend update failed, continuing with local storage: $backendError');
        // Continue with local storage update even if backend fails
      }
      
      // Update local storage
      final prefs = await SharedPreferences.getInstance();
      final String buildingKey = (widget.buildingName ?? 'unknown')
          .replaceAll(' ', '_')
          .toLowerCase();
      final String originalBuildingKey = widget.buildingName ?? 'unknown';
      
      // Update both building key formats for compatibility
      await _updateLocalNoticeAsRead(prefs, buildingKey, noticeId);
      await _updateLocalNoticeAsRead(prefs, originalBuildingKey, noticeId);
      
      print('✅ Notice $noticeId marked as read by user ${widget.userId}');
      
      // Remove the notice from the current view immediately
      setState(() {
        notices.removeWhere((notice) => notice['id'] == noticeId);
      });
      
      // Show success message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.white, size: 20),
                const SizedBox(width: 8),
                const Expanded(
                  child: Text('Notice marked as read and removed from your inbox'),
                ),
              ],
            ),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 2),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      print('❌ Error marking notice as read: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.error, color: Colors.white, size: 20),
                const SizedBox(width: 8),
                Expanded(child: Text('Error: ${e.toString()}')),
              ],
            ),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      setState(() {
        markingAsRead.remove(noticeId);
      });
    }
  }

  Future<void> _markNoticeAsReadInBackend(int noticeId) async {
    try {
      final baseUrl = getBaseUrl();
      final response = await http.post(
        Uri.parse('$baseUrl/resident/notices/$noticeId/read'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'userId': widget.userId,
          'buildingName': widget.buildingName,
        }),
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode != 200) {
        throw Exception('Backend returned status: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      print('❌ Failed to mark notice as read in backend: $e');
      rethrow;
    }
  }

  Future<void> _updateLocalNoticeAsRead(SharedPreferences prefs, String buildingKey, int noticeId) async {
    try {
      // Get all notices for this building
      final noticesData = prefs.getString('building_notices_$buildingKey') ?? '[]';
      final List<dynamic> allNotices = jsonDecode(noticesData);
      
      // Find the notice and mark it as read by this user
      for (var notice in allNotices) {
        if (notice['id'] == noticeId) {
          final readBy = List<String>.from(notice['readBy'] ?? []);
          if (!readBy.contains(widget.userId)) {
            readBy.add(widget.userId);
            notice['readBy'] = readBy;
            notice['readCount'] = (notice['readCount'] ?? 0) + 1;
          }
          break;
        }
      }
      
      // Save updated notices back to storage
      await prefs.setString('building_notices_$buildingKey', jsonEncode(allNotices));
    } catch (e) {
      print('❌ Error updating local notice storage for key $buildingKey: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isLargeScreen = screenWidth > 800;
    final maxWidth = screenWidth > 1200 ? 900.0 : screenWidth > 800 ? 700.0 : screenWidth;
    
    return Scaffold(
      appBar: AppBar(
        title: const Text("Community Notices"),
        backgroundColor: Colors.deepPurple,
        actions: [
          isLoading
              ? Container(
                  padding: const EdgeInsets.all(10),
                  child: const CircularProgressIndicator(
                    color: Colors.white,
                    strokeWidth: 2,
                  ),
                )
              : IconButton(
                  icon: const Icon(Icons.refresh),
                  onPressed: fetchNotices,
                  tooltip: 'Refresh Notices',
                ),
          PopupMenuButton<String>(
            onSelected: (value) {
              if (value == 'clear_all') {
                _showClearConfirmationDialog();
              }
            },
            itemBuilder: (BuildContext context) => [
              const PopupMenuItem<String>(
                value: 'clear_all',
                child: Row(
                  children: [
                    Icon(Icons.clear_all, color: Colors.red),
                    SizedBox(width: 8),
                    Text('Clear All Notices'),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: Center(
        child: Container(
          constraints: BoxConstraints(maxWidth: maxWidth),
          child: isLoading
              ? const Center(child: CircularProgressIndicator())
              : errorMessage != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.error_outline, size: 48, color: Colors.red),
                      const SizedBox(height: 16),
                      Text(
                        'Error loading notices',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        errorMessage!,
                        style: Theme.of(context).textTheme.bodyMedium,
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 24),
                      ElevatedButton.icon(
                        onPressed: fetchNotices,
                        icon: const Icon(Icons.refresh),
                        label: const Text('Try Again'),
                      ),
                    ],
                  ),
                )
              : notices.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.notifications_off, size: 64, color: Colors.grey),
                      const SizedBox(height: 16),
                      Text(
                        'No Notices Available',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'There are no notices from your Union Incharge yet',
                        style: Theme.of(context).textTheme.bodyMedium,
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  itemCount: notices.length,
                  padding: EdgeInsets.all(isLargeScreen ? 24 : 16),
                  itemBuilder: (context, index) {
                    final notice = notices[index];
                    final title = notice['title'] ?? 'No Title';
                    final body = notice['body'] ?? 'No content';
                    final postedBy = notice['posted_by'] ?? 'Union Incharge';
                    final postedAt = notice['posted_at'] ?? '';
                    final propertyName = notice['property_name'] ?? '';
                    
                    // Check if this is an election results notice
                    final bool isElectionResults = title.contains('Election Results');
                    
                    return Card(
                      margin: EdgeInsets.only(bottom: isLargeScreen ? 20 : 16),
                      elevation: 2,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: InkWell(
                        onTap: () => _showNoticeDetails(notice),
                        borderRadius: BorderRadius.circular(12),
                        child: Padding(
                          padding: EdgeInsets.all(isLargeScreen ? 20 : 16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(
                                    isElectionResults 
                                      ? Icons.how_to_vote
                                      : Icons.notifications_active, 
                                    color: isElectionResults 
                                      ? Colors.green
                                      : Colors.deepPurple
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      title,
                                      style: TextStyle(
                                        fontSize: isLargeScreen ? 20 : 18,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const Divider(height: 24),
                              Text(
                                body.length > 100 ? '${body.substring(0, 100)}...' : body,
                                style: TextStyle(fontSize: isLargeScreen ? 16 : 14),
                              ),
                              SizedBox(height: isLargeScreen ? 20 : 16),
                              isLargeScreen 
                                ? Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              'From: $postedBy',
                                              style: const TextStyle(
                                                fontSize: 12,
                                                fontStyle: FontStyle.italic,
                                                color: Colors.grey,
                                              ),
                                            ),
                                            Text(
                                              postedAt,
                                              style: const TextStyle(
                                                fontSize: 12,
                                                color: Colors.grey,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      const SizedBox(width: 16),
                                      ElevatedButton.icon(
                                        onPressed: markingAsRead.contains(notice['id']) ? null : () {
                                          final noticeId = notice['id'];
                                          if (noticeId != null) {
                                            markNoticeAsRead(noticeId);
                                          }
                                        },
                                        icon: markingAsRead.contains(notice['id']) 
                                            ? const SizedBox(
                                                width: 16,
                                                height: 16,
                                                child: CircularProgressIndicator(
                                                  strokeWidth: 2,
                                                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                                ),
                                              )
                                            : const Icon(Icons.done_all, size: 16),
                                        label: Text(markingAsRead.contains(notice['id']) ? 'Marking...' : 'Mark as Read'),
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: markingAsRead.contains(notice['id']) ? Colors.grey : Colors.green,
                                          foregroundColor: Colors.white,
                                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                          minimumSize: const Size(0, 36),
                                          textStyle: const TextStyle(fontSize: 14),
                                        ),
                                      ),
                                    ],
                                  )
                                : Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            'From: $postedBy',
                                            style: const TextStyle(
                                              fontSize: 12,
                                              fontStyle: FontStyle.italic,
                                              color: Colors.grey,
                                            ),
                                          ),
                                          Text(
                                            postedAt,
                                            style: const TextStyle(
                                              fontSize: 12,
                                              color: Colors.grey,
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 12),
                                      SizedBox(
                                        width: double.infinity,
                                        child: ElevatedButton.icon(
                                          onPressed: markingAsRead.contains(notice['id']) ? null : () {
                                            final noticeId = notice['id'];
                                            if (noticeId != null) {
                                              markNoticeAsRead(noticeId);
                                            }
                                          },
                                          icon: markingAsRead.contains(notice['id']) 
                                              ? const SizedBox(
                                                  width: 16,
                                                  height: 16,
                                                  child: CircularProgressIndicator(
                                                    strokeWidth: 2,
                                                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                                  ),
                                                )
                                              : const Icon(Icons.done_all, size: 16),
                                          label: Text(markingAsRead.contains(notice['id']) ? 'Marking...' : 'Mark as Read'),
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: markingAsRead.contains(notice['id']) ? Colors.grey : Colors.green,
                                            foregroundColor: Colors.white,
                                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                            minimumSize: const Size(0, 32),
                                            textStyle: const TextStyle(fontSize: 12),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                              if (propertyName.isNotEmpty)
                                Padding(
                                  padding: const EdgeInsets.only(top: 4),
                                  child: Text(
                                    'Property: $propertyName',
                                    style: const TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
        ),
      ),
    );
  }

  void _showClearConfirmationDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.warning, color: Colors.orange),
            SizedBox(width: 8),
            Text('Clear All Notices'),
          ],
        ),
        content: const Text(
          'Are you sure you want to clear all notices from your local storage? This action cannot be undone.\n\nNote: This only clears notices stored locally on your device.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _clearAllLocalNotices();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Clear All'),
          ),
        ],
      ),
    );
  }

  void _showNoticeDetails(Map<String, dynamic> notice) {
    final title = notice['title'] ?? 'No Title';
    final body = notice['body'] ?? 'No content';
    final postedBy = notice['posted_by'] ?? 'Union Incharge';
    final postedAt = notice['posted_at'] ?? '';
    final propertyName = notice['property_name'] ?? '';
    final noticeId = notice['id'];

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                body,
                style: const TextStyle(fontSize: 14, height: 1.5),
              ),
              const SizedBox(height: 20),
              Text(
                'From: $postedBy',
                style: const TextStyle(
                  fontSize: 12,
                  fontStyle: FontStyle.italic,
                  color: Colors.grey,
                ),
              ),
              Text(
                'Property: $propertyName',
                style: const TextStyle(
                  fontSize: 12,
                  color: Colors.grey,
                ),
              ),
              Text(
                'Posted: $postedAt',
                style: const TextStyle(
                  fontSize: 12,
                  color: Colors.grey,
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
            },
            child: const Text('Close'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              if (noticeId != null) {
                markNoticeAsRead(noticeId);
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.deepPurple,
            ),
            child: const Text('Mark as Read'),
          ),
        ],
      ),
    );
  }
}
