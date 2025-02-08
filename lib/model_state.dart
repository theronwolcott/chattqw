import 'package:flutter/material.dart';
import 'package:collection/collection.dart'; // Required for firstOrNull
import 'package:flutter_chat_types/flutter_chat_types.dart' as chat_types;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:dart_openai/dart_openai.dart';
import 'dart:async';

import 'user_state.dart';
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
    userState.addListener(() {
      if (userState.id != _currentUserId) {
        // userId changed so reload past chats from server
        _currentUserId = userState.id;
        _searchQuery = '';
        _currentChatId = "";
        _loadPastChats();
      }
    });
  }

  static final List<LLMModel> availableModels = [
    LLMModel(
      company: LLMModelCompany.OpenAI,
      name: "GPT-4o mini",
      value: "openai/gpt-4o-mini",
      short: "chatgpt-4o-mini",
    ),
    LLMModel(
      company: LLMModelCompany.OpenAI,
      name: "GPT-4o",
      value: "openai/chatgpt-4o-latest",
      short: "chatgpt-4o",
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
      name: "Claude 3.5 Haiku",
      value: "anthropic/claude-3.5-haiku",
      short: "claude-3-haiku",
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
      value: "google/gemini-2.0-flash-thinking-exp:free",
      short: "gemini-2.0-flash-thinking",
    ),
    LLMModel(
      company: LLMModelCompany.Google,
      name: "Gemini 2.0 Flash",
      value: "google/gemini-2.0-flash-001",
      short: "gemini-2.0-flash",
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
      name: "R1 Distill Llama 70B",
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
      name: "Llama 3.3 70B",
      value: "meta-llama/llama-3.3-70b-instruct",
      short: "llama-3.3-70b",
    ),
    LLMModel(
      company: LLMModelCompany.Meta,
      name: "Llama 3.2 3B",
      value: "meta-llama/llama-3.2-3b-instruct",
      short: "llama-3.2-3b",
    ),
    LLMModel(
      company: LLMModelCompany.Meta,
      name: "Llama 3.2 1B",
      value: "meta-llama/llama-3.2-1b-instruct",
      short: "llama-3.2-1b",
    ),
    LLMModel(
      company: LLMModelCompany.Mistral,
      name: "Mistral Small 3",
      value: "mistralai/mistral-small-24b-instruct-2501",
      short: "mistral-small-24b",
    ),
    LLMModel(
      company: LLMModelCompany.Mistral,
      name: "Mistral Nemo",
      value: "mistralai/mistral-nemo",
      short: "mistral-nemo",
    ),
  ];

  LLMModel _currentModel = availableModels.first;
  final LLMModel _labelSummaryModel =
      findModelByValue("meta-llama/llama-3.3-70b-instruct");
  String currentModelKey = 'ModelState.currentModel';
  late SharedPreferences prefs;
  final Completer<void> _completer = Completer<void>();
  late List<UserChatItem> _pastChats;
  String _currentChatId = "";
  String _searchQuery = '';
  final userState = UserState();
  String _currentUserId = "";

  static LLMModel findModelByValue(String modelValue) {
    var m =
        availableModels.firstWhereOrNull((model) => model.value == modelValue);
    return (m == null) ? availableModels.first : m;
  }

  Future<void> _loadModels() async {
    _currentModel = availableModels.first;
    prefs = await SharedPreferences.getInstance();
    var currentModelFromDisk = prefs.getString(currentModelKey);
    debugPrint("currentModelFromDisk: $currentModelFromDisk");
    if (currentModelFromDisk == null) {
      prefs.setString(currentModelKey, _currentModel.value);
    } else {
      _currentModel = findModelByValue(currentModelFromDisk);
      notifyListeners();
    }
    _completer.complete(); // Mark as initialized
  }

  Future<void> _loadPastChats() async {
    final ApiService apiService = ApiService();
    final data = await apiService.fetchList<UserChatItem>(
      "/chat/list",
      UserChatItem.fromJson,
    );
    // update list locally
    _pastChats = data;
    notifyListeners();
  }

  void saveCurrentChat(UserChat chat) async {
    final ApiService apiService = ApiService();
    _currentChatId = chat.chatId;
    if (chat.messages.isNotEmpty) {
      if (_pastChats.where((c) => chat.chatId == c.chatId).isEmpty) {
        // add to the user's list of chats if it isn't already there

        // summarize it to get the label
        var label = await getLabel(chat.messages);

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

  /// uses an LLM to generate a short phrase to use as the "label" for
  /// a chat in the sidebar/drawer
  /// It takes the existing messages, and adds a system message with
  /// instructions for the LLM
  Future<String> getLabel(List<chat_types.TextMessage> messages) async {
    var chatHistory =
        messages.reversed.map((m) => convertMessageToOpenAI(m)).toList();
    chatHistory.add(OpenAIChatCompletionChoiceMessageModel(
      role: OpenAIChatMessageRole.system,
      content: [
        OpenAIChatCompletionChoiceMessageContentItemModel.text(
          "Write a *very* short phrase to summarize the topic of this conversation so far. No emoji.",
        ),
      ],
    ));
    var result = await OpenAI.instance.chat
        .create(model: _labelSummaryModel.value, messages: chatHistory);
    var label = result.choices.first.message.content!
        .where((item) => item.type == 'text' && item.text != null)
        .map((item) => item.text!)
        .join('')
        .trim();

    return label;
  }

  /// getter for currentModel
  LLMModel get currentModel => _currentModel;

  /// setter for currentModel -- notifies listeners of change
  set currentModel(LLMModel value) {
    _currentModel = value;
    notifyListeners();
    // save to disk
    prefs.setString(currentModelKey, _currentModel.value);
  }

  /// getter for currentChatId
  String get currentChatId => _currentChatId;

  /// setter for currentChatId -- notifies listeners of change
  set currentChatId(String value) {
    _currentChatId = value;
    notifyListeners();
  }

  List<UserChatItem> get pastChats => _pastChats;

  String get searchQuery => _searchQuery;

  set searchQuery(String value) {
    if (_searchQuery != value) {
      _searchQuery = value;
      notifyListeners();
    }
  }

  // Future<String> get idAsync async {
  //   await _completer.future; // Wait for initialization if needed
  //   return _id;
  // }
  static OpenAIChatCompletionChoiceMessageModel convertMessageToOpenAI(
      chat_types.Message message) {
    OpenAIChatMessageRole role;
    switch (message.author.role) {
      case chat_types.Role.user:
        role = OpenAIChatMessageRole.user;
        break;
      case chat_types.Role.agent:
        role = OpenAIChatMessageRole.assistant;
        break;
      default:
        role = OpenAIChatMessageRole.user;
    }
    return OpenAIChatCompletionChoiceMessageModel(
      role: role,
      content: [
        OpenAIChatCompletionChoiceMessageContentItemModel.text(
          (message as chat_types.TextMessage).text,
        ),
      ],
    );
  }
}
