import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:school_app_flutter/features/communication/domain/entities/announcement_audience.dart';
import 'package:school_app_flutter/features/communication/domain/entities/audience_student.dart';
import 'package:school_app_flutter/features/communication/presentation/bloc/editor/announcement_editor_state.dart';
import 'package:school_app_flutter/features/communication/presentation/bloc/editor/audience_selections.dart';

/// Les gestes du ciblage : chacun produit de nouvelles sélections, que
/// l'éditeur applique ([selectAudience]).
mixin AudienceEditing on Cubit<AnnouncementEditorState> {
  void selectAudience(AudienceSelections selections);

  void setAudienceMode(AudienceMode mode) =>
      selectAudience(state.selections.withMode(mode));

  void toggleLevel(String id) =>
      selectAudience(state.selections.toggleLevel(id));

  void toggleClassroom(String id) =>
      selectAudience(state.selections.toggleClassroom(id));

  void toggleClassrooms(List<String> ids) =>
      selectAudience(state.selections.toggleClassrooms(ids));

  void addStudent(AudienceStudent student) =>
      selectAudience(state.selections.addStudent(student));

  void removeStudent(String id) =>
      selectAudience(state.selections.removeStudent(id));

  void setOverdueFee(String? feeCode, {String? tariffCode}) =>
      selectAudience(state.selections.withFee(feeCode, tariffCode: tariffCode));

  void setOverdueDays(int days) =>
      selectAudience(state.selections.withOverdueDays(days));
}
