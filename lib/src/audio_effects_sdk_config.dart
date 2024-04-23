import 'audio_effects_sdk_enums.dart';

class Config {
  String? apiUrl;
  String? sdkUrl;
  ModelPreset? preset;
  int? sampleRate;
  int? droppedFramesThresholdMs;

  Map<String, String>? wasmPaths;

    Config({
      this.apiUrl,
      this.sdkUrl,
      this.preset,
      this.sampleRate,
      this.droppedFramesThresholdMs,
      this.wasmPaths});
}