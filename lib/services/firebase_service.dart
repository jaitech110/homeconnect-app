import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'dart:typed_data';

class FirebaseService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final FirebaseAuth _auth = FirebaseAuth.instance;
  static final FirebaseStorage _storage = FirebaseStorage.instance;

  // User Management
  static Future<Map<String, dynamic>?> signUp({
    required String email,
    required String password,
    required String firstName,
    required String lastName,
    required String role,
    required String phone,
    String? building,
    String? flatNo,
    String? category,
  }) async {
    try {
      // Create user account
      UserCredential userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      // Store user data in Firestore
      await _firestore.collection('users').doc(userCredential.user!.uid).set({
        'email': email,
        'firstName': firstName,
        'lastName': lastName,
        'role': role,
        'phone': phone,
        'building': building ?? '',
        'flatNo': flatNo ?? '',
        'category': category ?? '',
        'isApproved': role == 'admin' ? true : false, // Auto-approve admin
        'createdAt': FieldValue.serverTimestamp(),
        'uid': userCredential.user!.uid,
      });

      return {
        'success': true,
        'message': 'User registered successfully',
        'uid': userCredential.user!.uid,
      };
    } catch (e) {
      return {
        'success': false,
        'message': e.toString(),
      };
    }
  }

  static Future<Map<String, dynamic>?> signIn({
    required String email,
    required String password,
  }) async {
    try {
      UserCredential userCredential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      // Get user data from Firestore
      DocumentSnapshot userDoc = await _firestore
          .collection('users')
          .doc(userCredential.user!.uid)
          .get();

      if (userDoc.exists) {
        Map<String, dynamic> userData = userDoc.data() as Map<String, dynamic>;
        
        // Check if user is approved
        if (userData['isApproved'] != true && userData['role'] != 'admin') {
          await _auth.signOut();
          return {
            'success': false,
            'message': 'Your account is pending approval',
          };
        }

        return {
          'success': true,
          'message': 'Login successful',
          'user': userData,
        };
      } else {
        return {
          'success': false,
          'message': 'User data not found',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': e.toString(),
      };
    }
  }

  // Admin Functions
  static Future<List<Map<String, dynamic>>> getPendingApprovals() async {
    try {
      QuerySnapshot snapshot = await _firestore
          .collection('users')
          .where('isApproved', isEqualTo: false)
          .orderBy('createdAt', descending: true)
          .get();

      return snapshot.docs.map((doc) {
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
        data['id'] = doc.id;
        return data;
      }).toList();
    } catch (e) {
      print('Error getting pending approvals: $e');
      return [];
    }
  }

  static Future<bool> approveUser(String userId) async {
    try {
      await _firestore.collection('users').doc(userId).update({
        'isApproved': true,
        'approvedAt': FieldValue.serverTimestamp(),
      });
      return true;
    } catch (e) {
      print('Error approving user: $e');
      return false;
    }
  }

  static Future<bool> rejectUser(String userId) async {
    try {
      await _firestore.collection('users').doc(userId).delete();
      return true;
    } catch (e) {
      print('Error rejecting user: $e');
      return false;
    }
  }

  // Complaints Management
  static Future<String?> createComplaint({
    required String title,
    required String description,
    required String userId,
    String? category,
  }) async {
    try {
      DocumentReference docRef = await _firestore.collection('complaints').add({
        'title': title,
        'description': description,
        'userId': userId,
        'category': category ?? 'General',
        'status': 'Open',
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
      return docRef.id;
    } catch (e) {
      print('Error creating complaint: $e');
      return null;
    }
  }

  static Future<List<Map<String, dynamic>>> getComplaints({String? userId}) async {
    try {
      Query query = _firestore.collection('complaints');
      
      if (userId != null) {
        query = query.where('userId', isEqualTo: userId);
      }
      
      QuerySnapshot snapshot = await query
          .orderBy('createdAt', descending: true)
          .get();

      return snapshot.docs.map((doc) {
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
        data['id'] = doc.id;
        return data;
      }).toList();
    } catch (e) {
      print('Error getting complaints: $e');
      return [];
    }
  }

  static Future<bool> updateComplaintStatus(String complaintId, String status) async {
    try {
      await _firestore.collection('complaints').doc(complaintId).update({
        'status': status,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      return true;
    } catch (e) {
      print('Error updating complaint status: $e');
      return false;
    }
  }

  // Buildings Management
  static Future<List<Map<String, dynamic>>> getBuildings() async {
    try {
      QuerySnapshot snapshot = await _firestore.collection('buildings').get();
      return snapshot.docs.map((doc) {
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
        data['id'] = doc.id;
        return data;
      }).toList();
    } catch (e) {
      print('Error getting buildings: $e');
      return [];
    }
  }

  static Future<String?> createBuilding({
    required String name,
    required String address,
    String? unionIncharge,
  }) async {
    try {
      DocumentReference docRef = await _firestore.collection('buildings').add({
        'name': name,
        'address': address,
        'unionIncharge': unionIncharge ?? '',
        'createdAt': FieldValue.serverTimestamp(),
      });
      return docRef.id;
    } catch (e) {
      print('Error creating building: $e');
      return null;
    }
  }

  // Elections Management
  static Future<String?> createElection({
    required String title,
    required String description,
    required List<String> candidates,
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    try {
      DocumentReference docRef = await _firestore.collection('elections').add({
        'title': title,
        'description': description,
        'candidates': candidates,
        'startDate': Timestamp.fromDate(startDate),
        'endDate': Timestamp.fromDate(endDate),
        'status': 'upcoming',
        'votes': {},
        'createdAt': FieldValue.serverTimestamp(),
      });
      return docRef.id;
    } catch (e) {
      print('Error creating election: $e');
      return null;
    }
  }

  static Future<List<Map<String, dynamic>>> getElections() async {
    try {
      QuerySnapshot snapshot = await _firestore
          .collection('elections')
          .orderBy('createdAt', descending: true)
          .get();

      return snapshot.docs.map((doc) {
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
        data['id'] = doc.id;
        return data;
      }).toList();
    } catch (e) {
      print('Error getting elections: $e');
      return [];
    }
  }

  // File Upload
  static Future<String?> uploadFile(Uint8List fileBytes, String fileName, String folder) async {
    try {
      Reference ref = _storage.ref().child('$folder/$fileName');
      UploadTask uploadTask = ref.putData(fileBytes);
      TaskSnapshot snapshot = await uploadTask;
      String downloadUrl = await snapshot.ref.getDownloadURL();
      return downloadUrl;
    } catch (e) {
      print('Error uploading file: $e');
      return null;
    }
  }

  // Real-time Streams
  static Stream<List<Map<String, dynamic>>> streamPendingApprovals() {
    return _firestore
        .collection('users')
        .where('isApproved', isEqualTo: false)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) {
              Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
              data['id'] = doc.id;
              return data;
            }).toList());
  }

  static Stream<List<Map<String, dynamic>>> streamComplaints({String? userId}) {
    Query query = _firestore.collection('complaints');
    
    if (userId != null) {
      query = query.where('userId', isEqualTo: userId);
    }
    
    return query
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) {
              Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
              data['id'] = doc.id;
              return data;
            }).toList());
  }

  // Utility Functions
  static User? getCurrentUser() {
    return _auth.currentUser;
  }

  static Future<void> signOut() async {
    await _auth.signOut();
  }

  static Future<Map<String, dynamic>?> getCurrentUserData() async {
    User? user = getCurrentUser();
    if (user != null) {
      DocumentSnapshot doc = await _firestore.collection('users').doc(user.uid).get();
      if (doc.exists) {
        return doc.data() as Map<String, dynamic>?;
      }
    }
    return null;
  }
} 