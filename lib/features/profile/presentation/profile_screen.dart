import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:notetaking_app/core/theme/app_colors.dart';
import 'package:notetaking_app/features/offlinesupport/image_db.dart';
import 'package:notetaking_app/features/setting/presentation/settings.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  File? _avatarFile;

  @override
  void initState() {
    super.initState();
    _loadAvatar();
  }

  // Load saved image from DB
  Future<void> _loadAvatar() async {
    final path = await ProfileDB.instance.getImagePath();
    if (path != null && mounted) {
      setState(() {
        _avatarFile = File(path);
      });
    }
  }

  // Pick new image and save to DB
  Future<void> _pickImage() async {
    try {
      final picker = ImagePicker();
      final picked = await picker.pickImage(source: ImageSource.gallery);
      if (picked != null) {
        final file = File(picked.path);
        setState(() => _avatarFile = file);
        await ProfileDB.instance.saveImagePath(file.path);
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to pick image: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(56),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.arrow_back),
                  onPressed: () => Navigator.of(context).maybePop(),
                ),
                const Spacer(),
                const Text(
                  'Profile',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
                ),
                const Spacer(),
                const SizedBox(width: 48),
              ],
            ),
          ),
        ),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          children: [
            const SizedBox(height: 8),
            // Avatar with image picker
            Center(
              child: GestureDetector(
                onTap: _pickImage,
                child: CircleAvatar(
                  radius: 64,
                  backgroundColor: scheme.primary.withOpacity(0.15),
                  child: CircleAvatar(
                    radius: 60,
                    backgroundColor: scheme.surface,
                    backgroundImage: _avatarFile != null
                        ? FileImage(_avatarFile!)
                        : null,
                    child: _avatarFile == null
                        ? Icon(Icons.person, size: 56, color: scheme.primary)
                        : null,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            // Name
            const Center(
              child: Text(
                'Sophia Carter',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
              ),
            ),
            const SizedBox(height: 6),
            // Email
            Center(
              child: Text(
                'sophia.carter@email.com',
                style: TextStyle(
                  fontSize: 14,
                  color: AppColors.textcolor,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const SizedBox(height: 24),
            // Section header
            const Text(
              'Account',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 8),
            // Rows
            _ProfileRow(
              title: 'Edit Profile',
              onTap: () {
                // Navigate to edit profile
              },
            ),
            _ProfileRow(
              title: 'Settings',
              onTap: () {
                // Navigate to settingsnaviga
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (_) => const SettingsScreen()),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _ProfileRow extends StatelessWidget {
  final String title;
  final VoidCallback? onTap;

  const _ProfileRow({required this.title, this.onTap});

  @override
  Widget build(BuildContext context) {
    final textStyle = Theme.of(
      context,
    ).textTheme.bodyLarge?.copyWith(fontSize: 16, fontWeight: FontWeight.w600);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        splashColor: Colors.transparent,
        highlightColor: Colors.transparent,
        hoverColor: Colors.transparent,
        focusColor: Colors.transparent,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 18),
          child: Row(
            children: [
              Expanded(child: Text(title, style: textStyle)),
              const Icon(Icons.arrow_forward, size: 22),
            ],
          ),
        ),
      ),
    );
  }
}
