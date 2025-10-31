import 'package:flutter/material.dart';
import 'package:room_booker/data/entities/organization.dart';

class JoinOrgView extends StatelessWidget {
  final AsyncSnapshot<Organization?> snapshot;
  final VoidCallback onJoin;

  const JoinOrgView({
    super.key,
    required this.snapshot,
    required this.onJoin,
  });

  @override
  Widget build(BuildContext context) {
    if (snapshot.hasError) {
      return const Center(child: Text('Error loading organization'));
    }

    if (!snapshot.hasData) {
      return const Center(child: CircularProgressIndicator());
    }

    final org = snapshot.data;
    if (org == null) {
      // This case can be handled more gracefully, maybe with a specific message.
      return const Center(child: Text('Organization not found.'));
    }

    if (!org.acceptingAdminRequests) {
      return const Center(
        child: Text('This organization is not accepting new members'),
      );
    }

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text('Join ${org.name}?'),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: onJoin,
            child: const Text('Join'),
          ),
        ],
      ),
    );
  }
}
