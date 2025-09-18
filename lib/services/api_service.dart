import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class ApiService {
  static const String baseUrl = '/api/v3';
  String? _apiKey;
  String? _instanceUrl;
  bool _useProxy = false;
  String? _proxyUrl;

  // Initialisation - charge les credentials sauvegardés
  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    _apiKey = prefs.getString('api_key');
    _instanceUrl = prefs.getString('instance_url');
    _useProxy = prefs.getBool('use_proxy') ?? false;
    _proxyUrl = prefs.getString('proxy_url');
  }

  // Sauvegarde les credentials
  Future<void> setCredentials(
    String instanceUrl,
    String apiKey, {
    bool useProxy = false,
    String? proxyUrl,
  }) async {
    final prefs = await SharedPreferences.getInstance();

    // Normalise l'URL instance (ajoute https:// si manquant, supprime les slashs finaux)
    String normalizedInstance = instanceUrl.trim();
    if (!normalizedInstance.startsWith('http://') &&
        !normalizedInstance.startsWith('https://')) {
      normalizedInstance = 'https://$normalizedInstance';
    }
    normalizedInstance = normalizedInstance.replaceAll(RegExp(r'/+$'), '');

    // Normalise l'URL proxy si fournie (par défaut http://)
    String? normalizedProxy = proxyUrl?.trim();
    if (normalizedProxy != null && normalizedProxy.isNotEmpty) {
      if (!normalizedProxy.startsWith('http://') &&
          !normalizedProxy.startsWith('https://')) {
        // Les proxies de dev sont souvent en http
        normalizedProxy = 'http://$normalizedProxy';
      }
      normalizedProxy = normalizedProxy.replaceAll(RegExp(r'/+$'), '');
    }

    await prefs.setString('instance_url', normalizedInstance);
    await prefs.setString('api_key', apiKey);
    await prefs.setBool('use_proxy', useProxy);
    if (useProxy && normalizedProxy != null && normalizedProxy.isNotEmpty) {
      await prefs.setString('proxy_url', normalizedProxy);
    } else {
      await prefs.remove('proxy_url');
    }

    // Met à jour les variables internes
    _instanceUrl = normalizedInstance;
    _apiKey = apiKey;
    _useProxy = useProxy;
    _proxyUrl = normalizedProxy;
  }

  // Vérifie si on a des credentials
  bool get hasCredentials {
    return _apiKey != null &&
        _instanceUrl != null &&
        _apiKey!.isNotEmpty &&
        _instanceUrl!.isNotEmpty;
  }

  // Efface les credentials (pour la déconnexion)
  Future<void> clearCredentials() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('api_key');
    await prefs.remove('instance_url');
    await prefs.remove('use_proxy');
    await prefs.remove('proxy_url');

    _apiKey = null;
    _instanceUrl = null;
    _useProxy = false;
    _proxyUrl = null;
  }

  // 🎯 Smart proxy detection pour déploiement
  bool _shouldUseProxy() {
    // Development: Utilise le proxy si configuré
    if (_useProxy && _proxyUrl != null && _proxyUrl!.isNotEmpty) {
      // Si l'URL contient localhost/127.0.0.1/192.168.x.x/172.x.x.x -> Mode dev
      if (_proxyUrl!.contains('localhost') || 
          _proxyUrl!.contains('127.0.0.1') ||
          _proxyUrl!.contains('192.168.') ||
          _proxyUrl!.contains('172.')) {
        print('📍 Using development proxy: $_proxyUrl');
        return true;
      }
    }
    
    // Production: Mobile apps n'ont pas besoin de proxy (pas de CORS)
    if (!kIsWeb) {
      print('📱 Mobile app: Direct API access (no CORS issues)');
      return false;
    }
    
    // Web en production: Utilise proxy seulement si vraiment nécessaire
    if (kIsWeb && _useProxy && _proxyUrl != null) {
      print('🌐 Web app: Using configured proxy: $_proxyUrl');
      return true;
    }
    
    print('🚀 Production mode: Direct API access');
    return false;
  }

  // Méthode privée pour faire les requêtes GET
  Future<http.Response> _get(String endpoint) async {
    if (_apiKey == null || _instanceUrl == null) {
      throw Exception('Credentials manquantes');
    }

    // Détermine la stratégie d'URL selon le contexte
    final selectedBase = _shouldUseProxy() ? _proxyUrl! : _instanceUrl!;
    String cleanBase = selectedBase.replaceAll(RegExp(r'/+$'), '');
    String cleanEndpoint = endpoint.startsWith('/') ? endpoint : '/$endpoint';
    final url = '$cleanBase$baseUrl$cleanEndpoint';

    // Authentification Basic
    final authString = 'apikey:$_apiKey';
    final auth = base64Encode(utf8.encode(authString));

    final headers = {
      'Authorization': 'Basic $auth',
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };

    print('🌐 GET: $url');
    print('🔑 Auth: Basic $auth');

    try {
      final response = await http.get(Uri.parse(url), headers: headers);

      print('📡 Status: ${response.statusCode}');

      if (response.statusCode == 401) {
        throw Exception('API Key invalide');
      } else if (response.statusCode == 403) {
        throw Exception('Permissions insuffisantes');
      } else if (response.statusCode != 200) {
        throw Exception('Erreur HTTP ${response.statusCode}: ${response.body}');
      }

      return response;
    } on FormatException catch (e) {
      print('❌ Format error: $e');
      throw Exception('URL malformée: $e');
    } catch (e) {
      print('❌ Unexpected error: $e');
      print('❌ Error type: ${e.runtimeType}');
      throw Exception('Erreur inattendue: $e');
    }
  }

  // Test de connexion simple
  Future<bool> testConnection() async {
    try {
      final response = await _get('/projects');
      return response.statusCode == 200;
    } catch (e) {
      print('❌ Test connexion échoué: $e'); // Debug
      return false;
    }
  }

  // Récupère les informations de l'utilisateur connecté
  Future<Map<String, dynamic>?> getCurrentUser() async {
    try {
      final response = await _get('/users/me');
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data;
      }
      return null;
    } catch (e) {
      print('❌ Erreur getCurrentUser: $e');
      return null;
    }
  }

  // Récupère la liste des projets
  Future<List<Map<String, dynamic>>> getProjects() async {
    try {
      final response = await _get('/projects');
      final data = jsonDecode(response.body);

      // OpenProject retourne les données dans _embedded.elements
      if (data['_embedded'] != null && data['_embedded']['elements'] != null) {
        return List<Map<String, dynamic>>.from(data['_embedded']['elements']);
      }

      return [];
    } catch (e) {
      print('❌ Erreur getProjects: $e');
      throw Exception('Impossible de récupérer les projets: $e');
    }
  }

  // Récupère les work packages d'un projet
  Future<List<Map<String, dynamic>>> getWorkPackages(int projectId) async {
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
      print('❌ Erreur getWorkPackages: $e');
      throw Exception('Impossible de récupérer les work packages: $e');
    }
  }

  // Récupère tous les work packages (global)
  Future<List<Map<String, dynamic>>> getAllWorkPackages() async {
    try {
      final response = await _get('/work_packages?pageSize=100');
      final data = jsonDecode(response.body);

      if (data['_embedded'] != null && data['_embedded']['elements'] != null) {
        return List<Map<String, dynamic>>.from(data['_embedded']['elements']);
      }

      return [];
    } catch (e) {
      print('❌ Erreur getAllWorkPackages: $e');
      throw Exception('Impossible de récupérer les work packages: $e');
    }
  }

  // Récupère les versions/sprints d'un projet
  Future<List<Map<String, dynamic>>> getVersions(int projectId) async {
    try {
      final response = await _get('/projects/$projectId/versions');
      final data = jsonDecode(response.body);

      if (data['_embedded'] != null && data['_embedded']['elements'] != null) {
        return List<Map<String, dynamic>>.from(data['_embedded']['elements']);
      }

      return [];
    } catch (e) {
      print('❌ Erreur getVersions: $e');
      throw Exception('Impossible de récupérer les versions: $e');
    }
  }

  // Récupère les statuts disponibles
  Future<List<Map<String, dynamic>>> getStatuses() async {
    try {
      final response = await _get('/statuses');
      final data = jsonDecode(response.body);

      if (data['_embedded'] != null && data['_embedded']['elements'] != null) {
        return List<Map<String, dynamic>>.from(data['_embedded']['elements']);
      }

      return [];
    } catch (e) {
      print('❌ Erreur getStatuses: $e');
      throw Exception('Impossible de récupérer les statuts: $e');
    }
  }

  // Récupère les time entries
  Future<List<Map<String, dynamic>>> getTimeEntries({
    int? projectId,
    int? workPackageId,
  }) async {
    try {
      String endpoint = '/time_entries?pageSize=100';

      // Filtres optionnels
      List<String> filters = [];
      if (projectId != null) {
        filters.add('{"project_id":{"operator":"=","values":["$projectId"]}}');
      }
      if (workPackageId != null) {
        filters.add(
          '{"work_package_id":{"operator":"=","values":["$workPackageId"]}}',
        );
      }

      if (filters.isNotEmpty) {
        endpoint += '&filters=[${filters.join(",")}]';
      }

      final response = await _get(endpoint);
      final data = jsonDecode(response.body);

      if (data['_embedded'] != null && data['_embedded']['elements'] != null) {
        return List<Map<String, dynamic>>.from(data['_embedded']['elements']);
      }

      return [];
    } catch (e) {
      print('❌ Erreur getTimeEntries: $e');
      throw Exception('Impossible de récupérer les time entries: $e');
    }
  }
}
