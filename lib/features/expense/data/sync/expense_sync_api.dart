import 'package:dio/dio.dart';
import 'package:retrofit/retrofit.dart';
import 'package:school_app_flutter/core/constants/app_constants.dart';
import 'package:school_app_flutter/features/expense/data/sync/expense_sync_models.dart';

part 'expense_sync_api.g.dart';

/// Surface réseau du registre des dépenses : le contenu, le retrait, les
/// **sept gestes du circuit**, et une descente.
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

  // ── Les sept gestes du circuit (v2) ─────────────────────────────────────
  //
  // Une méthode par route, et non une route paramétrée : chacune porte sa
  // propre garde côté serveur (`expense.decide`, `expense.pay`,
  // `expense.reopen`, `expense.write` + propriété), et le geste doit rester
  // dans le CHEMIN — une route unique ferait dépendre l'autorisation d'une
  // valeur postée.
  //
  // Toutes **idempotentes par l'uuid du message** porté dans le corps (Q3) :
  // un rejeu rend 200 et l'état canonique, sans faire monter le compteur de
  // relances.

  /// Accorder ou refuser — `expense.decide`, et jamais sur sa propre demande.
  @POST(AppConstants.syncExpenseDecisionEndpoint)
  Future<ExpenseSyncResponseDto> decideExpense(
    @Extras() Map<String, dynamic> extras,
    @Path('expenseId') String expenseId,
    @Body() Map<String, dynamic> body,
  );

  /// Constater le décaissement — `expense.pay`, sur une demande accordée.
  @POST(AppConstants.syncExpensePaymentEndpoint)
  Future<ExpenseSyncResponseDto> payExpense(
    @Extras() Map<String, dynamic> extras,
    @Path('expenseId') String expenseId,
    @Body() Map<String, dynamic> body,
  );

  /// Annuler une décision — `expense.reopen` ; relances remises à zéro.
  @POST(AppConstants.syncExpenseReopenEndpoint)
  Future<ExpenseSyncResponseDto> reopenExpense(
    @Extras() Map<String, dynamic> extras,
    @Path('expenseId') String expenseId,
    @Body() Map<String, dynamic> body,
  );

  /// Retirer sa demande — `expense.write` **et** propriété. Ce n'est plus une
  /// bascule (Q2) : c'est `/resubmit` qui réengage.
  @POST(AppConstants.syncExpenseRetractionEndpoint)
  Future<ExpenseSyncResponseDto> retractExpense(
    @Extras() Map<String, dynamic> extras,
    @Path('expenseId') String expenseId,
    @Body() Map<String, dynamic> body,
  );

  /// Renvoyer une demande refusée ou retirée — `expense.write` + propriété.
  /// Porte le `clientUpdatedAt` attendu (F32) : tant que la copie serveur est
  /// plus ancienne, il refuse en 409 rejouable.
  @POST(AppConstants.syncExpenseResubmitEndpoint)
  Future<ExpenseSyncResponseDto> resubmitExpense(
    @Extras() Map<String, dynamic> extras,
    @Path('expenseId') String expenseId,
    @Body() Map<String, dynamic> body,
  );

  /// Relancer — `expense.write` + propriété ; `reminderCount` monte d'un.
  @POST(AppConstants.syncExpenseReminderEndpoint)
  Future<ExpenseSyncResponseDto> remindExpense(
    @Extras() Map<String, dynamic> extras,
    @Path('expenseId') String expenseId,
    @Body() Map<String, dynamic> body,
  );

  /// Commenter — `expense.write`, **sans** contrôle de propriété : c'est la
  /// soupape du circuit, un validateur doit pouvoir écrire sur la demande
  /// d'un autre (Q1).
  @POST(AppConstants.syncExpenseMessagesEndpoint)
  Future<ExpenseSyncResponseDto> commentExpense(
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
