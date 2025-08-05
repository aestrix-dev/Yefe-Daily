abstract class ApiResult<T> {
  const ApiResult();
}

class Success<T> extends ApiResult<T> {
  final T data;
  final String? message;

  const Success(this.data, {this.message});
}

class Failure<T> extends ApiResult<T> {
  final String error;
  final int? statusCode;

  const Failure(this.error, {this.statusCode});
}

// Extension for easier handling
extension ApiResultX<T> on ApiResult<T> {
  bool get isSuccess => this is Success<T>;
  bool get isFailure => this is Failure<T>;

  T? get data => isSuccess ? (this as Success<T>).data : null;
  String? get error => isFailure ? (this as Failure<T>).error : null;

  // Handle result with callbacks
  R when<R>({
    required R Function(T data) success,
    required R Function(String error) failure,
  }) {
    if (this is Success<T>) {
      return success((this as Success<T>).data);
    } else {
      return failure((this as Failure<T>).error);
    }
  }

  // Handle result with optional callbacks
  void whenOrNull({
    void Function(T data)? success,
    void Function(String error)? failure,
  }) {
    if (this is Success<T> && success != null) {
      success((this as Success<T>).data);
    } else if (this is Failure<T> && failure != null) {
      failure((this as Failure<T>).error);
    }
  }
}
