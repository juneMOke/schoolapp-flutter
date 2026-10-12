import 'package:equatable/equatable.dart';
import 'package:school_app_flutter/features/communication/domain/entities/announcement_category.dart';

/// Un modèle de communiqué de l'école : catégorie, titre, message. Utiliser
/// un modèle ouvre un brouillon pré-rempli ; le supprimer n'affecte aucun
/// envoi passé.
class AnnouncementTemplate extends Equatable {
  final String id;
  final AnnouncementCategory category;
  final String title;
  final String body;

  const AnnouncementTemplate({
    required this.id,
    required this.category,
    required this.title,
    required this.body,
  });

  @override
  List<Object?> get props => [id, category, title, body];
}
