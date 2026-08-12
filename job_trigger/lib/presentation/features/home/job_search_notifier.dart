import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'job_search_notifier.g.dart';

@riverpod
class JobSearchNotifier extends _$JobSearchNotifier {
  @override
  String build() => '';

  void setQuery(String query) => state = query;

  void clear() => state = '';
}
