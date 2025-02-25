# ChatTQW - Universal AI Chatbot for iOS & Android

<img src="images/ChatTQW_1.gif" width="365" height="720" alt="ChatTQW demo" align="right">

A **generative AI chatbot mobile app** that supports multiple **LLM models** (GPT-4, Claude, DeepSeek, Gemini, LLaMA, etc.) and provides a **seamless chat experience** with **local state management**, **real-time message streaming** and connects to a [**Node.js API back-end**](https://github.com/theronwolcott/chattqw-node).

This project demonstrates **full-stack execution**, including:
- **Flutter mobile app** (front-end)
- **Node.js API server** (back-end --- [project link](https://github.com/theronwolcott/chattqw-node)
- **MongoDB database** (persistent user info and chat history)
- **Multi-LLM support** (OpenAI, Anthropic, DeepSeek, Meta, Google)
- **State management** with Provider

### Features

- **Multi-LLM Support**: Easily switch between OpenAI, Anthropic, DeepSeek, Meta, and Google AI models --- even in the middle of a chat.
- **Real-Time Message Streaming**: AI responses appear token-by-token, just like ChatGPT.
- **User Sign Up and Login**: User login info is stored and retrieved from a **NodeJS** backend, backed by **MongoDB**.
- **Persistent Chat History**: Conversations are also stored and retrieved from the backend.
- **Searchable Chat Drawer**: View, filter, and revisit past conversations.
- **Smart Chat Labeling**: Automatically generates conversation titles using an LLM model.
- **Stateful UI Management**: Uses **Provider** to maintain app-wide state efficiently.
- **API-Driven Backend**: Node.js server with a **RESTful API** to manage chats.
- **User Preferences**: Stores user preferences locally via **SharedPreferences**.
- **Secure API Calls**: Fetches data securely using **HTTP requests with dotenv-based API keys**.

### Tech Stack

#### Front-End (Flutter)
- **Dart** (Flutter framework)
- **Provider** (State management)
- **flutter_chat_ui** (Chat interface)
- **dart_openai** (OpenAI API interface)
- **gpt_markdown** (Markdown rendering for AI responses)
- **flutter_login** (Sign Up/Login flow)
- **flutter_dotenv** (Environment variables)

#### Back-End (Node.js --- [project link](https://github.com/theronwolcott/chattqw-node)
- **Express.js** (API framework)
- **MongoDB & Mongoose** (Database & ODM)
- **dotenv** (Environment variables)
- **bcrypt** (Password hashing)
- **uuid** (Chat ID management)

#### Database
- **MongoDB** (Atlas Cloud Database)
- Stores **chat history**, **user information**, and **conversation metadata**.

## Architecture Overview

This project follows a **modular, provider-driven architecture** for **scalability** and **efficiency**.

### 📌 **Core Components**

#### **1. `main.dart`** - Entry Point
- Initializes Flutter app.
- Loads environment variables (`.env`).
- Sets up state management (`Provider`).
- Instantiates the **chat UI**, **drawer menu**, and **model selector**.

#### **2. `chat_window.dart`** - Chat UI
- Displays the conversation.
- Supports **Markdown AI responses** (via `gpt_markdown`).
- Implements **real-time message streaming**.
- Handles **user input**, **message history**, and **LLM interactions**.

#### **3. `model_state.dart`** - Global Model State Singleton
- Tracks **current LLM model**, **chat history**, and **search queries**.
- Stores data using **SharedPreferences**.
- Manages API calls and UI updates **efficiently** with `ChangeNotifier`.

#### **4. `drawer_content.dart`** - Chat History Drawer
- Displays **past chats**, organized by date.
- Implements **search filtering**.
- Allows switching between past conversations.

#### **5. `model_selector.dart`** - LLM Model Selector
- Custom multi-level dropdown menu for selecting **OpenAI, Anthropic, DeepSeek, Google, or Meta** models.
- Updates the **selected AI model in real-time**.

#### **6. `login_screen.dart`** - Sign Up/Login Flow
- Wires login/sign up UI to UserState() (below).
- Uses `flutter_login` plugin for UI.

#### **7. `user_state.dart`** - Global User State Singleton
- Calls **API endpoints** login/sign up.
- Uses `flutter_login` plugin.

#### **8. `api_service.dart`** - API Communication Layer
- Handles **secure API requests** to the Node.js backend.
- Supports **user sign up/login**, **fetching chat history**, **saving messages**, and **updating chat metadata**.

#### **9.  [Node.js Backend](https://github.com/theronwolcott/chattqw-node)**
- **MongoDB database** for chat storage.
- **Express.js API** endpoints:
  - `/chat/list` - Fetch all past chats.
  - `/chat/get` - Retrieve a specific conversation.
  - `/chat/update` - Update chat labels.
  - `/chat/save-messages` - Store new messages.
  - `/user/get` - Retrieves details for the current user.
  - `/user/login` - Authenticates existing users.
  - `/user/signup` - Registers new users.
- **Indexes for fast lookups** and **atomic updates**.

## API Endpoints

| Method | Endpoint                | Description                           |
|--------|-------------------------|---------------------------------------|
| `POST` | `/chat/list`            | Fetches the list of past user chats  |
| `POST` | `/chat/get`             | Retrieves a specific chat by ID      |
| `POST` | `/chat/update`          | Updates chat labels                  |
| `POST` | `/chat/save-messages`   | Saves new chat messages              |
| `POST` | `/user/get`             | Retrieves the current user           |
| `POST` | `/user/login`           | Authenticates existing users         |
| `POST` | `/user/signup`          | Registers new users                  |

### **Example API Call**
```dart
final ApiService apiService = ApiService();
final chats = await apiService.fetchList<UserChatItem>(
  "/chat/list",
  UserChatItem.fromJson,
    body: {
        'chatId':  [current chat id],
    },
);
// ApiService automatically adds 'userId': [current user id]
```

## 📱 How It Works

1. **User opens the app** - The application launches, initializing the chat UI and loading past conversations from the database.
2. **Selects an AI model** - Users can choose any model from OpenAI, Anthropic, DeepSeek, Meta, and Google.
3. **Starts a conversation** - The user types a message, which is processed in real-time. The app creates a new chat session if none exists.
4. **Real-time message streaming** - AI responses are generated incrementally and displayed as they arrive, creating a smooth and interactive experience.
5. **Chat is auto-labeled** - Using an LLM, a concise summary or title is generated for each conversation and stored for easy reference.
6. **Search and navigate past chats** - Users can access past conversations via the drawer, organized by time and searchable via a query field.
7. **Chats are saved persistently** - Each conversation is stored in MongoDB with timestamps and models used, ensuring seamless retrieval even after restarting the app. The user can pick up where they left off with any past conversation.
8. **User preferences are maintained** - The app retains the selected AI model and chat history using shared preferences, offering a consistent user experience across sessions.
9. **Supports user registration and login** - Users can log in from different devices, retrieve their chat history, and pick up right where they left off.

## 🛠️ Setup Instructions

### **1. Clone the Repository**
```sh
git clone https://github.com/theronwolcott/chattqw.git
cd chattqw
```

### **2. Install Flutter Dependencies**
```sh
flutter pub get
```

### **3. Configure Environment Variables**
Create a `.env` file with your API keys:
```
OPENAI_API_KEY=your_openai_api_key
OPENAI_BASE_URL=your_base_url
API_ROOT=http://your-node-server.com
```

### **4. Run the Flutter App**
```sh
flutter run
```

### **5. Run the Back-End Project**
See [ChatTQW Back-End Project](https://github.com/theronwolcott/chattqw-node) (Node.js)

## Screenshots

| Chat UI | Chat History Drawer | Model Selector |
|---------|---------------------|----------------|
| ![Chat](images/chat_ui.png) | ![Drawer](images/chat_drawer.png) | ![Model](images/model_selector.png) |


## 🚀 Future Enhancements

- [ ] **User-Selected AI Models** - Allow user-identified custom models.
- [ ] **Offline Mode** - Local storage for chat history.
- [ ] **Voice Support** - Dictate messages and listen to response.
- [ ] **Rich Media Support** - Handle images & files.

## 📩 Contact

Theron Wolcott  
📧 Email: theronwolcott@gmail.com  
🔗 LinkedIn: [linkedin.com/in/theronwolcott](https://linkedin.com/in/theronwolcott)  
💻 GitHub: [github.com/theronwolcott](https://github.com/theronwolcott)

