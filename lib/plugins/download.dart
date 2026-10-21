import 'package:skyward/common/common.dart';
import 'package:flutter/services.dart';

/// The system download manager: the file lands in the device's Downloads
/// folder and the system shows its own progress and a retry.
class SystemDownloader {
  SystemDownloader._();

  static final instance = SystemDownloader._();

  static const _methodChannel = MethodChannel('$packageName/download');

  /// The ABI the device runs, which names the package that fits it.
  Future<String?> supportedAbi() {
    return _methodChannel.invokeMethod<String>('supportedAbi');
  }

  /// Hands the file to the system download manager and returns its id.
  Future<int?> download({required String url, required String fileName}) {
    return _methodChannel.invokeMethod<int>('download', {
      'url': url,
      'fileName': fileName,
    });
  }
}

final systemDownloader = system.isAndroid ? SystemDownloader.instance : null;
