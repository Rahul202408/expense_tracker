import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';

class ConnectivityProvider extends ChangeNotifier {
  final Connectivity _connectivity = Connectivity();
  StreamSubscription<List<ConnectivityResult>>? _subscription;

  Timer? _onlineTimer;
  bool _isDisposed = false;

  bool _isOffline = false;
  bool get isOffline => _isOffline;

  bool _wasOffline = false;
  bool get showBackOnlineBanner => !_isOffline && _wasOffline;

  ConnectivityProvider() {
    _initConnectivity();
    _subscription = _connectivity.onConnectivityChanged.listen(_updateConnectionStatus);
  }

  void _safeNotifyListeners() {
    if (!_isDisposed) {
      notifyListeners();
    }
  }

  Future<void> _initConnectivity() async {
    try {
      final results = await _connectivity.checkConnectivity();
      _updateConnectionStatus(results);
    } catch (e) {
      debugPrint("Connectivity Check Error: $e");
    }
  }

  void _updateConnectionStatus(List<ConnectivityResult> results) {
    if (_isDisposed) return;
    final bool currentlyOffline = results.every((result) => result == ConnectivityResult.none);

    if (currentlyOffline != _isOffline) {
      if (!currentlyOffline && _isOffline) {
        // Was offline, now back online
        _wasOffline = true;
        _isOffline = false;
        _safeNotifyListeners();

        // Hide "Back Online" badge after 3 seconds
        _onlineTimer?.cancel();
        _onlineTimer = Timer(const Duration(seconds: 3), () {
          if (!_isDisposed) {
            _wasOffline = false;
            _safeNotifyListeners();
          }
        });
      } else {
        _isOffline = currentlyOffline;
        _safeNotifyListeners();
      }
    }
  }

  Future<void> retryConnection() async {
    final results = await _connectivity.checkConnectivity();
    _updateConnectionStatus(results);
  }

  @override
  void dispose() {
    _isDisposed = true;
    _onlineTimer?.cancel();
    _subscription?.cancel();
    super.dispose();
  }
}
