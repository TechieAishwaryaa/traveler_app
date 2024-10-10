import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:typed_data'; // For Uint8List

class RegistrationPage extends StatefulWidget {
  const RegistrationPage({Key? key}) : super(key: key);

  @override
  _RegistrationPageState createState() => _RegistrationPageState();
}

class _RegistrationPageState extends State<RegistrationPage> {
  final TextEditingController nameController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController phoneController = TextEditingController();
  Uint8List? _selectedImageBytes; // To store picked image bytes
  bool isLoading = false; // For showing a loading indicator during registration

  // Method to pick image from gallery and store it as bytes
  Future<void> pickImage() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);

    if (image != null) {
      Uint8List imageBytes = await image.readAsBytes(); // Convert to Uint8List
      setState(() {
        _selectedImageBytes = imageBytes;
      });
    }
  }

  // Method to upload image bytes to Firebase Storage and get the download URL
  Future<String?> uploadImage(String travelerId) async {
    if (_selectedImageBytes == null) return null;

    try {
      // Create a reference to Firebase Storage
      Reference storageRef = FirebaseStorage.instance
          .ref()
          .child('traveler/$travelerId'); // Folder 'traveler_photos' with document ID

      // Upload the image bytes using putData
      UploadTask uploadTask = storageRef.putData(_selectedImageBytes!);

      // Wait for the upload to complete
      TaskSnapshot snapshot = await uploadTask;

      if (snapshot.state == TaskState.success) {
        // Get the download URL of the uploaded image
        String downloadUrl = await storageRef.getDownloadURL();
        return downloadUrl;
      }
      return null;
    } catch (e) {
      print('Error uploading image: $e');
      return null;
    }
  }

  // Method to register the traveler
  Future<void> register() async {
    final name = nameController.text.trim();
    final email = emailController.text.trim();
    final password = passwordController.text.trim();
    final phone = phoneController.text.trim();

    if (name.isEmpty || email.isEmpty || password.isEmpty || phone.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill all fields')),
      );
      return;
    }

    setState(() {
      isLoading = true; // Start loading
    });

    try {
      // Add traveler data to Firestore with autogenerated document ID
      final docRef = await FirebaseFirestore.instance.collection('travelers').add({
        'travelerName': name,
        'email': email,
        'password': password,
        'phone': phone,
        'photoUrl': '', // Placeholder for photoUrl, will update later
      });

      final travelerId = docRef.id; // Get the auto-generated document ID

      // Upload the image and get the download URL
      final photoUrl = await uploadImage(travelerId);

      if (photoUrl != null) {
        // Update Firestore document with the photoUrl
        await FirebaseFirestore.instance.collection('travelers').doc(travelerId).update({
          'photoUrl': photoUrl,
          'travelerId': travelerId, // Add the travelerId to Firestore document
        });
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Registration successful!'),
          backgroundColor: Colors.green,
        ),
      );
      Navigator.pop(context); // Return to previous screen after registration
    } catch (e) {
      print('Error registering traveler: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Registration failed: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        isLoading = false; // Stop loading
      });
    }
  }

  @override
  void dispose() {
    nameController.dispose();
    emailController.dispose();
    passwordController.dispose();
    phoneController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Register Traveler',
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        ),
        backgroundColor: Colors.deepOrangeAccent[100],
        centerTitle: true,
        elevation: 8,
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text(
                'Create an Account',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.deepOrange,
                ),
              ),
              const SizedBox(height: 20),
              // Name Input
              TextField(
                controller: nameController,
                decoration: InputDecoration(
                  labelText: 'Name',
                  labelStyle: const TextStyle(color: Colors.deepOrangeAccent),
                  filled: true,
                  fillColor: Colors.deepOrange[50],
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(20),
                    borderSide: const BorderSide(color: Colors.deepOrange),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(20),
                    borderSide: const BorderSide(color: Colors.deepOrangeAccent),
                  ),
                  prefixIcon: const Icon(
                    Icons.person_outline,
                    color: Colors.deepOrange,
                  ),
                  contentPadding:
                      const EdgeInsets.symmetric(vertical: 15, horizontal: 20),
                ),
              ),
              const SizedBox(height: 20),
              // Email Input
              TextField(
                controller: emailController,
                keyboardType: TextInputType.emailAddress,
                decoration: InputDecoration(
                  labelText: 'Email',
                  labelStyle: const TextStyle(color: Colors.deepOrangeAccent),
                  filled: true,
                  fillColor: Colors.deepOrange[50],
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(20),
                    borderSide: const BorderSide(color: Colors.deepOrange),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(20),
                    borderSide: const BorderSide(color: Colors.deepOrangeAccent),
                  ),
                  prefixIcon: const Icon(
                    Icons.email_outlined,
                    color: Colors.deepOrange,
                  ),
                  contentPadding:
                      const EdgeInsets.symmetric(vertical: 15, horizontal: 20),
                ),
              ),
              const SizedBox(height: 20),
              // Password Input
              TextField(
                controller: passwordController,
                obscureText: true,
                decoration: InputDecoration(
                  labelText: 'Password',
                  labelStyle: const TextStyle(color: Colors.deepOrangeAccent),
                  filled: true,
                  fillColor: Colors.deepOrange[50],
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(20),
                    borderSide: const BorderSide(color: Colors.deepOrange),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(20),
                    borderSide: const BorderSide(color: Colors.deepOrangeAccent),
                  ),
                  prefixIcon: const Icon(
                    Icons.lock_outline,
                    color: Colors.deepOrange,
                  ),
                  contentPadding:
                      const EdgeInsets.symmetric(vertical: 15, horizontal: 20),
                ),
              ),
              const SizedBox(height: 20),
              // Phone Input
              TextField(
                controller: phoneController,
                keyboardType: TextInputType.phone,
                decoration: InputDecoration(
                  labelText: 'Phone Number',
                  labelStyle: const TextStyle(color: Colors.deepOrangeAccent),
                  filled: true,
                  fillColor: Colors.deepOrange[50],
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(20),
                    borderSide: const BorderSide(color: Colors.deepOrange),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(20),
                    borderSide: const BorderSide(color: Colors.deepOrangeAccent),
                  ),
                  prefixIcon: const Icon(
                    Icons.phone_outlined,
                    color: Colors.deepOrange,
                  ),
                  contentPadding:
                      const EdgeInsets.symmetric(vertical: 15, horizontal: 20),
                ),
              ),
              const SizedBox(height: 20),
              // Image Upload
              GestureDetector(
                onTap: pickImage, // Pick image from gallery
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.deepOrange[50],
                    border: Border.all(color: Colors.deepOrange),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 20),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: const [
                      Icon(Icons.camera_alt_outlined, color: Colors.deepOrange),
                      SizedBox(width: 10),
                      Text('Upload Photo', style: TextStyle(color: Colors.deepOrange)),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),
              // Display selected image (if any)
              if (_selectedImageBytes != null)
                Image.memory(
                  _selectedImageBytes!,
                  height: 200,
                  width: 200,
                  fit: BoxFit.cover,
                ),
              const SizedBox(height: 20),
              // Register Button
              ElevatedButton(
                onPressed: isLoading ? null : register,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.deepOrange,
                  padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 50),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
                child: isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text(
                        'Register',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
