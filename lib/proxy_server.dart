import 'dart:io';
import 'dart:convert';
import 'dart:typed_data';

void main() async {
  final server = await HttpServer.bind('localhost', 8080);
  print('🚀 Proxy CORS server running on http://localhost:8080');
  print('🔗 Proxying to https://forge2.ebindoo.com');

  await for (HttpRequest request in server) {
    // Headers CORS pour autoriser toutes les requêtes
    request.response.headers.set('Access-Control-Allow-Origin', '*');
    request.response.headers.set(
      'Access-Control-Allow-Methods',
      'GET, POST, PUT, DELETE, OPTIONS',
    );
    request.response.headers.set(
      'Access-Control-Allow-Headers',
      'Content-Type, Authorization',
    );

    // Répond aux requêtes OPTIONS (preflight)
    if (request.method == 'OPTIONS') {
      request.response.statusCode = 200;
      await request.response.close();
      continue;
    }

    // Proxy vers OpenProject
    final targetUrl = 'https://forge2.ebindoo.com${request.uri}';
    print('📡 Proxying: ${request.method} $targetUrl');

    final client = HttpClient();

    try {
      final proxyRequest = await client.openUrl(
        request.method,
        Uri.parse(targetUrl),
      );

      // Copie tous les headers de la requête originale
      request.headers.forEach((name, values) {
        if (name.toLowerCase() != 'host') {
          proxyRequest.headers.set(name, values);
        }
      });

      // Copie le body pour les requêtes POST/PUT
      if (request.method == 'POST' || request.method == 'PUT') {
        final bodyBytes = <int>[];
        await for (var chunk in request) {
          bodyBytes.addAll(chunk);
        }
        proxyRequest.add(bodyBytes);
      }

      final proxyResponse = await proxyRequest.close();

      // Copie le status code
      request.response.statusCode = proxyResponse.statusCode;

      // Copie les headers de réponse (en évitant les conflits)
      proxyResponse.headers.forEach((name, values) {
        final lowerName = name.toLowerCase();
        if (lowerName != 'transfer-encoding' &&
            lowerName != 'content-encoding' &&
            lowerName != 'content-length') {
          request.response.headers.set(name, values);
        }
      });

      // Copie le body de la réponse
      await proxyResponse.pipe(request.response);
    } catch (e) {
      print('❌ Proxy error: $e');
      request.response.statusCode = 500;
      request.response.headers.contentType = ContentType.json;
      request.response.write(jsonEncode({'error': 'Proxy error: $e'}));
      await request.response.close();
    }

    client.close();
  }
}
