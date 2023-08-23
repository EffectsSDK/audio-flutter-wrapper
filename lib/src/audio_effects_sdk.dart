import 'dart:collection';

import 'audio_effects_sdk_enums.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart' as webrtc;

import 'audio_effects_sdk_platform_interface.dart';

class AudioEffectsSDK {
  final Object _sdkContext;
  bool _ready = false;
  Function? onReady;
  Function? onUnableToProcessLive;

  AudioEffectsSDK(String customerID)
      : _sdkContext =
            AudioEffectsSDKPlatform.instance.createContext(customerID) {
    onUnableToProcessLiveCallback() {
      onUnableToProcessLive?.call();
    }

    callback() {
      AudioEffectsSDKPlatform.instance.setOnUnableToProcessLiveCallback(
          _sdkContext, onUnableToProcessLiveCallback);
      _ready = true;
      onReady?.call();
      onReady = null;
    }

    AudioEffectsSDKPlatform.instance.setOnReadyCallback(_sdkContext, callback);
  }

  void useStream(webrtc.MediaStream stream) {
    AudioEffectsSDKPlatform.instance.useStream(_sdkContext, stream);
  }

  webrtc.MediaStream getStream() {
    _throwIfNotReady("getStream()");
    return AudioEffectsSDKPlatform.instance.getStream(_sdkContext);
  }

  bool get isReady => _ready;

  void clear() {
    AudioEffectsSDKPlatform.instance.clear(_sdkContext);
    _ready = false;
  }

  void run() {
    _throwIfNotReady("run()");
    AudioEffectsSDKPlatform.instance.run(_sdkContext);
  }

  void stop() {
    AudioEffectsSDKPlatform.instance.stop(_sdkContext);
  }

  Future<void> setPreset(ModelPreset preset) {
    _throwIfNotReady("setPreset()");
    return AudioEffectsSDKPlatform.instance.setPreset(_sdkContext, preset);
  }

  void _throwIfNotReady(String methodName) {
    if (!_ready) {
      throw StateError(
          "${methodName} can not be used until AudioEffectsSDK is ready.");
    }
  }
}
