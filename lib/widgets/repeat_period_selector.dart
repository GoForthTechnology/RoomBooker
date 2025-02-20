import 'package:flutter/material.dart';
import 'package:room_booker/entities/request.dart';

class RepeatPeriodSelector extends StatefulWidget {
  final Frequency frequency;
  final Function(Frequency) onFrequencyChanged;
  final Function(int) onIntervalChanged;

  const RepeatPeriodSelector(
      {super.key,
      required this.frequency,
      required this.onFrequencyChanged,
      required this.onIntervalChanged});

  @override
  RepeatPeriodSelectorState createState() => RepeatPeriodSelectorState();
}

class RepeatPeriodSelectorState extends State<RepeatPeriodSelector> {
  final _controller = TextEditingController(text: "1");

  @override
  Widget build(BuildContext context) {
    var currentValue = int.parse(_controller.text);
    return InputDecorator(
      decoration: const InputDecoration(labelText: "Repeat every"),
      child: Row(
        children: [
          Expanded(
              child: TextFormField(
            decoration: const InputDecoration(
              border: OutlineInputBorder(),
            ),
            keyboardType: TextInputType.number,
            controller: _controller,
          )),
          IconButton(
              onPressed: (currentValue == 1)
                  ? null
                  : () {
                      setState(() {
                        var newValue = int.parse(_controller.text) - 1;
                        widget.onIntervalChanged(newValue);
                        _controller.text = (newValue).toString();
                      });
                    },
              icon: const Icon(Icons.remove)),
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () {
              setState(() {
                var newValue = int.parse(_controller.text) + 1;
                widget.onIntervalChanged(newValue);
                _controller.text = (newValue).toString();
              });
            },
          ),
          const Spacer(),
          Expanded(
              child: DropdownButton<Frequency>(
            items: const [
              DropdownMenuItem(value: Frequency.daily, child: Text("Days")),
              DropdownMenuItem(value: Frequency.weekly, child: Text("Weeks")),
              DropdownMenuItem(value: Frequency.monthly, child: Text("Months")),
              DropdownMenuItem(value: Frequency.annually, child: Text("Years")),
            ],
            onChanged: (value) {
              widget.onFrequencyChanged(value!);
            },
            value: widget.frequency,
          )),
        ],
      ),
    );
  }
}
