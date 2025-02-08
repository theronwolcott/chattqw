import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_chat_ui/flutter_chat_ui.dart';
import 'package:flutter_chat_types/flutter_chat_types.dart' as types;
import 'package:gpt_markdown/gpt_markdown.dart';
import 'package:uuid/uuid.dart';
import 'package:dart_openai/dart_openai.dart';
import 'package:intl/intl.dart';
import 'package:chat_tqw/model_state.dart';

import 'api_service.dart';
import 'user_chat.dart';

class ChatWindow extends StatefulWidget {
  const ChatWindow({super.key});

  @override
  State<ChatWindow> createState() => _ChatWindowState();
}

class _ChatWindowState extends State<ChatWindow> {
  final _modelState = ModelState();
  late UserChat _currentChat;
  late List<OpenAIChatCompletionChoiceMessageModel> _chatHistory;
  final uuid = const Uuid();

  final _user = const types.User(
    id: 'user-123',
    firstName: 'Me',
    role: types.Role.user,
  );

  final _assistant = const types.User(
    id: 'assistant-123',
    firstName: 'Bot',
    role: types.Role.agent,
  );

  @override
  void initState() {
    super.initState();

    // new blank chat
    newBlankChat();

    _modelState.addListener(_handleModelStateChange);
  }

  void newBlankChat() {
    _currentChat = UserChat(
        chatId: uuid.v4(),
        model: _modelState.currentModel,
        createdAt: DateTime.now());
    _chatHistory = [];
    _modelState.currentChatId = _currentChat.chatId;
  }

  void _handleModelStateChange() async {
    // Did the chatId change?
    if (_modelState.currentChatId != _currentChat.chatId) {
      if (_modelState.currentChatId == "") {
        setState(() {
          newBlankChat();
        });
      } else {
        // Perform the asynchronous operation outside of setState.
        final ApiService apiService = ApiService();
        try {
          final newChat = await apiService.fetchSingle<UserChat>(
            "/chat/get",
            UserChat.fromJson,
            body: {
              'chatId': _modelState.currentChatId,
            },
          );
          // Now update the state with the result
          setState(() {
            _currentChat = newChat;
            _currentChat.model = _modelState.currentModel;
            _chatHistory = _currentChat.messages.reversed
                .map((m) => ModelState.convertMessageToOpenAI(m))
                .toList();
          });
        } catch (e) {
          debugPrint("/chat/get Exception");
        }
      }
    }
    // Did the model change?
    if (_modelState.currentModel.value != _currentChat.model.value) {
      // Update the model, then refresh state if needed.
      setState(() {
        _currentChat.model = _modelState.currentModel;
      });
    }
  }

  @override
  void dispose() {
    _modelState.removeListener(_handleModelStateChange);
    super.dispose();
  }

  void _handleSendPressed(types.PartialText message) async {
    final uuid = const Uuid();

    // 1) Insert user message
    final userMessage = types.TextMessage(
      id: uuid.v4(),
      author: _user,
      text: message.text,
      createdAt: DateTime.now().millisecondsSinceEpoch,
    );

    setState(() {
      _currentChat.messages.insert(0, userMessage);
    });

    // 2) Add to conversation history
    _chatHistory.add(
      OpenAIChatCompletionChoiceMessageModel(
        role: OpenAIChatMessageRole.user,
        content: [
          OpenAIChatCompletionChoiceMessageContentItemModel.text(
            message.text,
          ),
        ],
      ),
    );

    // 3) Create a placeholder assistant message
    final botPlaceholderMessage = types.TextMessage(
      id: uuid.v4(),
      author: _assistant,
      text: '${_currentChat.model.name} is thinking . . . ',
      createdAt: DateTime.now().millisecondsSinceEpoch,
    );

    setState(() {
      _currentChat.messages.insert(0, botPlaceholderMessage);
    });

    // We'll remember the index for updating
    final botPlaceholderIndex = 0;
    final buffer = StringBuffer();

    try {
      ("Received partial delta: $_chatHistory");

      // 4) Start streaming
      final stream = OpenAI.instance.chat.createStream(
        model: _currentChat.model.value,
        messages: _chatHistory,
      );

      StreamSubscription<OpenAIStreamChatCompletionModel>? subscription;

      subscription = stream.listen(
        (event) {
          // debugPrint("Received partial delta: ${event.choices.first.delta}");

          final delta = event.choices.first.delta;
          final contentItems = delta.content;
          if (contentItems == null) return;

          final partialText = contentItems
              .where((item) => item?.type == 'text' && item?.text != null)
              .map((item) => item?.text!)
              .join('');

          // debugPrint("Partial text: $partialText");

          if (partialText.isNotEmpty) {
            buffer.write(partialText);

            // Create a fresh message object with updated text
            final updatedMessage = types.TextMessage(
              id: botPlaceholderMessage.id,
              author: botPlaceholderMessage.author,
              text: buffer.toString(),
              createdAt: botPlaceholderMessage.createdAt,
            );

            setState(() {
              // Replace the placeholder in the list
              _currentChat.messages[botPlaceholderIndex] = updatedMessage;
            });
          } else {
            // debugPrint("Empty text: $event");
          }
        },
        onDone: () {
          final finalText = buffer.toString();
          // debugPrint("Finished streaming. Final text: $finalText");

          // Add final text to history
          if (finalText.isNotEmpty) {
            _chatHistory.add(
              OpenAIChatCompletionChoiceMessageModel(
                role: OpenAIChatMessageRole.assistant,
                content: [
                  OpenAIChatCompletionChoiceMessageContentItemModel.text(
                    finalText,
                  ),
                ],
              ),
            );
            // for (var item in _chatHistory) {
            //   print(jsonEncode(item.toMap()));
            // }
            // for (var item in _currentChat.messages) {
            //   print(jsonEncode(item.toJson()));
            // }
            _modelState.saveCurrentChat(_currentChat);
          }
          subscription?.cancel();
        },
        onError: (error) {
          debugPrint("OpenAI streaming error: $error");
          subscription?.cancel();
        },
      );
    } catch (e) {
      debugPrint("Error calling createStream: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      bottom: false,
      child: Chat(
        user: _user,
        messages: _currentChat.messages,
        bubbleBuilder: (child,
            {required message, required nextMessageInGroup}) {
          if (message.type == types.MessageType.text) {
            var textMessage = message as types.TextMessage;
            if (message.author.role == types.Role.agent) {
              return GptMarkdown(
                textMessage.text,
                style:
                    TextStyle(color: Theme.of(context).colorScheme.onSurface),
              );
            } else {
              return Container(
                padding:
                    const EdgeInsets.symmetric(vertical: 15, horizontal: 20),
                decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primaryContainer,
                    borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(15),
                        topRight: Radius.circular(15),
                        bottomLeft: Radius.circular(15))),
                child: GptMarkdown(
                  textMessage.text,
                  style: TextStyle(
                      color: Theme.of(context).colorScheme.onPrimaryContainer),
                ),
              );
            }
          } else {
            return Text("not a text message");
          }
        },
        onSendPressed: _handleSendPressed,
        dateFormat: DateFormat.yMd(),
        timeFormat: DateFormat.jm(),
        theme: DefaultChatTheme(
          primaryColor: Theme.of(context)
              .colorScheme
              .primaryContainer, // Color.fromARGB(255, 222, 186, 255),
          secondaryColor: Color.fromARGB(255, 255, 255, 255),
          inputBackgroundColor: Theme.of(context).colorScheme.primary,
          backgroundColor: Theme.of(context).colorScheme.surfaceContainerLowest,
          messageMaxWidth: 800,
        ),
        messageWidthRatio: 0.85,
        keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      ),
    );
  }
}
