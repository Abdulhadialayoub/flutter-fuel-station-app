import 'dart:async';
import '../services/exceptions.dart';

/// Helper class for implementing retry logic with exponential backoff
class RetryHelper {
  /// Execute a function with retry logic
  /// 
  /// Parameters:
  /// - [fn]: The async function to execute
  /// - [maxAttempts]: Maximum number of retry attempts (default: 3)
  /// - [initialDelay]: Initial delay before first retry in milliseconds (default: 1000ms)
  /// - [maxDelay]: Maximum delay between retries in milliseconds (default: 10000ms)
  /// - [shouldRetry]: Optional function to determine if error should trigger retry
  /// 
  /// Returns the result of the function if successful
  /// Throws the last error if all retries fail
  static Future<T> retry<T>({
    required Future<T> Function() fn,
    int maxAttempts = 3,
    int initialDelay = 1000,
    int maxDelay = 10000,
    bool Function(dynamic error)? shouldRetry,
  }) async {
    int attempt = 0;
    int delay = initialDelay;

    while (true) {
      attempt++;
      
      try {
        return await fn();
      } catch (e) {
        // Check if we should retry this error
        final canRetry = shouldRetry?.call(e) ?? _defaultShouldRetry(e);
        
        // If this was the last attempt or we shouldn't retry, throw the error
        if (attempt >= maxAttempts || !canRetry) {
          rethrow;
        }

        // Wait before retrying with exponential backoff
        await Future.delayed(Duration(milliseconds: delay));
        
        // Increase delay for next attempt (exponential backoff)
        delay = (delay * 2).clamp(initialDelay, maxDelay);
      }
    }
  }

  /// Default logic to determine if an error should trigger a retry
  /// 
  /// Retries on:
  /// - NetworkException (no internet, timeout)
  /// - TimeoutException
  /// 
  /// Does not retry on:
  /// - DatabaseException (likely a data/query issue)
  /// - OSRMException (likely an API issue)
  /// - Other exceptions
  static bool _defaultShouldRetry(dynamic error) {
    return error is NetworkException || error is TimeoutException;
  }
}
