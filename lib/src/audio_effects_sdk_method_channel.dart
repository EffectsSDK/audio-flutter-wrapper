import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'audio_effects_sdk_platform_interface.dart';

/// An implementation of [AudioEffectsSDKPlatform] that uses method channels.
class MethodChannelAudioEffectsSDK extends AudioEffectsSDKPlatform {
  /// The method channel used to interact with the native platform.
  @visibleForTesting
  final methodChannel = const MethodChannel('audio_effects_sdk');
}
