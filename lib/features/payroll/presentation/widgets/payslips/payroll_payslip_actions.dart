import 'package:dartz/dartz.dart';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:school_app_flutter/core/components/documents/eteelo_document_viewer.dart';
import 'package:school_app_flutter/core/components/documents/printable_document.dart';
import 'package:school_app_flutter/core/constants/app_constants.dart';
import 'package:school_app_flutter/core/error/failures.dart';
import 'package:school_app_flutter/core/helpers/phone_number_format.dart';
import 'package:school_app_flutter/features/payroll/domain/entities/payroll_enums.dart';
import 'package:school_app_flutter/features/payroll/domain/entities/payroll_line.dart';
import 'package:school_app_flutter/features/payroll/domain/entities/payroll_month_view.dart';
import 'package:school_app_flutter/features/payroll/presentation/bloc/payroll_cubit.dart';
import 'package:school_app_flutter/features/payroll/presentation/bloc/payroll_notice.dart';
import 'package:school_app_flutter/features/payroll/presentation/bloc/payroll_state.dart';
import 'package:school_app_flutter/features/payroll/presentation/export/payroll_payslip_pdf.dart';
import 'package:school_app_flutter/features/payroll/presentation/helpers/payroll_labels.dart';
import 'package:school_app_flutter/features/payroll/presentation/widgets/payslips/payroll_payslip_content.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';
import 'package:url_launcher/url_launcher.dart';

/// Les sorties d'un bulletin : le PDF (scellé par le serveur après
/// validation, provisoire sur la tablette avant), et WhatsApp.
class PayrollPayslipActions {
  final BuildContext context;

  const PayrollPayslipActions(this.context);

  PayrollCubit get _cubit => context.read<PayrollCubit>();

  PayrollState get _state => _cubit.state;

  AppLocalizations get _l10n => AppLocalizations.of(context)!;

  /// Un agent, ou tout le livre quand [line] est `null` — ce recueil-là
  /// n'existe qu'en provisoire : le serveur ne scelle les bulletins qu'un à un.
  Future<void> openPdf(PayrollLine? line) async {
    // Le cubit est pris avant le premier `await` : la page peut se fermer
    // pendant le téléchargement ou l'aperçu.
    final cubit = _cubit;
    final view = cubit.state.view;
    if (view == null || view.lines.isEmpty) return;
    final sealed = view.phase.isLocked;
    final name = line == null
        ? _l10n.payrollPayslipsFileName(view.month)
        : '${_l10n.payrollPayslipFileName(view.month)}-${line.staffMemberId}';
    if (!sealed) {
      final bytes = await PayrollPayslipPdf.build([
        for (final l in line == null ? view.lines : [line])
          PayrollPayslipContent.of(
            context,
            snapshot: _state.snapshot,
            view: view,
            line: l,
          ),
      ]);
      if (!context.mounted) return;
      await showEteeloDocumentViewer(
        context,
        title: _l10n.payrollPayslipProvisional,
        document: PrintableDocument(bytes: bytes, fileName: '$name.pdf'),
        canShare: false,
      );
      return;
    }
    if (line == null) {
      await _serverPdf(
        cubit.commands.monthPayslips(view.month),
        title: _l10n.payrollPayslipSealed,
        fileName: '$name.pdf',
      );
      return;
    }
    final result = await cubit.commands.payslip(view.month, line.staffMemberId);
    if (!context.mounted || cubit.isClosed) return;
    await result.fold(
      (failure) async => cubit.announce(
        PayrollNotice(
          failure is NetworkFailure
              ? PayrollNoticeKind.offline
              : PayrollNoticeKind.downloadFailed,
        ),
      ),
      (bytes) async {
        await cubit.commands.recordShare(
          view.month,
          line.staffMemberId,
          PayrollShareChannel.pdf,
        );
        if (!context.mounted) return;
        await showEteeloDocumentViewer(
          context,
          title: _l10n.payrollPayslipSealed,
          document: PrintableDocument(bytes: bytes, fileName: '$name.pdf'),
        );
        if (!cubit.isClosed) await cubit.refresh();
      },
    );
  }

  /// L'état de paie du mois validé (A4 paysage), composé par le serveur —
  /// en ligne seulement (T16).
  Future<void> openStatement() async {
    final view = _state.view;
    if (view == null || !view.phase.isLocked) return;
    await _serverPdf(
      _cubit.commands.statement(view.month),
      title: _l10n.payrollStatementPrint,
      fileName: '${_l10n.payrollStatementFileName(view.month)}.pdf',
    );
  }

  /// Un PDF composé par le serveur : la visionneuse, ou l'annonce de ce qui
  /// l'empêche (hors ligne, refus).
  Future<void> _serverPdf(
    Future<Either<Failure, Uint8List>> request, {
    required String title,
    required String fileName,
  }) async {
    final cubit = _cubit;
    final result = await request;
    if (!context.mounted || cubit.isClosed) return;
    await result.fold(
      (failure) async => cubit.announce(
        PayrollNotice(
          failure is NetworkFailure
              ? PayrollNoticeKind.offline
              : PayrollNoticeKind.downloadFailed,
        ),
      ),
      (bytes) => showEteeloDocumentViewer(
        context,
        title: title,
        document: PrintableDocument(bytes: bytes, fileName: fileName),
      ),
    );
  }

  /// Le numéro WhatsApp d'un agent : celui du profil de paie, sinon celui de
  /// sa fiche.
  String? phoneOf(String staffMemberId) {
    final payout = _state.snapshot.profiles[staffMemberId]?.payoutPhone;
    final phone = payout ?? _state.snapshot.member(staffMemberId)?.phoneNumber;
    return phone == null || !PhoneNumberFormat.isValid(phone) ? null : phone;
  }

  /// Ouvre WhatsApp sur le message prérempli ; la trace reste sur la tablette
  /// (A6) — ouvrir n'est pas envoyer.
  Future<void> whatsapp(PayrollLine line) async {
    final cubit = _cubit;
    final view = cubit.state.view;
    final phone = phoneOf(line.staffMemberId);
    if (view == null || phone == null) return;
    final member = _state.snapshot.member(line.staffMemberId);
    final content = PayrollPayslipContent.of(
      context,
      snapshot: _state.snapshot,
      view: view,
      line: line,
    );
    final message = _whatsappMessage(
      line,
      view,
      name: member?.firstName ?? member?.fullName ?? '',
      month: content.monthLabel,
      school: content.schoolName,
    );
    final digits = PhoneNumberFormat.canonicalE164(phone).replaceAll('+', '');
    final uri = Uri.https(AppConstants.whatsappHost, '/$digits', {
      'text': message,
    });
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) return;
    await cubit.commands.recordShare(
      view.month,
      line.staffMemberId,
      PayrollShareChannel.whatsapp,
    );
    if (cubit.isClosed) return;
    cubit.announce(const PayrollNotice(PayrollNoticeKind.shared));
    await cubit.refresh();
  }

  /// Le message prérempli (v2) : le brut, les retenues non nulles et leur
  /// total, les jours prestés, le net, ce qui est perçu et ce qui reste.
  String _whatsappMessage(
    PayrollLine line,
    PayrollMonthView view, {
    required String name,
    required String month,
    required String school,
  }) {
    final l10n = _l10n;
    String money(int cents) => PayrollLabels.money(cents, line.currency);
    final d = line.deductions;
    final withheld = [
      if (d.iprInCents + d.cnssInCents > 0)
        '${l10n.payrollPayslipIprCnss} ${money(d.iprInCents + d.cnssInCents)}',
      if (d.absenceInCents > 0)
        '${l10n.payrollPayslipAbsence} ${money(d.absenceInCents)}',
      if (line.advanceInCents > 0)
        '${l10n.payrollPayslipSalaryAdvance} ${money(line.advanceInCents)}',
      if (d.childcareInCents > 0)
        '${l10n.payrollPayslipChildcare} ${money(d.childcareInCents)}',
    ];
    final settlement = view.settlementOf(line);
    return l10n.payrollPayslipWhatsappMessageV2(
      name,
      month,
      school,
      money(line.grossInCents),
      withheld.isEmpty ? '—' : withheld.join(', '),
      money(d.totalInCents + line.advanceInCents),
      d.workDaysDivisor == null
          ? '—'
          : l10n.payrollPayslipWorkedDaysValue(
              d.workedDays ?? d.workDaysDivisor!,
              d.workDaysDivisor!,
            ),
      money(line.netInCents),
      money(settlement.paidInCents),
      money(settlement.remainingInCents),
    );
  }
}
