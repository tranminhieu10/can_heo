import 'package:equatable/equatable.dart';

/// Base class cho tất cả failures trong app
abstract class Failure extends Equatable {
  final String message;
  final String? code;

  const Failure({required this.message, this.code});

  @override
  List<Object?> get props => [message, code];
}

/// Lỗi từ database/cache
class CacheFailure extends Failure {
  const CacheFailure({required super.message, super.code});
}

/// Lỗi từ server/API
class ServerFailure extends Failure {
  final int? statusCode;

  const ServerFailure({required super.message, super.code, this.statusCode});

  @override
  List<Object?> get props => [message, code, statusCode];
}

/// Lỗi kết nối mạng
class NetworkFailure extends Failure {
  const NetworkFailure({required super.message, super.code});
}

/// Lỗi validation dữ liệu
class ValidationFailure extends Failure {
  final Map<String, String>? fieldErrors;

  const ValidationFailure({required super.message, super.code, this.fieldErrors});

  @override
  List<Object?> get props => [message, code, fieldErrors];
}

/// Lỗi từ thiết bị cân
class ScaleFailure extends Failure {
  const ScaleFailure({required super.message, super.code});
}

/// Lỗi không tìm thấy dữ liệu
class NotFoundFailure extends Failure {
  const NotFoundFailure({required super.message, super.code});
}

/// Lỗi không xác định
class UnknownFailure extends Failure {
  final Object? originalError;

  const UnknownFailure({required super.message, super.code, this.originalError});

  @override
  List<Object?> get props => [message, code, originalError];
}
