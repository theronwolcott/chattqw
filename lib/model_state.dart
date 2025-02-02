import 'package:flutter/material.dart';
import 'package:collection/collection.dart'; // Required for firstOrNull
import 'package:flutter_chat_types/flutter_chat_types.dart' as chat_types;
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:async';

import 'api_service.dart';
import 'llm_model.dart';
import 'user_chat.dart';
import 'user_chat_item.dart';

class ModelState extends ChangeNotifier {
  /* UserState tracks the user's id and other preferences */
  static final ModelState _instance = ModelState._internal();

  factory ModelState() => _instance;

  ModelState._internal() {
    _loadModels();
    _loadPastChats();
  }

  static final List<LLMModel> availableModels = [
    LLMModel(
      company: LLMModelCompany.OpenAI,
      name: "GPT-4o",
      value: "openai/chatgpt-4o-latest",
      short: "chatgpt-4o",
    ),
    LLMModel(
      company: LLMModelCompany.OpenAI,
      name: "GPT-4o mini",
      value: "openai/gpt-4o-mini",
      short: "chatgpt-4o-mini",
    ),
    LLMModel(
      company: LLMModelCompany.OpenAI,
      name: "o1",
      value: "openai/o1",
      short: "o1",
    ),
    LLMModel(
      company: LLMModelCompany.OpenAI,
      name: "o1-mini",
      value: "openai/o1-mini",
      short: "o1-mini",
    ),
    LLMModel(
      company: LLMModelCompany.OpenAI,
      name: "GPT-4 Turbo",
      value: "openai/gpt-4-turbo",
      short: "gpt-4-turbo",
    ),
    LLMModel(
      company: LLMModelCompany.OpenAI,
      name: "GPT-3.5 Turbo",
      value: "openai/gpt-3.5-turbo",
      short: "gpt-3.5-turbo",
    ),
    LLMModel(
      company: LLMModelCompany.Anthropic,
      name: "Claude 3.5 Sonnet",
      value: "anthropic/claude-3.5-sonnet",
      short: "claude-3.5-sonnet",
    ),
    LLMModel(
      company: LLMModelCompany.Anthropic,
      name: "Claude 3 Haiku",
      value: "anthropic/claude-3-haiku",
      short: "claude-3-haiku",
    ),
    LLMModel(
      company: LLMModelCompany.Google,
      name: "Gemini 2.0 Flash Thinking",
      value: "google/gemini-2.0-flash-thinking-exp-1219:free",
      short: "gemini-2.0-flash-thinking",
    ),
    LLMModel(
      company: LLMModelCompany.Google,
      name: "Gemma 2 9B",
      value: "google/gemma-2-9b-it:free",
      short: "gemma-2-9b",
    ),
    LLMModel(
      company: LLMModelCompany.DeepSeek,
      name: "R1 (free)",
      value: "deepseek/deepseek-r1:free",
      short: "deepseek-r1-free",
    ),
    LLMModel(
      company: LLMModelCompany.DeepSeek,
      name: "R1",
      value: "deepseek/deepseek-r1",
      short: "deepseek-r1",
    ),
    LLMModel(
      company: LLMModelCompany.DeepSeek,
      name: "R1 Llama 70B",
      value: "deepseek/deepseek-r1-distill-llama-70b",
      short: "deepseek-r1-llama-70b",
    ),
    LLMModel(
      company: LLMModelCompany.DeepSeek,
      name: "R1 Distill Qwen 32B",
      value: "deepseek/deepseek-r1-distill-qwen-32b",
      short: "deepseek-r1-qwen-32b",
    ),
    LLMModel(
      company: LLMModelCompany.DeepSeek,
      name: "R1 Distill Qwen 14B",
      value: "deepseek/deepseek-r1-distill-qwen-14b",
      short: "deepseek-r1-qwen-14b",
    ),
    LLMModel(
      company: LLMModelCompany.Meta,
      name: "R1 Distill Qwen 14B",
      value: "meta-llama/llama-3.3-70b-instruct",
      short: "llama-3.3-70b",
    ),
  ];

  LLMModel _currentModel = availableModels.first;
  String currentModelKey = 'ModelState.currentModel';
  late SharedPreferences prefs;
  final Completer<void> _completer = Completer<void>();
  late List<UserChatItem> _pastChats;
  String _currentChatId = "";

  static LLMModel findModelByValue(String modelValue) {
    var m =
        availableModels.firstWhereOrNull((model) => model.value == modelValue);
    return (m == null) ? availableModels.first : m;
  }

  Future<void> _loadModels() async {
    prefs = await SharedPreferences.getInstance();
    _currentModel = availableModels.first;
    var currentModelFromDisk = prefs.getString(currentModelKey);

    if (currentModelFromDisk == null) {
      prefs.setString(currentModelKey, _currentModel.value);
    } else {
      _currentModel = findModelByValue(currentModelFromDisk);
    }
    _completer.complete(); // Mark as initialized
  }

  Future<void> _loadPastChats() async {
    final ApiService apiService = ApiService();
    final data = await apiService.fetchList<UserChatItem>(
      "/chat/list",
      UserChatItem.fromJson,
    );
    _pastChats = data;
  }

  void reset() {
    _currentModel = availableModels.first;
    prefs.setString(currentModelKey, _currentModel.value);
    notifyListeners();
  }

  void saveCurrentChat(UserChat chat) async {
    final ApiService apiService = ApiService();
    _currentChatId = chat.chatId;
    if (chat.messages.isNotEmpty) {
      if (_pastChats.where((c) => chat.chatId == c.chatId).isEmpty) {
        // add to the user's list of chats if it isn't already there

        // summarize it to get the label
        var label = (chat.messages.last)
            .text
            .split(RegExp(r'\s+'))
            .take(6)
            .join(' '); // Take first 6 words and join back

        // add to list locally
        _pastChats.add(UserChatItem(
            chatId: chat.chatId, label: label, createdAt: chat.createdAt));

        // notify listeners
        notifyListeners();

        // add to list remotely
        apiService.postRequest("/chat/update", body: {
          "chatId": chat.chatId,
          "label": label,
          "createdAt": chat.createdAt.toIso8601String(),
        });
      }
      // save messages remotely
      apiService.postRequest("/chat/save-messages", body: {
        "chatId": chat.chatId,
        "model": _currentModel.value,
        "createdAt": chat.createdAt.toIso8601String(),
        "messages": chat.messages,
      });
    }
  }

  LLMModel get currentModel => _currentModel;
  set currentModel(LLMModel value) {
    _currentModel = value;
    notifyListeners();
    prefs.setString(currentModelKey, _currentModel.value);
  }

  String get currentChatId => _currentChatId;
  set currentChatId(String value) {
    _currentChatId = value;
    notifyListeners();
  }

  List<UserChatItem> get pastChats => _pastChats;

  // Future<String> get idAsync async {
  //   await _completer.future; // Wait for initialization if needed
  //   return _id;
  // }
}
