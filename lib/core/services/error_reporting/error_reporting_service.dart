import 'app_error.dart';

abstract class ErrorReportingService {
  Future<void> initialize();
  Future<void> reportError(AppError error);
  Future<void> recordLog(String message);
  Future<void> setUserId(String userId);
  Future<void> setCustomKey(String key, dynamic value);
}
