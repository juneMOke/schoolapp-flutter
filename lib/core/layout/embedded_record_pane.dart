import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/widgets/outlined_panel.dart';
import 'package:school_app_flutter/core/components/selection/desktop_selection_area.dart';
import 'package:school_app_flutter/core/constants/app_dimensions.dart';

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
    return OutlinedPanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Une barre d'application réserve l'encoche de l'écran ; posée au
          // milieu de la page, elle n'en a pas.
          SizedBox(
            height: header.preferredSize.height,
            child: MediaQuery.removePadding(
              context: context,
              removeTop: true,
              child: header,
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(AppDimensions.spacingL),
              child: DesktopSelectionArea(child: child),
            ),
          ),
        ],
      ),
    );
  }
}
