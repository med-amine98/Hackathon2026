// lib/data/repositories/declaration_repository.dart

import 'package:ai_insurance_advisor/data/models/declaration_model.dart';

class DeclarationRepository {
  // Simuler une base de données locale
  static final List<DeclarationModel> _declarations = [];

  // Ajouter une déclaration
  static Future<void> addDeclaration(DeclarationModel declaration) async {
    _declarations.add(declaration);
  }

  // Récupérer toutes les déclarations
  static Future<List<DeclarationModel>> getDeclarations() async {
    return _declarations;
  }

  // Récupérer une déclaration par ID
  static Future<DeclarationModel?> getDeclarationById(String id) async {
    try {
      return _declarations.firstWhere((d) => d.id == id);
    } catch (e) {
      return null;
    }
  }

  // Mettre à jour le statut d'une déclaration
  static Future<void> updateDeclarationStatus(String id, String newStatus) async {
    final index = _declarations.indexWhere((d) => d.id == id);
    if (index != -1) {
      final declaration = _declarations[index];
      _declarations[index] = DeclarationModel(
        id: declaration.id,
        title: declaration.title,
        description: declaration.description,
        status: newStatus,
        date: declaration.date,
        vehicleInfo: declaration.vehicleInfo,
        imageUrl: declaration.imageUrl,
        details: declaration.details,
      );
    }
  }

  // Supprimer une déclaration
  static Future<void> deleteDeclaration(String id) async {
    _declarations.removeWhere((d) => d.id == id);
  }

  // Ajouter des déclarations de test
  static void addTestDeclarations() {
    _declarations.addAll([
      DeclarationModel(
        id: '1',
        title: 'Accident - Tuning',
        description: 'Accident avec un autre véhicule sur la route de la Marsa',
        status: 'en_attente',
        date: DateTime.now().subtract(const Duration(days: 2)),
        vehicleInfo: 'Renault Symbol - 2019',
        imageUrl: null,
        details: {
          'lieu': 'Route de la Marsa, Tunis',
          'autres_participants': '1',
          'degats': 'Pare-chocs avant endommagé',
        },
      ),
      DeclarationModel(
        id: '2',
        title: 'Vol de véhicule',
        description: 'Vol de ma voiture devant le centre commercial',
        status: 'en_cours',
        date: DateTime.now().subtract(const Duration(days: 5)),
        vehicleInfo: 'Peugeot 208 - 2021',
        imageUrl: null,
        details: {
          'lieu': 'Centre commercial Lac, Tunis',
          'date_vol': '2026-01-15',
          'plainte': 'Déposée au poste de police',
        },
      ),
      DeclarationModel(
        id: '3',
        title: 'Incendie résidentiel',
        description: 'Incendie dans mon appartement suite à un court-circuit',
        status: 'traite',
        date: DateTime.now().subtract(const Duration(days: 10)),
        vehicleInfo: 'Non applicable',
        imageUrl: null,
        details: {
          'lieu': 'Appartement, Ariana',
          'cause': 'Court-circuit électrique',
          'degats': 'Dégâts matériels importants',
        },
      ),
      DeclarationModel(
        id: '4',
        title: 'Accident de la route',
        description: 'Carambolage sur l\'autoroute A1',
        status: 'rejete',
        date: DateTime.now().subtract(const Duration(days: 15)),
        vehicleInfo: 'Toyota Yaris - 2020',
        imageUrl: null,
        details: {
          'lieu': 'Autoroute A1, Tunis',
          'autres_participants': '3',
          'degats': 'Dommages importants',
        },
      ),
    ]);
  }
}