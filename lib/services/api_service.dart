import 'dart:convert';
import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:http/io_client.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../utils/logger.dart';
import '../utils/secure_error_handler.dart';

class ApiService {
  static const String baseUrl = '/api/v3';

  // Use secure storage for sensitive credentials
  final _secureStorage = const FlutterSecureStorage(
    aOptions: AndroidOptions(
      encryptedSharedPreferences: true,
    ),
  );

  String? _apiKey;
  String? _instanceUrl;
  bool _useProxy = false;
  String? _proxyUrl;

  // Rate limiting state
  final Map<String, DateTime> _lastRequestTime = {};
  final Map<String, int> _requestCount = {};
  static const int _maxRequestsPerMinute = 60;
  static const Duration _minRequestInterval = Duration(milliseconds: 100);

  // Session timeout state
  DateTime? _lastActivityTime;
  static const Duration _inactivityTimeout = Duration(minutes: 30);
  Timer? _sessionTimer;

  // HTTP client with certificate validation
  http.Client? _httpClient;

  // Cache for responses
  final Map<String, Map<String, dynamic>> _cache = {};
  static const Duration _cacheExpiration = Duration(minutes: 5);
  final Map<String, DateTime> _cacheTimestamps = {};

  /// Initializes the service by loading credentials from secure storage
  Future<void> init() async {
    try {
      // Load credentials from secure storage
      _apiKey = await _secureStorage.read(key: 'api_key');
      _instanceUrl = await _secureStorage.read(key: 'instance_url');

      // Load non-sensitive settings from SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      _useProxy = prefs.getBool('use_proxy') ?? false;
      _proxyUrl = prefs.getString('proxy_url');

      // Check session timeout
      final lastActivityStr = prefs.getString('last_activity_time');
      if (lastActivityStr != null) {
        _lastActivityTime = DateTime.parse(lastActivityStr);

        final now = DateTime.now();
        final timeSinceLastActivity = now.difference(_lastActivityTime!);

        if (timeSinceLastActivity > _inactivityTimeout) {
          Logger.security('Session timed out due to inactivity');
          await clearCredentials();
          return;
        }
      }

      // Start session monitoring
      _startSessionMonitoring();

      if (_apiKey != null && _instanceUrl != null) {
        Logger.info('Credentials loaded successfully', tag: 'API');
      }
    } catch (e) {
      Logger.error('Error initializing API service', error: e, tag: 'API');
    }
  }

  /// Starts monitoring session for timeout
  void _startSessionMonitoring() {
    _sessionTimer?.cancel();
    _sessionTimer = Timer.periodic(const Duration(minutes: 1), (timer) async {
      if (_lastActivityTime != null) {
        final now = DateTime.now();
        final inactive = now.difference(_lastActivityTime!);

        if (inactive > _inactivityTimeout) {
          Logger.security('Auto-logout due to inactivity');
          await clearCredentials();
          timer.cancel();
          // TODO: Notify UI to redirect to login
        }
      }
    });
  }

  /// Updates last activity timestamp
  Future<void> _updateActivity() async {
    _lastActivityTime = DateTime.now();

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
        'last_activity_time',
        _lastActivityTime!.toIso8601String(),
      );
    } catch (e) {
      Logger.warn('Failed to update activity time', tag: 'API');
    }
  }

  /// Validates and normalizes URLs
  String _validateAndNormalizeUrl(
    String url, {
    required bool allowHttp,
    required bool allowPrivateIp,
  }) {
    if (url.isEmpty) {
      throw ApiException('URL ne peut pas être vide');
    }

    // Add protocol if missing
    String normalized = url;
    if (!normalized.startsWith('http://') &&
        !normalized.startsWith('https://')) {
      normalized = 'https://$normalized';
    }

    // Parse and validate URL
    final Uri uri;
    try {
      uri = Uri.parse(normalized);
    } catch (e) {
      throw ApiException('URL invalide: format incorrect');
    }

    // Validate protocol
    if (uri.scheme != 'https' && uri.scheme != 'http') {
      throw ApiException('Protocole invalide: utilisez http:// ou https://');
    }

    if (!allowHttp && uri.scheme == 'http') {
      Logger.warn('HTTP URLs are insecure in production', tag: 'Security');
      if (!kDebugMode) {
        throw ApiException(
          'HTTP non autorisé: utilisez HTTPS pour plus de sécurité',
        );
      }
    }

    // Validate hostname exists
    if (uri.host.isEmpty) {
      throw ApiException('URL invalide: nom d\'hôte manquant');
    }

    // Validate hostname format
    final hostnameRegex = RegExp(
      r'^[a-zA-Z0-9]([a-zA-Z0-9\-]{0,61}[a-zA-Z0-9])?(\.[a-zA-Z0-9]([a-zA-Z0-9\-]{0,61}[a-zA-Z0-9])?)*$',
    );

    // Check if it's an IP address
    final ipRegex = RegExp(r'^(\d{1,3}\.){3}\d{1,3}$');
    final isIpAddress = ipRegex.hasMatch(uri.host);

    if (!isIpAddress &&
        !hostnameRegex.hasMatch(uri.host) &&
        uri.host != 'localhost') {
      throw ApiException('URL invalide: format de nom d\'hôte incorrect');
    }

    // Prevent private IP ranges in production
    if (!allowPrivateIp &&
        (uri.host == 'localhost' || uri.host == '127.0.0.1')) {
      if (!kDebugMode) {
        throw ApiException('localhost n\'est pas autorisé en production');
      }
    }

    if (!allowPrivateIp && isIpAddress) {
      final parts = uri.host.split('.');
      final first = int.tryParse(parts[0]) ?? 0;
      final second = int.tryParse(parts[1]) ?? 0;

      // Check for private IP ranges
      if (first == 10 ||
          (first == 172 && second >= 16 && second <= 31) ||
          (first == 192 && second == 168) ||
          (first == 169 && second == 254)) {
        if (!kDebugMode) {
          throw ApiException('Adresses IP privées non autorisées en production');
        }
      }
    }

    // Remove trailing slashes
    return normalized.replaceAll(RegExp(r'/+$'), '');
  }

  /// Validates API key format
  bool _isValidApiKey(String apiKey) {
    if (apiKey.isEmpty) return false;

    // OpenProject API keys are typically 40+ characters of alphanumeric
    if (apiKey.length < 20) {
      return false;
    }

    // Basic format validation
    final validFormat = RegExp(r'^[a-zA-Z0-9]+$');
    return validFormat.hasMatch(apiKey);
  }

  /// Saves credentials securely
  Future<void> setCredentials(
    String instanceUrl,
    String apiKey, {
    bool useProxy = false,
    String? proxyUrl,
  }) async {
    // Validate and normalize instance URL
    final normalizedInstance = _validateAndNormalizeUrl(
      instanceUrl.trim(),
      allowHttp: false, // Force HTTPS for instance URLs
      allowPrivateIp: kDebugMode, // Only allow in debug mode
    );

    // Validate API key
    if (!_isValidApiKey(apiKey)) {
      throw ApiException('Format de clé API invalide');
    }

    // Validate proxy URL if provided
    String? normalizedProxy;
    if (useProxy && proxyUrl != null && proxyUrl.isNotEmpty) {
      normalizedProxy = _validateAndNormalizeUrl(
        proxyUrl.trim(),
        allowHttp: kDebugMode, // Dev proxies often use HTTP
        allowPrivateIp: kDebugMode, // Only allow in debug mode
      );

      // Warn about HTTP proxies
      final proxyUri = Uri.parse(normalizedProxy);
      if (proxyUri.scheme == 'http') {
        Logger.warn(
          'Using insecure HTTP proxy. Credentials may be exposed.',
          tag: 'Security',
        );
        if (!kDebugMode) {
          throw ApiException('HTTP proxies not allowed in production. Use HTTPS.');
        }
      }
    }

    // Save sensitive credentials to secure storage
    await _secureStorage.write(key: 'instance_url', value: normalizedInstance);
    await _secureStorage.write(key: 'api_key', value: apiKey);

    // Save non-sensitive settings to SharedPreferences
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('use_proxy', useProxy);
    if (useProxy && normalizedProxy != null && normalizedProxy.isNotEmpty) {
      await prefs.setString('proxy_url', normalizedProxy);
    } else {
      await prefs.remove('proxy_url');
    }

    // Update internal variables
    _instanceUrl = normalizedInstance;
    _apiKey = apiKey;
    _useProxy = useProxy;
    _proxyUrl = normalizedProxy;

    // Clear cache on credential change
    _cache.clear();
    _cacheTimestamps.clear();

    Logger.success('Credentials saved securely', tag: 'API');
  }

  /// Checks if credentials are configured
  bool get hasCredentials {
    return _apiKey != null &&
        _instanceUrl != null &&
        _apiKey!.isNotEmpty &&
        _instanceUrl!.isNotEmpty;
  }

  /// Clears all credentials and session data
  Future<void> clearCredentials() async {
    try {
      // Clear secure storage
      await _secureStorage.delete(key: 'api_key');
      await _secureStorage.delete(key: 'instance_url');

      // Clear SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('use_proxy');
      await prefs.remove('proxy_url');
      await prefs.remove('last_activity_time');

      // Reset internal state
      _apiKey = null;
      _instanceUrl = null;
      _useProxy = false;
      _proxyUrl = null;
      _lastActivityTime = null;

      // Clear cache
      _cache.clear();
      _cacheTimestamps.clear();

      // Cancel session timer
      _sessionTimer?.cancel();

      Logger.info('Credentials cleared', tag: 'API');
    } catch (e) {
      Logger.error('Error clearing credentials', error: e, tag: 'API');
    }
  }

  /// Determines if proxy should be used
  bool _shouldUseProxy() {
    // Development: Use proxy if configured
    if (_useProxy && _proxyUrl != null && _proxyUrl!.isNotEmpty) {
      // If URL contains localhost/local IPs -> Dev mode
      if (_proxyUrl!.contains('localhost') ||
          _proxyUrl!.contains('127.0.0.1') ||
          _proxyUrl!.contains('192.168.') ||
          _proxyUrl!.contains('172.')) {
        Logger.info('Using development proxy: $_proxyUrl', tag: 'API');
        return true;
      }
    }

    // Mobile apps don't need proxy (no CORS issues)
    if (!kIsWeb) {
      Logger.info('Mobile app: Direct API access', tag: 'API');
      return false;
    }

    // Web: Use proxy if configured
    if (kIsWeb && _useProxy && _proxyUrl != null) {
      Logger.info('Web app: Using proxy: $_proxyUrl', tag: 'API');
      return true;
    }

    return false;
  }

  /// Gets or creates HTTP client with certificate validation
  http.Client _getHttpClient() {
    if (_httpClient != null) return _httpClient!;

    // For production, implement certificate validation
    if (!kDebugMode && !kIsWeb) {
      try {
        final client = HttpClient();

        // Add certificate validation callback
        client.badCertificateCallback = (cert, host, port) {
          // In production, always validate certificates
          Logger.warn(
            'Certificate validation failed for $host:$port',
            tag: 'Security',
          );
          return false; // Reject invalid certificates in production
        };

        _httpClient = IOClient(client);
      } catch (e) {
        Logger.error('Error creating secure HTTP client', error: e);
        _httpClient = http.Client();
      }
    } else {
      _httpClient = http.Client();
    }

    return _httpClient!;
  }

  /// Enforces rate limiting before making requests
  Future<void> _enforceRateLimit(String endpoint) async {
    final now = DateTime.now();
    const key = 'api_request';

    // Check minimum interval between requests
    if (_lastRequestTime.containsKey(key)) {
      final timeSinceLastRequest = now.difference(_lastRequestTime[key]!);
      if (timeSinceLastRequest < _minRequestInterval) {
        final waitTime = _minRequestInterval - timeSinceLastRequest;
        await Future.delayed(waitTime);
      }
    }

    // Check requests per minute limit
    final oneMinuteAgo = now.subtract(const Duration(minutes: 1));
    _requestCount.removeWhere(
      (k, v) => _lastRequestTime[k]!.isBefore(oneMinuteAgo),
    );

    final recentRequests =
        _requestCount.values.fold<int>(0, (sum, count) => sum + count);

    if (recentRequests >= _maxRequestsPerMinute) {
      throw ApiException(
        'Trop de requêtes. Veuillez patienter avant de réessayer.',
      );
    }

    // Update tracking
    _lastRequestTime[key] = now;
    _requestCount[key] = (_requestCount[key] ?? 0) + 1;
  }

  /// Makes an HTTP GET request with security measures
  Future<http.Response> _get(
    String endpoint, {
    int maxResponseSize = 10 * 1024 * 1024,
  }) async {
    if (_apiKey == null || _instanceUrl == null) {
      throw ApiException('Credentials manquantes');
    }

    // Update activity timestamp
    await _updateActivity();

    // Enforce rate limiting
    await _enforceRateLimit(endpoint);

    // Determine URL strategy
    final selectedBase = _shouldUseProxy() ? _proxyUrl! : _instanceUrl!;
    final cleanBase = selectedBase.replaceAll(RegExp(r'/+$'), '');
    final cleanEndpoint = endpoint.startsWith('/') ? endpoint : '/$endpoint';
    final url = '$cleanBase$baseUrl$cleanEndpoint';

    // Build authentication header
    final authString = 'apikey:$_apiKey';
    final auth = base64Encode(utf8.encode(authString));

    final headers = {
      'Authorization': 'Basic $auth',
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };

    // Secure logging - never expose credentials
    Logger.api('GET: $url');

    try {
      final client = _getHttpClient();
      final response = await client
          .get(Uri.parse(url), headers: headers)
          .timeout(const Duration(seconds: 30));

      Logger.info('Response status: ${response.statusCode}', tag: 'API');

      // Check response size
      if (response.contentLength != null &&
          response.contentLength! > maxResponseSize) {
        throw ApiException('Response too large: ${response.contentLength} bytes');
      }

      if (response.body.length > maxResponseSize) {
        throw ApiException('Response body exceeds size limit');
      }

      // Handle error status codes
      if (response.statusCode == 401) {
        throw ApiException('API Key invalide', statusCode: 401);
      } else if (response.statusCode == 403) {
        throw ApiException('Permissions insuffisantes', statusCode: 403);
      } else if (response.statusCode == 404) {
        throw ApiException('Ressource non trouvée', statusCode: 404);
      } else if (response.statusCode == 429) {
        throw ApiException(
          'Trop de requêtes. Patientez quelques instants.',
          statusCode: 429,
        );
      } else if (response.statusCode >= 500) {
        throw ApiException(
          'Erreur serveur',
          statusCode: response.statusCode,
        );
      } else if (response.statusCode != 200) {
        SecureErrorHandler.logSecurely(
          'HTTP ${response.statusCode}',
          context: 'API GET $endpoint',
        );
        throw ApiException(
          'Erreur serveur',
          statusCode: response.statusCode,
        );
      }

      return response;
    } on TimeoutException {
      throw ApiException('La requête a pris trop de temps');
    } on SocketException {
      throw ApiException('Erreur de connexion réseau');
    } on FormatException catch (e) {
      SecureErrorHandler.logSecurely(e, context: 'URL parsing');
      throw ApiException('URL malformée');
    } catch (e) {
      if (e is ApiException) rethrow;
      SecureErrorHandler.logSecurely(e, context: 'API request');
      throw ApiException('Erreur de connexion');
    }
  }

  /// Tests connection to the API
  Future<bool> testConnection() async {
    try {
      await _get('/projects');
      return true;
    } catch (e) {
      Logger.error('Connection test failed', error: e, tag: 'API');
      return false;
    }
  }

  /// Gets current user information
  Future<Map<String, dynamic>?> getCurrentUser() async {
    try {
      final response = await _get('/users/me');
      final data = jsonDecode(response.body);
      return data;
    } catch (e) {
      SecureErrorHandler.logSecurely(e, context: 'getCurrentUser');
      return null;
    }
  }

  /// Gets list of projects
  Future<List<Map<String, dynamic>>> getProjects() async {
    try {
      final response = await _get('/projects');
      final data = jsonDecode(response.body);

      if (data['_embedded'] != null && data['_embedded']['elements'] != null) {
        return List<Map<String, dynamic>>.from(data['_embedded']['elements']);
      }

      return [];
    } catch (e) {
      SecureErrorHandler.logSecurely(e, context: 'getProjects');
      throw ApiException('Impossible de récupérer les projets');
    }
  }

  /// Gets work packages for a project
  Future<List<Map<String, dynamic>>> getWorkPackages(int projectId) async {
    if (projectId <= 0) {
      throw ArgumentError('projectId doit être un entier positif');
    }

    try {
      final response = await _get(
        '/projects/$projectId/work_packages?pageSize=100',
      );
      final data = jsonDecode(response.body);

      if (data['_embedded'] != null && data['_embedded']['elements'] != null) {
        return List<Map<String, dynamic>>.from(data['_embedded']['elements']);
      }

      return [];
    } catch (e) {
      SecureErrorHandler.logSecurely(e, context: 'getWorkPackages');
      throw ApiException('Impossible de récupérer les work packages');
    }
  }

  /// Gets all work packages
  Future<List<Map<String, dynamic>>> getAllWorkPackages() async {
    try {
      final response = await _get('/work_packages?pageSize=100');
      final data = jsonDecode(response.body);

      if (data['_embedded'] != null && data['_embedded']['elements'] != null) {
        return List<Map<String, dynamic>>.from(data['_embedded']['elements']);
      }

      return [];
    } catch (e) {
      SecureErrorHandler.logSecurely(e, context: 'getAllWorkPackages');
      throw ApiException('Impossible de récupérer les work packages');
    }
  }

  /// Gets versions/sprints for a project
  Future<List<Map<String, dynamic>>> getVersions(int projectId) async {
    if (projectId <= 0) {
      throw ArgumentError('projectId doit être un entier positif');
    }

    try {
      final response = await _get('/projects/$projectId/versions');
      final data = jsonDecode(response.body);

      if (data['_embedded'] != null && data['_embedded']['elements'] != null) {
        return List<Map<String, dynamic>>.from(data['_embedded']['elements']);
      }

      return [];
    } catch (e) {
      SecureErrorHandler.logSecurely(e, context: 'getVersions');
      throw ApiException('Impossible de récupérer les versions');
    }
  }

  /// Gets available statuses
  Future<List<Map<String, dynamic>>> getStatuses() async {
    try {
      final response = await _get('/statuses');
      final data = jsonDecode(response.body);

      if (data['_embedded'] != null && data['_embedded']['elements'] != null) {
        return List<Map<String, dynamic>>.from(data['_embedded']['elements']);
      }

      return [];
    } catch (e) {
      SecureErrorHandler.logSecurely(e, context: 'getStatuses');
      throw ApiException('Impossible de récupérer les statuts');
    }
  }

  /// Gets time entries with secure filter construction
  Future<List<Map<String, dynamic>>> getTimeEntries({
    int? projectId,
    int? workPackageId,
  }) async {
    try {
      String endpoint = '/time_entries?pageSize=100';

      // Build filters safely using proper JSON encoding
      List<Map<String, dynamic>> filterObjects = [];

      if (projectId != null) {
        if (projectId <= 0) {
          throw ArgumentError('projectId doit être un entier positif');
        }
        filterObjects.add({
          "project_id": {
            "operator": "=",
            "values": ["$projectId"]
          }
        });
      }

      if (workPackageId != null) {
        if (workPackageId <= 0) {
          throw ArgumentError('workPackageId doit être un entier positif');
        }
        filterObjects.add({
          "work_package_id": {
            "operator": "=",
            "values": ["$workPackageId"]
          }
        });
      }

      if (filterObjects.isNotEmpty) {
        final filtersJson = jsonEncode(filterObjects);
        final encodedFilters = Uri.encodeComponent(filtersJson);
        endpoint += '&filters=$encodedFilters';
      }

      final response = await _get(endpoint);
      final data = jsonDecode(response.body);

      if (data['_embedded'] != null && data['_embedded']['elements'] != null) {
        return List<Map<String, dynamic>>.from(data['_embedded']['elements']);
      }

      return [];
    } catch (e) {
      SecureErrorHandler.logSecurely(e, context: 'getTimeEntries');
      throw ApiException('Impossible de récupérer les time entries');
    }
  }

  /// Generic GET method with caching
  Future<Map<String, dynamic>> get(String endpoint) async {
    // Check cache
    if (_cache.containsKey(endpoint)) {
      final cacheTime = _cacheTimestamps[endpoint];
      if (cacheTime != null &&
          DateTime.now().difference(cacheTime) < _cacheExpiration) {
        Logger.info('Using cached response for $endpoint', tag: 'API');
        return _cache[endpoint]!;
      }
    }

    try {
      final response = await _get(endpoint);
      final data = jsonDecode(response.body);

      // Cache successful responses
      _cache[endpoint] = data;
      _cacheTimestamps[endpoint] = DateTime.now();

      return data;
    } catch (e) {
      SecureErrorHandler.logSecurely(e, context: 'API GET $endpoint');
      throw ApiException('Erreur API');
    }
  }

  /// Clears the response cache
  void clearCache() {
    _cache.clear();
    _cacheTimestamps.clear();
    Logger.info('Cache cleared', tag: 'API');
  }

  /// Exposes API key (use with caution)
  String get apiKey => _apiKey ?? '';

  /// Exposes instance URL
  String get instanceUrl => _instanceUrl ?? '';

  /// Checks if using proxy
  bool get isUsingProxy => _shouldUseProxy();

  /// Cleanup resources
  void dispose() {
    _sessionTimer?.cancel();
    _httpClient?.close();
  }
}