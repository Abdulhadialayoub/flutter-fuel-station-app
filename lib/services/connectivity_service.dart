import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';

/// Service for monitoring network connectivity
/// 
/// Provides:
/// - Current connectivity status
/// - Stream of connectivity changes
/// - Helper methods to check if connected
class ConnectivityService {
  final Connectivity _connectivity;
  StreamSubscription<List<ConnectivityResult>>? _subscription;
  
  // Callbacks for connectivity changes
  final List<VoidCallback> _onConnectedCallbacks = [];
  final List<VoidCallback> _onDisconnectedCallbacks = [];
  
  bool _wasConnected = true;

  ConnectivityService({Connectivity? connectivity})
      : _connectivity = connectivity ?? Connectivity();

  /// Start monitoring connectivity changes
  void startMonitoring() {
    _subscription = _connectivity.onConnectivityChanged.listen(
      (List<ConnectivityResult> results) {
        _handleConnectivityChange(results);
      },
    );
  }

  /// Stop monitoring connectivity changes
  void stopMonitoring() {
    _subscription?.cancel();
    _subscription = null;
  }

  /// Handle connectivity change
  void _handleConnectivityChange(List<ConnectivityResult> results) {
    final isConnected = _isConnected(results);
    
    // Detect transition from disconnected to connected
    if (!_wasConnected && isConnected) {
      // Network restored - trigger callbacks
      for (final callback in _onConnectedCallbacks) {
        callback();
      }
    }
    
    // Detect transition from connected to disconnected
    if (_wasConnected && !isConnected) {
      // Network lost - trigger callbacks
      for (final callback in _onDisconnectedCallbacks) {
        callback();
      }
    }
    
    _wasConnected = isConnected;
  }

  /// Check if currently connected to network
  Future<bool> isConnected() async {
    final results = await _connectivity.checkConnectivity();
    return _isConnected(results);
  }

  /// Helper to check if connectivity results indicate connection
  bool _isConnected(List<ConnectivityResult> results) {
    return results.any((result) =>
        result == ConnectivityResult.mobile ||
        result == ConnectivityResult.wifi ||
        result == ConnectivityResult.ethernet);
  }

  /// Register callback for when network is restored
  void onConnected(VoidCallback callback) {
    _onConnectedCallbacks.add(callback);
  }

  /// Register callback for when network is lost
  void onDisconnected(VoidCallback callback) {
    _onDisconnectedCallbacks.add(callback);
  }

  /// Remove a connected callback
  void removeOnConnected(VoidCallback callback) {
    _onConnectedCallbacks.remove(callback);
  }

  /// Remove a disconnected callback
  void removeOnDisconnected(VoidCallback callback) {
    _onDisconnectedCallbacks.remove(callback);
  }

  /// Clear all callbacks
  void clearCallbacks() {
    _onConnectedCallbacks.clear();
    _onDisconnectedCallbacks.clear();
  }

  /// Dispose resources
  void dispose() {
    stopMonitoring();
    clearCallbacks();
  }
}
