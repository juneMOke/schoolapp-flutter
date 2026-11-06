import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/components/dialogs/eteelo_pickers.dart';
import 'package:school_app_flutter/core/constants/app_colors.dart';
import 'package:school_app_flutter/core/constants/app_dimensions.dart';
import 'package:school_app_flutter/core/constants/app_text_styles.dart';
import 'package:school_app_flutter/core/theme/app_motion.dart';

/// Ouvre le calendrier aux couleurs de la Discipline ; rend le jour choisi,
/// `null` si l'utilisateur renonce. Un fait ne se date pas dans le futur.
Future<DateTime?> pickDisciplinaryCaseDate(
  BuildContext context, {
  required DateTime initialDate,
}) {
  final baseTheme = Theme.of(context);
  return showEteeloDatePicker(
    context: context,
    initialDate: initialDate,
    firstDate: DateTime(2000),
    lastDate: DateTime.now(),
    builder: (context, child) {
      if (child == null) return const SizedBox.shrink();

      final themed = baseTheme.copyWith(
        colorScheme: baseTheme.colorScheme.copyWith(
          primary: AppColors.disciplinaryDetailAccent,
          onPrimary: AppColors.surface,
          onSurface: AppColors.textPrimary,
          surface: AppColors.surface,
        ),
        datePickerTheme: DatePickerThemeData(
          backgroundColor: AppColors.surface,
          surfaceTintColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(
              AppDimensions.sectionCardRadius,
            ),
          ),
          headerBackgroundColor: AppColors.disciplinaryDetailAccentSoft,
          headerForegroundColor: AppColors.disciplinaryDetailAccent,
          dayForegroundColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.selected)) {
              return AppColors.surface;
            }
            return AppColors.textPrimary;
          }),
          dayBackgroundColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.selected)) {
              return AppColors.disciplinaryDetailAccent;
            }
            return null;
          }),
          todayForegroundColor: const WidgetStatePropertyAll(
            AppColors.disciplinaryDetailAccent,
          ),
          todayBackgroundColor: const WidgetStatePropertyAll(
            AppColors.disciplinaryDetailAccentSoft,
          ),
          dayStyle: AppTextStyles.body,
          yearStyle: AppTextStyles.body,
        ),
        textButtonTheme: TextButtonThemeData(
          style: TextButton.styleFrom(
            foregroundColor: AppColors.disciplinaryDetailAccent,
            textStyle: AppTextStyles.action,
          ),
        ),
      );

      return Theme(data: themed, child: child);
    },
  );
}

/// La date du fait : une tuile qui ouvre le calendrier, estompée pendant
/// l'enregistrement.
class DisciplinaryCreateDateTile extends StatelessWidget {
  final DateTime date;
  final bool isLoading;
  final VoidCallback onTap;

  const DisciplinaryCreateDateTile({
    super.key,
    required this.date,
    required this.isLoading,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    // reduced-motion : les transitions du formulaire deviennent instantanées.
    final reduceMotion =
        MediaQuery.maybeOf(context)?.disableAnimations ?? false;
    return AnimatedOpacity(
      duration: reduceMotion ? Duration.zero : AppMotion.fast,
      curve: AppMotion.outCurve,
      opacity: isLoading ? 0.65 : 1,
      child: InkWell(
        onTap: isLoading ? null : onTap,
        borderRadius: BorderRadius.circular(AppDimensions.spacingM),
        child: AnimatedContainer(
          duration: reduceMotion ? Duration.zero : AppMotion.medium,
          curve: AppMotion.outCurve,
          width: double.infinity,
          padding: const EdgeInsets.all(AppDimensions.spacingM),
          decoration: BoxDecoration(
            color: AppColors.disciplinaryDetailAccentSoft,
            borderRadius: BorderRadius.circular(AppDimensions.spacingM),
            border: Border.all(
              color: AppColors.disciplinaryDetailAccent.withValues(
                alpha: isLoading ? 0.12 : 0.2,
              ),
            ),
          ),
          child: Row(
            children: [
              const Icon(
                Icons.calendar_today_outlined,
                size: AppDimensions.detailMiniIconSize,
                color: AppColors.disciplinaryDetailAccent,
              ),
              const SizedBox(width: AppDimensions.spacingS),
              Expanded(
                child: AnimatedSwitcher(
                  duration: reduceMotion ? Duration.zero : AppMotion.fast,
                  switchInCurve: AppMotion.outCurve,
                  switchOutCurve: AppMotion.inCurve,
                  child: Text(
                    MaterialLocalizations.of(context).formatMediumDate(date),
                    key: ValueKey(date),
                    style: AppTextStyles.bodyStrong.copyWith(
                      color: AppColors.textPrimary,
                    ),
                  ),
                ),
              ),
              const Icon(
                Icons.expand_more_rounded,
                color: AppColors.textSecondary,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
