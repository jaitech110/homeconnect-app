import 'package:flutter/material.dart';
import 'resident_signup.dart';
import 'union_signup.dart';
import 'service_provider_signup.dart';

class SignupPageRouter extends StatelessWidget {
  final String userType;

  const SignupPageRouter({super.key, required this.userType});

  @override
  Widget build(BuildContext context) {
    switch (userType) {
      case 'Resident':
        return const ResidentSignupPage();
      case 'Union Incharge':
        return const UnionSignupPage();
      case 'Service Provider':
        return const ServiceProviderSignupPage();
      default:
        return Scaffold(
          backgroundColor: Colors.black,
          appBar: AppBar(title: const Text("Error")),
          body: const Center(
            child: Text(
              'Unknown user type provided!',
              style: TextStyle(color: Colors.white),
            ),
          ),
        );
    }
  }
}
