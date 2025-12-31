import 'dart:async';
import 'package:room_booker/data/entities/request.dart';
import 'package:room_booker/data/repos/booking_repo.dart';
import 'package:rxdart/rxdart.dart';
import 'package:sentry_flutter/sentry_flutter.dart';

class BookingService {
  final BookingRepo _bookingRepo;

  BookingService({required BookingRepo bookingRepo})
    : _bookingRepo = bookingRepo;

  Stream<List<Request>> getRequestsStream({
    required String orgID,
    required bool isAdmin,
    required DateTime start,
    required DateTime end,
    Set<RequestStatus>? includeStatuses,
    Set<String>? includeRoomIDs,
  }) {
    return _bookingRepo
        .listRequests(
          orgID: orgID,
          startTime: start,
          endTime: end,
          includeStatuses:
              includeStatuses ??
              {RequestStatus.pending, RequestStatus.confirmed},
          includeRoomIDs: includeRoomIDs,
        )
        .switchMap((requests) {
          // 1. Expand recurring requests into instances within the window
          final expandedRequests = <Request>[];
          for (var request in requests) {
            final instances = request.expand(
              start,
              end,
              includeRequestDate: true,
            );
            expandedRequests.addAll(instances);
          }

          if (expandedRequests.isEmpty) {
            return Stream.value(<Request>[]);
          }

          // 2. Fetch private details if user is admin
          if (!isAdmin) {
            return Stream.value(expandedRequests);
          }

          // Fetch details for the *original* request IDs (not the expanded instance IDs which might be null or same)
          // Actually request.expand returns copies. The 'id' field is still the original request ID.
          final uniqueRequestIds = expandedRequests
              .map((r) => r.id)
              .whereType<String>()
              .toSet();

          // If no IDs (e.g. all new local requests?), just return.
          if (uniqueRequestIds.isEmpty) {
            return Stream.value(expandedRequests);
          }

          final detailStreams = uniqueRequestIds
              .map((id) => _bookingRepo.getRequestDetails(orgID, id))
              .toList();

          return Rx.combineLatestList(detailStreams).map((detailsList) {
            final span = Sentry.getSpan()?.startChild(
              'enrich_requests',
              description:
                  'Enriching ${expandedRequests.length} requests with details',
            );

            try {
              final detailsMap = <String, PrivateRequestDetails>{};
              for (var d in detailsList) {
                if (d?.id != null) {
                  detailsMap[d!.id!] = d;
                }
              }

              return expandedRequests.map((request) {
                if (request.id == null) return request;
                final details = detailsMap[request.id];
                if (details != null) {
                  String? subject = request.publicName;
                  if (subject == null || subject.isEmpty) {
                    // If public name is empty, use private event name marked as Private
                    // Or just use the private name?
                    // CalendarViewModel logic:
                    // if (subject == null && details != null) { subject = "${details.eventName} (Private)"; }
                    // But wait, ViewBookingsViewModel Print logic:
                    // if (details != null && details.eventName.isNotEmpty) { return r.copyWith(publicName: details.eventName); }

                    // Let's standardise on showing the real name if admin.
                    // If it was private, the publicName is null/empty.
                    subject = "${details.eventName} (Private)";
                  }
                  return request.copyWith(publicName: subject);
                }
                return request;
              }).toList();
            } catch (e) {
              span?.status = const SpanStatus.internalError();
              rethrow;
            } finally {
              span?.finish();
            }
          });
        });
  }
}
