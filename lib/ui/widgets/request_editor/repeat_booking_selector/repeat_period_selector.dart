import 'package:flutter/material.dart';
import 'package:room_booker/data/entities/request.dart';

class RepeatPeriodSelector extends StatefulWidget {
  final Frequency frequency;
  final int interval;
  final Function(Frequency) onFrequencyChanged;
  final Function(int) onIntervalChanged;
  final bool readOnly;

  const RepeatPeriodSelector({
    super.key,
    required this.frequency,
    required this.interval,
    required this.onFrequencyChanged,
    required this.onIntervalChanged,
    this.readOnly = false,
  });

  @override
  RepeatPeriodSelectorState createState() => RepeatPeriodSelectorState();
}

class RepeatPeriodSelectorState extends State<RepeatPeriodSelector> {
  late TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.interval.toString());
  }

  @override
  void didUpdateWidget(RepeatPeriodSelector oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.interval != oldWidget.interval) {
      if (int.tryParse(_controller.text) != widget.interval) {
        _controller.text = widget.interval.toString();
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return InputDecorator(
      decoration: const InputDecoration(labelText: "Repeat every"),
      child: Row(
        children: [
          Expanded(
            child: TextFormField(
              readOnly: widget.readOnly,
              enabled: !widget.readOnly,
              decoration: const InputDecoration(border: OutlineInputBorder()),
              keyboardType: TextInputType.number,
              controller: _controller,
              onChanged: (value) {
                var newValue = int.tryParse(value);
                if (newValue != null) {
                  widget.onIntervalChanged(newValue);
                }
              },
            ),
          ),
          IconButton(
            onPressed: (widget.readOnly || widget.interval <= 1)
                ? null
                : () {
                    widget.onIntervalChanged(widget.interval - 1);
                  },
            icon: const Icon(Icons.remove),
          ),
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: widget.readOnly
                ? null
                : () {
                    widget.onIntervalChanged(widget.interval + 1);
                  },
          ),
          const Spacer(),
          Expanded(
            child: DropdownButton<Frequency>(
              items: const [
                DropdownMenuItem(value: Frequency.daily, child: Text("Days")),
                DropdownMenuItem(value: Frequency.weekly, child: Text("Weeks")),
                DropdownMenuItem(
                  value: Frequency.monthly,
                  child: Text("Months"),
                ),
                DropdownMenuItem(
                  value: Frequency.annually,
                  child: Text("Years"),
                ),
              ],
              onChanged: widget.readOnly
                  ? null
                  : (value) {
                      widget.onFrequencyChanged(value!);
                    },
              value: widget.frequency,
            ),
          ),
        ],
      ),
    );
  }
}
