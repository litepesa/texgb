// lib/features/contacts/screens/contacts_screen.dart
// Updated with AppBar and back navigation
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_contacts/flutter_contacts.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:textgb/features/contacts/providers/contacts_provider.dart';
import 'package:textgb/features/contacts/repositories/contacts_repository.dart';
import 'package:textgb/features/contacts/screens/contact_profile_screen.dart';
import 'package:textgb/features/contacts/widgets/contact_item_widget.dart';
import 'package:textgb/features/users/models/user_model.dart';
import 'package:textgb/shared/theme/theme_extensions.dart';
import 'package:cached_network_image/cached_network_image.dart';

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
  List<SyncedContact> _filteredRegisteredContacts = [];
  List<Contact> _filteredUnregisteredContacts = [];
  
  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _setupAnimations();
    _setupListeners();
    
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
      // Use displayName (local contact name) for search
      _filteredRegisteredContacts = contactsState.registeredContacts
          .where((contact) =>
              contact.displayName.toLowerCase().contains(_searchQuery) ||
              contact.user.phoneNumber.toLowerCase().contains(_searchQuery))
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

  Future<void> _initializeContacts() async {
    setState(() {
      _isInitializing = true;
    });
    
    try {
      final contactsNotifier = ref.read(contactsNotifierProvider.notifier);
      
      await ref.read(contactsNotifierProvider.future);
      
      if (mounted) {
        setState(() {
          _isInitializing = false;
          _updateFilteredContacts();
        });
      }
      
      final syncInfo = contactsNotifier.getSyncInfo();
      if (syncInfo['backgroundSyncAvailable'] == true) {
        _performBackgroundSync();
      }
      
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

  Future<void> _performBackgroundSync() async {
    try {
      final contactsNotifier = ref.read(contactsNotifierProvider.notifier);
      await contactsNotifier.performBackgroundSync();
      
      if (mounted) {
        _updateFilteredContacts();
      }
    } catch (e) {
      debugPrint('Background sync failed: $e');
    }
  }

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
    super.build(context);
    
    final theme = context.modernTheme;
    
    return GestureDetector(
      onTap: () {
        if (_isSearching) {
          _dismissSearch();
        }
      },
      behavior: HitTestBehavior.opaque,
      child: Scaffold(
        backgroundColor: theme.surfaceColor,
        appBar: AppBar(
          backgroundColor: theme.surfaceColor,
          elevation: 0,
          leading: IconButton(
            icon: Icon(
              Icons.arrow_back_ios_rounded,
              color: theme.textColor,
              size: 20,
            ),
            onPressed: () {
              HapticFeedback.lightImpact();
              Navigator.pop(context);
            },
          ),
          title: Text(
            'Contacts',
            style: TextStyle(
              color: theme.textColor,
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          centerTitle: false,
          systemOverlayStyle: SystemUiOverlayStyle(
            statusBarColor: Colors.transparent,
            statusBarIconBrightness: Theme.of(context).brightness == Brightness.dark 
                ? Brightness.light 
                : Brightness.dark,
            statusBarBrightness: Theme.of(context).brightness,
          ),
        ),
        body: Column(
          children: [
            _buildWeChatHeader(theme),
            
            Expanded(
              child: Container(
                color: theme.surfaceColor,
                child: Consumer(
                  builder: (context, ref, child) {
                    final contactsState = ref.watch(contactsNotifierProvider);
                    
                    return contactsState.when(
                      data: (state) {
                        if (state.syncStatus == SyncStatus.permissionDenied) {
                          return ContactsEmptyStatesWidget.buildPermissionScreen(
                            context,
                            () async {
                              final contactsNotifier = ref.read(contactsNotifierProvider.notifier);
                              await contactsNotifier.requestPermission();
                            },
                          );
                        }
                        
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
    );
  }

  Widget _buildWeChatHeader(theme) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
      color: theme.surfaceColor,
      child: Column(
        children: [
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

    final allContacts = [
      ..._buildRegisteredContactsSection(theme),
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

  List<Widget> _buildRegisteredContactsSection(theme) {
    if (_filteredRegisteredContacts.isEmpty) return [];

    final Map<String, List<SyncedContact>> groupedContacts = {};

    for (final contact in _filteredRegisteredContacts) {
      // Use displayName (local contact name) for grouping
      final firstLetter = contact.displayName.isNotEmpty
          ? contact.displayName[0].toUpperCase()
          : '#';
      if (!groupedContacts.containsKey(firstLetter)) {
        groupedContacts[firstLetter] = [];
      }
      groupedContacts[firstLetter]!.add(contact);
    }

    final sortedLetters = groupedContacts.keys.toList()..sort();

    final List<Widget> sections = [];

    for (final letter in sortedLetters) {
      // Sort by displayName (local contact name)
      final contactsInGroup = groupedContacts[letter]!..sort((a, b) => a.displayName.compareTo(b.displayName));

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

      for (int i = 0; i < contactsInGroup.length; i++) {
        final syncedContact = contactsInGroup[i];
        final user = syncedContact.user;
        final showDivider = i < contactsInGroup.length - 1;

        sections.add(
          _buildWeChatContactItem(
            title: syncedContact.displayName, // Use local contact name
            subtitle: user.phoneNumber,
            onTap: () {
              _navigateToContactProfile(user); // Pass UserModel for profile
            },
            theme: theme,
            showDivider: showDivider,
            isContact: true,
            contact: user,
            profileImageUrl: user.profileImage,
          ),
        );
      }
    }

    return sections;
  }

  List<Widget> _buildUnregisteredContactsSection(theme) {
    if (_filteredUnregisteredContacts.isEmpty) return [];

    return [
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
      }),
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
    String? profileImageUrl,
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
    _showSuccessSnackBar('Invite sent to ${contact.displayName}');
  }

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