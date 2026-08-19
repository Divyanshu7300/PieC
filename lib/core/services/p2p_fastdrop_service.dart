import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:piec/core/models/p2p_transfer_model.dart';
import 'package:uuid/uuid.dart';

class P2pFastDropService extends ChangeNotifier {
  final Uuid _uuid = const Uuid();

  P2pTransferModel? _activeTransfer;
  bool _isDiscovering = false;
  Timer? _transferTimer;

  P2pTransferModel? get activeTransfer => _activeTransfer;
  bool get isDiscovering => _isDiscovering;
  bool get isTransferring => _activeTransfer != null && _activeTransfer!.status == P2pTransferStatus.transferring;

  void startDiscovery() {
    _isDiscovering = true;
    notifyListeners();
  }

  void stopDiscovery() {
    _isDiscovering = false;
    notifyListeners();
  }

  void startTransfer({
    required String fileName,
    required double fileSizeGb,
    required String senderName,
    required String receiverName,
    P2pTransferMode mode = P2pTransferMode.offlineWifiDirect,
  }) {
    _transferTimer?.cancel();

    double initialSpeed = 74.8;
    int streams = 8;
    if (mode == P2pTransferMode.turboOnlineCloudStream) {
      initialSpeed = 58.4;
      streams = 16;
    } else if (mode == P2pTransferMode.p2pWebRtcStream) {
      initialSpeed = 42.5;
      streams = 4;
    }

    _activeTransfer = P2pTransferModel(
      id: _uuid.v4(),
      fileName: fileName,
      fileSizeGb: fileSizeGb,
      senderName: senderName,
      receiverName: receiverName,
      mode: mode,
      parallelStreams: streams,
      isResumable: true,
      status: P2pTransferStatus.transferring,
      progressPercent: 0.05,
      currentSpeedMbPerSec: initialSpeed,
      remainingSeconds: (fileSizeGb * 1024 / initialSpeed).round(),
    );

    notifyListeners();

    _startProgressSimulation();
  }

  void _startProgressSimulation() {
    _transferTimer?.cancel();
    _transferTimer = Timer.periodic(const Duration(milliseconds: 550), (timer) {
      if (_activeTransfer == null) {
        timer.cancel();
        return;
      }

      if (_activeTransfer!.progressPercent < 1.0) {
        _activeTransfer!.progressPercent += 0.09;
        if (_activeTransfer!.remainingSeconds > 3) {
          _activeTransfer!.remainingSeconds -= 4;
        }

        // Realistic speed calculation with multi-stream fluctuations
        double baseSpeed = 72.0;
        if (_activeTransfer!.mode == P2pTransferMode.turboOnlineCloudStream) {
          baseSpeed = 56.0;
        } else if (_activeTransfer!.mode == P2pTransferMode.p2pWebRtcStream) {
          baseSpeed = 40.0;
        }

        _activeTransfer!.currentSpeedMbPerSec = baseSpeed + (DateTime.now().millisecond % 14);

        if (_activeTransfer!.progressPercent >= 1.0) {
          _activeTransfer!.progressPercent = 1.0;
          _activeTransfer!.status = P2pTransferStatus.completed;
          _activeTransfer!.remainingSeconds = 0;
          timer.cancel();
        }
        notifyListeners();
      }
    });
  }

  void cancelTransfer() {
    _transferTimer?.cancel();
    _activeTransfer = null;
    notifyListeners();
  }

  @override
  void dispose() {
    _transferTimer?.cancel();
    super.dispose();
  }
}
