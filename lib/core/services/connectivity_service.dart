import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';

enum NetworkStatus { online, offline, unknown }

class ConnectivityService {
  final Connectivity _connectivity = Connectivity();

  final StreamController<NetworkStatus> _statusController =
      StreamController<NetworkStatus>.broadcast();

  Stream<NetworkStatus> get statusStream => _statusController.stream;
  NetworkStatus _currentStatus = NetworkStatus.unknown;

  NetworkStatus get currentStatus => _currentStatus;

  Future<void> init() async {
    final results = await _connectivity.checkConnectivity();
    _updateStatus(results);

    _connectivity.onConnectivityChanged.listen((results) {
      _updateStatus(results);
    });
  }

  void _updateStatus(List<ConnectivityResult> results) {
    final previousStatus = _currentStatus;

    if (results.contains(ConnectivityResult.none) || results.isEmpty) {
      _currentStatus = NetworkStatus.offline;
    } else {
      _currentStatus = NetworkStatus.online;
    }

    if (previousStatus == NetworkStatus.offline &&
        _currentStatus == NetworkStatus.online) {
      debugPrint('CONNECTIVITY: Going online - triggering sync');
      _statusController.add(_currentStatus);
    } else if (_currentStatus != previousStatus) {
      _statusController.add(_currentStatus);
    }
  }

  Future<bool> isOnline() async {
    final results = await _connectivity.checkConnectivity();
    return !results.contains(ConnectivityResult.none) && results.isNotEmpty;
  }

  void dispose() {
    _statusController.close();
  }
}
