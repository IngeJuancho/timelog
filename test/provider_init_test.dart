import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timelog/time_log_controller.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('timeLogProvider initializes without Bad state error', () async {
    SharedPreferences.setMockInitialValues({});
    final container = ProviderContainer();
    addTearDown(container.dispose);

    // Reading the provider must not throw StateError
    final state = container.read(timeLogProvider);
    expect(state.isRunning, false);
    expect(state.usePhysicalButtons, false);
    expect(state.isAmoledMode, true);
  });
}
