import 'package:equatable/equatable.dart';
import 'package:school_app_flutter/core/error/failures.dart';
import 'package:school_app_flutter/features/hr_personnel/domain/hr_roster_query.dart';
import 'package:school_app_flutter/features/hr_personnel/domain/hr_staff_member_row.dart';

const Object _undefined = Object();

enum HrStaffMembersStatus { loading, ready, failure }

class HrStaffMembersState extends Equatable {
  /// Les critères affichés — la recherche suit la frappe, avant même que le
  /// serveur ait répondu.
  final HrRosterQuery query;
  final HrStaffMembersStatus status;

  /// La dernière page lue. Elle reste affichée pendant qu'une autre page
  /// charge ; une autre question (filtre, ordre) la retire.
  final HrStaffMembersPage? page;
  final Failure? failure;

  /// La question qui a produit [page] — celle que le PDF reprend.
  final HrRosterQuery? answered;

  const HrStaffMembersState({
    this.query = HrRosterQuery.none,
    this.status = HrStaffMembersStatus.loading,
    this.page,
    this.failure,
    this.answered,
  });

  HrStaffMembersState copyWith({
    HrRosterQuery? query,
    HrStaffMembersStatus? status,
    Object? page = _undefined,
    Object? failure = _undefined,
    Object? answered = _undefined,
  }) => HrStaffMembersState(
    query: query ?? this.query,
    status: status ?? this.status,
    page: identical(page, _undefined) ? this.page : page as HrStaffMembersPage?,
    failure: identical(failure, _undefined)
        ? this.failure
        : failure as Failure?,
    answered: identical(answered, _undefined)
        ? this.answered
        : answered as HrRosterQuery?,
  );

  @override
  List<Object?> get props => [query, status, page, failure, answered];
}
