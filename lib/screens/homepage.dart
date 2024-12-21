import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:room_booker/router.dart';

@RoutePage()
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Home"),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            ElevatedButton(
              onPressed: () =>
                  AutoRouter.of(context).push(const NewBookingRoute()),
              child: const Text('New Booking'),
            ),
            const SizedBox(height: 20),
            const ElevatedButton(
              onPressed: null,
              child: Text('Button 2'),
            ),
          ],
        ),
      ),
    );
  }
}
