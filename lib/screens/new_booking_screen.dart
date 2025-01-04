import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:room_booker/repos/request_repo.dart';
import 'package:room_booker/widgets/new_booking_form.dart';

@RoutePage()
class NewBookingScreen extends StatelessWidget {
  final DateTime? startTime;
  final String? roomID;

  const NewBookingScreen({super.key, this.startTime, this.roomID});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('New Booking Request'),
      ),
      body: Consumer<RequestRepo>(
        builder: (context, repo, child) => FutureBuilder(
          future: repo.rooms.first,
          builder: (context, snapshot) {
            if (!snapshot.hasData) {
              return const CircularProgressIndicator();
            }
            return SingleChildScrollView(
                child: NewBookingForm(
              roomID: roomID ?? snapshot.data!.first,
              startTime: startTime,
            ));
          },
        ),
      ),
    );
  }
}
