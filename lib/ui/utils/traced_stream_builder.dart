import 'package:flutter/widgets.dart';
import 'package:room_booker/data/logging_service.dart';

class TracedStreamBuilder<T> extends StreamBuilder<T> {
  final String spanName;
  final LoggingService loggingService;

  TracedStreamBuilder(
    this.spanName,
    this.loggingService, {
    super.key,
    required Stream<T> stream,
    required Widget Function(BuildContext, AsyncSnapshot<T>) builder,
  }) : super(
         stream: stream,
         builder: (context, snapshot) =>
             loggingService.trace(spanName, () => builder(context, snapshot)),
       );
}
