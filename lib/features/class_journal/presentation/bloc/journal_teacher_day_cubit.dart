import 'package:school_app_flutter/features/class_journal/domain/usecases/load_teacher_journal_day_use_case.dart';
import 'package:school_app_flutter/features/class_journal/presentation/bloc/journal_day_cubit.dart';

/// La page du journal d'un enseignant, lue en ligne par la direction : le
/// même cubit de journée, sans signaux de synchronisation. Un type à part pour
/// s'enregistrer en fabrique à côté de celui du professeur.
class JournalTeacherDayCubit extends JournalDayCubit {
  JournalTeacherDayCubit({
    required LoadTeacherJournalDayUseCase super.load,
    super.initialDate,
  });
}
