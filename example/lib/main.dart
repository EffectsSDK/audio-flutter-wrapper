import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:html';

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

class AudioEffectsSDKSampleApp extends StatefulWidget {
  const AudioEffectsSDKSampleApp({super.key});

  @override
  State<AudioEffectsSDKSampleApp> createState() =>
      _AudioEffectsSDKSampleAppState();
}

class _AudioEffectsSDKSampleAppState extends State<AudioEffectsSDKSampleApp> {
  final _audioOutput = AudioElement();
  final _audioSDK = AudioEffectsSDK(getCustomerID());
  ModelPreset _currentPreset = ModelPreset.speed;
  bool _audioEnhancementEnabled = false;
  bool _sdkInializing = false;
  bool _unableToProcessLive = false;
  bool _switchingPreset = false;

  String? _currentDeviceID;
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
    switchDevice();
  }

  Future<void> switchDevice([String? deviceID]) async {
    MediaStream inputStream = await getAudioStream(deviceID);

    if (_audioEnhancementEnabled) {
      setupAudioEnhancementPipeline(inputStream);
    } else {
      setAudioOutputStream(inputStream);
    }

    stopTracks(_currentAudioStream);
    _currentAudioStream = inputStream;
  }

  void setupAudioEnhancementPipeline(MediaStream stream) {
    setState(() {
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
      _audioEnhancementEnabled = false;
      if (null != _currentAudioStream) {
        setAudioOutputStream(_currentAudioStream!);
      }
      _audioSDK.clear();
      stopTracks(_currentSdkOutput);
      _currentSdkOutput = null;
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

  Future<MediaStream> getAudioStream([String? deviceID]) async {
    final constraints = getAudioConstraints(deviceID);
    return navigator.mediaDevices.getUserMedia(constraints);
  }

  Map<String, dynamic> getAudioConstraints([String? deviceID]) {
    if (null != deviceID) {
      return {
        "audio": {"deviceId": deviceID}
      };
    }
    return {"audio": true, "video": false};
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

  bool get _presetSwitchAllowed =>
      _audioEnhancementEnabled && !_switchingPreset && !_sdkInializing;

  void setPreset(ModelPreset preset) async {
    setState(() {
      _switchingPreset = true;
    });

    try {
      await _audioSDK.setPreset(preset);
      setState(() {
        _currentPreset = preset;
        _switchingPreset = false;
      });
    } catch (e) {
      setState(() {
        _switchingPreset = false;
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
        DropdownButton<ModelPreset>(
          value: _currentPreset,
          onChanged: _presetSwitchAllowed
              ? (ModelPreset? preset) {
                  if (null != preset) {
                    setPreset(preset);
                  }
                }
              : null,
          items: ModelPreset.values
              .map<DropdownMenuItem<ModelPreset>>((ModelPreset value) {
            return DropdownMenuItem<ModelPreset>(
                value: value, child: Text(value.name));
          }).toList(),
        )
      ]),
      makeTextButton("Switch Input", onPressed: onSwitchInputPressed)
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
