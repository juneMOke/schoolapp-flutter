import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/components/selection/desktop_selection_area.dart';
import 'package:school_app_flutter/core/constants/app_dimensions.dart';
import 'package:school_app_flutter/core/theme/tokens/app_colors.dart';
import 'package:school_app_flutter/core/theme/tokens/app_radius.dart';

/// Une fiche montrée à côté de sa liste (cf. `MasterDetailLayout`) : sa barre
/// en tête, comme en page entière, et son contenu qui défile dessous.
class EmbeddedRecordPane extends StatelessWidget {
  final PreferredSizeWidget header;
  final Widget child;

  const EmbeddedRecordPane({
    super.key,
    required this.header,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: AppRadius.brCard,
        border: Border.all(color: AppColors.border),
      ),
      child: ClipRRect(
        borderRadius: AppRadius.brCard,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SizedBox(height: header.preferredSize.height, child: header),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(AppDimensions.spacingL),
                child: DesktopSelectionArea(child: child),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
