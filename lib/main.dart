import 'package:flutter/material.dart';
import 'signup_pages/signup_pages.dart';
import 'dashboards/resident_dashboard.dart';
import 'dashboards/service_provider_dashboard.dart';
import 'dashboards/union_incharge_dashboard.dart';
import 'dashboards/admin_dashboard.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'utils/token_utility.dart';
import 'utils/payment_proof_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
// Supabase imports
import 'services/supabase_service.dart';
import 'config/supabase_config.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize Supabase
  try {
    await SupabaseService.initialize(
      url: SupabaseConfig.supabaseUrl,
      anonKey: SupabaseConfig.supabaseAnonKey,
    );
    print('✅ Supabase initialized successfully');
  } catch (e) {
    print('❌ Failed to initialize Supabase: $e');
    print('💡 Make sure to update your Supabase credentials in supabase_config.dart');
  }
  
  // Initialize PaymentProofService
  await PaymentProofService.instance.initialize();
  
  // Initialize global bank details storage for web persistence
  await _initializeGlobalBankStorage();
  
  runApp(HomeConnectApp());
}

// Track the last working server URL
String? _workingServerUrl;

// Updated getBaseUrl to use the last working URL if available
String getBaseUrl() {
  // If we already have a working URL, return it instead
  if (_workingServerUrl != null) {
    print('🔌 Using cached working server URL: $_workingServerUrl');
    return _workingServerUrl!;
  }
  
  // Original implementation continues below...
  List<String> serverUrls;
  
  if (kIsWeb) {
    // For web, prioritize cloud server for global access
    serverUrls = [
      'https://homeconnect-backend.onrender.com',  // 🌍 CLOUD SERVER (REPLACE WITH YOUR URL)
      'http://localhost:5000',                     // Local development
      'http://127.0.0.1:5000',                     // Alternative localhost
      'http://192.168.18.16:5000',                 // Local network fallback
    ];
    print('🔍 Platform: Web, prioritizing cloud server for global access');
  } else if (Platform.isAndroid) {
    // For Android, prioritize cloud server for global access
    serverUrls = [
      'https://homeconnect-backend.onrender.com',  // 🌍 CLOUD SERVER (REPLACE WITH YOUR URL)
      'http://192.168.18.16:5000',                 // Local network fallback
      'http://10.0.2.2:5000',                      // Android emulator fallback
      'http://localhost:5000',                     // Direct localhost
      'http://127.0.0.1:5000',                     // Another localhost variant
    ];
    print('🔍 Platform: Android, prioritizing cloud server for global access');
  } else if (Platform.isIOS) {
    // For iOS, prioritize cloud server for global access
    serverUrls = [
      'https://homeconnect-backend.onrender.com',  // 🌍 CLOUD SERVER (REPLACE WITH YOUR URL)
      'http://localhost:5000',                     // iOS simulator to host
      'http://127.0.0.1:5000',                     // Alternative localhost
      'http://192.168.18.16:5000',                 // External IP for physical device
    ];
    print('🔍 Platform: iOS, prioritizing cloud server for global access');
  } else {
    // Default fallback order with cloud server first
    serverUrls = [
      'https://homeconnect-backend.onrender.com',  // 🌍 CLOUD SERVER (REPLACE WITH YOUR URL)
      'http://localhost:5000',
      'http://127.0.0.1:5000',
      'http://192.168.18.16:5000',
      'http://10.0.2.2:5000'
    ];
    print('🔍 Platform: Other, prioritizing cloud server for global access');
  }
  
  String primaryUrl = serverUrls[0]; // Default to first server
  print('🔍 Server URLs in priority order: ${serverUrls.join(", ")}');
  
  // Return the primary URL
  return primaryUrl;
}

// List of fallback server URLs to try if primary fails
List<String> getFallbackUrls() {
  // Reusing getBaseUrl logic to get properly ordered URLs based on platform
  String primaryUrl = getBaseUrl();
  
  List<String> serverUrls;
  if (kIsWeb) {
    serverUrls = [
      'https://homeconnect-backend.onrender.com',  // 🌍 CLOUD SERVER (REPLACE WITH YOUR URL)
      'http://localhost:5000',                     // Local development
      'http://127.0.0.1:5000',                     // Alternative localhost
      'http://192.168.18.16:5000',                 // Local network fallback
    ];
  } else if (Platform.isAndroid) {
    serverUrls = [
      'https://homeconnect-backend.onrender.com',  // 🌍 CLOUD SERVER (REPLACE WITH YOUR URL)
      'http://10.0.2.2:5000',
      'http://192.168.18.16:5000',
      'http://localhost:5000', 
      'http://127.0.0.1:5000',
    ];
  } else if (Platform.isIOS) {
    serverUrls = [
      'https://homeconnect-backend.onrender.com',  // 🌍 CLOUD SERVER (REPLACE WITH YOUR URL)
      'http://localhost:5000',
      'http://127.0.0.1:5000',
      'http://192.168.18.16:5000',
    ];
  } else {
    serverUrls = [
      'https://homeconnect-backend.onrender.com',  // 🌍 CLOUD SERVER (REPLACE WITH YOUR URL)
      'http://localhost:5001',
      'http://localhost:5000',
      'http://127.0.0.1:5001',
      'http://127.0.0.1:5000',
      'http://192.168.18.16:5001',
      'http://192.168.18.16:5000',
      'http://10.0.2.2:5001',
      'http://10.0.2.2:5000'
    ];
  }
  
  // Return all URLs except the primary one
  return serverUrls.where((url) => url != primaryUrl).toList();
}

// Function to test API connectivity with fallbacks
Future<bool> testAPIConnection() async {
  // Add a small delay to give server time to start
  await Future.delayed(Duration(seconds: 2));
  
  String primaryUrl = getBaseUrl();
  List<String> fallbackUrls = getFallbackUrls();
  
  // Add the primary URL to the beginning of fallbacks to try it first
  List<String> allUrls = [primaryUrl, ...fallbackUrls.where((url) => url != primaryUrl)];
  
  // For web platform, try all URLs but with proper CORS settings
  if (kIsWeb) {
    print('🔌 Running on web platform with CORS-friendly settings');
  }
  
  print('🔌 Testing ${allUrls.length} possible server URLs');
  
  for (String baseUrl in allUrls) {
    try {
      print('🔍 Testing connection to: $baseUrl');
      
      // Try the simpler /test endpoint which is guaranteed to exist
      final response = await http.get(
        Uri.parse('$baseUrl/test'),
        headers: {
          'Cache-Control': 'no-cache',
          'Accept': 'application/json',
          'Content-Type': 'application/json',
          if (!kIsWeb) 'Access-Control-Allow-Origin': '*',
        },
      ).timeout(const Duration(seconds: 15)); // Increased timeout for more reliable testing
      
      if (response.statusCode == 200) {
        print('✅ Successfully connected to: $baseUrl');
        print('✅ Response: ${response.body}');
        // Store this as the working URL in a global variable for easy access
        _workingServerUrl = baseUrl;
        return true;
      } else {
        print('⚠️ Server responded with status code: ${response.statusCode}');
        print('⚠️ Response body: ${response.body}');
      }
    } catch (e) {
      print('❌ Failed to connect to $baseUrl: $e');
      // For web, try to provide more specific error information
      if (kIsWeb && e.toString().contains('Failed to fetch')) {
        print('💡 Web browser blocked the request. This could be a CORS issue.');
        print('💡 Make sure the Dart backend server is running with proper CORS headers.');
      }
      // Continue to the next URL
    }
  }
  
  print('❌ All server URLs failed. Please check server status and network connection.');
  // For web platform, provide additional troubleshooting info
  if (kIsWeb) {
    print('🌐 Web Platform Troubleshooting:');
    print('   1. Ensure Dart backend server is running on localhost:5000');
    print('   2. Check browser console for CORS errors');
    print('   3. Try running Flutter with: flutter run -d chrome --web-renderer html');
    print('   4. Check if localhost is accessible from your browser');
  }
  return false;
}

class HomeConnectApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'HomeConnect',
      debugShowCheckedModeBanner: false,
      debugShowMaterialGrid: false,
      showPerformanceOverlay: false,
      showSemanticsDebugger: false,
      theme: ThemeData.dark(),
      home: SplashScreen(),
    );
  }
}

class SplashScreen extends StatefulWidget {
  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    
    // Test API connection
    testAPIConnection().then((success) {
      print('🔌 API connection ${success ? 'successful' : 'failed'}');
    });
    
    Future.delayed(Duration(seconds: 4), () {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => LoginPage()),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset('assets/images/logo.png', height: 350),
            const SizedBox(height: 40),
            const CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Colors.orangeAccent),
            ),
          ],
        ),
      ),
    );
  }
}

class LoginPage extends StatefulWidget {
  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  String selectedRole = 'Resident';
  final List<String> roles = ['Union Incharge', 'Service Provider', 'Resident'];

  final emailController = TextEditingController();
  final passwordController = TextEditingController();

  bool isHovering = false;

  Future<void> login(BuildContext context) async {
    final email = emailController.text.trim();
    final password = passwordController.text;
    
    if (email.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter email and password')),
      );
      return;
    }
    
    print('🔑 Attempting Supabase login with email: $email, role: $selectedRole');

    try {
      // Use Supabase authentication
      final result = await SupabaseService.signIn(
        email: email,
        password: password,
      );

      if (result['success'] == true) {
        final user = result['user'];
        
        final userId = user['id']?.toString() ?? '';
        final firstName = user['first_name']?.toString() ?? '';
        final role = user['role']?.toString() ?? '';
        
        print('✅ Supabase login successful - Role: $role, Name: $firstName, ID: $userId');
        
        // Store user data in SharedPreferences for use throughout the app
        try {
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString('user_data', jsonEncode(user));
          print('✅ User data stored in SharedPreferences');
        } catch (e) {
          print('⚠️ Error storing user data in SharedPreferences: $e');
        }
        
        if (role.toLowerCase() == 'resident') {
          // Check if resident is approved
          final isApproved = user['is_approved'] ?? false;
          if (isApproved) {
            // Get building and union information for the resident
            final buildingName = user['building_name']?.toString();
            final unionId = user['union_id']?.toString(); // If available from backend
            
            // Approved resident gets access to their dashboard
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (_) => ResidentDashboard(
                userName: firstName,
                userId: userId,
                buildingName: buildingName,
                unionId: unionId,
              )),
            );
          } else {
            // Not approved yet - show message
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Your resident application is pending union incharge approval'),
                backgroundColor: Colors.orange,
                duration: Duration(seconds: 4),
              ),
            );
          }
        } else if (role.toLowerCase() == 'union incharge') {
          // Check if union incharge is approved
          final isApproved = user['is_approved'] ?? false;
          if (isApproved) {
            // Approved union incharge gets their special dashboard
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (_) => UnionInchargeDashboard(user: user)),
            );
          } else {
            // Not approved yet - show message
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Your union incharge application is pending admin approval'),
                backgroundColor: Colors.orange,
              ),
            );
          }
        } else if (role.toLowerCase() == 'service provider') {
          // Check if service provider is approved
          final isApproved = user['is_approved'] ?? false;
          if (isApproved) {
            print('✅ Service provider is approved, navigating to dashboard');
            // Approved service provider gets their dashboard
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (_) => ServiceProviderDashboard(
                providerName: firstName,
                providerId: userId,
              )),
            );
          } else {
            print('⚠️ Service provider not approved yet');
            // Not approved yet - show message
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Your service provider application is pending admin approval'),
                backgroundColor: Colors.orange,
              ),
            );
          }
        } else if (role.toLowerCase() == 'admin') {
          // Admin user
          print('✅ Admin login successful');
          Navigator.pushReplacement(
            context, 
            MaterialPageRoute(builder: (_) => const AdminDashboard())
          );
        } else {
          print('❌ Unknown role: $role');
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Unknown user role: $role')),
          );
        }
      } else {
        print('❌ Supabase login failed: ${result['message']}');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(result['message'] ?? 'Login failed')),
        );
      }
    } catch (e) {
      print('❌ Login error: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: ${e.toString()}')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final isWebLayout = screenWidth > 600;
    final isLargeScreen = screenWidth > 1200;
    
    // Responsive dimensions
    double containerWidth;
    double logoHeight;
    double spacing;
    double fontSize;
    
    if (screenWidth <= 600) {
      // Mobile
      containerWidth = screenWidth * 0.9;
      logoHeight = 80;
      spacing = 12;
      fontSize = 14;
    } else if (screenWidth <= 800) {
      // Tablet
      containerWidth = 450;
      logoHeight = 90;
      spacing = 16;
      fontSize = 15;
    } else if (screenWidth <= 1200) {
      // Medium desktop
      containerWidth = 500;
      logoHeight = 100;
      spacing = 20;
      fontSize = 16;
    } else {
      // Large desktop
      containerWidth = 550;
      logoHeight = 120;
      spacing = 24;
      fontSize = 16;
    }
    
    return Scaffold(
      body: Stack(
        children: [
          Container(
            decoration: BoxDecoration(
              image: DecorationImage(
                image: AssetImage(_getBackgroundForRole()),
                fit: BoxFit.cover,
              ),
            ),
          ),
          Center(
            child: SingleChildScrollView(
              padding: EdgeInsets.symmetric(
                horizontal: isWebLayout ? 40 : 20,
                vertical: 20,
              ),
              child: MouseRegion(
                onEnter: (_) => setState(() => isHovering = true),
                onExit: (_) => setState(() => isHovering = false),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  padding: EdgeInsets.all(isWebLayout ? 32 : 24),
                  width: containerWidth,
                  constraints: BoxConstraints(
                    maxWidth: containerWidth,
                    minHeight: isWebLayout ? 500 : 400,
                  ),
                  decoration: BoxDecoration(
                    color: isHovering ? Colors.black87 : Colors.black54,
                    borderRadius: BorderRadius.circular(isWebLayout ? 20 : 16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.3),
                        blurRadius: isWebLayout ? 20 : 15,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Logo
                      Image.asset(
                        'assets/images/logo.png',
                        height: logoHeight,
                      ),
                      SizedBox(height: spacing),
                      
                      // Welcome Text
                      Text(
                        'Welcome to HomeConnect',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: isWebLayout ? 24 : 20,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      SizedBox(height: spacing * 0.5),
                      Text(
                        'Please select your role and login',
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: fontSize,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      SizedBox(height: spacing * 1.5),
                      
                      // Role Dropdown
                      Container(
                        width: double.infinity,
                        padding: EdgeInsets.symmetric(
                          horizontal: isWebLayout ? 16 : 12,
                          vertical: isWebLayout ? 4 : 2,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.black45,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.white30),
                        ),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            value: selectedRole,
                            dropdownColor: Colors.black87,
                            iconEnabledColor: Colors.white,
                            isExpanded: true,
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: fontSize,
                            ),
                            items: roles.map((role) {
                              return DropdownMenuItem(
                                value: role, 
                                child: Text(
                                  role,
                                  style: TextStyle(
                                    fontSize: fontSize,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              );
                            }).toList(),
                            onChanged: (value) {
                              setState(() => selectedRole = value!);
                            },
                          ),
                        ),
                      ),
                      SizedBox(height: spacing),
                      
                      // Email Field
                      _buildTextField(
                        emailController, 
                        'Email Address',
                        fontSize: fontSize,
                        isWebLayout: isWebLayout,
                        icon: Icons.email,
                      ),
                      SizedBox(height: spacing),
                      
                      // Password Field
                      _buildTextField(
                        passwordController, 
                        'Password',
                        isPassword: true,
                        fontSize: fontSize,
                        isWebLayout: isWebLayout,
                        icon: Icons.lock,
                      ),
                      SizedBox(height: spacing * 1.5),
                      
                      // Action Buttons
                      if (isWebLayout) ...[
                        // Desktop Layout - Side by side
                        Row(
                          children: [
                            Expanded(
                              child: ElevatedButton.icon(
                                onPressed: () => login(context),
                                icon: Icon(Icons.login, size: fontSize + 2),
                                label: Text(
                                  'Login',
                                  style: TextStyle(fontSize: fontSize),
                                ),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.blue[600],
                                  foregroundColor: Colors.white,
                                  padding: EdgeInsets.symmetric(vertical: 16),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  elevation: 4,
                                ),
                              ),
                            ),
                            SizedBox(width: 16),
                            Expanded(
                              child: OutlinedButton.icon(
                                onPressed: () => _navigateToSignup(context),
                                icon: Icon(Icons.person_add, size: fontSize + 2),
                                label: Text(
                                  'Signup',
                                  style: TextStyle(fontSize: fontSize),
                                ),
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: Colors.white,
                                  side: const BorderSide(color: Colors.white, width: 2),
                                  padding: EdgeInsets.symmetric(vertical: 16),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ] else ...[
                        // Mobile Layout - Stacked
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            onPressed: () => login(context),
                            icon: Icon(Icons.login, size: fontSize + 2),
                            label: Text(
                              'Login',
                              style: TextStyle(fontSize: fontSize),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.blue[600],
                              foregroundColor: Colors.white,
                              padding: EdgeInsets.symmetric(vertical: 16),
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
                          child: OutlinedButton.icon(
                            onPressed: () => _navigateToSignup(context),
                            icon: Icon(Icons.person_add, size: fontSize + 2),
                            label: Text(
                              'Create Account',
                              style: TextStyle(fontSize: fontSize),
                            ),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: Colors.white,
                              side: const BorderSide(color: Colors.white, width: 2),
                              padding: EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          )
        ],
      ),
    );
  }

  Widget _buildTextField(
    TextEditingController controller, 
    String label,
    {
      bool isPassword = false,
      required double fontSize,
      required bool isWebLayout,
      IconData? icon,
    }
  ) {
    return TextField(
      controller: controller,
      obscureText: isPassword,
      style: TextStyle(
        color: Colors.white,
        fontSize: fontSize,
      ),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(
          color: Colors.white70,
          fontSize: fontSize - 1,
        ),
        prefixIcon: icon != null 
          ? Icon(
              icon, 
              color: Colors.white70,
              size: fontSize + 4,
            ) 
          : null,
        enabledBorder: OutlineInputBorder(
          borderSide: const BorderSide(color: Colors.white30, width: 1.5),
          borderRadius: BorderRadius.circular(12),
        ),
        focusedBorder: OutlineInputBorder(
          borderSide: const BorderSide(color: Colors.blueAccent, width: 2),
          borderRadius: BorderRadius.circular(12),
        ),
        filled: true,
        fillColor: Colors.black26,
        contentPadding: EdgeInsets.symmetric(
          horizontal: isWebLayout ? 16 : 12,
          vertical: isWebLayout ? 16 : 14,
        ),
      ),
    );
  }

  void _navigateToSignup(BuildContext context) {
    if (selectedRole == 'Union Incharge' &&
        emailController.text == 'admin@homeconnect.com') {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Admin cannot sign up")),
      );
    } else {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => SignupPageRouter(userType: selectedRole),
        ),
      );
    }
  }

  String _getBackgroundForRole() {
    switch (selectedRole.toLowerCase()) {
      case 'union incharge':
        return 'assets/images/union.png';
      case 'service provider':
        return 'assets/images/provider.png';
      default:
        return 'assets/images/resident.png';
    }
  }
}

// Global bank details storage initialization
Future<void> _initializeGlobalBankStorage() async {
  if (kIsWeb) {
    try {
      print('🌐 Initializing global bank storage for web persistence...');
      
      // Use a special persistent key that browsers are less likely to clear
      final prefs = await SharedPreferences.getInstance();
      
      // Check if we have any bank data under different keys and consolidate
      final allKeys = prefs.getKeys();
      final bankKeys = allKeys.where((key) => 
        key.contains('bank') || 
        key.contains('iban') || 
        key.contains('account_title') ||
        key.contains('master_bank_index')
      ).toList();
      
      if (bankKeys.isNotEmpty) {
        print('🔑 Found ${bankKeys.length} bank-related keys on startup');
        
        // Try to recover any lost bank data and create a master backup
        for (final key in bankKeys) {
          if (key.contains('xyz_apartment') || key.contains('demo_building')) {
            final value = prefs.getString(key);
            if (value != null && value.isNotEmpty) {
              print('📦 Found bank data in key: $key');
              
              // Create additional persistent backup
              final persistentKey = 'persistent_$key';
              await prefs.setString(persistentKey, value);
              
              // Create timestamp backup
              final timestampKey = '${key}_${DateTime.now().millisecondsSinceEpoch}';
              await prefs.setString(timestampKey, value);
              
              print('💾 Created persistent backups for $key');
            }
          }
        }
        
        // Force commit
        await Future.delayed(Duration(milliseconds: 200));
      } else {
        print('ℹ️ No existing bank data found on startup');
      }
      
    } catch (e) {
      print('⚠️ Error initializing global bank storage: $e');
    }
  }
}
