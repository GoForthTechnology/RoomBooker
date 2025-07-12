import 'package:flutter_test/flutter_test.dart';
import 'package:room_booker/ui/core/room_colors.dart';

void main() {
  group('RoomColors', () {
    test('to and from hex', () {
      for (var color in colors) {
        var hex = toHex(color, leadingHashSign: false);
        var parsedColor = fromHex(hex);
        expect(parsedColor, color,
            reason: 'Color $hex should match parsed color');
      }
    });
  });
}
