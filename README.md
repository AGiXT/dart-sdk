[![GitHub](https://img.shields.io/badge/GitHub-Sponsor%20Josh%20XT-blue?logo=github&style=plastic)](https://github.com/sponsors/Josh-XT) [![PayPal](https://img.shields.io/badge/PayPal-Sponsor%20Josh%20XT-blue.svg?logo=paypal&style=plastic)](https://paypal.me/joshxt) [![Ko-Fi](https://img.shields.io/badge/Kofi-Sponsor%20Josh%20XT-blue.svg?logo=kofi&style=plastic)](https://ko-fi.com/joshxt)

# AGiXT SDK for Dart

[![GitHub](https://img.shields.io/badge/GitHub-AGiXT%20Core-blue?logo=github&style=plastic)](https://github.com/Josh-XT/AGiXT) [![GitHub](https://img.shields.io/badge/GitHub-AGiXT%20Hub-blue?logo=github&style=plastic)](https://github.com/AGiXT/hub) [![GitHub](https://img.shields.io/badge/GitHub-AGiXT%20NextJS%20Web%20UI-blue?logo=github&style=plastic)](https://github.com/AGiXT/nextjs) [![GitHub](https://img.shields.io/badge/GitHub-AGiXT%20Streamlit%20Web%20UI-blue?logo=github&style=plastic)](https://github.com/AGiXT/streamlit)

[![GitHub](https://img.shields.io/badge/GitHub-AGiXT%20Python%20SDK-blue?logo=github&style=plastic)](https://github.com/AGiXT/python-sdk) [![pypi](https://img.shields.io/badge/pypi-AGiXT%20Python%20SDK-blue?logo=pypi&style=plastic)](https://pypi.org/project/agixtsdk/)

[![GitHub](https://img.shields.io/badge/GitHub-AGiXT%20TypeScript%20SDK-blue?logo=github&style=plastic)](https://github.com/AGiXT/typescript-sdk) [![npm](https://img.shields.io/badge/npm-AGiXT%20TypeScript%20SDK-blue?logo=npm&style=plastic)](https://www.npmjs.com/package/agixt)

[![GitHub](https://img.shields.io/badge/GitHub-AGiXT%20Dart%20SDK-blue?logo=github&style=plastic)](https://github.com/AGiXT/dart-sdk)

[![Discord](https://img.shields.io/discord/1097720481970397356?label=Discord&logo=discord&logoColor=white&style=plastic&color=5865f2)](https://discord.gg/d3TkHRZcjD)
[![Twitter](https://img.shields.io/badge/Twitter-Follow_@Josh_XT-blue?logo=twitter&style=plastic)](https://twitter.com/Josh_XT) 

[![Logo](https://josh-xt.github.io/AGiXT/images/AGiXT-gradient-flat.svg)](https://josh-xt.github.io/AGiXT/)

This repository is for the [AGiXT](https://github.com/Josh-XT/AGiXT) SDK for Dart.

## More Documentation
Want to know more about AGiXT? Check out our [documentation](https://josh-xt.github.io/AGiXT/) or [GitHub](https://github.com/Josh-XT/AGiXT) page.

**AGiXT SDK Documentation**

**Overview**

The AGiXT SDK is a Dart library that provides a comprehensive set of APIs for interacting with the AGiXT platform. The SDK allows developers to create agents, manage conversations, execute commands, handle authentication, and utilize various AI capabilities including text generation, image generation, and speech processing.

**Getting Started**

To use the AGiXT SDK, you need to import the library and create an instance of the `AGiXTSDK` class:
```dart
import 'agixt.dart';

void main() {
  final agixtSDK = AGiXTSDK(
    baseUri: 'http://localhost:7437',
    apiKey: 'YOUR_API_KEY',
  );
}
```

**Authentication**

* `login(String email, String otp)`: Log in with email and OTP
* `registerUser(String email, String firstName, String lastName)`: Register a new user
* `userExists(String email)`: Check if a user exists
* `updateUser(Map<String, dynamic> userData)`: Update user details
* `getUser()`: Get current user details
* `oauth2Login(String provider, String code, {String? referrer})`: OAuth2 authentication

**Agents**

* `getAgents()`: Retrieves a list of all agents
* `getAgentConfig(String agentName)`: Retrieves agent configuration
* `addAgent(String agentName, {Map settings, Map commands, List trainingUrls})`: Creates a new agent
* `updateAgentSettings(String agentName, Map settings)`: Updates agent settings
* `deleteAgent(String agentName)`: Deletes an agent
* `getPersona(String agentName)`: Get agent's persona
* `updatePersona(String agentName, String persona)`: Update agent's persona

**Conversations**

* `getConversations()`: Get all conversations
* `getConversationsWithIds()`: Get conversations with their IDs
* `getConversation(String agentName, String conversationName)`: Get specific conversation
* `newConversation(String agentName, String conversationName)`: Create new conversation
* `deleteConversation(String agentName, String conversationName)`: Delete conversation
* `forkConversation(String conversationName, String messageId)`: Fork a conversation
* `updateConversationMessageById(String messageId, String newMessage, String conversationName)`: Update message by ID
* `deleteConversationMessageById(String messageId, String conversationName)`: Delete message by ID

**AI Capabilities**

* `generateImage(String prompt, {String model, int n, String size, String responseFormat})`: Generate images
* `transcribeAudio(String file, String model, {String? language, String? prompt})`: Transcribe audio to text
* `translateAudio(String file, String model, {String? prompt})`: Translate audio
* `textToSpeech(String agentName, String text)`: Convert text to speech

**Learning & Memory**

* `learnText(String agentName, String userInput, String text)`: Learn from text
* `learnUrl(String agentName, String url)`: Learn from URL
* `learnFile(String agentName, String fileName, String fileContent)`: Learn from file
* `learnGithubRepo(String agentName, String githubRepo)`: Learn from GitHub repository
* `learnArxiv({String agentName, String? query, String? arxivIds})`: Learn from arXiv papers
* `getAgentMemories(String agentName, String userInput)`: Get agent memories
* `exportAgentMemories(String agentName)`: Export memories
* `importAgentMemories(String agentName, List<Map> memories)`: Import memories
* `getUniqueExternalSources(String agentName)`: Get unique external sources

**Commands & Extensions**

* `getCommands(String agentName)`: Get available commands
* `executeCommand(String agentName, String commandName, Map commandArgs)`: Execute command
* `getExtensions()`: Get all extensions
* `getExtensionSettings()`: Get extension settings
* `createExtension(String agentName, String extensionName, String openapiJsonUrl)`: Create new extension

**Chains & Prompts**

* `getChains()`: Get all chains
* `runChain({String chainName, String userInput, String agentName})`: Run a chain
* `getPrompts({String promptCategory})`: Get prompts
* `addPrompt(String promptName, String prompt)`: Add new prompt
* `updatePrompt(String promptName, String prompt)`: Update prompt

**Training**

* `createDataset(String agentName, String datasetName)`: Create training dataset
* `train({String agentName, String datasetName, String model})`: Train on dataset

**Error Handling**

The SDK includes comprehensive error handling:
```dart
dynamic handleError(dynamic error) {
  print("Error: $error");
  throw Exception("Unable to retrieve data. $error");
}
```

All API methods are asynchronous and return Futures. Use try-catch blocks for proper error handling:
```dart
try {
  final agents = await agixtSDK.getAgents();
  print(agents);
} catch (e) {
  print('Error: $e');
}
