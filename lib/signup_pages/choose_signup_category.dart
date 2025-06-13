import 'package:flutter/material.dart';
import 'resident_signup.dart';
import 'service_provider_signup.dart';
import 'union_signup.dart';

class ChooseSignupCategory extends StatefulWidget {
  const ChooseSignupCategory({Key? key}) : super(key: key);

  @override
  State<ChooseSignupCategory> createState() => _ChooseSignupCategoryState();
}

class _ChooseSignupCategoryState extends State<ChooseSignupCategory> {
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
          'Choose Account Type',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: isWebLayout ? 22 : 20,
          ),
        ),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
      ),
      body: Center(
        child: Container(
          constraints: BoxConstraints(maxWidth: maxWidth),
          child: SingleChildScrollView(
            padding: EdgeInsets.all(isWebLayout ? 32 : 20),
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
                        Colors.deepPurple[600]!,
                        Colors.deepPurple[800]!,
                      ],
                    ),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.deepPurple.withOpacity(0.3),
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
                          Icons.person_add,
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
                              'Create Account',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: isWebLayout ? 20 : 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            SizedBox(height: isWebLayout ? 8 : 4),
                            Text(
                              'Select your account type to get started',
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
                
                // Category Options
                _buildCategoryOptions(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCategoryOptions() {
    final screenWidth = MediaQuery.of(context).size.width;
    final isWebLayout = screenWidth > 600;
    
    // Responsive grid configuration
    int crossAxisCount;
    double childAspectRatio;
    
    if (screenWidth <= 600) {
      // Mobile: 1 column
      crossAxisCount = 1;
      childAspectRatio = 1.2;
    } else if (screenWidth <= 900) {
      // Tablet: 2 columns
      crossAxisCount = 2;
      childAspectRatio = 1.1;
    } else {
      // Desktop: 3 columns
      crossAxisCount = 3;
      childAspectRatio = 1.0;
    }
    
    final List<Map<String, dynamic>> categories = [
      {
        'title': 'Resident',
        'subtitle': 'Join your residential community',
        'description': 'Access building services, pay maintenance, participate in community activities',
        'icon': Icons.home,
        'color': Colors.blue[600],
        'route': () => const ResidentSignupPage(),
      },
      {
        'title': 'Service Provider',
        'subtitle': 'Offer professional services',
        'description': 'Provide services to residents, manage requests, grow your business',
        'icon': Icons.work,
        'color': Colors.green[600],
        'route': () => const ServiceProviderSignupPage(),
      },
      {
        'title': 'Union Incharge',
        'subtitle': 'Manage residential unions',
        'description': 'Oversee building operations, manage residents, handle administration',
        'icon': Icons.admin_panel_settings,
        'color': Colors.orange[600],
        'route': () => const UnionSignupPage(),
      },
    ];
    
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        crossAxisSpacing: isWebLayout ? 20 : 16,
        mainAxisSpacing: isWebLayout ? 20 : 16,
        childAspectRatio: childAspectRatio,
      ),
      itemCount: categories.length,
      itemBuilder: (context, index) {
        final category = categories[index];
        return _buildCategoryCard(category, isWebLayout);
      },
    );
  }

  Widget _buildCategoryCard(Map<String, dynamic> category, bool isWebLayout) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => category['route']()),
        );
      },
      child: Container(
        padding: EdgeInsets.all(isWebLayout ? 24 : 20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
          border: Border.all(
            color: category['color'].withOpacity(0.2),
            width: 2,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Icon Container
            Container(
              padding: EdgeInsets.all(isWebLayout ? 20 : 16),
              decoration: BoxDecoration(
                color: category['color'].withOpacity(0.1),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(
                category['icon'],
                color: category['color'],
                size: isWebLayout ? 48 : 40,
              ),
            ),
            
            SizedBox(height: isWebLayout ? 20 : 16),
            
            // Title
            Text(
              category['title'],
              style: TextStyle(
                fontSize: isWebLayout ? 20 : 18,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
              textAlign: TextAlign.center,
            ),
            
            SizedBox(height: isWebLayout ? 8 : 6),
            
            // Subtitle
            Text(
              category['subtitle'],
              style: TextStyle(
                fontSize: isWebLayout ? 14 : 13,
                fontWeight: FontWeight.w600,
                color: category['color'],
              ),
              textAlign: TextAlign.center,
            ),
            
            SizedBox(height: isWebLayout ? 12 : 8),
            
            // Description
            Text(
              category['description'],
              style: TextStyle(
                fontSize: isWebLayout ? 13 : 12,
                color: Colors.grey[600],
                height: 1.4,
              ),
              textAlign: TextAlign.center,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
            
            SizedBox(height: isWebLayout ? 16 : 12),
            
            // Action Button
            Container(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => category['route']()),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: category['color'],
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.symmetric(
                    vertical: isWebLayout ? 12 : 10,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  elevation: 2,
                ),
                child: Text(
                  'Get Started',
                  style: TextStyle(
                    fontSize: isWebLayout ? 14 : 13,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
