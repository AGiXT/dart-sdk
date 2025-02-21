import 'dart:convert';

/// A simple implementation of tokenization similar to tiktoken, but using UTF-8 bytes as a base.
/// This is a simplified version and won't match tiktoken exactly, but provides a reasonable approximation.
/// For production use, you should implement or use a proper tiktoken port.
int getTokens(String text) {
  if (text.isEmpty) return 0;
  
  // Convert string to UTF-8 bytes
  List<int> bytes = utf8.encode(text);
  
  // Basic tokenization: roughly 100 tokens per 75 bytes
  // This is a very rough approximation and should be replaced with proper tiktoken for production
  return (bytes.length * 100 / 75).ceil();
}