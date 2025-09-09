import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/project_provider.dart';
import '../models/project.dart';

class DashboardScreen extends StatefulWidget {
  @override
  _DashboardScreenState createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  @override
  void initState() {
    super.initState();
    // Charge les projets au démarrage
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ProjectProvider>().loadProjects();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Tableau de bord'),
        actions: [
          IconButton(
            icon: Icon(Icons.refresh),
            onPressed: () => context.read<ProjectProvider>().refresh(),
          ),
        ],
      ),
      body: Consumer<ProjectProvider>(
        builder: (context, projectProvider, child) {
          if (projectProvider.isLoading) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Chargement des projets...'),
                ],
              ),
            );
          }

          if (projectProvider.errorMessage != null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error, size: 64, color: Colors.red),
                  SizedBox(height: 16),
                  Text(
                    'Erreur',
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  SizedBox(height: 8),
                  Text(projectProvider.errorMessage!),
                  SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => projectProvider.refresh(),
                    child: Text('Réessayer'),
                  ),
                ],
              ),
            );
          }

          if (!projectProvider.hasProjects) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.folder_open, size: 64, color: Colors.grey),
                  SizedBox(height: 16),
                  Text(
                    'Aucun projet trouvé',
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  SizedBox(height: 8),
                  Text('Vérifiez vos permissions OpenProject'),
                ],
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: projectProvider.refresh,
            child: ListView.builder(
              padding: EdgeInsets.all(16),
              itemCount: projectProvider.projects.length,
              itemBuilder: (context, index) {
                final project = projectProvider.projects[index];
                return _buildProjectCard(project);
              },
            ),
          );
        },
      ),
    );
  }

  Widget _buildProjectCard(Project project) {
    return Card(
      margin: EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: project.active ? Colors.green : Colors.grey,
          child: Text(
            project.name.substring(0, 1).toUpperCase(),
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
        ),
        title: Text(
          project.name,
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (project.description != null) ...[
              Text(
                project.description!,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              SizedBox(height: 4),
            ],
            Text('Créé le ${project.createdAtFormatted}'),
          ],
        ),
        trailing: Chip(
          label: Text(project.statusDisplay, style: TextStyle(fontSize: 12)),
          backgroundColor: project.active
              ? Colors.green.shade100
              : Colors.grey.shade100,
        ),
        onTap: () {
          // Navigation vers les détails du projet (à implémenter)
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Détails du projet ${project.name} - À implémenter',
              ),
            ),
          );
        },
      ),
    );
  }
}
