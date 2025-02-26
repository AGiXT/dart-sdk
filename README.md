[![GitHub](https://img.shields.io/badge/GitHub-Sponsor%20Josh%20XT-blue?logo=github&style=plastic)](https://github.com/sponsors/Josh-XT) [![PayPal](https://img.shields.io/badge/PayPal-Sponsor%20Josh%20XT-blue.svg?logo=paypal&style=plastic)](https://paypal.me/joshxt) [![Ko-Fi](https://img.shields.io/badge/Kofi-Sponsor%20Josh%20XT-blue.svg?logo=kofi&style=plastic)](https://ko-fi.com/joshxt)

# AGiXT SDK for Dart

[![GitHub](https://img.shields.io/badge/GitHub-AGiXT%20Core-blue?logo=github&style=plastic)](https://github.com/Josh-XT/AGiXT) [![GitHub](https://img.shields.io/badge/GitHub-AGiXT%20Hub-blue?logo=github&style=plastic)](https://github.com/AGiXT/hub) [![GitHub](https://img.shields.io/badge/GitHub-AGiXT%20NextJS%20Web%20UI-blue?logo=github&style=plastic)](https://github.com/AGiXT/nextjs) [![GitHub](https://img.shields.io/badge/GitHub-AGiXT%20Streamlit%20Web%20UI-blue?logo=github&style=plastic)](https://github.com/AGiXT/streamlit)

[![GitHub](https://img.shields.io/badge/GitHub-AGiXT%20Python%20SDK-blue?logo=github&style=plastic)](https://github.com/AGiXT/python-sdk) [![pypi](https://img.shields.io/badge/pypi-AGiXT%20Python%20SDK-blue?logo=pypi&style=plastic)](https://pypi.org/project/agixtsdk/)

[![GitHub](https://img.shields.io/badge/GitHub-AGiXT%20TypeScript%20SDK-blue?logo=github&style=plastic)](https://github.com/AGiXT/typescript-sdk) [![npm](https://img.shields.io/badge/npm-AGiXT%20TypeScript%20SDK-blue?logo=npm&style=plastic)](https://www.npmjs.com/package/agixt)

[![GitHub](https://img.shields.io/badge/GitHub-AGiXT%20Dart%20SDK-blue?logo=github&style=plastic)](https://github.com/AGiXT/dart-sdk)

[![Discord](https://img.shields.io/discord/1097720481970397356?label=Discord&logo=discord&logoColor=white&style=plastic&color=5865f2)](https://discord.gg/d3TkHRZcjD)
[![Twitter](https://img.shields.io/badge/Twitter-Follow_@Josh_XT-blue?logo=twitter&style=plastic)](https://twitter.com/Josh_XT) 

![AGiXT_New](https://github.com/user-attachments/assets/14a5c1ae-6af8-4de8-a82e-f24ea52da23f)


This repository is for the [AGiXT](https://github.com/Josh-XT/AGiXT) SDK for Dart.

## More Documentation
Want to know more about AGiXT?  Check out our [documentation](https://josh-xt.github.io/AGiXT/) or [GitHub](https://github.com/Josh-XT/AGiXT) page.


**AGiXT SDK Documentation**

**Overview**

The AGiXT SDK is a Dart library that provides a set of APIs for interacting with the AGiXT platform. The SDK allows developers to create agents, manage conversations, and execute commands on the platform.

**Getting Started**

To use the AGiXT SDK, you need to import the library and create an instance of the `AGiXTSDK` class, passing in the base URI and API key as parameters.
```dart
import 'agixt.dart';

void main() {
  final agixtSDK = AGiXTSDK(
    baseUri: 'http://localhost:7437',
    apiKey: 'YOUR_API_KEY',
  );
}
```
**APIs**

The AGiXT SDK provides a wide range of APIs for interacting with the platform. Here are some of the key APIs:

### Agents

* `getAgents()`: Retrieves a list of all agents on the platform.
* `getAgentConfig(String agentName)`: Retrieves the configuration for a specific agent.
* `addAgent(String agentName, Map<String, dynamic> settings)`: Creates a new agent with the specified settings.
* `updateAgentSettings(String agentName, Map<String, dynamic> settings)`: Updates the settings for an existing agent.
* `deleteAgent(String agentName)`: Deletes an agent from the platform.

### Conversations

* `getConversations(String agentName)`: Retrieves a list of conversations for a specific agent.
* `getConversation(String agentName, String conversationName)`: Retrieves a specific conversation for an agent.
* `newConversation(String agentName, String conversationName, List<Map<String, dynamic>> conversationContent)`: Creates a new conversation for an agent.
* `deleteConversation(String agentName, String conversationName)`: Deletes a conversation from an agent.

### Commands

* `getCommands(String agentName)`: Retrieves a list of commands for a specific agent.
* `executeCommand(String agentName, String commandName, Map<String, dynamic> commandArgs)`: Executes a command on an agent.
* `addCommand(String agentName, String commandName, Map<String, dynamic> commandArgs)`: Adds a new command to an agent.
* `updateCommand(String agentName, String commandName, Map<String, dynamic> commandArgs)`: Updates an existing command on an agent.
* `deleteCommand(String agentName, String commandName)`: Deletes a command from an agent.

### Chains

* `getChains()`: Retrieves a list of all chains on the platform.
* `getChain(String chainName)`: Retrieves a specific chain.
* `addChain(String chainName)`: Creates a new chain.
* `updateChain(String chainName, Map<String, dynamic> chainArgs)`: Updates an existing chain.
* `deleteChain(String chainName)`: Deletes a chain from the platform.

### Prompts

* `getPrompts()`: Retrieves a list of all prompts on the platform.
* `getPrompt(String promptName)`: Retrieves a specific prompt.
* `addPrompt(String promptName, String prompt)`: Creates a new prompt.
* `updatePrompt(String promptName, String prompt)`: Updates an existing prompt.
* `deletePrompt(String promptName)`: Deletes a prompt from the platform.

### Extensions

* `getExtensionSettings()`: Retrieves the settings for all extensions on the platform.
* `getExtensions()`: Retrieves a list of all extensions on the platform.
* `getCommandArgs(String commandName)`: Retrieves the arguments for a specific command.

### Learning

* `learnText(String agentName, String userInput, String text)`: Learns from a text input.
* `learnUrl(String agentName, String url)`: Learns from a URL.
* `learnFile(String agentName, String fileName, String fileContent)`: Learns from a file.
* `learnGithubRepo(String agentName, String githubRepo)`: Learns from a GitHub repository.

### Memory

* `getAgentMemories(String agentName, String userInput)`: Retrieves a list of memories for an agent.
* `exportAgentMemories(String agentName)`: Exports the memories for an agent.
* `importAgentMemories(String agentName, List<Map<String, dynamic>> memories)`: Imports memories into an agent.

### Dataset

* `createDataset(String agentName, String datasetName)`: Creates a new dataset for an agent.
* `train(String agentName, String datasetName)`: Trains a model on a dataset.

### Text-to-Speech

* `textToSpeech(String agentName, String text, String conversationName)`: Converts text to speech using an agent.

**Error Handling**

The AGiXT SDK provides a `handleError` function that can be used to handle errors that occur during API calls.
```dart
Future<String> handleError(error) {
  print('Error: $error');
  return 'Unable to retrieve data.';
}
```
