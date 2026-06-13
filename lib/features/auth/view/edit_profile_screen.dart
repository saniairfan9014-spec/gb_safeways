import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../controller/auth_controller.dart';
import '../model/user_model.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController nameController;
  late TextEditingController phoneController;
  late TextEditingController bioController;

  File? selectedImage;
  bool isLoading = false;
  UserModel? _initialUser;

  @override
  void initState() {
    super.initState();
    nameController = TextEditingController();
    phoneController = TextEditingController();
    bioController = TextEditingController();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    if (_initialUser == null) {
      final authController = context.read<AuthController>();
      _initialUser = authController.currentUser;

      if (_initialUser != null) {
        nameController.text = _initialUser!.fullName;
        phoneController.text = _initialUser!.phoneNumber;
        bioController.text = _initialUser!.bio ?? '';
      }
    }
  }

  @override
  void dispose() {
    nameController.dispose();
    phoneController.dispose();
    bioController.dispose();
    super.dispose();
  }

  Future<void> pickImage() async {
    final picker = ImagePicker();
    final image = await picker.pickImage(source: ImageSource.gallery);

    if (image != null) {
      setState(() {
        selectedImage = File(image.path);
      });
    }
  }

  Future<void> updateProfile() async {
    if (!_formKey.currentState!.validate()) return;

    final authController = context.read<AuthController>();
    final user = authController.currentUser;

    if (user == null) return;

    setState(() => isLoading = true);

    try {
      final success = await authController.editProfile(
        fullName: nameController.text.trim(),
        phoneNumber: phoneController.text.trim(),
        bio: bioController.text.trim(),
        newAvatarFile: selectedImage,
      );

      if (mounted && success) {
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Failed to update profile")),
        );
      }
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final authController = context.watch<AuthController>();
    final user = authController.currentUser;

    if (user == null) {
      return Scaffold(
        appBar: AppBar(title: const Text("Edit Profile")),
        body: const Center(
          child: Text("User session not found. Please log in again."),
        ),
      );
    }

    final avatarUrl = user.avatarUrl;

    return Scaffold(
      appBar: AppBar(
        title: const Text("Edit Profile"),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              const SizedBox(height: 20),

              // ================= AVATAR =================
              Material(
                color: Colors.transparent,
                child: InkWell(
                  borderRadius: BorderRadius.circular(60),
                  onTap: pickImage,
                  child: Stack(
                    children: [
                      CircleAvatar(
                        radius: 55,
                        backgroundImage: selectedImage != null
                            ? FileImage(selectedImage!)
                            : (avatarUrl.isNotEmpty
                            ? NetworkImage(
                          "$avatarUrl?v=${DateTime.now().millisecondsSinceEpoch}",
                        )
                            : null) as ImageProvider?,
                        child: (selectedImage == null && avatarUrl.isEmpty)
                            ? const Icon(Icons.person, size: 50)
                            : null,
                      ),

                      Positioned(
                        bottom: 0,
                        right: 0,
                        child: Container(
                          padding: const EdgeInsets.all(6),
                          decoration: const BoxDecoration(
                            color: Colors.blue,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.camera_alt,
                            size: 18,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 30),

              // ================= NAME =================
              TextFormField(
                controller: nameController,
                decoration: const InputDecoration(
                  labelText: "Full Name",
                  border: OutlineInputBorder(),
                ),
                validator: (v) =>
                (v == null || v.isEmpty) ? "Name cannot be empty" : null,
              ),

              const SizedBox(height: 15),

              // ================= PHONE =================
              TextFormField(
                controller: phoneController,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(
                  labelText: "Phone",
                  border: OutlineInputBorder(),
                ),
                validator: (v) =>
                (v == null || v.isEmpty) ? "Phone cannot be empty" : null,
              ),

              const SizedBox(height: 15),

              // ================= BIO =================
              TextFormField(
                controller: bioController,
                maxLines: 4,
                maxLength: 250,
                decoration: const InputDecoration(
                  labelText: "Bio",
                  border: OutlineInputBorder(),
                ),
              ),




              const SizedBox(height: 25),

              // ================= BUTTON =================
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: isLoading ? null : updateProfile,
                  child: isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text("Update Profile"),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}