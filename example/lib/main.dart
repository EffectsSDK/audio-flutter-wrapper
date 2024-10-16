import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:html' as html;

import 'package:audio_effects_sdk/audio_effects_sdk.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';

void main() {
  runApp(const AudioEffectsSDKSampleApp());
}

void stopTracks(MediaStream? stream) {
  if (stream == null) {
    return;
  }

  for (final track in stream.getTracks()) {
    track.stop();
  }
}

String getCustomerID() {
  const String result = String.fromEnvironment("CUSTOMER_ID");
  if (result.isEmpty) {
    throw Exception("CUSTOMER_ID is not provided!\n"
      "Please, provide CUSTOMER_ID as an environment variable by using --dart-define=CUSTOMER_ID={Your_customer_id}.\n"
      "Example 'flutter run --dart-define=CUSTOMER_ID=\$CUSTOMER_ID'\n"
      "To receive a license, visit https://effectssdk.com/contacts/");
  }

  return result;
}

enum PresetSetting {
  speed16khz(preset: ModelPreset.speed, sampleRate: 16000, friendlyName: "Speed: 16kHz"),
  balanced16khz(preset: ModelPreset.balanced, sampleRate: 16000, friendlyName: "Balanced: 16kHz"),
  balanced32khz(preset: ModelPreset.balanced, sampleRate: 32000, friendlyName: "Balanced: 32kHz"),
  balanced44khz(preset: ModelPreset.balanced, sampleRate: 44100, friendlyName: "Balanced: 44.1kHz"),
  balanced48khz(preset: ModelPreset.balanced, sampleRate: 48000, friendlyName: "Balanced: 48kHz"),
  quality16khz(preset: ModelPreset.quality, sampleRate: 16000, friendlyName: "Quality: 16kHz");

  const PresetSetting({
    required this.preset,
    required this.sampleRate,
    required this.friendlyName
  });

  final ModelPreset preset;
  final int sampleRate;
  final String friendlyName;
}

class AudioEffectsSDKSampleApp extends StatefulWidget {
  const AudioEffectsSDKSampleApp({super.key});

  @override
  State<AudioEffectsSDKSampleApp> createState() =>
      _AudioEffectsSDKSampleAppState();
}

class _AudioEffectsSDKSampleAppState extends State<AudioEffectsSDKSampleApp> {
  final _audioOutput = html.AudioElement();
  final _audioSDK = AudioEffectsSDK(getCustomerID());
  ModelPreset _currentPreset = ModelPreset.speed;
  int _currentSampleRate = 16000;
  bool _audioEnhancementEnabled = false;
  bool _sdkInializing = false;
  bool _unableToProcessLive = false;
  bool _switchingPreset = false;
  String? _lastError;

  MediaStream? _currentAudioStream;
  MediaStream? _currentSdkOutput;

  bool _audioInputSelectionEnabled = false;
  List<MediaDeviceInfo> _audioInputInfoList = [];

  @override
  void initState() {
    super.initState();
    initAudioEffectsSDK();
  }

  Future<void> initAudioEffectsSDK() async {
    _audioSDK.onUnableToProcessLive = () {
      if (!_unableToProcessLive) {
        setState(() {
          _unableToProcessLive = true;
          disableEnhancement();
        });
      }
    };
    _audioSDK.onError = (e) { 
      if (e.type != ErrorType.error) {
        return;
      }

      if (_sdkInializing) {
        setState(() {
          _sdkInializing = false;
          _audioEnhancementEnabled = false;
          _lastError = e.message;
        });
      }
      else {
        setState(() {
          _lastError = e.message;
        });
      }
    };
    switchDevice();
  }

  Future<void> switchDevice([String? deviceID]) async {
    final inputStream = await getAudioStream(_currentSampleRate, deviceID);
    await setAudioStream(inputStream);
  }

  Future<void> setAudioStream(MediaStream inputStream) async {
    if (_audioEnhancementEnabled) {
      setupAudioEnhancementPipeline(inputStream);
    } else {
      setAudioOutputStream(inputStream);
    }

    stopTracks(_currentAudioStream);
    _currentAudioStream = inputStream;
  }

  void setupAudioEnhancementPipeline(MediaStream stream) async {
    setState(() {
      _lastError = null;
      _sdkInializing = true;
      _unableToProcessLive = false;
    });

    _audioSDK.clear();
    _audioSDK.onReady = () {
      _audioSDK.run();
      setState(() {
        _sdkInializing = false;
      });

      final outputStream = _audioSDK.getStream();
      if (_audioEnhancementEnabled) {
        setAudioOutputStream(outputStream);
        stopTracks(_currentSdkOutput);
        _currentSdkOutput = outputStream;
      } else {
        final outputStream = _audioSDK.getStream();
        stopTracks(outputStream);
      }
    };

    _audioSDK.useStream(stream);
  }

  void enableEnhancement() {
    setState(() {
      _audioEnhancementEnabled = true;
      if (null != _currentAudioStream) {
        setupAudioEnhancementPipeline(_currentAudioStream!);
      }
    });
  }

  void disableEnhancement() {
    setState(() {
      _lastError = null;
      _audioEnhancementEnabled = false;
      if (null != _currentAudioStream) {
        setAudioOutputStream(_currentAudioStream!);
      }
      _audioSDK.clear();
      stopTracks(_currentSdkOutput);
      _currentSdkOutput = null;
      _sdkInializing = false;
    });
  }

  setAudioOutputStream(MediaStream stream) {
    final jsStream = (stream as dynamic).jsStream;
    _audioOutput.srcObject = jsStream;
    _audioOutput.play();
    _audioOutput.volume = 1;
  }

  Future<List<MediaDeviceInfo>> enumerateAudioInputs() async {
    final List<MediaDeviceInfo> devices =
        await navigator.mediaDevices.enumerateDevices();
    List<MediaDeviceInfo> result = [];
    for (final device in devices) {
      if ("audioinput" == device.kind) {
        result.add(device);
      }
    }

    return result;
  }

  Future<MediaStream> getAudioStream(int sampleRate, [String? deviceID]) async {
    final constraints = getAudioConstraints(sampleRate, deviceID);
    return navigator.mediaDevices.getUserMedia(constraints);
  }

  Map<String, dynamic> getAudioConstraints(int sampleRate, [String? deviceID]) {
    return {
      "audio": {
        if (null != deviceID) "deviceId": deviceID,
        "autoGainControl": false,
        "channelCount": 1,
        "echoCancellation": false,
        "noiseSuppression": false
      },
      "video": false
    };
  }

  String get sdkStatusDesc {
    if (!_audioEnhancementEnabled) {
      return "Processing is disabled";
    }

    if (_switchingPreset) {
      return "Switching preset";
    }

    return _sdkInializing ? "Initializing" : "Ready";
  }

  bool get _presetSwitchAllowed => !_switchingPreset && !_sdkInializing;

  void setPreset(PresetSetting setting) async {
    setState(() {
      _switchingPreset = true;
      _lastError = null;
    });

    try {
      if (_audioSDK.isReady) {
        await _audioSDK.setPreset(setting.preset, sampleRate: setting.sampleRate);
      }
      else {
        _audioSDK.config(Config(preset: setting.preset, sampleRate: setting.sampleRate));
      }
      setState(() {
        _currentPreset = setting.preset;
        _switchingPreset = false;
        _currentSampleRate = setting.sampleRate;
      });
    } catch (e) {
      setState(() {
        _switchingPreset = false;
        _lastError = e.toString();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          title: const Text('Audio Effects SDK Example App'),
        ),
        body: _audioInputSelectionEnabled
            ? buildAudioInputSelector()
            : buildMainPage(),
      ),
    );
  }

  Widget buildMainPage() {
    onSwitchInputPressed() async {
      final infos = await enumerateAudioInputs();
      setState(() {
        _audioInputInfoList = infos;
        _audioInputSelectionEnabled = true;
      });
    }

    makeTextButton(String title,
        {required void Function() onPressed, bool enabled = true}) {
      return TextButton(
          onPressed: enabled ? onPressed : null,
          child: Container(
              padding: const EdgeInsets.all(6.0),
              margin: const EdgeInsets.all(12.0),
              decoration: BoxDecoration(border: Border.all(width: 1)),
              child: Text(title)));
    }

    final currentPresetSetting = PresetSetting.values.firstWhere(
      (s)=>s.preset == _currentPreset && s.sampleRate == _currentSampleRate
    );

    return Column(mainAxisAlignment: MainAxisAlignment.center, children: [
      Text(sdkStatusDesc, style: TextStyle(fontSize: 28)),
      if (_unableToProcessLive)
        Container(
            padding: const EdgeInsets.all(6.0),
            margin: const EdgeInsets.all(12.0),
            decoration:
                BoxDecoration(border: Border.all(width: 1, color: Colors.red)),
            child: Text("Unable to process live!",
                style: TextStyle(color: Colors.red))),
      Row(mainAxisAlignment: MainAxisAlignment.center, children: [
        makeTextButton("Enable SDK",
            onPressed: () => enableEnhancement(),
            enabled: !_audioEnhancementEnabled),
        makeTextButton("Disable SDK",
            onPressed: () => disableEnhancement(),
            enabled: _audioEnhancementEnabled)
      ]),
      Row(mainAxisAlignment: MainAxisAlignment.center, children: [
        Text("Model preset: ", style: TextStyle(fontSize: 16)),
        DropdownButton<PresetSetting>(
          value: currentPresetSetting,
          onChanged: _presetSwitchAllowed
              ? (PresetSetting? preset) {
                  if (null != preset) {
                    setPreset(preset);
                  }
                }
              : null,
          items: PresetSetting.values
              .map<DropdownMenuItem<PresetSetting>>((PresetSetting value) {
            return DropdownMenuItem<PresetSetting>(
                value: value, child: Text(value.friendlyName));
          }).toList(),
        )
      ]),
      makeTextButton("Switch Input", onPressed: onSwitchInputPressed),
      Text((null != _lastError)? _lastError! : "", style: TextStyle(color: Colors.red))
    ]);
  }

  Widget buildAudioInputSelector() {
    return Column(children: [
      Expanded(child: buildAudioInputList()),
      TextButton(
          onPressed: () {
            setState(() {
              _audioInputInfoList = [];
              _audioInputSelectionEnabled = false;
            });
          },
          child: Container(
              padding: const EdgeInsets.all(24), child: const Text("Cancel")))
    ]);
  }

  Widget buildAudioInputList() {
    final cameraInfos = _audioInputInfoList;
    return ListView.builder(
      padding: const EdgeInsets.all(24),
      itemBuilder: (BuildContext context, int index) {
        return buildAudioInputItem(cameraInfos[index]);
      },
      itemCount: cameraInfos.length,
    );
  }

  Widget buildAudioInputItem(MediaDeviceInfo deviceInfo) {
    onPressed() {
      switchDevice(deviceInfo.deviceId);
      setState(() {
        _audioInputInfoList = [];
        _audioInputSelectionEnabled = false;
      });
    }

    return TextButton(
        onPressed: onPressed,
        child: Container(
            padding: const EdgeInsets.all(12.0),
            child: Text(deviceInfo.label)));
  }
}
