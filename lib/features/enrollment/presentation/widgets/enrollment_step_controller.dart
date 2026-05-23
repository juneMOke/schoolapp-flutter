import 'package:flutter/material.dart';

abstract class EnrollmentStepController {
  void submitForm();
}

class EnrollmentStepSubmitController implements EnrollmentStepController {
  VoidCallback? _submitAction;

  bool get isBound => _submitAction != null;

  void bind(VoidCallback submitAction) {
    _submitAction = submitAction;
  }

  void unbind(VoidCallback submitAction) {
    if (identical(_submitAction, submitAction)) {
      _submitAction = null;
    }
  }

  @override
  void submitForm() {
    _submitAction?.call();
  }
}
