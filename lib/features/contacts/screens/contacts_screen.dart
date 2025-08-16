// Enhanced contacts_screen.dart with modern design language matching channels screen
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_contacts/flutter_contacts.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:textgb/constants.dart';
import 'package:textgb/features/contacts/providers/contacts_provider.dart';
import 'package:textgb/features/contacts/screens/add_contact_screen.dart';
import 'package:textgb/features/contacts/screens/blocked_contacts_screen.dart';
import 'package:textgb/models/user_model.dart';
import 'package:textgb/shared/theme/theme_extensions.dart';
import 'package:textgb/shared/utilities/global_methods.dart';
import 'package:share_plus/share_plus.dart';
import 'package:intl/intl.dart';
import 'package:cached_network_image/cached_network_image.dart';

class ContactsScreen extends ConsumerStatefulWidget {
  const ContactsScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<ContactsScreen> createState() => _ContactsScreenState();
}

class _ContactsScreenState extends ConsumerState<ContactsScreen> 
    with TickerProviderStateMixin, AutomaticKeepAliveClientMixin {
  
  late TabController _tabController;
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  final ScrollController _contactsScrollController = ScrollController();
  final ScrollController _invitesScrollController = ScrollController();
  
  String _searchQuery = '';
  bool _isSearching = false;
  bool _isInitializing = true;
  
  // Performance optimizations
  late AnimationController _refreshAnimationController;
  late Animation<double> _refreshAnimation;
  final GlobalKey<RefreshIndicatorState> _refreshIndicatorKey = GlobalKey();
  
  // Cached filtered lists for better performance
  List<UserModel> _filteredRegisteredContacts = [];
  List<Contact> _filteredUnregisteredContacts = [];
  
  @override
  bool get wantKeepAlive => true; // Keep state alive when switching tabs

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _setupAnimations();
    _setupListeners();
    
    // Initialize contacts data
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeContacts();
    });
  }

  void _setupAnimations() {
    _refreshAnimationController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );
    _refreshAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(_refreshAnimationController);
  }

  void _setupListeners() {
    _searchController.addListener(_onSearchChanged);
    _tabController.addListener(_onTabChanged);
  }

  void _onSearchChanged() {
    final query = _searchController.text.toLowerCase().trim();
    if (query != _searchQuery) {
      setState(() {
        _searchQuery = query;
        _updateFilteredContacts();
      });
    }
  }

  void _onTabChanged() {
    // Clear search when switching tabs
    if (_searchController.text.isNotEmpty) {
      _searchController.clear();
    }
  }

  void _updateFilteredContacts() {
    final contactsState = ref.read(contactsNotifierProvider).value;
    if (contactsState == null) return;

    if (_searchQuery.isEmpty) {
      _filteredRegisteredContacts = contactsState.registeredContacts;
      _filteredUnregisteredContacts = contactsState.unregisteredContacts;
    } else {
      _filteredRegisteredContacts = contactsState.registeredContacts
          .where((contact) =>
              contact.name.toLowerCase().contains(_searchQuery) ||
              contact.phoneNumber.toLowerCase().contains(_searchQuery))
          .toList();

      _filteredUnregisteredContacts = contactsState.unregisteredContacts
          .where((contact) =>
              contact.displayName.toLowerCase().contains(_searchQuery) ||
              contact.phones.any((phone) =>
                  phone.number.toLowerCase().contains(_searchQuery)))
          .toList();
    }
  }

  // Smart initialization with background sync
  Future<void> _initializeContacts() async {
    setState(() {
      _isInitializing = true;
    });
    
    try {
      final contactsNotifier = ref.read(contactsNotifierProvider.notifier);
      
      // Load cached data first for instant UI
      await ref.read(contactsNotifierProvider.future);
      
      if (mounted) {
        setState(() {
          _isInitializing = false;
          _updateFilteredContacts();
        });
      }
      
      // Check if background sync is needed
      final syncInfo = contactsNotifier.getSyncInfo();
      if (syncInfo['backgroundSyncAvailable'] == true) {
        // Perform background sync without blocking UI
        _performBackgroundSync();
      }
      
      // Always load blocked contacts
      await contactsNotifier.loadBlockedContacts();
    } catch (e) {
      debugPrint('Error initializing contacts: $e');
      if (mounted) {
        setState(() {
          _isInitializing = false;
        });
        _showErrorSnackBar('Error loading contacts: $e');
      }
    }
  }

  // Background sync with user feedback
  Future<void> _performBackgroundSync() async {
    try {
      final contactsNotifier = ref.read(contactsNotifierProvider.notifier);
      await contactsNotifier.performBackgroundSync();
      
      if (mounted) {
        _updateFilteredContacts();
        _showSuccessSnackBar('Contacts updated');
      }
    } catch (e) {
      debugPrint('Background sync failed: $e');
      // Don't show error for background sync failures
    }
  }

  // Force sync with user feedback
  Future<void> _forceSyncContacts() async {
    _refreshAnimationController.repeat();
    
    try {
      final contactsNotifier = ref.read(contactsNotifierProvider.notifier);
      await contactsNotifier.syncContacts(forceSync: true);
      
      if (mounted) {
        _updateFilteredContacts();
        _showSuccessSnackBar('Contacts synced successfully');
      }
    } catch (e) {
      if (mounted) {
        _showErrorSnackBar('Error syncing contacts: $e');
      }
    } finally {
      _refreshAnimationController.stop();
      _refreshAnimationController.reset();
    }
  }

  // Navigate to contact profile
  void _navigateToContactProfile(UserModel contact) {
    HapticFeedback.lightImpact();
    Navigator.pushNamed(
      context,
      Constants.contactProfileScreen,
      arguments: contact,
    );
  }

  // Enhanced sync status display
  Widget _buildSyncStatusIndicator(ContactsState state) {
    if (state.lastSyncTime == null) return const SizedBox.shrink();
    
    final formatter = DateFormat('MMM d, h:mm a');
    final syncTime = formatter.format(state.lastSyncTime!);
    final theme = context.modernTheme;
    
    Color statusColor;
    IconData statusIcon;
    String statusText;
    
    switch (state.syncStatus) {
      case SyncStatus.upToDate:
        statusColor = Colors.green;
        statusIcon = Icons.check_circle_rounded;
        statusText = 'Up to date';
        break;
      case SyncStatus.stale:
        statusColor = Colors.orange;
        statusIcon = Icons.update_rounded;
        statusText = 'Update available';
        break;
      case SyncStatus.backgroundSyncing:
        statusColor = Colors.blue;
        statusIcon = Icons.sync_rounded;
        statusText = 'Syncing...';
        break;
      case SyncStatus.failed:
        statusColor = Colors.red;
        statusIcon = Icons.error_outline_rounded;
        statusText = 'Sync failed';
        break;
      default:
        statusColor = Colors.grey;
        statusIcon = Icons.help_outline_rounded;
        statusText = 'Unknown';
    }
    
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: theme.surfaceColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: theme.dividerColor!.withOpacity(0.15),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: statusColor.withOpacity(0.08),
            blurRadius: 16,
            offset: const Offset(0, 3),
            spreadRadius: -3,
          ),
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 1),
            spreadRadius: -1,
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: statusColor.withOpacity(0.15),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Icon(statusIcon, size: 12, color: statusColor),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              '$statusText • Last synced: $syncTime',
              style: TextStyle(
                fontSize: 11,
                color: theme.textSecondaryColor,
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          if (state.backgroundSyncAvailable) ...[
            const SizedBox(width: 8),
            Material(
              color: Colors.transparent,
              borderRadius: BorderRadius.circular(6),
              child: InkWell(
                onTap: _forceSyncContacts,
                borderRadius: BorderRadius.circular(6),
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: theme.primaryColor!.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Icon(
                    Icons.refresh_rounded,
                    size: 12,
                    color: theme.primaryColor,
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  // Permission request UI with modern design
  Widget _buildPermissionScreen() {
    final theme = context.modernTheme;
    
    return Container(
      color: theme.surfaceColor,
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Container(
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: theme.surfaceColor,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: theme.dividerColor!.withOpacity(0.15),
                width: 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: theme.primaryColor!.withOpacity(0.08),
                  blurRadius: 24,
                  offset: const Offset(0, 6),
                  spreadRadius: -6,
                ),
                BoxShadow(
                  color: Colors.black.withOpacity(0.04),
                  blurRadius: 12,
                  offset: const Offset(0, 3),
                  spreadRadius: -3,
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: theme.primaryColor!.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.contacts_rounded,
                    size: 60,
                    color: theme.primaryColor,
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  'Contacts Access Required',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    color: theme.textColor,
                    letterSpacing: -0.3,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                Text(
                  'To sync your contacts and find friends on TexGB, we need access to your contacts.',
                  style: TextStyle(
                    fontSize: 15,
                    color: theme.textSecondaryColor,
                    height: 1.4,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 32),
                Material(
                  color: Colors.transparent,
                  borderRadius: BorderRadius.circular(16),
                  child: InkWell(
                    onTap: () async {
                      HapticFeedback.lightImpact();
                      final contactsNotifier = ref.read(contactsNotifierProvider.notifier);
                      await contactsNotifier.requestPermission();
                    },
                    borderRadius: BorderRadius.circular(16),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                      decoration: BoxDecoration(
                        color: theme.primaryColor,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: theme.primaryColor!.withOpacity(0.3),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(2),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: const Icon(
                              Icons.security_rounded,
                              color: Colors.white,
                              size: 16,
                            ),
                          ),
                          const SizedBox(width: 8),
                          const Text(
                            'Grant Permission',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Optimized contact item with modern design
  Widget _buildOptimizedContactItem(UserModel contact, int index) {
    final theme = context.modernTheme;
    
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
      decoration: BoxDecoration(
        color: theme.surfaceColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: theme.dividerColor!.withOpacity(0.15),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: theme.primaryColor!.withOpacity(0.08),
            blurRadius: 20,
            offset: const Offset(0, 4),
            spreadRadius: -4,
          ),
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 2),
            spreadRadius: -2,
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _navigateToContactProfile(contact),
          borderRadius: BorderRadius.circular(16),
          child: Container(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                // Enhanced Contact Avatar
                Container(
                  width: 52,
                  height: 52,
                  padding: const EdgeInsets.all(2),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: theme.dividerColor!.withOpacity(0.2),
                      width: 1,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: theme.primaryColor!.withOpacity(0.15),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: _buildCachedAvatar(contact),
                ),
                
                const SizedBox(width: 12),
                
                // Enhanced Contact Info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Contact name
                      Text(
                        contact.name,
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: theme.textColor,
                          letterSpacing: -0.2,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      
                      const SizedBox(height: 4),
                      
                      // Phone number with enhanced styling
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: theme.primaryColor!.withOpacity(0.08),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.phone_rounded,
                              size: 10,
                              color: theme.primaryColor,
                            ),
                            const SizedBox(width: 3),
                            Flexible(
                              child: Text(
                                contact.phoneNumber,
                                style: TextStyle(
                                  fontSize: 10,
                                  color: theme.primaryColor,
                                  fontWeight: FontWeight.w600,
                                ),
                                overflow: TextOverflow.ellipsis,
                                maxLines: 1,
                              ),
                            ),
                          ],
                        ),
                      ),
                      
                      const SizedBox(height: 4),
                      
                      // Status message if available
                      if (contact.status?.isNotEmpty == true)
                        Text(
                          contact.status!,
                          style: TextStyle(
                            fontSize: 11,
                            color: theme.textSecondaryColor,
                            fontStyle: FontStyle.italic,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                    ],
                  ),
                ),
                
                const SizedBox(width: 8),
                

              ],
            ),
          ),
        ),
      ),
    );
  }

  // Cached avatar widget for better performance
  Widget _buildCachedAvatar(UserModel contact) {
    final theme = context.modernTheme;
    
    if (contact.image.isEmpty) {
      return CircleAvatar(
        radius: 24,
        backgroundColor: theme.primaryColor!.withOpacity(0.15),
        child: Text(
          contact.name.isNotEmpty ? contact.name[0].toUpperCase() : '?',
          style: TextStyle(
            color: theme.primaryColor,
            fontWeight: FontWeight.w700,
            fontSize: 18,
          ),
        ),
      );
    }

    return CachedNetworkImage(
      imageUrl: contact.image,
      imageBuilder: (context, imageProvider) => CircleAvatar(
        radius: 24,
        backgroundImage: imageProvider,
      ),
      placeholder: (context, url) => CircleAvatar(
        radius: 24,
        backgroundColor: theme.surfaceVariantColor,
        child: CircularProgressIndicator(
          strokeWidth: 2,
          color: theme.primaryColor,
        ),
      ),
      errorWidget: (context, url, error) => CircleAvatar(
        radius: 24,
        backgroundColor: theme.primaryColor!.withOpacity(0.15),
        child: Text(
          contact.name.isNotEmpty ? contact.name[0].toUpperCase() : '?',
          style: TextStyle(
            color: theme.primaryColor,
            fontWeight: FontWeight.w700,
            fontSize: 18,
          ),
        ),
      ),
    );
  }

  // Contact options menu
  void _showContactOptionsMenu(UserModel contact) {
    // Method removed - no longer needed
  }

  Widget _buildActionTile({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    required theme,
    bool isDestructive = false,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: isDestructive 
                    ? Colors.red.withOpacity(0.1)
                    : theme.primaryColor!.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  icon,
                  color: isDestructive ? Colors.red : theme.primaryColor,
                  size: 18,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                title,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: isDestructive ? Colors.red : theme.textColor,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Block contact with feedback
  Future<void> _blockContact(UserModel contact) async {
    try {
      await ref.read(contactsNotifierProvider.notifier).blockContact(contact);
      _updateFilteredContacts();
      _showSuccessSnackBar('${contact.name} blocked');
    } catch (e) {
      _showErrorSnackBar('Failed to block contact: $e');
    }
  }

  // Remove contact with feedback
  Future<void> _removeContact(UserModel contact) async {
    try {
      await ref.read(contactsNotifierProvider.notifier).removeContact(contact);
      _updateFilteredContacts();
      _showSuccessSnackBar('${contact.name} removed');
    } catch (e) {
      _showErrorSnackBar('Failed to remove contact: $e');
    }
  }

  // Confirmation dialog with modern design
  Future<bool> _showConfirmationDialog({
    required String title,
    required String content,
    required String action,
  }) async {
    final theme = context.modernTheme;
    
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: theme.surfaceColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(title, style: TextStyle(color: theme.textColor, fontWeight: FontWeight.w700)),
        content: Text(content, style: TextStyle(color: theme.textSecondaryColor)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Cancel', style: TextStyle(color: theme.textSecondaryColor)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: Text(action),
          ),
        ],
      ),
    );
    return result ?? false;
  }

  // Enhanced invite item with modern design
  Widget _buildOptimizedInviteItem(Contact contact, int index) {
    final theme = context.modernTheme;
    
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
      decoration: BoxDecoration(
        color: theme.surfaceColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: theme.dividerColor!.withOpacity(0.15),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: theme.primaryColor!.withOpacity(0.08),
            blurRadius: 20,
            offset: const Offset(0, 4),
            spreadRadius: -4,
          ),
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 2),
            spreadRadius: -2,
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _showContactDetailsSheet(contact),
          borderRadius: BorderRadius.circular(16),
          child: Container(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                // Enhanced Contact Avatar
                Container(
                  width: 52,
                  height: 52,
                  padding: const EdgeInsets.all(2),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: theme.dividerColor!.withOpacity(0.2),
                      width: 1,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: theme.primaryColor!.withOpacity(0.15),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: CircleAvatar(
                    radius: 24,
                    backgroundColor: theme.surfaceVariantColor!.withOpacity(0.7),
                    child: Text(
                      contact.displayName.isNotEmpty 
                          ? contact.displayName[0].toUpperCase() 
                          : '?',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: theme.textSecondaryColor,
                      ),
                    ),
                  ),
                ),
                
                const SizedBox(width: 12),
                
                // Enhanced Contact Info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Contact name
                      Text(
                        contact.displayName,
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: theme.textColor,
                          letterSpacing: -0.2,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      
                      const SizedBox(height: 4),
                      
                      // Phone number with enhanced styling
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.orange.withOpacity(0.08),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.phone_outlined,
                              size: 10,
                              color: Colors.orange.shade600,
                            ),
                            const SizedBox(width: 3),
                            Flexible(
                              child: Text(
                                contact.phones.isNotEmpty 
                                    ? contact.phones.first.number 
                                    : 'No phone number',
                                style: TextStyle(
                                  fontSize: 10,
                                  color: Colors.orange.shade600,
                                  fontWeight: FontWeight.w600,
                                ),
                                overflow: TextOverflow.ellipsis,
                                maxLines: 1,
                              ),
                            ),
                          ],
                        ),
                      ),
                      
                      const SizedBox(height: 4),
                      
                      // Not on WeiBao indicator
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: theme.surfaceVariantColor!.withOpacity(0.7),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.person_off_outlined,
                              size: 10,
                              color: theme.textSecondaryColor,
                            ),
                            const SizedBox(width: 3),
                            Text(
                              'Not on WeiBao',
                              style: TextStyle(
                                fontSize: 10,
                                color: theme.textSecondaryColor,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                
                const SizedBox(width: 8),
                
                // Enhanced Invite Button
                Material(
                  color: Colors.transparent,
                  borderRadius: BorderRadius.circular(14),
                  child: InkWell(
                    onTap: () {
                      HapticFeedback.lightImpact();
                      _shareInvitation(contact);
                    },
                    borderRadius: BorderRadius.circular(14),
                    child: Container(
                      constraints: const BoxConstraints(
                        minWidth: 80,
                        maxWidth: 100,
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: theme.primaryColor,
                        borderRadius: BorderRadius.circular(14),
                        boxShadow: [
                          BoxShadow(
                            color: theme.primaryColor!.withOpacity(0.3),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(2),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(3),
                            ),
                            child: const Icon(
                              Icons.share_rounded,
                              color: Colors.white,
                              size: 12,
                            ),
                          ),
                          const SizedBox(width: 4),
                          const Flexible(
                            child: Text(
                              'Invite',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 0.1,
                              ),
                              overflow: TextOverflow.ellipsis,
                              maxLines: 1,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Share invitation with error handling
  Future<void> _shareInvitation(Contact contact) async {
    try {
      final contactsNotifier = ref.read(contactsNotifierProvider.notifier);
      final message = contactsNotifier.generateInviteMessage();
      
      await Share.share(
        message,
        subject: 'Join me on WeiBao!',
      );
      
      _showSuccessSnackBar('Invitation sent to ${contact.displayName}');
    } catch (e) {
      _showErrorSnackBar('Failed to share invitation: $e');
    }
  }

  // Enhanced contact details sheet with modern design
  void _showContactDetailsSheet(Contact contact) {
    final theme = context.modernTheme;
    
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.5,
        minChildSize: 0.3,
        maxChildSize: 0.8,
        expand: false,
        builder: (context, scrollController) => Container(
          decoration: BoxDecoration(
            color: theme.surfaceColor,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 20,
                offset: const Offset(0, -5),
              ),
            ],
          ),
          child: Column(
            children: [
              // Handle bar
              Container(
                margin: const EdgeInsets.only(top: 12, bottom: 20),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: theme.textSecondaryColor?.withOpacity(0.4),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              
              Expanded(
                child: SingleChildScrollView(
                  controller: scrollController,
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Contact info header
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: theme.surfaceVariantColor!.withOpacity(0.3),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: theme.dividerColor!.withOpacity(0.15),
                            width: 1,
                          ),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 60,
                              height: 60,
                              decoration: BoxDecoration(
                                color: theme.surfaceVariantColor,
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: theme.primaryColor!.withOpacity(0.1),
                                    blurRadius: 8,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: Center(
                                child: Text(
                                  contact.displayName.isNotEmpty 
                                      ? contact.displayName[0].toUpperCase() 
                                      : '?',
                                  style: TextStyle(
                                    fontSize: 24,
                                    fontWeight: FontWeight.w700,
                                    color: theme.textSecondaryColor,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    contact.displayName,
                                    style: TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.w700,
                                      color: theme.textColor,
                                      letterSpacing: -0.3,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: Colors.orange.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Text(
                                      'Not on WeiBao',
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                        color: Colors.orange.shade600,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      
                      const SizedBox(height: 24),
                      
                      // Phone numbers section
                      if (contact.phones.isNotEmpty) ...[
                        Text(
                          'Phone Numbers',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: theme.textColor,
                            letterSpacing: -0.2,
                          ),
                        ),
                        const SizedBox(height: 12),
                        ...contact.phones.map((phone) => Container(
                          margin: const EdgeInsets.only(bottom: 8),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: theme.surfaceVariantColor!.withOpacity(0.3),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: theme.dividerColor!.withOpacity(0.15),
                              width: 1,
                            ),
                          ),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: theme.primaryColor!.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Icon(
                                  Icons.phone_rounded,
                                  color: theme.primaryColor,
                                  size: 16,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      phone.number,
                                      style: TextStyle(
                                        fontSize: 15,
                                        fontWeight: FontWeight.w600,
                                        color: theme.textColor,
                                      ),
                                    ),
                                    Text(
                                      phone.label.name.toUpperCase(),
                                      style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w500,
                                        color: theme.textSecondaryColor,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        )),
                        const SizedBox(height: 24),
                      ],
                      
                      // Actions section
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: theme.surfaceVariantColor!.withOpacity(0.3),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: theme.dividerColor!.withOpacity(0.15),
                            width: 1,
                          ),
                        ),
                        child: Column(
                          children: [
                            // Invite button
                            Material(
                              color: Colors.transparent,
                              borderRadius: BorderRadius.circular(14),
                              child: InkWell(
                                onTap: () async {
                                  Navigator.pop(context);
                                  await _shareInvitation(contact);
                                },
                                borderRadius: BorderRadius.circular(14),
                                child: Container(
                                  width: double.infinity,
                                  padding: const EdgeInsets.symmetric(vertical: 16),
                                  decoration: BoxDecoration(
                                    color: theme.primaryColor,
                                    borderRadius: BorderRadius.circular(14),
                                    boxShadow: [
                                      BoxShadow(
                                        color: theme.primaryColor!.withOpacity(0.3),
                                        blurRadius: 8,
                                        offset: const Offset(0, 2),
                                      ),
                                    ],
                                  ),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.all(4),
                                        decoration: BoxDecoration(
                                          color: Colors.white.withOpacity(0.2),
                                          borderRadius: BorderRadius.circular(4),
                                        ),
                                        child: const Icon(
                                          Icons.share_rounded,
                                          color: Colors.white,
                                          size: 16,
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      const Text(
                                        'Invite to WeiBao',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 16,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                            
                            const SizedBox(height: 12),
                            
                            // Close button
                            Material(
                              color: Colors.transparent,
                              borderRadius: BorderRadius.circular(14),
                              child: InkWell(
                                onTap: () => Navigator.pop(context),
                                borderRadius: BorderRadius.circular(14),
                                child: Container(
                                  width: double.infinity,
                                  padding: const EdgeInsets.symmetric(vertical: 16),
                                  decoration: BoxDecoration(
                                    color: theme.surfaceVariantColor,
                                    borderRadius: BorderRadius.circular(14),
                                    border: Border.all(
                                      color: theme.dividerColor!.withOpacity(0.3),
                                      width: 1,
                                    ),
                                  ),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(
                                        Icons.close_rounded,
                                        color: theme.textSecondaryColor,
                                        size: 16,
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        'Close',
                                        style: TextStyle(
                                          color: theme.textSecondaryColor,
                                          fontSize: 16,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      
                      const SizedBox(height: 20),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Helper methods for notifications
  void _showSuccessSnackBar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  void _showErrorSnackBar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 3),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    _searchFocusNode.dispose();
    _contactsScrollController.dispose();
    _invitesScrollController.dispose();
    _refreshAnimationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context); // Required for AutomaticKeepAliveClientMixin
    
    final theme = context.modernTheme;
    
    return Scaffold(
      backgroundColor: theme.surfaceColor,
      body: SafeArea(
        child: Column(
          children: [
            // Enhanced Custom App Bar matching channels screen
            Container(
              margin: const EdgeInsets.fromLTRB(16, 8, 16, 12),
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
              decoration: BoxDecoration(
                color: theme.surfaceColor,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: theme.dividerColor!.withOpacity(0.15),
                  width: 1,
                ),
                boxShadow: [
                  BoxShadow(
                    color: theme.primaryColor!.withOpacity(0.08),
                    blurRadius: 20,
                    offset: const Offset(0, 4),
                    spreadRadius: -4,
                  ),
                  BoxShadow(
                    color: Colors.black.withOpacity(0.04),
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                    spreadRadius: -2,
                  ),
                ],
              ),
              child: Row(
                children: [
                  // Enhanced Back Button
                  Material(
                    color: Colors.transparent,
                    borderRadius: BorderRadius.circular(12),
                    child: InkWell(
                      onTap: () {
                        HapticFeedback.lightImpact();
                        Navigator.pop(context);
                      },
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: theme.primaryColor!.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          Icons.arrow_back_rounded,
                          color: theme.primaryColor,
                          size: 20,
                        ),
                      ),
                    ),
                  ),
                  
                  // Enhanced Title
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Column(
                        children: [
                          Text(
                            _isSearching ? 'Search Contacts' : 'Contacts',
                            style: TextStyle(
                              color: theme.textColor,
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                              letterSpacing: -0.3,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 2),
                          Container(
                            height: 2,
                            width: 60,
                            decoration: BoxDecoration(
                              color: theme.primaryColor!.withOpacity(0.3),
                              borderRadius: BorderRadius.circular(1),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  
                  // Enhanced Search Button
                  if (!_isSearching)
                    Material(
                      color: Colors.transparent,
                      borderRadius: BorderRadius.circular(12),
                      child: InkWell(
                        onTap: () {
                          HapticFeedback.lightImpact();
                          setState(() {
                            _isSearching = true;
                          });
                          _searchFocusNode.requestFocus();
                        },
                        borderRadius: BorderRadius.circular(12),
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: theme.primaryColor!.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(
                            Icons.search_rounded,
                            color: theme.primaryColor,
                            size: 20,
                          ),
                        ),
                      ),
                    ),
                  
                  // Enhanced Clear Search Button
                  if (_isSearching)
                    Material(
                      color: Colors.transparent,
                      borderRadius: BorderRadius.circular(12),
                      child: InkWell(
                        onTap: () {
                          HapticFeedback.lightImpact();
                          setState(() {
                            _searchController.clear();
                            _searchQuery = '';
                            _isSearching = false;
                          });
                          _updateFilteredContacts();
                        },
                        borderRadius: BorderRadius.circular(12),
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.red.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(
                            Icons.clear_rounded,
                            color: Colors.red,
                            size: 20,
                          ),
                        ),
                      ),
                    ),
                  
                  const SizedBox(width: 8),
                  
                  // Enhanced Menu Button
                  Material(
                    color: Colors.transparent,
                    borderRadius: BorderRadius.circular(12),
                    child: InkWell(
                      onTap: () {
                        HapticFeedback.lightImpact();
                        _showMenuOptions();
                      },
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: theme.primaryColor!.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: RotationTransition(
                          turns: _refreshAnimation,
                          child: Icon(
                            Icons.more_vert_rounded,
                            color: theme.primaryColor,
                            size: 20,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            
            // Search Field (when active)
            if (_isSearching)
              Container(
                margin: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                decoration: BoxDecoration(
                  color: theme.surfaceColor,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: theme.primaryColor!.withOpacity(0.3),
                    width: 1,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: theme.primaryColor!.withOpacity(0.1),
                      blurRadius: 12,
                      offset: const Offset(0, 2),
                      spreadRadius: -2,
                    ),
                  ],
                ),
                child: TextField(
                  controller: _searchController,
                  focusNode: _searchFocusNode,
                  decoration: InputDecoration(
                    hintText: 'Search contacts...',
                    border: InputBorder.none,
                    hintStyle: TextStyle(color: theme.textSecondaryColor),
                    prefixIcon: Icon(
                      Icons.search_rounded,
                      color: theme.primaryColor,
                      size: 20,
                    ),
                  ),
                  style: TextStyle(color: theme.textColor),
                ),
              ),
            
            // Enhanced Tab Bar
            Container(
              margin: const EdgeInsets.fromLTRB(16, 8, 16, 8),
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
              decoration: BoxDecoration(
                color: theme.surfaceColor,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: theme.dividerColor!.withOpacity(0.15),
                  width: 1,
                ),
                boxShadow: [
                  BoxShadow(
                    color: theme.primaryColor!.withOpacity(0.08),
                    blurRadius: 20,
                    offset: const Offset(0, 4),
                    spreadRadius: -4,
                  ),
                  BoxShadow(
                    color: Colors.black.withOpacity(0.04),
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                    spreadRadius: -2,
                  ),
                ],
              ),
              child: TabBar(
                controller: _tabController,
                dividerColor: Colors.transparent,
                indicator: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  border: Border(
                    bottom: BorderSide(
                      color: theme.primaryColor!,
                      width: 3,
                    ),
                  ),
                ),
                labelColor: theme.primaryColor,
                unselectedLabelColor: theme.textSecondaryColor,
                labelStyle: const TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 14,
                  letterSpacing: 0.1,
                ),
                unselectedLabelStyle: const TextStyle(
                  fontWeight: FontWeight.w500,
                  fontSize: 14,
                ),
                tabs: [
                  Tab(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.people_rounded, size: 16),
                        const SizedBox(width: 6),
                        const Text('Contacts'),
                      ],
                    ),
                  ),
                  Tab(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.person_add_rounded, size: 16),
                        const SizedBox(width: 6),
                        const Text('Invites'),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            
            // Tab Content
            Expanded(
              child: Container(
                color: theme.surfaceColor,
                child: Consumer(
                  builder: (context, ref, child) {
                    final contactsState = ref.watch(contactsNotifierProvider);
                    
                    return contactsState.when(
                      data: (state) {
                        // Handle permission denied
                        if (state.syncStatus == SyncStatus.permissionDenied) {
                          return _buildPermissionScreen();
                        }
                        
                        // Update filtered contacts when state changes
                        WidgetsBinding.instance.addPostFrameCallback((_) {
                          _updateFilteredContacts();
                        });
                        
                        return TabBarView(
                          controller: _tabController,
                          children: [
                            _buildContactsTab(state),
                            _buildInvitesTab(state),
                          ],
                        );
                      },
                      loading: () => Container(
                        color: theme.surfaceColor,
                        child: Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              CircularProgressIndicator(
                                color: theme.primaryColor,
                                strokeWidth: 3,
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'Loading contacts...',
                                style: TextStyle(
                                  color: theme.textSecondaryColor,
                                  fontSize: 16,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      error: (error, stackTrace) => Container(
                        color: theme.surfaceColor,
                        child: Center(
                          child: Padding(
                            padding: const EdgeInsets.all(24),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.error_outline_rounded,
                                  size: 64,
                                  color: theme.textTertiaryColor,
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  'Unable to load contacts',
                                  style: TextStyle(
                                    color: theme.textColor,
                                    fontSize: 18,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  error.toString(),
                                  style: TextStyle(
                                    color: theme.textSecondaryColor,
                                    fontSize: 14,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                                const SizedBox(height: 20),
                                ElevatedButton.icon(
                                  onPressed: _forceSyncContacts,
                                  icon: const Icon(Icons.refresh_rounded),
                                  label: const Text('Try Again'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: theme.primaryColor,
                                    foregroundColor: Colors.white,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 24,
                                      vertical: 12,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          HapticFeedback.lightImpact();
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const AddContactScreen(),
            ),
          ).then((_) => _updateFilteredContacts());
        },
        backgroundColor: theme.primaryColor,
        foregroundColor: Colors.white,
        elevation: 8,
        child: const Icon(Icons.person_add_rounded),
      ),
    );
  }

  void _showMenuOptions() {
    final theme = context.modernTheme;
    
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: theme.surfaceColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 20,
              offset: const Offset(0, -5),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle bar
            Container(
              margin: const EdgeInsets.only(top: 12, bottom: 20),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: theme.textSecondaryColor?.withOpacity(0.4),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            
            _buildActionTile(
              icon: Icons.sync_rounded,
              title: 'Sync contacts',
              onTap: () {
                Navigator.pop(context);
                _forceSyncContacts();
              },
              theme: theme,
            ),
            _buildActionTile(
              icon: Icons.block_rounded,
              title: 'Blocked contacts',
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const BlockedContactsScreen(),
                  ),
                );
              },
              theme: theme,
            ),
            _buildActionTile(
              icon: Icons.clear_all_rounded,
              title: 'Clear cache',
              onTap: () {
                Navigator.pop(context);
                _clearCache();
              },
              theme: theme,
            ),
            _buildActionTile(
              icon: Icons.settings_rounded,
              title: 'Contact settings',
              onTap: () {
                Navigator.pop(context);
                _showErrorSnackBar('Contact settings coming soon');
              },
              theme: theme,
            ),
            
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Future<void> _clearCache() async {
    final confirmed = await _showConfirmationDialog(
      title: 'Clear Cache',
      content: 'This will clear all cached contact data and force a fresh sync.',
      action: 'Clear',
    );
    
    if (confirmed) {
      try {
        await ref.read(contactsNotifierProvider.notifier).clearCache();
        _showSuccessSnackBar('Cache cleared');
        await _initializeContacts();
      } catch (e) {
        _showErrorSnackBar('Failed to clear cache: $e');
      }
    }
  }

  Widget _buildContactsTab(ContactsState state) {
    final theme = context.modernTheme;
    
    if (state.isLoading && _isInitializing) {
      return Container(
        color: theme.surfaceColor,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(
                color: theme.primaryColor,
                strokeWidth: 3,
              ),
              const SizedBox(height: 16),
              Text(
                'Loading contacts...',
                style: TextStyle(
                  color: theme.textSecondaryColor,
                  fontSize: 16,
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (_filteredRegisteredContacts.isEmpty && !state.isLoading) {
      return _buildEmptyContactsState();
    }

    return Container(
      color: theme.surfaceColor,
      child: RefreshIndicator(
        key: _refreshIndicatorKey,
        onRefresh: _forceSyncContacts,
        color: theme.primaryColor,
        child: Column(
          children: [
            _buildSyncStatusIndicator(state),
            Expanded(
              child: ListView.separated(
                controller: _contactsScrollController,
                padding: const EdgeInsets.all(16),
                itemCount: _filteredRegisteredContacts.length,
                separatorBuilder: (context, index) => const SizedBox(height: 8),
                itemBuilder: (context, index) {
                  final contact = _filteredRegisteredContacts[index];
                  return _buildOptimizedContactItem(contact, index);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInvitesTab(ContactsState state) {
    final theme = context.modernTheme;
    
    if (state.isLoading && _isInitializing) {
      return Container(
        color: theme.surfaceColor,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(
                color: theme.primaryColor,
                strokeWidth: 3,
              ),
              const SizedBox(height: 16),
              Text(
                'Loading contacts...',
                style: TextStyle(
                  color: theme.textSecondaryColor,
                  fontSize: 16,
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (_filteredUnregisteredContacts.isEmpty && !state.isLoading) {
      return _buildEmptyInvitesState();
    }

    return Container(
      color: theme.surfaceColor,
      child: RefreshIndicator(
        onRefresh: _forceSyncContacts,
        color: theme.primaryColor,
        child: Column(
          children: [
            _buildSyncStatusIndicator(state),
            Expanded(
              child: ListView.separated(
                controller: _invitesScrollController,
                padding: const EdgeInsets.all(16),
                itemCount: _filteredUnregisteredContacts.length,
                separatorBuilder: (context, index) => const SizedBox(height: 8),
                itemBuilder: (context, index) {
                  final contact = _filteredUnregisteredContacts[index];
                  return _buildOptimizedInviteItem(contact, index);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyContactsState() {
    final theme = context.modernTheme;
    
    return Container(
      color: theme.surfaceColor,
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: theme.primaryColor!.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  CupertinoIcons.person_2,
                  size: 64,
                  color: theme.primaryColor,
                ),
              ),
              const SizedBox(height: 24),
              Text(
                _searchQuery.isEmpty ? 'No contacts found' : 'No matching contacts',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: theme.textColor,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                _searchQuery.isEmpty 
                  ? 'Your contacts will appear here when synced'
                  : 'Try a different search term',
                style: TextStyle(
                  fontSize: 15,
                  color: theme.textSecondaryColor,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              if (_searchQuery.isEmpty)
                ElevatedButton.icon(
                  onPressed: _forceSyncContacts,
                  icon: const Icon(Icons.sync_rounded),
                  label: const Text('Sync Contacts'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: theme.primaryColor,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 12,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyInvitesState() {
    final theme = context.modernTheme;
    
    return Container(
      color: theme.surfaceColor,
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.orange.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  CupertinoIcons.person_badge_plus,
                  size: 64,
                  color: Colors.orange.shade600,
                ),
              ),
              const SizedBox(height: 24),
              Text(
                _searchQuery.isEmpty ? 'No contacts to invite' : 'No matching contacts',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: theme.textColor,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                _searchQuery.isEmpty 
                  ? 'Contacts not using WeiBao will appear here'
                  : 'Try a different search term',
                style: TextStyle(
                  fontSize: 15,
                  color: theme.textSecondaryColor,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              if (_searchQuery.isEmpty)
                ElevatedButton.icon(
                  onPressed: _forceSyncContacts,
                  icon: const Icon(Icons.refresh_rounded),
                  label: const Text('Refresh Contacts'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange.shade600,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 12,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}