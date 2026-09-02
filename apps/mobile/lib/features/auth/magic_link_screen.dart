import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class MagicLinkScreen extends StatefulWidget {
  const MagicLinkScreen({super.key, required this.onAuthenticated});

  final VoidCallback onAuthenticated;

  @override
  State<MagicLinkScreen> createState() => _MagicLinkScreenState();
}

class _MagicLinkScreenState extends State<MagicLinkScreen> {
  final _emailController = TextEditingController();
  var _sending = false;
  String? _message;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    final email = _emailController.text.trim();
    if (!email.contains('@')) {
      setState(() => _message = 'Informe um e-mail válido.');
      return;
    }
    setState(() {
      _sending = true;
      _message = null;
    });
    try {
      await Supabase.instance.client.auth.signInWithOtp(email: email);
      if (mounted) {
        setState(() => _message = 'Enviamos um link seguro para seu e-mail.');
      }
    } on AuthException {
      if (mounted) {
        setState(
          () => _message =
              'Não foi possível enviar o link agora. Tente novamente.',
        );
      }
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    body: SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Spacer(),
            Text(
              'Antes de publicar, entre com calma',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: 12),
            const Text(
              'Usamos seu e-mail somente para entrar na sua conta. Não aparece nos convites.',
            ),
            const SizedBox(height: 24),
            TextField(
              controller: _emailController,
              keyboardType: TextInputType.emailAddress,
              autofillHints: const [AutofillHints.email],
              decoration: const InputDecoration(
                labelText: 'Seu e-mail',
                border: OutlineInputBorder(),
              ),
            ),
            if (_message != null)
              Padding(
                padding: const EdgeInsets.only(top: 12),
                child: Text(_message!, semanticsLabel: _message),
              ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: FilledButton(
                onPressed: _sending ? null : _send,
                child: Text(_sending ? 'Enviando…' : 'Receber link de entrada'),
              ),
            ),
            const Spacer(),
          ],
        ),
      ),
    ),
  );
}
