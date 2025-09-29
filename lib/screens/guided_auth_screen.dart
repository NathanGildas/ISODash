import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../services/api_service.dart';
import '../providers/theme_provider.dart';

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
  String? _proxyUrl = kIsWeb
      ? 'http://localhost:8080'
      : 'http://172.17.71.19:8080';

  //état de l'interface
  bool _isLoading = false;
  String? _errorMessage;

  final ApiService _apiService = ApiService();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return PopScope(
      canPop: false, // Empêche la sortie automatique
      onPopInvoked: (didPop) {
        if (didPop) return;
        _handleBackButton(context);
      },
      child: Scaffold(
        appBar: AppBar(
          title: LayoutBuilder(
            builder: (context, constraints) {
              // Check available width for responsive title
              final screenWidth = MediaQuery.of(context).size.width;
              final isSmallScreen = screenWidth < 400;

              return Row(
                children: [
                  Container(
                    padding: EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.secondary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      Icons.settings_applications,
                      color: theme.colorScheme.secondary,
                      size: 20,
                    ),
                  ),
                  SizedBox(width: isSmallScreen ? 8 : 12),
                  Expanded(
                    child: Text(
                      isSmallScreen
                          ? 'Configuration'
                          : 'Configuration OpenProject',
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).appBarTheme.titleTextStyle,
                    ),
                  ),
                ],
              );
            },
          ),
          actions: [
            Consumer<ThemeProvider>(
              builder: (context, themeProvider, child) {
                return PopupMenuButton<ThemeMode>(
                  icon: Icon(
                    isDark ? Icons.dark_mode : Icons.light_mode,
                    color: Colors.white,
                  ),
                  onSelected: (ThemeMode mode) {
                    themeProvider.setThemeMode(mode);
                  },
                  itemBuilder: (context) => [
                    PopupMenuItem(
                      value: ThemeMode.light,
                      child: Row(
                        children: [
                          Icon(
                            Icons.light_mode,
                            size: 20,
                            color: Theme.of(context).colorScheme.onSurface,
                          ),
                          SizedBox(width: 8),
                          Text('Clair'),
                        ],
                      ),
                    ),
                    PopupMenuItem(
                      value: ThemeMode.dark,
                      child: Row(
                        children: [
                          Icon(
                            Icons.dark_mode,
                            size: 20,
                            color: Theme.of(context).colorScheme.onSurface,
                          ),
                          SizedBox(width: 8),
                          Text('Sombre'),
                        ],
                      ),
                    ),
                    PopupMenuItem(
                      value: ThemeMode.system,
                      child: Row(
                        children: [
                          Icon(
                            Icons.auto_mode,
                            size: 20,
                            color: Theme.of(context).colorScheme.onSurface,
                          ),
                          SizedBox(width: 8),
                          Text('Système'),
                        ],
                      ),
                    ),
                  ],
                );
              },
            ),
          ],
          bottom: PreferredSize(
            preferredSize: Size.fromHeight(12.0),
            child: Column(
              children: [
                // Indicateur de progression moderne
                Container(
                  margin: EdgeInsets.symmetric(horizontal: 20),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(4, (index) {
                      bool isActive = index <= _currentStep;
                      bool isCurrent = index == _currentStep;

                      return Expanded(
                        child: Container(
                          margin: EdgeInsets.symmetric(horizontal: 2),
                          height: 4,
                          decoration: BoxDecoration(
                            color: isActive
                                ? theme.colorScheme.secondary
                                : theme.colorScheme.secondary.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(2),
                            boxShadow: isCurrent
                                ? [
                                    BoxShadow(
                                      color: theme.colorScheme.secondary
                                          .withOpacity(0.4),
                                      blurRadius: 4,
                                      offset: Offset(0, 1),
                                    ),
                                  ]
                                : null,
                          ),
                        ),
                      );
                    }),
                  ),
                ),
                SizedBox(height: 8),
              ],
            ),
          ),
        ),
        body: PageView(
          controller: _pageController,
          physics: NeverScrollableScrollPhysics(),
          children: [
            _buildUrlStep(),
            _buildGuideStep(),
            _buildApiKeyStep(),
            _buildTestStep(),
          ],
        ),
      ),
    );
  }

  /// Gère le comportement du bouton retour natif
  void _handleBackButton(BuildContext context) {
    if (_currentStep > 0) {
      // Si on n'est pas à la première étape, aller à l'étape précédente
      _goToPreviousStep();
    } else {
      // Si on est à la première étape, demander confirmation de sortie
      _showExitConfirmationDialog(context);
    }
  }

  /// Affiche une dialog de confirmation pour quitter l'app
  void _showExitConfirmationDialog(BuildContext context) {
    showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Row(
            children: [
              Icon(
                Icons.exit_to_app,
                color: Theme.of(context).colorScheme.primary,
                size: 20,
              ),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Quitter l\'application ?',
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ),
            ],
          ),
          content: Text(
            'Êtes-vous sûr de vouloir quitter l\'application ?\n\nVos paramètres non sauvegardés seront perdus.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text('Annuler'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop(true);
                // Quitter l'application
                Navigator.of(context).pop();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
              child: Text('Quitter'),
            ),
          ],
        );
      },
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
            _buildInstructionStep(6, 'Copiez la clé générée', Icons.copy),
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
              subtitle: Text(
                'Activez pour utiliser un proxy comme http://localhost:8080',
              ),
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
                  hintText: kIsWeb
                      ? 'http://localhost:8080'
                      : 'http://172.17.71.19:8080',
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
        _showErrorSnackBar(
          'Aucune méthode ne peut ouvrir le lien. Vérifiez qu\'un navigateur est installé sur votre téléphone.',
        );
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
    final screenHeight = MediaQuery.of(context).size.height;
    final availableHeight =
        screenHeight -
        MediaQuery.of(context).padding.top -
        kToolbarHeight -
        100;

    return LayoutBuilder(
      builder: (context, constraints) {
        return SingleChildScrollView(
          padding: isSmallScreen ? EdgeInsets.all(12.0) : EdgeInsets.all(20.0),
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: availableHeight),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                // Titre
                Text(
                  'Étape 2: Ouvrir OpenProject',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                SizedBox(height: isSmallScreen ? 12 : 16),

                // Instructions
                Text(
                  'Nous allons vous guider pour générer votre clé API OpenProject.',
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
                SizedBox(height: isSmallScreen ? 16 : 24),

                // Card avec instructions visuelles - Compacte pour mobile
                Card(
                  elevation: 2,
                  child: Padding(
                    padding: EdgeInsets.all(isSmallScreen ? 12.0 : 16.0),
                    child: Column(
                      children: [
                        Icon(
                          Icons.open_in_new,
                          size: isSmallScreen ? 32 : 40,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                        SizedBox(height: 12),
                        Text(
                          'Cliquez sur le bouton ci-dessous pour ouvrir OpenProject.',
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ],
                    ),
                  ),
                ),

                SizedBox(height: isSmallScreen ? 16 : 24),

                // Bouton pour ouvrir OpenProject
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _openProjectInNewTab,
                    icon: Icon(Icons.launch),
                    label: Text('Ouvrir OpenProject'),
                    style: ElevatedButton.styleFrom(
                      padding: EdgeInsets.symmetric(
                        vertical: isSmallScreen ? 12 : 16,
                      ),
                    ),
                  ),
                ),

                SizedBox(height: isSmallScreen ? 16 : 24),

                // Instructions étape par étape - Plus compactes
                _buildStepByStepInstructions(),

                SizedBox(height: isSmallScreen ? 24 : 32),

                // Boutons navigation
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: _goToPreviousStep,
                        child: Text('Précédent'),
                      ),
                    ),
                    SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: _goToNextStep,
                        child: Text('J\'ai généré ma clé'),
                      ),
                    ),
                  ],
                ),

                // Bottom padding for mobile safe area
                SizedBox(height: MediaQuery.of(context).padding.bottom + 16),
              ],
            ),
          ),
        );
      },
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
    // Navigation vers l'écran principal avec navigation fluide
    Navigator.of(context).pushReplacementNamed('/main');
  }
}
