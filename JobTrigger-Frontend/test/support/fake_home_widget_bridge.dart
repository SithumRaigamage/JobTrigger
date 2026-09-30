import 'package:job_trigger/core/platform/home_widget_bridge.dart';
import 'package:job_trigger/domain/widget/widget_snapshot.dart';

/// Records what the app would hand the home-screen widget.
class FakeHomeWidgetBridge implements HomeWidgetBridge {
  final written = <WidgetSnapshot>[];
  int clears = 0;

  @override
  Future<void> write(WidgetSnapshot snapshot) async => written.add(snapshot);

  @override
  Future<void> clear() async => clears++;
}
