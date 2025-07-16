// Enhanced contacts_screen.dart with performance optimizations
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_contacts/flutter_contacts.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:textgb/constants.dart';
import 'package:textgb/features/contacts/providers/contacts_provider.dart';
import 'package:textgb/features/chat/providers/chat_provider.dart';
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

  // Optimized chat starting
  void _startChatWithContact(UserModel contact) async {
    try {
      // Show loading indicator for immediate feedback
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(
          child: CircularProgressIndicator(),
        ),
      );

      final chatNotifier = ref.read(chatProvider.notifier);
      final chatId = chatNotifier.getChatIdForContact(contact.uid);
      
      await chatNotifier.createChat(contact);
      
      if (mounted) {
        Navigator.pop(context); // Close loading dialog
        Navigator.pushNamed(
          context,
          Constants.chatScreen,
          arguments: {
            'chatId': chatId,
            'contact': contact,
          },
        );
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context); // Close loading dialog
        _showErrorSnackBar('Error starting chat: $e');
      }
    }
  }

  // Enhanced sync status display
  Widget _buildSyncStatusIndicator(ContactsState state) {
    if (state.lastSyncTime == null) return const SizedBox.shrink();
    
    final formatter = DateFormat('MMM d, h:mm a');
    final syncTime = formatter.format(state.lastSyncTime!);
    final modernTheme = context.modernTheme;
    
    Color statusColor;
    IconData statusIcon;
    String statusText;
    
    switch (state.syncStatus) {
      case SyncStatus.upToDate:
        statusColor = Colors.green;
        statusIcon = Icons.check_circle;
        statusText = 'Up to date';
        break;
      case SyncStatus.stale:
        statusColor = Colors.orange;
        statusIcon = Icons.update;
        statusText = 'Update available';
        break;
      case SyncStatus.backgroundSyncing:
        statusColor = Colors.blue;
        statusIcon = Icons.sync;
        statusText = 'Syncing...';
        break;
      case SyncStatus.failed:
        statusColor = Colors.red;
        statusIcon = Icons.error;
        statusText = 'Sync failed';
        break;
      default:
        statusColor = Colors.grey;
        statusIcon = Icons.help;
        statusText = 'Unknown';
    }
    
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      color: modernTheme.surfaceColor,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(statusIcon, size: 16, color: statusColor),
          const SizedBox(width: 8),
          Text(
            '$statusText • Last synced: $syncTime',
            style: TextStyle(
              fontSize: 12,
              color: modernTheme.textSecondaryColor,
            ),
          ),
          if (state.backgroundSyncAvailable) ...[
            const SizedBox(width: 8),
            GestureDetector(
              onTap: _forceSyncContacts,
              child: Icon(
                Icons.refresh,
                size: 16,
                color: modernTheme.primaryColor,
              ),
            ),
          ],
        ],
      ),
    );
  }

  // Permission request UI
  Widget _buildPermissionScreen() {
    final modernTheme = context.modernTheme;
    
    return Container(
      color: modernTheme.surfaceColor,
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.contacts,
                size: 100,
                color: modernTheme.textSecondaryColor?.withOpacity(0.5),
              ),
              const SizedBox(height: 24),
              Text(
                'Contacts Access Required',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: modernTheme.textColor,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              Text(
                'To sync your contacts and find friends on TexGB, we need access to your contacts.',
                style: TextStyle(
                  fontSize: 16,
                  color: modernTheme.textSecondaryColor,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              ElevatedButton.icon(
                onPressed: () async {
                  final contactsNotifier = ref.read(contactsNotifierProvider.notifier);
                  await contactsNotifier.requestPermission();
                },
                icon: const Icon(Icons.security),
                label: const Text('Grant Permission'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: modernTheme.primaryColor,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 32,
                    vertical: 16,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Optimized contact item with clean list design
  Widget _buildOptimizedContactItem(UserModel contact, int index) {
    final modernTheme = context.modernTheme;
    
    return Container(
      color: modernTheme.surfaceColor,
      child: ListTile(
        key: ValueKey(contact.uid),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        leading: _buildCachedAvatar(contact),
        title: Text(
          contact.name,
          style: TextStyle(
            fontWeight: FontWeight.w600,
            color: modernTheme.textColor,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Text(
          contact.phoneNumber,
          style: TextStyle(
            color: modernTheme.textSecondaryColor,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        trailing: _buildContactActions(contact),
        onTap: () => _startChatWithContact(contact),
      ),
    );
  }

  // Cached avatar widget for better performance
  Widget _buildCachedAvatar(UserModel contact) {
    final modernTheme = context.modernTheme;
    
    if (contact.image.isEmpty) {
      return CircleAvatar(
        radius: 24,
        backgroundColor: modernTheme.primaryColor,
        child: Text(
          contact.name.isNotEmpty ? contact.name[0].toUpperCase() : '?',
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
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
        backgroundColor: modernTheme.surfaceVariantColor,
        child: const CircularProgressIndicator(strokeWidth: 2),
      ),
      errorWidget: (context, url, error) => CircleAvatar(
        radius: 24,
        backgroundColor: modernTheme.primaryColor,
        child: Text(
          contact.name.isNotEmpty ? contact.name[0].toUpperCase() : '?',
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  // Contact actions with better UX
  Widget _buildContactActions(UserModel contact) {
    final modernTheme = context.modernTheme;
    
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          icon: Icon(
            CupertinoIcons.chat_bubble_text,
            color: modernTheme.textSecondaryColor,
          ),
          onPressed: () => _startChatWithContact(contact),
          tooltip: 'Message',
        ),
        PopupMenuButton<String>(
          icon: Icon(
            Icons.more_vert,
            color: modernTheme.textSecondaryColor,
          ),
          color: modernTheme.surfaceColor,
          onSelected: (value) => _handleContactAction(value, contact),
          itemBuilder: (context) => [
            PopupMenuItem<String>(
              value: 'info',
              child: Row(
                children: [
                  Icon(Icons.info_outline, color: modernTheme.textSecondaryColor),
                  const SizedBox(width: 10),
                  Text('Contact info', style: TextStyle(color: modernTheme.textColor)),
                ],
              ),
            ),
            PopupMenuItem<String>(
              value: 'block',
              child: Row(
                children: [
                  const Icon(Icons.block, color: Colors.red),
                  const SizedBox(width: 10),
                  Text('Block contact', style: TextStyle(color: Colors.red)),
                ],
              ),
            ),
            PopupMenuItem<String>(
              value: 'remove',
              child: Row(
                children: [
                  const Icon(Icons.delete_outline, color: Colors.red),
                  const SizedBox(width: 10),
                  Text('Remove contact', style: TextStyle(color: Colors.red)),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  // Handle contact actions with confirmations
  Future<void> _handleContactAction(String action, UserModel contact) async {
    switch (action) {
      case 'info':
        Navigator.pushNamed(
          context,
          Constants.contactProfileScreen,
          arguments: contact,
        );
        break;
      case 'block':
        final confirmed = await _showConfirmationDialog(
          title: 'Block Contact',
          content: 'Are you sure you want to block ${contact.name}?',
          action: 'Block',
        );
        if (confirmed) {
          await _blockContact(contact);
        }
        break;
      case 'remove':
        final confirmed = await _showConfirmationDialog(
          title: 'Remove Contact',
          content: 'Are you sure you want to remove ${contact.name}?',
          action: 'Remove',
        );
        if (confirmed) {
          await _removeContact(contact);
        }
        break;
    }
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

  // Confirmation dialog
  Future<bool> _showConfirmationDialog({
    required String title,
    required String content,
    required String action,
  }) async {
    final modernTheme = context.modernTheme;
    
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: modernTheme.surfaceColor,
        title: Text(title, style: TextStyle(color: modernTheme.textColor)),
        content: Text(content, style: TextStyle(color: modernTheme.textSecondaryColor)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Cancel', style: TextStyle(color: modernTheme.textSecondaryColor)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: Text(action),
          ),
        ],
      ),
    );
    return result ?? false;
  }

  // Enhanced invite item with clean list design
  Widget _buildOptimizedInviteItem(Contact contact, int index) {
    final modernTheme = context.modernTheme;
    
    return Container(
      color: modernTheme.surfaceColor,
      child: ListTile(
        key: ValueKey(contact.id),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        leading: CircleAvatar(
          radius: 24,
          backgroundColor: modernTheme.surfaceVariantColor,
          child: Text(
            contact.displayName.isNotEmpty 
                ? contact.displayName[0].toUpperCase() 
                : '?',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: modernTheme.textSecondaryColor,
            ),
          ),
        ),
        title: Text(
          contact.displayName,
          style: TextStyle(
            fontWeight: FontWeight.w600,
            color: modernTheme.textColor,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Text(
          contact.phones.isNotEmpty 
              ? contact.phones.first.number 
              : 'No phone number',
          style: TextStyle(
            color: modernTheme.textSecondaryColor,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        trailing: _buildInviteButton(contact),
        onTap: () => _showContactDetailsSheet(contact),
      ),
    );
  }

  // Invite button with loading state
  Widget _buildInviteButton(Contact contact) {
    final modernTheme = context.modernTheme;
    
    return ElevatedButton(
      onPressed: () => _shareInvitation(contact),
      style: ElevatedButton.styleFrom(
        foregroundColor: Colors.white,
        backgroundColor: modernTheme.primaryColor,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      ),
      child: const Text('Invite'),
    );
  }

  // Share invitation with error handling
  Future<void> _shareInvitation(Contact contact) async {
    try {
      final contactsNotifier = ref.read(contactsNotifierProvider.notifier);
      final message = contactsNotifier.generateInviteMessage();
      
      await Share.share(
        message,
        subject: 'Join me on TexGB!',
      );
    } catch (e) {
      _showErrorSnackBar('Failed to share invitation: $e');
    }
  }

  // Enhanced contact details sheet
  void _showContactDetailsSheet(Contact contact) {
    final modernTheme = context.modernTheme;
    
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: modernTheme.surfaceColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.4,
        minChildSize: 0.3,
        maxChildSize: 0.8,
        expand: false,
        builder: (context, scrollController) => Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: modernTheme.surfaceColor,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Handle bar
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: modernTheme.textSecondaryColor?.withOpacity(0.4),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              
              // Contact info
              Row(
                children: [
                  CircleAvatar(
                    radius: 30,
                    backgroundColor: modernTheme.surfaceVariantColor,
                    child: Text(
                      contact.displayName.isNotEmpty 
                          ? contact.displayName[0].toUpperCase() 
                          : '?',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: modernTheme.textSecondaryColor,
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
                            fontWeight: FontWeight.bold,
                            color: modernTheme.textColor,
                          ),
                        ),
                        if (contact.phones.isNotEmpty)
                          Text(
                            contact.phones.first.number,
                            style: TextStyle(
                              fontSize: 16,
                              color: modernTheme.textSecondaryColor,
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 24),
              
              // Phone numbers
              if (contact.phones.isNotEmpty) ...[
                Text(
                  'Phone Numbers',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: modernTheme.textColor,
                  ),
                ),
                const SizedBox(height: 8),
                ...contact.phones.map((phone) => ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Icon(Icons.phone, color: modernTheme.primaryColor),
                  title: Text(phone.number, style: TextStyle(color: modernTheme.textColor)),
                  subtitle: Text(phone.label.name.toUpperCase(), style: TextStyle(color: modernTheme.textSecondaryColor)),
                )),
                const SizedBox(height: 16),
              ],
              
              // Actions
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () async {
                        Navigator.pop(context);
                        await _shareInvitation(contact);
                      },
                      icon: const Icon(Icons.share),
                      label: const Text('Invite to TexGB'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: modernTheme.primaryColor,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => Navigator.pop(context),
                      icon: Icon(Icons.close, color: modernTheme.textSecondaryColor),
                      label: Text('Close', style: TextStyle(color: modernTheme.textSecondaryColor)),
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(color: modernTheme.dividerColor!),
                      ),
                    ),
                  ),
                ],
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
      ),
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    _searchFocusNode.dispose();
    _refreshAnimationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context); // Required for AutomaticKeepAliveClientMixin
    
    final modernTheme = context.modernTheme;
    
    return Scaffold(
      backgroundColor: modernTheme.surfaceColor,
      appBar: AppBar(
        backgroundColor: modernTheme.surfaceColor,
        elevation: 0,
        title: _isSearching ? _buildSearchField() : Text('Contacts', style: TextStyle(color: modernTheme.textColor)),
        iconTheme: IconThemeData(color: modernTheme.textColor),
        actions: _buildAppBarActions(),
        bottom: TabBar(
          controller: _tabController,
          labelColor: modernTheme.primaryColor,
          unselectedLabelColor: modernTheme.textSecondaryColor,
          indicatorColor: modernTheme.primaryColor,
          tabs: const [
            Tab(text: 'Contacts'),
            Tab(text: 'Invites'),
          ],
        ),
      ),
      body: Consumer(
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
              
              return Container(
                color: modernTheme.surfaceColor,
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    _buildContactsTab(state),
                    _buildInvitesTab(state),
                  ],
                ),
              );
            },
            loading: () => Container(
              color: modernTheme.surfaceColor,
              child: Center(
                child: CircularProgressIndicator(color: modernTheme.primaryColor),
              ),
            ),
            error: (error, stackTrace) => Container(
              color: modernTheme.surfaceColor,
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.error_outline,
                      size: 64,
                      color: Colors.red.shade300,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Error loading contacts',
                      style: TextStyle(
                        color: modernTheme.textColor,
                        fontSize: 18,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      error.toString(),
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: modernTheme.textSecondaryColor,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton.icon(
                      onPressed: _forceSyncContacts,
                      icon: const Icon(Icons.refresh),
                      label: const Text('Retry'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: modernTheme.primaryColor,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const AddContactScreen(),
            ),
          ).then((_) => _updateFilteredContacts());
        },
        backgroundColor: modernTheme.primaryColor,
        foregroundColor: Colors.white,
        child: const Icon(Icons.person_add),
      ),
    );
  }

  List<Widget> _buildAppBarActions() {
    final modernTheme = context.modernTheme;
    
    return [
      if (!_isSearching)
        IconButton(
          icon: Icon(Icons.search, color: modernTheme.textColor),
          onPressed: () {
            setState(() {
              _isSearching = true;
            });
            _searchFocusNode.requestFocus();
          },
        ),
      if (_isSearching)
        IconButton(
          icon: Icon(Icons.clear, color: modernTheme.textColor),
          onPressed: () {
            setState(() {
              _searchController.clear();
              _searchQuery = '';
              _isSearching = false;
            });
            _updateFilteredContacts();
          },
        ),
      PopupMenuButton<String>(
        icon: RotationTransition(
          turns: _refreshAnimation,
          child: Icon(Icons.more_vert, color: modernTheme.textColor),
        ),
        color: modernTheme.surfaceColor,
        onSelected: _handleMenuAction,
        itemBuilder: (context) => [
          PopupMenuItem<String>(
            value: 'refresh',
            child: Row(
              children: [
                Icon(Icons.sync, color: modernTheme.textSecondaryColor),
                const SizedBox(width: 10),
                Text('Sync contacts', style: TextStyle(color: modernTheme.textColor)),
              ],
            ),
          ),
          PopupMenuItem<String>(
            value: 'blocked',
            child: Row(
              children: [
                Icon(Icons.block, color: modernTheme.textSecondaryColor),
                const SizedBox(width: 10),
                Text('Blocked contacts', style: TextStyle(color: modernTheme.textColor)),
              ],
            ),
          ),
          PopupMenuItem<String>(
            value: 'clear_cache',
            child: Row(
              children: [
                Icon(Icons.clear_all, color: modernTheme.textSecondaryColor),
                const SizedBox(width: 10),
                Text('Clear cache', style: TextStyle(color: modernTheme.textColor)),
              ],
            ),
          ),
          PopupMenuItem<String>(
            value: 'settings',
            child: Row(
              children: [
                Icon(Icons.settings, color: modernTheme.textSecondaryColor),
                const SizedBox(width: 10),
                Text('Contact settings', style: TextStyle(color: modernTheme.textColor)),
              ],
            ),
          ),
        ],
      ),
    ];
  }

  void _handleMenuAction(String value) {
    switch (value) {
      case 'refresh':
        _forceSyncContacts();
        break;
      case 'blocked':
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => const BlockedContactsScreen(),
          ),
        );
        break;
      case 'clear_cache':
        _clearCache();
        break;
      case 'settings':
        _showErrorSnackBar('Contact settings coming soon');
        break;
    }
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

  Widget _buildSearchField() {
    final modernTheme = context.modernTheme;
    
    return TextField(
      controller: _searchController,
      focusNode: _searchFocusNode,
      decoration: InputDecoration(
        hintText: 'Search contacts...',
        border: InputBorder.none,
        hintStyle: TextStyle(color: modernTheme.textSecondaryColor),
      ),
      style: TextStyle(color: modernTheme.textColor),
    );
  }

  Widget _buildContactsTab(ContactsState state) {
    final modernTheme = context.modernTheme;
    
    if (state.isLoading && _isInitializing) {
      return Container(
        color: modernTheme.surfaceColor,
        child: Center(
          child: CircularProgressIndicator(color: modernTheme.primaryColor),
        ),
      );
    }

    if (_filteredRegisteredContacts.isEmpty && !state.isLoading) {
      return _buildEmptyContactsState();
    }

    return Container(
      color: modernTheme.surfaceColor,
      child: RefreshIndicator(
        key: _refreshIndicatorKey,
        onRefresh: _forceSyncContacts,
        child: Column(
          children: [
            _buildSyncStatusIndicator(state),
            Expanded(
              child: ListView.builder(
                itemCount: _filteredRegisteredContacts.length,
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
    final modernTheme = context.modernTheme;
    
    if (state.isLoading && _isInitializing) {
      return Container(
        color: modernTheme.surfaceColor,
        child: Center(
          child: CircularProgressIndicator(color: modernTheme.primaryColor),
        ),
      );
    }

    if (_filteredUnregisteredContacts.isEmpty && !state.isLoading) {
      return _buildEmptyInvitesState();
    }

    return Container(
      color: modernTheme.surfaceColor,
      child: RefreshIndicator(
        onRefresh: _forceSyncContacts,
        child: Column(
          children: [
            _buildSyncStatusIndicator(state),
            Expanded(
              child: ListView.builder(
                itemCount: _filteredUnregisteredContacts.length,
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
    final modernTheme = context.modernTheme;
    
    return Container(
      color: modernTheme.surfaceColor,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              CupertinoIcons.person_2,
              size: 80,
              color: modernTheme.textSecondaryColor,
            ),
            const SizedBox(height: 16),
            Text(
              _searchQuery.isEmpty ? 'No contacts found' : 'No matching contacts',
              style: TextStyle(
                fontSize: 16,
                color: modernTheme.textColor,
              ),
            ),
            const SizedBox(height: 16),
            if (_searchQuery.isEmpty)
              ElevatedButton.icon(
                onPressed: _forceSyncContacts,
                icon: const Icon(Icons.sync),
                label: const Text('Sync Contacts'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: modernTheme.primaryColor,
                  foregroundColor: Colors.white,
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyInvitesState() {
    final modernTheme = context.modernTheme;
    
    return Container(
      color: modernTheme.surfaceColor,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              CupertinoIcons.person_badge_plus,
              size: 80,
              color: modernTheme.textSecondaryColor,
            ),
            const SizedBox(height: 16),
            Text(
              _searchQuery.isEmpty ? 'No contacts to invite' : 'No matching contacts',
              style: TextStyle(
                fontSize: 16,
                color: modernTheme.textColor,
              ),
            ),
            const SizedBox(height: 16),
            if (_searchQuery.isEmpty)
              ElevatedButton.icon(
                onPressed: _forceSyncContacts,
                icon: const Icon(Icons.refresh),
                label: const Text('Refresh Contacts'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: modernTheme.primaryColor,
                  foregroundColor: Colors.white,
                ),
              ),
          ],
        ),
      ),
    );
  }
}