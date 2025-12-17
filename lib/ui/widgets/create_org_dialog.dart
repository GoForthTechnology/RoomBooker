import 'package:flutter/material.dart';

class CreateOrgDialog extends StatefulWidget {
  const CreateOrgDialog({super.key});

  @override
  State<CreateOrgDialog> createState() => _CreateOrgDialogState();
}

class _CreateOrgDialogState extends State<CreateOrgDialog> {
  int _currentStep = 0;
  final TextEditingController _orgNameController = TextEditingController();
  final TextEditingController _roomNameController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    _orgNameController.dispose();
    _roomNameController.dispose();
    super.dispose();
  }

  void _onStepContinue() {
    if (_formKey.currentState!.validate()) {
      if (_currentStep == 0) {
        setState(() {
          _currentStep++;
        });
      } else {
        Navigator.of(context).pop({
          'orgName': _orgNameController.text,
          'roomName': _roomNameController.text,
        });
      }
    }
  }

  void _onStepCancel() {
    if (_currentStep > 0) {
      setState(() {
        _currentStep--;
      });
    } else {
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Create New Organization'),
      content: SizedBox(
        width: 400,
        height: 300,
        child: Form(
          key: _formKey,
          child: Stepper(
            currentStep: _currentStep,
            onStepContinue: _onStepContinue,
            onStepCancel: _onStepCancel,
            controlsBuilder: (context, details) {
              return Padding(
                padding: const EdgeInsets.only(top: 16.0),
                child: Row(
                  children: <Widget>[
                    TextButton(
                      onPressed: details.onStepContinue,
                      child: Text(_currentStep == 0 ? 'Continue' : 'Create'),
                    ),
                    TextButton(
                      onPressed: details.onStepCancel,
                      child: const Text('Cancel'),
                    ),
                  ],
                ),
              );
            },
            steps: [
              Step(
                title: const Text('Organization Name'),
                content: TextFormField(
                  controller: _orgNameController,
                  autofocus: true,
                  decoration: const InputDecoration(
                    labelText: 'Organization Name',
                    hintText: 'Enter your organization name',
                  ),
                  validator: (value) {
                    if (_currentStep == 0) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter a name';
                      }
                    }
                    return null;
                  },
                ),
                isActive: _currentStep >= 0,
                state: _currentStep > 0
                    ? StepState.complete
                    : StepState.indexed,
              ),
              Step(
                title: const Text('First Room Name'),
                content: TextFormField(
                  controller: _roomNameController,
                  decoration: const InputDecoration(
                    labelText: 'First Room Name',
                    hintText: 'e.g. Conference Room A',
                  ),
                  validator: (value) {
                    if (_currentStep == 1) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter a room name';
                      }
                    }
                    return null;
                  },
                ),
                isActive: _currentStep >= 1,
                state: _currentStep > 1
                    ? StepState.complete
                    : StepState.indexed,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
