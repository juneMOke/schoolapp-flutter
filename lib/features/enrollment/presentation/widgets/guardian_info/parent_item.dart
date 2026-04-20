import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/theme/app_theme.dart';
import 'package:school_app_flutter/features/enrollment/domain/entities/relationship_type.dart';
import 'package:school_app_flutter/features/enrollment/presentation/widgets/guardian_info/guardian_card_header.dart';
import 'package:school_app_flutter/features/enrollment/presentation/widgets/guardian_info/guardian_fields_grid.dart';
import 'package:school_app_flutter/features/enrollment/presentation/widgets/guardian_info/parent_item_models.dart';
import 'package:school_app_flutter/features/student/domain/entities/parent_summary.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

typedef ParentItemStateChanged =
    void Function(String parentId, ParentItemFormState state);
typedef ParentItemValueChanged =
    void Function(String parentId, ParentItemValue value);

class ParentItem extends StatefulWidget {
  final ParentSummary parent;
  final bool isPrimary;
  final int number;
  final ParentItemStateChanged? onFormStateChanged;
  final ParentItemValueChanged? onValueChanged;
  final VoidCallback? onRemoveRequested;
  final bool isEditable;

  const ParentItem({
    super.key,
    required this.parent,
    required this.isPrimary,
    required this.number,
    this.onFormStateChanged,
    this.onValueChanged,
    this.onRemoveRequested,
    this.isEditable = true,
  });

  @override
  State<ParentItem> createState() => _ParentItemState();
}

class _ParentItemState extends State<ParentItem> {
  late final TextEditingController _firstNameController;
  late final TextEditingController _lastNameController;
  late final TextEditingController _surnameController;
  late final TextEditingController _phoneController;
  late final TextEditingController _emailController;

  late RelationshipType _selectedRelationshipType;

  late ParentItemValue _initialValue;
  bool _isHydratingFromParent = false;

  @override
  void initState() {
    super.initState();
    _hydrateFromParent(widget.parent, resetSnapshot: true);

    _firstNameController.addListener(_onFieldChanged);
    _lastNameController.addListener(_onFieldChanged);
    _surnameController.addListener(_onFieldChanged);
    _phoneController.addListener(_onFieldChanged);
    _emailController.addListener(_onFieldChanged);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _emitAll();
    });
  }

  @override
  void didUpdateWidget(covariant ParentItem oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.parent != widget.parent) {
      _hydrateFromParent(widget.parent, resetSnapshot: true);
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        _emitAll();
      });
    }
  }

  void _hydrateFromParent(ParentSummary parent, {required bool resetSnapshot}) {
    _isHydratingFromParent = true;
    try {
      final initial = ParentItemValue.fromParent(parent);

      if (!(_isControllerReady)) {
        _firstNameController = TextEditingController(text: initial.firstName);
        _lastNameController = TextEditingController(text: initial.lastName);
        _surnameController = TextEditingController(text: initial.surname);
        _phoneController = TextEditingController(text: initial.phoneNumber);
        _emailController = TextEditingController(text: initial.email);
      } else {
        _firstNameController.text = initial.firstName;
        _lastNameController.text = initial.lastName;
        _surnameController.text = initial.surname;
        _phoneController.text = initial.phoneNumber;
        _emailController.text = initial.email;
      }

      if (resetSnapshot) {
        _initialValue = initial;
      }
      _selectedRelationshipType = initial.relationshipType;
    } finally {
      _isHydratingFromParent = false;
    }
  }

  bool get _isControllerReady {
    try {
      _firstNameController.text;
      return true;
    } catch (_) {
      return false;
    }
  }

  ParentItemValue _currentValue() {
    return ParentItemValue(
      firstName: _firstNameController.text,
      lastName: _lastNameController.text,
      surname: _surnameController.text,
      phoneNumber: _phoneController.text,
      email: _emailController.text,
      relationshipType: _selectedRelationshipType,
    );
  }

  ParentItemFormState _currentState() {
    final value = _currentValue();
    final changed = value.changedComparedTo(_initialValue);

    // Parent update endpoint does not persist identificationNumber.
    final dirty =
        (changed['firstName'] ?? false) ||
        (changed['lastName'] ?? false) ||
        (changed['surname'] ?? false) ||
        (changed['phoneNumber'] ?? false) ||
        (changed['email'] ?? false) ||
        (changed['relationshipType'] ?? false);

    return ParentItemFormState(
      valid: value.isValid,
      dirty: dirty,
      changedFields: changed,
    );
  }

  void _emitAll() {
    final value = _currentValue();
    widget.onValueChanged?.call(widget.parent.id, value);
    widget.onFormStateChanged?.call(widget.parent.id, _currentState());
  }

  void _onFieldChanged() {
    if (_isHydratingFromParent) return;
    _emitAll();
  }

  void _onRelationshipChanged(RelationshipType value) {
    if (_selectedRelationshipType == value) return;
    setState(() => _selectedRelationshipType = value);
    _emitAll();
  }

  String _getInitials() {
    final f = widget.parent.firstName.isNotEmpty
        ? widget.parent.firstName[0]
        : '';
    final l = widget.parent.lastName.isNotEmpty
        ? widget.parent.lastName[0]
        : '';
    return '$f$l'.toUpperCase();
  }

  @override
  void dispose() {
    _firstNameController.removeListener(_onFieldChanged);
    _lastNameController.removeListener(_onFieldChanged);
    _surnameController.removeListener(_onFieldChanged);
    _phoneController.removeListener(_onFieldChanged);
    _emailController.removeListener(_onFieldChanged);

    _firstNameController.dispose();
    _lastNameController.dispose();
    _surnameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final state = _currentState();
    final changed = state.changedFields;
    const deleteColor = Color(0xFFDC2626); // rouge sémantique, constant

    return Container(
      decoration: BoxDecoration(
        color: AppTheme.surfaceColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: widget.isPrimary
              ? AppTheme.primaryColor.withValues(alpha: 0.35)
              : const Color(0xFFE5E7EB),
          width: widget.isPrimary ? 1.5 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          // ── Header compact ──────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 8, 0),
            child: Row(
              children: [
                Expanded(
                  child: GuardianCardHeader(
                    parent: widget.parent,
                    isPrimary: widget.isPrimary,
                    number: widget.number,
                    initials: _getInitials(),
                  ),
                ),
                if (widget.onRemoveRequested != null)
                  TextButton.icon(
                    onPressed: widget.onRemoveRequested,
                    icon: const Icon(
                      Icons.delete_outline_rounded,
                      size: 16,
                      color: deleteColor,
                    ),
                    label: Text(
                      l10n.guardianDeleteAction,
                      style: const TextStyle(
                        color: deleteColor,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    style: TextButton.styleFrom(
                      foregroundColor: deleteColor,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 6,
                      ),
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                  ),
              ],
            ),
          ),
          const Divider(height: 20, thickness: 1, indent: 14, endIndent: 14),
          // ── Champs ──────────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
            child: GuardianFieldsGrid(
              firstNameController: _firstNameController,
              lastNameController: _lastNameController,
              surnameController: _surnameController,
              phoneController: _phoneController,
              emailController: _emailController,
              firstNameChanged: changed['firstName'] ?? false,
              lastNameChanged: changed['lastName'] ?? false,
              surnameChanged: changed['surname'] ?? false,
              phoneChanged: changed['phoneNumber'] ?? false,
              emailChanged: changed['email'] ?? false,
              selectedRelationshipType: _selectedRelationshipType,
              onRelationshipTypeChanged: _onRelationshipChanged,
              relationshipChanged: changed['relationshipType'] ?? false,
              isEditable: widget.isEditable,
            ),
          ),
        ],
      ),
    );
  }
}
