import 'package:chat_tqw/login_screen.dart';
import 'package:chat_tqw/model_state.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter/cupertino.dart';

import 'new_chat_button.dart';
import 'user.dart';
import 'user_chat_item.dart';
import 'user_state.dart';

class DrawerContent extends StatefulWidget {
  const DrawerContent({super.key});

  @override
  State<DrawerContent> createState() => _DrawerContentState();
}

class _DrawerContentState extends State<DrawerContent> {
  late TextEditingController _searchController;
  final modelState = ModelState();

  @override
  void initState() {
    super.initState();
    // Initialize the controller using the current value stored in ModelState.
    _searchController = TextEditingController(text: modelState.searchQuery);

    // Update the ModelState's search query whenever the text changes.
    _searchController.addListener(() {
      modelState.searchQuery = _searchController.text;
      setState(() {}); // Trigger a rebuild for filtering purposes.
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  /// Groups the chats by createdAt date.
  List<Widget> _buildGroupedChatList(List<UserChatItem> chats) {
    // Prepare the groups.
    final Map<String, List<UserChatItem>> groups = {
      'Today': [],
      'Yesterday': [],
      'Previous 7 Days': [],
      'Previous 30 Days': [],
      'Older': [],
    };

    // Calculate date boundaries.
    final DateTime now = DateTime.now();
    final DateTime todayStart = DateTime(now.year, now.month, now.day);
    final DateTime yesterdayStart =
        todayStart.subtract(const Duration(days: 1));
    final DateTime sevenDaysAgo = todayStart.subtract(const Duration(days: 7));
    final DateTime thirtyDaysAgo =
        todayStart.subtract(const Duration(days: 30));

    for (var chat in chats) {
      final DateTime created = chat.createdAt;
      if (created.isAfter(todayStart)) {
        groups['Today']!.add(chat);
      } else if (created.isAfter(yesterdayStart)) {
        groups['Yesterday']!.add(chat);
      } else if (created.isAfter(sevenDaysAgo)) {
        groups['Previous 7 Days']!.add(chat);
      } else if (created.isAfter(thirtyDaysAgo)) {
        groups['Previous 30 Days']!.add(chat);
      } else {
        groups['Older']!.add(chat);
      }
    }

    final List<String> groupOrder = [
      'Today',
      'Yesterday',
      'Previous 7 Days',
      'Previous 30 Days',
      'Older'
    ];
    final List<Widget> listItems = [];

    for (String group in groupOrder) {
      final List<UserChatItem> chatsInGroup = groups[group]!;
      if (chatsInGroup.isNotEmpty) {
        // Group header.
        listItems.add(
          Padding(
            padding: const EdgeInsets.only(
                left: 16.0, right: 16.0, top: 10.0, bottom: 2.0),
            child: Text(
              group,
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
            ),
          ),
        );
        // Chat items.
        for (var chat in chatsInGroup) {
          listItems.add(
            ListTile(
              title: Text(
                chat.label,
                style: const TextStyle(fontSize: 15),
              ),
              onTap: () {
                modelState.currentChatId = chat.chatId;
                Navigator.pop(context);
              },
            ),
          );
        }
      }
    }
    return listItems;
  }

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: SafeArea(
        child: Stack(
          children: [
            // The main column containing the search bar and the scrollable list.
            Column(
              children: [
                // Search bar and "New Chat" button.
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Row(
                    children: [
                      // Expanded search field.
                      Expanded(
                        child: TextField(
                          controller: _searchController,
                          decoration: InputDecoration(
                            labelText: 'Search',
                            border: const OutlineInputBorder(),
                            suffixIcon: _searchController.text.isNotEmpty
                                ? IconButton(
                                    icon: const Icon(Icons.cancel),
                                    onPressed: () {
                                      _searchController.clear();
                                      FocusScope.of(context)
                                          .unfocus(); // Dismiss the keyboard.
                                      setState(
                                          () {}); // Rebuild with cleared search.
                                    },
                                  )
                                : null,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8.0),
                      // "New Chat" icon button.
                      NewChatButton(),
                    ],
                  ),
                ),
                // Expanded scrollable list.
                Expanded(
                  // Use Selector to rebuild only when pastChats changes.
                  child: Selector<ModelState, List<UserChatItem>>(
                    selector: (_, modelState) =>
                        modelState.pastChats.reversed.toList(),
                    builder: (context, pastChats, child) {
                      // Apply the search filtering.
                      final query =
                          Provider.of<ModelState>(context).searchQuery;
                      final List<UserChatItem> filteredChats = query.isNotEmpty
                          ? pastChats
                              .where((chat) => chat.label
                                  .toLowerCase()
                                  .contains(query.toLowerCase()))
                              .toList()
                          : pastChats;
                      // Build grouped list.
                      return ListView(
                        // Add bottom padding so the last items are not hidden by the fixed panel.
                        padding: const EdgeInsets.only(bottom: 70.0),
                        children: _buildGroupedChatList(filteredChats),
                      );
                    },
                  ),
                ),
              ],
            ),
            // Fixed panel at the bottom.
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              height: 70.0,
              child: DrawerCurrentUserPanel(),
            ),
          ],
        ),
      ),
    );
  }
}

class DrawerCurrentUserPanel extends StatelessWidget {
  const DrawerCurrentUserPanel({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Selector<UserState, User?>(
      selector: (_, userState) => userState.currentUser,
      builder: (context, currentUser, child) {
        // If there's no currentUser, show a Sign In button.
        if (currentUser == null) {
          return Container(
            decoration: BoxDecoration(
              border: Border(
                top: BorderSide(
                  color: const Color.fromARGB(255, 208, 208, 208),
                  width: 1.0,
                ),
              ),
              color: Theme.of(context).canvasColor,
            ),
            alignment: Alignment.center,
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => LoginScreen()),
                  );
                },
                child: const Text("Sign up or log in"),
              ),
            ),
          );
        }

        // If there is a currentUser, display their information.
        final fullName = '${currentUser.firstName} ${currentUser.lastName}';
        // Create initials
        final initials = currentUser.firstName[0].toUpperCase() +
            currentUser.lastName[0].toUpperCase();

        return Container(
          decoration: BoxDecoration(
            border: Border(
              top: BorderSide(
                color: const Color.fromARGB(255, 208, 208, 208),
                width: 1.0,
              ),
            ),
            color: Theme.of(context).canvasColor,
          ),
          alignment: Alignment.center,
          padding: const EdgeInsets.only(left: 12.0, right: 8.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Left side: Profile circle and user name.
              Row(
                children: [
                  CircleAvatar(
                    child: Text(initials),
                  ),
                  const SizedBox(width: 8.0),
                  Text(
                    fullName,
                    style: const TextStyle(fontSize: 16.0),
                  ),
                ],
              ),
              // Right side: Ellipsis icon.
              IconButton(
                icon: const Icon(Icons.more_horiz),
                onPressed: () {
                  showCupertinoModalPopup<void>(
                    context: context,
                    builder: (BuildContext context) => CupertinoActionSheet(
                      actions: <CupertinoActionSheetAction>[
                        CupertinoActionSheetAction(
                          onPressed: () {
                            Navigator.pop(context);
                            // log user out
                            UserState().logout();
                          },
                          child: const Text('Log Out'),
                        ),
                      ],
                      cancelButton: CupertinoActionSheetAction(
                        onPressed: () {
                          Navigator.pop(context);
                        },
                        child: const Text('Cancel'),
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
        );
      },
    );
  }
}
