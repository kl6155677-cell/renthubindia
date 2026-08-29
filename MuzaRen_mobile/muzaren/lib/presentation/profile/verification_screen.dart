import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../../core/theme/app_colors.dart';
import '../../data/services/api_service.dart';
import '../../core/constants/api_constants.dart';

class VerificationScreen extends StatefulWidget {
  const VerificationScreen({super.key});

  @override
  State<VerificationScreen> createState() => _VerificationScreenState();
}

class _VerificationScreenState extends State<VerificationScreen> {
  String _status = 'UNVERIFIED'; // UNVERIFIED, PENDING, VERIFIED
  String? _selectedDocType;
  File? _documentImage;
  bool _isSubmitting = false;

  final _docTypes = ['National ID', 'Passport', 'Driver\'s License'];

  @override
  void initState() {
    super.initState();
    _loadStatus();
  }

  Future<void> _loadStatus() async {
    try {
      final response = await ApiService.dio.get(ApiConstants.userProfile);
      final status = response.data['data']?['verificationStatus'] ?? 'UNVERIFIED';
      if (mounted) setState(() => _status = status);
    } catch (_) {}
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery, maxWidth: 1200, imageQuality: 85);
    if (picked != null && mounted) {
      final file = File(picked.path);
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
      setState(() => _documentImage = File(picked.path));
    }
  }

  Future<void> _submit() async {
    if (_documentImage == null || _selectedDocType == null) return;
    setState(() => _isSubmitting = true);
    try {
      final formData = FormData.fromMap({
        'document': await MultipartFile.fromFile(_documentImage!.path, filename: 'document.jpg'),
        'documentType': _selectedDocType,
      });
      await ApiService.dio.post(ApiConstants.verifyIdentity, data: formData);
      if (mounted) {
        setState(() => _status = 'PENDING');
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Document submitted for review!'), backgroundColor: AppColors.success, behavior: SnackBarBehavior.floating),
        );
      }
    } on DioException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.response?.data?['message'] ?? 'Upload failed'), backgroundColor: AppColors.error, behavior: SnackBarBehavior.floating),
        );
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: AppColors.textPrimary,
        elevation: 0.5,
        title: const Text('Identity Verification', style: TextStyle(fontFamily: 'Sora', fontSize: 18, fontWeight: FontWeight.w700)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: _status == 'VERIFIED' ? _buildVerified() : _status == 'PENDING' ? _buildPending() : _buildForm(),
      ),
    );
  }

  // ── VERIFIED STATE ──
  Widget _buildVerified() {
    return Center(
      child: Column(
        children: [
          const SizedBox(height: 60),
          Container(
            width: 100, height: 100,
            decoration: BoxDecoration(color: AppColors.success.withValues(alpha: 0.1), shape: BoxShape.circle),
            child: const Icon(Icons.verified, size: 56, color: AppColors.success),
          ),
          const SizedBox(height: 24),
          const Text('You\'re Verified!', style: TextStyle(fontFamily: 'Sora', fontSize: 22, fontWeight: FontWeight.w700, color: Color(0xFF111827))),
          const SizedBox(height: 8),
          const Text('Your identity has been verified.\nYou can now access all features.', textAlign: TextAlign.center, style: TextStyle(fontFamily: 'PlusJakartaSans', fontSize: 14, color: Color(0xFF6B7280), height: 1.5)),
          const SizedBox(height: 32),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            decoration: BoxDecoration(color: AppColors.success.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(20)),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.verified, size: 18, color: AppColors.success),
                SizedBox(width: 8),
                Text('Verified Badge Active', style: TextStyle(fontFamily: 'Sora', fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.success)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── PENDING STATE ──
  Widget _buildPending() {
    return Center(
      child: Column(
        children: [
          const SizedBox(height: 60),
          Container(
            width: 100, height: 100,
            decoration: BoxDecoration(color: AppColors.accent.withValues(alpha: 0.1), shape: BoxShape.circle),
            child: const Icon(Icons.hourglass_bottom, size: 56, color: AppColors.accent),
          ),
          const SizedBox(height: 24),
          const Text('Under Review', style: TextStyle(fontFamily: 'Sora', fontSize: 22, fontWeight: FontWeight.w700, color: Color(0xFF111827))),
          const SizedBox(height: 8),
          const Text('Your document is being reviewed.\nThis usually takes 1-2 business days.', textAlign: TextAlign.center, style: TextStyle(fontFamily: 'PlusJakartaSans', fontSize: 14, color: Color(0xFF6B7280), height: 1.5)),
          const SizedBox(height: 32),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
            child: const Row(
              children: [
                Icon(Icons.info_outline, size: 20, color: AppColors.accent),
                SizedBox(width: 12),
                Expanded(
                  child: Text('We\'ll notify you once verification is complete.', style: TextStyle(fontFamily: 'PlusJakartaSans', fontSize: 13, color: Color(0xFF6B7280))),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── UPLOAD FORM ──
  Widget _buildForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Why verify
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: LinearGradient(colors: [AppColors.primary.withValues(alpha: 0.08), AppColors.primary.withValues(alpha: 0.02)]),
            borderRadius: BorderRadius.circular(14),
          ),
          child: const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.shield_outlined, size: 22, color: AppColors.primary),
                  SizedBox(width: 8),
                  Text('Why verify?', style: TextStyle(fontFamily: 'Sora', fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.primary)),
                ],
              ),
              SizedBox(height: 10),
              _BulletItem('Build trust with other users'),
              _BulletItem('List higher-value items'),
              _BulletItem('Get a verified badge on your profile'),
              _BulletItem('Priority support from our team'),
            ],
          ),
        ),
        const SizedBox(height: 24),
        // Document type selector
        const Text('Document Type', style: TextStyle(fontFamily: 'Sora', fontSize: 14, fontWeight: FontWeight.w600, color: Color(0xFF111827))),
        const SizedBox(height: 10),
        Wrap(
          spacing: 10,
          children: _docTypes.map((type) {
            final isSelected = _selectedDocType == type;
            return GestureDetector(
              onTap: () => setState(() => _selectedDocType = type),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                decoration: BoxDecoration(
                  color: isSelected ? AppColors.primary : Colors.white,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: isSelected ? AppColors.primary : const Color(0xFFE5E7EB)),
                ),
                child: Text(type, style: TextStyle(fontFamily: 'Sora', fontSize: 13, fontWeight: FontWeight.w500, color: isSelected ? Colors.white : const Color(0xFF374151))),
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: 24),
        // Image picker
        const Text('Upload Document', style: TextStyle(fontFamily: 'Sora', fontSize: 14, fontWeight: FontWeight.w600, color: Color(0xFF111827))),
        const SizedBox(height: 10),
        GestureDetector(
          onTap: _pickImage,
          child: Container(
            width: double.infinity,
            height: 180,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFFE5E7EB), style: _documentImage == null ? BorderStyle.solid : BorderStyle.none),
            ),
            child: _documentImage != null
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(14),
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        Image.file(_documentImage!, fit: BoxFit.cover),
                        Positioned(
                          top: 8, right: 8,
                          child: GestureDetector(
                            onTap: () => setState(() => _documentImage = null),
                            child: Container(
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(color: Colors.black.withValues(alpha: 0.5), shape: BoxShape.circle),
                              child: const Icon(Icons.close, size: 16, color: Colors.white),
                            ),
                          ),
                        ),
                      ],
                    ),
                  )
                : Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.cloud_upload_outlined, size: 40, color: Colors.grey.shade400),
                      const SizedBox(height: 10),
                      const Text('Tap to upload your document', style: TextStyle(fontFamily: 'PlusJakartaSans', fontSize: 14, color: Color(0xFF9CA3AF))),
                      const SizedBox(height: 4),
                      const Text('JPG, PNG up to 8MB', style: TextStyle(fontFamily: 'PlusJakartaSans', fontSize: 12, color: Color(0xFFD1D5DB))),
                    ],
                  ),
          ),
        ),
        const SizedBox(height: 30),
        // Submit
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: (_selectedDocType != null && _documentImage != null && !_isSubmitting) ? _submit : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              disabledBackgroundColor: const Color(0xFFE5E7EB),
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              textStyle: const TextStyle(fontFamily: 'Sora', fontSize: 16, fontWeight: FontWeight.w600),
            ),
            child: _isSubmitting
                ? const SizedBox(height: 22, width: 22, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                : const Text('Submit for Verification'),
          ),
        ),
      ],
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

class _BulletItem extends StatelessWidget {
  final String text;
  const _BulletItem(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          Container(width: 6, height: 6, decoration: const BoxDecoration(color: AppColors.primary, shape: BoxShape.circle)),
          const SizedBox(width: 10),
          Text(text, style: const TextStyle(fontFamily: 'PlusJakartaSans', fontSize: 13, color: Color(0xFF374151))),
        ],
      ),
    );
  }
}
