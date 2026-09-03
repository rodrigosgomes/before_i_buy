import 'package:flutter/material.dart';

import '../../design_system/bib_components.dart';
import '../../design_system/bib_theme.dart';
import 'auth_gateway.dart';

class GoogleSignInScreen extends StatefulWidget {
  const GoogleSignInScreen({super.key, required this.authGateway});

  final AuthGateway authGateway;

  @override
  State<GoogleSignInScreen> createState() => _GoogleSignInScreenState();
}

class _GoogleSignInScreenState extends State<GoogleSignInScreen> {
  var _signingIn = false;
  String? _message;

  Future<void> _signIn() async {
    if (_signingIn) return;
    setState(() {
      _signingIn = true;
      _message = null;
    });
    final result = await widget.authGateway.signInWithGoogle();
    if (!mounted) return;
    setState(() {
      _signingIn = false;
      _message = switch (result) {
        SocialAuthResult.authenticated => null,
        SocialAuthResult.cancelled =>
          'Entrada cancelada. Você pode tentar quando quiser.',
        SocialAuthResult.failed =>
          'Não foi possível entrar agora. Tente novamente em alguns instantes.',
      };
    });
  }

  @override
  Widget build(BuildContext context) => BibPageShell(
    child: ConstrainedBox(
      constraints: const BoxConstraints(minHeight: 600),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.spa_outlined,
            size: 44,
            color: Theme.of(context).colorScheme.primary,
            semanticLabel: 'Before I Buy',
          ),
          const SizedBox(height: BibSpacing.x5),
          Text(
            'Um espaço antes de decidir',
            style: Theme.of(context).textTheme.headlineMedium,
          ),
          const SizedBox(height: BibSpacing.x3),
          const Text(
            'Entre para guardar seu espaço privado e retomar seus rascunhos neste aparelho.',
          ),
          const SizedBox(height: BibSpacing.x6),
          if (_message != null) ...[
            BibInlineMessage(message: _message!, kind: BibMessageKind.warning),
            const SizedBox(height: BibSpacing.x4),
          ],
          SizedBox(
            width: double.infinity,
            height: 52,
            child: OutlinedButton.icon(
              onPressed: _signingIn ? null : _signIn,
              icon: _signingIn
                  ? const SizedBox.square(
                      dimension: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Image.asset(
                      'assets/google_g_logo.png',
                      width: 20,
                      height: 20,
                      semanticLabel: 'Google',
                    ),
              label: Text(
                _signingIn ? 'Abrindo Google…' : 'Continuar com Google',
              ),
            ),
          ),
          const SizedBox(height: BibSpacing.x4),
          const BibPrivacyNotice(
            title: 'Sua identidade fica privada',
            body:
                'O Google fornece dados de autenticação para sua conta. Nome e e-mail nunca aparecem nos convites.',
          ),
        ],
      ),
    ),
  );
}
