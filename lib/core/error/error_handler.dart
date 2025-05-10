import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

/// Centralized error handling for the application
class ErrorHandler {
  /// Log an exception to the console
  static void logError(String context, dynamic error, StackTrace? stackTrace) {
    if (kDebugMode) {
      print('[$context] Error: $error');
      if (stackTrace != null) {
        print('StackTrace: $stackTrace');
      }
    }
    
    // TODO: Add crash reporting service integration here
  }
  
  /// Show a snackbar with error message
  static void showError(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 3),
      ),
    );
  }
  
  /// Show a dialog with error details
  static void showErrorDialog(BuildContext context, String title, String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('확인'),
          ),
        ],
      ),
    );
  }
}

/// Class representing the result of an operation that may succeed or fail
class Result<T> {
  final T? _value;
  final Exception? _error;
  
  const Result.success(T value)
      : _value = value,
        _error = null;
  
  const Result.failure(Exception error)
      : _error = error,
        _value = null;
  
  bool get isSuccess => _error == null;
  bool get isFailure => _error != null;
  
  T get value => _value as T;
  Exception get error => _error!;
  
  R fold<R>(R Function(T value) onSuccess, R Function(Exception error) onFailure) {
    if (isSuccess) {
      return onSuccess(_value as T);
    } else {
      return onFailure(_error!);
    }
  }
}
