String snakeCase(String oldStr) {
  if (oldStr.isEmpty) {
    return "";
  }

  oldStr = oldStr
    .replaceAll(" ", "")
    .replaceAll("@", "_")
    .replaceAll(".", "_")
    .replaceAll("-", "_")
    .replaceAll("&", "and")
    .replaceAll(":", "_");

  final snakeStr = StringBuffer();
  for (var i = 0; i < oldStr.length; i++) {
    final char = oldStr[i];
    if (char.toUpperCase() == char) {
      if (i != 0 && oldStr[i - 1].toLowerCase() == oldStr[i - 1]) {
        snakeStr.write("_");
      }
      if (i != oldStr.length - 1 && oldStr[i + 1].toLowerCase() == oldStr[i + 1]) {
        snakeStr.write("_");  
      }
    }
    snakeStr.write(char.toLowerCase());
  }

  return snakeStr.toString().trim().replaceAll(RegExp(r'^_+|_+$'), '');
}