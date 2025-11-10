// lib/features/contacts/screens/contacts_screen.dart
// Updated to use new contacts provider system with extracted widgets
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_contacts/flutter_contacts.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:textgb/features/contacts/providers/contacts_provider.dart';
import 'package:textgb/features/contacts/screens/add_contact_screen.dart';
import 'package:textgb/features/contacts/screens/blocked_contacts_screen.dart';
import 'package:textgb/features/contacts/widgets/contact_item_widget.dart';
import 'package:textgb/features/contacts/widgets/contacts_empty_states_widget.dart';
import 'package:textgb/features/users/models/user_model.dart';
import 'package:textgb/shared/theme/theme_extensions.dart';

class ContactsScreen extends ConsumerStatefulWidget {
  const ContactsScreen({super.key});

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
            _buildAppBar(theme),
            
            // Search Field (when active)
            if (_isSearching) _buildSearchField(theme),
            
            // Enhanced Tab Bar
            _buildTabBar(theme),
            
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
                        
                        return TabBarView(
                          controller: _tabController,
                          children: [
                            _buildContactsTab(state),
                            _buildInvitesTab(state),
                          ],
                        );
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

  Widget _buildAppBar(theme) {
    return Container(
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
    );
  }

  Widget _buildSearchField(theme) {
    return Container(
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
    );
  }

  Widget _buildTabBar(theme) {
    return Container(
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
    );
  }

  Widget _buildContactsTab(ContactsState state) {
    final theme = context.modernTheme;
    
    if (state.isLoading && _isInitializing) {
      return ContactsEmptyStatesWidget.buildLoadingState(
        context, 
        'Loading contacts...'
      );
    }

    if (_filteredRegisteredContacts.isEmpty && !state.isLoading) {
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
            ContactsEmptyStatesWidget.buildSyncStatusIndicator(
              context,
              state.lastSyncTime,
              state.syncStatus,
              state.backgroundSyncAvailable,
              _forceSyncContacts,
            ),
            Expanded(
              child: ListView.separated(
                controller: _contactsScrollController,
                padding: const EdgeInsets.all(16),
                itemCount: _filteredRegisteredContacts.length,
                separatorBuilder: (context, index) => const SizedBox(height: 8),
                itemBuilder: (context, index) {
                  final contact = _filteredRegisteredContacts[index];
                  return ContactItemWidget(
                    contact: contact,
                    index: index,
                  );
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
      return ContactsEmptyStatesWidget.buildLoadingState(
        context, 
        'Loading contacts...'
      );
    }

    if (_filteredUnregisteredContacts.isEmpty && !state.isLoading) {
      return ContactsEmptyStatesWidget.buildEmptyInvitesState(
        context,
        _searchQuery,
        _forceSyncContacts,
      );
    }

    return Container(
      color: theme.surfaceColor,
      child: RefreshIndicator(
        onRefresh: _forceSyncContacts,
        color: theme.primaryColor,
        child: Column(
          children: [
            ContactsEmptyStatesWidget.buildSyncStatusIndicator(
              context,
              state.lastSyncTime,
              state.syncStatus,
              state.backgroundSyncAvailable,
              _forceSyncContacts,
            ),
            Expanded(
              child: ListView.separated(
                controller: _invitesScrollController,
                padding: const EdgeInsets.all(16),
                itemCount: _filteredUnregisteredContacts.length,
                separatorBuilder: (context, index) => const SizedBox(height: 8),
                itemBuilder: (context, index) {
                  final contact = _filteredUnregisteredContacts[index];
                  return InviteItemWidget(
                    contact: contact,
                    index: index,
                  );
                },
              ),
            ),
          ],
        ),
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
}