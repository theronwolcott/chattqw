import 'package:chat_tqw/model_state.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class DrawerContent extends StatefulWidget {
  const DrawerContent({super.key});

  @override
  State<DrawerContent> createState() => _DrawerContentState();
}

class _DrawerContentState extends State<DrawerContent> {
  @override
  Widget build(BuildContext context) {
    var modelState = context.watch<ModelState>();
    var userChats = modelState.pastChats.reversed.toList();

    return Drawer(
      child: ListView.builder(
        itemCount: userChats.length,
        itemBuilder: (BuildContext context, int index) {
          return ListTile(
            title: Text(userChats[index].label),
            onTap: () {
              // Update the current chat ID in the model state
              modelState.currentChatId = userChats[index].chatId;

              // Close the drawer
              Navigator.pop(context);
            },
          );
        },
      ),
    );
  }
}
