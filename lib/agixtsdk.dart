import 'dart:convert';
import 'package:http/http.dart' as http;

class AGiXTSDK {
  final String baseUri;
  final Map<String, String> headers;
  final bool verbose;

  AGiXTSDK({
    String? baseUri,
    String? apiKey,
    this.verbose = false,
  })  : baseUri = (baseUri ?? 'http://localhost:7437').replaceAll(RegExp(r'/$'), ''),
        headers = {
          'Content-Type': 'application/json',
          if (apiKey != null)
            'Authorization': apiKey.replaceAll('Bearer ', '').replaceAll('bearer ', ''),
        };

  String _handleError(dynamic error) {
    print('Error: $error');
    throw Exception('Unable to retrieve data. $error');
  }

  void _parseResponse(http.Response response) {
    if (verbose) {
      print('Status Code: ${response.statusCode}');
      print('Response JSON:');
      print(response.body);
      print('\n');
    }
  }

  // ─────────────────────────────────────────────────────────────
  // Auth Methods
  // ─────────────────────────────────────────────────────────────

  Future<String?> login(String email, String otp) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUri/v1/login'),
        headers: headers,
        body: jsonEncode({'email': email, 'token': otp}),
      );
      _parseResponse(response);
      final data = jsonDecode(response.body);
      if (data['detail'] != null && data['detail'].toString().contains('?token=')) {
        final token = data['detail'].toString().split('token=')[1];
        headers['Authorization'] = token;
        return token;
      }
      return null;
    } catch (e) {
      return _handleError(e);
    }
  }

  Future<String> registerUser(String email, String firstName, String lastName) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUri/v1/user'),
        headers: headers,
        body: jsonEncode({
          'email': email,
          'first_name': firstName,
          'last_name': lastName,
        }),
      );
      _parseResponse(response);
      final data = jsonDecode(response.body);
      if (data['otp_uri'] != null) {
        final mfaToken = data['otp_uri'].toString().split('secret=')[1].split('&')[0];
        await login(email, mfaToken);
        return data['otp_uri'];
      }
      return jsonEncode(data);
    } catch (e) {
      return _handleError(e);
    }
  }

  Future<bool> userExists(String email) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUri/v1/user/exists?email=${Uri.encodeComponent(email)}'),
        headers: headers,
      );
      _parseResponse(response);
      return jsonDecode(response.body);
    } catch (e) {
      return _handleError(e);
    }
  }

  Future<Map<String, dynamic>> updateUser(Map<String, dynamic> updates) async {
    try {
      final response = await http.put(
        Uri.parse('$baseUri/v1/user'),
        headers: headers,
        body: jsonEncode(updates),
      );
      _parseResponse(response);
      return jsonDecode(response.body);
    } catch (e) {
      return _handleError(e);
    }
  }

  Future<Map<String, dynamic>> getUser() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUri/v1/user'),
        headers: headers,
      );
      _parseResponse(response);
      return jsonDecode(response.body);
    } catch (e) {
      return _handleError(e);
    }
  }

  // ─────────────────────────────────────────────────────────────
  // Provider Methods
  // ─────────────────────────────────────────────────────────────

  Future<List<dynamic>> getProviders() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUri/v1/providers'),
        headers: headers,
      );
      _parseResponse(response);
      final data = jsonDecode(response.body);
      if (data is List) {
        return data;
      }
      return data['providers'] ?? data;
    } catch (e) {
      return _handleError(e);
    }
  }

  Future<Map<String, dynamic>> getEmbedders() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUri/v1/embedders'),
        headers: headers,
      );
      _parseResponse(response);
      final data = jsonDecode(response.body);
      return data['embedders'] ?? data;
    } catch (e) {
      return _handleError(e);
    }
  }

  // ─────────────────────────────────────────────────────────────
  // Agent Methods
  // ─────────────────────────────────────────────────────────────

  Future<Map<String, dynamic>> addAgent(
    String agentName, {
    Map<String, dynamic>? settings,
    Map<String, bool>? commands,
    List<String>? trainingUrls,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUri/v1/agent'),
        headers: headers,
        body: jsonEncode({
          'agent_name': agentName,
          'settings': settings ?? {},
          'commands': commands ?? {},
          'training_urls': trainingUrls ?? [],
        }),
      );
      _parseResponse(response);
      return jsonDecode(response.body);
    } catch (e) {
      return _handleError(e);
    }
  }

  Future<Map<String, dynamic>> importAgent(
    String agentName, {
    Map<String, dynamic>? settings,
    Map<String, bool>? commands,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUri/v1/agent/import'),
        headers: headers,
        body: jsonEncode({
          'agent_name': agentName,
          'settings': settings ?? {},
          'commands': commands ?? {},
        }),
      );
      _parseResponse(response);
      return jsonDecode(response.body);
    } catch (e) {
      return _handleError(e);
    }
  }

  Future<Map<String, dynamic>> renameAgent(String agentId, String newName) async {
    try {
      final response = await http.patch(
        Uri.parse('$baseUri/v1/agent/$agentId'),
        headers: headers,
        body: jsonEncode({'new_name': newName}),
      );
      _parseResponse(response);
      return jsonDecode(response.body);
    } catch (e) {
      return _handleError(e);
    }
  }

  Future<String> updateAgentSettings(
    String agentId,
    Map<String, dynamic> settings, {
    String agentName = '',
  }) async {
    try {
      final response = await http.put(
        Uri.parse('$baseUri/v1/agent/$agentId'),
        headers: headers,
        body: jsonEncode({
          'agent_name': agentName,
          'settings': settings,
          'commands': {},
          'training_urls': [],
        }),
      );
      _parseResponse(response);
      final data = jsonDecode(response.body);
      return data['message'] ?? response.body;
    } catch (e) {
      return _handleError(e);
    }
  }

  Future<String> updateAgentCommands(String agentId, Map<String, bool> commands) async {
    try {
      final response = await http.put(
        Uri.parse('$baseUri/v1/agent/$agentId/commands'),
        headers: headers,
        body: jsonEncode({'commands': commands}),
      );
      _parseResponse(response);
      final data = jsonDecode(response.body);
      return data['message'] ?? response.body;
    } catch (e) {
      return _handleError(e);
    }
  }

  Future<String> deleteAgent(String agentId) async {
    try {
      final response = await http.delete(
        Uri.parse('$baseUri/v1/agent/$agentId'),
        headers: headers,
      );
      _parseResponse(response);
      final data = jsonDecode(response.body);
      return data['message'] ?? response.body;
    } catch (e) {
      return _handleError(e);
    }
  }

  Future<List<dynamic>> getAgents() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUri/v1/agent'),
        headers: headers,
      );
      _parseResponse(response);
      final data = jsonDecode(response.body);
      return data['agents'] ?? data;
    } catch (e) {
      return _handleError(e);
    }
  }

  Future<Map<String, dynamic>> getAgentConfig(String agentId) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUri/v1/agent/$agentId'),
        headers: headers,
      );
      _parseResponse(response);
      final data = jsonDecode(response.body);
      return data['agent'] ?? data;
    } catch (e) {
      return _handleError(e);
    }
  }

  Future<String?> getAgentIdByName(String agentName) async {
    try {
      final agents = await getAgents();
      for (final agent in agents) {
        if (agent is Map && agent['name'] == agentName) {
          return agent['id']?.toString();
        }
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  // ─────────────────────────────────────────────────────────────
  // Conversation Methods
  // ─────────────────────────────────────────────────────────────

  Future<List<dynamic>> getConversations({String agentId = ''}) async {
    try {
      final url = agentId.isNotEmpty
          ? '$baseUri/v1/conversations?agent_id=$agentId'
          : '$baseUri/v1/conversations';
      final response = await http.get(Uri.parse(url), headers: headers);
      _parseResponse(response);
      final data = jsonDecode(response.body);
      if (data is List) {
        return data;
      }
      return data['conversations'] ?? data;
    } catch (e) {
      return _handleError(e);
    }
  }

  Future<List<dynamic>> getConversation(
    String conversationId, {
    int limit = 100,
    int page = 1,
  }) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUri/v1/conversation/$conversationId?limit=$limit&page=$page'),
        headers: headers,
      );
      _parseResponse(response);
      final data = jsonDecode(response.body);
      return data['conversation_history'] ?? data;
    } catch (e) {
      return _handleError(e);
    }
  }

  Future<Map<String, dynamic>> forkConversation(String conversationId, String messageId) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUri/v1/conversation/fork/$conversationId/$messageId'),
        headers: headers,
      );
      _parseResponse(response);
      return jsonDecode(response.body);
    } catch (e) {
      return _handleError(e);
    }
  }

  Future<Map<String, dynamic>> newConversation(
    String agentId,
    String conversationName, {
    List<Map<String, dynamic>>? conversationContent,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUri/v1/conversation'),
        headers: headers,
        body: jsonEncode({
          'conversation_name': conversationName,
          'agent_id': agentId,
          'conversation_content': conversationContent ?? [],
        }),
      );
      _parseResponse(response);
      return jsonDecode(response.body);
    } catch (e) {
      return _handleError(e);
    }
  }

  Future<Map<String, dynamic>> renameConversation(
    String conversationId, {
    String newName = '-',
  }) async {
    try {
      final response = await http.put(
        Uri.parse('$baseUri/v1/conversation/$conversationId'),
        headers: headers,
        body: jsonEncode({'new_conversation_name': newName}),
      );
      _parseResponse(response);
      return jsonDecode(response.body);
    } catch (e) {
      return _handleError(e);
    }
  }

  Future<String> deleteConversation(String conversationId) async {
    try {
      final response = await http.delete(
        Uri.parse('$baseUri/v1/conversation/$conversationId'),
        headers: headers,
      );
      _parseResponse(response);
      final data = jsonDecode(response.body);
      return data['message'] ?? response.body;
    } catch (e) {
      return _handleError(e);
    }
  }

  Future<String> deleteConversationMessage(String conversationId, String messageId) async {
    try {
      final response = await http.delete(
        Uri.parse('$baseUri/v1/conversation/$conversationId/message/$messageId'),
        headers: headers,
      );
      _parseResponse(response);
      final data = jsonDecode(response.body);
      return data['message'] ?? response.body;
    } catch (e) {
      return _handleError(e);
    }
  }

  Future<String> updateConversationMessage(
    String conversationId,
    String messageId,
    String newMessage,
  ) async {
    try {
      final response = await http.put(
        Uri.parse('$baseUri/v1/conversation/$conversationId/message/$messageId'),
        headers: headers,
        body: jsonEncode({'new_message': newMessage}),
      );
      _parseResponse(response);
      final data = jsonDecode(response.body);
      return data['message'] ?? response.body;
    } catch (e) {
      return _handleError(e);
    }
  }

  Future<String> newConversationMessage(
    String role,
    String message,
    String conversationId,
  ) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUri/v1/conversation/$conversationId/message'),
        headers: headers,
        body: jsonEncode({'role': role, 'message': message}),
      );
      _parseResponse(response);
      final data = jsonDecode(response.body);
      return data['message'] ?? response.body;
    } catch (e) {
      return _handleError(e);
    }
  }

  Future<String?> getConversationIdByName(String conversationName) async {
    try {
      final conversations = await getConversations();
      for (final conv in conversations) {
        if (conv is Map && conv['name'] == conversationName) {
          return conv['id']?.toString();
        }
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  // ─────────────────────────────────────────────────────────────
  // Agent Prompt Methods
  // ─────────────────────────────────────────────────────────────

  Future<String> promptAgent(
    String agentId,
    String promptName,
    Map<String, dynamic> promptArgs,
  ) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUri/v1/agent/$agentId/prompt'),
        headers: headers,
        body: jsonEncode({
          'prompt_name': promptName,
          'prompt_args': promptArgs,
        }),
      );
      _parseResponse(response);
      final data = jsonDecode(response.body);
      return data['response'] ?? response.body;
    } catch (e) {
      return _handleError(e);
    }
  }

  Future<String> instruct(String agentId, String userInput, String conversationId) async {
    return promptAgent(agentId, 'instruct', {
      'user_input': userInput,
      'disable_memory': true,
      'conversation_name': conversationId,
    });
  }

  Future<String> chat(
    String agentId,
    String userInput,
    String conversationId, {
    int contextResults = 4,
  }) async {
    return promptAgent(agentId, 'Chat', {
      'user_input': userInput,
      'context_results': contextResults,
      'conversation_name': conversationId,
      'disable_memory': true,
    });
  }

  Future<String> smartinstruct(String agentId, String userInput, String conversationId) async {
    return runChain(
      chainName: 'Smart Instruct',
      userInput: userInput,
      agentId: agentId,
      allResponses: false,
      fromStep: 1,
      chainArgs: {
        'conversation_name': conversationId,
        'disable_memory': true,
      },
    );
  }

  Future<String> smartchat(String agentId, String userInput, String conversationId) async {
    return runChain(
      chainName: 'Smart Chat',
      userInput: userInput,
      agentId: agentId,
      allResponses: false,
      fromStep: 1,
      chainArgs: {
        'conversation_name': conversationId,
        'disable_memory': true,
      },
    );
  }

  // ─────────────────────────────────────────────────────────────
  // Command Methods
  // ─────────────────────────────────────────────────────────────

  Future<Map<String, dynamic>> getCommands(String agentId) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUri/v1/agent/$agentId/command'),
        headers: headers,
      );
      _parseResponse(response);
      final data = jsonDecode(response.body);
      return data['commands'] ?? data;
    } catch (e) {
      return _handleError(e);
    }
  }

  Future<String> toggleCommand(String agentId, String commandName, bool enable) async {
    try {
      final response = await http.patch(
        Uri.parse('$baseUri/v1/agent/$agentId/command'),
        headers: headers,
        body: jsonEncode({'command_name': commandName, 'enable': enable}),
      );
      _parseResponse(response);
      final data = jsonDecode(response.body);
      return data['message'] ?? response.body;
    } catch (e) {
      return _handleError(e);
    }
  }

  Future<String> executeCommand(
    String agentId,
    String commandName,
    Map<String, dynamic> commandArgs, {
    String conversationId = '',
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUri/v1/agent/$agentId/command'),
        headers: headers,
        body: jsonEncode({
          'command_name': commandName,
          'command_args': commandArgs,
          'conversation_name': conversationId,
        }),
      );
      _parseResponse(response);
      final data = jsonDecode(response.body);
      return data['response'] ?? response.body;
    } catch (e) {
      return _handleError(e);
    }
  }

  // ─────────────────────────────────────────────────────────────
  // Chain Methods
  // ─────────────────────────────────────────────────────────────

  Future<List<dynamic>> getChains() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUri/v1/chains'),
        headers: headers,
      );
      _parseResponse(response);
      return jsonDecode(response.body);
    } catch (e) {
      return _handleError(e);
    }
  }

  Future<Map<String, dynamic>> getChain(String chainId) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUri/v1/chain/$chainId'),
        headers: headers,
      );
      _parseResponse(response);
      final data = jsonDecode(response.body);
      if (data is Map && data.length == 1) {
        return data.values.first;
      }
      return data;
    } catch (e) {
      return _handleError(e);
    }
  }

  Future<Map<String, dynamic>> getChainResponses(String chainId) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUri/v1/chain/$chainId/responses'),
        headers: headers,
      );
      _parseResponse(response);
      final data = jsonDecode(response.body);
      return data['chain'] ?? data;
    } catch (e) {
      return _handleError(e);
    }
  }

  Future<List<String>> getChainArgs(String chainId) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUri/v1/chain/$chainId/args'),
        headers: headers,
      );
      _parseResponse(response);
      return List<String>.from(jsonDecode(response.body));
    } catch (e) {
      return _handleError(e);
    }
  }

  Future<dynamic> runChain({
    String chainId = '',
    String chainName = '',
    String userInput = '',
    String agentId = '',
    bool allResponses = false,
    int fromStep = 1,
    Map<String, dynamic>? chainArgs,
  }) async {
    try {
      final endpoint = chainId.isNotEmpty ? chainId : chainName;
      final response = await http.post(
        Uri.parse('$baseUri/v1/chain/$endpoint/run'),
        headers: headers,
        body: jsonEncode({
          'prompt': userInput,
          'agent_override': agentId,
          'all_responses': allResponses,
          'from_step': fromStep,
          'chain_args': chainArgs ?? {},
        }),
      );
      _parseResponse(response);
      return jsonDecode(response.body);
    } catch (e) {
      return _handleError(e);
    }
  }

  Future<dynamic> runChainStep(
    String chainId,
    int stepNumber,
    String userInput, {
    String agentId = '',
    Map<String, dynamic>? chainArgs,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUri/v1/chain/$chainId/run/step/$stepNumber'),
        headers: headers,
        body: jsonEncode({
          'prompt': userInput,
          'agent_override': agentId,
          'chain_args': chainArgs ?? {},
        }),
      );
      _parseResponse(response);
      return jsonDecode(response.body);
    } catch (e) {
      return _handleError(e);
    }
  }

  Future<Map<String, dynamic>> addChain(String chainName) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUri/v1/chain'),
        headers: headers,
        body: jsonEncode({'chain_name': chainName}),
      );
      _parseResponse(response);
      return jsonDecode(response.body);
    } catch (e) {
      return _handleError(e);
    }
  }

  Future<String> importChain(String chainName, dynamic steps) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUri/v1/chain/import'),
        headers: headers,
        body: jsonEncode({'chain_name': chainName, 'steps': steps}),
      );
      _parseResponse(response);
      final data = jsonDecode(response.body);
      return data['message'] ?? response.body;
    } catch (e) {
      return _handleError(e);
    }
  }

  Future<String> renameChain(String chainId, String newName) async {
    try {
      final response = await http.put(
        Uri.parse('$baseUri/v1/chain/$chainId'),
        headers: headers,
        body: jsonEncode({'new_name': newName}),
      );
      _parseResponse(response);
      final data = jsonDecode(response.body);
      return data['message'] ?? response.body;
    } catch (e) {
      return _handleError(e);
    }
  }

  Future<String> deleteChain(String chainId) async {
    try {
      final response = await http.delete(
        Uri.parse('$baseUri/v1/chain/$chainId'),
        headers: headers,
      );
      _parseResponse(response);
      final data = jsonDecode(response.body);
      return data['message'] ?? response.body;
    } catch (e) {
      return _handleError(e);
    }
  }

  Future<String> addStep(
    String chainId,
    int stepNumber,
    String agentId,
    String promptType,
    dynamic prompt,
  ) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUri/v1/chain/$chainId/step'),
        headers: headers,
        body: jsonEncode({
          'step_number': stepNumber,
          'agent_id': agentId,
          'prompt_type': promptType,
          'prompt': prompt,
        }),
      );
      _parseResponse(response);
      final data = jsonDecode(response.body);
      return data['message'] ?? response.body;
    } catch (e) {
      return _handleError(e);
    }
  }

  Future<String> updateStep(
    String chainId,
    int stepNumber,
    String agentId,
    String promptType,
    dynamic prompt,
  ) async {
    try {
      final response = await http.put(
        Uri.parse('$baseUri/v1/chain/$chainId/step/$stepNumber'),
        headers: headers,
        body: jsonEncode({
          'step_number': stepNumber,
          'agent_id': agentId,
          'prompt_type': promptType,
          'prompt': prompt,
        }),
      );
      _parseResponse(response);
      final data = jsonDecode(response.body);
      return data['message'] ?? response.body;
    } catch (e) {
      return _handleError(e);
    }
  }

  Future<String> moveStep(String chainId, int oldStepNumber, int newStepNumber) async {
    try {
      final response = await http.patch(
        Uri.parse('$baseUri/v1/chain/$chainId/step/move'),
        headers: headers,
        body: jsonEncode({
          'old_step_number': oldStepNumber,
          'new_step_number': newStepNumber,
        }),
      );
      _parseResponse(response);
      final data = jsonDecode(response.body);
      return data['message'] ?? response.body;
    } catch (e) {
      return _handleError(e);
    }
  }

  Future<String> deleteStep(String chainId, int stepNumber) async {
    try {
      final response = await http.delete(
        Uri.parse('$baseUri/v1/chain/$chainId/step/$stepNumber'),
        headers: headers,
      );
      _parseResponse(response);
      final data = jsonDecode(response.body);
      return data['message'] ?? response.body;
    } catch (e) {
      return _handleError(e);
    }
  }

  Future<String?> getChainIdByName(String chainName) async {
    try {
      final chains = await getChains();
      for (final chain in chains) {
        if (chain is Map && chain['name'] == chainName) {
          return chain['id']?.toString();
        }
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  // ─────────────────────────────────────────────────────────────
  // Prompt Methods
  // ─────────────────────────────────────────────────────────────

  Future<Map<String, dynamic>> addPrompt(
    String promptName,
    String prompt, {
    String promptCategory = 'Default',
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUri/v1/prompt'),
        headers: headers,
        body: jsonEncode({
          'prompt_name': promptName,
          'prompt': prompt,
          'prompt_category': promptCategory,
        }),
      );
      _parseResponse(response);
      return jsonDecode(response.body);
    } catch (e) {
      return _handleError(e);
    }
  }

  Future<Map<String, dynamic>> getPrompt(String promptId) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUri/v1/prompt/$promptId'),
        headers: headers,
      );
      _parseResponse(response);
      return jsonDecode(response.body);
    } catch (e) {
      return _handleError(e);
    }
  }

  Future<List<dynamic>> getPrompts({String promptCategory = 'Default'}) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUri/v1/prompts?prompt_category=${Uri.encodeComponent(promptCategory)}'),
        headers: headers,
      );
      _parseResponse(response);
      final data = jsonDecode(response.body);
      return data['prompts'] ?? data;
    } catch (e) {
      return _handleError(e);
    }
  }

  Future<Map<String, dynamic>> getAllPrompts() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUri/v1/prompt/all'),
        headers: headers,
      );
      _parseResponse(response);
      return jsonDecode(response.body);
    } catch (e) {
      return _handleError(e);
    }
  }

  Future<List<dynamic>> getPromptCategories() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUri/v1/prompt/categories'),
        headers: headers,
      );
      _parseResponse(response);
      final data = jsonDecode(response.body);
      return data['categories'] ?? data;
    } catch (e) {
      return _handleError(e);
    }
  }

  Future<List<dynamic>> getPromptsByCategoryId(String categoryId) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUri/v1/prompt/category/$categoryId'),
        headers: headers,
      );
      _parseResponse(response);
      final data = jsonDecode(response.body);
      return data['prompts'] ?? data;
    } catch (e) {
      return _handleError(e);
    }
  }

  Future<Map<String, dynamic>> getPromptArgs(String promptId) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUri/v1/prompt/$promptId/args'),
        headers: headers,
      );
      _parseResponse(response);
      final data = jsonDecode(response.body);
      return data['prompt_args'] ?? data;
    } catch (e) {
      return _handleError(e);
    }
  }

  Future<String> deletePrompt(String promptId) async {
    try {
      final response = await http.delete(
        Uri.parse('$baseUri/v1/prompt/$promptId'),
        headers: headers,
      );
      _parseResponse(response);
      final data = jsonDecode(response.body);
      return data['message'] ?? response.body;
    } catch (e) {
      return _handleError(e);
    }
  }

  Future<String> updatePrompt(String promptId, String prompt) async {
    try {
      final response = await http.put(
        Uri.parse('$baseUri/v1/prompt/$promptId'),
        headers: headers,
        body: jsonEncode({'prompt': prompt}),
      );
      _parseResponse(response);
      final data = jsonDecode(response.body);
      return data['message'] ?? response.body;
    } catch (e) {
      return _handleError(e);
    }
  }

  Future<String> renamePrompt(String promptId, String newName) async {
    try {
      final response = await http.patch(
        Uri.parse('$baseUri/v1/prompt/$promptId'),
        headers: headers,
        body: jsonEncode({'prompt_name': newName}),
      );
      _parseResponse(response);
      final data = jsonDecode(response.body);
      return data['message'] ?? response.body;
    } catch (e) {
      return _handleError(e);
    }
  }

  // ─────────────────────────────────────────────────────────────
  // Extension Methods
  // ─────────────────────────────────────────────────────────────

  Future<Map<String, dynamic>> getExtensionSettings() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUri/v1/extensions/settings'),
        headers: headers,
      );
      _parseResponse(response);
      final data = jsonDecode(response.body);
      return data['extension_settings'] ?? data;
    } catch (e) {
      return _handleError(e);
    }
  }

  Future<List<dynamic>> getExtensions() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUri/v1/extensions'),
        headers: headers,
      );
      _parseResponse(response);
      final data = jsonDecode(response.body);
      if (data is List) {
        return data;
      }
      return data['extensions'] ?? data;
    } catch (e) {
      return _handleError(e);
    }
  }

  Future<List<dynamic>> getAgentExtensions(String agentId) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUri/v1/agent/$agentId/extensions'),
        headers: headers,
      );
      _parseResponse(response);
      final data = jsonDecode(response.body);
      return data['extensions'] ?? data;
    } catch (e) {
      return _handleError(e);
    }
  }

  Future<Map<String, dynamic>> getCommandArgs(String commandName) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUri/v1/extensions/$commandName/args'),
        headers: headers,
      );
      _parseResponse(response);
      final data = jsonDecode(response.body);
      return data['command_args'] ?? data;
    } catch (e) {
      return _handleError(e);
    }
  }

  // ─────────────────────────────────────────────────────────────
  // Memory Methods
  // ─────────────────────────────────────────────────────────────

  Future<String> learnText(
    String agentId,
    String userInput,
    String text, {
    String collectionNumber = '0',
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUri/v1/agent/$agentId/learn/text'),
        headers: headers,
        body: jsonEncode({
          'user_input': userInput,
          'text': text,
          'collection_number': collectionNumber,
        }),
      );
      _parseResponse(response);
      final data = jsonDecode(response.body);
      return data['message'] ?? response.body;
    } catch (e) {
      return _handleError(e);
    }
  }

  Future<String> learnUrl(
    String agentId,
    String url, {
    String collectionNumber = '0',
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUri/v1/agent/$agentId/learn/url'),
        headers: headers,
        body: jsonEncode({
          'url': url,
          'collection_number': collectionNumber,
        }),
      );
      _parseResponse(response);
      final data = jsonDecode(response.body);
      return data['message'] ?? response.body;
    } catch (e) {
      return _handleError(e);
    }
  }

  Future<String> learnFile(
    String agentId,
    String fileName,
    String fileContent, {
    String collectionNumber = '0',
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUri/v1/agent/$agentId/learn/file'),
        headers: headers,
        body: jsonEncode({
          'file_name': fileName,
          'file_content': fileContent,
          'collection_number': collectionNumber,
        }),
      );
      _parseResponse(response);
      final data = jsonDecode(response.body);
      return data['message'] ?? response.body;
    } catch (e) {
      return _handleError(e);
    }
  }

  Future<String> learnGithubRepo(
    String agentId,
    String githubRepo, {
    String? githubUser,
    String? githubToken,
    String githubBranch = 'main',
    bool useAgentSettings = false,
    String collectionNumber = '0',
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUri/v1/agent/$agentId/learn/github'),
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
      _parseResponse(response);
      final data = jsonDecode(response.body);
      return data['message'] ?? response.body;
    } catch (e) {
      return _handleError(e);
    }
  }

  Future<String> learnArxiv(
    String agentId, {
    String query = '',
    String arxivIds = '',
    int maxResults = 5,
    String collectionNumber = '0',
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUri/v1/agent/$agentId/learn/arxiv'),
        headers: headers,
        body: jsonEncode({
          'query': query,
          'arxiv_ids': arxivIds,
          'max_results': maxResults,
          'collection_number': collectionNumber,
        }),
      );
      _parseResponse(response);
      final data = jsonDecode(response.body);
      return data['message'] ?? response.body;
    } catch (e) {
      return _handleError(e);
    }
  }

  Future<String> agentReader(
    String agentId,
    String readerName,
    Map<String, dynamic> data, {
    String collectionNumber = '0',
  }) async {
    if (!data.containsKey('collection_number')) {
      data['collection_number'] = collectionNumber;
    }
    try {
      final response = await http.post(
        Uri.parse('$baseUri/v1/agent/$agentId/reader/$readerName'),
        headers: headers,
        body: jsonEncode({'data': data}),
      );
      _parseResponse(response);
      final respData = jsonDecode(response.body);
      return respData['message'] ?? response.body;
    } catch (e) {
      return _handleError(e);
    }
  }

  Future<String> wipeAgentMemories(String agentId, {String collectionNumber = '0'}) async {
    try {
      final response = await http.delete(
        Uri.parse('$baseUri/v1/agent/$agentId/memory/$collectionNumber'),
        headers: headers,
      );
      _parseResponse(response);
      final data = jsonDecode(response.body);
      return data['message'] ?? response.body;
    } catch (e) {
      return _handleError(e);
    }
  }

  Future<String> deleteAgentMemory(
    String agentId,
    String memoryId, {
    String collectionNumber = '0',
  }) async {
    try {
      final response = await http.delete(
        Uri.parse('$baseUri/v1/agent/$agentId/memory/$collectionNumber/$memoryId'),
        headers: headers,
      );
      _parseResponse(response);
      final data = jsonDecode(response.body);
      return data['message'] ?? response.body;
    } catch (e) {
      return _handleError(e);
    }
  }

  Future<List<dynamic>> getAgentMemories(
    String agentId,
    String userInput, {
    int limit = 5,
    double minRelevanceScore = 0.0,
    String collectionNumber = '0',
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUri/v1/agent/$agentId/memory/$collectionNumber/query'),
        headers: headers,
        body: jsonEncode({
          'user_input': userInput,
          'limit': limit,
          'min_relevance_score': minRelevanceScore,
        }),
      );
      _parseResponse(response);
      final data = jsonDecode(response.body);
      return data['memories'] ?? data;
    } catch (e) {
      return _handleError(e);
    }
  }

  Future<List<dynamic>> exportAgentMemories(String agentId) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUri/v1/agent/$agentId/memory/export'),
        headers: headers,
      );
      _parseResponse(response);
      final data = jsonDecode(response.body);
      return data['memories'] ?? data;
    } catch (e) {
      return _handleError(e);
    }
  }

  Future<String> importAgentMemories(String agentId, List<dynamic> memories) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUri/v1/agent/$agentId/memory/import'),
        headers: headers,
        body: jsonEncode({'memories': memories}),
      );
      _parseResponse(response);
      final data = jsonDecode(response.body);
      return data['message'] ?? response.body;
    } catch (e) {
      return _handleError(e);
    }
  }

  Future<String> createDataset(
    String agentId,
    String datasetName, {
    int batchSize = 4,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUri/v1/agent/$agentId/memory/dataset'),
        headers: headers,
        body: jsonEncode({
          'dataset_name': datasetName,
          'batch_size': batchSize,
        }),
      );
      _parseResponse(response);
      final data = jsonDecode(response.body);
      return data['message'] ?? response.body;
    } catch (e) {
      return _handleError(e);
    }
  }

  Future<List<String>> getBrowsedLinks(String agentId, {String collectionNumber = '0'}) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUri/v1/agent/$agentId/browsed_links/$collectionNumber'),
        headers: headers,
      );
      _parseResponse(response);
      final data = jsonDecode(response.body);
      return List<String>.from(data['links'] ?? []);
    } catch (e) {
      return _handleError(e);
    }
  }

  Future<String> deleteBrowsedLink(
    String agentId,
    String link, {
    String collectionNumber = '0',
  }) async {
    try {
      final request = http.Request('DELETE', Uri.parse('$baseUri/v1/agent/$agentId/browsed_links'));
      request.headers.addAll(headers);
      request.body = jsonEncode({'link': link, 'collection_number': collectionNumber});
      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);
      _parseResponse(response);
      final data = jsonDecode(response.body);
      return data['message'] ?? response.body;
    } catch (e) {
      return _handleError(e);
    }
  }

  Future<Map<String, dynamic>> getMemoriesExternalSources(
    String agentId,
    String collectionNumber,
  ) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUri/v1/agent/$agentId/memory/external_sources/$collectionNumber'),
        headers: headers,
      );
      _parseResponse(response);
      final data = jsonDecode(response.body);
      return data['external_sources'] ?? data;
    } catch (e) {
      return _handleError(e);
    }
  }

  Future<String> deleteMemoryExternalSource(
    String agentId,
    String source,
    String collectionNumber,
  ) async {
    try {
      final request = http.Request('DELETE', Uri.parse('$baseUri/v1/agent/$agentId/memory/external_source'));
      request.headers.addAll(headers);
      request.body = jsonEncode({
        'external_source': source,
        'collection_number': collectionNumber,
      });
      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);
      _parseResponse(response);
      final data = jsonDecode(response.body);
      return data['message'] ?? response.body;
    } catch (e) {
      return _handleError(e);
    }
  }

  // ─────────────────────────────────────────────────────────────
  // Persona Methods
  // ─────────────────────────────────────────────────────────────

  Future<String> getPersona(String agentId) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUri/v1/agent/$agentId/persona'),
        headers: headers,
      );
      _parseResponse(response);
      final data = jsonDecode(response.body);
      return data['message'] ?? response.body;
    } catch (e) {
      return _handleError(e);
    }
  }

  Future<String> updatePersona(String agentId, String persona) async {
    try {
      final response = await http.put(
        Uri.parse('$baseUri/v1/agent/$agentId/persona'),
        headers: headers,
        body: jsonEncode({'persona': persona}),
      );
      _parseResponse(response);
      final data = jsonDecode(response.body);
      return data['message'] ?? response.body;
    } catch (e) {
      return _handleError(e);
    }
  }

  // ─────────────────────────────────────────────────────────────
  // Feedback Methods
  // ─────────────────────────────────────────────────────────────

  Future<String> positiveFeedback(
    String agentId,
    String message,
    String userInput,
    String feedback, {
    String conversationId = '',
  }) async {
    return _provideFeedback(agentId, message, userInput, feedback, true, conversationId);
  }

  Future<String> negativeFeedback(
    String agentId,
    String message,
    String userInput,
    String feedback, {
    String conversationId = '',
  }) async {
    return _provideFeedback(agentId, message, userInput, feedback, false, conversationId);
  }

  Future<String> _provideFeedback(
    String agentId,
    String message,
    String userInput,
    String feedback,
    bool positive,
    String conversationId,
  ) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUri/v1/agent/$agentId/feedback'),
        headers: headers,
        body: jsonEncode({
          'user_input': userInput,
          'message': message,
          'feedback': feedback,
          'positive': positive,
          'conversation_name': conversationId,
        }),
      );
      _parseResponse(response);
      final data = jsonDecode(response.body);
      return data['message'] ?? response.body;
    } catch (e) {
      return _handleError(e);
    }
  }

  // ─────────────────────────────────────────────────────────────
  // Text-to-Speech Methods
  // ─────────────────────────────────────────────────────────────

  Future<String> textToSpeech(String agentId, String text) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUri/v1/agent/$agentId/text_to_speech'),
        headers: headers,
        body: jsonEncode({'text': text}),
      );
      _parseResponse(response);
      final data = jsonDecode(response.body);
      return data['url'] ?? response.body;
    } catch (e) {
      return _handleError(e);
    }
  }

  // ─────────────────────────────────────────────────────────────
  // Task Planning Methods
  // ─────────────────────────────────────────────────────────────

  Future<String> planTask(
    String agentId,
    String userInput, {
    bool websearch = false,
    int websearchDepth = 3,
    String conversationId = '',
    bool logUserInput = true,
    bool logOutput = true,
    bool enableNewCommand = true,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUri/v1/agent/$agentId/plan/task'),
        headers: headers,
        body: jsonEncode({
          'user_input': userInput,
          'websearch': websearch,
          'websearch_depth': websearchDepth,
          'conversation_name': conversationId,
          'log_user_input': logUserInput,
          'log_output': logOutput,
          'enable_new_command': enableNewCommand,
        }),
      );
      _parseResponse(response);
      final data = jsonDecode(response.body);
      return data['response'] ?? response.body;
    } catch (e) {
      return _handleError(e);
    }
  }

  // ─────────────────────────────────────────────────────────────
  // Company Methods
  // ─────────────────────────────────────────────────────────────

  Future<List<dynamic>> getCompanies() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUri/v1/companies'),
        headers: headers,
      );
      _parseResponse(response);
      return jsonDecode(response.body);
    } catch (e) {
      return _handleError(e);
    }
  }

  Future<Map<String, dynamic>> createCompany(
    String name,
    String agentName, {
    String? parentCompanyId,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUri/v1/companies'),
        headers: headers,
        body: jsonEncode({
          'name': name,
          'agent_name': agentName,
          'parent_company_id': parentCompanyId,
        }),
      );
      _parseResponse(response);
      return jsonDecode(response.body);
    } catch (e) {
      return _handleError(e);
    }
  }

  Future<Map<String, dynamic>> updateCompany(String companyId, String name) async {
    try {
      final response = await http.put(
        Uri.parse('$baseUri/v1/companies/$companyId'),
        headers: headers,
        body: jsonEncode({'name': name}),
      );
      _parseResponse(response);
      return jsonDecode(response.body);
    } catch (e) {
      return _handleError(e);
    }
  }

  Future<Map<String, dynamic>> deleteCompany(String companyId) async {
    try {
      final response = await http.delete(
        Uri.parse('$baseUri/v1/companies/$companyId'),
        headers: headers,
      );
      _parseResponse(response);
      return jsonDecode(response.body);
    } catch (e) {
      return _handleError(e);
    }
  }

  Future<Map<String, dynamic>> deleteUserFromCompany(String companyId, String userId) async {
    try {
      final response = await http.delete(
        Uri.parse('$baseUri/v1/companies/$companyId/users/$userId'),
        headers: headers,
      );
      _parseResponse(response);
      return jsonDecode(response.body);
    } catch (e) {
      return _handleError(e);
    }
  }

  // ─────────────────────────────────────────────────────────────
  // Invitation Methods
  // ─────────────────────────────────────────────────────────────

  Future<List<dynamic>> getInvitations({String? companyId}) async {
    try {
      final url = companyId != null
          ? '$baseUri/v1/invitations/$companyId'
          : '$baseUri/v1/invitations';
      final response = await http.get(Uri.parse(url), headers: headers);
      _parseResponse(response);
      final data = jsonDecode(response.body);
      return data['invitations'] ?? data;
    } catch (e) {
      return _handleError(e);
    }
  }

  // ─────────────────────────────────────────────────────────────
  // OAuth2 Methods
  // ─────────────────────────────────────────────────────────────

  Future<List<dynamic>> getOauth2Providers() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUri/v1/oauth2'),
        headers: headers,
      );
      _parseResponse(response);
      return jsonDecode(response.body);
    } catch (e) {
      return _handleError(e);
    }
  }

  Future<List<String>> getUserOauth2Connections() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUri/v1/user/oauth2'),
        headers: headers,
      );
      _parseResponse(response);
      return List<String>.from(jsonDecode(response.body));
    } catch (e) {
      return _handleError(e);
    }
  }

  Future<Map<String, dynamic>> oauth2Login(String provider, String code, {String? referrer}) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUri/v1/oauth2/$provider'),
        headers: headers,
        body: jsonEncode({'code': code, 'referrer': referrer}),
      );
      _parseResponse(response);
      return jsonDecode(response.body);
    } catch (e) {
      return _handleError(e);
    }
  }

  // ─────────────────────────────────────────────────────────────
  // Training Methods
  // ─────────────────────────────────────────────────────────────

  Future<Map<String, dynamic>> train(
    String agentId, {
    String datasetName = 'dataset',
    String model = 'unsloth/mistral-7b-v0.2',
    int maxSeqLength = 16384,
    String huggingfaceOutputPath = 'JoshXT/finetuned-mistral-7b-v0.2',
    bool privateRepo = true,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUri/v1/agent/$agentId/train'),
        headers: headers,
        body: jsonEncode({
          'dataset_name': datasetName,
          'model': model,
          'max_seq_length': maxSeqLength,
          'huggingface_output_path': huggingfaceOutputPath,
          'private_repo': privateRepo,
        }),
      );
      _parseResponse(response);
      return jsonDecode(response.body);
    } catch (e) {
      return _handleError(e);
    }
  }

  // ─────────────────────────────────────────────────────────────
  // Audio Methods
  // ─────────────────────────────────────────────────────────────

  Future<Map<String, dynamic>> transcribeAudio(
    String file,
    String model, {
    String? language,
    String? prompt,
    String responseFormat = 'json',
    double temperature = 0.0,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUri/v1/audio/transcriptions'),
        headers: headers,
        body: jsonEncode({
          'file': file,
          'model': model,
          'language': language,
          'prompt': prompt,
          'response_format': responseFormat,
          'temperature': temperature,
        }),
      );
      _parseResponse(response);
      return jsonDecode(response.body);
    } catch (e) {
      return _handleError(e);
    }
  }

  Future<Map<String, dynamic>> translateAudio(
    String file,
    String model, {
    String? prompt,
    String responseFormat = 'json',
    double temperature = 0.0,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUri/v1/audio/translations'),
        headers: headers,
        body: jsonEncode({
          'file': file,
          'model': model,
          'prompt': prompt,
          'response_format': responseFormat,
          'temperature': temperature,
        }),
      );
      _parseResponse(response);
      return jsonDecode(response.body);
    } catch (e) {
      return _handleError(e);
    }
  }

  // ─────────────────────────────────────────────────────────────
  // Image Generation Methods
  // ─────────────────────────────────────────────────────────────

  Future<Map<String, dynamic>> generateImage(
    String prompt, {
    String model = 'dall-e-3',
    int n = 1,
    String size = '1024x1024',
    String responseFormat = 'url',
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUri/v1/images/generations'),
        headers: headers,
        body: jsonEncode({
          'prompt': prompt,
          'model': model,
          'n': n,
          'size': size,
          'response_format': responseFormat,
        }),
      );
      _parseResponse(response);
      return jsonDecode(response.body);
    } catch (e) {
      return _handleError(e);
    }
  }
}
