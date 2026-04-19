sealed class Result<T> {
  const Result();
}

class Success<T> extends Result<T> {
  const Success(this.value);

  final T value;
}

class ErrorResult<T> extends Result<T> {
  const ErrorResult(this.failure);

  final Object failure;
}
