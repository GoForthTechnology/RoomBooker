import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:room_booker/data/entities/request.dart';
import 'package:room_booker/ui/utils/traced_stream_builder.dart';
import 'package:room_booker/ui/widgets/request_editor/date_field.dart';
import 'package:room_booker/ui/widgets/org_state_provider.dart';
import 'package:room_booker/ui/widgets/request_editor/repeat_booking_selector/repeat_bookings_selector.dart';
import 'package:room_booker/ui/widgets/request_editor/request_editor_view_model.dart';
import 'package:room_booker/ui/widgets/room_dropdown_selector.dart';
import 'package:room_booker/ui/widgets/room_selector.dart';
import 'package:room_booker/ui/widgets/simple_text_form_field.dart';
import 'package:room_booker/ui/widgets/request_editor/time_field.dart';

import 'logs_widget.dart';

class RequestEditor extends StatelessWidget {
  final VoidCallback? onClose;

  const RequestEditor({super.key, this.onClose});

  @override
  Widget build(BuildContext context) {
    var orgState = Provider.of<OrgState>(context, listen: false);
    var localizations = MaterialLocalizations.of(context);
    return Consumer2<RoomState, RequestEditorViewModel>(
      builder: (context, roomState, viewModel, child) => TracedStreamBuilder(
        "render_request_editor",
        context.read(),
        stream: viewModel.viewStateStream,
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          var state = snapshot.data!;
          var formContents = Column(
            children: [
              _title(viewModel, context),
              _roomSelector(viewModel, state.readOnly),
              _eventNameSelector(viewModel, state.readOnly),
              _isPublicSelector(viewModel, state.readOnly),
              if (state.showIgnoreOverlapsToggle)
                _ignoreOverlapsSelector(viewModel, state.readOnly)!,
              _eventDateSelector(viewModel, state.readOnly),
              _eventStartTimeSelector(viewModel, localizations, state.readOnly),
              _eventEndTimeSelector(viewModel, localizations, state.readOnly),
              RepeatBookingsSelector(
                viewModel: viewModel.repeatBookingsViewModel,
              ),
              _patternEndSelector(viewModel, state.readOnly),
              const Divider(),
              _contactNameSelector(viewModel, state.readOnly),
              _contactEmailSelector(viewModel, state.readOnly),
              _contactPhoneSelector(viewModel, state.readOnly),
              if (orgState.currentUserIsAdmin)
                _adminContactInfoButton(viewModel, orgState, state.readOnly)!,
              const Divider(),
              _additionalInfoSelector(viewModel, state.readOnly),
              if (state.showID) _requestIDField(viewModel)!,
              if (state.showEventLog)
                _requestLogWidget(viewModel, state.readOnly)!,
              _getButtons(state, context),
            ],
          );
          return SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(4),
              child: Form(key: viewModel.formKey, child: formContents),
            ),
          );
        },
      ),
    );
  }

  Widget _title(RequestEditorViewModel viewModel, BuildContext context) {
    return AppBar(
      title: Text(viewModel.editorTitle),
      actions: [
        IconButton(
          icon: const Icon(Icons.close),
          onPressed: () async {
            await viewModel.closeEditor();
            if (onClose != null) {
              onClose!();
            }
          },
        ),
      ],
      automaticallyImplyLeading: false,
    );
  }

  Widget _roomSelector(RequestEditorViewModel viewModel, bool readOnly) {
    return RoomDropdownSelector(
      readOnly: readOnly,
      initialRoomID: viewModel.roomID,
      orgID: viewModel.orgID,
      onChanged: (room) {
        if (room != null) {
          viewModel.updateRoom(room);
        }
      },
    );
  }

  Widget _eventNameSelector(RequestEditorViewModel viewModel, bool readOnly) {
    return SimpleTextFormField(
      readOnly: readOnly,
      controller: viewModel.eventNameContoller,
      labelText: "Event Name",
      validationMessage: "Please provide a name",
    );
  }

  Widget _isPublicSelector(RequestEditorViewModel viewModel, bool readOnly) {
    return StreamBuilder(
      stream: viewModel.isPublicStream,
      builder: (context, snapshot) {
        var isPublic = snapshot.data ?? false;
        return SwitchListTile(
          title: Text("Show name on parish calendar"),
          value: isPublic,
          onChanged: readOnly ? null : viewModel.updateIsPublic,
        );
      },
    );
  }

  Widget? _ignoreOverlapsSelector(
    RequestEditorViewModel viewModel,
    bool readOnly,
  ) {
    return StreamBuilder(
      stream: viewModel.ignoreOverlapsStream,
      builder: (context, snapshot) {
        var isIgnoreOverlaps = snapshot.data ?? false;
        return SwitchListTile(
          title: Text("Ignore overlapping events"),
          value: isIgnoreOverlaps,
          onChanged: readOnly ? null : viewModel.updateIgnoreOverlaps,
        );
      },
    );
  }

  Widget _eventDateSelector(RequestEditorViewModel viewModel, bool readOnly) {
    return StreamBuilder(
      stream: viewModel.eventStartStream,
      builder: (context, snapshot) {
        var startTime = snapshot.data;
        return DateField(
          initialValue: startTime,
          readOnly: readOnly,
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
    bool readOnly,
  ) {
    return StreamBuilder<(DateTime, DateTime)>(
      stream: viewModel.eventTimeStream,
      builder: (context, snapshot) {
        var (startTime, endTime) = snapshot.data ?? (null, null);
        if (startTime == null || endTime == null) {
          return const SizedBox.shrink();
        }
        return TimeField(
          readOnly: readOnly,
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
    bool readOnly,
  ) {
    return StreamBuilder<(DateTime, DateTime)>(
      stream: viewModel.eventTimeStream,
      builder: (context, snapshot) {
        var (startTime, endTime) = snapshot.data ?? (null, null);
        if (startTime == null || endTime == null) {
          return const SizedBox.shrink();
        }
        return TimeField(
          readOnly: readOnly,
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

  Widget _patternEndSelector(RequestEditorViewModel viewModel, bool readOnly) {
    return StreamBuilder<RecurrancePattern>(
      stream: viewModel.repeatBookingsViewModel.patternStream,
      builder: (context, snapshot) {
        if (!snapshot.hasData || snapshot.data!.frequency == Frequency.never) {
          return const SizedBox.shrink();
        }
        return DateField(
          initialValue: snapshot.data!.end,
          labelText: "End on or before",
          onChanged: (date) =>
              viewModel.repeatBookingsViewModel.updateEndDate(date),
          readOnly: readOnly,
          clearable: true,
        );
      },
    );
  }

  Widget _contactNameSelector(RequestEditorViewModel viewModel, bool readOnly) {
    return SimpleTextFormField(
      readOnly: readOnly,
      controller: viewModel.contactNameController,
      labelText: "Your Name",
      validationMessage: "Please provide your name",
    );
  }

  Widget _contactEmailSelector(
    RequestEditorViewModel viewModel,
    bool readOnly,
  ) {
    return SimpleTextFormField(
      readOnly: readOnly,
      controller: viewModel.contactEmailController,
      labelText: "Your Email",
      validationMessage: "Please provide your email",
      validationRegex: RegExp(
        r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
      ),
    );
  }

  Widget _contactPhoneSelector(
    RequestEditorViewModel viewModel,
    bool readOnly,
  ) {
    return SimpleTextFormField(
      readOnly: readOnly,
      controller: viewModel.phoneNumberController,
      labelText: "Your Phone Number",
      validationMessage: "Please provide your phone number",
    );
  }

  Widget? _adminContactInfoButton(
    RequestEditorViewModel viewModel,
    OrgState orgState,
    bool readOnly,
  ) {
    if (!orgState.currentUserIsAdmin) {
      return null;
    }
    return ElevatedButton(
      onPressed: readOnly
          ? null
          : () {
              viewModel.useAdminContactInfo();
            },
      child: Text("Use My Info"),
    );
  }

  Widget _additionalInfoSelector(
    RequestEditorViewModel viewModel,
    bool readOnly,
  ) {
    return SimpleTextFormField(
      readOnly: readOnly,
      controller: viewModel.additionalInfoController,
      labelText: "Additional Info",
    );
  }

  Widget? _requestIDField(RequestEditorViewModel viewModel) {
    return SimpleTextFormField(
      readOnly: true,
      controller: viewModel.idController,
      labelText: "Request ID",
    );
  }

  Widget? _requestLogWidget(RequestEditorViewModel viewModel, bool readOnly) {
    return Consumer<OrgState>(
      builder: (context, orgState, child) => FutureBuilder(
        future: viewModel.currentDataStream().first,
        builder: (context, snapshot) {
          if (!snapshot.hasData || snapshot.data!.$1 == null) {
            return const SizedBox.shrink();
          }
          var request = snapshot.data!.$1!;
          return LogsWidget(
            org: orgState.org,
            requestID: request.id!,
            readOnly: readOnly,
          );
        },
      ),
    );
  }

  Widget _getButtons(EditorViewState viewState, BuildContext context) {
    var messenger = ScaffoldMessenger.of(context);
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      mainAxisSize: MainAxisSize.max,
      children: viewState.actions
          .map(
            (action) => ElevatedButton(
              onPressed: () async {
                try {
                  var result = await action.onPressed();
                  if (result.message.isNotEmpty) {
                    messenger.showSnackBar(
                      SnackBar(content: Text(result.message)),
                    );
                  }
                  if (result.shouldCloseEditor && onClose != null) {
                    onClose!();
                  }
                } catch (e) {
                  messenger.showSnackBar(SnackBar(content: Text(e.toString())));
                }
              },
              child: Text(action.title),
            ),
          )
          .toList(),
    );
  }
}
