import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:classlly/main.dart'; // For ThemeProvider
import 'package:classlly/core/theme/app_theme.dart';
import 'package:classlly/features/library/widgets/dashboard_sidebar.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: Row(
        children: [
          // Sidebar (Full)
          const DashboardSidebar(),

          // Main Content
          Expanded(
            child: Column(
              children: [
                _buildHeader(context, isDark),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 60,
                      vertical: 40,
                    ),
                    child: Center(
                      child: Container(
                        constraints: const BoxConstraints(maxWidth: 800),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildSectionHeader(
                              'Appearance',
                              'Customize how Classlly looks and feels on your device.',
                              isDark,
                            ),
                            const SizedBox(height: 24),
                            _buildGlassPanel(
                              isDark: isDark,
                              child: Column(
                                children: [
                                  _buildThemeRow(context, isDark),
                                  Divider(
                                    height: 1,
                                    color: isDark
                                        ? Colors.white10
                                        : Colors.black.withValues(alpha: 0.05),
                                  ),
                                  _buildAccentColorRow(context, isDark),
                                ],
                              ),
                            ),
                            const SizedBox(height: 48),
                            _buildSectionHeader(
                              'Sync & Cloud',
                              'Keep your notes synchronized across all your academic devices.',
                              isDark,
                            ),
                            const SizedBox(height: 24),
                            Row(
                              children: [
                                Expanded(
                                  child: _buildCloudCard(
                                    'Google Drive',
                                    'Connected 2m ago',
                                    true,
                                    isDark,
                                  ),
                                ),
                                const SizedBox(width: 20),
                                Expanded(
                                  child: _buildCloudCard(
                                    'iCloud Workspace',
                                    'Disconnected',
                                    false,
                                    isDark,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 48),
                            _buildSectionHeader(
                              'Accessibility',
                              'Make Classlly more comfortable for your specific needs.',
                              isDark,
                            ),
                            const SizedBox(height: 24),
                            _buildGlassPanel(
                              isDark: isDark,
                              child: Column(
                                children: [
                                  _buildFontSizeSlider(isDark),
                                  Divider(
                                    height: 1,
                                    color: isDark
                                        ? Colors.white10
                                        : Colors.black.withValues(alpha: 0.05),
                                  ),
                                  _buildToggleRow(
                                    'High Contrast Mode',
                                    'Increases contrast for better readability.',
                                    false,
                                    isDark,
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 100),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context, bool isDark) {
    final textColor = isDark ? Colors.white : Colors.black;
    final subColor = isDark ? Colors.grey : Colors.grey[800];

    return Container(
      height: 64,
      padding: const EdgeInsets.symmetric(horizontal: 32),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: isDark
                ? Colors.white.withValues(alpha: 0.05)
                : Colors.black.withValues(alpha: 0.05),
          ),
        ),
      ),
      child: Row(
        children: [
          Text(
            'Settings',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: textColor,
            ),
          ),
          const VerticalDivider(width: 32, indent: 24, endIndent: 24),
          Text('Workspace', style: TextStyle(fontSize: 12, color: subColor)),
          Icon(Icons.chevron_right, size: 14, color: subColor),
          Text(
            'Appearance',
            style: TextStyle(
              fontSize: 12,
              color: isDark ? Colors.white70 : Colors.black87,
              fontWeight: FontWeight.bold,
            ),
          ),
          const Spacer(),
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon: Icon(Icons.close, color: subColor),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title, String subtitle, bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: isDark ? Colors.white : Colors.black,
          ),
        ),
        Text(
          subtitle,
          style: TextStyle(
            fontSize: 14,
            color: isDark ? Colors.grey : Colors.grey[700],
          ),
        ),
      ],
    );
  }

  Widget _buildGlassPanel({required Widget child, required bool isDark}) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withValues(alpha: 0.03) : Colors.white,
        border: Border.all(
          color: isDark
              ? Colors.white.withValues(alpha: 0.05)
              : Colors.black.withValues(alpha: 0.05),
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: isDark
            ? []
            : [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.02),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
      ),
      child: child,
    );
  }

  Widget _buildThemeRow(BuildContext context, bool isDark) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Row(
        children: [
          _iconBox(Icons.dark_mode, isDark),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Interface Theme',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                    color: isDark ? Colors.white : Colors.black,
                  ),
                ),
                Text(
                  'Choose between light, dark, or system default.',
                  style: TextStyle(
                    fontSize: 12,
                    color: isDark ? Colors.grey : Colors.grey[700],
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: isDark
                  ? Colors.white.withValues(alpha: 0.05)
                  : Colors.black.withValues(alpha: 0.03),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                GestureDetector(
                  onTap: () => themeProvider.setThemeMode(ThemeMode.light),
                  child: _themeBtn(
                    'Light',
                    themeProvider.themeMode == ThemeMode.light,
                    isDark,
                  ),
                ),
                GestureDetector(
                  onTap: () => themeProvider.setThemeMode(ThemeMode.dark),
                  child: _themeBtn(
                    'Dark',
                    themeProvider.themeMode == ThemeMode.dark,
                    isDark,
                  ),
                ),
                GestureDetector(
                  onTap: () => themeProvider.setThemeMode(ThemeMode.system),
                  child: _themeBtn(
                    'System',
                    themeProvider.themeMode == ThemeMode.system,
                    isDark,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _themeBtn(String label, bool active, bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: active ? AppTheme.primaryPurple : Colors.transparent,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: active
              ? Colors.white
              : (isDark ? Colors.grey : Colors.grey[600]),
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildAccentColorRow(BuildContext context, bool isDark) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Accent Color',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 15,
              color: isDark ? Colors.white : Colors.black,
            ),
          ),
          Text(
            'Select the glowing accent used for buttons and highlights.',
            style: TextStyle(
              fontSize: 12,
              color: isDark ? Colors.grey : Colors.grey[700],
            ),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              _colorDot(
                AppTheme.primaryPurple,
                themeProvider.accentColor == AppTheme.primaryPurple,
                isDark,
                () => themeProvider.setAccentColor(AppTheme.primaryPurple),
              ),
              _colorDot(
                Colors.blue,
                themeProvider.accentColor == Colors.blue,
                isDark,
                () => themeProvider.setAccentColor(Colors.blue),
              ),
              _colorDot(
                Colors.teal,
                themeProvider.accentColor == Colors.teal,
                isDark,
                () => themeProvider.setAccentColor(Colors.teal),
              ),
              _colorDot(
                Colors.orange,
                themeProvider.accentColor == Colors.orange,
                isDark,
                () => themeProvider.setAccentColor(Colors.orange),
              ),
              _colorDot(
                Colors.pink,
                themeProvider.accentColor == Colors.pink,
                isDark,
                () => themeProvider.setAccentColor(Colors.pink),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _colorDot(Color color, bool active, bool isDark, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(right: 16),
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
          border: active
              ? Border.all(
                  color: isDark ? Colors.white : Colors.black,
                  width: 2,
                )
              : null,
          boxShadow: active
              ? [BoxShadow(color: color.withValues(alpha: 0.4), blurRadius: 10)]
              : null,
        ),
        child: active
            ? const Icon(Icons.check, size: 16, color: Colors.white)
            : null,
      ),
    );
  }

  Widget _buildCloudCard(
    String title,
    String status,
    bool connected,
    bool isDark,
  ) {
    return _buildGlassPanel(
      isDark: isDark,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _iconBox(Icons.cloud, isDark, size: 40),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: connected
                        ? Colors.green.withValues(alpha: 0.1)
                        : (isDark
                              ? Colors.white10
                              : Colors.black.withValues(alpha: 0.05)),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    connected ? 'CONNECTED' : 'DISCONNECTED',
                    style: TextStyle(
                      color: connected
                          ? Colors.green
                          : (isDark ? Colors.grey : Colors.grey[600]),
                      fontSize: 8,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            Text(
              title,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 15,
                color: isDark ? Colors.white : Colors.black,
              ),
            ),
            Text(
              status,
              style: TextStyle(
                fontSize: 12,
                color: isDark ? Colors.grey : Colors.grey[700],
              ),
            ),
            const SizedBox(height: 20),
            TextButton(
              onPressed: () {},
              child: Text(
                connected ? 'Disconnect' : 'Connect Account',
                style: TextStyle(
                  color: connected ? Colors.green : AppTheme.primaryPurple,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFontSizeSlider(bool isDark) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Base Font Size',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                      color: isDark ? Colors.white : Colors.black,
                    ),
                  ),
                  Text(
                    'Scale the size of the note editor text.',
                    style: TextStyle(
                      fontSize: 12,
                      color: isDark ? Colors.grey : Colors.grey[700],
                    ),
                  ),
                ],
              ),
              const Text(
                '16px (Normal)',
                style: TextStyle(
                  color: AppTheme.primaryPurple,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Slider(
            value: 16,
            min: 12,
            max: 24,
            activeColor: AppTheme.primaryPurple,
            onChanged: (v) {},
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Small',
                  style: TextStyle(
                    fontSize: 9,
                    color: isDark ? Colors.grey : Colors.grey[700],
                  ),
                ),
                Text(
                  'Default',
                  style: TextStyle(
                    fontSize: 9,
                    color: isDark ? Colors.grey : Colors.grey[700],
                  ),
                ),
                Text(
                  'Large',
                  style: TextStyle(
                    fontSize: 9,
                    color: isDark ? Colors.grey : Colors.grey[700],
                  ),
                ),
                Text(
                  'Extra Large',
                  style: TextStyle(
                    fontSize: 9,
                    color: isDark ? Colors.grey : Colors.grey[700],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildToggleRow(String title, String subtitle, bool val, bool isDark) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Row(
        children: [
          _iconBox(Icons.contrast, isDark),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                    color: isDark ? Colors.white : Colors.black,
                  ),
                ),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 12,
                    color: isDark ? Colors.grey : Colors.grey[700],
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: val,
            onChanged: (v) {},
            activeThumbColor: AppTheme.primaryPurple,
          ),
        ],
      ),
    );
  }

  Widget _iconBox(IconData icon, bool isDark, {double size = 40}) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: isDark
            ? Colors.white.withValues(alpha: 0.05)
            : Colors.black.withValues(alpha: 0.03),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Icon(icon, size: 20, color: AppTheme.primaryPurple),
    );
  }
}
