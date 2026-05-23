import 'package:flutter/material.dart';

/// Widget réutilisable pour afficher un état chargement
class EnrollmentLoadingState extends StatelessWidget {
  final String? message;

  const EnrollmentLoadingState({
    super.key,
    this.message,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      key: const ValueKey('enrollment-table-loading'),
      padding: const EdgeInsets.symmetric(vertical: 64, horizontal: 32),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(
              width: 44,
              height: 44,
              child: CircularProgressIndicator(strokeWidth: 3),
            ),
            const SizedBox(height: 16),
            Text(
              message ?? 'Chargement des étudiants...',
              style: Theme.of(context)
                  .textTheme
                  .bodyMedium
                  ?.copyWith(color: Colors.grey.shade600),
            ),
          ],
        ),
      ),
    );
  }
}

/// Widget réutilisable pour afficher un état erreur
class EnrollmentErrorState extends StatelessWidget {
  final String? errorMessage;

  const EnrollmentErrorState({
    super.key,
    this.errorMessage,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      key: const ValueKey('enrollment-table-error'),
      padding: const EdgeInsets.symmetric(vertical: 64, horizontal: 32),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                borderRadius: BorderRadius.circular(40),
              ),
              child: Icon(
                Icons.error_outline_rounded,
                size: 40,
                color: Colors.red.shade600,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'Erreur de chargement',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 6),
            Text(
              errorMessage ?? 'Une erreur est survenue',
              textAlign: TextAlign.center,
              style: Theme.of(context)
                  .textTheme
                  .bodySmall
                  ?.copyWith(color: Colors.grey.shade600),
            ),
          ],
        ),
      ),
    );
  }
}

/// Widget réutilisable pour afficher un état vide
class EnrollmentEmptyState extends StatelessWidget {
  final String? message;

  const EnrollmentEmptyState({
    super.key,
    this.message,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      key: const ValueKey('enrollment-table-empty'),
      padding: const EdgeInsets.symmetric(vertical: 64, horizontal: 32),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(40),
              ),
              child: Icon(
                Icons.people_outline_rounded,
                size: 40,
                color: Colors.blue.shade600,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'Aucun résultat',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 6),
            Text(
              message ?? 'Aucun étudiant trouvé',
              textAlign: TextAlign.center,
              style: Theme.of(context)
                  .textTheme
                  .bodySmall
                  ?.copyWith(color: Colors.grey.shade600),
            ),
          ],
        ),
      ),
    );
  }
}

/// Widget réutilisable pour afficher l'état initial (avant recherche)
class EnrollmentInitialState extends StatelessWidget {
  final String? message;

  const EnrollmentInitialState({
    super.key,
    this.message,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      key: const ValueKey('enrollment-table-initial'),
      padding: const EdgeInsets.symmetric(vertical: 64, horizontal: 32),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(40),
              ),
              child: Icon(
                Icons.search_rounded,
                size: 40,
                color: Colors.grey.shade600,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'Lancer une recherche',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 6),
            Text(
              message ?? 'Lancez une recherche pour voir les résultats',
              textAlign: TextAlign.center,
              style: Theme.of(context)
                  .textTheme
                  .bodySmall
                  ?.copyWith(color: Colors.grey.shade600),
            ),
          ],
        ),
      ),
    );
  }
}
