import 'package:flutter/foundation.dart';
import 'logger.dart';

/// Custom exception class for API errors
class ApiException implements Exception {
  final String message;
  final int? statusCode;
  final String? originalError;

  ApiException(
    this.message, {
    this.statusCode,
    this.originalError,
  });

  @override
  String toString() => message;
}

/// Handles errors securely by providing user-friendly messages
/// while logging technical details only in debug mode
class SecureErrorHandler {
  /// Converts technical errors into user-friendly messages
  /// Never exposes internal system details to users
  static String getUserFriendlyMessage(dynamic error) {
    final errorString = error.toString().toLowerCase();

    // Network errors
    if (errorString.contains('socketexception') ||
        errorString.contains('failed host lookup') ||
        errorString.contains('network is unreachable')) {
      return 'Impossible de se connecter au serveur. Vérifiez votre connexion réseau.';
    }

    if (errorString.contains('timeoutexception') ||
        errorString.contains('timeout')) {
      return 'La requête a pris trop de temps. Veuillez réessayer.';
    }

    // HTTP status code errors
    if (errorString.contains('401') ||
        errorString.contains('api key invalide') ||
        errorString.contains('unauthorized')) {
      return 'Identifiants invalides. Veuillez vérifier votre clé API.';
    }

    if (errorString.contains('403') ||
        errorString.contains('forbidden') ||
        errorString.contains('permissions insuffisantes')) {
      return 'Accès refusé. Vous n\'avez pas les permissions nécessaires.';
    }

    if (errorString.contains('404') || errorString.contains('not found')) {
      return 'Ressource non trouvée. Vérifiez l\'URL de l\'instance.';
    }

    if (errorString.contains('429') || errorString.contains('too many')) {
      return 'Trop de requêtes. Veuillez patienter quelques instants.';
    }

    if (errorString.contains('500') ||
        errorString.contains('502') ||
        errorString.contains('503') ||
        errorString.contains('504') ||
        errorString.contains('internal server error') ||
        errorString.contains('bad gateway') ||
        errorString.contains('service unavailable')) {
      return 'Le serveur rencontre des difficultés. Réessayez plus tard.';
    }

    // Format errors
    if (errorString.contains('formatexception') ||
        errorString.contains('url malformée')) {
      return 'Format d\'URL invalide. Vérifiez l\'adresse saisie.';
    }

    // JSON parsing errors
    if (errorString.contains('json') ||
        errorString.contains('unexpected character')) {
      return 'Erreur de traitement des données. Réessayez.';
    }

    // Certificate errors
    if (errorString.contains('certificate') ||
        errorString.contains('handshake')) {
      return 'Erreur de sécurité de connexion. Vérifiez l\'URL.';
    }

    // Generic fallback - never expose technical details
    return 'Une erreur s\'est produite. Veuillez réessayer.';
  }

  /// Logs errors securely with full details in debug mode
  /// and minimal information in production
  static void logSecurely(
    dynamic error, {
    String? context,
    StackTrace? stackTrace,
  }) {
    if (kDebugMode) {
      // Full details in debug mode
      Logger.error(
        'Error${context != null ? " in $context" : ""}',
        error: error,
        stackTrace: stackTrace,
      );
    } else {
      // Minimal logging in production
      Logger.error('Error occurred${context != null ? " in $context" : ""}');
      // TODO: Send to remote logging service (Sentry, Firebase, etc.)
    }
  }

  /// Combines logging and user message generation
  static String handleError(
    dynamic error, {
    String? context,
    StackTrace? stackTrace,
  }) {
    logSecurely(error, context: context, stackTrace: stackTrace);
    return getUserFriendlyMessage(error);
  }
}