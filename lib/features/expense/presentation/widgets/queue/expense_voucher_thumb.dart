import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:school_app_flutter/core/components/skeletons/eteelo_skeleton.dart';
import 'package:school_app_flutter/core/constants/app_colors.dart';
import 'package:school_app_flutter/core/constants/app_dimensions.dart';
import 'package:school_app_flutter/features/expense/domain/entities/expense.dart';
import 'package:school_app_flutter/features/expense/domain/entities/expense_voucher_image.dart';
import 'package:school_app_flutter/features/expense/domain/repositories/expense_voucher_repository.dart';

/// La vignette de la photo d'un bon dans la file « À viser ».
///
/// Elle lit la copie du poste, ou la télécharge : c'est aussi ce qui rend
/// le bon visable sur cette tablette (F40). Une vignette qui échoue montre
/// une marque neutre — la ligne reste ouvrable, la fiche dira pourquoi.
class ExpenseVoucherThumb extends StatefulWidget {
  final Expense expense;

  const ExpenseVoucherThumb({super.key, required this.expense});

  // L'état est attaché à une dépense : la ligne qui le porte a pour clé
  // l'identifiant de la dépense (`ExpenseVisaQueueList`).

  @override
  State<ExpenseVoucherThumb> createState() => _ExpenseVoucherThumbState();
}

class _ExpenseVoucherThumbState extends State<ExpenseVoucherThumb> {
  late final Future<ExpenseVoucherImage?> _image = _load();

  Future<ExpenseVoucherImage?> _load() async {
    final getIt = GetIt.instance;
    if (!getIt.isRegistered<ExpenseVoucherRepository>()) return null;
    final result = await getIt<ExpenseVoucherRepository>().voucherOf(
      widget.expense,
    );
    return result.fold((_) => null, (image) => image);
  }

  @override
  Widget build(BuildContext context) => ClipRRect(
    borderRadius: BorderRadius.circular(AppDimensions.expenseIconBoxRadius),
    child: SizedBox.square(
      dimension: AppDimensions.expenseVoucherQueueThumb,
      child: FutureBuilder<ExpenseVoucherImage?>(
        future: _image,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const EteeloSkeletonBox(
              height: AppDimensions.expenseVoucherQueueThumb,
            );
          }
          final image = snapshot.data;
          if (image == null || image.isPdf) {
            return _Mark(
              icon: image == null
                  ? Icons.no_photography_outlined
                  : Icons.picture_as_pdf_outlined,
            );
          }
          return Image.memory(
            image.bytes,
            fit: BoxFit.cover,
            errorBuilder: (_, _, _) =>
                const _Mark(icon: Icons.broken_image_outlined),
          );
        },
      ),
    ),
  );
}

class _Mark extends StatelessWidget {
  final IconData icon;

  const _Mark({required this.icon});

  @override
  Widget build(BuildContext context) => ColoredBox(
    color: AppColors.surfaceAlt,
    child: Center(child: Icon(icon, color: AppColors.textSecondary)),
  );
}
