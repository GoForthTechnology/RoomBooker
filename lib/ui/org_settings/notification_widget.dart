import 'package:flutter/material.dart';
import 'package:room_booker/data/entities/organization.dart';
import 'package:room_booker/data/repos/org_repo.dart';
import 'package:room_booker/ui/core/heading.dart';
import 'package:room_booker/ui/core/simple_text_form_field.dart';

class NotificationWidget extends StatefulWidget {
  final Organization org;
  final OrgRepo repo;

  const NotificationWidget({super.key, required this.org, required this.repo});

  @override
  NotificationWidgetState createState() => NotificationWidgetState();
}

class NotificationWidgetState extends State<NotificationWidget> {
  bool dirty = false;
  final _formKey = GlobalKey<FormState>();
  final controllers = <NotificationEvent, TextEditingController>{};

  @override
  void initState() {
    super.initState();
    var targets = widget.org.notificationSettings?.notificationTargets ?? {};
    for (var event in NotificationEvent.values) {
      var controller = TextEditingController(text: targets[event]);
      controller.addListener(() {
        setState(() {
          dirty = true;
        });
      });
      controllers[event] = controller;
    }
  }

  @override
  void dispose() {
    for (var controller in controllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
        constraints: BoxConstraints.tightFor(width: 400),
        child: Form(
            key: _formKey,
            child: Column(
              children: [
                const Heading("Notifications"),
                const Text(
                    "Please provide the email addresses for notifications"),
                ...NotificationEvent.values.map((e) => SimpleTextFormField(
                      controller: controllers[e]!,
                      readOnly: false,
                      labelText: e.name,
                      clearable: true,
                      validationRegex: RegExp(
                          r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}\$'),
                      validationMessage: "Please provide a valid email address",
                    )),
                ElevatedButton(
                  onPressed: !dirty
                      ? null
                      : () async {
                          if (_formKey.currentState!.validate()) {
                            widget.repo.updateNotificationSettings(
                                widget.org.id!,
                                NotificationSettings(
                                    notificationTargets: controllers.map(
                                        (key, value) =>
                                            MapEntry(key, value.text))));
                          }
                        },
                  child: Text('Save'),
                ),
              ],
            )));
  }
}
