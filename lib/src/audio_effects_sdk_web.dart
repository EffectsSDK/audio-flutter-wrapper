import 'dart:async';
import 'dart:html' as html show window;
import 'dart:js' as js;
import 'dart:js_util' as jsutil;

import 'package:dart_webrtc/src/media_stream_impl.dart' as dartrtc;
import 'package:flutter_web_plugins/flutter_web_plugins.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart' as webrtc;

import 'audio_effects_sdk_config.dart';
import 'audio_effects_sdk_enums.dart';
import 'audio_effects_sdk_error.dart';
import 'audio_effects_sdk_platform_interface.dart';

Map<String, ErrorEmitter> webEmittersMap() {
  return {
    "atsvb": ErrorEmitter.atsvb,
    "stream_processor": ErrorEmitter.streamProcessor,
    "ml_inference": ErrorEmitter.mlInference,
    "model": ErrorEmitter.model,
    "worklet": ErrorEmitter.webWorklet,
    "worker": ErrorEmitter.webWorker,
  };
}

ErrorEmitter? webEmitterByName(String? name) {
  return (null != name)? webEmittersMap()[name]: null;
}

class WrapperContext {
  bool errorCallbackInstalled = false;
  Function? onUnableToProcessLive;
  Function(ErrorObject e)? onError;
}

class AudioEffectsSDKWeb extends AudioEffectsSDKPlatform {
  static const _defaultSampleRate = 16000;
  static const _wrapperContextSymbol = Symbol("atsvb.WrapperContext");

  AudioEffectsSDKWeb();

  static void registerWith(Registrar registrar) {
    AudioEffectsSDKPlatform.instance = AudioEffectsSDKWeb();
  }

  @override
  Object createContext(String customerID) {
    if (!jsutil.hasProperty(html.window, "atsvb")) {
      throw StateError('atsvb has not been loaded.'
          ' Please, add <script crossorigin="anonymous" src="https://effectssdk.ai/sdk/audio/dev/2.3.5/atsvb-web.js"></script> to your index.html');
    }

    final tsvb = jsutil.getProperty(html.window, "atsvb");
    Object sdkContext = jsutil.callConstructor(tsvb, [customerID]);
    jsutil.setProperty(sdkContext, _wrapperContextSymbol, WrapperContext());
    return sdkContext;
  }

  @override
  void setOnReadyCallback(Object sdkContext, Function? callback) {
    jsutil.setProperty(sdkContext, "onReady", _jsAllowInterop(callback));
  }

  @override
  void setOnUnableToProcessLiveCallback(Object sdkContext, Function? callback) {
    _wrapperContext(sdkContext).onUnableToProcessLive = callback;
    _updateInstalledErrorCallback(sdkContext);
  }

  @override
  void config(Object sdkContext, Config config) {
    final jsConfig = jsutil.newObject();
    _setPropertyIfNotNull(jsConfig, "api_url", config.apiUrl);
    _setPropertyIfNotNull(jsConfig, "sdk_url", config.sdkUrl);
    _setPropertyIfNotNull(jsConfig, "preset", config.preset?.name);
    _setPropertyIfNotNull(jsConfig, "sample_rate", config.sampleRate);
    _setPropertyIfNotNull(jsConfig, "dropped_frames_threshold", config.droppedFramesThresholdMs);

    if (null != config.wasmPaths) {
      final jsModels = jsutil.newObject();
      config.wasmPaths?.forEach((String model, String url) {
        jsutil.setProperty(jsModels, model, url);
      });
      jsutil.setProperty(jsConfig, "wasmPaths", jsModels);
    }

    _callJSMethod(sdkContext, "config", [jsConfig]);
  }

  @override
  void useStream(Object sdkContext, webrtc.MediaStream stream) {
    final streamWeb = stream as dartrtc.MediaStreamWeb;
    final jsStream = streamWeb.jsStream;
    _callJSMethod(sdkContext, "useStream", [jsStream]);
  }

  @override
  webrtc.MediaStream getStream(Object sdkContext) {
    final jsStream = _callJSMethod(sdkContext, "getStream", []);
    return dartrtc.MediaStreamWeb(jsStream, "local");
  }

  @override
  void clear(Object sdkContext) {
    _callJSMethod(sdkContext, "clear", []);
  }

  @override
  void preload(Object sdkContext) {
    _callJSMethod(sdkContext, "preload", []);
  }

  @override
  void run(Object sdkContext) {
    _callJSMethod(sdkContext, "run", []);
  }

  @override
  void stop(Object sdkContext) {
    _callJSMethod(sdkContext, "stop", []);
  }

  @override
  void setDenoisePower(Object sdkContext, double power) {
    _callJSMethod(sdkContext, "stop", [power]);
  }

  @override
  void setDroppedFramesThreshold(Object sdkContext, int threshold) {
    _callJSMethod(sdkContext, "setDroppedFramesThreshold", [threshold]);
  }

  @override
  Future<void> setPreset(Object sdkContext, ModelPreset preset, int? sampleRate) {
    sampleRate = (null != sampleRate)? sampleRate : _defaultSampleRate;
    final error = _checkPresetForError(preset, sampleRate);
    if (null != error) {
      return Future(() => throw error);
    }

    Object resultPromise = _callJSMethod(
      sdkContext, 
      "setPreset", 
      [preset.name, sampleRate]
    );

    return jsutil.promiseToFuture(resultPromise);
  }
  
  @override
  void setOnErrorCallback(Object sdkContext, Function(ErrorObject e)? callback) {
    _wrapperContext(sdkContext).onError = callback;
    _updateInstalledErrorCallback(sdkContext);
  }

  T _callJSMethod<T>(Object object, String method, List<dynamic> args) {
    return jsutil.callMethod(object, method, args);
  }

  Function? _jsAllowInterop(Function? function) {
    return (null != function)? js.allowInterop(function) : null;
  }

  void _setPropertyIfNotNull(Object object, String name, dynamic value) {
    if (null == value) {
      return;
    }

    jsutil.setProperty(object, name, value);
  }

  ArgumentError? _checkPresetForError(ModelPreset preset, int sampleRate) {
    final supportedRates = _supportedSampleRateMap()[preset]!;
    if (supportedRates.contains(sampleRate)) {
      return null;
    }

    String supportedRatesStr = supportedRates.map((rate)=> rate.toString()).join("|");
    return ArgumentError(
      "Unsupported sample rate ($sampleRate)."
      " Preset '${preset.name}' supports $supportedRatesStr"
    );
  }

  Map<ModelPreset, List<int>> _supportedSampleRateMap() {
    return {
      ModelPreset.speed: [16000],
      ModelPreset.balanced: [16000, 32000, 44100, 48000],
      ModelPreset.quality: [16000]
    };
  }

  T? _getOptionalProperty<T>(Object o, Object name) {
    return jsutil.hasProperty(o, name)? jsutil.getProperty<T>(o, name) : null;
  }

  ErrorCode? _errorCode(int? code) {
    if (null == code) {
      return null;
    }

    for (final e in ErrorCode.values) {
      if (e.code == code) {
        return e;
      }
    }

    return null;
  }

  void _updateInstalledErrorCallback(Object sdkContext) {
    final wrapperContext = _wrapperContext(sdkContext);
    bool neededErrorCallback = 
      (null != wrapperContext.onError) || 
      (null != wrapperContext.onUnableToProcessLive);

    if (neededErrorCallback && !wrapperContext.errorCallbackInstalled) {
      _installErrorCallback(sdkContext);
    }
      
    if (!neededErrorCallback && wrapperContext.errorCallbackInstalled) {
      _uninstallErrorCallback(sdkContext);
    }
  }

  void _installErrorCallback(Object sdkContext) {
    final wrapperContext = _wrapperContext(sdkContext);
    
    jsCallback(Object e) {
      final code = _getOptionalProperty<int>(e, "code");
      if (ErrorCode.droppedFrames.code == code) {
        Future(() {
          wrapperContext.onUnableToProcessLive?.call();
        });
      }

      if (null == wrapperContext.onError) {
        return;
      }

      final typeName = jsutil.getProperty<String>(e, "type");
      final errorType = ErrorType.values.firstWhere((element) => element.name == typeName);
      final errorCode = _errorCode(code);
      final emitter = webEmitterByName(
        _getOptionalProperty<String>(e, "emitter")
      );

      final errorObject = ErrorObject(
        message: jsutil.getProperty<String>(e, "message"),
        type: errorType,
        code: errorCode,
        emitter: emitter,
        cause: jsutil.dartify(_getOptionalProperty(e, "cause"))
      );

      wrapperContext.onError?.call(errorObject);
    }
    _callJSMethod(sdkContext, "onError", [_jsAllowInterop(jsCallback)]);
    wrapperContext.errorCallbackInstalled = true;
  }

  void _uninstallErrorCallback(Object sdkContext) {
    _callJSMethod(sdkContext, "onError", [null]);
    _wrapperContext(sdkContext).errorCallbackInstalled = false;
  }

  WrapperContext _wrapperContext(Object sdkContext) {
    return jsutil.getProperty<WrapperContext>(sdkContext, _wrapperContextSymbol);
  }
}
