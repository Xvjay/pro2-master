import 'dart:io';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'navigation_bar.dart' as custom_nav;
import 'message_screen.dart';
import 'settings_screen.dart';
import 'image_handler.dart'; // Make sure this import is correct

class ProfileScreen extends StatefulWidget {
  @override
  _ProfileScreenState createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final ImageHandler _imageHandler = ImageHandler(); // ImageHandler instance

  TextEditingController _usernameController = TextEditingController();
  TextEditingController _firstNameController = TextEditingController();
  TextEditingController _lastNameController = TextEditingController();
  String? _userRole;
  String? _email;
  DateTime? _registrationDate;
  String? _imageUrl; // URL for the image

  int _currentIndex = 0; // Index 0 for the Profile Screen

  @override
  void initState() {
    super.initState();
    _loadUserProfile();
  }

  void _loadUserProfile() async {
    User? currentUser = _auth.currentUser;
    if (currentUser != null) {
      var userDoc = _firestore.collection('users').doc(currentUser.uid);
      userDoc.get().then((doc) {
        if (doc.exists) {
          var data = doc.data() as Map<String, dynamic>;
          _usernameController.text = data['username'] ?? '';
          _firstNameController.text = data['firstName'] ?? '';
          _lastNameController.text = data['lastName'] ?? '';
          _userRole = data['userRole'];
          _email = currentUser.email; // Email comes from FirebaseAuth
          _imageUrl = data['profilePictureUrl']; // Load the image URL
          _registrationDate =
              (data['registrationDatetime'] as Timestamp).toDate();
          setState(() {}); // Ensure the UI is updated
        }
      }).catchError((error) {
        print("Failed to load user data: $error");
      });
    }
  }

  void _updateUserProfile() async {
    User? currentUser = _auth.currentUser;
    if (currentUser != null) {
      await _firestore.collection('users').doc(currentUser.uid).update({
        'username': _usernameController.text,
        'firstName': _firstNameController.text,
        'lastName': _lastNameController.text,
      }).then((_) {
        print("User profile updated");
      }).catchError((error) {
        print("Failed to update user data: $error");
      });
    }
  }

  void _uploadAndDisplayImage() async {
    final pickedFile = await _imageHandler.pickImage();
    if (pickedFile != null) {
      String downloadUrl = await _imageHandler.uploadImage(pickedFile);
      // Update the user profile in Firestore
      User? currentUser = _auth.currentUser;
      if (currentUser != null) {
        await _firestore.collection('users').doc(currentUser.uid).update({
          'profilePictureUrl': downloadUrl,
        }).then((_) {
          setState(() {
            _imageUrl =
                downloadUrl; // This will only be set after Firestore confirms the update.
          });
        }).catchError((error) {
          print("Failed to update user data: $error");
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Profile")),
      bottomNavigationBar: custom_nav.NavigationBar(
        currentIndex: _currentIndex,
        onItemTapped: _onItemTapped,
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            if (_imageUrl != null)
              _imageHandler.displayImage(
                  _imageUrl!), // Display the image using ImageHandler
            Column(
              children: <Widget>[
                ElevatedButton(
                  onPressed: _uploadAndDisplayImage,
                  child: const Text('Upload Profile Picture'),
                  style: ElevatedButton.styleFrom(
                    foregroundColor: Colors.black,
                    backgroundColor: Colors.grey[400],
                    padding:
                        const EdgeInsets.symmetric(horizontal: 50, vertical: 8),
                    textStyle: const TextStyle(
                        fontSize: 16, fontWeight: FontWeight.bold),
                    elevation: 2,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: TextFormField(
                    controller: _usernameController,
                    decoration: const InputDecoration(
                      labelText: 'User Name',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: TextFormField(
                    controller: _firstNameController,
                    decoration: const InputDecoration(
                      labelText: 'First Name',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: TextFormField(
                    controller: _lastNameController,
                    decoration: const InputDecoration(
                      labelText: 'Last Name',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                ListTile(
                  title: const Text('Email'),
                  subtitle: Text(_email ?? 'No email'),
                ),
                ListTile(
                  title: const Text('User Role'),
                  subtitle: Text(_userRole ?? 'No role assigned'),
                ),
                ListTile(
                  title: const Text('Registration Date'),
                  subtitle: Text(_registrationDate != null
                      ? DateFormat('yyyy-MM-dd').format(_registrationDate!)
                      : 'Not registered'),
                ),
                ElevatedButton(
                  onPressed: _updateUserProfile,
                  child: const Text('Update Profile'),
                  style: ElevatedButton.styleFrom(
                    foregroundColor: Colors.black,
                    backgroundColor:
                        Colors.grey[400], // Text color for readability
                    padding:
                        const EdgeInsets.symmetric(horizontal: 50, vertical: 8),
                    textStyle: const TextStyle(
                        fontSize: 16, fontWeight: FontWeight.bold),
                    elevation: 2, // Subtle shadow for a slight 3D effect
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(
                          8), // Rounded corners for a sleek look
                    ),
                  ),
                ),
              ],
            )
          ],
        ),
      ),
    );
  }

  void _onItemTapped(int index) {
    if (index != 0) {
      // Don't navigate away if we're on the current screen
      switch (index) {
        case 1:
          Navigator.pushReplacementNamed(context, '/messages');
          break;
        case 2:
          Navigator.pushReplacementNamed(context, '/feed');
          break;
        case 3:
          Navigator.pushReplacementNamed(context, '/settings');
          break;
      }
    }
  }
}
