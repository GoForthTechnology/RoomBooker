import 'dart:ui';

const List<Color> colors = [
  Color.fromRGBO(131, 45, 164, 1),
  Color.fromRGBO(123, 134, 198, 1),
  Color.fromRGBO(67, 80, 175, 1),
  Color.fromRGBO(69, 153, 223, 1),
  Color.fromRGBO(57, 126, 73, 1),
  Color.fromRGBO(93, 179, 126, 1),
  Color.fromRGBO(237, 193, 75, 1),
  Color.fromRGBO(226, 93, 51, 1),
  Color.fromRGBO(216, 129, 119, 1),
  Color.fromRGBO(195, 41, 28, 1),
  Color.fromRGBO(97, 97, 97, 1),
];

Color? fromHex(String? hexColor) {
  if (hexColor == null || hexColor.isEmpty) {
    return null;
  }
  final buffer = StringBuffer();
  if (hexColor.length == 6 || hexColor.length == 7) {
    buffer.write('ff'); // Default alpha value
  }
  buffer.write(hexColor.replaceFirst('#', ''));
  return Color(int.parse(buffer.toString(), radix: 16));
}

String? toHex(Color? color, {bool leadingHashSign = true}) {
  if (color == null) {
    return null;
  }
  final hex = color.toARGB32().toRadixString(16).padLeft(8, '0');
  return (leadingHashSign ? '#' : '') + hex.substring(2);
}
