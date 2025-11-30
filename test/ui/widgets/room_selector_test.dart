import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:room_booker/data/entities/organization.dart';
import 'package:room_booker/ui/widgets/room_selector.dart';

void main() {
  group('RoomState', () {
    late List<Room> rooms;
    late RoomState roomState;

    setUp(() {
      rooms = [
        Room(id: '1', name: 'Room 1', colorHex: '#FF0000'),
        Room(id: '2', name: 'Room 2', colorHex: '#00FF00'),
        Room(id: '3', name: 'Room 3', colorHex: '#0000FF'),
      ];
      roomState = RoomState(rooms, {rooms[0]}, null);
    });

    test('initial state is correct', () {
      expect(roomState.isEnabled('1'), true);
      expect(roomState.isEnabled('2'), false);
      expect(roomState.enabledValue(), rooms[0]);
      expect(roomState.enabledValues(), {rooms[0]});
    });

    test('toggleRoom toggles selection', () {
      roomState.toggleRoom(rooms[1]);
      expect(roomState.isEnabled('2'), true);
      expect(roomState.enabledValues().length, 2);

      roomState.toggleRoom(rooms[1]);
      expect(roomState.isEnabled('2'), false);
    });

    test('toggleRoom prevents deselecting the last room', () {
      roomState.toggleRoom(rooms[0]); // Try to deselect the only active room
      expect(roomState.isEnabled('1'), true);
      expect(roomState.enabledValues().length, 1);
    });

    test('toggleSoloRoom activates only the selected room', () {
      // Activate multiple rooms
      roomState.toggleRoom(rooms[1]);
      expect(roomState.enabledValues().length, 2);

      // Solo room 2
      roomState.toggleSoloRoom(rooms[1]);
      expect(roomState.isEnabled('1'), false);
      expect(roomState.isEnabled('2'), true);
      expect(roomState.isEnabled('3'), false);
      expect(roomState.enabledValues().length, 1);
    });

    test('toggleSoloRoom on single active room activates all', () {
      // Only room 1 is active
      roomState.toggleSoloRoom(rooms[0]);
      
      expect(roomState.isEnabled('1'), true);
      expect(roomState.isEnabled('2'), true);
      expect(roomState.isEnabled('3'), true);
      expect(roomState.enabledValues().length, 3);
    });
    
    test('color returns correct color', () {
       expect(roomState.color('1'), const Color(0xFFFF0000));
    });

    test('color throws on invalid ID', () {
      expect(() => roomState.color('invalid'), throwsArgumentError);
    });
    
    test('enabledValue returns null if empty', () {
       final emptyState = RoomState(rooms, {}, null);
       expect(emptyState.enabledValue(), isNull);
    });
  });
}
