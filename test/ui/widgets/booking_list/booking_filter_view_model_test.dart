import 'package:flutter_test/flutter_test.dart';
import 'package:room_booker/ui/widgets/booking_list/booking_filter_view_model.dart';

void main() {
  test('BookingFilterViewModel updates search query', () {
    final viewModel = BookingFilterViewModel();

    expect(viewModel.searchQuery, "");

    viewModel.updateSearchQuery("test query");

    expect(viewModel.searchQuery, "test query");
  });

  test('BookingFilterViewModel notifies listeners on update', () {
    final viewModel = BookingFilterViewModel();
    bool notified = false;
    viewModel.addListener(() {
      notified = true;
    });

    viewModel.updateSearchQuery("test");

    expect(notified, true);
  });
}
