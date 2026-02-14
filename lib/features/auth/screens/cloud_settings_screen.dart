import 'package:flutter/material.dart';
import 'package:classlly/core/services/cloud_provider.dart';
import 'package:classlly/data/repositories/notes_repository.dart';

/// BYOC Cloud Settings screen — lets users choose their storage provider.
class CloudSettingsScreen extends StatefulWidget {
  const CloudSettingsScreen({super.key});

  @override
  State<CloudSettingsScreen> createState() => _CloudSettingsScreenState();
}

class _CloudSettingsScreenState extends State<CloudSettingsScreen> {
  late CloudProvider _selectedProvider;
  bool _isSyncing = false;
  DateTime? _lastSynced;

  @override
  void initState() {
    super.initState();
    final prefs = NotesRepository().getPreferences();
    _selectedProvider = CloudProvider.values.firstWhere(
      (p) => p.name == prefs.cloudProvider,
      orElse: () => CloudProvider.none,
    );
    _lastSynced = prefs.lastSyncTimestamp;
  }

  Future<void> _selectProvider(CloudProvider provider) async {
    if (provider == _selectedProvider) return;

    setState(() => _selectedProvider = provider);

    // Save preference
    final repo = NotesRepository();
    final prefs = repo.getPreferences();
    prefs.cloudProvider = provider.name;
    await repo.savePreferences(prefs);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Cloud storage set to ${provider.displayName}'),
          backgroundColor: const Color(0xFF8B5CF6),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> _syncNow() async {
    if (_isSyncing) return;

    setState(() => _isSyncing = true);

    try {
      final service = CloudProviderManager.getService(_selectedProvider);
      await service.syncAll(interactive: true);

      final repo = NotesRepository();
      final prefs = repo.getPreferences();
      prefs.lastSyncTimestamp = DateTime.now();
      await repo.savePreferences(prefs);

      setState(() {
        _lastSynced = prefs.lastSyncTimestamp;
        _isSyncing = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Sync completed successfully!'),
            backgroundColor: Color(0xFF22C55E),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      setState(() => _isSyncing = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Sync failed: $e'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0F0F23) : Colors.grey[50],
      appBar: AppBar(
        title: const Text('Cloud Storage'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF8B5CF6), Color(0xFF6366F1)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.cloud,
                      color: Colors.white,
                      size: 28,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Bring Your Own Cloud',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Your data, your cloud. Choose where to store.',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.8),
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Provider cards
            Text(
              'STORAGE PROVIDER',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: isDark ? Colors.grey[400] : Colors.grey[600],
                letterSpacing: 1.0,
              ),
            ),
            const SizedBox(height: 12),

            ...CloudProvider.values
                .where((p) => p.isAvailable)
                .map((provider) => _buildProviderCard(provider, isDark)),

            const SizedBox(height: 24),

            // Sync section
            if (_selectedProvider != CloudProvider.none) ...[
              Text(
                'SYNC',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: isDark ? Colors.grey[400] : Colors.grey[600],
                  letterSpacing: 1.0,
                ),
              ),
              const SizedBox(height: 12),
              _buildSyncCard(isDark),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildProviderCard(CloudProvider provider, bool isDark) {
    final isSelected = provider == _selectedProvider;
    final IconData icon;
    switch (provider) {
      case CloudProvider.none:
        icon = Icons.smartphone;
      case CloudProvider.supabase:
        icon = Icons.dns_outlined;
      case CloudProvider.googleDrive:
        icon = Icons.add_to_drive;
      case CloudProvider.iCloud:
        icon = Icons.cloud_queue;
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _selectProvider(provider),
          borderRadius: BorderRadius.circular(14),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isSelected
                  ? (isDark
                      ? const Color(0xFF8B5CF6).withValues(alpha: 0.15)
                      : const Color(0xFF8B5CF6).withValues(alpha: 0.08))
                  : (isDark ? const Color(0xFF1A1A2E) : Colors.white),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: isSelected
                    ? const Color(0xFF8B5CF6)
                    : (isDark ? Colors.grey[800]! : Colors.grey[200]!),
                width: isSelected ? 2 : 1,
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? const Color(0xFF8B5CF6).withValues(alpha: 0.2)
                        : (isDark ? Colors.grey[800] : Colors.grey[100]),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    icon,
                    size: 22,
                    color: isSelected
                        ? const Color(0xFF8B5CF6)
                        : (isDark ? Colors.grey[400] : Colors.grey[600]),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        provider.displayName,
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: isDark ? Colors.white : Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        provider.description,
                        style: TextStyle(
                          fontSize: 12,
                          color: isDark ? Colors.grey[500] : Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
                if (isSelected)
                  const Icon(
                    Icons.check_circle,
                    color: Color(0xFF8B5CF6),
                    size: 22,
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSyncCard(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1A1A2E) : Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isDark ? Colors.grey[800]! : Colors.grey[200]!,
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Icon(
                Icons.sync,
                size: 18,
                color: isDark ? Colors.grey[400] : Colors.grey[600],
              ),
              const SizedBox(width: 10),
              Text(
                'Last synced: ',
                style: TextStyle(
                  fontSize: 13,
                  color: isDark ? Colors.grey[400] : Colors.grey[600],
                ),
              ),
              Text(
                _lastSynced != null
                    ? _formatTimestamp(_lastSynced!)
                    : 'Never',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: isDark ? Colors.white : Colors.black87,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _isSyncing ? null : _syncNow,
              icon: _isSyncing
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.cloud_upload, size: 18),
              label: Text(_isSyncing ? 'Syncing...' : 'Sync Now'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF8B5CF6),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatTimestamp(DateTime dt) {
    final now = DateTime.now();
    final diff = now.difference(dt);
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return '${dt.day}/${dt.month}/${dt.year}';
  }
}
