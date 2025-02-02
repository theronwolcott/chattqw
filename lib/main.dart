import 'package:chat_tqw/chat_window.dart';
import 'package:chat_tqw/llm_model.dart';
import 'package:chat_tqw/model_state.dart';
import 'package:provider/provider.dart';
import 'package:chat_tqw/drawer_content.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:dart_openai/dart_openai.dart';

void main() async {
  // Ensure flutter bindings are initialized
  WidgetsFlutterBinding.ensureInitialized();

  await dotenv.load(fileName: ".env");
  OpenAI.apiKey = dotenv.env['OPENAI_API_KEY']!;
  OpenAI.baseUrl = dotenv.env['OPENAI_BASE_URL']!;
  runApp(const ChatApp());
}

class ChatApp extends StatefulWidget {
  const ChatApp({super.key});

  @override
  State<ChatApp> createState() => _ChatAppState();
}

class _ChatAppState extends State<ChatApp> {
  final _modelState = ModelState();
  late LLMModel selectedModel;

  @override
  void initState() {
    super.initState();
    selectedModel = _modelState.currentModel;
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<ModelState>(create: (_) => _modelState),
      ],
      child: MaterialApp(
        home: Scaffold(
          drawer: DrawerContent(),
          appBar: AppBar(
            actions: [
              Padding(
                padding: const EdgeInsets.only(right: 8.0),
                child: IconButton(
                  icon: const Icon(Icons.edit_square),
                  tooltip: 'New Chat',
                  onPressed: () {
                    _modelState.currentChatId = "";
                  },
                ),
              ),
            ],
            title: MenuAnchor(
              alignmentOffset: Offset(0, 10), // Center dynamically
              builder: (BuildContext context, MenuController controller,
                  Widget? child) {
                return GestureDetector(
                  onTap: () {
                    if (controller.isOpen) {
                      controller.close();
                    } else {
                      controller.open();
                    }
                  },
                  child: RichText(
                    text: TextSpan(
                      children: <TextSpan>[
                        TextSpan(
                            text: 'ChatTQW',
                            style: Theme.of(context).textTheme.titleLarge),
                        TextSpan(
                            text: ' ${selectedModel.short} ›',
                            style: Theme.of(context)
                                .textTheme
                                .labelLarge!
                                .copyWith(
                                  color: Theme.of(context)
                                      .colorScheme
                                      .outlineVariant,
                                )),
                      ],
                    ),
                  ),
                );
              },
              menuChildren: ModelState.availableModels.map((model) {
                return MenuItemButton(
                  onPressed: () {
                    setState(() {
                      selectedModel = model;
                      _modelState.currentModel = model;
                    });
                  },
                  child: Text("${model.company.value}: ${model.name}"),
                );
              }).toList(),
            ),
            centerTitle: true, // Ensure the dropdown stays centered
          ),
          body: ChatWindow(),
        ),
      ),
    );
  }
}
