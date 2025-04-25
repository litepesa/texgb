import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:textgb/constants.dart';
import 'package:textgb/features/channels/channel_provider.dart';
import 'package:textgb/features/channels/screens/my_channels_screen.dart';
import 'package:textgb/features/channels/screens/explore_channels_screen.dart';
import 'package:textgb/features/authentication/authentication_provider.dart';

class ChannelsScreen extends StatefulWidget {
  const ChannelsScreen({Key? key}) : super(key: key);

  @override
  State<ChannelsScreen> createState() => _ChannelsScreenState();
}

class _ChannelsScreenState extends State<ChannelsScreen> with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        body: Column(
          children: [
            // TabBar for My Channels / Explore
            TabBar(
              indicatorSize: TabBarIndicatorSize.label,
              tabs: [
                Tab(
                  text: 'MY CHANNELS',
                ),
                Tab(
                  text: 'EXPLORE',
                ),
              ],
            ),
            // TabBarView for the content
            Expanded(
              child: TabBarView(
                children: [
                  // My Channels tab
                  MyChannelsScreen(),
                  
                  // Explore Channels tab
                  ExploreChannelsTabView(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Create a separate widget for the Explore tab to avoid navigation conflicts
class ExploreChannelsTabView extends StatelessWidget {
  const ExploreChannelsTabView({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ExploreChannelsScreen(isInTabView: true);
  }
}