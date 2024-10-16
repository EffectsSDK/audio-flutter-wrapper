

# Audio Effects SDK: Flutter plugin and samples

Audio Effects SDK plugin for Flutter

Add real-time AI audio denoise and echo cancellation to your product in a hour. 

This repository contains the Audio Effects SDK Flutter plugin that integrates Audio Effects SDK Web into your project/product that uses **Flutter WebRTC** plugin.
The plugin can work with **Flutter WebRTC**, just put a **MediaStream** into the SDK and use the returned **MediaStream**.
Also, there is the example Flutter project, which, if you have a license, you can build and run to see the plugin in action.

This plugin is currently available only for web.

## Obtaining an Effects SDK License

To receive an **Effects SDK** license, please fill out the contact form on [effectssdk.com](https://effectssdk.com/contacts) website.

## Features

- AI Denoise - **implemented**
- Echo Cancellation - **in progress**
- AI Denoise by Speaker Extraction - **in progress**

### How to add

Add `<script crossorigin="anonymous" src="https://effectssdk.ai/sdk/audio/dev/2.3.3/atsvb-web.js"></script>` to your index.html.

Add next code as dependency in your pubspec.yaml file.
```yaml
  audio_effects_sdk:
    git:
      url: https://github.com/EffectsSDK/audio-flutter-wrapper
```

### Usage

- Create an instance of **AudioEffectsSDK** and pass your Customer ID to the constructor.
- Use `AudioEffectsSDK.useStream(mediaStream)` to put a stream to be processed.
- Set `AudioEffectsSDK.onReady` callback.
- When ready use `AudioEffectsSDK.run()` to start video processing.
- Use `AudioEffectsSDK.getStream()` to get a stream with applied effects.

```dart
const String customerID = String.fromEnvironment("CUSTOMER_ID");
final audioEffectsSDK = AudioEffectsSDK(customerID);
effectsSDK.useStream(inputStream);
effectsSDK.onReady = () {
    effectsSDK.run();
    final outputStream = effectsSDK.getStream();
};
```

More usage details can be found in: **Example/lib/main.dart**.

## How to run example

To run example provide environment variable `CUSTOMER_ID` with your customer id.
```sh
git clone git@github.com:EffectsSDK/audio-flutter-wrapper.git
cd audio-flutter-wrapper
flutter pub get
cd example
flutter run --dart-define=CUSTOMER_ID=$CUSTOMER_ID
```

## Class Reference

### class AudioEffectsSDK

**AudioEffectsSDK**(**String** *customerID*)  
Constructs an instance of **AudioEffectsSDK**  
Arguments:
- **String** *customerID* - ID gotten from [effectssdk.com](https://effectssdk.com/contacts)

onReady -\> **Function**?  
The property holds a function that is called on SDK readiness.  
Note: An instance can not get ready before `useStream` is called with the correct argument.

onError -\> **Function**(**ErrorObject** *e*)?  
Pass onError callback to ErrorBus. See [ErrorObject](#class-errorobject).  

onUnableToProcessLive -\> **Function**?  
The property holds a function that is called on SDK stopped processing because can not process audio stream fast enought.

useStream(**MediaStream** *stream*) -\> **void**  
Puts the stream into SDK to process.  
Arguments:
- **MediaStream** *stream* - a WebRTC stream to be processed.

isReady -\> **bool**  
The property is true when SDK is ready to process video, method `run` can be called, and features can be activated.

clear() -\> **void**  
Disables enabled features and stops processing.

**NOTE**: Don't use next methods until this instance is ready.

preload() -\> **void**  
Ability to preload all required resourses specified in config. This functionality make the initialization faster.  
Should be started after all configs are passed to *config* method.
Starts prealoading asynchronous.

run()-\> **void**  
Starts processing.  
Note: The stream that was returned by `getStream()` started providing media.  

getStream() -\> **MediaStream**  
Returns a stream with applied effects.

setDenoisePower(**double** *power*) -\> **void**  
Set denoise power in the runtime. Avilable only for balanced preset.

setDroppedFramesThreshold(**int** *threshold*) -\> **void**  
Set the acceptable delay in processing in milliseconds. This parameter is used to understand that SDK can handle audio in real-time.  
This parameter doesn't take into account the initial audio chunk required by preset to start processing.  
If there is the delay in frame processing higher than provided threshold - SDK will pass an error with **ErrorCode**.droppedFrames in onError callback.  
If you get such error - this mean SDK can't handle audio in real-time on the current hardware, and you should stop the SDK.  
Arguments:
- **int** *threshold* - Acceptable delay in processing in milliseconds.

setPreset(**ModelPreset** *preset*, {int? *sampleRate*}) -\> **Future**  
Set preset. If models are not loaded then loads model asynchronously and use them when loaded.  
During loading previous models are used.  
Arguments:
- **ModelPreset** *preset* -  Default is speed.
- **int**? *sampleRate* - Default is 16000. *quality* and *speed* presets only support 16000. *balanced* preset supports 16000|32000|44100|48000.

### enum ModelPreset  
Controls set of using models.

Available values:  
* quality
* balanced
* speed

### class Config 

apiUrl -\> **String**?  
Custom url for sdk authentication, applicable for on-premises solutions.  

sdkUrl -\> **String**?  
Specifies the url to SDK folder in case when you host model files by yourself.  

preset -\> **ModelPreset**?  

sampleRate -\> **int**?  - see *setPreset* method for sampleRate limitations.  

droppedFramesThresholdMs -\> **int**?  

wasmPaths -\> **Map**\<**String**, **String**\>  
Currently wasm files are loading from the same directory where SDK is placed, but custom urls also supported (for example you can load it from CDNs)

```dart
config.wasmPaths = {
    'ort-wasm.wasm': 'url',
    'ort-wasm-simd.wasm': 'url',
    'ort-wasm-threaded.wasm': 'url'
    'ort-wasm-simd-threaded.wasm': 'url' 
};
```

### class ErrorObject  
Holds a description of an Error, warning or info.  

message -\> **String**  

type -\> **ErrorType**  

code -\> **ErrorCode**?  

emitter -\> **ErrorEmitter**?  

cause -\> **Object**?  

### enum ErrorCode 

Available values:  
* droppedFrames - SDK is not able to process the aduio stream in realtime.

### enum ErrorType 
  
Available values:
* info
* warning
* error

### enum ErrorEmitter 

Available values:
* atsvb
* streamProcessor
* mlInference
* model
* webWorklet
* webWorker
