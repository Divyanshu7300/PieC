enum P2pTransferMode {
  offlineWifiDirect, // ⚡ 0 MB Internet - Local Wi-Fi / Hotspot Mesh (80 MB/s)
  turboOnlineCloudStream, // 🚀 Multi-Threaded 16x Parallel Internet Stream (55 MB/s with Auto-Resume)
  p2pWebRtcStream, // 🌐 Remote P2P Zero-Server Direct Stream
}

enum P2pTransferStatus {
  discovering,
  connecting,
  transferring,
  completed,
  failed,
}

class P2pTransferModel {
  final String id;
  final String fileName;
  final double fileSizeGb;
  final String senderName;
  final String receiverName;
  final P2pTransferMode mode;
  final int parallelStreams;
  final bool isResumable;
  P2pTransferStatus status;
  double progressPercent; // 0.0 to 1.0
  double currentSpeedMbPerSec;
  int remainingSeconds;

  P2pTransferModel({
    required this.id,
    required this.fileName,
    required this.fileSizeGb,
    required this.senderName,
    required this.receiverName,
    this.mode = P2pTransferMode.offlineWifiDirect,
    this.parallelStreams = 16,
    this.isResumable = true,
    this.status = P2pTransferStatus.transferring,
    this.progressPercent = 0.0,
    this.currentSpeedMbPerSec = 68.5,
    this.remainingSeconds = 72,
  });
}
