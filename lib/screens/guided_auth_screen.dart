import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:url_launcher/url_launcher.dart';
import '../services/api_service.dart';

class GuidedAuthScreen extends StatefulWidget {
  const GuidedAuthScreen({super.key});

  @override
  _GuidedAuthScreenState createState() => _GuidedAuthScreenState();
}

class _GuidedAuthScreenState extends State<GuidedAuthScreen> {
  //Variables d'état pour stocker les données entre les étapes
  int _currentStep = 0;
  final PageController _pageController = PageController();

  //Données collectées dans les étapes
  String? _openProjectUrl;
  String? _apiKey;

  // Paramètres proxy (utile pour le Web/CORS)
  bool _useProxy = kIsWeb; // Par défaut activé sur Web
  String? _proxyUrl = kIsWeb ? 'http://localhost:8080' : 'http://172.17.71.19:8080';

  //état de l'interface
  bool _isLoading = false;
  String? _errorMessage;

  final ApiService _apiService = ApiService();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Configuration OpenProject'),
        //Indicateur de progression
        bottom: PreferredSize(
          preferredSize: Size.fromHeight(4.0),
          child: LinearProgressIndicator(
            value: (_currentStep + 1) / 4, //Progression 25% → 50% → 75% → 100%
          ),
        ),
      ),
      body: PageView(
        controller: _pageController,
        physics: NeverScrollableScrollPhysics(), //Empêche le swipe manuel
        children: [
          _buildUrlStep(), //étape 0
          _buildGuideStep(), //étape 1
          _buildApiKeyStep(), //étape 2
          _buildTestStep(), //étape 3
        ],
      ),
    );
  }

  Widget _buildStepByStepInstructions() {
    final isSmallScreen = MediaQuery.of(context).size.width < 600;
    
    return Card(
      child: Padding(
        padding: EdgeInsets.all(isSmallScreen ? 12.0 : 16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Instructions :',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 12),

            _buildInstructionStep(
              1,
              'Connectez-vous à votre compte OpenProject',
              Icons.login,
            ),
            _buildInstructionStep(
              2,
              'Cliquez sur votre avatar (coin supérieur droit)',
              Icons.account_circle,
            ),
            _buildInstructionStep(
              3,
              'Sélectionnez "My account" dans le menu',
              Icons.settings,
            ),
            _buildInstructionStep(
              4,
              'Cliquez sur l\'onglet "Access tokens"',
              Icons.key,
            ),
            _buildInstructionStep(
              5,
              'Cliquez sur "Generate" pour créer une nouvelle clé',
              Icons.add_circle,
            ),
            _buildInstructionStep(
              6, 
              'Copiez la clé générée', 
              Icons.copy,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInstructionStep(int number, String instruction, IconData icon) {
    final isSmallScreen = MediaQuery.of(context).size.width < 600;
    final circleSize = isSmallScreen ? 20.0 : 24.0;
    final iconSize = isSmallScreen ? 16.0 : 20.0;
    final verticalPadding = isSmallScreen ? 6.0 : 8.0;
    
    return Padding(
      padding: EdgeInsets.symmetric(vertical: verticalPadding),
      child: Row(
        children: [
          // Numéro dans un cercle
          Container(
            width: circleSize,
            height: circleSize,
            decoration: BoxDecoration(
              color: Theme.of(context).primaryColor,
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                '$number',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: isSmallScreen ? 10 : 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          SizedBox(width: isSmallScreen ? 8 : 12),

          // Icône
          Icon(icon, size: iconSize, color: Theme.of(context).primaryColor),
          SizedBox(width: isSmallScreen ? 8 : 12),

          // Texte instruction
          Expanded(
            child: Text(
              instruction,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUrlStep() {
    return SingleChildScrollView(
      child: Padding(
        padding: MediaQuery.of(context).size.width < 600 
            ? EdgeInsets.all(16.0) 
            : EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
          // Titre et description
          Text(
            'Étape 1: URL de votre OpenProject',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          SizedBox(height: 16),
          Text(
            'Entrez l\'URL de votre instance OpenProject pour commencer la configuration.',
            style: Theme.of(context).textTheme.bodyLarge,
          ),
          SizedBox(height: 32),

            // Champ de saisie
            TextField(
              onChanged: (value) {
                setState(() {
                  _openProjectUrl = value.trim();
                });
              },
              decoration: InputDecoration(
                labelText: 'URL OpenProject',
                hintText: 'https://votre-instance.openproject.com',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.link),
              ),
            ),

            SizedBox(height: 16),

            // Proxy toggle
            SwitchListTile.adaptive(
              title: Text('Utiliser un proxy (recommandé pour Web/CORS)'),
              subtitle: Text('Activez pour utiliser un proxy comme http://localhost:8080'),
              value: _useProxy,
              onChanged: (value) {
                setState(() {
                  _useProxy = value;
                });
              },
            ),

            if (_useProxy) ...[
              SizedBox(height: 12),
              TextField(
                controller: TextEditingController(text: _proxyUrl),
                onChanged: (value) {
                  setState(() {
                    _proxyUrl = value.trim();
                  });
                },
                decoration: InputDecoration(
                  labelText: 'URL du proxy',
                  hintText: kIsWeb ? 'http://localhost:8080' : 'http://172.17.71.19:8080',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.swap_horiz),
                ),
              ),
            ],

            SizedBox(height: 32),
            // Bouton suivant
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _openProjectUrl?.isNotEmpty == true
                    ? _goToNextStep
                    : null,
                child: Text('Suivant'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _goToNextStep() {
    setState(() {
      _currentStep++;
    });
    _pageController.nextPage(
      duration: Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  Future<void> _openProjectInNewTab() async {
    if (_openProjectUrl == null || _openProjectUrl!.isEmpty) {
      _showErrorSnackBar('Veuillez d\'abord entrer l\'URL OpenProject');
      return;
    }

    try {
      // Ensure URL has protocol
      String cleanUrl = _openProjectUrl!;
      if (!cleanUrl.startsWith('http://') && !cleanUrl.startsWith('https://')) {
        cleanUrl = 'https://$cleanUrl';
      }
      
      // URL directe vers la page des tokens
      final url = Uri.parse('$cleanUrl/my/access_token');

      print('🔗 Trying to open: $url');

      // Essayer plusieurs méthodes de lancement
      bool launched = false;
      
      try {
        // Méthode 1: Mode externe par défaut
        if (await canLaunchUrl(url)) {
          await launchUrl(url, mode: LaunchMode.externalApplication);
          launched = true;
          print('✅ URL launched with externalApplication');
        }
      } catch (e) {
        print('❌ Failed with externalApplication: $e');
      }
      
      if (!launched) {
        try {
          // Méthode 2: Mode plateforme par défaut
          await launchUrl(url, mode: LaunchMode.platformDefault);
          launched = true;
          print('✅ URL launched with platformDefault');
        } catch (e) {
          print('❌ Failed with platformDefault: $e');
        }
      }
      
      if (!launched) {
        try {
          // Méthode 3: Mode ancien (deprecated mais parfois plus compatible)
          await launchUrl(url);
          launched = true;
          print('✅ URL launched with default mode');
        } catch (e) {
          print('❌ Failed with default mode: $e');
        }
      }
      
      if (!launched) {
        print('❌ All launch methods failed for URL: $url');
        _showErrorSnackBar('Aucune méthode ne peut ouvrir le lien. Vérifiez qu\'un navigateur est installé sur votre téléphone.');
      }
    } catch (e) {
      print('❌ Exception launching URL: $e');
      _showErrorSnackBar('Erreur: $e');
    }
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  void _goToPreviousStep() {
    setState(() {
      _currentStep--;
    });
    _pageController.previousPage(
      duration: Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  Widget _buildGuideStep() {
    final isSmallScreen = MediaQuery.of(context).size.width < 600;
    
    return SingleChildScrollView(
      child: Padding(
        padding: isSmallScreen ? EdgeInsets.all(16.0) : EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
          // Titre
          Text(
            'Étape 2: Ouvrir OpenProject',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          SizedBox(height: 16),

          // Instructions
          Text(
            'Nous allons vous guider pour générer votre clé API OpenProject.',
            style: Theme.of(context).textTheme.bodyLarge,
          ),
          SizedBox(height: 24),

          // Card avec instructions visuelles
          Card(
            elevation: 4, // Ombre portée
            child: Padding(
              padding: EdgeInsets.all(16.0),
              child: Column(
                children: [
                  Icon(
                    Icons.open_in_new,
                    size: 48,
                    color: Theme.of(context).primaryColor,
                  ),
                  SizedBox(height: 16),
                  Text(
                    'Cliquez sur le bouton ci-dessous pour ouvrir OpenProject dans un nouvel onglet.',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ],
              ),
            ),
          ),

          SizedBox(height: 24),

            // Bouton pour ouvrir OpenProject
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _openProjectInNewTab,
                icon: Icon(Icons.launch),
                label: Text('Ouvrir OpenProject'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                ),
              ),
            ),

          SizedBox(height: 24),

          // Instructions étape par étape
          _buildStepByStepInstructions(),

            SizedBox(height: 32),

            // Boutons navigation
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: _goToPreviousStep,
                    child: Text('Précédent'),
                  ),
                ),
                SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _goToNextStep,
                    child: Text('J\'ai généré ma clé'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildApiKeyStep() {
    final isSmallScreen = MediaQuery.of(context).size.width < 600;
    
    return SingleChildScrollView(
      child: Padding(
        padding: isSmallScreen ? EdgeInsets.all(16.0) : EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
          // Titre
          Text(
            'Étape 3: Saisir votre clé API',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          SizedBox(height: 16),

          // Description
          Text(
            'Collez la clé API que vous venez de générer dans OpenProject.',
            style: Theme.of(context).textTheme.bodyLarge,
          ),
          SizedBox(height: 24),

          // Card avec exemple visuel
          Card(
            color: Colors.blue.shade50, // Couleur de fond légère
            child: Padding(
              padding: EdgeInsets.all(16.0),
              child: Column(
                children: [
                  Icon(Icons.info_outline, color: Colors.blue, size: 32),
                  SizedBox(height: 12),
                  Text(
                    'La clé API ressemble à ceci :',
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                  SizedBox(height: 8),
                  Container(
                    padding: EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.grey.shade300),
                    ),
                    child: Text(
                      'abcdef1234567890abcdef1234567890abcdef12',
                      style: TextStyle(
                        fontFamily: 'monospace', // Police à espacement fixe
                        fontSize: 14,
                        color: Colors.grey.shade700,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          SizedBox(height: 24),

            // Champ de saisie API Key
            TextField(
              onChanged: (value) {
                setState(() {
                  _apiKey = value.trim();
                  _errorMessage = null;
                });
              },
              decoration: InputDecoration(
                labelText: 'Clé API OpenProject',
                hintText: 'Collez votre clé API ici...',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.vpn_key),
                suffixIcon: _apiKey?.isNotEmpty == true
                    ? Icon(Icons.check_circle, color: Colors.green)
                    : null,
                errorText: _errorMessage,
              ),
              maxLines: 2,
              obscureText: false,
            ),

          SizedBox(height: 16),

          // Bouton test rapide de la clé
          if (_apiKey?.isNotEmpty == true) ...[
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: _isLoading ? null : _testApiKey,
                icon: _isLoading
                    ? SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Icon(Icons.wifi_protected_setup),
                label: Text(
                  _isLoading ? 'Test en cours...' : 'Tester la connexion',
                ),
              ),
            ),
            SizedBox(height: 16),
          ],

            SizedBox(height: 32),

            // Navigation
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: _goToPreviousStep,
                    child: Text('Précédent'),
                  ),
                ),
                SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _canProceedToNextStep() ? _goToNextStep : null,
                    child: Text('Finaliser'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _testApiKey() async {
    if (_apiKey == null || _apiKey!.isEmpty) {
      setState(() {
        _errorMessage = 'Veuillez saisir votre clé API';
      });
      return;
    }

    if (_useProxy && (_proxyUrl == null || _proxyUrl!.isEmpty)) {
      setState(() {
        _errorMessage = 'Veuillez saisir l\'URL du proxy';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // Configure les credentials pour le test
      await _apiService.setCredentials(
        _openProjectUrl!,
        _apiKey!,
        useProxy: _useProxy,
        proxyUrl: _proxyUrl,
      );

      // Tests étendus
      print('🧪 Test 1: Connexion basique...');
      final isValid = await _apiService.testConnection();

      if (isValid) {
        print('✅ Test 1 réussi !');

        print('🧪 Test 2: Récupération utilisateur...');
        final user = await _apiService.getCurrentUser();
        print('👤 Utilisateur: ${user?['name']}');

        print('🧪 Test 3: Récupération projets...');
        final projects = await _apiService.getProjects();
        print('📋 ${projects.length} projets trouvés');

        setState(() {
          _isLoading = false;
        });
        
        _showSuccessSnackBar('✅ Tous les tests réussis !');
      } else {
        setState(() {
          _isLoading = false;
          _errorMessage = 'Clé API invalide ou permissions insuffisantes';
        });
      }
    } catch (e) {
      print('❌ Erreur test: $e');
      setState(() {
        _isLoading = false;
        _errorMessage = 'Erreur de connexion: ${e.toString()}';
      });
    }
  }

  bool _canProceedToNextStep() {
    return _apiKey?.isNotEmpty == true && !_isLoading;
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(Icons.check_circle, color: Colors.white),
            SizedBox(width: 8),
            Text(message),
          ],
        ),
        backgroundColor: Colors.green,
        duration: Duration(seconds: 3),
      ),
    );
  }

  Widget _buildTestStep() {
    final isSmallScreen = MediaQuery.of(context).size.width < 600;
    
    return SingleChildScrollView(
      child: Padding(
        padding: isSmallScreen ? EdgeInsets.all(16.0) : EdgeInsets.all(24.0),
        child: Column(
          children: [
            // Animation de succès
            Container(
              width: isSmallScreen ? 80 : 120,
              height: isSmallScreen ? 80 : 120,
            decoration: BoxDecoration(
              color: Colors.green.shade100,
              shape: BoxShape.circle,
            ),
              child: Icon(
                Icons.check_circle_outline,
                size: isSmallScreen ? 48 : 64,
                color: Colors.green,
              ),
          ),

            SizedBox(height: isSmallScreen ? 16 : 24),

            Text(
              'Configuration terminée !',
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
              color: Colors.green.shade700,
              fontWeight: FontWeight.bold,
            ),
          ),

            SizedBox(height: isSmallScreen ? 12 : 16),

            Text(
              'Votre application est maintenant connectée à OpenProject.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyLarge,
            ),

            SizedBox(height: isSmallScreen ? 24 : 32),

            // Informations de connexion
            Card(
            child: Padding(
              padding: EdgeInsets.all(16.0),
              child: Column(
                children: [
                  _buildInfoRow('Instance', _openProjectUrl ?? ''),
                  Divider(),
                  _buildInfoRow('Statut', 'Connecté ✅'),
                ],
              ),
            ),
          ),

            SizedBox(height: 32),

            // Bouton pour continuer vers l'app
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _goToDashboard,
                icon: Icon(Icons.dashboard),
                label: Text('Accéder au tableau de bord'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Row(
      children: [
        Text('$label: ', style: TextStyle(fontWeight: FontWeight.bold)),
        Expanded(
          child: Text(
            value,
            overflow: TextOverflow.ellipsis, // Ajoute "..." si trop long
          ),
        ),
      ],
    );
  }

  void _goToDashboard() {
    // Navigation vers l'écran principal
    Navigator.of(context).pushReplacementNamed('/kpi');
  }
}
