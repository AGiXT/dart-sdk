import 'dart:convert';
import 'package:http/http.dart' as http;

class AGiXTSDK {
  final String baseUri;
  final Map<String, String> headers;

  AGiXTSDK({String baseUri = 'http://localhost:7437', String apiKey})
      : baseUri = baseUri.endsWith('/') ? baseUri.substring(0, baseUri.length - 1) : baseUri,
        headers = {
          'Content-Type': 'application/json',
          if (apiKey != null) 'Authorization': apiKey.replaceAll('Bearer ', '').replaceAll('bearer ', ''),
        };

  dynamic handleError(error) {
    print('Error: $error');
    return 'Unable to retrieve data.';
  }

  Future<List<String>> getProviders() async {
    try {
      final response = await http.get(Uri.parse('$baseUri/api/provider'), headers: headers);
      return List<String>.from(json.decode(response.body)['providers']);
    } catch (e) {
      return handleError(e);
    }
  }

  Future<List<String>> getProvidersByService(String service) async {
    try {
      final response = await http.get(Uri.parse('$baseUri/api/providers/service/$service'), headers: headers);
      return List<String>.from(json.decode(response.body)['providers']);
    } catch (e) {
      return handleError(e);
    }
  }

  Future<Map<String, dynamic>> getProviderSettings(String providerName) async {
    try {
      final response = await http.get(Uri.parse('$baseUri/api/provider/$providerName'), headers: headers);
      return Map<String, dynamic>.from(json.decode(response.body)['settings']);
    } catch (e) {
      return handleError(e);
    }
  }

  Future<List<String>> getEmbedProviders() async {
    try {
      final response = await http.get(Uri.parse('$baseUri/api/embedding_providers'), headers: headers);
      return List<String>.from(json.decode(response.body)['providers']);
    } catch (e) {
      return handleError(e);
    }
  }

  Future<Map<String, dynamic>> getEmbedders() async {
    try {
      final response = await http.get(Uri.parse('$baseUri/api/embedders'), headers: headers);
      return Map<String, dynamic>.from(json.decode(response.body)['embedders']);
    } catch (e) {
      return handleError(e);
    }
  }

  Future<Map<String, dynamic>> addAgent(String agentName, {Map<String, dynamic> settings = const {}}) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUri/api/agent'),
        headers: headers,
        body: json.encode({'agent_name': agentName, 'settings': settings}),
      );
      return Map<String, dynamic>.from(json.decode(response.body));
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
        body: json.encode({'agent_name': agentName, 'settings': settings, 'commands': commands}),
      );
      return Map<String, dynamic>.from(json.decode(response.body));
    } catch (e) {
      return handleError(e);
    }
  }

  Future<String> renameAgent(String agentName, String newName) async {
    try {
      final response = await http.patch(
        Uri.parse('$baseUri/api/agent/$agentName'),
        headers: headers,
        body: json.encode({'new_name': newName}),
      );
      return response.body;
    } catch (e) {
      return handleError(e);
    }
  }

  Future<String> updateAgentSettings(String agentName, Map<String, dynamic> settings) async {
    try {
      final response = await http.put(
        Uri.parse('$baseUri/api/agent/$agentName'),
        body: json.encode({'settings': settings, 'agent_name': agentName}),
      );
      return json.decode(response.body)['message'];
    } catch (e) {
      return handleError(e);
    }
  }

  Future<String> updateAgentCommands(String agentName, Map<String, dynamic> commands) async {
    try {
      final response = await http.put(
        Uri.parse('$baseUri/api/agent/$agentName/commands'),
        body: json.encode({'commands': commands, 'agent_name': agentName}),
      );
      return json.decode(response.body)['message'];
    } catch (e) {
      return handleError(e);
    }
  }

  Future<String> deleteAgent(String agentName) async {
    try {
      final response = await http.delete(Uri.parse('$baseUri/api/agent/$agentName'), headers: headers);
      return json.decode(response.body)['message'];
    } catch (e) {
      return handleError(e);
    }
  }

  Future<List<Map<String, dynamic>>> getAgents() async {
    try {
      final response = await http.get(Uri.parse('$baseUri/api/agent'), headers: headers);
      return List<Map<String, dynamic>>.from(json.decode(response.body)['agents']);
    } catch (e) {
      return handleError(e);
    }
  }

  Future<Map<String, dynamic>> getAgentConfig(String agentName) async {
    try {
      final response = await http.get(Uri.parse('$baseUri/api/agent/$agentName'), headers: headers);
      return Map<String, dynamic>.from(json.decode(response.body)['agent']);
    } catch (e) {
      return handleError(e);
    }
  }

  Future<List<String>> getConversations({String agentName = ''}) async {
    final url = agentName.isEmpty ? '$baseUri/api/conversations' : '$baseUri/api/$agentName/conversations';
    try {
      final response = await http.get(Uri.parse(url), headers: headers);
      return List<String>.from(json.decode(response.body)['conversations']);
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
        body: json.encode({
          'conversation_name': conversationName,
          'agent_name': agentName,
          'limit': limit,
          'page': page,
        }),
      );
      return List<Map<String, dynamic>>.from(json.decode(response.body)['conversation_history']);
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
        body: json.encode({
          'conversation_name': conversationName,
          'agent_name': agentName,
          'conversation_content': conversationContent,
        }),
      );
      return List<Map<String, dynamic>>.from(json.decode(response.body)['conversation_history']);
    } catch (e) {
      return handleError(e);
    }
  }

  Future<String> deleteConversation(String agentName, String conversationName) async {
    try {
      final response = await http.delete(
        Uri.parse('$baseUri/api/conversation'),
        headers: headers,
        body: json.encode({
          'conversation_name': conversationName,
          'agent_name': agentName,
        }),
      );
      return json.decode(response.body)['message'];
    } catch (e) {
      return handleError(e);
    }
  }

  Future<String> deleteConversationMessage(String agentName, String conversationName, String message) async {
    try {
      final response = await http.delete(
        Uri.parse('$baseUri/api/conversation/message'),
        headers: headers,
        body: json.encode({
          'message': message,
          'agent_name': agentName,
          'conversation_name': conversationName,
        }),
      );
      return json.decode(response.body)['message'];
    } catch (e) {
      return handleError(e);
    }
  }

  Future<String> updateConversationMessage(
    String agentName,
    String conversationName,
    String message,
    String newMessage,
  ) async {
    try {
      final response = await http.put(
        Uri.parse('$baseUri/api/conversation/message'),
        headers: headers,
        body: json.encode({
          'message': message,
          'new_message': newMessage,
          'agent_name': agentName,
          'conversation_name': conversationName,
        }),
      );
      return json.decode(response.body)['message'];
    } catch (e) {
      return handleError(e);
    }
  }

  Future<String> promptAgent(
    String agentName,
    String promptName,
    Map<String, dynamic> promptArgs,
  ) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUri/api/agent/$agentName/prompt'),
        headers: headers,
        body: json.encode({
          'prompt_name': promptName,
          'prompt_args': promptArgs,
        }),
      );
      return json.decode(response.body)['response'];
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
      final response = await http.get(Uri.parse('$baseUri/api/agent/$agentName/command'), headers: headers);
      return Map<String, Map<String, bool>>.from(json.decode(response.body)['commands']);
    } catch (e) {
      return handleError(e);
    }
  }

  Future<String> toggleCommand(String agentName, String commandName, bool enable) async {
    try {
      final response = await http.patch(
        Uri.parse('$baseUri/api/agent/$agentName/command'),
        headers: headers,
        body: json.encode({'command_name': commandName, 'enable': enable}),
      );
      return json.decode(response.body)['message'];
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
        body: json.encode({
          'command_name': commandName,
          'command_args': commandArgs,
          'conversation_name': conversationName,
        }),
      );
      return json.decode(response.body)['response'];
    } catch (e) {
      return handleError(e);
    }
  }

  Future<List<String>> getChains() async {
    try {
      final response = await http.get(Uri.parse('$baseUri/api/chain'), headers: headers);
      return List<String>.from(json.decode(response.body));
    } catch (e) {
      return handleError(e);
    }
  }

  Future<Map<String, dynamic>> getChain(String chainName) async {
    try {
      final response = await http.get(Uri.parse('$baseUri/api/chain/$chainName'), headers: headers);
      return Map<String, dynamic>.from(json.decode(response.body)['chain']);
    } catch (e) {
      return handleError(e);
    }
  }

  Future<Map<String, dynamic>> getChainResponses(String chainName) async {
    try {
      final response = await http.get(Uri.parse('$baseUri/api/chain/$chainName/responses'), headers: headers);
      return Map<String, dynamic>.from(json.decode(response.body)['chain']);
    } catch (e) {
      return handleError(e);
    }
  }

  Future<List<String>> getChainArgs(String chainName) async {
    try {
      final response = await http.get(Uri.parse('$baseUri/api/chain/$chainName/args'), headers: headers);
      return List<String>.from(json.decode(response.body)['chain_args']);
    } catch (e) {
      return handleError(e);
    }
  }

  Future<dynamic> runChain(
    String chainName,
    String userInput, {
    String agentName = '',
    bool allResponses = false,
    int fromStep = 1,
    Map<String, dynamic> chainArgs = const {},
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUri/api/chain/$chainName/run'),
        headers: headers,
        body: json.encode({
          'prompt': userInput,
          'agent_override': agentName,
          'all_responses': allResponses,
          'from_step': fromStep,
          'chain_args': chainArgs,
        }),
      );
      return json.decode(response.body);
    } catch (e) {
      return handleError(e);
}
  }

  Future<dynamic> runChainStep(
    String chainName,
    int stepNumber,
    String userInput, {
    String agentName,
    Map<String, dynamic> chainArgs = const {},
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUri/api/chain/$chainName/run/step/$stepNumber'),
        headers: headers,
        body: json.encode({
          'prompt': userInput,
          'agent_override': agentName,
          'chain_args': chainArgs,
        }),
      );
      return json.decode(response.body);
    } catch (e) {
      return handleError(e);
    }
  }

  Future<String> addChain(String chainName) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUri/api/chain'),
        headers: headers,
        body: json.encode({'chain_name': chainName}),
      );
      return json.decode(response.body)['message'];
    } catch (e) {
      return handleError(e);
    }
  }

  Future<String> importChain(String chainName, Map<String, dynamic> steps) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUri/api/chain/import'),
        headers: headers,
        body: json.encode({'chain_name': chainName, 'steps': steps}),
      );
      return json.decode(response.body)['message'];
    } catch (e) {
      return handleError(e);
    }
  }

  Future<String> renameChain(String chainName, String newName) async {
    try {
      final response = await http.put(
        Uri.parse('$baseUri/api/chain/$chainName'),
        body: json.encode({'new_name': newName}),
      );
      return json.decode(response.body)['message'];
    } catch (e) {
      return handleError(e);
    }
  }

  Future<String> deleteChain(String chainName) async {
    try {
      final response = await http.delete(Uri.parse('$baseUri/api/chain/$chainName'), headers: headers);
      return json.decode(response.body)['message'];
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
        body: json.encode({
          'step_number': stepNumber,
          'agent_name': agentName,
          'prompt_type': promptType,
          'prompt': prompt,
        }),
      );
      return json.decode(response.body)['message'];
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
        body: json.encode({
          'step_number': stepNumber,
          'agent_name': agentName,
          'prompt_type': promptType,
          'prompt': prompt,
        }),
      );
      return json.decode(response.body)['message'];
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
        body: json.encode({
          'old_step_number': oldStepNumber,
          'new_step_number': newStepNumber,
        }),
      );
      return json.decode(response.body)['message'];
    } catch (e) {
      return handleError(e);
    }
  }

  Future<String> deleteStep(String chainName, int stepNumber) async {
    try {
      final response = await http.delete(Uri.parse('$baseUri/api/chain/$chainName/step/$stepNumber'), headers: headers);
      return json.decode(response.body)['message'];
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
        body: json.encode({
          'prompt_name': promptName,
          'prompt': prompt,
        }),
      );
      return json.decode(response.body)['message'];
    } catch (e) {
      return handleError(e);
    }
  }

  Future<Map<String, dynamic>> getPrompt(String promptName, {String promptCategory = 'Default'}) async {
    try {
      final response = await http.get(Uri.parse('$baseUri/api/prompt/$promptCategory/$promptName'), headers: headers);
      return Map<String, dynamic>.from(json.decode(response.body)['prompt']);
    } catch (e) {
      return handleError(e);
    }
  }

  Future<List<String>> getPrompts({String promptCategory = 'Default'}) async {
    try {
      final response = await http.get(Uri.parse('$baseUri/api/prompt/$promptCategory'), headers: headers);
      return List<String>.from(json.decode(response.body)['prompts']);
    } catch (e) {
      return handleError(e);
    }
  }

  Future<List<String>> getPromptCategories() async {
    try {
      final response = await http.get(Uri.parse('$baseUri/api/prompt/categories'), headers: headers);
      return List<String>.from(json.decode(response.body)['prompt_categories']);
    } catch (e) {
      return handleError(e);
    }
  }

  Future<Map<String, dynamic>> getPromptArgs(String promptName, {String promptCategory = 'Default'}) async {
    try {
      final response = await http.get(Uri.parse('$baseUri/api/prompt/$promptCategory/$promptName/args'), headers: headers);
      return Map<String, dynamic>.from(json.decode(response.body)['prompt_args']);
    } catch (e) {
      return handleError(e);
    }
  }

  Future<String> deletePrompt(String promptName, {String promptCategory = 'Default'}) async {
    try {
      final response = await http.delete(Uri.parse('$baseUri/api/prompt/$promptCategory/$promptName'), headers: headers);
      return json.decode(response.body)['message'];
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
        body: json.encode({
          'prompt': prompt,
          'prompt_name': promptName,
          'prompt_category': promptCategory,
        }),
      );
      return json.decode(response.body)['message'];
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
        body: json.encode({'prompt_name': newName}),
      );
      return json.decode(response.body)['message'];
    } catch (e) {
      return handleError(e);
    }
  }

  Future<Map<String, dynamic>> getExtensionSettings() async {
    try {
      final response = await http.get(Uri.parse('$baseUri/api/extensions/settings'), headers: headers);
      return Map<String, dynamic>.from(json.decode(response.body)['extension_settings']);
    } catch (e) {
      return handleError(e);
    }
  }

  Future<dynamic> getExtensions() async {
    try {
      final response = await http.get(Uri.parse('$baseUri/api/extensions'), headers: headers);
      return json.decode(response.body)['extensions'];
    } catch (e) {
      return handleError(e);
    }
  }

  Future<Map<String, dynamic>> getCommandArgs(String commandName) async {
    try {
      final response = await http.get(Uri.parse('$baseUri/api/extensions/$commandName/args'), headers: headers);
      return Map<String, dynamic>.from(json.decode(response.body)['command_args']);
    } catch (e) {
      return handleError(e);
    }
  }

  Future<Map<String, dynamic>> getEmbeddersDetails() async {
    try {
      final response = await http.get(Uri.parse('$baseUri/api/embedders'), headers: headers);
      return Map<String, dynamic>.from(json.decode(response.body)['embedders']);
    } catch (e) {
      return handleError(e);
    }
  }

  Future<String> learnText(
    String agentName,
    String userInput,
    String text, {
    int collectionNumber = 0,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUri/api/agent/$agentName/learn/text'),
        headers: headers,
        body: json.encode({
          'user_input': userInput,
          'text': text,
          'collection_number': collectionNumber,
        }),
      );
      return json.decode(response.body)['message'];
    } catch (e) {
      return handleError(e);
    }
  }

  Future<String> learnUrl(
    String agentName,
    String url, {
    int collectionNumber = 0,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUri/api/agent/$agentName/learn/url'),
        headers: headers,
        body: json.encode({
          'url': url,
          'collection_number': collectionNumber,
        }),
      );
      return json.decode(response.body)['message'];
    } catch (e) {
      return handleError(e);
    }
  }

  Future<String> learnFile(
    String agentName,
    String fileName,
    String fileContent, {
    int collectionNumber = 0,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUri/api/agent/$agentName/learn/file'),
        headers: headers,
        body: json.encode({
          'file_name': fileName,
          'file_content': fileContent,
          'collection_number': collectionNumber,
        }),
      );
      return json.decode(response.body)['message'];
    } catch (e) {
      return handleError(e);
    }
  }

  Future<String> learnGithubRepo(
    String agentName,
    String githubRepo, {
    String githubUser,
    String githubToken,
    String githubBranch = 'main',
    bool useAgentSettings = false,
    int collectionNumber = 0,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUri/api/agent/$agentName/learn/github'),
        headers: headers,
        body: json.encode({
          'github_repo': githubRepo,
          'github_user': githubUser,
          'github_token': githubToken,
          'github_branch': githubBranch,
          'collection_number': collectionNumber,
          'use_agent_settings': useAgentSettings,
        }),
      );
      return json.decode(response.body)['message'];
    } catch (e) {
      return handleError(e);
    }
  }

  Future<String> learnArxiv(
    String agentName, {
    String query,
    String arxivIds,
    int maxResults = 5,
    int collectionNumber = 0,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUri/api/agent/$agentName/learn/arxiv'),
        headers: headers,
        body: json.encode({
          'query': query,
          'arxiv_ids': arxivIds,
          'max_results': maxResults,
          'collection_number': collectionNumber,
        }),
      );
      return json.decode(response.body)['message'];
    } catch (e) {
      return handleError(e);
    }
  }

  Future<String> agentReader(
    String agentName,
    String readerName,
    Map<String, dynamic> data, {
    int collectionNumber = 0,
  }) async {
    if (!data.containsKey('collection_number')) {
      data['collection_number'] = collectionNumber;
    }
    try {
      final response = await http.post(
        Uri.parse('$baseUri/api/agent/$agentName/reader/$readerName'),
        headers: headers,
        body: json.encode(data),
      );
      return json.decode(response.body)['message'];
    } catch (e) {
      return handleError(e);
    }
  }

  Future<String> wipeAgentMemories(String agentName, {int collectionNumber = 0}) async {
    try {
      final response = await http.delete(
        Uri.parse(collectionNumber == 0
            ? '$baseUri/api/agent/$agentName/memory'
            : '$baseUri/api/agent/$agentName/memory/$collectionNumber'),
        headers: headers,
      );
      return json.decode(response.body)['message'];
    } catch (e) {
      return handleError(e);
    }
  }

  Future<String> deleteAgentMemory(
    String agentName,
    String memoryId, {
    int collectionNumber = 0,
  }) async {
    try {
      final response = await http.delete(
        Uri.parse('$baseUri/api/agent/$agentName/memory/$collectionNumber/$memoryId'),
        headers: headers,
      );
      return json.decode(response.body)['message'];
    } catch (e) {
      return handleError(e);
    }
  }

  Future<List<Map<String, dynamic>>> getAgentMemories(
    String agentName,
    String userInput, {
    int limit = 5,
    double minRelevanceScore = 0.0,
    int collectionNumber = 0,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUri/api/agent/$agentName/memory/$collectionNumber/query'),
        headers: headers,
        body: json.encode({
          'user_input': userInput,
          'limit': limit,
          'min_relevance_score': minRelevanceScore,
        }),
      );
      return List<Map<String, dynamic>>.from(json.decode(response.body)['memories']);
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
      return List<Map<String, dynamic>>.from(json.decode(response.body)['memories']);
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
        Uri.parse('$baseUri/api/agent/$agentName/memory/import'),
        headers: headers,
        body: json.encode({'memories': memories}),
      );
      return json.decode(response.body)['message'];
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
        body: json.encode({'dataset_name': datasetName, 'batch_size': batchSize}),
      );
      return json.decode(response.body)['message'];
    } catch (e) {
      return handleError(e);
    }
  }

  Future<String> train(
    String agentName,
    String datasetName, {
    String model = 'unsloth/mistral-7b-v0.2',
    int maxSeqLength = 16384,
    String huggingfaceOutputPath = 'JoshXT/finetuned-mistral-7b-v0.2',
    bool privateRepo = true,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUri/api/agent/$agentName/memory/dataset/$datasetName/finetune'),
        headers: headers,
        body: json.encode({
          'model': model,
          'max_seq_length': maxSeqLength,
          'huggingface_output_path': huggingfaceOutputPath,
          'private_repo': privateRepo,
        }),
      );
      return json.decode(response.body)['message'];
    } catch (e) {
      return handleError(e);
    }
  }

  Future<String> textToSpeech(String agentName, String text, String conversationName) async {
    final response = await executeCommand(
      agentName: agentName,
      commandName: 'Text to Speech',
      commandArgs: {'text': text},
      conversationName: conversationName,
    );
    return response;
  }
}
