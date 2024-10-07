import 'dart:io';
import 'package:cook/models/presigned_url.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cook/services/s3_upload_service.dart'; // Use your S3UploadService
import 'package:cook/services/loginservice.dart'; // Use your LoginService
import 'package:cook/services/userprofile_service.dart'; // Use the UserProfileService
import 'package:cook/models/editprofile_model.dart'; // Use your EditUserProfile model

class EditProfilePage extends StatefulWidget {
  final String currentUsername;
  final String currentBio;
  final File? currentImage;

  EditProfilePage({
    required this.currentUsername,
    required this.currentBio,
    this.currentImage,
  });

  @override
  _EditProfilePageState createState() => _EditProfilePageState();
}

class _EditProfilePageState extends State<EditProfilePage> {
  late TextEditingController usernameController;
  late TextEditingController bioController;
  File? _imageFile;
  final ImagePicker _picker = ImagePicker();
  final int bioMaxLength = 150;
  bool isUploading = false;

  @override
  void initState() {
    super.initState();
    usernameController = TextEditingController(text: widget.currentUsername);
    bioController = TextEditingController(text: widget.currentBio);
    _imageFile = widget.currentImage;
  }

  Future<void> _pickImage(ImageSource source) async {
    final pickedFile = await _picker.pickImage(source: source);
    if (pickedFile != null) {
      setState(() {
        _imageFile = File(pickedFile.path);
      });
    }
  }

  Future<void> _saveChanges() async {
    setState(() {
      isUploading = true;
    });

    String? uploadedImageUrl;
    if (_imageFile != null) {
      uploadedImageUrl = await _uploadProfileImage(_imageFile!);
    }

    String? newUsername = (usernameController.text != widget.currentUsername) ? usernameController.text : null;
    String? newBio = (bioController.text != widget.currentBio) ? bioController.text : null;
    String? newProfilePic = (uploadedImageUrl != null) ? uploadedImageUrl : null;

    if (newProfilePic != null || newUsername != null || newBio != null) {
      UserProfileService userProfileService = UserProfileService();
      int userId = await LoginService().getUserId() ?? 0;

      EditUserProfile updatedProfile = EditUserProfile(
        profilePic: newProfilePic,
        fullName: newUsername,
        bio: newBio,
      );

      bool success = await userProfileService.editUserProfile(
        id: userId.toString(),
        editUserProfile: updatedProfile,
      );

      if (success) {
        Navigator.pop(context, {
          'username': usernameController.text,
          'bio': bioController.text,
          'imageFile': _imageFile,
        });
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to update profile')),
        );
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('No changes detected')),
      );
    }

    setState(() {
      isUploading = false;
    });
  }

  Future<String?> _uploadProfileImage(File imageFile) async {
    try {
      S3UploadService s3UploadService = S3UploadService();
      String fileName = imageFile.path.split('/').last;
      List<PresignedUrl> presignedUrls = await s3UploadService.getPresignedUrls([fileName], folderName: 'users');

      if (presignedUrls.isNotEmpty) {
        String uploadedUrl = await s3UploadService.uploadFile(presignedUrls[0], XFile(imageFile.path));
        return uploadedUrl;
      }
    } catch (e) {
      print('Error uploading profile image: $e');
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    double screenWidth = MediaQuery.of(context).size.width;

    return Material(
      type: MaterialType.transparency,
      child: Scaffold(
        resizeToAvoidBottomInset: true,
        backgroundColor: Colors.transparent,
        body: SafeArea(
          child: Stack(
            children: [
              GestureDetector(
                onTap: () => Navigator.pop(context),
                child: Container(
                  color: Colors.transparent,
                ),
              ),
              Align(
                alignment: Alignment.center,
                child: SingleChildScrollView(
                  child: Container(
                    width: screenWidth * 0.85,
                    padding: const EdgeInsets.all(20.0),
                    decoration: BoxDecoration(
                        color: Colors.white,
                        border: Border.all(color: Color(0xFFF45F67), width: 2), // Border with primary color
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black26,
                            blurRadius: 15,
                            spreadRadius: 5,
                            offset: Offset(0, 8),
                          ),
                        ],
                        borderRadius: BorderRadius.circular(30),  // Rounded corners
                      ),

                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Align(
                          alignment: Alignment.topRight,
                          child: GestureDetector(
                            onTap: () {
                              Navigator.pop(context);
                            },
                            child: Icon(Icons.close, color: Colors.grey, size: 24),
                          ),
                        ),
                        SizedBox(height: 10),
                        GestureDetector(
                          onTap: () {
                            _showImageSourceActionSheet(context);
                          },
                          child: CircleAvatar(
                            radius: 60,
                            backgroundImage: _imageFile != null
                                ? FileImage(_imageFile!)
                                : widget.currentImage != null
                                    ? FileImage(widget.currentImage!)
                                    : AssetImage('assets/images/chef-image.jpg'),
                            child: Align(
                              alignment: Alignment.bottomRight,
                              child: CircleAvatar(
                                backgroundColor: Colors.white,
                                radius: 14,
                                child: Icon(Icons.edit, size: 18, color: Color(0xFFF45F67)),
                              ),
                            ),
                          ),
                        ),
                        SizedBox(height: 20),
                        TextField(
                          controller: usernameController,
                          decoration: InputDecoration(
                            labelText: 'Username',
                            labelStyle: TextStyle(color: Color(0xFFF45F67)),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(15),
                              borderSide: BorderSide(color: Color(0xFFF45F67)),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(15),
                              borderSide: BorderSide(color: Colors.grey),
                            ),
                            prefixIcon: Icon(Icons.person_outline, color: Color(0xFFF45F67)),
                          ),
                        ),
                        SizedBox(height: 20),
                        TextField(
                          controller: bioController,
                          maxLines: 6,
                          maxLength: 100,
                          decoration: InputDecoration(
                            labelText: 'Bio',
                            labelStyle: TextStyle(color: Color(0xFFF45F67)),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(15),
                              borderSide: BorderSide(color: Color(0xFFF45F67)),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(15),
                              borderSide: BorderSide(color: Colors.grey),
                            ),
                            prefixIcon: Icon(Icons.info_outline, color: Color(0xFFF45F67)),
                            counterText: '',
                          ),
                        ),
                        SizedBox(height: 30),
                        isUploading
                            ? CircularProgressIndicator()
                            : SizedBox(
                                width: screenWidth * 0.7,
                                child: ElevatedButton.icon(
                                  icon: Icon(Icons.check, color: Colors.white),
                                  label: Text('Save', style: TextStyle(color: Colors.white, fontSize: 16)),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Color(0xFFF45F67),
                                    padding: EdgeInsets.symmetric(vertical: 15),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(50),
                                    ),
                                  ),
                                  onPressed: _saveChanges,
                                ),
                              ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showImageSourceActionSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return SafeArea(
          child: Wrap(
            children: <Widget>[
              ListTile(
                leading: Icon(Icons.photo_library),
                title: Text('Choose from Gallery'),
                onTap: () {
                  Navigator.pop(context);
                  _pickImage(ImageSource.gallery);
                },
              ),
              ListTile(
                leading: Icon(Icons.camera_alt),
                title: Text('Take a Photo'),
                onTap: () {
                  Navigator.pop(context);
                  _pickImage(ImageSource.camera);
                },
              ),
              ListTile(
                leading: Icon(Icons.close),
                title: Text('Cancel'),
                onTap: () {
                  Navigator.pop(context);
                },
              ),
            ],
          ),
        );
      },
    );
  }
}