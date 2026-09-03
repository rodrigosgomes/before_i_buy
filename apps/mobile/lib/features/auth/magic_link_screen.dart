import 'package:flutter/material.dart';

import '../../design_system/bib_components.dart';
import '../../design_system/bib_theme.dart';
import 'auth_gateway.dart';

const creatorAuthRedirect = 'beforeibuy://auth-callback';

class MagicLinkScreen extends StatefulWidget {
  const MagicLinkScreen({
    super.key,
    required this.authGateway,
    required this.onLinkSent,
  });

  final AuthGateway authGateway;
  final ValueChanged<String> onLinkSent;

  @override
  State<MagicLinkScreen> createState() => _MagicLinkScreenState();
}

class _MagicLinkScreenState extends State<MagicLinkScreen> {
  final _emailController = TextEditingController();
  var _sending = false;
  String? _error;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    final email = _emailController.text.trim();
    if (!_looksLikeEmail(email)) {
      setState(() => _error = 'Informe um e-mail válido.');
      return;
    }
    setState(() {
      _sending = true;
      _error = null;
    });
    try {
      await widget.authGateway.signInWithOtp(
        email: email,
        emailRedirectTo: creatorAuthRedirect,
      );
      if (mounted) widget.onLinkSent(email);
    } catch (_) {
      if (mounted) {
        setState(
          () =>
              _error = 'Não foi possível enviar o link agora. Tente novamente.',
        );
      }
    } finally {
      if (mounted) setState(() => _sending = false);
    }
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
            'Entre sem senha. Enviaremos um link seguro para o seu e-mail.',
          ),
          const SizedBox(height: BibSpacing.x6),
          BibTextField(
            controller: _emailController,
            label: 'Seu e-mail',
            keyboardType: TextInputType.emailAddress,
            autofillHints: const [AutofillHints.email],
            error: _error,
            onChanged: (_) {
              if (_error != null) setState(() => _error = null);
            },
          ),
          const SizedBox(height: BibSpacing.x4),
          const BibPrivacyNotice(
            title: 'Seu e-mail fica privado',
            body:
                'Ele serve somente para entrar na conta e nunca aparece nos convites.',
          ),
          const SizedBox(height: BibSpacing.x6),
          BibPrimaryButton(
            label: 'Receber link de entrada',
            loading: _sending,
            onPressed: _send,
          ),
        ],
      ),
    ),
  );
}

class WaitingForMagicLinkScreen extends StatefulWidget {
  const WaitingForMagicLinkScreen({
    super.key,
    required this.email,
    required this.authGateway,
    required this.onChangeEmail,
  });

  final String email;
  final AuthGateway authGateway;
  final VoidCallback onChangeEmail;

  @override
  State<WaitingForMagicLinkScreen> createState() =>
      _WaitingForMagicLinkScreenState();
}

class _WaitingForMagicLinkScreenState extends State<WaitingForMagicLinkScreen> {
  var _sending = false;
  String? _message;
  BibMessageKind _kind = BibMessageKind.info;

  Future<void> _resend() async {
    setState(() {
      _sending = true;
      _message = null;
    });
    try {
      await widget.authGateway.signInWithOtp(
        email: widget.email,
        emailRedirectTo: creatorAuthRedirect,
      );
      if (mounted) {
        setState(() {
          _message = 'Um novo link foi enviado.';
          _kind = BibMessageKind.success;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _message = 'Não foi possível reenviar agora. Tente novamente.';
          _kind = BibMessageKind.error;
        });
      }
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  @override
  Widget build(BuildContext context) => BibPageShell(
    child: ConstrainedBox(
      constraints: const BoxConstraints(minHeight: 560),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.mark_email_read_outlined, size: 56),
          const SizedBox(height: BibSpacing.x5),
          Text(
            'Confira seu e-mail',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.headlineMedium,
          ),
          const SizedBox(height: BibSpacing.x3),
          Text(
            'Enviamos um link de entrada para ${widget.email}. Volte ao app depois de abrir o link.',
            textAlign: TextAlign.center,
          ),
          if (_message != null) ...[
            const SizedBox(height: BibSpacing.x4),
            BibInlineMessage(message: _message!, kind: _kind),
          ],
          const SizedBox(height: BibSpacing.x6),
          BibPrimaryButton(
            label: 'Reenviar link',
            loading: _sending,
            onPressed: _resend,
          ),
          BibTextButton(
            label: 'Usar outro e-mail',
            onPressed: widget.onChangeEmail,
          ),
        ],
      ),
    ),
  );
}

bool _looksLikeEmail(String value) =>
    RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$').hasMatch(value);
