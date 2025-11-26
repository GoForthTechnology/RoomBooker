import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:room_booker/ui/widgets/date_field.dart';
import 'package:room_booker/ui/widgets/org_state_provider.dart';
import 'package:room_booker/ui/widgets/request_editor/request_editor_view_model.dart';
import 'package:room_booker/ui/widgets/room_dropdown_selector.dart';
import 'package:room_booker/ui/widgets/room_selector.dart';
import 'package:room_booker/ui/widgets/simple_text_form_field.dart';
import 'package:room_booker/ui/widgets/time_field.dart';

import 'logs_widget.dart';

class RequestEditor extends StatelessWidget {
  const RequestEditor({super.key});

  @override
  Widget build(BuildContext context) {
    var orgState = Provider.of<OrgState>(context, listen: false);
    var localizations = MaterialLocalizations.of(context);
    return Consumer2<RoomState, RequestEditorViewModel>(
      builder: (context, roomState, viewModel, child) {
        var formContents = Column(
          children: [
            _title(viewModel, context),
            _roomSelector(viewModel),
            _eventNameSelector(viewModel),
            _isPublicSelector(viewModel),
            if (viewModel.showIgnoreOverlapsToggle())
              _ignoreOverlapsSelector(viewModel)!,
            _eventDateSelector(viewModel),
            _eventStartTimeSelector(viewModel, localizations),
            _eventEndTimeSelector(viewModel, localizations),
            /*RepeatBookingsSelector(
              readOnly: readOnly,
              startTime: state.startTime!,
              isCustom: state.isCustomRecurrencePattern,
              onIntervalChanged: state.updateInterval,
              pattern: state.recurrancePattern,
              onFrequencyChanged: (value) {
                if (value == Frequency.custom) {
                  state.updateFrequency(Frequency.weekly, true);
                } else {
                  state.updateFrequency(value, state.isCustomRecurrencePattern);
                }
              },
              onPatternChanged: (pattern, isCustom) {
                state.updateOffset(pattern.offset);
                state.updateInterval(pattern.period);
                state.updateFrequency(pattern.frequency, isCustom);
              },
              toggleDay: state.toggleWeekday,
              frequency: state.recurrancePattern.frequency,
            ),*/
            /*if (state.recurrancePattern.frequency != Frequency.never)
              DateField(
                initialValue: state.recurrancePattern.end,
                labelText: "End on or before",
                onChanged: (date) => state.updateEndDate(date),
                readOnly: readOnly,
                clearable: true,
              ),*/
            const Divider(),
            _contactNameSelector(viewModel),
            _contactEmailSelector(viewModel),
            _contactPhoneSelector(viewModel),
            if (orgState.currentUserIsAdmin())
              _adminContactInfoButton(viewModel, orgState)!,
            const Divider(),
            _additionalInfoSelector(viewModel),
            if (viewModel.showID()) _requestIDField(viewModel)!,
            if (viewModel.showEventLog()) _requestLogWidget(viewModel)!,
            _getButtons(viewModel, context),
          ],
        );
        return SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(4),
            child: Form(key: viewModel.formKey, child: formContents),
          ),
        );
      },
    );
  }

  Widget _title(RequestEditorViewModel viewModel, BuildContext context) {
    return AppBar(
      title: Text(viewModel.editorTitle),
      actions: [
        IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => viewModel.closeEditor(),
        ),
      ],
      automaticallyImplyLeading: false,
    );
  }

  Widget _roomSelector(RequestEditorViewModel viewModel) {
    return RoomDropdownSelector(
      readOnly: viewModel.readOnly,
      orgID: viewModel.orgID,
      onChanged: (room) {
        if (room != null) {
          viewModel.updateRoom(room);
        }
      },
      initialRoomID: viewModel.initialRequest.roomID,
    );
  }

  Widget _eventNameSelector(RequestEditorViewModel viewModel) {
    return SimpleTextFormField(
      readOnly: viewModel.readOnly,
      controller: viewModel.eventNameContoller,
      labelText: "Event Name",
      validationMessage: "Please provide a name",
      onChanged: viewModel.updateEventName,
    );
  }

  Widget _isPublicSelector(RequestEditorViewModel viewModel) {
    return StreamBuilder(
      stream: viewModel.isPublicStream,
      builder: (context, snapshot) {
        var isPublic = snapshot.data ?? false;
        return SwitchListTile(
          title: Text("Show name on parish calendar"),
          value: isPublic,
          onChanged: viewModel.readOnly ? null : viewModel.updateIsPublic,
        );
      },
    );
  }

  Widget? _ignoreOverlapsSelector(RequestEditorViewModel viewModel) {
    if (!viewModel.showIgnoreOverlapsToggle()) {
      return null;
    }
    return StreamBuilder(
      stream: viewModel.ignoreOverlapsStream,
      builder: (context, snapshot) {
        var isIgnoreOverlaps = snapshot.data ?? false;
        return SwitchListTile(
          title: Text("Ignore overlapping events"),
          value: isIgnoreOverlaps,
          onChanged: viewModel.readOnly ? null : viewModel.updateIgnoreOverlaps,
        );
      },
    );
  }

  Widget _eventDateSelector(RequestEditorViewModel viewModel) {
    return StreamBuilder(
      stream: viewModel.eventStartStream,
      builder: (context, snapshot) {
        var startTime = snapshot.data;
        return DateField(
          initialValue: startTime,
          readOnly: viewModel.readOnly,
          labelText: 'Event Date',
          validationMessage: 'Please select a date',
          onChanged: (newDate) {
            viewModel.updateEventStart(
              DateTime(
                newDate.year,
                newDate.month,
                newDate.day,
                startTime!.hour,
                startTime.minute,
              ),
            );
          },
        );
      },
    );
  }

  Widget _eventStartTimeSelector(
    RequestEditorViewModel viewModel,
    MaterialLocalizations localizations,
  ) {
    return StreamBuilder<(DateTime, DateTime)>(
      stream: viewModel.eventTimeStream,
      builder: (context, snapshot) {
        var (startTime, endTime) = snapshot.data ?? (null, null);
        if (startTime == null || endTime == null) {
          return const SizedBox.shrink();
        }
        return TimeField(
          readOnly: viewModel.readOnly,
          labelText: 'Start Time',
          initialValue: TimeOfDay.fromDateTime(startTime),
          localizations: localizations,
          maxTime: TimeOfDay.fromDateTime(endTime),
          onChanged: (newTime) {
            var eventDuration = endTime.difference(startTime);
            var newStartTime = DateTime(
              startTime.year,
              startTime.month,
              startTime.day,
              newTime.hour,
              newTime.minute,
            );
            var newEndTime = newStartTime.add(eventDuration);
            viewModel.updateEventStart(newStartTime);
            viewModel.updateEventEnd(newEndTime);
          },
        );
      },
    );
  }

  Widget _eventEndTimeSelector(
    RequestEditorViewModel viewModel,
    MaterialLocalizations localizations,
  ) {
    return StreamBuilder<(DateTime, DateTime)>(
      stream: viewModel.eventTimeStream,
      builder: (context, snapshot) {
        var (startTime, endTime) = snapshot.data ?? (null, null);
        if (startTime == null || endTime == null) {
          return const SizedBox.shrink();
        }
        return TimeField(
          readOnly: viewModel.readOnly,
          labelText: 'End Time',
          initialValue: TimeOfDay.fromDateTime(endTime),
          localizations: localizations,
          minTime: TimeOfDay.fromDateTime(startTime),
          onChanged: (newTime) {
            var newEndTime = DateTime(
              startTime.year,
              startTime.month,
              startTime.day,
              newTime.hour,
              newTime.minute,
            );
            viewModel.updateEventEnd(newEndTime);
          },
        );
      },
    );
  }

  Widget _contactNameSelector(RequestEditorViewModel viewModel) {
    return SimpleTextFormField(
      readOnly: viewModel.readOnly,
      controller: viewModel.contactNameController,
      labelText: "Your Name",
      validationMessage: "Please provide your name",
      onChanged: viewModel.updateContactName,
    );
  }

  Widget _contactEmailSelector(RequestEditorViewModel viewModel) {
    return SimpleTextFormField(
      readOnly: viewModel.readOnly,
      controller: viewModel.contactEmailController,
      labelText: "Your Email",
      validationMessage: "Please provide your email",
      validationRegex: RegExp(
        r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
      ),
      onChanged: viewModel.updateContactEmail,
    );
  }

  Widget _contactPhoneSelector(RequestEditorViewModel viewModel) {
    return SimpleTextFormField(
      readOnly: viewModel.readOnly,
      controller: viewModel.phoneNumberController,
      labelText: "Your Phone Number",
      validationMessage: "Please provide your phone number",
      onChanged: viewModel.updateContactPhone,
    );
  }

  Widget? _adminContactInfoButton(
    RequestEditorViewModel viewModel,
    OrgState orgState,
  ) {
    if (!orgState.currentUserIsAdmin()) {
      return null;
    }
    return ElevatedButton(
      onPressed: () {
        viewModel.useAdminContactInfo();
      },
      child: Text("Use My Info"),
    );
  }

  Widget _additionalInfoSelector(RequestEditorViewModel viewModel) {
    return SimpleTextFormField(
      readOnly: viewModel.readOnly,
      controller: viewModel.additionalInfoController,
      labelText: "Additional Info",
      onChanged: viewModel.updateAdditionalInfo,
    );
  }

  Widget? _requestIDField(RequestEditorViewModel viewModel) {
    if (!viewModel.showID()) {
      return null;
    }
    return SimpleTextFormField(
      readOnly: true,
      controller: viewModel.idController,
      labelText: "Request ID",
    );
  }

  Widget? _requestLogWidget(RequestEditorViewModel viewModel) {
    if (!viewModel.showEventLog()) {
      return null;
    }
    return Consumer<OrgState>(
      builder: (context, orgState, child) => LogsWidget(
        org: orgState.org,
        requestID: viewModel.initialRequest.id!,
      ),
    );
  }

  Widget _getButtons(RequestEditorViewModel viewModel, BuildContext context) {
    var messenger = ScaffoldMessenger.of(context);
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      mainAxisSize: MainAxisSize.max,
      children: viewModel
          .getActions()
          .map(
            (action) => ElevatedButton(
              onPressed: () async {
                var message = await action.onPressed();
                if (message.isNotEmpty) {
                  messenger.showSnackBar(SnackBar(content: Text(message)));
                }
              },
              child: Text(action.title),
            ),
          )
          .toList(),
    );
  }
}
