import 'package:plugin_platform_interface/plugin_platform_interface.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart' as webrtc;

import 'audio_effects_sdk_config.dart';
import 'audio_effects_sdk_method_channel.dart';
import 'audio_effects_sdk_enums.dart';
import 'audio_effects_sdk_error.dart';

abstract class AudioEffectsSDKPlatform extends PlatformInterface {
  /// Constructs a AudioEffectsSDKPlatform.
  AudioEffectsSDKPlatform() : super(token: _token);

  static final Object _token = Object();

  static AudioEffectsSDKPlatform _instance = MethodChannelAudioEffectsSDK();

  /// The default instance of [AudioEffectsSDKPlatform] to use.
  ///
  /// Defaults to [MethodChannelAudioEffectsSDK].
  static AudioEffectsSDKPlatform get instance => _instance;

  /// Platform-specific implementations should set this with their own
  /// platform-specific class that extends [AudioEffectsSDKPlatform] when
  /// they register themselves.
  static set instance(AudioEffectsSDKPlatform instance) {
    PlatformInterface.verifyToken(instance, _token);
    _instance = instance;
  }

  Object createContext(String customerID) {
    throw UnimplementedError('createContext() has not been implemented.');
  }

  void setOnReadyCallback(Object sdkContext, Function? callback) {
    throw UnimplementedError('setOnReadyCallback() has not been implemented.');
  }

  void setOnUnableToProcessLiveCallback(Object sdkContext, Function? callback) {
    throw UnimplementedError(
        'setOnUnableToProcessLiveCallback() has not been implemented.');
  }

  void config(Object sdkContext, Config config) {
    throw UnimplementedError(
        'config() has not been implemented.');
  }

  void useStream(Object sdkContext, webrtc.MediaStream stream) {
    throw UnimplementedError('useStream() has not been implemented.');
  }

  webrtc.MediaStream getStream(Object sdkContext) {
    throw UnimplementedError('getStream() has not been implemented.');
  }

  void clear(Object sdkContext) {
    throw UnimplementedError('clear() has not been implemented.');
  }

  void preload(Object sdkContext) {
    throw UnimplementedError('preload() has not been implemented.');
  }

  void run(Object sdkContext) {
    throw UnimplementedError('run() has not been implemented.');
  }

  void stop(Object sdkContext) {
    throw UnimplementedError('stop() has not been implemented.');
  }

  void setDenoisePower(Object sdkContext, double power) {
    throw UnimplementedError('setDenoisePower() has not been implemented.');
  }

  void setDroppedFramesThreshold(Object sdkContext, int threshold) {
    throw UnimplementedError('setDroppedFramesThreshold() has not been implemented.');
  }

  Future<void> setPreset(Object sdkContext, ModelPreset preset, int? sampleRate) {
    throw UnimplementedError(
        'setSegmentationPreset() has not been implemented.');
  }

  void setOnErrorCallback(Object sdkContext, Function(ErrorObject e)? callback) {
    throw UnimplementedError(
        'setOnErrorCallback() has not been implemented.');
  }
}
