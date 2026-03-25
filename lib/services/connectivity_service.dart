import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';

class ConnectivityService {
  final Connectivity _connectivity = Connectivity();
  StreamSubscription<List<ConnectivityResult>>? _subscription;

  bool _isConnected = true;
  bool get isConnected => _isConnected;

  final _controller = StreamController<bool>.broadcast();
  Stream<bool> get onConnectivityChanged => _controller.stream;

  Future<void> init() async {
    final results = await _connectivity.checkConnectivity();
    _isConnected = !results.contains(ConnectivityResult.none);

    _subscription = _connectivity.onConnectivityChanged.listen((results) {
      final connected = !results.contains(ConnectivityResult.none);
      if (connected != _isConnected) {
        _isConnected = connected;
        _controller.add(_isConnected);
      }
    });
  }

  void dispose() {
    _subscription?.cancel();
    _controller.close();
  }
}
