// lib/features/channels/screens/channel_settings_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:textgb/features/channels/models/channel_model.dart';
import 'package:textgb/features/channels/providers/channels_provider.dart';
import 'package:textgb/features/channels/theme/channels_theme.dart';

/// Screen for managing channel settings (owner/admin only)
class ChannelSettingsScreen extends ConsumerStatefulWidget {
  final String channelId;

  const ChannelSettingsScreen({
    super.key,
    required this.channelId,
  });

  @override
  ConsumerState<ChannelSettingsScreen> createState() =>
      _ChannelSettingsScreenState();
}

class _ChannelSettingsScreenState extends ConsumerState<ChannelSettingsScreen> {
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();

  bool _isLoading = false;
  bool _isSaving = false;
  ChannelModel? _channel;

  @override
  void initState() {
    super.initState();
    _loadChannel();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _loadChannel() async {
    setState(() => _isLoading = true);

    final channelAsync = await ref.read(channelProvider(widget.channelId).future);

    if (channelAsync != null) {
      setState(() {
        _channel = channelAsync;
        _nameController.text = channelAsync.name;
        _descriptionController.text = channelAsync.description;
        _isLoading = false;
      });
    } else {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (_channel == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Channel Settings')),
        body: const Center(
          child: Text('Channel not found'),
        ),
      );
    }

    return Scaffold(
      backgroundColor: ChannelsTheme.screenBackground,
      appBar: AppBar(
        title: const Text('Channel Settings'),
        actions: [
          if (_isSaving)
            const Center(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 16),
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
            )
          else
            TextButton(
              onPressed: _saveSettings,
              child: Text(
                'Save',
                style: ChannelsTheme.headingSmall.copyWith(
                  fontSize: 16,
                  color: ChannelsTheme.facebookBlue,
                ),
              ),
            ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Channel Info Section
          Text(
            'Channel Information',
            style: ChannelsTheme.headingMedium,
          ),
          const SizedBox(height: 16),

          // Channel Name
          TextField(
            controller: _nameController,
            decoration: ChannelsTheme.inputDecoration(
              labelText: 'Channel Name',
              prefixIcon: const Icon(Icons.tv),
            ).copyWith(
              border: const OutlineInputBorder(),
            ),
            maxLength: 50,
          ),
          const SizedBox(height: 16),

          // Description
          TextField(
            controller: _descriptionController,
            decoration: ChannelsTheme.inputDecoration(
              labelText: 'Description',
              prefixIcon: const Icon(Icons.description),
            ).copyWith(
              border: const OutlineInputBorder(),
              alignLabelWithHint: true,
            ),
            maxLines: 4,
            maxLength: 500,
          ),
          const SizedBox(height: 24),

          // Channel Type (Read-only)
          _buildInfoCard(
            title: 'Channel Type',
            icon: _getTypeIcon(_channel!.type),
            iconColor: _getTypeColor(_channel!.type),
            value: _getTypeName(_channel!.type),
            subtitle: 'Channel type cannot be changed',
          ),
          const SizedBox(height: 16),

          // Subscription Price (Read-only for premium)
          if (_channel!.type == ChannelType.premium) ...[
            _buildInfoCard(
              title: 'Subscription Price',
              icon: Icons.attach_money,
              iconColor: Colors.amber,
              value: '${_channel!.subscriptionPriceCoins ?? 0} coins',
              subtitle: 'Contact support to change pricing',
            ),
            const SizedBox(height: 16),
          ],

          // Stats Section
          Text(
            'Statistics',
            style: ChannelsTheme.headingMedium,
          ),
          const SizedBox(height: 16),

          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  icon: Icons.people,
                  label: 'Subscribers',
                  value: '${_channel!.subscriberCount}',
                  color: ChannelsTheme.facebookBlue,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildStatCard(
                  icon: Icons.post_add,
                  label: 'Posts',
                  value: '${_channel!.postCount}',
                  color: ChannelsTheme.success,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Management Section
          Text(
            'Management',
            style: ChannelsTheme.headingMedium,
          ),
          const SizedBox(height: 16),

          // Manage Members
          _buildManagementOption(
            icon: Icons.group,
            title: 'Manage Members',
            subtitle: 'Add or remove admins and moderators',
            onTap: _navigateToMembersManagement,
          ),

          // Verification Status
          if (_channel!.isVerified)
            _buildManagementOption(
              icon: Icons.verified,
              iconColor: ChannelsTheme.facebookBlue,
              title: 'Verified Channel',
              subtitle: 'This channel is verified',
              onTap: null,
            )
          else
            _buildManagementOption(
              icon: Icons.verified_outlined,
              title: 'Request Verification',
              subtitle: 'Get your channel verified',
              onTap: _requestVerification,
            ),

          const SizedBox(height: 24),

          // Danger Zone
          Text(
            'Danger Zone',
            style: ChannelsTheme.headingMedium.copyWith(
              color: ChannelsTheme.error,
            ),
          ),
          const SizedBox(height: 16),

          _buildDangerOption(
            icon: Icons.delete_forever,
            title: 'Delete Channel',
            subtitle: 'Permanently delete this channel and all its content',
            onTap: _confirmDeleteChannel,
          ),
        ],
      ),
    );
  }

  Widget _buildInfoCard({
    required String title,
    required IconData icon,
    required Color iconColor,
    required String value,
    required String subtitle,
  }) {
    return Card(
      color: ChannelsTheme.cardBackground,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: iconColor.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: iconColor),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: ChannelsTheme.bodySmall,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    value,
                    style: ChannelsTheme.headingMedium,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: ChannelsTheme.caption,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Card(
      color: ChannelsTheme.cardBackground,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Icon(icon, color: color, size: 32),
            const SizedBox(height: 8),
            Text(
              value,
              style: ChannelsTheme.headingLarge,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: ChannelsTheme.bodySmall,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildManagementOption({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback? onTap,
    Color? iconColor,
  }) {
    return Card(
      color: ChannelsTheme.cardBackground,
      child: ListTile(
        leading: Icon(icon, color: iconColor),
        title: Text(title, style: ChannelsTheme.bodyLarge),
        subtitle: Text(subtitle, style: ChannelsTheme.bodySmall),
        trailing: onTap != null ? const Icon(Icons.chevron_right) : null,
        onTap: onTap,
      ),
    );
  }

  Widget _buildDangerOption({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Card(
      color: ChannelsTheme.error.withOpacity(0.1),
      child: ListTile(
        leading: const Icon(Icons.delete_forever, color: ChannelsTheme.error),
        title: Text(title, style: ChannelsTheme.bodyLarge.copyWith(color: ChannelsTheme.error)),
        subtitle: Text(subtitle, style: ChannelsTheme.bodySmall),
        trailing: const Icon(Icons.chevron_right, color: ChannelsTheme.error),
        onTap: onTap,
      ),
    );
  }

  IconData _getTypeIcon(ChannelType type) {
    switch (type) {
      case ChannelType.public:
        return Icons.public;
      case ChannelType.private:
        return Icons.lock;
      case ChannelType.premium:
        return Icons.star;
    }
  }

  Color _getTypeColor(ChannelType type) {
    switch (type) {
      case ChannelType.public:
        return ChannelsTheme.publicChannelColor;
      case ChannelType.private:
        return ChannelsTheme.privateChannelColor;
      case ChannelType.premium:
        return ChannelsTheme.premiumChannelColor;
    }
  }

  String _getTypeName(ChannelType type) {
    switch (type) {
      case ChannelType.public:
        return 'Public';
      case ChannelType.private:
        return 'Private';
      case ChannelType.premium:
        return 'Premium';
    }
  }

  Future<void> _saveSettings() async {
    if (_nameController.text.trim().isEmpty ||
        _descriptionController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill in all fields')),
      );
      return;
    }

    setState(() => _isSaving = true);

    try {
      final actionsNotifier = ref.read(channelActionsProvider.notifier);
      final success = await actionsNotifier.updateChannel(
        widget.channelId,
        {
          'name': _nameController.text.trim(),
          'description': _descriptionController.text.trim(),
        },
      );

      if (mounted) {
        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Settings saved successfully!'),
              backgroundColor: ChannelsTheme.success,
            ),
          );
          Navigator.of(context).pop();
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Failed to save settings'),
              backgroundColor: ChannelsTheme.error,
            ),
          );
        }
        setState(() => _isSaving = false);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${e.toString()}')),
        );
        setState(() => _isSaving = false);
      }
    }
  }

  void _navigateToMembersManagement() {
    context.push('/channel/${widget.channelId}/members');
  }

  void _requestVerification() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Request Verification'),
        content: const Text(
          'To verify your channel, please contact support with:\n\n'
          '• Proof of identity\n'
          '• Channel purpose and audience\n'
          '• Reason for verification request',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              // TODO: Implement contact support
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Contact support (coming soon)')),
              );
            },
            child: const Text('Contact Support'),
          ),
        ],
      ),
    );
  }

  Future<void> _confirmDeleteChannel() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Channel?'),
        content: const Text(
          'This action cannot be undone. All posts, comments, and subscriber data will be permanently deleted.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: ChannelsTheme.error),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      _deleteChannel();
    }
  }

  Future<void> _deleteChannel() async {
    setState(() => _isSaving = true);

    try {
      final actionsNotifier = ref.read(channelActionsProvider.notifier);
      final success = await actionsNotifier.deleteChannel(widget.channelId);

      if (mounted) {
        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Channel deleted successfully'),
              backgroundColor: ChannelsTheme.success,
            ),
          );
          // Navigate back to channels home
          Navigator.of(context).popUntil((route) => route.isFirst);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Failed to delete channel'),
              backgroundColor: ChannelsTheme.error,
            ),
          );
          setState(() => _isSaving = false);
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${e.toString()}')),
        );
        setState(() => _isSaving = false);
      }
    }
  }
}
