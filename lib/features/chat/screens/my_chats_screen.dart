import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:textgb/shared/theme/theme_extensions.dart';
import 'package:textgb/features/authentication/providers/auth_providers.dart';
import 'package:textgb/features/chat/providers/chat_provider.dart';
import 'package:textgb/streams/chats_stream.dart';
import 'package:textgb/streams/search_stream.dart';

class MyChatsScreen extends ConsumerStatefulWidget {
  const MyChatsScreen({super.key});

  @override
  ConsumerState<MyChatsScreen> createState() => _MyChatsScreenState();
}

class _MyChatsScreenState extends ConsumerState<MyChatsScreen> {
  final TextEditingController _searchController = TextEditingController();
  bool _isSearching = false;
  
  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    final currentUser = ref.watch(currentUserProvider);
    if (currentUser == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }
    
    final uid = currentUser.uid;
    final modernTheme = context.modernTheme;
    final backgroundColor = modernTheme.backgroundColor ?? Theme.of(context).scaffoldBackgroundColor;
    
    return Scaffold(
      backgroundColor: backgroundColor,
      body: Column(
        children: [
          // Top space after app bar
          const SizedBox(height: 12),
          
          // Search bar with enhanced styling
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16.0),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              color: Theme.of(context).brightness == Brightness.dark 
                  ? Colors.grey.shade800 
                  : Colors.grey.shade200,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 3,
                  offset: const Offset(0, 1),
                ),
              ],
            ),
            child: CupertinoSearchTextField(
              controller: _searchController,
              backgroundColor: Colors.transparent,
              prefixInsets: const EdgeInsets.only(left: 12),
              suffixInsets: const EdgeInsets.only(right: 12),
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
              placeholder: 'Search chats',
              placeholderStyle: TextStyle(
                color: Theme.of(context).textTheme.bodyMedium!.color?.withOpacity(0.6),
                fontSize: 15,
              ),
              style: TextStyle(
                color: Theme.of(context).textTheme.bodyMedium!.color,
                fontSize: 15,
              ),
              onChanged: (value) {
                ref.read(chatProvider.notifier).setSearchQuery(value);
                setState(() {
                  _isSearching = value.isNotEmpty;
                });
              },
              onSuffixTap: () {
                _searchController.clear();
                ref.read(chatProvider.notifier).setSearchQuery('');
                setState(() {
                  _isSearching = false;
                });
                FocusScope.of(context).unfocus();
              },
            ),
          ),
          
          // Results counter when searching
          if (_isSearching) 
            Padding(
              padding: const EdgeInsets.only(left: 16, right: 16, top: 8, bottom: 0),
              child: Row(
                children: [
                  Icon(
                    Icons.search,
                    size: 16,
                    color: modernTheme.textSecondaryColor ?? Colors.grey,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Search results for "${_searchController.text}"',
                    style: TextStyle(
                      fontSize: 13,
                      color: modernTheme.textSecondaryColor ?? Colors.grey,
                    ),
                  ),
                ],
              ),
            ),
            
          // Divider for better section separation
          Padding(
            padding: const EdgeInsets.only(top: 12, bottom: 4),
            child: Divider(
              height: 1,
              thickness: 0.5,
              color: modernTheme.dividerColor ?? Colors.grey.withOpacity(0.2),
            ),
          ),
          
          // Main chat list with pull-to-refresh and empty state
          Expanded(
            child: _isSearching
                ? _buildSearchResults(uid)
                : _buildChatsList(uid),
          ),
        ],
      ),
    );
  }
  
  Widget _buildChatsList(String uid) {
    return RefreshIndicator(
      onRefresh: () async {
        // Implement refresh logic if needed
        await Future.delayed(const Duration(milliseconds: 800));
      },
      child: ChatsStream(uid: uid),
    );
  }
  
  Widget _buildSearchResults(String uid) {
    return SearchStream(uid: uid);
  }
}