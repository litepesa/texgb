// lib/features/status/screens/status_screen.dart
import 'package:flutter/material.dart';
import 'package:textgb/shared/theme/theme_extensions.dart';

class StatusScreen extends StatefulWidget {
  const StatusScreen({super.key});

  @override
  State<StatusScreen> createState() => _StatusScreenState();
}

class _StatusScreenState extends State<StatusScreen> {
  final ScrollController _scrollController = ScrollController();
  
  // Dummy status data
  final List<StatusData> recentStatuses = [
    StatusData(
      name: "My Status",
      phoneNumber: "+254712345678",
      time: "45m ago",
      isMyStatus: true,
      hasUnviewedStory: false,
      statusCount: 2,
      profileColor: Colors.blue,
    ),
  ];
  
  final List<StatusData> viewedStatuses = [
    StatusData(
      name: "Maya Fashion Hub",
      phoneNumber: "+254787654321",
      time: "12m ago",
      isMyStatus: false,
      hasUnviewedStory: false,
      statusCount: 1,
      profileColor: Colors.pink,
    ),
    StatusData(
      name: "David Kiprotich",
      phoneNumber: "+254798765432",
      time: "1h ago",
      isMyStatus: false,
      hasUnviewedStory: false,
      statusCount: 3,
      profileColor: Colors.green,
    ),
    StatusData(
      name: "Sarah Wanjiku",
      phoneNumber: "+254723456789",
      time: "2h ago",
      isMyStatus: false,
      hasUnviewedStory: false,
      statusCount: 2,
      profileColor: Colors.purple,
    ),
  ];
  
  final List<StatusData> recentUpdates = [
    StatusData(
      name: "John Mwangi",
      phoneNumber: "+254734567890",
      time: "3m ago",
      isMyStatus: false,
      hasUnviewedStory: true,
      statusCount: 1,
      profileColor: Colors.orange,
    ),
    StatusData(
      name: "Grace Akinyi",
      phoneNumber: "+254745678901",
      time: "15m ago",
      isMyStatus: false,
      hasUnviewedStory: true,
      statusCount: 4,
      profileColor: Colors.teal,
    ),
    StatusData(
      name: "Peter Kamau",
      phoneNumber: "+254756789012",
      time: "32m ago",
      isMyStatus: false,
      hasUnviewedStory: true,
      statusCount: 2,
      profileColor: Colors.indigo,
    ),
    StatusData(
      name: "Faith Njeri",
      phoneNumber: "+254767890123",
      time: "1h ago",
      isMyStatus: false,
      hasUnviewedStory: true,
      statusCount: 1,
      profileColor: Colors.red,
    ),
    StatusData(
      name: "Michael Ochieng",
      phoneNumber: "+254778901234",
      time: "2h ago",
      isMyStatus: false,
      hasUnviewedStory: true,
      statusCount: 3,
      profileColor: Colors.cyan,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final theme = context.modernTheme;
    
    return Scaffold(
      backgroundColor: theme.surfaceColor,
      body: SafeArea(
        child: Column(
          children: [
            // Status list
            Expanded(
              child: ListView(
                controller: _scrollController,
                children: [
                  // My Status Section
                  if (recentStatuses.isNotEmpty) ...[
                    _buildSectionHeader('My Status', theme),
                    ...recentStatuses.map((status) => _buildStatusItem(status, theme)),
                    const SizedBox(height: 8),
                  ],
                  
                  // Recent Updates Section
                  if (recentUpdates.isNotEmpty) ...[
                    _buildSectionHeader('Recent updates', theme),
                    ...recentUpdates.map((status) => _buildStatusItem(status, theme)),
                    const SizedBox(height: 8),
                  ],
                  
                  // Viewed Updates Section
                  if (viewedStatuses.isNotEmpty) ...[
                    _buildSectionHeader('Viewed updates', theme),
                    ...viewedStatuses.map((status) => _buildStatusItem(status, theme)),
                  ],
                  
                  const SizedBox(height: 100), // Bottom padding
                ],
              ),
            ),
          ],
        ),
      ),
      
      // Floating action button for adding status
      floatingActionButton: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Text status button
          FloatingActionButton(
            heroTag: "text_status",
            onPressed: () {
              // Handle text status creation
            },
            backgroundColor: theme.surfaceVariantColor,
            child: Icon(
              Icons.edit,
              color: theme.textColor,
            ),
          ),
          const SizedBox(height: 16),
          
          // Camera status button
          FloatingActionButton(
            heroTag: "camera_status",
            onPressed: () {
              // Handle camera status creation
            },
            backgroundColor: theme.primaryColor,
            child: const Icon(
              Icons.camera_alt,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title, ModernThemeExtension theme) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: theme.textSecondaryColor,
        ),
      ),
    );
  }

  Widget _buildStatusItem(StatusData status, ModernThemeExtension theme) {
    return InkWell(
      onTap: () {
        // Handle status view
        _viewStatus(status);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            // Profile picture with status ring
            _buildProfilePicture(status, theme),
            
            const SizedBox(width: 12),
            
            // Status info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Name
                  Text(
                    status.name,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: theme.textColor,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  
                  const SizedBox(height: 2),
                  
                  // Time
                  Text(
                    status.time,
                    style: TextStyle(
                      fontSize: 13,
                      color: theme.textSecondaryColor,
                    ),
                  ),
                ],
              ),
            ),
            
            // Additional actions for my status
            if (status.isMyStatus) ...[
              PopupMenuButton<String>(
                icon: Icon(
                  Icons.more_vert,
                  color: theme.textSecondaryColor,
                ),
                onSelected: (value) {
                  switch (value) {
                    case 'privacy':
                      // Handle status privacy
                      break;
                    case 'delete':
                      // Handle status deletion
                      break;
                  }
                },
                itemBuilder: (context) => [
                  PopupMenuItem(
                    value: 'privacy',
                    child: Row(
                      children: [
                        Icon(Icons.visibility, color: theme.textSecondaryColor),
                        const SizedBox(width: 12),
                        Text('Status privacy', style: TextStyle(color: theme.textColor)),
                      ],
                    ),
                  ),
                  PopupMenuItem(
                    value: 'delete',
                    child: Row(
                      children: [
                        Icon(Icons.delete, color: theme.textSecondaryColor),
                        const SizedBox(width: 12),
                        Text('Delete status', style: TextStyle(color: theme.textColor)),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildProfilePicture(StatusData status, ModernThemeExtension theme) {
    return Stack(
      children: [
        // Status ring
        Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(
              color: status.hasUnviewedStory 
                  ? theme.primaryColor! 
                  : (status.isMyStatus ? Colors.transparent : theme.dividerColor!),
              width: status.hasUnviewedStory ? 2.5 : 2,
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(3),
            child: Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: status.profileColor.withOpacity(0.1),
              ),
              child: Center(
                child: Text(
                  status.name[0].toUpperCase(),
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                    color: status.profileColor,
                  ),
                ),
              ),
            ),
          ),
        ),
        
        // Add button for my status
        if (status.isMyStatus)
          Positioned(
            bottom: 0,
            right: 0,
            child: Container(
              width: 20,
              height: 20,
              decoration: BoxDecoration(
                color: theme.primaryColor,
                shape: BoxShape.circle,
                border: Border.all(
                  color: theme.surfaceColor!,
                  width: 2,
                ),
              ),
              child: const Icon(
                Icons.add,
                color: Colors.white,
                size: 12,
              ),
            ),
          ),
      ],
    );
  }

  void _viewStatus(StatusData status) {
    // Navigate to status viewer
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.black,
      builder: (context) => _buildStatusViewer(status),
    );
  }

  Widget _buildStatusViewer(StatusData status) {
    final theme = context.modernTheme;
    
    return Container(
      height: MediaQuery.of(context).size.height,
      child: Stack(
        children: [
          // Status content (placeholder)
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 200,
                  height: 200,
                  decoration: BoxDecoration(
                    color: status.profileColor.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Center(
                    child: Text(
                      'Status Content\n(${status.statusCount} ${status.statusCount == 1 ? 'update' : 'updates'})',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          
          // Top bar with progress indicator
          SafeArea(
            child: Container(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  // Progress indicators
                  Expanded(
                    child: Row(
                      children: List.generate(
                        status.statusCount,
                        (index) => Expanded(
                          child: Container(
                            height: 2,
                            margin: EdgeInsets.only(right: index < status.statusCount - 1 ? 4 : 0),
                            decoration: BoxDecoration(
                              color: index == 0 ? Colors.white : Colors.white.withOpacity(0.3),
                              borderRadius: BorderRadius.circular(1),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  
                  const SizedBox(width: 16),
                  
                  // Close button
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.3),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.close,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          
          // User info overlay
          Positioned(
            top: MediaQuery.of(context).padding.top + 60,
            left: 16,
            right: 16,
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: status.profileColor.withOpacity(0.1),
                  ),
                  child: Center(
                    child: Text(
                      status.name[0].toUpperCase(),
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: status.profileColor,
                      ),
                    ),
                  ),
                ),
                
                const SizedBox(width: 12),
                
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        status.name,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      Text(
                        status.time,
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.7),
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class StatusData {
  final String name;
  final String phoneNumber;
  final String time;
  final bool isMyStatus;
  final bool hasUnviewedStory;
  final int statusCount;
  final Color profileColor;

  StatusData({
    required this.name,
    required this.phoneNumber,
    required this.time,
    required this.isMyStatus,
    required this.hasUnviewedStory,
    required this.statusCount,
    required this.profileColor,
  });
}