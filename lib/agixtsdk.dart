import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:uuid/uuid.dart';

class ChatCompletions {
  String model;
  List<Map<String, dynamic>> messages;
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
    required this.model,
    required this.messages,
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
  bool verbose;
  int failures;

  AGiXTSDK({String? baseUri, String? apiKey, this.verbose = false})
      : baseUri = baseUri ?? 'http://localhost:7437',
        headers = {
          'Content-Type': 'application/json',
          if (apiKey != null) 'Authorization': apiKey.replaceAll(RegExp(r'Bearer ', caseSensitive: false), ''),
        },
        failures = 0 {
    if (this.baseUri.endsWith('/')) {
      this.baseUri = this.baseUri.substring(0, this.baseUri.length - 1);
    }
  }

  void handleError(dynamic error) {
    print('Error: $error');
    throw Exception('Unable to retrieve data. $error');
  }

  Future<String> login(String email, String otp) async {
    final response = await http.post(
      Uri.parse('$baseUri/v1/login'),
      headers: headers,
      body: jsonEncode({'email': email, 'token': otp}),
    );
    if (verbose) {
      parseResponse(response);
    }
    final responseJson = jsonDecode(response.body);
    if (responseJson.containsKey('detail')) {
      final detail = responseJson['detail'];
      if (detail.contains('?token=')) {
        final token = detail.split('token=')[1];
        headers['Authorization'] = token;
        print('Log in at $detail');
        return token;
      }
    }
    return '';
  }

  Future<dynamic> registerUser(String email, String firstName, String lastName) async {
    final response = await http.post(
      Uri.parse('$baseUri/v1/user'),
      headers: headers,
      body: jsonEncode({'email': email, 'first_name': firstName, 'last_name': lastName}),
    );
    if (verbose) {
      parseResponse(response);
    }
    final responseJson = jsonDecode(response.body);
    if (responseJson.containsKey('otp_uri')) {
      final mfaToken = responseJson['otp_uri'].split('secret=')[1].split('&')[0];
      final totp = TOTP(mfaToken);
      await login(email, totp.now());
      return responseJson['otp_uri'];
    }
    return responseJson;
  }

  Future<Map<String, dynamic>> userExists(String email) async {
    final response = await http.get(
      Uri.parse('$baseUri/v1/user/exists?email=$email'),
      headers: headers,
    );
    if (verbose) {
      parseResponse(response);
    }
    return jsonDecode(response.body);
  }

  Future<Map<String, dynamic>> updateUser(Map<String, dynamic> kwargs) async {
    final response = await http.put(
      Uri.parse('$baseUri/v1/user'),
      headers: headers,
      body: jsonEncode(kwargs),
    );
    if (verbose) {
      parseResponse(response);
    }
    return jsonDecode(response.body);
  }

  Future<Map<String, dynamic>> getUser() async {
    final response = await http.get(
      Uri.parse('$baseUri/v1/user'),
      headers: headers,
    );
    if (verbose) {
      parseResponse(response);
    }
    return jsonDecode(response.body);
  }

  Future<List<String>> getProviders() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUri/api/provider'),
        headers: headers,
      );
      if (verbose) {
        parseResponse(response);
      }
      return List<String>.from(jsonDecode(response.body)['providers']);
    } catch (e) {
      return handleError(e);
    }
  }

  Future<List<String>> getProvidersByService(String service) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUri/api/providers/service/$service'),
        headers: headers,
      );
      if (verbose) {
        parseResponse(response);
      }
      return List<String>.from(jsonDecode(response.body)['providers']);
    } catch (e) {
      return handleError(e);
    }
  }

  Future<Map<String, dynamic>> getProviderSettings(String providerName) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUri/api/provider/$providerName'),
        headers: headers,
      );
      if (verbose) {
        parseResponse(response);
      }
      return Map<String, dynamic>.from(jsonDecode(response.body)['settings']);
    } catch (e) {
      return handleError(e);
    }
  }

  Future<List<String>> getEmbedProviders() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUri/api/embedding_providers'),
        headers: headers,
      );
      if (verbose) {
        parseResponse(response);
      }
      return List<String>.from(jsonDecode(response.body)['providers']);
    } catch (e) {
      return handleError(e);
    }
  }

  Future<Map<String, dynamic>> getEmbedders() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUri/api/embedders'),
        headers: headers,
      );
      if (verbose) {
        parseResponse(response);
      }
      return Map<String, dynamic>.from(jsonDecode(response.body)['embedders']);
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
        Uri.parse('$baseUri/api/agent'),
        headers: headers,
        body: jsonEncode({
          'agent_name': agentName,
          'settings': settings,
          'commands': commands,
          'training_urls': trainingUrls,
        }),
      );
      if (verbose) {
        parseResponse(response);
      }
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
        Uri.parse('$baseUri/api/agent/import'),
        headers: headers,
        body: jsonEncode({
          'agent_name': agentName,
          'settings': settings,
          'commands': commands,
        }),
      );
      if (verbose) {
        parseResponse(response);
      }
      return jsonDecode(response.body);
    } catch (e) {
      return handleError(e);
    }
  }

  Future<String> renameAgent(String agentName, String newName) async {
    try {
      final response = await http.patch(
        Uri.parse('$baseUri/api/agent/$agentName'),
        headers: headers,
        body: jsonEncode({'new_name': newName}),
      );
      if (verbose) {
        parseResponse(response);
      }
      return jsonDecode(response.body)['message'];
    } catch (e) {
      return handleError(e);
    }
  }

  Future<String> updateAgentSettings(String agentName, Map<String, dynamic> settings) async {
    try {
      final response = await http.put(
        Uri.parse('$baseUri/api/agent/$agentName'),
        headers: headers,
        body: jsonEncode({'settings': settings, 'agent_name': agentName}),
      );
      if (verbose) {
        parseResponse(response);
      }
      return jsonDecode(response.body)['message'];
    } catch (e) {
      return handleError(e);
    }
  }

  Future<String> updateAgentCommands(String agentName, Map<String, dynamic> commands) async {
    try {
      final response = await http.put(
        Uri.parse('$baseUri/api/agent/$agentName/commands'),
        headers: headers,
        body: jsonEncode({'commands': commands, 'agent_name': agentName}),
      );
      if (verbose) {
        parseResponse(response);
      }
      return jsonDecode(response.body)['message'];
    } catch (e) {
      return handleError(e);
    }
  }

  Future<String> deleteAgent(String agentName) async {
    try {
      final response = await http.delete(
        Uri.parse('$baseUri/api/agent/$agentName'),
        headers: headers,
      );
      if (verbose ) {
        parseResponse(response);
      }
      return jsonDecode(response.body)['message'];
    } catch (e) {
      return handleError(e);
    }
  }

  Future<List<Map<String, dynamic>>> getAgents() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUri/api/agent'),
        headers: headers,
      );
      if (verbose) {
        parseResponse(response);
      }
      return List<Map<String, dynamic>>.from(jsonDecode(response.body)['agents']);
    } catch (e) {
      return handleError(e);
    }
  }

  Future<Map<String, dynamic>> getAgentConfig(String agentName) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUri/api/agent/$agentName'),
        headers: headers,
      );
      if (verbose) {
        parseResponse(response);
      }
      return Map<String, dynamic>.from(jsonDecode(response.body)['agent']);
    } catch (e) {
      return handleError(e);
    }
  }

  Future<List<String>> getConversations({String agentName = ''}) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUri/api/conversations'),
        headers: headers,
      );
      if (verbose) {
        parseResponse(response);
      }
      return List<String>.from(jsonDecode(response.body)['conversations']);
    } catch (e) {
      return handleError(e);
    }
  }

  Future<List<String>> getConversationsWithIds() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUri/api/conversations'),
        headers: headers,
      );
      if (verbose) {
        parseResponse(response);
      }
      return List<String>.from(jsonDecode(response.body)['conversations_with_ids']);
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
      final response = await http.get(
        Uri.parse('$baseUri/api/conversation'),
        headers: headers,
        body: jsonEncode({
          'conversation_name': conversationName,
          'agent_name': agentName,
          'limit': limit,
          'page': page,
        }),
      );
      if (verbose) {
        parseResponse(response);
      }
      return List<Map<String, dynamic>>.from(jsonDecode(response.body)['conversation_history']);
    } catch (e) {
      return handleError(e);
    }
  }

  Future<String> forkConversation(String conversationName, String messageId) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUri/api/conversation/fork'),
        headers: headers,
        body: jsonEncode({'conversation_name': conversationName, 'message_id': messageId}),
      );
      if (verbose) {
        parseResponse(response);
      }
      return jsonDecode(response.body)['message'];
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
        Uri.parse('$baseUri/api/conversation'),
        headers: headers,
        body: jsonEncode({
          'conversation_name': conversationName,
          'agent_name': agentName,
          'conversation_content': conversationContent,
        }),
      );
      if (verbose) {
        parseResponse(response);
      }
      return List<Map<String, dynamic>>.from(jsonDecode(response.body)['conversation_history']);
    } catch (e) {
      return handleError(e);
    }
  }

  Future<String> renameConversation(
    String agentName,
    String conversationName, {
    String newName = '-',
  }) async {
    try {
      final response = await http.put(
        Uri.parse('$baseUri/api/conversation'),
        headers: headers,
        body: jsonEncode({
          'conversation_name': conversationName,
          'new_conversation_name': newName,
          'agent_name': agentName,
        }),
      );
      if (verbose) {
        parseResponse(response);
      }
      return jsonDecode(response.body)['conversation_name'];
    } catch (e) {
      return handleError(e);
    }
  }

  Future<String> deleteConversation(String agentName, String conversationName) async {
    try {
      final response = await http.delete(
        Uri.parse('$baseUri/api/conversation'),
        headers: headers,
        body: jsonEncode({
          'conversation_name': conversationName,
          'agent_name': agentName,
        }),
      );
      if (verbose) {
        parseResponse(response);
      }
      return jsonDecode(response.body)['message'];
    } catch (e) {
      return handleError(e);
    }
  }

  Future<String> deleteConversationMessage (String agentName, String conversationName, String message) async {
    try {
      final response = await http.delete(
        Uri.parse('$baseUri/api/conversation/message'),
        headers: headers,
        body: jsonEncode({
          'message': message,
          'agent_name': agentName,
          'conversation_name': conversationName,
        }),
      );
      if (verbose) {
        parseResponse(response);
      }
      return jsonDecode(response.body)['message'];
    } catch (e) {
      return handleError(e);
    }
  }

  Future<String> updateConversationMessage(String agentName, String conversationName, String message, String newMessage) async {
    try {
      final response = await http.put(
        Uri.parse('$baseUri/api/conversation/message'),
        headers: headers,
        body: jsonEncode({
          'message': message,
          'new_message': newMessage,
          'agent_name': agentName,
          'conversation_name': conversationName,
        }),
      );
      if (verbose) {
        parseResponse(response);
      }
      return jsonDecode(response.body)['message'];
    } catch (e) {
      return handleError(e);
    }
  }

  Future<String> newConversationMessage({
    String role = 'user',
    String message = '',
    String conversationName = '',
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUri/api/conversation/message'),
        headers: headers,
        body: jsonEncode({
          'role': role,
          'message': message,
          'conversation_name': conversationName,
        }),
      );
      if (verbose) {
        parseResponse(response);
      }
      return jsonDecode(response.body)['message'];
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
        Uri.parse('$baseUri/api/agent/$agentName/prompt'),
        headers: headers,
        body: jsonEncode({
          'prompt_name': promptName,
          'prompt_args': promptArgs,
        }),
      );
      if (verbose) {
        parseResponse(response);
      }
      return jsonDecode(response.body)['response'];
    } catch (e) {
      return handleError(e);
    }
  }

  Future<String> instruct(String agentName, String userInput, String conversation) async {
    return promptAgent(
      agentName: agentName,
      promptName: 'instruct',
      promptArgs: {
        'user_input': userInput,
        'disable_memory': true,
        'conversation_name': conversation,
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
      promptName: 'Chat',
      promptArgs: {
        'user_input': userInput,
        'context_results': contextResults,
        'conversation_name': conversation,
        'disable_memory': true,
      },
    );
  }

  Future<String> smartInstruct(String agentName, String userInput, String conversation) async {
    return runChain(
      chainName: 'Smart Instruct',
      userInput: userInput,
      agentName: agentName,
      allResponses: false,
      fromStep: 1,
      chainArgs: {
        'conversation_name': conversation,
        'disable_memory': true,
      },
    );
  }

  Future<String> smartChat(String agentName, String userInput, String conversation) async {
    return runChain(
      chainName: 'Smart Chat',
      userInput: userInput,
      agentName: agentName,
      allResponses: false,
      fromStep: 1,
      chainArgs: {
        'conversation_name': conversation,
        'disable_memory': true,
      },
    );
  }

  Future<Map<String, Map<String, bool>>> getCommands(String agentName) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUri/api/agent/$agentName/command'),
        headers: headers,
      );
      if (verbose) {
        parseResponse(response);
      }
      return Map<String, Map<String, bool>>.from(jsonDecode(response.body)['commands']);
    } catch (e) {
      return handleError(e);
    }
  }

  Future<String> toggleCommand(String agentName, String commandName, bool enable) async {
    try {
      final response = await http.patch(
        Uri.parse('$baseUri/api/agent/$agentName/command'),
        headers: headers,
        body: jsonEncode({
          'command_name': commandName,
          'enable': enable,
        }),
      );
      if (verbose) {
        parseResponse(response);
      }
      return jsonDecode(response.body)['message'];
    } catch (e) {
      return handleError(e);
    }
  }

  Future<dynamic> executeCommand(
    String agentName,
    String commandName,
    Map<String, dynamic> commandArgs, {
    String conversationName = 'AGiXT Terminal Command Execution',
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUri/api/agent/$agentName/command'),
        headers: headers,
        body: jsonEncode({
          'command_name': commandName,
          'command_args': commandArgs,
          'conversation_name': conversationName,
        }),
      );
      if (verbose) {
        parseResponse(response);
      }
      return jsonDecode(response.body)['response'];
    } catch (e) {
      return handleError(e);
    }
  }

  Future<List<String>> getChains() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUri/api/chain'),
        headers: headers,
      );
      if (verbose) {
        parseResponse(response);
      }
      return List<String>.from(jsonDecode(response.body));
    } catch (e) {
      return handleError(e);
    }
  }

  Future<Map<String, dynamic>> getChain(String chainName) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUri/api/chain/$chainName'),
        headers: headers,
      );
      if (verbose) {
        parseResponse(response);
      }
      return Map<String, dynamic>.from(jsonDecode(response.body)['chain']);
    } catch (e) {
      return handleError(e);
    }
  }

  Future<Map<String, dynamic>> getChainResponses(String chainName) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUri/api/chain/$chainName/responses'),
        headers: headers,
      );
      if (verbose) {
        parseResponse(response);
      }
      return Map<String, dynamic>.from(jsonDecode(response.body)['chain']);
    } catch (e) {
      return handleError(e);
    }
  }

  Future<List<String>> getChainArgs(String chainName) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUri/api/chain/$chainName/args'),
        headers: headers,
      );
      if (verbose) {
        parseResponse(response);
      }
      return List<String>.from(jsonDecode(response.body)['chain_args']);
    } catch (e) {
      return handleError(e);
    }
  }

  Future<dynamic> runChain({
    required String chainName,
    required String userInput,
    String agentName = '',
    bool allResponses = false,
    int fromStep = 1,
    Map<String, dynamic> chainArgs = const {},
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUri/api/chain/$chainName/run'),
        headers: headers,
        body: jsonEncode({
          'prompt': userInput,
          'agent_name': agentName,
          'all_responses': allResponses,
          'from_step': fromStep,
          'chain_args': chainArgs,
        }),
      );
      if (verbose) {
        parseResponse(response);
      }
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
        Uri.parse('$baseUri/api/chain/$chainName/run/step/$stepNumber'),
        headers: headers,
        body: jsonEncode({
          'prompt': userInput,
          'agent_name': agentName,
          'chain_args': chainArgs,
        }),
      );
      if (verbose) {
        parseResponse(response);
      }
      return jsonDecode(response.body);
    } catch (e) {
      return handleError(e);
    }
  }

  Future<String> addChain(String chainName) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUri/api/chain'),
        headers: headers,
        body: jsonEncode({'chain_name': chainName}),
      );
      if (verbose) {
        parseResponse(response);
      }
      return jsonDecode(response.body)['message'];
    } catch (e) {
      return handleError(e);
    }
  }

  Future<String> importChain(String chainName, Map<String, dynamic> steps) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUri/api/chain/import'),
        headers: headers,
        body: jsonEncode({'chain_name': chainName, 'steps': steps}),
      );
      if (verbose) {
        parseResponse(response);
      }
      return jsonDecode(response.body)['message'];
    } catch (e) {
      return handleError(e);
    }
  }

  Future<String> renameChain(String chainName, String newName) async {
 try {
      final response = await http.put(
        Uri.parse('$baseUri/api/chain/$chainName'),
        headers: headers,
        body: jsonEncode({'new_name': newName}),
      );
      if (verbose) {
        parseResponse(response);
      }
      return jsonDecode(response.body)['message'];
    } catch (e) {
      return handleError(e);
    }
  }

  Future<String> deleteChain(String chainName) async {
    try {
      final response = await http.delete(
        Uri.parse('$baseUri/api/chain/$chainName'),
        headers: headers,
      );
      if (verbose) {
        parseResponse(response);
      }
      return jsonDecode(response.body)['message'];
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
        Uri.parse('$baseUri/api/chain/$chainName/step'),
        headers: headers,
        body: jsonEncode({
          'step_number': stepNumber,
          'agent_name': agentName,
          'prompt_type': promptType,
          'prompt': prompt,
        }),
      );
      if (verbose) {
        parseResponse(response);
      }
      return jsonDecode(response.body)['message'];
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
        Uri.parse('$baseUri/api/chain/$chainName/step/$stepNumber'),
        headers: headers,
        body: jsonEncode({
          'step_number': stepNumber,
          'agent_name': agentName,
          'prompt_type': promptType,
          'prompt': prompt,
        }),
      );
      if (verbose) {
        parseResponse(response);
      }
      return jsonDecode(response.body)['message'];
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
        Uri.parse('$baseUri/api/chain/$chainName/step/move'),
        headers: headers,
        body: jsonEncode({
          'old_step_number': oldStepNumber,
          'new_step_number': newStepNumber,
        }),
      );
      if (verbose) {
        parseResponse(response);
      }
      return jsonDecode(response.body)['message'];
    } catch (e) {
      return handleError(e);
    }
  }

  Future<String> deleteStep(String chainName, int stepNumber) async {
    try {
      final response = await http.delete(
        Uri.parse('$baseUri/api/chain/$chainName/step/$stepNumber'),
        headers: headers,
      );
      if (verbose) {
        parseResponse(response);
      }
      return jsonDecode(response.body)['message'];
    } catch (e) {
      return handleError(e);
    }
  }

  Future<String> addPrompt(
    String promptName,
    String prompt, {
    String promptCategory = 'Default',
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUri/api/prompt/$promptCategory'),
        headers: headers,
        body: jsonEncode({
          'prompt_name': promptName,
          'prompt': prompt,
        }),
      );
      if (verbose) {
        parseResponse(response);
      }
      return jsonDecode(response.body)['message'];
    } catch (e) {
      return handleError(e);
    }
  }

  Future<Map<String, dynamic>> getPrompt(
    String promptName, {
    String promptCategory = 'Default',
  }) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUri/api/prompt/$promptCategory/$promptName'),
        headers: headers,
      );
      if (verbose) {
        parseResponse(response);
      }
      return Map<String, dynamic>.from(jsonDecode(response.body)['prompt']);
    } catch (e) {
      return handleError(e);
    }
  }

  Future<List<String>> getPrompts({String promptCategory = 'Default'}) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUri/api/prompt/$promptCategory'),
        headers: headers,
      );
      if (verbose) {
        parseResponse(response);
      }
      return List<String>.from(jsonDecode(response.body)['prompts']);
    } catch (e) {
      return handleError(e);
    }
  }

  Future<List<String>> getPromptCategories() async {
    try {
      final response = await http.get(
        Uri.parse('$base Uri/api/prompt/categories'),
        headers: headers,
      );
      if (verbose) {
        parseResponse(response);
      }
      return List<String>.from(jsonDecode(response.body)['prompt_categories']);
    } catch (e) {
      return handleError(e);
    }
  }

  Future<Map<String, dynamic>> getPromptArgs(
    String promptName, {
    String promptCategory = 'Default',
  }) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUri/api/prompt/$promptCategory/$promptName/args'),
        headers: headers,
      );
      if (verbose) {
        parseResponse(response);
      }
      return Map<String, dynamic>.from(jsonDecode(response.body)['prompt_args']);
    } catch (e) {
      return handleError(e);
    }
  }

  Future<String> deletePrompt(
    String promptName, {
    String promptCategory = 'Default',
  }) async {
    try {
      final response = await http.delete(
        Uri.parse('$baseUri/api/prompt/$promptCategory/$promptName'),
        headers: headers,
      );
      if (verbose) {
        parseResponse(response);
      }
      return jsonDecode(response.body)['message'];
    } catch (e) {
      return handleError(e);
    }
  }

  Future<String> updatePrompt(
    String promptName,
    String prompt, {
    String promptCategory = 'Default',
  }) async {
    try {
      final response = await http.put(
        Uri.parse('$baseUri/api/prompt/$promptCategory/$promptName'),
        headers: headers,
        body: jsonEncode({
          'prompt': prompt,
          'prompt_name': promptName,
          'prompt_category': promptCategory,
        }),
      );
      if (verbose) {
        parseResponse(response);
      }
      return jsonDecode(response.body)['message'];
    } catch (e) {
      return handleError(e);
    }
  }

  Future<String> renamePrompt(
    String promptName,
    String newName, {
    String promptCategory = 'Default',
  }) async {
    try {
      final response = await http.patch(
        Uri.parse('$baseUri/api/prompt/$promptCategory/$promptName'),
        headers: headers,
        body: jsonEncode({'prompt_name': newName}),
      );
      if (verbose) {
        parseResponse(response);
      }
      return jsonDecode(response.body)['message'];
    } catch (e) {
      return handleError(e);
    }
  }

  Future<Map<String, dynamic>> getExtensionSettings() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUri/api/extensions/settings'),
        headers: headers,
      );
      if (verbose) {
        parseResponse(response);
      }
      return Map<String, dynamic>.from(jsonDecode(response.body)['extension_settings']);
    } catch (e) {
      return handleError(e);
    }
  }

  Future<List<dynamic>> getExtensions() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUri/api/extensions'),
        headers: headers,
      );
      if (verbose) {
        parseResponse(response);
      }
      return jsonDecode(response.body)['extensions'];
    } catch (e) {
      return handleError(e);
    }
  }

  Future<Map<String, dynamic>> getCommandArgs(String commandName) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUri/api/extensions/$commandName/args'),
        headers: headers,
      );
      if (verbose) {
        parseResponse(response);
      }
      return Map<String, dynamic>.from(jsonDecode(response.body)['command_args']);
    } catch (e) {
      return handleError(e);
    }
  }

  Future<Map<String, dynamic>> getEmbeddersDetails() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUri/api/embedders'),
        headers: headers,
      );
      if (verbose) {
        parseResponse(response);
      }
      return Map<String, dynamic>.from(jsonDecode(response.body)['embedders']);
    } catch (e) {
      return handleError(e);
    }
  }

  Future<String> positiveFeedback(
    String agentName,
    String message,
    String userInput,
    String feedback, {
    String conversationName = '',
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUri/api/agent/$agentName/feedback'),
        headers: headers,
        body: jsonEncode({
          'user_input': userInput,
          'message': message,
          'feedback': feedback,
          'positive': true,
          'conversation_name': conversationName,
        }),
      );
      if (verbose) {
        parseResponse(response);
      }
      return jsonDecode(response.body)['message'];
    } catch (e) {
      return handleError(e);
    }
  }

  Future<String> negativeFeedback(
    String agentName,
    String message,
    String userInput,
    String feedback, {
    String conversationName = '',
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUri/api/agent/$agentName/feedback'),
        headers: headers,
        body: jsonEncode({
          'user_input': userInput,
          'message': message,
          'feedback': feedback,
          'positive': false,
          'conversation_name': conversationName,
        }),
      );
      if (verbose) {
        parseResponse(response);
      }
      return jsonDecode(response.body)['message'];
    } catch (e) {
      return handleError(e);
    }
  }

  Future<String> learnText(
    String agentName,
    String userInput,
    String text, {
    String collectionNumber = '0',
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUri/api/agent/$agentName/learn/text'),
        headers: headers,
        body: jsonEncode({
          'user_input': userInput,
          'text': text,
          'collection_number': collectionNumber,
        }),
      );
      if (verbose) {
        parseResponse(response);
      }
      return jsonDecode(response.body)['message'];
    } catch (e) {
      return handleError(e);
    }
  }

  Future<String> learnUrl(
    String agentName,
    String url, {
    String collectionNumber = '0',
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUri/api/agent/$agentName/learn/url'),
        headers: headers,
        body: jsonEncode({
          'url': url,
          'collection_number': collectionNumber,
        }),
      );
      if (verbose) {
        parseResponse(response);
      }
      return jsonDecode(response.body)['message'];
    } catch (e) {
      return handleError(e);
    }
  }

  Future<String> learnFile(
    String agentName,
    String fileName,
    String fileContent, {
    String collectionNumber = '0',
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUri/api/agent/$agentName/learn/file'),
        headers: headers,
        body: jsonEncode({
          'file_name': fileName,
          'file_content': fileContent,
          'collection_number': collectionNumber,
        }),
      );
      if (verbose) {
        parseResponse(response);
      }
      return jsonDecode(response.body)['message'];
    } catch (e) {
      return handleError(e);
    }
  }

  Future<String> learnGithubRepo(
    String agentName,
    String githubRepo, {
    String? githubUser,
    String? githubToken,
    String githubBranch = 'main',
    bool useAgentSettings = false,
    String collectionNumber = '0',
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUri/api/agent/$agentName/learn/github'),
        headers: headers,
        body: jsonEncode({
          'github_repo': githubRepo,
          'github_user': githubUser,
          'github_token': githubToken,
          'github_branch': githubBranch,
          'use_agent_settings': useAgentSettings,
          'collection_number': collectionNumber,
        }),
      );
      if (verbose) {
        parseResponse(response);
      }
      return jsonDecode(response.body)['message'];
    } catch (e) {
      return handleError(e);
    }
  }

  Future<String> learnArxiv({
    required String agentName,
    String? query,
    String? arxivIds,
    int maxResults = 5,
    String collectionNumber = '0',
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUri/api/agent/$agentName/learn/arxiv'),
        headers: headers,
        body: jsonEncode({
          'query': query,
          'arxiv_ids': arxivIds,
          'max_results': maxResults,
          'collection_number': collectionNumber,
        }),
      );
      if (verbose) {
        parseResponse(response);
      }
      return jsonDecode(response.body)['message'];
    } catch (e) {
      return handleError(e);
    }
  }

  Future<String> agentReader(
    String agentName,
    String readerName,
    Map<String, dynamic> data, {
    String collectionNumber = '0',
  }) async {
    if (!data.containsKey('collection_number')) {
      data['collection_number'] = collectionNumber;
    }
    try {
      final response = await http.post(
        Uri.parse('$baseUri/api/agent/$agentName/reader/$readerName'),
        headers: headers,
        body: jsonEncode(data),
      );
      if (verbose) {
        parseResponse(response);
      }
      return jsonDecode(response.body)['message'];
    } catch (e) {
      return handleError(e);
    }
  }

  Future<String> wipeAgentMemories(
    String agentName, {
    String collectionNumber = '0',
  }) async {
    try {
      final response = await http.delete(
        Uri.parse(collectionNumber == '0'
            ? '$baseUri/api/agent/$agentName/memory'
            : '$baseUri/api/agent/$agentName/memory/$collectionNumber'),
        headers: headers,
      );
      if (verbose) {
        parseResponse(response);
      }
      return jsonDecode(response.body)['message'];
    } catch (e) {
      return handleError(e);
    }
  }

  Future<String> deleteAgentMemory(
    String agentName,
    String memoryId, {
    String collectionNumber = '0',
  }) async {
    try {
      final response = await http.delete(
        Uri.parse('$baseUri/api/agent/$agentName/memory/$collectionNumber/$memoryId'),
        headers: headers,
      );
      if (verbose) {
        parseResponse(response);
      }
      return jsonDecode(response.body)['message'];
    } catch (e) {
      return handleError(e);
    }
  }

  Future<List<Map<String, dynamic>>> getAgentMemories(
    String agentName,
    String userInput, {
    int limit = 5,
    double minRelevanceScore = 0.0,
    String collectionNumber = '0',
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUri/api/agent/$agentName/memory/$collectionNumber/query'),
        headers: headers,
        body: jsonEncode({
          'user_input': userInput,
          'limit': limit,
          'min_relevance_score': minRelevanceScore,
        }),
      );
      if (verbose) {
        parseResponse(response);
      }
      return List<Map<String, dynamic>>.from(jsonDecode(response.body)['memories']);
    } catch (e) {
      return handleError(e);
    }
  }

  Future<List<Map<String, dynamic>>> exportAgentMemories(String agentName) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUri/api/agent/$agentName/memory/export'),
        headers: headers,
      );
      if (verbose) {
        parseResponse(response);
      }
      return List<Map<String, dynamic>>.from(jsonDecode(response.body)['memories']);
    } catch (e) {
      return handleError(e);
    }
  }

  Future<String> importAgentMemories(
    String agentName,
    List<Map<String, dynamic>> memories,
  }) async {
    try {
 final response = await http.post(
        Uri.parse('$baseUri/api/agent/$agentName/memory/import'),
        headers: headers,
        body: jsonEncode({'memories': memories}),
      );
      if (verbose) {
        parseResponse(response);
      }
      return jsonDecode(response.body)['message'];
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
        Uri.parse('$baseUri/api/agent/$agentName/memory/dataset'),
        headers: headers,
        body: jsonEncode({'dataset_name': datasetName, 'batch_size': batchSize}),
      );
      if (verbose) {
        parseResponse(response);
      }
      return jsonDecode(response.body)['message'];
    } catch (e) {
      return handleError(e);
    }
  }

  Future<List<String>> getBrowsedLinks(
    String agentName, {
    String collectionNumber = '0',
  }) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUri/api/agent/$agentName/browsed_links/$collectionNumber'),
        headers: headers,
      );
      if (verbose) {
        parseResponse(response);
      }
      return List<String>.from(jsonDecode(response.body)['links']);
    } catch (e) {
      return handleError(e);
    }
  }

  Future<String> deleteBrowsedLink(
    String agentName,
    String link, {
    String collectionNumber = '0',
  }) async {
    try {
      final response = await http.delete(
        Uri.parse('$baseUri/api/agent/$agentName/browsed_links'),
        headers: headers,
        body: jsonEncode({'link': link, 'collection_number': collectionNumber}),
      );
      if (verbose) {
        parseResponse(response);
      }
      return jsonDecode(response.body)['message'];
    } catch (e) {
      return handleError(e);
    }
  }

  Future<List<String>> getMemoriesExternalSources(
    String agentName,
    String collectionNumber,
  }) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUri/api/agent/$agentName/memory/external_sources/$collectionNumber'),
        headers: headers,
      );
      if (verbose) {
        parseResponse(response);
      }
      return List<String>.from(jsonDecode(response.body)['external_sources']);
    } catch (e) {
      return handleError(e);
    }
  }

  Future<String> deleteMemoryExternalSource(
    String agentName,
    String source,
    String collectionNumber,
  }) async {
    try {
      final response = await http.delete(
        Uri.parse('$baseUri/api/agent/$agentName/memory/external_source'),
        headers: headers,
        body: jsonEncode({
          'external_source': source,
          'collection_number': collectionNumber,
        }),
      );
      if (verbose) {
        parseResponse(response);
      }
      return jsonDecode(response.body)['message'];
    } catch (e) {
      return handleError(e);
    }
  }

  Future<String> train({
    String agentName = 'AGiXT',
    String datasetName = 'dataset',
    String model = 'unsloth/mistral-7b-v0.2',
    int maxSeqLength = 16384,
    String huggingfaceOutputPath = 'JoshXT/finetuned-mistral-7b-v0.2',
    bool privateRepo = true,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUri/api/agent/$agentName/memory/dataset/$datasetName/finetune'),
        headers: headers,
        body: jsonEncode({
          'model': model,
          'max_seq_length': maxSeqLength,
          'huggingface_output_path': huggingfaceOutputPath,
          'private_repo': privateRepo,
        }),
      );
      if (verbose) {
        parseResponse(response);
      }
      return jsonDecode(response.body)['message'];
    } catch (e) {
      return handleError(e);
    }
  }

  Future<String> textToSpeech(String agentName, String text) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUri/api/agent/$agentName/text_to_speech'),
        headers: headers,
        body: jsonEncode({'text': text}),
      );
      if (verbose) {
        parseResponse(response);
      }
      return jsonDecode(response.body)['url'];
    } catch (e) {
      return handleError(e);
    }
  }

  Future<Map<String, dynamic>> chatCompletions(
    ChatCompletions prompt,
    Future<String> Function(String) func,
  }) async {
    String agentName = prompt.model;
    String conversationName = prompt.user ?? '-';
    Map<String, dynamic> agentConfig = await getAgentConfig(agentName);
    Map<String, dynamic> agentSettings = agentConfig['settings'] ?? {};

    bool tts = false;
    if (agentSettings.containsKey('tts_provider')) {
      String ttsProvider = agentSettings['tts_provider'].toString().toLowerCase();
      if (ttsProvider != 'none' && ttsProvider.isNotEmpty) {
        tts = true;
      }
    }

    String newPrompt = '';
    for (var message in prompt.messages ?? []) {
      if (message.containsKey('tts')) {
        tts = message['tts'].toString().toLowerCase() == 'true';
      }
      if (!message.containsKey('content')) continue;

      if (message['content'] is String) {
                String role = message['role'] ?? 'User';
        if (role.toLowerCase() == 'system' && message['content'].contains('/')) {
          newPrompt += '${message['content']}\n\n';
        }
        if (role.toLowerCase() == 'user') {
          newPrompt += '${message['content']}\n\n';
        }
      } else if (message['content'] is List) {
        for (var msg in message['content']) {
          if (msg.containsKey('text')) {
            String role = message['role'] ?? 'User';
            if (role.toLowerCase() == 'user') {
              newPrompt += '${msg['text']}\n\n';
            }
          }
          // Handle image, audio, video, and file processing here
          // This part would require significant adaptation and potentially
          // additional Dart packages to handle file operations, base64 encoding/decoding,
          // and potentially platform-specific code for mobile vs web.
        }
      }
    }

    await newConversationMessage(
      role: 'user',
      message: newPrompt,
      conversationName: conversationName,
    );

    String response = await func(newPrompt);

    await newConversationMessage(
      role: agentName,
      message: response,
      conversationName: conversationName,
    );

    if (tts) {
      await newConversationMessage(
        role: agentName,
        message: '[ACTIVITY] Generating audio response.',
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
      'id': conversationName,
      'object': 'chat.completion',
      'created': DateTime.now().millisecondsSinceEpoch ~/ 1000,
      'model': agentName,
      'choices': [
        {
          'index': 0,
          'message': {
            'role': 'assistant',
            'content': response,
          },
          'finish_reason': 'stop',
        }
      ],
      'usage': {
        'prompt_tokens': newPrompt.length, // This is not accurate, just a placeholder
        'completion_tokens': response.length, // This is not accurate, just a placeholder
        'total_tokens': newPrompt.length + response.length, // This is not accurate, just a placeholder
      },
    };
  }

  Future<String> planTask(
    String agentName,
    String userInput, {
    bool websearch = false,
    int websearchDepth = 3,
    String conversationName = '',
    bool logUserInput = true,
    bool logOutput = true,
    bool enableNewCommand = true,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUri/api/agent/$agentName/plan/task'),
        headers: headers,
        body: jsonEncode({
          'user_input': userInput,
          'websearch': websearch,
          'websearch_depth': websearchDepth,
          'conversation_name': conversationName,
          'log_user_input': logUserInput,
          'log_output': logOutput,
          'enable_new_command': enableNewCommand,
        }),
      );
      if (verbose) {
        parseResponse(response);
      }
      return jsonDecode(response.body)['response'];
    } catch (e) {
      return handleError(e);
    }
  }

  void parseResponse(http.Response response) {
    print('Status Code: ${response.statusCode}');
    print('Response JSON:');
    if (response.statusCode == 200) {
      print(jsonDecode(response.body));
    } else {
      print(response.body);
      throw Exception('Failed to load data');
    }
    print('\n');
  }

  // Implement other methods as needed...
}

class TOTP {
  final String secret;

  TOTP(this.secret);

  String now() {
    // Implement the TOTP algorithm or use a library if available.
    // This is a placeholder implementation.
    return '123456';
  }
}

void main() {
  // Example usage
  var sdk = AGiXTSDK(apiKey: 'your_api_key');
  sdk.login('email@example.com', '123456');
}