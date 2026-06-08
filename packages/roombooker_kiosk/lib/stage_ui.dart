import 'package:flutter/material.dart';

class MeetingStageWidget extends StatefulWidget {
  const MeetingStageWidget({super.key});

  @override
  State<MeetingStageWidget> createState() => _MeetingStageWidgetState();
}

class _MeetingStageWidgetState extends State<MeetingStageWidget> {
  String _roomName = 'LOADING...';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              _roomName,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 64,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 24),
            StreamBuilder(
              stream: Stream.periodic(const Duration(seconds: 1)),
              builder: (context, snapshot) {
                return Text(
                  TimeOfDay.now().format(context),
                  style: const TextStyle(
                    color: Colors.grey,
                    fontSize: 48,
                  ),
                );
              },
            ),
            const SizedBox(height: 48),
            const Text(
              'AVAILABLE',
              style: TextStyle(
                color: Colors.green,
                fontSize: 32,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
