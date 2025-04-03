import 'dart:convert';
import 'dart:io' show Directory, File;
import 'package:http/http.dart' as http;
import 'tokenizer.dart';

class ChatCompletions {
  String model;
  List<Map<String, dynamic>>? messages;
  double? temperature;
  double? topP;
  List<Map<String, dynamic>>? tools;
  String? toolsChoice;
  int? n;
  bool? stream;
  List<String>? stop;
  int? maxTokens;
  double? presencePenalty;
  double? frequencyPenalty;
  Map<String, double>? logitBias;
  String? user;

  ChatCompletions({
    this.model = "gpt4free",
    this.messages,
    this.temperature = 0.9,
    this.topP = 1.0,
    this.tools,
    this.toolsChoice = "auto",
    this.n = 1,
    this.stream = false,
    this.stop,
    this.maxTokens = 4096,
    this.presencePenalty = 0.0,
    this.frequencyPenalty = 0.0,
    this.logitBias,
    this.user = "Chat",
  });
}


class AGiXTSDK {
  String baseUri;
  Map<String, String> headers;

  final bool verbose;

  AGiXTSDK({String? baseUri, String? apiKey, this.verbose = false})
      : baseUri = baseUri?.replaceAll(RegExp(r'/$'), '') ?? "http://localhost:7437",
        headers = {
          "Content-Type": "application/json",
          if (apiKey != null) "Authorization": apiKey.replaceAll(RegExp(r'^(Bearer |bearer )'), ''),
        };

  void parseResponse(http.Response response) {
    if (verbose) {
      print("Status Code: ${response.statusCode}");
      print("Response JSON:");
      if (response.statusCode == 200) {
        print(jsonDecode(response.body));
      } else {
        print(response.body);
        throw Exception("Request failed");
      }
      print("\n");
    }
  }

  dynamic handleError(dynamic error) {
    if (verbose) {
      print("Error occurred:");
      print(error);
    }
    throw Exception("Unable to retrieve data. $error");
  }
  
  Future<http.Response> _processResponse(http.Response response) async {
    if (verbose) {
      parseResponse(response);
    }
    return response;
  }

  Future<List<String>> getProviders() async {
    try {
      final response = await http.get(Uri.parse("$baseUri/api/provider"), headers: headers)
          .then(_processResponse);
      if (verbose) {
        print("Got providers response: ${response.body}");
      }
      return List<String>.from(jsonDecode(response.body)["providers"]);
    } catch (e) {
      return handleError(e);
    }
  }

  Future<List<Map<String, dynamic>>> getOAuthProviders() async {
    try {
      final response = await http.get(Uri.parse("$baseUri/v1/oauth"), headers: headers)
          .then(_processResponse);
      // Expecting a JSON like {"providers": [{"name": "google", "client_id": "...", ...}, ...]}
      final decodedBody = jsonDecode(response.body);
      if (decodedBody is Map<String, dynamic> && decodedBody.containsKey('providers') && decodedBody['providers'] is List) {
        // Ensure each item in the list is a Map<String, dynamic>
        return List<Map<String, dynamic>>.from(decodedBody['providers'].map((item) {
          if (item is Map<String, dynamic>) {
            return item;
          } else {
            // Handle unexpected item type if necessary, or throw error
            if (verbose) {
              print("Warning: Unexpected item type in OAuth providers list: $item");
            }
            // Returning an empty map or throwing might be options
            return <String, dynamic>{}; // Or throw an exception
          }
        }));
      } else {
         if (verbose) {
            print("Error: Unexpected response format for OAuth providers. Expected {'providers': [...]}. Got: ${response.body}");
         }
        throw Exception("Unexpected response format for OAuth providers.");
      }
    } catch (e) {
      return handleError(e);
    }
  }

  Future<List<String>> getProvidersByService(String service) async {
    try {
      final response = await http.get(Uri.parse("$baseUri/api/providers/service/$service"), headers: headers);
      return List<String>.from(jsonDecode(response.body)["providers"]);
    } catch (e) {
      return handleError(e);
    }
  }

  Future<Map<String, dynamic>> getProviderSettings(String providerName) async {
    try {
      final response = await http.get(Uri.parse("$baseUri/api/provider/$providerName"), headers: headers);
      return Map<String, dynamic>.from(jsonDecode(response.body)["settings"]);
    } catch (e) {
      return handleError(e);
    }
  }

  Future<List<String>> getEmbedProviders() async {
    try {
      final response = await http.get(Uri.parse("$baseUri/api/embedding_providers"), headers: headers);
      return List<String>.from(jsonDecode(response.body)["providers"]);
    } catch (e) {
      return handleError(e);
    }
  }

  Future<Map<String, dynamic>> getEmbedders() async {
    try {
      final response = await http.get(Uri.parse("$baseUri/api/embedders"), headers: headers);
      return Map<String, dynamic>.from(jsonDecode(response.body)["embedders"]);
    } catch (e) {
      return handleError(e);
    }
  }

  Future<Map<String, dynamic>> addAgent(
    String agentName, {
    Map<String, dynamic> settings = const {},
    Map<String, dynamic> commands = const {},
    List<String> trainingUrls = const [],
  }) async {
    try {
      final response = await http.post(
        Uri.parse("$baseUri/api/agent"),
        headers: headers,
        body: jsonEncode({
          "agent_name": agentName,
          "settings": settings,
          "commands": commands,
          "training_urls": trainingUrls,
        }),
      );
      return jsonDecode(response.body);
    } catch (e) {
      return handleError(e);
    }
  }

  Future<Map<String, dynamic>> importAgent(
    String agentName, {
    Map<String, dynamic> settings = const {},
    Map<String, dynamic> commands = const {},
  }) async {
    try {
      final response = await http.post(
        Uri.parse("$baseUri/api/agent/import"),
        headers: headers,
        body: jsonEncode({
          "agent_name": agentName,
          "settings": settings,
          "commands": commands,
        }),
      );
      return jsonDecode(response.body);
    } catch (e) {
      return handleError(e);
    }
  }

  Future<String> renameAgent(String agentName, String newName) async {
    try {
      final response = await http.patch(
        Uri.parse("$baseUri/api/agent/$agentName"),
        headers: headers,
        body: jsonEncode({"new_name": newName}),
      );
      return jsonDecode(response.body);
    } catch (e) {
      return handleError(e);
    }
  }

  Future<String> updateAgentSettings(String agentName, Map<String, dynamic> settings) async {
    try {
      final response = await http.put(
        Uri.parse("$baseUri/api/agent/$agentName"),
        headers: headers,
        body: jsonEncode({"settings": settings, "agent_name": agentName}),
      );
      return jsonDecode(response.body)["message"];
    } catch (e) {
      return handleError(e);
    }
  }

  Future<String> updateAgentCommands(String agentName, Map<String, dynamic> commands) async {
    try {
      final response = await http.put(
        Uri.parse("$baseUri/api/agent/$agentName/commands"),
        headers: headers,
        body: jsonEncode({"commands": commands, "agent_name": agentName}),
      );
      return jsonDecode(response.body)["message"];
    } catch (e) {
      return handleError(e);
    }
  }

  Future<String> deleteAgent(String agentName) async {
    try {
      final response = await http.delete(Uri.parse("$baseUri/api/agent/$agentName"), headers: headers);
      return jsonDecode(response.body)["message"];
    } catch (e) {
      return handleError(e);
    }
  }

  Future<List<Map<String, dynamic>>> getAgents() async {
    try {
      final response = await http.get(Uri.parse("$baseUri/api/agent"), headers: headers);
      return List<Map<String, dynamic>>.from(jsonDecode(response.body)["agents"]);
    } catch (e) {
      return handleError(e);
    }
  }

  Future<Map<String, dynamic>> getAgentConfig(String agentName) async {
    try {
      final response = await http.get(Uri.parse("$baseUri/api/agent/$agentName"), headers: headers);
      return Map<String, dynamic>.from(jsonDecode(response.body)["agent"]);
    } catch (e) {
      return handleError(e);
    }
  }

  Future<List<String>> getConversations({String agentName = ""}) async {
    try {
      final response = await http.get(Uri.parse("$baseUri/api/conversations"), headers: headers);
      return List<String>.from(jsonDecode(response.body)["conversations"]);
    } catch (e) {
      return handleError(e);
    }
  }

  Future<List<String>> getConversationsWithIds() async {
    try {
      final response = await http.get(Uri.parse("$baseUri/api/conversations"), headers: headers);
      return List<String>.from(jsonDecode(response.body)["conversations_with_ids"]);
    } catch (e) {
      return handleError(e);
    }
  }

  Future<List<Map<String, dynamic>>> getConversation(
    String agentName,
    String conversationName, {
    int limit = 100,
    int page = 1,
  }) async {
    try {
      final response = await http.post(
        Uri.parse("$baseUri/api/conversation/query"),
        headers: headers,
        body: jsonEncode({
          "conversation_name": conversationName,
          "agent_name": agentName,
          "limit": limit,
          "page": page,
        }),
      );
      return List<Map<String, dynamic>>.from(jsonDecode(response.body)["conversation_history"]);
    } catch (e) {
      return handleError(e);
    }
  }

  Future<List<Map<String, dynamic>>> newConversation(
    String agentName,
    String conversationName, {
    List<Map<String, dynamic>> conversationContent = const [],
  }) async {
    try {
      final response = await http.post(
        Uri.parse("$baseUri/api/conversation"),
        headers: headers,
        body: jsonEncode({
          "conversation_name": conversationName,
          "agent_name": agentName,
          "conversation_content": conversationContent,
        }),
      );
      return List<Map<String, dynamic>>.from(jsonDecode(response.body)["conversation_history"]);
    } catch (e) {
      return handleError(e);
    }
  }

  Future<String> renameConversation(
    String agentName,
    String conversationName, {
    String newName = "-",
  }) async {
    try {
      final response = await http.put(
        Uri.parse("$baseUri/api/conversation"),
        headers: headers,
        body: jsonEncode({
          "conversation_name": conversationName,
          "new_conversation_name": newName,
          "agent_name": agentName,
        }),
      );
      return jsonDecode(response.body)["conversation_name"];
    } catch (e) {
      return handleError(e);
    }
  }

  Future<String> deleteConversation(String agentName, String conversationName) async {
    try {
      final response = await http.delete(
        Uri.parse("$baseUri/api/conversation"),
        headers: headers,
        body: jsonEncode({
          "conversation_name": conversationName,
          "agent_name": agentName,
        }),
      );
      return jsonDecode(response.body)["message"];
    } catch (e) {
      return handleError(e);
    }
  }

  Future<String> deleteConversationMessage(String agentName, String conversationName, String message) async {
    try {
      final response = await http.delete(
        Uri.parse("$baseUri/api/conversation/message"),
        headers: headers,
        body: jsonEncode({
          "message": message,
          "agent_name": agentName,
          "conversation_name": conversationName,
        }),
      );
      return jsonDecode(response.body)["message"];
    } catch (e) {
      return handleError(e);
    }
  }

  Future<String> updateConversationMessage(String agentName, String conversationName, String message, String newMessage) async {
    try {
      final response = await http.put(
        Uri.parse("$baseUri/api/conversation/message"),
        headers: headers,
        body: jsonEncode({
          "message": message,
          "new_message": newMessage,
          "agent_name": agentName,
          "conversation_name": conversationName,
        }),
      );
      return jsonDecode(response.body)["message"];
    } catch (e) {
      return handleError(e);
    }
  }

  Future<String> newConversationMessage({
    String role = "user",
    String message = "",
    String conversationName = "",
  }) async {
    try {
      final response = await http.post(
        Uri.parse("$baseUri/api/conversation/message"),
        headers: headers,
        body: jsonEncode({
          "role": role,
          "message": message,
          "conversation_name": conversationName,
        }),
      );
      return jsonDecode(response.body)["message"];
    } catch (e) {
      return handleError(e);
    }
  }

  Future<String> promptAgent({
    required String agentName,
    required String promptName,
    required Map<String, dynamic> promptArgs,
  }) async {
    try {
      final response = await http.post(
        Uri.parse("$baseUri/api/agent/$agentName/prompt"),
        headers: headers,
        body: jsonEncode({
          "prompt_name": promptName,
          "prompt_args": promptArgs,
        }),
      );
      return jsonDecode(response.body)["response"];
    } catch (e) {
      return handleError(e);
    }
  }

  Future<String> instruct(String agentName, String userInput, String conversation) async {
    return promptAgent(
      agentName: agentName,
      promptName: "instruct",
      promptArgs: {
        "user_input": userInput,
        "disable_memory": true,
        "conversation_name": conversation,
      },
    );
  }

  Future<String> chat(
    String agentName,
    String userInput,
    String conversation, {
    int contextResults = 4,
  }) async {
    return promptAgent(
      agentName: agentName,
      promptName: "Chat",
      promptArgs: {
        "user_input": userInput,
        "context_results": contextResults,
        "conversation_name": conversation,
        "disable_memory": true,
      },
    );
  }

  Future<String> smartInstruct(String agentName, String userInput, String conversation) async {
    final response = await runChain(
      chainName: "Smart Instruct",
      userInput: userInput,
      agentName: agentName,
      allResponses: false,
      fromStep: 1,
      chainArgs: {
        "conversation_name": conversation,
        "disable_memory": true,
      },
    );
    return response.toString();
  }
Future<String> smartChat(String agentName, String userInput, String conversation) async {
  final response = await runChain(
    chainName: "Smart Chat",
    userInput: userInput,
    agentName: agentName,
    allResponses: false,
    fromStep: 1,
    chainArgs: {
      "conversation_name": conversation,
      "disable_memory": true,
    },
  );
  return response.toString();
  }

  Future<Map<String, Map<String, bool>>> getCommands(String agentName) async {
    try {
      final response = await http.get(Uri.parse("$baseUri/api/agent/$agentName/command"), headers: headers);
      return Map<String, Map<String, bool>>.from(jsonDecode(response.body)["commands"]);
    } catch (e) {
      return handleError(e);
    }
  }

  Future<String> toggleCommand(String agentName, String commandName, bool enable) async {
    try {
      final response = await http.patch(
        Uri.parse("$baseUri/api/agent/$agentName/command"),
        headers: headers,
        body: jsonEncode({
          "command_name": commandName,
          "enable": enable,
        }),
      );
      return jsonDecode(response.body)["message"];
    } catch (e) {
      return handleError(e);
    }
  }

  Future<dynamic> executeCommand(
    String agentName,
    String commandName,
    Map<String, dynamic> commandArgs, {
    String conversationName = "AGiXT Terminal Command Execution",
  }) async {
    try {
      final response = await http.post(
        Uri.parse("$baseUri/api/agent/$agentName/command"),
        headers: headers,
        body: jsonEncode({
          "command_name": commandName,
          "command_args": commandArgs,
          "conversation_name": conversationName,
        }),
      );
      return jsonDecode(response.body)["response"];
    } catch (e) {
      return handleError(e);
    }
  }

  Future<List<String>> getChains() async {
    try {
      final response = await http.get(Uri.parse("$baseUri/api/chain"), headers: headers);
      return List<String>.from(jsonDecode(response.body));
    } catch (e) {
      return handleError(e);
    }
  }

  Future<Map<String, dynamic>> getChain(String chainName) async {
    try {
      final response = await http.get(Uri.parse("$baseUri/api/chain/$chainName"), headers: headers);
      return Map<String, dynamic>.from(jsonDecode(response.body)["chain"]);
    } catch (e) {
      return handleError(e);
    }
  }

  Future<Map<String, dynamic>> getChainResponses(String chainName) async {
    try {
      final response = await http.get(Uri.parse("$baseUri/api/chain/$chainName/responses"), headers: headers);
      return Map<String, dynamic>.from(jsonDecode(response.body)["chain"]);
    } catch (e) {
      return handleError(e);
    }
  }

  Future<List<String>> getChainArgs(String chainName) async {
    try {
      final response = await http.get(Uri.parse("$baseUri/api/chain/$chainName/args"), headers: headers);
      return List<String>.from(jsonDecode(response.body)["chain_args"]);
    } catch (e) {
      return handleError(e);
    }
  }

  Future<dynamic> runChain({
    required String chainName,
    required String userInput,
    String agentName = "",
    bool allResponses = false,
    int fromStep = 1,
    Map<String, dynamic> chainArgs = const {},
  }) async {
    try {
      final response = await http.post(
        Uri.parse("$baseUri/api/chain/$chainName/run"),
        headers: headers,
        body: jsonEncode({
          "prompt": userInput,
          "agent_override": agentName,
          "all_responses": allResponses,
          "from_step": fromStep,
          "chain_args": chainArgs,
        }),
      );
      return jsonDecode(response.body);
    } catch (e) {
      return handleError(e);
    }
  }

  Future<dynamic> runChainStep({
    required String chainName,
    required int stepNumber,
    required String userInput,
    String? agentName,
    Map<String, dynamic> chainArgs = const {},
  }) async {
    try {
      final response = await http.post(
        Uri.parse("$baseUri/api/chain/$chainName/run/step/$stepNumber"),
        headers: headers,
        body: jsonEncode({
          "prompt": userInput,
          "agent_override": agentName,
          "chain_args": chainArgs,
        }),
      );
      return jsonDecode(response.body);
    } catch (e) {
      return handleError(e);
    }
  }

  Future<String> addChain(String chainName) async {
    try {
      final response = await http.post(
        Uri.parse("$baseUri/api/chain"),
        headers: headers,
        body: jsonEncode({"chain_name": chainName}),
      );
      return jsonDecode(response.body)["message"];
    } catch (e) {
      return handleError(e);
    }
  }

  Future<String> importChain(String chainName, Map<String, dynamic> steps) async {
    try {
      final response = await http.post(
        Uri.parse("$baseUri/api/chain/import"),
        headers: headers,
        body: jsonEncode({"chain_name": chainName, "steps": steps}),
      );
      return jsonDecode(response.body)["message"];
    } catch (e) {
      return handleError(e);
    }
  }

  Future<String> renameChain(String chainName, String newName) async {
    try {
      final response = await http.put(
        Uri.parse("$baseUri/api/chain/$chainName"),
        headers: headers,
        body: jsonEncode({"new_name": newName}),
      );
      return jsonDecode(response.body)["message"];
    } catch (e) {
      return handleError(e);
    }
  }

  Future<String> deleteChain(String chainName) async {
    try {
      final response = await http.delete(Uri.parse("$baseUri/api/chain/$chainName"), headers: headers);
      return jsonDecode(response.body)["message"];
    } catch (e) {
      return handleError(e);
    }
  }

  Future<String> addStep(
    String chainName,
    int stepNumber,
    String agentName,
    String promptType,
    Map<String, dynamic> prompt,
  ) async {
    try {
      final response = await http.post(
        Uri.parse("$baseUri/api/chain/$chainName/step"),
        headers: headers,
        body: jsonEncode({
          "step_number": stepNumber,
          "agent_name": agentName,
          "prompt_type": promptType,
          "prompt": prompt,
        }),
      );
      return jsonDecode(response.body)["message"];
    } catch (e) {
      return handleError(e);
    }
  }

  Future<String> updateStep(
    String chainName,
    int stepNumber,
    String agentName,
    String promptType,
    Map<String, dynamic> prompt,
  ) async {
    try {
      final response = await http.put(
        Uri.parse("$baseUri/api/chain/$chainName/step/$stepNumber"),
        headers: headers,
        body: jsonEncode({
          "step_number": stepNumber,
          "agent_name": agentName,
          "prompt_type": promptType,
          "prompt": prompt,
        }),
      );
      return jsonDecode(response.body)["message"];
    } catch (e) {
      return handleError(e);
    }
  }

  Future<String> moveStep(
    String chainName,
    int oldStepNumber,
    int newStepNumber,
  ) async {
    try {
      final response = await http.patch(
        Uri.parse("$baseUri/api/chain/$chainName/step/move"),
        headers: headers,
        body: jsonEncode({
          "old_step_number": oldStepNumber,
          "new_step_number": newStepNumber,
        }),
      );
      return jsonDecode(response.body)["message"];
    } catch (e) {
      return handleError(e);
    }
  }

  Future<String> deleteStep(String chainName, int stepNumber) async {
    try {
      final response = await http.delete(
        Uri.parse("$baseUri/api/chain/$chainName/step/$stepNumber"),
        headers: headers,
      );
      return jsonDecode(response.body)["message"];
    } catch (e) {
      return handleError(e);
    }
  }

  Future<String> addPrompt(
    String promptName,
    String prompt, {
    String promptCategory = "Default",
  }) async {
    try {
      final response = await http.post(
        Uri.parse("$baseUri/api/prompt/$promptCategory"),
        headers: headers,
        body: jsonEncode({
          "prompt_name": promptName,
          "prompt": prompt,
        }),
      );
      return jsonDecode(response.body)["message"];
    } catch (e) {
      return handleError(e);
    }
  }

  Future<Map<String, dynamic>> getPrompt(
    String promptName, {
    String promptCategory = "Default",
  }) async {
    try {
      final response = await http.get(
        Uri.parse("$baseUri/api/prompt/$promptCategory/$promptName"),
        headers: headers,
      );
      return Map<String, dynamic>.from(jsonDecode(response.body)["prompt"]);
    } catch (e) {
      return handleError(e);
    }
  }

  Future<List<String>> getPrompts({String promptCategory = "Default"}) async {
    try {
      final response = await http.get(
        Uri.parse("$baseUri/api/prompt/$promptCategory"),
        headers: headers,
      );
      return List<String>.from(jsonDecode(response.body)["prompts"]);
    } catch (e) {
      return handleError(e);
    }
  }

  Future<List<String>> getPromptCategories() async {
    try {
      final response = await http.get(
        Uri.parse("$baseUri/api/prompt/categories"),
        headers: headers,
      );
      return List<String>.from(jsonDecode(response.body)["prompt_categories"]);
    } catch (e) {
      return handleError(e);
    }
  }

  Future<Map<String, dynamic>> getPromptArgs(
    String promptName, {
    String promptCategory = "Default",
  }) async {
    try {
      final response = await http.get(
        Uri.parse("$baseUri/api/prompt/$promptCategory/$promptName/args"),
        headers: headers,
      );
      return Map<String, dynamic>.from(jsonDecode(response.body)["prompt_args"]);
    } catch (e) {
      return handleError(e);
    }
  }

  Future<String> deletePrompt(
    String promptName, {
    String promptCategory = "Default",
  }) async {
    try {
      final response = await http.delete(
        Uri.parse("$baseUri/api/prompt/$promptCategory/$promptName"),
        headers: headers,
      );
      return jsonDecode(response.body)["message"];
    } catch (e) {
      return handleError(e);
    }
  }

  Future<String> updatePrompt(
    String promptName,
    String prompt, {
    String promptCategory = "Default",
  }) async {
    try {
      final response = await http.put(
        Uri.parse("$baseUri/api/prompt/$promptCategory/$promptName"),
        headers: headers,
        body: jsonEncode({
          "prompt": prompt,
          "prompt_name": promptName,
          "prompt_category": promptCategory,
        }),
      );
      return jsonDecode(response.body)["message"];
    } catch (e) {
      return handleError(e);
    }
  }

  Future<String> renamePrompt(
    String promptName,
    String newName, {
    String promptCategory = "Default",
  }) async {
    try {
      final response = await http.patch(
        Uri.parse("$baseUri/api/prompt/$promptCategory/$promptName"),
        headers: headers,
        body: jsonEncode({"prompt_name": newName}),
      );
      return jsonDecode(response.body)["message"];
    } catch (e) {
      return handleError(e);
    }
  }

  Future<Map<String, dynamic>> getExtensionSettings() async {
    try {
      final response = await http.get(Uri.parse("$baseUri/api/extensions/settings"), headers: headers);
      return Map<String, dynamic>.from(jsonDecode(response.body)["extension_settings"]);
    } catch (e) {
      return handleError(e);
    }
  }

  Future<List<dynamic>> getExtensions() async {
    try {
      final response = await http.get(Uri.parse("$baseUri/api/extensions"), headers: headers);
      return jsonDecode(response.body)["extensions"];
    } catch (e) {
      return handleError(e);
    }
  }

  Future<List<dynamic>> getAgentExtensions(String agentName) async {
    try {
      final response = await http.get(
        Uri.parse("$baseUri/api/agent/$agentName/extensions"),
        headers: headers,
      );
      return jsonDecode(response.body)["extensions"];
    } catch (e) {
      return handleError(e);
    }
  }

  Future<Map<String, dynamic>> getDpoResponse(
    String agentName,
    String userInput, {
    int injectedMemories = 10,
    String conversationName = "",
  }) async {
    try {
      final response = await http.post(
        Uri.parse("$baseUri/api/agent/$agentName/dpo"),
        headers: headers,
        body: jsonEncode({
          "user_input": userInput,
          "injected_memories": injectedMemories,
          "conversation_name": conversationName,
        }),
      );
      return jsonDecode(response.body);
    } catch (e) {
      return handleError(e);
    }
  }

  Future<Map<String, dynamic>> getCommandArgs(String commandName) async {
    try {
      final response = await http.get(Uri.parse("$baseUri/api/extensions/$commandName/args"), headers: headers);
      return Map<String, dynamic>.from(jsonDecode(response.body)["command_args"]);
    } catch (e) {
      return handleError(e);
    }
  }

  Future<Map<String, dynamic>> getEmbeddersDetails() async {
    try {
      final response = await http.get(Uri.parse("$baseUri/api/embedders"), headers: headers);
      return Map<String, dynamic>.from(jsonDecode(response.body)["embedders"]);
    } catch (e) {
      return handleError(e);
    }
  }

  Future<String> positiveFeedback(
    String agentName,
    String message,
    String userInput,
    String feedback, {
    String conversationName = "",
  }) async {
    try {
      final response = await http.post(
        Uri.parse("$baseUri/api/agent/$agentName/feedback"),
        headers: headers,
        body: jsonEncode({
          "user_input": userInput,
          "message": message,
          "feedback": feedback,
          "positive": true,
          "conversation_name": conversationName,
        }),
      );
      return jsonDecode(response.body)["message"];
    } catch (e) {
      return handleError(e);
    }
  }

  Future<String> negativeFeedback(
    String agentName,
    String message,
    String userInput,
    String feedback, {
    String conversationName = "",
  }) async {
    try {
      final response = await http.post(
        Uri.parse("$baseUri/api/agent/$agentName/feedback"),
        headers: headers,
        body: jsonEncode({
          "user_input": userInput,
          "message": message,
          "feedback": feedback,
          "positive": false,
          "conversation_name": conversationName,
        }),
      );
      return jsonDecode(response.body)["message"];
    } catch (e) {
      return handleError(e);
    }
  }

  Future<String> learnText(
    String agentName,
    String userInput,
    String text, {
    String collectionNumber = "0",
  }) async {
    try {
      final response = await http.post(
        Uri.parse("$baseUri/api/agent/$agentName/learn/text"),
        headers: headers,
        body: jsonEncode({
          "user_input": userInput,
          "text": text,
          "collection_number": collectionNumber,
        }),
      );
      return jsonDecode(response.body)["message"];
    } catch (e) {
      return handleError(e);
    }
  }

  Future<String> learnUrl(
    String agentName,
    String url, {
    String collectionNumber = "0",
  }) async {
    try {
      final response = await http.post(
        Uri.parse("$baseUri/api/agent/$agentName/learn/url"),
        headers: headers,
        body: jsonEncode({
          "url": url,
          "collection_number": collectionNumber,
        }),
      );
      return jsonDecode(response.body)["message"];
    } catch (e) {return handleError(e);
    }
  }

  Future<String> learnFile(
    String agentName,
    String fileName,
    String fileContent, {
    String collectionNumber = "0",
  }) async {
    try {
      final response = await http.post(
        Uri.parse("$baseUri/api/agent/$agentName/learn/file"),
        headers: headers,
        body: jsonEncode({
          "file_name": fileName,
          "file_content": fileContent,
          "collection_number": collectionNumber,
        }),
      );
      return jsonDecode(response.body)["message"];
    } catch (e) {
      return handleError(e);
    }
  }

  Future<String> learnGithubRepo(
    String agentName,
    String githubRepo, {
    String? githubUser,
    String? githubToken,
    String githubBranch = "main",
    bool useAgentSettings = false,
    String collectionNumber = "0",
  }) async {
    try {
      final response = await http.post(
        Uri.parse("$baseUri/api/agent/$agentName/learn/github"),
        headers: headers,
        body: jsonEncode({
          "github_repo": githubRepo,
          "github_user": githubUser,
          "github_token": githubToken,
          "github_branch": githubBranch,
          "collection_number": collectionNumber,
          "use_agent_settings": useAgentSettings,
        }),
      );
      return jsonDecode(response.body)["message"];
    } catch (e) {
      return handleError(e);
    }
  }

  Future<String> learnArxiv({
    required String agentName,
    String? query,
    String? arxivIds,
    int maxResults = 5,
    String collectionNumber = "0",
  }) async {
    try {
      final response = await http.post(
        Uri.parse("$baseUri/api/agent/$agentName/learn/arxiv"),
        headers: headers,
        body: jsonEncode({
          "query": query,
          "arxiv_ids": arxivIds,
          "max_results": maxResults,
          "collection_number": collectionNumber,
        }),
      );
      return jsonDecode(response.body)["message"];
    } catch (e) {
      return handleError(e);
    }
  }

  Future<String> agentReader(
    String agentName,
    String readerName,
    Map<String, dynamic> data, {
    String collectionNumber = "0",
  }) async {
    if (!data.containsKey("collection_number")) {
      data["collection_number"] = collectionNumber;
    }
    try {
      final response = await http.post(
        Uri.parse("$baseUri/api/agent/$agentName/reader/$readerName"),
        headers: headers,
        body: jsonEncode(data),
      );
      return jsonDecode(response.body)["message"];
    } catch (e) {
      return handleError(e);
    }
  }

  Future<String> wipeAgentMemories(
    String agentName, {
    String collectionNumber = "0",
  }) async {
    try {
      final response = await http.delete(
        Uri.parse(collectionNumber == "0"
            ? "$baseUri/api/agent/$agentName/memory"
            : "$baseUri/api/agent/$agentName/memory/$collectionNumber"),
        headers: headers,
      );
      return jsonDecode(response.body)["message"];
    } catch (e) {
      return handleError(e);
    }
  }

  Future<String> deleteAgentMemory(
    String agentName,
    String memoryId, {
    String collectionNumber = "0",
  }) async {
    try {
      final response = await http.delete(
        Uri.parse("$baseUri/api/agent/$agentName/memory/$collectionNumber/$memoryId"),
        headers: headers,
      );
      return jsonDecode(response.body)["message"];
    } catch (e) {
      return handleError(e);
    }
  }

  Future<List<Map<String, dynamic>>> getAgentMemories(
    String agentName,
    String userInput, {
    int limit = 5,
    double minRelevanceScore = 0.0,
    String collectionNumber = "0",
  }) async {
    try {
      final response = await http.post(
        Uri.parse("$baseUri/api/agent/$agentName/memory/$collectionNumber/query"),
        headers: headers,
        body: jsonEncode({
          "user_input": userInput,
          "limit": limit,
          "min_relevance_score": minRelevanceScore,
        }),
      );
      return List<Map<String, dynamic>>.from(jsonDecode(response.body)["memories"]);
    } catch (e) {
      return handleError(e);
    }
  }

  Future<List<Map<String, dynamic>>> exportAgentMemories(String agentName) async {
    try {
      final response = await http.get(
        Uri.parse("$baseUri/api/agent/$agentName/memory/export"),
        headers: headers,
      );
      return List<Map<String, dynamic>>.from(jsonDecode(response.body)["memories"]);
    } catch (e) {
      return handleError(e);
    }
  }

  Future<String> importAgentMemories(
    String agentName,
    List<Map<String, dynamic>> memories,
  ) async {
    try {
      final response = await http.post(
        Uri.parse("$baseUri/api/agent/$agentName/memory/import"),
        headers: headers,
        body: jsonEncode({"memories": memories}),
      );
      return jsonDecode(response.body)["message"];
    } catch (e) {
      return handleError(e);
    }
  }

  Future<String> createDataset(
    String agentName,
    String datasetName, {
    int batchSize = 4,
  }) async {
    try {
      final response = await http.post(
        Uri.parse("$baseUri/api/agent/$agentName/memory/dataset"),
        headers: headers,
        body: jsonEncode({"dataset_name": datasetName, "batch_size": batchSize}),
      );
      return jsonDecode(response.body)["message"];
    } catch (e) {
      return handleError(e);
    }
  }

  Future<List<String>> getBrowsedLinks(
    String agentName, {
    String collectionNumber = "0",
  }) async {
    try {
      final response = await http.get(
        Uri.parse("$baseUri/api/agent/$agentName/browsed_links/$collectionNumber"),
        headers: headers,
      );
      return List<String>.from(jsonDecode(response.body)["links"]);
    } catch (e) {
      return handleError(e);
    }
  }

  Future<String> deleteBrowsedLink(
    String agentName,
    String link, {
    String collectionNumber = "0",
  }) async {
    try {
      final response = await http.delete(
        Uri.parse("$baseUri/api/agent/$agentName/browsed_links"),
        headers: headers,
        body: jsonEncode({"link": link, "collection_number": collectionNumber}),
      );
      return jsonDecode(response.body)["message"];
    } catch (e) {
      return handleError(e);
    }
  }

  Future<List<String>> getMemoriesExternalSources(
    String agentName,
    String collectionNumber,
  ) async {
    try {
      final response = await http.get(
        Uri.parse("$baseUri/api/agent/$agentName/memory/external_sources/$collectionNumber"),
        headers: headers,
      );
      return List<String>.from(jsonDecode(response.body)["external_sources"]);
    } catch (e) {
      return handleError(e);
    }
  }

  Future<String> deleteMemoryExternalSource(
    String agentName,
    String source,
    String collectionNumber,
  ) async {
    try {
      final response = await http.delete(
        Uri.parse("$baseUri/api/agent/$agentName/memory/external_source"),
        headers: headers,
        body: jsonEncode({
          "external_source": source,
          "collection_number": collectionNumber,
        }),
      );
      return jsonDecode(response.body)["message"];
    } catch (e) {
      return handleError(e);
    }
  }

  Future<String> train({
    String agentName = "AGiXT",
    String datasetName = "dataset",
    String model = "unsloth/mistral-7b-v0.2",
    int maxSeqLength = 16384,
    String huggingfaceOutputPath = "JoshXT/finetuned-mistral-7b-v0.2",
    bool privateRepo = true,
  }) async {
    try {
      final response = await http.post(
        Uri.parse("$baseUri/api/agent/$agentName/memory/dataset/$datasetName/finetune"),
        headers: headers,
        body: jsonEncode({
          "model": model,
          "max_seq_length": maxSeqLength,
          "huggingface_output_path": huggingfaceOutputPath,
          "private_repo": privateRepo,
        }),
      );
      return jsonDecode(response.body)["message"];
    } catch (e) {
      return handleError(e);
    }
  }

  Future<String> textToSpeech(String agentName, String text) async {
    try {
      final response = await http.post(
        Uri.parse("$baseUri/api/agent/$agentName/text_to_speech"),
        headers: headers,
        body: jsonEncode({"text": text}),
      );
      return jsonDecode(response.body)["url"];
    } catch (e) {
      return handleError(e);
    }
  }

  Future<Map<String, dynamic>> transcribeAudio(
    String file,
    String model, {
    String? language,
    String? prompt,
    String responseFormat = "json",
    double temperature = 0.0,
  }) async {
    try {
      final request = http.MultipartRequest(
        'POST',
        Uri.parse("$baseUri/v1/audio/transcriptions"),
      );
      request.headers.addAll(headers);
      request.files.add(await http.MultipartFile.fromPath('file', file));
      request.fields.addAll({
        'model': model,
        'response_format': responseFormat,
        'temperature': temperature.toString(),
      });
      if (language != null) request.fields['language'] = language;
      if (prompt != null) request.fields['prompt'] = prompt;

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);
      return jsonDecode(response.body);
    } catch (e) {
      return handleError(e);
    }
  }

  Future<Map<String, dynamic>> translateAudio(
    String file,
    String model, {
    String? prompt,
    String responseFormat = "json",
    double temperature = 0.0,
  }) async {
    try {
      final request = http.MultipartRequest(
        'POST',
        Uri.parse("$baseUri/v1/audio/translations"),
      );
      request.headers.addAll(headers);
      request.files.add(await http.MultipartFile.fromPath('file', file));
      request.fields.addAll({
        'model': model,
        'response_format': responseFormat,
        'temperature': temperature.toString(),
      });
      if (prompt != null) request.fields['prompt'] = prompt;

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);
      return jsonDecode(response.body);
    } catch (e) {
      return handleError(e);
    }
  }

  Future<Map<String, dynamic>> generateImage(
    String prompt, {
    String model = "dall-e-3",
    int n = 1,
    String size = "1024x1024",
    String responseFormat = "url",
  }) async {
    try {
      final response = await http.post(
        Uri.parse("$baseUri/v1/images/generations"),
        headers: headers,
        body: jsonEncode({
          "model": model,
          "prompt": prompt,
          "n": n,
          "size": size,
          "response_format": responseFormat,
        }),
      );
      return jsonDecode(response.body);
    } catch (e) {
      return handleError(e);
    }
  }

  Future<Map<String, dynamic>> chatCompletions(
    ChatCompletions prompt,
    Future<String> Function(String) func, {
    Future<String> Function(String)? asyncFunc,
  }) async {
    if (verbose) {
      print("Processing chat completion...");
      print("Model: ${prompt.model}");
      print("User: ${prompt.user}");
    }
    String agentName = prompt.model;
    String conversationName = prompt.user ?? "-";
    Map<String, dynamic> agentConfig = await getAgentConfig(agentName);
    Map<String, dynamic> agentSettings = agentConfig["settings"] ?? {};

    bool tts = false;
    if (agentSettings.containsKey("tts_provider")) {
      String ttsProvider = agentSettings["tts_provider"].toString().toLowerCase();
      if (ttsProvider != "none" && ttsProvider.isNotEmpty) {
        tts = true;
      }
    }

    String newPrompt = "";
    for (var message in prompt.messages ?? []) {
      if (message.containsKey("tts")) {
        tts = message["tts"].toString().toLowerCase() == "true";
      }
      if (!message.containsKey("content")) continue;

      if (message["content"] is String) {
        String role = message["role"] ?? "User";
        if (role.toLowerCase() == "system" && message["content"].contains("/")) {
          newPrompt += "${message['content']}\n\n";
        }
        if (role.toLowerCase() == "user") {
          newPrompt += "${message['content']}\n\n";
        }
      } else if (message["content"] is List) {
        for (var msg in message["content"]) {
          if (msg.containsKey("text")) {
            String role = message["role"] ?? "User";
            if (role.toLowerCase() == "user") {
              newPrompt += "${msg['text']}\n\n";
            }
          }
          if (msg.containsKey("image_url")) {
            var url = msg["image_url"] is String ? msg["image_url"] : msg["image_url"]["url"];
            
            if (url.startsWith("http")) {
              print("[IMAGE] Processing image from URL: $url");
            } else {
              // Handle base64 image
              print("[IMAGE] Processing base64 image");
            }
          }
          
          if (msg.containsKey("audio_url")) {
            var audioUrl = msg["audio_url"] is String ? msg["audio_url"] : msg["audio_url"]["url"];
            if (!audioUrl.startsWith("http")) {
              // Handle base64 audio
              print("[AUDIO] Processing base64 audio");
            }
            // Note: Audio file conversion would be platform specific
            print("[AUDIO] Audio processing would require platform-specific implementation");
          }

          if (msg.containsKey("video_url")) {
            var videoUrl = msg["video_url"] is String ? msg["video_url"] : msg["video_url"]["url"];
            String collectionNumber = msg["collection_number"]?.toString() ?? "0";
            
            if (videoUrl.startsWith("https://www.youtube.com/watch?v=")) {
              await newConversationMessage(
                role: agentName,
                message: "[ACTIVITY] Learning video from YouTube.",
                conversationName: conversationName,
              );
              await learnUrl(
                agentName,
                videoUrl,
                collectionNumber: collectionNumber,
              );
            }
          }

          if (msg.containsKey("file_url") ||
              msg.containsKey("application_url") ||
              msg.containsKey("text_url") ||
              msg.containsKey("url")) {
            var fileUrl = msg["file_url"] ?? msg["application_url"] ?? msg["text_url"] ?? msg["url"];
            fileUrl = fileUrl is String ? fileUrl : fileUrl["url"];
            String collectionNumber = message["collection_number"]?.toString() ??
                                    msg["collection_number"]?.toString() ?? "0";

            if (fileUrl.startsWith("http")) {
              if (fileUrl.startsWith("https://www.youtube.com/watch?v=")) {
                await newConversationMessage(
                  role: agentName,
                  message: "[ACTIVITY] Learning video from YouTube.",
                  conversationName: conversationName,
                );
                await learnUrl(
                  agentName,
                  fileUrl,
                  collectionNumber: collectionNumber,
                );
              } else if (fileUrl.startsWith("https://github.com")) {
                await newConversationMessage(
                  role: agentName,
                  message: "[ACTIVITY] Learning from GitHub.",
                  conversationName: conversationName,
                );
                await learnGithubRepo(
                  agentName,
                  fileUrl,
                  githubUser: agentSettings["GITHUB_USER"],
                  githubToken: agentSettings["GITHUB_TOKEN"],
                  collectionNumber: collectionNumber,
                );
              } else {
                await newConversationMessage(
                  role: agentName,
                  message: "[ACTIVITY] Browsing $fileUrl",
                  conversationName: conversationName,
                );
                await learnUrl(
                  agentName,
                  fileUrl,
                  collectionNumber: collectionNumber,
                );
              }
            } else {
              // Handle base64 file
              final fileType = fileUrl.split(",")[0].split("/")[1].split(";")[0];
              final bytes = base64.decode(fileUrl.split(",")[1]);
              final fileName = "Uploaded File ${DateTime.now().millisecondsSinceEpoch}.$fileType";
              
              await newConversationMessage(
                role: agentName,
                message: "[ACTIVITY] Learning from uploaded file.",
                conversationName: conversationName,
              );
              
              await learnFile(
                agentName,
                fileName,
                String.fromCharCodes(bytes),
                collectionNumber: collectionNumber,
              );
            }
          }
        }
      }
    }

    await newConversationMessage(
      role: "user",
      message: newPrompt,
      conversationName: conversationName,
    );

    String response;
    if (asyncFunc != null) {
      response = await asyncFunc(newPrompt);
    } else {
      response = await func(newPrompt);
    }

    await newConversationMessage(
      role: agentName,
      message: response,
      conversationName: conversationName,
    );

    if (tts) {
      await newConversationMessage(
        role: agentName,
        message: "[ACTIVITY] Generating audio response.",
        conversationName: conversationName,
      );
      String ttsResponse = await textToSpeech(agentName, response);
      await newConversationMessage(
        role: agentName,
        message: '<audio controls><source src="$ttsResponse" type="audio/wav"></audio>',
        conversationName: conversationName,
      );
    }

    // Note: Token counting is not implemented here as it would require a Dart-specific solution

    return {
      "id": conversationName,
      "object": "chat.completion",
      "created": DateTime.now().millisecondsSinceEpoch ~/ 1000,
      "model": agentName,
      "choices": [
        {
          "index": 0,
          "message": {
            "role": "assistant",
            "content": response,
          },
          "finish_reason": "stop",
        }
      ],
      "usage": {
        "prompt_tokens": getTokens(newPrompt),
        "completion_tokens": getTokens(response),
        "total_tokens": getTokens(newPrompt) + getTokens(response),
      },
    };
  }

  Future<String> planTask(
    String agentName,
    String userInput, {
    bool websearch = false,
    int websearchDepth = 3,
    String conversationName = "",
    bool logUserInput = true,
    bool logOutput = true,
    bool enableNewCommand = true,
  }) async {
    try {
      final response = await http.post(
        Uri.parse("$baseUri/api/agent/$agentName/plan/task"),
        headers: headers,
        body: jsonEncode({
          "user_input": userInput,
          "websearch": websearch,
          "websearch_depth": websearchDepth,
          "conversation_name": conversationName,
          "log_user_input": logUserInput,
          "log_output": logOutput,
          "enable_new_command": enableNewCommand,
        }),
      );
      return jsonDecode(response.body)["response"];
    } catch (e) {
      return handleError(e);
    }
  }
  Future<String?> login(String email, String otp) async {
    try {
      final response = await http.post(
        Uri.parse("$baseUri/v1/login"),
        headers: headers,
        body: jsonEncode({
          "email": email,
          "token": otp,
        }),
      );
      final data = jsonDecode(response.body);
      if (data.containsKey("detail")) {
        String detail = data["detail"];
        if (detail.contains("?token=")) {
          String token = detail.split("token=")[1];
          headers = {
            "Authorization": token,
            "Content-Type": "application/json",
          };
          print("Log in at $detail");
          return token;
        }
      }
      return null;
    } catch (e) {
      return handleError(e);
    }
  }

  Future<String?> registerUser(String email, String firstName, String lastName) async {
    try {
      final response = await http.post(
        Uri.parse("$baseUri/v1/user"),
        headers: headers,
        body: jsonEncode({
          "email": email,
          "first_name": firstName,
          "last_name": lastName,
        }),
      );
      final data = jsonDecode(response.body);
      if (data.containsKey("otp_uri")) {
        // Note: TOTP implementation would be needed here
        // For now, return the OTP URI for manual handling
        return data["otp_uri"];
      }
      return data.toString();
    } catch (e) {
      return handleError(e);
    }
  }

  Future<bool> userExists(String email) async {
    try {
      final response = await http.get(
        Uri.parse("$baseUri/v1/user/exists?email=$email"),
        headers: headers,
      );
      return jsonDecode(response.body) as bool;
    } catch (e) {
      return handleError(e);
    }
  }

  Future<Map<String, dynamic>> updateUser(Map<String, dynamic> userData) async {
    try {
      final response = await http.put(
        Uri.parse("$baseUri/v1/user"),
        headers: headers,
        body: jsonEncode(userData),
      );
      return jsonDecode(response.body);
    } catch (e) {
      return handleError(e);
    }
  }

  Future<Map<String, dynamic>> getUser() async {
    try {
      final response = await http.get(
        Uri.parse("$baseUri/v1/user"),
        headers: headers,
      );
      return jsonDecode(response.body);
    } catch (e) {
      return handleError(e);
    }
  }

  Future<Map<String, dynamic>> oauth2Login(String provider, String code, {String? referrer}) async {
    try {
      final data = {
        "code": code,
      };
      if (referrer != null) {
        data["referrer"] = referrer;
      }
      final response = await http.post(
        Uri.parse("$baseUri/v1/oauth2/$provider"),
        headers: headers,
        body: jsonEncode(data),
      );
      return jsonDecode(response.body);
    } catch (e) {
      return handleError(e);
    }
  }

  Future<Map<String, dynamic>> updateConversationMessageById(
    String messageId,
    String newMessage,
    String conversationName,
  ) async {
    try {
      final response = await http.put(
        Uri.parse("$baseUri/api/conversation/message/$messageId"),
        headers: headers,
        body: jsonEncode({
          "new_message": newMessage,
          "conversation_name": conversationName,
        }),
      );
      return jsonDecode(response.body);
    } catch (e) {
      return handleError(e);
    }
  }

  Future<Map<String, dynamic>> deleteConversationMessageById(
    String messageId,
    String conversationName,
  ) async {
    try {
      final response = await http.delete(
        Uri.parse("$baseUri/api/conversation/message/$messageId"),
        headers: headers,
        body: jsonEncode({
          "conversation_name": conversationName,
        }),
      );
      return jsonDecode(response.body);
    } catch (e) {
      return handleError(e);
    }
  }

  Future<List<String>> getUniqueExternalSources(
    String agentName, {
    String collectionNumber = "0",
  }) async {
    try {
      final response = await http.get(
        Uri.parse("$baseUri/api/agent/$agentName/memory/external_sources/$collectionNumber"),
        headers: headers,
      );
      return List<String>.from(jsonDecode(response.body)["external_sources"]);
    } catch (e) {
      return handleError(e);
    }
  }
  
  Future<String?> forkConversation(String conversationName, String messageId) async {
    try {
      final response = await http.post(
        Uri.parse("$baseUri/api/conversation/fork"),
        headers: headers,
        body: jsonEncode({
          "conversation_name": conversationName,
          "message_id": messageId,
        }),
      );
      return jsonDecode(response.body)["message"];
    } catch (e) {
      return handleError(e);
    }
  }
  
  Future<String?> getPersona(String agentName) async {
    try {
      final response = await http.get(
        Uri.parse("$baseUri/api/agent/$agentName/persona"),
        headers: headers,
      );
      return jsonDecode(response.body)["message"];
    } catch (e) {
      return handleError(e);
    }
  }
  
  Future<String> updatePersona(String agentName, String persona) async {
    try {
      final response = await http.put(
        Uri.parse("$baseUri/api/agent/$agentName/persona"),
        headers: headers,
        body: jsonEncode({"persona": persona}),
      );
      return jsonDecode(response.body)["message"];
    } catch (e) {
      return handleError(e);
    }
  }
  
  Future<String> createExtension(
    String agentName,
    String extensionName,
    String openapiJsonUrl,
  ) async {
    try {
      // Generate the extension using the Generate Extension from OpenAPI command
      final chainName = await executeCommand(
        agentName,
        "Generate Extension from OpenAPI",
        {
          "openapi_json_url": openapiJsonUrl,
          "extension_name": extensionName,
        },
        conversationName: "$extensionName Extension Generation",
      );
  
      // Run the chain to create the extension
      final extensionDownload = await runChain(
        chainName: chainName,
        userInput: "Create an AGiXT extension for $extensionName.",
        agentName: agentName,
      );
  
      // Download and save the extension file
      final fileName = Uri.parse(extensionDownload).pathSegments.last;
      final response = await http.get(Uri.parse(extensionDownload));
      if (response.statusCode != 200) {
        throw Exception("Failed to download extension file");
      }
  
      // Create extensions directory if it doesn't exist
      final extensionDir = Directory("extensions");
      if (!await extensionDir.exists()) {
        await extensionDir.create();
      }
  
      // Write the extension file with header comments
      final file = File("extensions/$fileName");
      final content = StringBuffer();
      content.writeln("# Generated from OpenAPI JSON URL: $openapiJsonUrl");
      content.writeln("# Date Generated: ${DateTime.now().toString()}");
      content.write(response.body);
      await file.writeAsString(content.toString());
  
      return "$extensionName extension created and downloaded to extensions/$fileName";
    } catch (e) {
      return handleError(e);
    }
  }
}