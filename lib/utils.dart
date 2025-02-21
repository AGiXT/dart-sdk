String snakeCase(String str) {
  if (str.isEmpty) {
    return "";
  }

  // Handle spaces, special characters
  if (str.contains(" ")) {
    str = str.replaceAll(" ", "");
  }
  if (str.contains("@")) {
    str = str.replaceAll("@", "_");
  }
  if (str.contains(".")) {
    str = str.replaceAll(".", "_");
  }
  if (str.contains("-")) {
    str = str.replaceAll("-", "_");
  }
  if (str.contains("&")) {
    str = str.replaceAll("&", "and");
  }
  if (str.contains(":")) {
    str = str.replaceAll(":", "_");
  }

  final StringBuffer result = StringBuffer();
  
  for (int i = 0; i < str.length; i++) {
    final char = str[i];
    
    if (char.toUpperCase() == char) {
      if (i > 0 && str[i - 1].toLowerCase() == str[i - 1]) {
        result.write('_');
      }
      if (i < str.length - 1 && str[i + 1].toLowerCase() == str[i + 1]) {
        result.write('_');
      }
    }
    
    result.write(char.toLowerCase());
  }

  String snakeStr = result.toString();
  while (snakeStr.startsWith('_')) {
    snakeStr = snakeStr.substring(1);
  }
  while (snakeStr.endsWith('_')) {
    snakeStr = snakeStr.substring(0, snakeStr.length - 1);
  }
  
  return snakeStr;
}

int getTokens(String text) {
  // A simple implementation that approximates token count
  // You may want to use a more sophisticated tokenizer in production
  return text.split(RegExp(r'\s+')).length;
}