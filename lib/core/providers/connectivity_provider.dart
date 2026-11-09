import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../utils/app_log.dart';

final onlineProvider = StreamProvider<bool>((ref) async* {
  final connectivity = Connectivity();
  try {
    yield _isOnline(await connectivity.checkConnectivity());
    await for (final update in connectivity.onConnectivityChanged) {
      yield _isOnline(update);
    }
  } catch (error) {
    AppLog.error('connectivity', error);
    yield true;
  }
});

bool _isOnline(List<ConnectivityResult> results) {
  return results.any((result) => result != ConnectivityResult.none);
}
