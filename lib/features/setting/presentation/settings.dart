import 'package:flutter/material.dart';
import 'package:notetaking_app/core/theme/app_colors.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:notetaking_app/features/auth/presentation/login_screen.dart'; // import your login screen

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({Key? key}) : super(key: key);

  Future<void> _logout(BuildContext context) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('auth_token');

    Navigator.of(
      context,
    ).pushReplacement(MaterialPageRoute(builder: (_) => const LoginScreen()));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final textTheme = theme.textTheme;

    // Determine current theme dynamically
    final isDarkMode = theme.brightness == Brightness.dark;
    final currentThemeText = isDarkMode ? 'Dark' : 'Light';

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: theme.scaffoldBackgroundColor,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: scheme.onSurface),
          onPressed: () => Navigator.of(context).pop(),
        ),
        centerTitle: true,
        title: Text(
          'Settings',
          style: textTheme.titleLarge?.copyWith(
            color: scheme.onSurface,
            fontWeight: FontWeight.w700,
            fontSize: 20,
          ),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 16),

            // Appearance Section
            Text(
              'Appearance',
              style: textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
                fontSize: 18,
                color: scheme.onSurface,
              ),
            ),
            const SizedBox(height: 12),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Theme',
                      style: textTheme.bodyLarge?.copyWith(
                        fontSize: 16,
                        color: scheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'System',
                      style: textTheme.bodySmall?.copyWith(
                        fontSize: 13,
                        color: AppColors.textcolor,
                      ),
                    ),
                  ],
                ),
                Text(
                  currentThemeText,
                  style: textTheme.bodyMedium?.copyWith(
                    fontSize: 16,
                    color: scheme.onSurface,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 32),

            Text(
              'Account',
              style: textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
                fontSize: 18,
                color: scheme.onSurface,
              ),
            ),
            const SizedBox(height: 12),

            InkWell(
              onTap: () => _logout(context),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Log Out',
                    style: textTheme.bodyMedium?.copyWith(
                      fontSize: 14,
                      color: scheme.onSurface,
                    ),
                  ),
                  Icon(Icons.arrow_forward, size: 25, color: scheme.onSurface),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
