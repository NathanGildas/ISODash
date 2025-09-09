import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class ApiService {
  static const String baseUrl = '/api/v3';
  String? _apiKey;
  String? _instanceUrl;

  // Initialisation - charge les credentials sauvegardés
  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    _apiKey = prefs.getString('api_key');
    _instanceUrl = prefs.getString('instance_url');
  }

  // Sauvegarde les credentials
  Future<void> setCredentials(String instanceUrl, String apiKey) async {
    final prefs = await SharedPreferences.getInstance();

    // Utilise le proxy au lieu de l'URL directe
    String proxyUrl = 'http://localhost:8080';

    await prefs.setString('instance_url', proxyUrl);
    await prefs.setString('api_key', apiKey);

    // Met à jour les variables internes
    _instanceUrl = proxyUrl;
    _apiKey = apiKey;
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

    _apiKey = null;
    _instanceUrl = null;
  }

  // Méthode privée pour faire les requêtes GET
  Future<http.Response> _get(String endpoint) async {
    if (_apiKey == null || _instanceUrl == null) {
      throw Exception('Credentials manquantes');
    }

    // Nettoie l'URL pour éviter les doubles slashes
    String cleanInstanceUrl = _instanceUrl!.replaceAll(RegExp(r'/+$'), '');
    String cleanEndpoint = endpoint.startsWith('/') ? endpoint : '/$endpoint';
    final url = '$cleanInstanceUrl$baseUrl$cleanEndpoint';

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
    } on HttpException catch (e) {
      print('❌ HTTP error: $e');
      throw Exception('Erreur HTTP: $e');
    } on SocketException catch (e) {
      print('❌ Network error: $e');
      throw Exception('Erreur réseau: Vérifiez votre connexion et l\'URL');
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
