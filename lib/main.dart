import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:dart_openai/dart_openai.dart';
import 'package:provider/provider.dart';
import 'package:flutter/services.dart';
import 'model_state.dart';
import 'drawer_content.dart';
import 'chat_window.dart';
import 'model_selector.dart';
import 'new_chat_button.dart';
import 'user_state.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    // Optionally include portraitDown if you want to allow upside down portrait:
    // DeviceOrientation.portraitDown,
  ]);
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
  // Instantiate the ModelState. This can be used to hold your app’s state.
  final _modelState = ModelState();
  final _userState = UserState();

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<ModelState>(create: (_) => _modelState),
        ChangeNotifierProvider<UserState>(create: (_) => _userState),
      ],
      child: MaterialApp(
        home: Scaffold(
          drawer: const DrawerContent(),
          appBar: AppBar(
            actions: const [
              Padding(
                padding: EdgeInsets.only(right: 8.0),
                child: NewChatButton(),
              ),
            ],
            title: const ModelSelector(),
            centerTitle: true,
          ),
          body: const ChatWindow(),
        ),
      ),
    );
  }
}
