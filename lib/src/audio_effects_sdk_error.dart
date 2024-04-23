

enum ErrorCode {
  droppedFrames(code: 1001);

  const ErrorCode({required this.code});

  final int code;
}

enum ErrorType {
  info,
  warning,
  error
}

enum ErrorEmitter {
  atsvb,
  streamProcessor,
  mlInference,
  model,
  webWorklet,
  webWorker,
}

class ErrorObject {
  final String message;
  final ErrorType type;
  final ErrorCode? code;
  final ErrorEmitter? emitter;
  final Object? cause;

  ErrorObject({
    required this.message,
    required this.type,
    this.code,
    this.emitter,
    this.cause
  });
}