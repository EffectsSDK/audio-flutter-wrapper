import 'dart:async';
import 'dart:html' as html show window;
import 'dart:js' as js;
import 'dart:js_util' as jsutil;

import 'package:dart_webrtc/src/media_stream_impl.dart' as dartrtc;
import 'package:flutter_web_plugins/flutter_web_plugins.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart' as webrtc;

import 'audio_effects_sdk_enums.dart';
import 'audio_effects_sdk_platform_interface.dart';

class AudioEffectsSDKWeb extends AudioEffectsSDKPlatform {
  AudioEffectsSDKWeb();

  static void registerWith(Registrar registrar) {
    AudioEffectsSDKPlatform.instance = AudioEffectsSDKWeb();
  }

  @override
  Object createContext(String customerID) {
    if (!jsutil.hasProperty(html.window, "atsvb")) {
      throw StateError('atsvb has not been loaded.'
          ' Please, add <script crossorigin="anonymous" src="https://effectssdk.com/sdk/audio/dist/atsvb-web-v1.2.10.js"></script> to your index.html');
    }

    final tsvb = jsutil.getProperty(html.window, "atsvb");
    Object sdkContext = jsutil.callConstructor(tsvb, [customerID]);
    return sdkContext;
  }

  @override
  void setOnReadyCallback(Object sdkContext, Function? callback) {
    jsutil.setProperty(sdkContext, "onReady", _jsAllowInterop(callback));
  }

  @override
  void setOnUnableToProcessLiveCallback(Object sdkContext, Function? callback) {
    jsutil.setProperty(
        sdkContext, "onUnableToProcessLive", _jsAllowInterop(callback));
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
  void run(Object sdkContext) {
    _callJSMethod(sdkContext, "run", []);
  }

  @override
  void stop(Object sdkContext) {
    _callJSMethod(sdkContext, "stop", []);
  }

  @override
  Future<void> setPreset(Object sdkContext, ModelPreset preset) {
    Object resultPromise =
        _callJSMethod(sdkContext, "setPreset", [preset.name]);

    final completer = Completer<void>();
    onComplete(unused) {
      completer.complete();
    }

    onCompleteError(e) {
      completer.completeError(e);
    }

    _callJSMethod(resultPromise, "then",
        [_jsAllowInterop(onComplete), _jsAllowInterop(onCompleteError)]);
    return completer.future;
  }

  T _callJSMethod<T>(Object object, String method, List<dynamic> args) {
    return jsutil.callMethod(object, method, args);
  }

  Function? _jsAllowInterop(Function? function) {
    if (null != function) {
      return js.allowInterop(function);
    } else {
      return null;
    }
  }
}
