import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:room_booker/widgets/new_booking_form.dart';

@RoutePage()
class NewBookingScreen extends StatelessWidget {
  final DateTime? startTime;

  const NewBookingScreen({super.key, this.startTime});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('New Booking Request'),
      ),
      body: Center(
        child: SingleChildScrollView(
            child: NewBookingForm(
          startTime: startTime,
        )),
      ),
    );
  }
}
