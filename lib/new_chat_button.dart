import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'model_state.dart';

class NewChatButton extends StatelessWidget {
  const NewChatButton({super.key});

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.edit_square),
      tooltip: 'New Chat',
      onPressed: () {
        // Reset the current chat by updating the provider with blank id
        context.read<ModelState>().currentChatId = "";
        // Check if there's something to pop so we close the menu when someone presses
        if (Navigator.canPop(context)) {
          Navigator.pop(context);
        }
      },
    );
  }
}
