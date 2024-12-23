class Booking {
  final String name;
  final String email;
  final String phone;
  final int attendance;
  final String message;
  final String eventName;
  final DateTime eventStartTime;
  final DateTime eventEndTime;
  final String selectedRoom;

  Booking({
    required this.name,
    required this.email,
    required this.phone,
    required this.attendance,
    required this.message,
    required this.eventName,
    required this.eventStartTime,
    required this.eventEndTime,
    required this.selectedRoom,
  });
}
