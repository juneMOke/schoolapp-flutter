import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:school_app_flutter/core/components/dialogs/eteelo_dialog_body.dart';
import 'package:school_app_flutter/core/components/labels/audience_note.dart';
import 'package:school_app_flutter/core/components/status/sync_status_cubit.dart';
import 'package:school_app_flutter/core/constants/app_dimensions.dart';
import 'package:school_app_flutter/core/widgets/app_snack_bar.dart';
import 'package:school_app_flutter/features/attendances/domain/entities/disciplinary_category.dart';
import 'package:school_app_flutter/features/attendances/domain/entities/disciplinary_sanction.dart';
import 'package:school_app_flutter/features/attendances/domain/entities/disciplinary_severity.dart';
import 'package:school_app_flutter/features/attendances/domain/entities/student_gender.dart';
import 'package:school_app_flutter/features/attendances/presentation/bloc/offline/disciplinary_case_offline_bloc.dart';
import 'package:school_app_flutter/features/attendances/presentation/bloc/offline/disciplinary_case_offline_event.dart';
import 'package:school_app_flutter/features/attendances/presentation/bloc/offline/disciplinary_case_offline_state.dart';
import 'package:school_app_flutter/features/attendances/presentation/widgets/disciplinary_case_create/disciplinary_create_date_field.dart';
import 'package:school_app_flutter/features/attendances/presentation/widgets/disciplinary_case_create/disciplinary_create_fields.dart';
import 'package:school_app_flutter/features/attendances/presentation/widgets/disciplinary_case_create/disciplinary_create_footer.dart';
import 'package:school_app_flutter/features/attendances/presentation/widgets/disciplinary_case_create/disciplinary_create_header.dart';
import 'package:school_app_flutter/features/attendances/presentation/widgets/disciplinary_case_dialog_shell.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

class DisciplinaryCaseCreateDialog extends StatefulWidget {
  final String studentId;
  final String studentFirstName;
  final String studentLastName;
  final String? studentMiddleName;

  /// Genre de l'élève en valeur API (MALE / FEMALE / OTHER).
  final String studentGender;
  final String academicYearId;

  const DisciplinaryCaseCreateDialog({
    super.key,
    required this.studentId,
    required this.studentFirstName,
    required this.studentLastName,
    this.studentMiddleName,
    required this.studentGender,
    required this.academicYearId,
  });

  @override
  State<DisciplinaryCaseCreateDialog> createState() =>
      _DisciplinaryCaseCreateDialogState();
}

class _DisciplinaryCaseCreateDialogState
    extends State<DisciplinaryCaseCreateDialog> {
  late final TextEditingController _titleController;
  late final TextEditingController _contentController;
  late DateTime _selectedDate;
  final _formKey = GlobalKey<FormState>();

  DisciplinaryCategory _category = DisciplinaryCategory.disruptiveBehavior;
  late DisciplinarySeverity _severity;
  DisciplinarySanction _sanction = DisciplinarySanction.unknown;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController();
    _contentController = TextEditingController();
    _selectedDate = DateTime.now();
    _severity = _category.defaultSeverity;
  }

  /// Choisir une catégorie sert de gabarit : pré-remplit la gravité par défaut
  /// et le titre (s'il est encore vide).
  void _onCategoryChanged(
    DisciplinaryCategory category,
    AppLocalizations l10n,
  ) {
    setState(() {
      _category = category;
      _severity = category.defaultSeverity;
      if (_titleController.text.trim().isEmpty) {
        _titleController.text = category.getDisplayName(l10n);
      }
    });
  }

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  Future<void> _selectDate(BuildContext context) async {
    final picked = await pickDisciplinaryCaseDate(
      context,
      initialDate: _selectedDate,
    );
    if (!mounted) return;
    if (picked != null && picked != _selectedDate) {
      setState(() => _selectedDate = picked);
    }
  }

  void _submit(BuildContext context) {
    if (!_formKey.currentState!.validate()) return;

    // Offline-first strict : l'écriture passe par le BLoC offline (écriture
    // locale + mise en file outbox) au lieu de l'appel online. Mêmes 12 champs
    // que l'ancien DisciplinaryCaseCreateRequested.
    context.read<DisciplinaryCaseOfflineBloc>().add(
      CreateOfflineDisciplinaryCase(
        studentId: widget.studentId,
        studentFirstName: widget.studentFirstName,
        studentLastName: widget.studentLastName,
        studentMiddleName: widget.studentMiddleName,
        studentGender: StudentGenderX.fromApiValue(widget.studentGender),
        disciplinaryCaseDate: _selectedDate,
        academicYearId: widget.academicYearId,
        title: _titleController.text.trim(),
        content: _contentController.text.trim(),
        category: _category,
        severity: _severity,
        sanction: _sanction,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return DisciplinaryCaseDialogShell(
      maxWidth: AppDimensions.disciplinaryCreateDialogMaxWidth,
      child:
          BlocListener<
            DisciplinaryCaseOfflineBloc,
            DisciplinaryCaseOfflineState
          >(
            listenWhen: (prev, curr) => prev != curr,
            listener: (context, state) {
              // Succès offline : cas écrit en local + enfilé (pending-sync).
              if (state is DisciplinaryOfflineCasePendingSync) {
                AppSnackBar.showSuccess(
                  context,
                  l10n.offlineDisciplinaryCaseQueued,
                );
                context.read<SyncStatusCubit>().notifyLocalWrite();
                Navigator.pop(context);
                return;
              }

              if (state is DisciplinaryOfflineError) {
                AppSnackBar.showError(context, l10n.offlineWriteError);
              }
            },
            child:
                BlocBuilder<
                  DisciplinaryCaseOfflineBloc,
                  DisciplinaryCaseOfflineState
                >(
                  buildWhen: (prev, curr) =>
                      (prev is DisciplinaryOfflineSaving) !=
                      (curr is DisciplinaryOfflineSaving),
                  builder: (context, state) => _buildForm(context, l10n, state),
                ),
          ),
    );
  }

  Widget _buildForm(
    BuildContext context,
    AppLocalizations l10n,
    DisciplinaryCaseOfflineState state,
  ) {
    final isLoading = state is DisciplinaryOfflineSaving;
    return EteeloDialogBody(
      // En-tête + pied à boutons ≈ 210 dp incompressibles. Au-dessus de ce
      // seuil ils tiennent et restent ancrés ; en dessous — téléphone en
      // paysage, clavier ouvert — ils rejoignent le défilement au lieu de
      // déborder (mesuré : 149 dp de débordement sur 640×360, 129 sur
      // 760×380, 98 sur 731×411).
      minPinnedHeight: 260,
      // Le formulaire occupait déjà toute la hauteur offerte : on la garde.
      pinnedMainAxisSize: MainAxisSize.max,
      header: DisciplinaryCreateHeader(isLoading: isLoading),
      bodyPadding: const EdgeInsets.all(AppDimensions.spacingM),
      body: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Le portail montre le fait aux parents (gravité, sanction), pas
            // ses commentaires ni son statut : l'agent le sait en l'écrivant.
            AudienceNote(l10n.disciplinaryCaseVisibleToParents),
            const SizedBox(height: AppDimensions.spacingM),
            const DisciplinaryCreateStatusBlock(),
            const SizedBox(height: AppDimensions.spacingM),
            DisciplinaryCreateCategoryField(
              value: _category,
              enabled: !isLoading,
              onChanged: (value) => _onCategoryChanged(value, l10n),
            ),
            const SizedBox(height: AppDimensions.spacingM),
            DisciplinaryCreateSeverityField(
              value: _severity,
              onChanged: (value) => setState(() => _severity = value),
            ),
            const SizedBox(height: AppDimensions.spacingM),
            DisciplinaryCreateTextField(
              label: l10n.disciplinaryCaseCreateDialogTitleField,
              hint: l10n.disciplinaryCaseCreateDialogTitleHint,
              controller: _titleController,
              enabled: !isLoading,
            ),
            const SizedBox(height: AppDimensions.spacingM),
            DisciplinaryCreateTextField(
              label: l10n.disciplinaryCaseCreateDialogContentField,
              hint: l10n.disciplinaryCaseCreateDialogContentHint,
              controller: _contentController,
              enabled: !isLoading,
              multiline: true,
            ),
            const SizedBox(height: AppDimensions.spacingM),
            DisciplinaryCreateFieldLabel(
              l10n.disciplinaryCaseCreateDialogCaseDateField,
            ),
            const SizedBox(height: AppDimensions.spacingXS),
            DisciplinaryCreateDateTile(
              date: _selectedDate,
              isLoading: isLoading,
              onTap: () => _selectDate(context),
            ),
            const SizedBox(height: AppDimensions.spacingM),
            DisciplinaryCreateSanctionField(
              value: _sanction,
              enabled: !isLoading,
              onChanged: (value) => setState(() => _sanction = value),
            ),
          ],
        ),
      ),
      footer: [
        DisciplinaryCreateFooter(
          isLoading: isLoading,
          onSubmit: () => _submit(context),
        ),
      ],
    );
  }
}
