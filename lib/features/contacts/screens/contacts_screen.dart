// lib/features/contacts/screens/contacts_screen.dart
// Updated with user profile images in the list
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_contacts/flutter_contacts.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:textgb/features/contacts/providers/contacts_provider.dart';
import 'package:textgb/features/contacts/screens/add_contact_screen.dart';
import 'package:textgb/features/contacts/screens/blocked_contacts_screen.dart';
import 'package:textgb/features/contacts/screens/contact_profile_screen.dart';
import 'package:textgb/features/contacts/widgets/contact_item_widget.dart';
import 'package:textgb/features/contacts/widgets/contacts_empty_states_widget.dart';
import 'package:textgb/features/users/models/user_model.dart';
import 'package:textgb/shared/theme/theme_extensions.dart';
import 'package:cached_network_image/cached_network_image.dart'; // Add this import for network images

class ContactsScreen extends ConsumerStatefulWidget {
  const ContactsScreen({super.key});

  @override
  ConsumerState<ContactsScreen> createState() => _ContactsScreenState();
}

class _ContactsScreenState extends ConsumerState<ContactsScreen> 
    with TickerProviderStateMixin, AutomaticKeepAliveClientMixin {
  
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  final ScrollController _contactsScrollController = ScrollController();
  
  String _searchQuery = '';
  bool _isSearching = false;
  bool _isInitializing = true;
  
  // Performance optimizations
  late AnimationController _refreshAnimationController;
  final GlobalKey<RefreshIndicatorState> _refreshIndicatorKey = GlobalKey();
  
  // Cached filtered lists for better performance
  List<UserModel> _filteredRegisteredContacts = [];
  List<Contact> _filteredUnregisteredContacts = [];
  
  @override
  bool get wantKeepAlive => true; // Keep state alive when switching tabs

  @override
  void initState() {
    super.initState();
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
  }

  void _setupListeners() {
    _searchController.addListener(_onSearchChanged);
    _searchFocusNode.addListener(_onSearchFocusChanged);
  }

  void _onSearchFocusChanged() {
    if (!_searchFocusNode.hasFocus && _searchController.text.isEmpty) {
      setState(() {
        _isSearching = false;
      });
    }
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

  void _dismissSearch() {
    _searchController.clear();
    _searchFocusNode.unfocus();
    setState(() {
      _isSearching = false;
      _searchQuery = '';
    });
    _updateFilteredContacts();
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
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ContactProfileScreen(contact: contact),
      ),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose();
    _contactsScrollController.dispose();
    _refreshAnimationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context); // Required for AutomaticKeepAliveClientMixin
    
    final theme = context.modernTheme;
    
    return GestureDetector(
      onTap: () {
        // Dismiss search when tapping outside
        if (_isSearching) {
          _dismissSearch();
        }
      },
      behavior: HitTestBehavior.opaque,
      child: Scaffold(
        backgroundColor: theme.surfaceColor,
        body: SafeArea(
          child: Column(
            children: [
              // WeChat-style Search Header
              _buildWeChatHeader(theme),
              
              // Main Contacts List
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
                            return ContactsEmptyStatesWidget.buildPermissionScreen(
                              context,
                              () async {
                                final contactsNotifier = ref.read(contactsNotifierProvider.notifier);
                                await contactsNotifier.requestPermission();
                              },
                            );
                          }
                          
                          // Update filtered contacts when state changes
                          WidgetsBinding.instance.addPostFrameCallback((_) {
                            _updateFilteredContacts();
                          });
                          
                          return _buildWeChatContactsList(state);
                        },
                        loading: () => ContactsEmptyStatesWidget.buildLoadingState(
                          context, 
                          'Loading contacts...'
                        ),
                        error: (error, stackTrace) => ContactsEmptyStatesWidget.buildErrorState(
                          context,
                          error.toString(),
                          _forceSyncContacts,
                        ),
                      );
                    },
                  ),
                ),
              ),
            ],
          ),
        ),
        /*floatingActionButton: FloatingActionButton(
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
          elevation: 4,
          child: const Icon(Icons.person_add_rounded, size: 24),
        ),*/
      ),
    );
  }

  Widget _buildWeChatHeader(theme) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
      color: theme.surfaceColor,
      child: Column(
        children: [
          // Search Field with clear button
          Stack(
            children: [
              Container(
                height: 36,
                decoration: BoxDecoration(
                  color: theme.surfaceColor!.withOpacity(0.6),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(
                    color: theme.dividerColor!.withOpacity(0.3),
                    width: 0.5,
                  ),
                ),
                child: TextField(
                  controller: _searchController,
                  focusNode: _searchFocusNode,
                  onTap: () {
                    setState(() {
                      _isSearching = true;
                    });
                  },
                  decoration: InputDecoration(
                    hintText: 'Search',
                    hintStyle: TextStyle(
                      color: theme.textSecondaryColor,
                      fontSize: 14,
                    ),
                    border: InputBorder.none,
                    prefixIcon: Icon(
                      Icons.search_rounded,
                      color: theme.textSecondaryColor,
                      size: 18,
                    ),
                    contentPadding: const EdgeInsets.symmetric(vertical: 8),
                  ),
                  style: TextStyle(
                    color: theme.textColor,
                    fontSize: 14,
                  ),
                ),
              ),
              
              // Clear search button (visible when searching)
              if (_isSearching && _searchController.text.isNotEmpty)
                Positioned(
                  right: 8,
                  top: 0,
                  bottom: 0,
                  child: GestureDetector(
                    onTap: _dismissSearch,
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: theme.textSecondaryColor!.withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.close_rounded,
                        color: theme.textSecondaryColor,
                        size: 14,
                      ),
                    ),
                  ),
                ),
            ],
          ),
          
          // Search dismissal hint (only shown when searching)
          if (_isSearching) ...[
            const SizedBox(height: 8),
            Text(
              'Tap anywhere outside to dismiss search',
              style: TextStyle(
                color: theme.textSecondaryColor,
                fontSize: 12,
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildWeChatContactsList(ContactsState state) {
    final theme = context.modernTheme;
    
    if (state.isLoading && _isInitializing) {
      return ContactsEmptyStatesWidget.buildLoadingState(
        context, 
        'Loading contacts...'
      );
    }

    // Combine registered and unregistered contacts for WeChat-style unified list
    final allContacts = [
      // Special sections like WeChat (only show when not searching)
      //if (!_isSearching) ..._buildSpecialSection(theme),
      // Registered contacts (friends)
      ..._buildRegisteredContactsSection(theme),
      // Unregistered contacts (invite suggestions)
      ..._buildUnregisteredContactsSection(theme),
    ];

    if (allContacts.isEmpty && !state.isLoading) {
      return ContactsEmptyStatesWidget.buildEmptyContactsState(
        context,
        _searchQuery,
        _forceSyncContacts,
      );
    }

    return Container(
      color: theme.surfaceColor,
      child: RefreshIndicator(
        key: _refreshIndicatorKey,
        onRefresh: _forceSyncContacts,
        color: theme.primaryColor,
        child: Column(
          children: [
            // Sync status indicator (minimal, only show when not searching)
            if (!_isSearching)
              ContactsEmptyStatesWidget.buildSyncStatusIndicator(
                context,
                state.lastSyncTime,
                state.syncStatus,
                state.backgroundSyncAvailable,
                _forceSyncContacts,
              ),
            Expanded(
              child: ListView.builder(
                controller: _contactsScrollController,
                padding: EdgeInsets.zero,
                itemCount: allContacts.length,
                itemBuilder: (context, index) => allContacts[index],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /*List<Widget> _buildSpecialSection(theme) {
    return [
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // New Friends
          _buildWeChatContactItem(
            icon: Icons.person_add_rounded,
            title: 'New Friends',
            subtitle: 'Add friends and accept requests',
            onTap: () {
              // Navigate to new friends screen
              _showComingSoonSnackBar('New Friends');
            },
            theme: theme,
            showDivider: true,
            isSpecialSection: true,
          ),
          // Group Chats
          _buildWeChatContactItem(
            icon: Icons.group_rounded,
            title: 'Group Chats',
            subtitle: 'Your group conversations',
            onTap: () {
              _showComingSoonSnackBar('Group Chats');
            },
            theme: theme,
            showDivider: true,
            isSpecialSection: true,
          ),
          // Tags
          _buildWeChatContactItem(
            icon: Icons.label_rounded,
            title: 'Tags',
            subtitle: 'Organize your contacts',
            onTap: () {
              _showComingSoonSnackBar('Tags');
            },
            theme: theme,
            showDivider: true,
            isSpecialSection: true,
          ),
          // Official Accounts
          _buildWeChatContactItem(
            icon: Icons.verified_rounded,
            title: 'Official Accounts',
            subtitle: 'Follow brands and services',
            onTap: () {
              _showComingSoonSnackBar('Official Accounts');
            },
            theme: theme,
            showDivider: false,
            isSpecialSection: true,
          ),
          // Section divider
          Container(
            height: 8,
            color: theme.dividerColor!.withOpacity(0.1),
          ),
        ],
      ),
    ];
  }*/

  List<Widget> _buildRegisteredContactsSection(theme) {
    if (_filteredRegisteredContacts.isEmpty) return [];

    // Group contacts by first letter for WeChat-style alphabetical index
    final Map<String, List<UserModel>> groupedContacts = {};
    
    for (final contact in _filteredRegisteredContacts) {
      final firstLetter = contact.name.isNotEmpty 
          ? contact.name[0].toUpperCase()
          : '#';
      if (!groupedContacts.containsKey(firstLetter)) {
        groupedContacts[firstLetter] = [];
      }
      groupedContacts[firstLetter]!.add(contact);
    }

    // Sort the groups alphabetically
    final sortedLetters = groupedContacts.keys.toList()..sort();

    final List<Widget> sections = [];

    for (final letter in sortedLetters) {
      final contactsInGroup = groupedContacts[letter]!..sort((a, b) => a.name.compareTo(b.name));
      
      // Add section header
      sections.add(
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          color: theme.surfaceColor!.withOpacity(0.6),
          child: Text(
            letter,
            style: TextStyle(
              color: theme.textSecondaryColor,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      );

      // Add contacts in this group
      for (int i = 0; i < contactsInGroup.length; i++) {
        final contact = contactsInGroup[i];
        final showDivider = i < contactsInGroup.length - 1;
        
        sections.add(
          _buildWeChatContactItem(
            title: contact.name,
            subtitle: contact.phoneNumber,
            onTap: () {
              _navigateToContactProfile(contact);
            },
            theme: theme,
            showDivider: showDivider,
            isContact: true,
            contact: contact,
            profileImageUrl: contact.profileImage, // Pass profile image URL
          ),
        );
      }
    }

    return sections;
  }

  List<Widget> _buildUnregisteredContactsSection(theme) {
    if (_filteredUnregisteredContacts.isEmpty) return [];

    return [
      // Section header for invite suggestions
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        color: theme.surfaceColor!.withOpacity(0.6),
        child: Text(
          'Invite to TextGB',
          style: TextStyle(
            color: theme.textSecondaryColor,
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      // Invite suggestions
      ..._filteredUnregisteredContacts.asMap().entries.map((entry) {
        final index = entry.key;
        final contact = entry.value;
        final phoneNumber = contact.phones.isNotEmpty 
            ? contact.phones.first.number 
            : 'No phone number';
        
        return _buildWeChatContactItem(
          icon: Icons.person_outline_rounded,
          title: contact.displayName.isEmpty ? 'Unknown' : contact.displayName,
          subtitle: phoneNumber,
          onTap: () {
            _showInviteDialog(contact);
          },
          theme: theme,
          showDivider: index < _filteredUnregisteredContacts.length - 1,
          isInvite: true,
          contact: contact,
        );
      }).toList(),
    ];
  }

  Widget _buildWeChatContactItem({
    IconData? icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    required theme,
    required bool showDivider,
    bool isContact = false,
    bool isInvite = false,
    bool isSpecialSection = false,
    dynamic contact,
    String? profileImageUrl, // Add profile image URL parameter
  }) {
    return Material(
      color: theme.surfaceColor,
      child: InkWell(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            border: showDivider
                ? Border(
                    bottom: BorderSide(
                      color: theme.dividerColor!.withOpacity(0.1),
                      width: 0.5,
                    ),
                  )
                : null,
          ),
          child: Row(
            children: [
              // Avatar/Profile Image or Icon
              if (isContact && profileImageUrl != null && profileImageUrl.isNotEmpty)
                _buildProfileAvatar(profileImageUrl, theme)
              else
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: isInvite 
                        ? theme.primaryColor!.withOpacity(0.1)
                        : isSpecialSection
                            ? theme.primaryColor!.withOpacity(0.1)
                            : theme.surfaceColor!.withOpacity(0.8),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Icon(
                    icon ?? Icons.person_rounded,
                    color: isInvite 
                        ? theme.primaryColor 
                        : isSpecialSection
                            ? theme.primaryColor
                            : theme.textSecondaryColor,
                    size: 20,
                  ),
                ),
              const SizedBox(width: 12),
              
              // Contact Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        color: theme.textColor,
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (subtitle.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        style: TextStyle(
                          color: theme.textSecondaryColor,
                          fontSize: 12,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ],
                ),
              ),
              
              // Action indicator
              if (isInvite)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: theme.primaryColor,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    'Invite',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                )
              else if (!isContact && !isSpecialSection)
                Icon(
                  Icons.arrow_forward_ios_rounded,
                  color: theme.textSecondaryColor,
                  size: 14,
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProfileAvatar(String imageUrl, theme) {
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(4),
        color: theme.surfaceColor!.withOpacity(0.8),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(4),
        child: CachedNetworkImage(
          imageUrl: imageUrl,
          fit: BoxFit.cover,
          placeholder: (context, url) => Container(
            color: theme.primaryColor!.withOpacity(0.1),
            child: Icon(
              Icons.person_rounded,
              color: theme.primaryColor,
              size: 20,
            ),
          ),
          errorWidget: (context, url, error) => Container(
            color: theme.primaryColor!.withOpacity(0.1),
            child: Icon(
              Icons.person_rounded,
              color: theme.primaryColor,
              size: 20,
            ),
          ),
        ),
      ),
    );
  }

  void _showInviteDialog(Contact contact) {
    final theme = context.modernTheme;
    final phoneNumber = contact.phones.isNotEmpty 
        ? contact.phones.first.number 
        : 'Unknown number';
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: theme.surfaceColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: Text(
          'Invite to TextGB',
          style: TextStyle(
            color: theme.textColor,
            fontWeight: FontWeight.w600,
          ),
        ),
        content: Text(
          'Invite ${contact.displayName.isEmpty ? phoneNumber : contact.displayName} to join TextGB?',
          style: TextStyle(color: theme.textSecondaryColor),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel', style: TextStyle(color: theme.textSecondaryColor)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _sendInvite(contact);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: theme.primaryColor,
              foregroundColor: Colors.white,
            ),
            child: const Text('Send Invite'),
          ),
        ],
      ),
    );
  }

  void _sendInvite(Contact contact) {
    // Implement invite sending logic
    _showSuccessSnackBar('Invite sent to ${contact.displayName}');
  }

  void _showComingSoonSnackBar(String feature) {
    _showInfoSnackBar('$feature - Coming Soon!');
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

  void _showInfoSnackBar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }
}