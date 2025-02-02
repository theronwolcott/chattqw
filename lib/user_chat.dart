import 'llm_model.dart';
import 'model_state.dart';
import 'package:flutter_chat_types/flutter_chat_types.dart' as types;

class UserChat {
  final String chatId;
  LLMModel model;
  final DateTime createdAt;
  final List<types.TextMessage> messages;

  UserChat({
    required this.chatId,
    required this.model,
    required this.createdAt,
    List<types.TextMessage>? messages, // optional
  }) : messages = messages ?? []; // Defaults to an empty list if null

  // Factory constructor to create an instance from JSON
  factory UserChat.fromJson(Map<String, dynamic> json) {
    return UserChat(
      chatId: json['chatId'] as String,
      model: ModelState.findModelByValue(
          json['model'] as String), // No longer nullable
      createdAt:
          DateTime.parse(json['createdAt']), // Convert string to DateTime
      messages: (json['messages'] as List<dynamic>)
          .map((messageJson) =>
              types.TextMessage.fromJson(messageJson as Map<String, dynamic>))
          .toList(),
    );
  }

  // Method to convert the object back to JSON
  Map<String, dynamic> toJson() {
    return {
      'chatId': chatId,
      'model': model.value,
      'createdAt': createdAt.toIso8601String(), // Convert DateTime to string
      'messages': messages.map((m) => m.toJson()),
    };
  }

  // String representation of the object including messages
  @override
  String toString() {
    // Join the string representations of each message separated by a comma and space
    final messagesString = messages.map((m) => m.toString()).join(', ');
    return 'UserChat(chatId: $chatId, model: ${model.value}, createdAt: $createdAt, messages: [$messagesString])';
  }
}
