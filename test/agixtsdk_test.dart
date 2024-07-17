import 'package:flutter_test/flutter_test.dart';
import 'package:agixtsdk/agixtsdk.dart';

void main() {
  group('AGiXTSDK', () {
    late AGiXTSDK sdk;

    setUp(() {
      sdk = AGiXTSDK(
        baseUri: 'http://localhost:7437',
        apiKey: 'test_api_key',
      );
    });

    test('getProviders', () async {
      final providers = await sdk.getProviders();
      expect(providers, isA<List<String>>());
    });

    test('getProvidersByService', () async {
      final providers = await sdk.getProvidersByService('llm');
      expect(providers, isA<List<String>>());
    });

    test('getProviderSettings', () async {
      final settings = await sdk.getProviderSettings('openai');
      expect(settings, isA<Map<String, dynamic>>());
    });

    test('addAgent', () async {
      final result = await sdk.addAgent('test_agent');
      expect(result, isA<Map<String, dynamic>>());
    });

    test('getAgents', () async {
      final agents = await sdk.getAgents();
      expect(agents, isA<List<Map<String, dynamic>>>());
    });

    test('getConversations', () async {
      final conversations = await sdk.getConversations();
      expect(conversations, isA<List<String>>());
    });

    test('newConversation', () async {
      final result = await sdk.newConversation('test_agent', 'test_conversation');
      expect(result, isA<List<Map<String, dynamic>>>());
    });

    test('promptAgent', () async {
      final response = await sdk.promptAgent(
        agentName: 'test_agent',
        promptName: 'instruct',
        promptArgs: {'user_input': 'Hello, how are you?'},
      );
      expect(response, isA<String>());
    });

    test('getChains', () async {
      final chains = await sdk.getChains();
      expect(chains, isA<List<String>>());
    });

    test('runChain', () async {
      final response = await sdk.runChain(
        chainName: 'Smart Instruct',
        userInput: 'Hello, how are you?',
        agentName: 'test_agent',
      );
      expect(response, isA<dynamic>());
    });

    test('learnText', () async {
      final result = await sdk.learnText('test_agent', 'Test input', 'Test text');
      expect(result, isA<String>());
    });

    test('learnUrl', () async {
      final result = await sdk.learnUrl('test_agent', 'https://example.com');
      expect(result, isA<String>());
    });

    test('getAgentMemories', () async {
      final memories = await sdk.getAgentMemories('test_agent', 'Test query');
      expect(memories, isA<List<Map<String, dynamic>>>());
    });

    test('exportAgentMemories', () async {
      final memories = await sdk.exportAgentMemories('test_agent');
      expect(memories, isA<List<Map<String, dynamic>>>());
    });

    test('createDataset', () async {
      final result = await sdk.createDataset('test_agent', 'test_dataset');
      expect(result, isA<String>());
    });

    test('getBrowsedLinks', () async {
      final links = await sdk.getBrowsedLinks('test_agent');
      expect(links, isA<List<String>>());
    });

    test('textToSpeech', () async {
      final url = await sdk.textToSpeech('test_agent', 'Hello, world!');
      expect(url, isA<String>());
    });

    test('planTask', () async {
      final response = await sdk.planTask('test_agent', 'Plan a birthday party');
      expect(response, isA<String>());
    });
  });
}