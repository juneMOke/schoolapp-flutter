import 'package:flutter/material.dart';
import 'package:school_app_flutter/features/auth/presentation/widgets/login/login_screen_layout.dart';
import 'package:school_app_flutter/features/auth/presentation/widgets/login_form.dart';

/// Écran de connexion ETEELO CONNECT (spec Connexion). Verrou éditorial à deux
/// panneaux responsive — la mise en page est portée par [LoginScreenLayout],
/// le contenu du formulaire par [LoginForm].
class LoginPage extends StatelessWidget {
  const LoginPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const LoginScreenLayout(form: LoginForm());
  }
}
