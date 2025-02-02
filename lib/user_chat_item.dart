import 'dart:convert';

class UserChatItem {
  final String chatId;
  final String label; // Now required, not nullable
  final DateTime createdAt;

  UserChatItem({
    required this.chatId,
    required this.label, // Required now
    required this.createdAt,
  });

  // Factory constructor to create an instance from JSON
  factory UserChatItem.fromJson(Map<String, dynamic> json) {
    return UserChatItem(
      chatId: json['chatId'] as String,
      label: json['label'] as String, // No longer nullable
      createdAt:
          DateTime.parse(json['createdAt']), // Convert string to DateTime
    );
  }

  // Method to convert the object back to JSON
  Map<String, dynamic> toJson() {
    return {
      'chatId': chatId,
      'label': label,
      'createdAt': createdAt.toIso8601String(), // Convert DateTime to string
    };
  }

  // Helper method to parse a list of UserChatItems from JSON array
  static List<UserChatItem> fromJsonList(String jsonString) {
    final List<dynamic> data = jsonDecode(jsonString);
    return data.map((item) => UserChatItem.fromJson(item)).toList();
  }

  // String representation of the object
  @override
  String toString() {
    return 'UserChatItem(chatId: $chatId, label: $label, createdAt: $createdAt)';
  }
}
