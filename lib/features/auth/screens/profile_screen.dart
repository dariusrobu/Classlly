import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:classlly/core/theme/app_theme.dart';
import 'package:classlly/features/library/screens/settings_screen.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF121212) : const Color(0xFFF7F7F7),
      body: Stack(
        children: [
          // Mesh Background (Radial Gradients)
          if (isDark)
            Positioned.fill(
              child: Container(
                decoration: const BoxDecoration(
                  gradient: RadialGradient(
                    center: Alignment(-1, -1),
                    radius: 1.5,
                    colors: [Color(0x26A852FF), Colors.transparent],
                  ),
                ),
              ),
            ),
          
          Row(
            children: [
              // Sidebar Navigation (Mini)
              _buildMiniSidebar(context, isDark),

              // Main Content
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 60),
                  child: Center(
                    child: Container(
                      constraints: const BoxConstraints(maxWidth: 1000),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildGlassPanel(
                            child: Column(
                              children: [
                                _buildProfileHeader(isDark),
                                const SizedBox(height: 40),
                                _buildStatsSection(isDark),
                              ],
                            ),
                          ),
                          const SizedBox(height: 32),
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(child: _buildSubscriptionCard(isDark)),
                              const SizedBox(width: 32),
                              Expanded(child: _buildQuickSettingsCard(isDark)),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMiniSidebar(BuildContext context, bool isDark) {
    return Container(
      width: 80,
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF121212).withOpacity(0.4) : Colors.white.withOpacity(0.4),
        border: Border(right: BorderSide(color: Colors.white.withOpacity(0.05))),
      ),
      child: Column(
        children: [
          const SizedBox(height: 40),
          _sidebarIcon(Icons.edit_note, isActive: false, isBrand: true),
          const SizedBox(height: 40),
          GestureDetector(onTap: () => Navigator.pop(context), child: _sidebarIcon(Icons.grid_view, isActive: false)),
          _sidebarIcon(Icons.description, isActive: false),
          _sidebarIcon(Icons.person, isActive: true),
          _sidebarIcon(Icons.analytics, isActive: false),
          GestureDetector(onTap: () => Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const SettingsScreen())), child: _sidebarIcon(Icons.settings, isActive: false)),
          const Spacer(),
          _sidebarIcon(Icons.logout, isActive: false, isDestructive: true),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _sidebarIcon(IconData icon, {required bool isActive, bool isBrand = false, bool isDestructive = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Container(
        width: 48, height: 48,
        decoration: BoxDecoration(
          color: isBrand ? AppTheme.primaryPurple : (isActive ? AppTheme.primaryPurple.withOpacity(0.1) : Colors.transparent),
          borderRadius: BorderRadius.circular(12),
          border: isActive && !isBrand ? Border.all(color: AppTheme.primaryPurple.withOpacity(0.2)) : null,
        ),
        child: Icon(icon, color: isBrand ? Colors.white : (isDestructive ? Colors.redAccent : (isActive ? AppTheme.primaryPurple : Colors.grey)), size: 24),
      ),
    );
  }

  Widget _buildGlassPanel({required Widget child}) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
        child: Container(
          padding: const EdgeInsets.all(48),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.03),
            border: Border.all(color: Colors.white.withOpacity(0.08)),
            borderRadius: BorderRadius.circular(24),
          ),
          child: child,
        ),
      ),
    );
  }

  Widget _buildProfileHeader(bool isDark) {
    return Row(
      children: [
        Stack(
          children: [
            Container(
              width: 120, height: 120,
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: AppTheme.primaryPurple.withOpacity(0.3), width: 4),
              ),
              child: const CircleAvatar(
                backgroundImage: NetworkImage('https://i.pravatar.cc/300'),
              ),
            ),
            Positioned(
              bottom: 0, left: 0, right: 0,
              child: Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryPurple,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [BoxShadow(color: AppTheme.primaryPurple.withOpacity(0.4), blurRadius: 10)],
                  ),
                  child: const Text("PRO MEMBER", style: TextStyle(color: Colors.white, fontSize: 8, fontWeight: FontWeight.bold, letterSpacing: 1.2)),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(width: 32),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text("Alex Rivera", style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.white)),
              const Text("Computer Science | Stanford University", style: TextStyle(fontSize: 16, color: Colors.white60)),
              const SizedBox(height: 16),
              Row(
                children: [
                  _badge("Verified Student", Icons.verified),
                  const SizedBox(width: 12),
                  _badge("Joined Sept 2023", null),
                ],
              ),
            ],
          ),
        ),
        Column(
          children: [
            ElevatedButton(
              onPressed: () {},
              style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primaryPurple, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
              child: const Text("Edit Profile", style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ],
    );
  }

  Widget _badge(String label, IconData? icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          if (icon != null) Icon(icon, size: 14, color: AppTheme.primaryPurple),
          if (icon != null) const SizedBox(width: 6),
          Text(label, style: const TextStyle(color: Colors.white70, fontSize: 11, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }

  Widget _buildStatsSection(bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text("Academic Performance", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white)),
            Text("Detailed Insights →", style: TextStyle(color: AppTheme.primaryPurple, fontSize: 13, fontWeight: FontWeight.bold)),
          ],
        ),
        const SizedBox(height: 24),
        Row(
          children: [
            Expanded(child: _statCard("Total Notes", "124", "+12%", Icons.menu_book)),
            const SizedBox(width: 20),
            Expanded(child: _statCard("Study Hours", "45.5h", "+5.4%", Icons.schedule)),
            const SizedBox(width: 20),
            Expanded(child: _statCard("Tasks Completed", "89%", "+2%", Icons.task_alt)),
          ],
        ),
      ],
    );
  }

  Widget _statCard(String label, String val, String trend, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: AppTheme.primaryPurple.withOpacity(0.1), borderRadius: BorderRadius.circular(8)), child: Icon(icon, color: AppTheme.primaryPurple, size: 20)),
              Text(trend, style: const TextStyle(color: Colors.greenAccent, fontWeight: FontWeight.bold, fontSize: 12)),
            ],
          ),
          const SizedBox(height: 16),
          Text(label, style: const TextStyle(color: Colors.white54, fontSize: 13)),
          Text(val, style: const TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildSubscriptionCard(bool isDark) {
    return _buildGlassPanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(width: 48, height: 48, decoration: BoxDecoration(gradient: const LinearGradient(colors: [AppTheme.primaryPurple, Color(0xFF7000FF)]), borderRadius: BorderRadius.circular(12)), child: const Icon(Icons.auto_awesome, color: Colors.white)),
              const SizedBox(width: 16),
              const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("Pro Plan", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.white)),
                  Text("Renews on Oct 12, 2024", style: TextStyle(color: Colors.white54, fontSize: 12)),
                ],
              ),
            ],
          ),
          const SizedBox(height: 24),
          const Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text("Storage Usage", style: TextStyle(color: Colors.white70, fontSize: 13)), Text("12.4 GB / 50 GB", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white))]),
          const SizedBox(height: 8),
          LinearProgressIndicator(value: 0.25, backgroundColor: Colors.white10, color: AppTheme.primaryPurple, minHeight: 6),
          const SizedBox(height: 32),
          ElevatedButton(
            onPressed: () {},
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primaryPurple, foregroundColor: Colors.white, minimumSize: const Size(double.infinity, 50), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
            child: const Text("Manage Subscription", style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickSettingsCard(bool isDark) {
    return _buildGlassPanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("Account Settings", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.white)),
          const SizedBox(height: 16),
          _settingItem(Icons.security, "Security & Privacy"),
          _settingItem(Icons.notifications, "Notifications"),
          _settingItem(Icons.devices, "Connected Devices"),
        ],
      ),
    );
  }

  Widget _settingItem(IconData icon, String label) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Icon(icon, color: Colors.white38, size: 20),
      title: Text(label, style: const TextStyle(color: Colors.white70, fontSize: 14)),
      trailing: const Icon(Icons.chevron_right, color: Colors.white10),
      onTap: () {},
    );
  }
}
