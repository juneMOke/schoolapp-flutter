import 'package:dio/dio.dart';
import 'package:retrofit/retrofit.dart';
import 'package:school_app_flutter/core/constants/app_constants.dart';
import 'package:school_app_flutter/features/expense/data/sync/expense_sync_models.dart';

part 'expense_sync_api.g.dart';

/// Surface réseau du registre des dépenses : deux remontées, une descente.
///
/// **Les types ne sont pas ici** : ils descendent à la racine du socle
/// référentiel. Aucune route de lecture unitaire ni de statistiques : le poste
/// détient le registre et calcule tout ce que ses deux écrans affichent.
@RestApi()
abstract class ExpenseSyncApi {
  factory ExpenseSyncApi(Dio dio, {String baseUrl}) = _ExpenseSyncApi;

  /// Créer ou modifier une dépense — l'état complet, un geste par requête.
  ///
  /// **Idempotent sur `expense.id`** : un rejeu après coupure retrouve la
  /// dépense, ne consomme aucun numéro et rend l'état canonique (200 au lieu
  /// de 201 — deux succès pour Retrofit, un seul chemin d'accusé).
  @POST(AppConstants.syncExpensesEndpoint)
  Future<ExpenseSyncResponseDto> submitExpense(
    @Extras() Map<String, dynamic> extras,
    @Body() ExpenseSyncRequestDto request,
  );

  /// Retirer (`deleted: true`) ou restaurer (`deleted: false`) — le plus
  /// récent des deux gestes l'emporte, sur sa propre horloge (`changedAt`).
  @POST(AppConstants.syncExpenseDeletionEndpoint)
  Future<ExpenseSyncResponseDto> setWithdrawn(
    @Extras() Map<String, dynamic> extras,
    @Path('expenseId') String expenseId,
    @Body() Map<String, dynamic> body,
  );

  /// Delta du registre de l'école, **retraits compris**. `304` = rien de neuf
  /// (sans corps), à ne pas confondre avec `hasMore: false`.
  @GET(AppConstants.syncExpensesEndpoint)
  Future<HttpResponse<ExpensePageDto>> pullExpenses(
    @Extras() Map<String, dynamic> extras,
    @Query('cursor') String? cursor,
    @Query('limit') int? limit,
  );
}
