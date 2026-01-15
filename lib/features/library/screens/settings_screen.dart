import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:classlly/core/theme/app_theme.dart';
import 'package:classlly/features/auth/screens/profile_screen.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF121212) : const Color(0xFFF7F7F7),
      body: Row(
        children: [
          // Sidebar (Full)
          _buildSidebar(context, isDark),

          // Main Content
          Expanded(
            child: Column(
              children: [
                _buildHeader(context, isDark),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 60, vertical: 40),
                    child: Center(
                      child: Container(
                        constraints: const BoxConstraints(maxWidth: 800),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildSectionHeader("Appearance", "Customize how Classlly looks and feels on your device."),
                            const SizedBox(height: 24),
                            _buildGlassPanel(
                              child: Column(
                                children: [
                                  _buildThemeRow(context, isDark),
                                  const Divider(height: 1, color: Colors.white10),
                                  _buildAccentColorRow(isDark),
                                ],
                              ),
                            ),
                            const SizedBox(height: 48),
                            _buildSectionHeader("Sync & Cloud", "Keep your notes synchronized across all your academic devices."),
                            const SizedBox(height: 24),
                            Row(
                              children: [
                                Expanded(child: _buildCloudCard("Google Drive", "Connected 2m ago", true, isDark)),
                                const SizedBox(width: 20),
                                Expanded(child: _buildCloudCard("iCloud Workspace", "Disconnected", false, isDark)),
                              ],
                            ),
                            const SizedBox(height: 48),
                            _buildSectionHeader("Accessibility", "Make Classlly more comfortable for your specific needs."),
                            const SizedBox(height: 24),
                            _buildGlassPanel(
                              child: Column(
                                children: [
                                  _buildFontSizeSlider(isDark),
                                  const Divider(height: 1, color: Colors.white10),
                                  _buildToggleRow("High Contrast Mode", "Increases contrast for better readability.", false),
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

  Widget _buildSidebar(BuildContext context, bool isDark) {
    return Container(
      width: 260,
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF121212).withOpacity(0.5) : Colors.white,
        border: Border(right: BorderSide(color: Colors.white.withOpacity(0.05))),
      ),
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("Classlly", style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: AppTheme.primaryPurple)),
          const Text("STUDENT WORKSPACE", style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.grey, letterSpacing: 1.2)),
          const SizedBox(height: 40),
          _navItem(Icons.grid_view, "Dashboard", false, onTap: () => Navigator.pop(context)),
          _navItem(Icons.description, "My Notes", false, onTap: () => Navigator.pop(context)),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 20),
            child: Divider(color: Colors.white10),
          ),
          const Text("PREFERENCES", style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.grey, letterSpacing: 1.2)),
          const SizedBox(height: 12),
          _navItem(Icons.settings, "General", false),
          _navItem(Icons.palette, "Appearance", true),
          _navItem(Icons.cloud_sync, "Sync & Cloud", false),
          _navItem(Icons.notifications, "Notifications", false),
          const Spacer(),
          _buildProPlanCard(),
        ],
      ),
    );
  }

  Widget _navItem(IconData icon, String label, bool isActive, {VoidCallback? onTap}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 4),
      decoration: BoxDecoration(
        color: isActive ? AppTheme.primaryPurple.withOpacity(0.1) : Colors.transparent,
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        leading: Icon(icon, color: isActive ? AppTheme.primaryPurple : Colors.grey, size: 20),
        title: Text(label, style: TextStyle(color: isActive ? AppTheme.primaryPurple : Colors.grey, fontSize: 14, fontWeight: FontWeight.w500)),
        dense: true,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        onTap: onTap,
      ),
    );
  }

  Widget _buildProPlanCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: AppTheme.primaryPurple.withOpacity(0.05), borderRadius: BorderRadius.circular(16), border: Border.all(color: AppTheme.primaryPurple.withOpacity(0.2))),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("PRO PLAN", style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppTheme.primaryPurple)),
          const SizedBox(height: 8),
          const Text("Unlock unlimited cloud storage and advanced features.", style: TextStyle(fontSize: 11, color: Colors.grey)),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () {},
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primaryPurple, foregroundColor: Colors.white, minimumSize: const Size(double.infinity, 36), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
            child: const Text("Upgrade Now", style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context, bool isDark) {
    return Container(
      height: 64,
      padding: const EdgeInsets.symmetric(horizontal: 32),
      decoration: BoxDecoration(border: Border(bottom: BorderSide(color: Colors.white.withOpacity(0.05)))),
      child: Row(
        children: [
          const Text("Settings", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
          const VerticalDivider(width: 32, indent: 24, endIndent: 24),
          const Text("Workspace", style: TextStyle(fontSize: 12, color: Colors.grey)),
          const Icon(Icons.chevron_right, size: 14, color: Colors.grey),
          const Text("Appearance", style: TextStyle(fontSize: 12, color: Colors.white70)),
          const Spacer(),
          SizedBox(
            width: 240,
            child: TextField(
              decoration: InputDecoration(
                hintText: "Search preferences...",
                hintStyle: const TextStyle(color: Colors.grey, fontSize: 13),
                prefixIcon: const Icon(Icons.search, size: 18, color: Colors.grey),
                filled: true,
                fillColor: Colors.white.withOpacity(0.05),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                contentPadding: EdgeInsets.zero,
              ),
            ),
          ),
          const SizedBox(width: 16),
          IconButton(onPressed: () => Navigator.pop(context), icon: const Icon(Icons.close, color: Colors.grey)),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title, String subtitle) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white)),
        Text(subtitle, style: const TextStyle(fontSize: 14, color: Colors.grey)),
      ],
    );
  }

  Widget _buildGlassPanel({required Widget child}) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.03),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
        borderRadius: BorderRadius.circular(20),
      ),
      child: child,
    );
  }

  Widget _buildThemeRow(BuildContext context, bool isDark) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Row(
        children: [
          _iconBox(Icons.dark_mode),
          const SizedBox(width: 16),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("Interface Theme", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Colors.white)),
                Text("Choose between light, dark, or system default.", style: TextStyle(fontSize: 12, color: Colors.grey)),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(color: Colors.white.withOpacity(0.05), borderRadius: BorderRadius.circular(12)),
            child: Row(
              children: [
                _themeBtn("Light", false),
                _themeBtn("Dark", true),
                _themeBtn("System", false),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _themeBtn(String label, bool active) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(color: active ? AppTheme.primaryPurple : Colors.transparent, borderRadius: BorderRadius.circular(8)),
      child: Text(label, style: TextStyle(color: active ? Colors.white : Colors.grey, fontSize: 12, fontWeight: FontWeight.bold)),
    );
  }

  Widget _buildAccentColorRow(bool isDark) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("Accent Color", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Colors.white)),
          const Text("Select the glowing accent used for buttons and highlights.", style: TextStyle(fontSize: 12, color: Colors.grey)),
          const SizedBox(height: 20),
          Row(
            children: [
              _colorDot(AppTheme.primaryPurple, true),
              _colorDot(Colors.blue, false),
              _colorDot(Colors.teal, false),
              _colorDot(Colors.orange, false),
              _colorDot(Colors.pink, false),
            ],
          ),
        ],
      ),
    );
  }

  Widget _colorDot(Color color, bool active) {
    return Container(
      margin: const EdgeInsets.only(right: 16),
      width: 32, height: 32,
      decoration: BoxDecoration(
        color: color, shape: BoxShape.circle,
        border: active ? Border.all(color: Colors.white, width: 2) : null,
        boxShadow: active ? [BoxShadow(color: color.withOpacity(0.4), blurRadius: 10)] : null,
      ),
      child: active ? const Icon(Icons.check, size: 16, color: Colors.white) : null,
    );
  }

  Widget _buildCloudCard(String title, String status, bool connected, bool isDark) {
    return _buildGlassPanel(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _iconBox(Icons.cloud, size: 40),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(color: connected ? Colors.green.withOpacity(0.1) : Colors.white10, borderRadius: BorderRadius.circular(20)),
                  child: Text(connected ? "CONNECTED" : "DISCONNECTED", style: TextStyle(color: connected ? Colors.green : Colors.grey, fontSize: 8, fontWeight: FontWeight.bold)),
                ),
              ],
            ),
            const SizedBox(height: 24),
            Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Colors.white)),
            Text(status, style: const TextStyle(fontSize: 12, color: Colors.grey)),
            const SizedBox(height: 20),
            TextButton(onPressed: () {}, child: Text(connected ? "Disconnect" : "Connect Account", style: TextStyle(color: connected ? Colors.green : AppTheme.primaryPurple, fontSize: 12, fontWeight: FontWeight.bold))),
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
          const Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("Base Font Size", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Colors.white)),
                  Text("Scale the size of the note editor text.", style: TextStyle(fontSize: 12, color: Colors.grey)),
                ],
              ),
              Text("16px (Normal)", style: TextStyle(color: AppTheme.primaryPurple, fontSize: 12, fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 24),
          Slider(value: 16, min: 12, max: 24, activeColor: AppTheme.primaryPurple, onChanged: (v) {}),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 12),
            child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              Text("Small", style: TextStyle(fontSize: 9, color: Colors.grey)),
              Text("Default", style: TextStyle(fontSize: 9, color: Colors.grey)),
              Text("Large", style: TextStyle(fontSize: 9, color: Colors.grey)),
              Text("Extra Large", style: TextStyle(fontSize: 9, color: Colors.grey)),
            ]),
          ),
        ],
      ),
    );
  }

  Widget _buildToggleRow(String title, String subtitle, bool val) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Row(
        children: [
          _iconBox(Icons.contrast),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Colors.white)),
                Text(subtitle, style: const TextStyle(fontSize: 12, color: Colors.grey)),
              ],
            ),
          ),
          Switch(value: val, onChanged: (v) {}, activeColor: AppTheme.primaryPurple),
        ],
      ),
    );
  }

  Widget _iconBox(IconData icon, {double size = 40}) {
    return Container(
      width: size, height: size,
      decoration: BoxDecoration(color: Colors.white.withOpacity(0.05), borderRadius: BorderRadius.circular(10)),
      child: Icon(icon, size: 20, color: AppTheme.primaryPurple),
    );
  }
}
