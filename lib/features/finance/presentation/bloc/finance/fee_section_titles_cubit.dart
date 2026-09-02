import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:school_app_flutter/features/configuration/domain/usecases/refresh_fee_section_titles_use_case.dart';
import 'package:school_app_flutter/features/finance/offline/domain/usecases/get_fee_section_titles_use_case.dart';

/// Les titres que l'école donne à ses natures de frais, chargés au montage.
///
/// **Aucun état d'erreur, et c'est délibéré.** Un catalogue absent et un
/// catalogue illisible produisent la même chose à l'écran : les frais se nomment
/// par la nature localisée, ce qu'ils faisaient déjà avant que ce cache existe.
/// Afficher « impossible de charger les titres » au-dessus d'une fiche de solde
/// inquiéterait un caissier sur un chemin qui va parfaitement bien.
class FeeSectionTitlesState extends Equatable {
  /// Nature (`TUITION`, en majuscules) → titre écrit par l'école.
  final Map<String, String> titles;

  const FeeSectionTitlesState({this.titles = const {}});

  /// Le titre de cette nature, ou `null` s'il n'est pas connu de cet appareil.
  ///
  /// `null` est **la** valeur attendue tant que le catalogue n'est pas descendu,
  /// et l'appelant y répond par la nature localisée. Ce n'est pas un cas
  /// dégradé : c'est le comportement d'avant, préservé.
  String? titleOf(String feeCode) {
    final key = feeCode.trim().toUpperCase();
    final title = titles[key];
    return (title == null || title.isEmpty) ? null : title;
  }

  @override
  List<Object?> get props => [titles];
}

class FeeSectionTitlesCubit extends Cubit<FeeSectionTitlesState> {
  final GetFeeSectionTitlesUseCase _getTitles;
  final RefreshFeeSectionTitlesUseCase _refreshTitles;

  FeeSectionTitlesCubit({
    required GetFeeSectionTitlesUseCase getTitles,
    required RefreshFeeSectionTitlesUseCase refreshTitles,
  }) : _getTitles = getTitles,
       _refreshTitles = refreshTitles,
       super(const FeeSectionTitlesState());

  /// Lecture **traversante** : le local d'abord, le serveur seulement s'il n'a
  /// pas encore été interrogé de la session.
  ///
  /// ⚠️ **L'ordre est ce qui rend l'écran utilisable hors ligne.** Le local est
  /// émis AVANT toute tentative réseau : la fiche s'affiche sans attendre, et
  /// une tablette sans couverture n'attend rien du tout. Le rafraîchissement ne
  /// produit un second `emit` que s'il a réellement rapporté quelque chose —
  /// sinon le titre affiché ne bouge pas sous les yeux de l'opérateur.
  ///
  /// **Ne lève jamais** : une fiche de solde ne tombe pas parce qu'un
  /// référentiel de confort est illisible. Un échec laisse le cache en place —
  /// un titre d'hier vaut mieux qu'un écran qui se renomme parce que le réseau
  /// a manqué.
  Future<void> load() async {
    await _emitLocal();

    final refreshed = await _refreshTitles();
    if (isClosed) return;

    // `0` couvre les trois cas où relire ne rendrait rien de neuf : la session
    // avait déjà tiré, l'école n'est pas résolue, ou le catalogue est vide.
    final changed = refreshed.fold((_) => false, (count) => count > 0);
    if (changed) await _emitLocal();
  }

  Future<void> _emitLocal() async {
    final result = await _getTitles();
    if (isClosed) return;
    emit(
      FeeSectionTitlesState(
        titles: result.fold(
          (_) => const <String, String>{},
          (titles) => titles,
        ),
      ),
    );
  }
}
