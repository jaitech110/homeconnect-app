import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:io';
import 'package:image_picker/image_picker.dart';

class UploadMenuScreen extends StatefulWidget {
  final String providerId;
  const UploadMenuScreen({super.key, required this.providerId});

  @override
  State<UploadMenuScreen> createState() => _UploadMenuScreenState();
}

class _UploadMenuScreenState extends State<UploadMenuScreen> {
  final TextEditingController serviceNameController = TextEditingController();
  final TextEditingController descriptionController = TextEditingController();
  final TextEditingController priceController = TextEditingController();
  File? selectedImage;

  Future<void> pickImage() async {
    final pickedFile = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        selectedImage = File(pickedFile.path);
      });
    }
  }

  Future<void> uploadMenuItem() async {
    if (serviceNameController.text.isEmpty ||
        priceController.text.isEmpty ||
        selectedImage == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('All fields and image are required')),
      );
      return;
    }

    final request = http.MultipartRequest(
      'POST',
      Uri.parse('http://localhost:5000/provider/upload_menu'),
    );
    request.fields['provider_id'] = widget.providerId;
    request.fields['service_name'] = serviceNameController.text;
    request.fields['description'] = descriptionController.text;
    request.fields['price'] = priceController.text;
    request.files.add(await http.MultipartFile.fromPath('image', selectedImage!.path));

    final response = await request.send();

    if (response.statusCode == 201) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Menu item uploaded successfully')),
      );
      setState(() {
        serviceNameController.clear();
        descriptionController.clear();
        priceController.clear();
        selectedImage = null;
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Upload failed')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Upload Service Menu')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: serviceNameController,
              decoration: const InputDecoration(labelText: 'Service Name'),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: descriptionController,
              decoration: const InputDecoration(labelText: 'Description'),
              maxLines: 3,
            ),
            const SizedBox(height: 10),
            TextField(
              controller: priceController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Price'),
            ),
            const SizedBox(height: 10),
            selectedImage != null
                ? Image.file(selectedImage!, height: 150)
                : const Text('No image selected'),
            const SizedBox(height: 10),
            ElevatedButton.icon(
              onPressed: pickImage,
              icon: const Icon(Icons.image),
              label: const Text('Pick Image'),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: uploadMenuItem,
              child: const Text('Upload Menu Item'),
            ),
          ],
        ),
      ),
    );
  }
}
