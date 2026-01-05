// lib/shared/services/connection_service.dart
import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;

/// Connection status enum
enum ConnectionStatus {
  online,
  offline,
  unknown,
}

/// Connection service state
class ConnectionState {
  final ConnectionStatus status;
  final DateTime lastChecked;
  final String? errorMessage;

  const ConnectionState({
    required this.status,
    required this.lastChecked,
    this.errorMessage,
  });

  bool get isOnline => status == ConnectionStatus.online;
  bool get isOffline => status == ConnectionStatus.offline;

  ConnectionState copyWith({
    ConnectionStatus? status,
    DateTime? lastChecked,
    String? errorMessage,
  }) {
    return ConnectionState(
      status: status ?? this.status,
      lastChecked: lastChecked ?? this.lastChecked,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }
}

/// Connection monitoring service
class ConnectionService extends StateNotifier<ConnectionState> {
  final Connectivity _connectivity = Connectivity();
  StreamSubscription<List<ConnectivityResult>>? _connectivitySubscription;
  Timer? _periodicCheckTimer;

  ConnectionService()
      : super(ConnectionState(
          status: ConnectionStatus.unknown,
          lastChecked: DateTime.now(),
        )) {
    _initializeConnectivityMonitoring();
  }

  /// Initialize connectivity monitoring
  void _initializeConnectivityMonitoring() {
    debugPrint('🌐 Initializing connection monitoring...');

    // Check initial connection status
    _checkConnection();

    // Listen to connectivity changes
    _connectivitySubscription =
        _connectivity.onConnectivityChanged.listen((result) {
      debugPrint('🌐 Connectivity changed: $result');
      _checkConnection();
    });

    // Periodic connection check (every 30 seconds)
    _periodicCheckTimer = Timer.periodic(
      const Duration(seconds: 30),
      (_) => _checkConnection(),
    );
  }

  /// Check current connection status
  Future<void> _checkConnection() async {
    try {
      // First, check connectivity
      final connectivityResult = await _connectivity.checkConnectivity();

      debugPrint('🌐 Connectivity result: $connectivityResult');

      // If no connectivity, immediately set offline
      if (connectivityResult.contains(ConnectivityResult.none)) {
        _updateStatus(ConnectionStatus.offline);
        return;
      }

      // If connected, verify with actual internet check
      final hasInternet = await _verifyInternetConnection();

      if (hasInternet) {
        _updateStatus(ConnectionStatus.online);
      } else {
        _updateStatus(ConnectionStatus.offline);
      }
    } catch (e) {
      debugPrint('❌ Error checking connection: $e');
      _updateStatus(ConnectionStatus.offline, errorMessage: e.toString());
    }
  }

  /// Verify actual internet connection by making a request
  Future<bool> _verifyInternetConnection() async {
    try {
      // Try to reach a reliable endpoint with timeout
      final response = await http
          .get(Uri.parse('https://www.google.com'))
          .timeout(const Duration(seconds: 5));

      return response.statusCode == 200;
    } catch (e) {
      debugPrint('❌ Internet verification failed: $e');
      return false;
    }
  }

  /// Update connection status
  void _updateStatus(ConnectionStatus status, {String? errorMessage}) {
    if (state.status != status) {
      debugPrint(
          '🌐 Connection status changed: ${state.status} → $status');

      state = ConnectionState(
        status: status,
        lastChecked: DateTime.now(),
        errorMessage: errorMessage,
      );
    }
  }

  /// Force check connection status
  Future<void> forceCheck() async {
    debugPrint('🌐 Force checking connection...');
    await _checkConnection();
  }

  /// Check if device has internet connectivity
  Future<bool> hasConnection() async {
    await _checkConnection();
    return state.isOnline;
  }

  @override
  void dispose() {
    debugPrint('🌐 Disposing connection service');
    _connectivitySubscription?.cancel();
    _periodicCheckTimer?.cancel();
    super.dispose();
  }
}

// ==================== PROVIDERS ====================

/// Provider for connection service
final connectionServiceProvider =
    StateNotifierProvider<ConnectionService, ConnectionState>((ref) {
  return ConnectionService();
});

/// Provider for connection status only
final connectionStatusProvider = Provider<ConnectionStatus>((ref) {
  final connectionState = ref.watch(connectionServiceProvider);
  return connectionState.status;
});

/// Provider for online/offline state
final isOnlineProvider = Provider<bool>((ref) {
  final connectionState = ref.watch(connectionServiceProvider);
  return connectionState.isOnline;
});

final isOfflineProvider = Provider<bool>((ref) {
  final connectionState = ref.watch(connectionServiceProvider);
  return connectionState.isOffline;
});
