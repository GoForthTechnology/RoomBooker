import 'package:flutter/material.dart';

class Heading extends StatelessWidget {
  final String text;

  const Heading(this.text, {super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Text(
          text,
          style: Theme.of(context).textTheme.headlineMedium,
        ));
  }
}

class Subheading extends StatelessWidget {
  final String text;

  const Subheading(this.text, {super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Text(
          text,
          style: Theme.of(context).textTheme.headlineSmall,
        ));
  }
}
