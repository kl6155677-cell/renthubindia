import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../blocs/auth/auth_bloc.dart';
import '../../blocs/auth/auth_event.dart';
import '../../blocs/auth/auth_state.dart';
import '../../core/theme/app_colors.dart';
import '../../data/models/user_model.dart';
import '../widgets/muza_snackbar.dart';
import '../../core/constants/location_data.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _phoneController;
  late TextEditingController _cityController;
  late TextEditingController _countryController;
  String? _selectedImagePath;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    final authState = context.read<AuthBloc>().state;
    if (authState is AuthAuthenticated) {
      final user = authState.user;
      _nameController = TextEditingController(text: user.name);
      _phoneController = TextEditingController(text: user.phone ?? '');
      _cityController = TextEditingController(text: user.city ?? '');
      _countryController = TextEditingController(text: user.country ?? '');
    } else {
      _nameController = TextEditingController();
      _phoneController = TextEditingController();
      _cityController = TextEditingController();
      _countryController = TextEditingController();
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _cityController.dispose();
    _countryController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final image = await picker.pickImage(source: ImageSource.gallery, imageQuality: 70);
    if (image != null) {
      final file = File(image.path);
      final sizeInBytes = await file.length();
      const maxSizeInBytes = 8 * 1024 * 1024; // 8MB

      if (sizeInBytes > maxSizeInBytes) {
        if (mounted) {
          final fileSizeMB = (sizeInBytes / (1024 * 1024)).toStringAsFixed(1);
          showDialog(
            context: context,
            builder: (ctx) => AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              title: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.error.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.photo_size_select_large, color: AppColors.error, size: 22),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Text('Image Too Large',
                        style: TextStyle(fontFamily: 'Sora', fontSize: 17, fontWeight: FontWeight.w700)),
                  ),
                ],
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Your image is $fileSizeMB MB but the maximum allowed size is 8 MB.',
                      style: const TextStyle(fontFamily: 'PlusJakartaSans', fontSize: 14, color: Color(0xFF6B7280), height: 1.5)),
                  const SizedBox(height: 14),
                  const Text('Tips:', style: TextStyle(fontFamily: 'Sora', fontSize: 13, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 6),
                  _buildTipRow(Icons.crop, 'Crop or resize your photo'),
                  _buildTipRow(Icons.photo_library_outlined, 'Pick a different photo'),
                ],
              ),
              actions: [
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(ctx),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    child: const Text("Got it, I'll pick another",
                        style: TextStyle(fontFamily: 'Sora', fontSize: 14, fontWeight: FontWeight.w600)),
                  ),
                ),
              ],
            ),
          );
        }
        return;
      }
      setState(() => _selectedImagePath = image.path);
    }
  }

  void _onSave() {
    if (_formKey.currentState!.validate()) {
      context.read<AuthBloc>().add(UpdateProfileRequested(
            name: _nameController.text.trim(),
            phone: _phoneController.text.trim().isEmpty ? null : _phoneController.text.trim(),
            city: _cityController.text.trim().isEmpty ? null : _cityController.text.trim(),
            country: _countryController.text.trim().isEmpty ? null : _countryController.text.trim(),
            avatarPath: _selectedImagePath,
          ));
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<AuthBloc, AuthState>(
      listener: (context, state) {
        if (state is AuthAuthenticated && _isSaving) {
          setState(() => _isSaving = false);
          MuzaSnackbar.show(
            context,
            message: 'Profile updated successfully!',
            type: MuzaSnackbarType.success,
          );
          Navigator.pop(context);
        } else if (state is AuthError && _isSaving) {
          setState(() => _isSaving = false);
        } else if (state is AuthLoading) {
          setState(() => _isSaving = true);
        }
      },
      builder: (context, state) {
        final user = state is AuthAuthenticated ? state.user : null;
        if (user == null) return const Scaffold(body: Center(child: CircularProgressIndicator()));

        return Scaffold(
          backgroundColor: const Color(0xFFF9FAFB),
          appBar: AppBar(
            backgroundColor: Colors.white,
            elevation: 0,
            centerTitle: true,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back, color: Color(0xFF374151)),
              onPressed: () => Navigator.pop(context),
            ),
            title: const Text(
              'Edit Profile',
              style: TextStyle(fontFamily: 'Sora', fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.primary),
            ),
          ),
          body: Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        _buildAvatarSection(user),
                        const SizedBox(height: 32),
                        _buildTextField(
                          label: 'Full Name',
                          controller: _nameController,
                          hint: 'Julian Casablancas',
                          icon: Icons.person_outline_rounded,
                          validator: (v) => v!.isEmpty ? 'Name is required' : null,
                        ),
                        const SizedBox(height: 20),
                        _buildTextField(
                          label: 'Phone Number',
                          controller: _phoneController,
                          hint: '+1 (555) 0123 4567',
                          icon: Icons.phone_outlined,
                          keyboardType: TextInputType.phone,
                        ),
                        const SizedBox(height: 20),
                        _buildCountryDropdown(),
                        const SizedBox(height: 20),
                        _buildCityDropdown(),
                        const SizedBox(height: 24),
                        _buildPrivacyNote(),
                        const SizedBox(height: 32),
                      ],
                    ),
                  ),
                ),
              ),
              _buildBottomAction(),
            ],
          ),
        );
      },
    );
  }

  Widget _buildAvatarSection(UserModel user) {
    return Column(
      children: [
        Stack(
          children: [
            Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 4),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.08),
                    blurRadius: 24,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: CircleAvatar(
                radius: 64,
                backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                backgroundImage: _selectedImagePath != null
                    ? FileImage(File(_selectedImagePath!))
                    : (user.avatarUrl != null ? CachedNetworkImageProvider(user.avatarUrl!) : null) as ImageProvider?,
                child: _selectedImagePath == null && user.avatarUrl == null
                    ? Text(
                        user.name.isNotEmpty ? user.name[0].toUpperCase() : '?',
                        style: const TextStyle(fontFamily: 'Sora', fontSize: 36, fontWeight: FontWeight.bold, color: AppColors.primary),
                      )
                    : null,
              ),
            ),
            Positioned(
              bottom: 4,
              right: 4,
              child: GestureDetector(
                onTap: _pickImage,
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 2),
                  ),
                  child: const Icon(Icons.camera_alt_rounded, color: Colors.white, size: 18),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        const Text(
          'Tap to change photo',
          style: TextStyle(fontFamily: 'PlusJakartaSans', fontSize: 14, color: Color(0xFF4B5563), fontWeight: FontWeight.w500),
        ),
      ],
    );
  }

  Widget _buildCountryDropdown() {
    final countries = LocationData.countriesAndCities.keys.toList();
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.only(left: 4, bottom: 8),
          child: Text('Country', style: TextStyle(fontFamily: 'Sora', fontSize: 14, fontWeight: FontWeight.w600, color: Color(0xFF374151))),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 10, offset: Offset(0, 4))],
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButtonFormField<String>(
              initialValue: countries.contains(_countryController.text) && _countryController.text.isNotEmpty 
                  ? _countryController.text 
                  : null,
              hint: const Text('Select Country', style: TextStyle(fontFamily: 'PlusJakartaSans', color: Color(0xFF9CA3AF), fontSize: 15, fontWeight: FontWeight.w400)),
              icon: const Icon(Icons.expand_more_rounded, color: Color(0xFF374151)),
              style: const TextStyle(fontFamily: 'PlusJakartaSans', fontSize: 15, color: Color(0xFF111827), fontWeight: FontWeight.w600),
              decoration: const InputDecoration(
                prefixIcon: Icon(Icons.public_rounded, size: 20, color: Color(0xFF374151)),
                border: InputBorder.none,
              ),
              items: countries.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
              onChanged: (val) {
                if (val != null) {
                  setState(() {
                    _countryController.text = val;
                    _cityController.text = ''; // Reset city when country changes
                  });
                }
              },
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCityDropdown() {
    final cities = LocationData.countriesAndCities[_countryController.text] ?? [];
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.only(left: 4, bottom: 8),
          child: Text('City', style: TextStyle(fontFamily: 'Sora', fontSize: 14, fontWeight: FontWeight.w600, color: Color(0xFF374151))),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 10, offset: Offset(0, 4))],
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButtonFormField<String>(
              initialValue: cities.contains(_cityController.text) && _cityController.text.isNotEmpty 
                  ? _cityController.text 
                  : null,
              hint: const Text('Select City', style: TextStyle(fontFamily: 'PlusJakartaSans', color: Color(0xFF9CA3AF), fontSize: 15, fontWeight: FontWeight.w400)),
              icon: const Icon(Icons.expand_more_rounded, color: Color(0xFF374151)),
              style: const TextStyle(fontFamily: 'PlusJakartaSans', fontSize: 15, color: Color(0xFF111827), fontWeight: FontWeight.w600),
              decoration: const InputDecoration(
                prefixIcon: Icon(Icons.apartment_rounded, size: 20, color: Color(0xFF374151)),
                border: InputBorder.none,
              ),
              items: cities.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
              onChanged: cities.isEmpty ? null : (val) {
                if (val != null) setState(() => _cityController.text = val);
              },
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTextField({
    required String label,
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
    String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 8),
          child: Text(
            label,
            style: const TextStyle(fontFamily: 'Sora', fontSize: 14, fontWeight: FontWeight.w600, color: Color(0xFF374151)),
          ),
        ),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.02),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: TextFormField(
            controller: controller,
            keyboardType: keyboardType,
            validator: validator,
            style: const TextStyle(fontFamily: 'PlusJakartaSans', fontSize: 15, color: Color(0xFF111827), fontWeight: FontWeight.w600),
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: const TextStyle(color: Color(0xFF9CA3AF), fontWeight: FontWeight.w400),
              prefixIcon: Icon(icon, size: 20, color: const Color(0xFF374151)),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            ),
          ),
        ),
      ],
    );
  }


  Widget _buildPrivacyNote() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFFF3F4F6).withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.shield_outlined, size: 22, color: AppColors.primary),
          const SizedBox(width: 16),
          const Expanded(
            child: Text(
              'Your personal information is kept secure and only visible to hosts during confirmed bookings. We never share your contact details publicly.',
              style: TextStyle(
                fontFamily: 'PlusJakartaSans',
                fontSize: 12,
                color: Color(0xFF6B7280),
                height: 1.6,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomAction() {
    return Container(
      padding: EdgeInsets.fromLTRB(24, 16, 24, MediaQuery.of(context).padding.bottom + 16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SizedBox(
        width: double.infinity,
        height: 56,
        child: ElevatedButton(
          onPressed: _isSaving ? null : _onSave,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            elevation: 0,
          ),
          child: _isSaving
              ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
              : const Text(
                  'Save Changes',
                  style: TextStyle(fontFamily: 'Sora', fontSize: 16, fontWeight: FontWeight.w700),
                ),
        ),
      ),
    );
  }

  Widget _buildTipRow(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        children: [
          Icon(icon, size: 16, color: const Color(0xFF9CA3AF)),
          const SizedBox(width: 8),
          Expanded(
            child: Text(text, style: const TextStyle(fontFamily: 'PlusJakartaSans', fontSize: 13, color: Color(0xFF4B5563))),
          ),
        ],
      ),
    );
  }
}
