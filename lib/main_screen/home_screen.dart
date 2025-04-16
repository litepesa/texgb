import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:textgb/constants.dart';
import 'package:textgb/features/status/screens/status_screen.dart';
import 'package:textgb/main_screen/add_contact_screen.dart';
import 'package:textgb/main_screen/create_group_screen.dart';
import 'package:textgb/main_screen/groups_screen.dart';
import 'package:textgb/main_screen/my_chats_screen.dart';
import 'package:textgb/main_screen/people_screen.dart';
import 'package:textgb/providers/authentication_provider.dart';
import 'package:textgb/providers/group_provider.dart';
import 'package:textgb/utilities/global_methods.dart';


class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with WidgetsBindingObserver, TickerProviderStateMixin {
  final PageController pageController = PageController(initialPage: 0);
  int currentIndex = 0;

  final List<Widget> pages = const [
    MyChatsScreen(),
    GroupsScreen(),
    StatusScreen(),
  ];

  @override
  void initState() {
    WidgetsBinding.instance.addObserver(this);
    super.initState();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    switch (state) {
      case AppLifecycleState.resumed:
        // user comes back to the app
        // update user status to online
        context.read<AuthenticationProvider>().updateUserStatus(
              value: true,
            );
        break;
      case AppLifecycleState.inactive:
      case AppLifecycleState.paused:
      case AppLifecycleState.detached:
      case AppLifecycleState.hidden:
        // app is inactive, paused, detached or hidden
        // update user status to offline
        context.read<AuthenticationProvider>().updateUserStatus(
              value: false,
            );
        break;
      default:
        // handle other states
        break;
    }
    super.didChangeAppLifecycleState(state);
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthenticationProvider>();
    return Scaffold(
        appBar: AppBar(
          title: const Text('TexGB'),
          actions: [
            IconButton(
              icon: const Icon(Icons.search),
              onPressed: () {
                // Navigate to search screen
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => const PeopleScreen(),
                  ),
                );
              },
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              child: Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: Colors.red.withOpacity(0.7),
                    width: 2,
                  ),
                ),
                child: userImageWidget(
                  imageUrl: authProvider.userModel!.image,
                  radius: 20,
                  onTap: () {
                    // navigate to user profile with uid as arguments
                    Navigator.pushNamed(
                      context,
                      Constants.profileScreen,
                      arguments: authProvider.userModel!.uid,
                    );
                  },
                ),
              ),
            )
          ],
        ),
        body: PageView(
          controller: pageController,
          onPageChanged: (index) {
            setState(() {
              currentIndex = index;
            });
          },
          children: pages,
        ),
        floatingActionButton: currentIndex == 1
            ? FloatingActionButton(
                onPressed: () {
                  context
                      .read<GroupProvider>()
                      .clearGroupMembersList()
                      .whenComplete(() {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => const CreateGroupScreen(),
                      ),
                    );
                  });
                },
                child: const Icon(CupertinoIcons.add),
              )
            : currentIndex == 0
                ? FloatingActionButton(
                    onPressed: () {
                      // Navigate to Contacts screen
                      Navigator.pushNamed(
                        context,
                        Constants.contactsScreen,
                      );
                    },
                    child: const Icon(CupertinoIcons.chat_bubble_text),
                  )
                : null,
        bottomNavigationBar: BottomNavigationBar(
          items: const [
            BottomNavigationBarItem(
              icon: Icon(CupertinoIcons.chat_bubble_2, size: 30),
              label: 'Chats',
            ),
            BottomNavigationBarItem(
              icon: Icon(CupertinoIcons.group, size: 30),
              label: 'Groups',
            ),
            BottomNavigationBarItem(
              icon: Icon(CupertinoIcons.rays, size: 30),
              label: 'Status',
            ),
          ],
          currentIndex: currentIndex,
          onTap: (index) {
            // animate to the page
            pageController.animateToPage(index,
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeIn);
            setState(() {
              currentIndex = index;
            });
          },
        ));
  }
}