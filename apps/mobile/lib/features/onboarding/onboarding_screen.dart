import 'package:flutter/material.dart';

import '../../design_system/bib_components.dart';
import '../../design_system/bib_theme.dart';
import 'onboarding_repository.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({
    super.key,
    required this.initialValue,
    required this.onComplete,
  });

  final LocalOnboarding? initialValue;
  final ValueChanged<LocalOnboarding> onComplete;

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  late final TextEditingController _nameController;
  late bool _adultConfirmed;
  late bool _termsAccepted;
  late bool _privacyAccepted;

  @override
  void initState() {
    super.initState();
    final value = widget.initialValue;
    _nameController = TextEditingController(text: value?.displayName ?? '');
    _adultConfirmed = value?.adultConfirmed ?? false;
    _termsAccepted = value?.termsAccepted ?? false;
    _privacyAccepted = value?.privacyAccepted ?? false;
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  LocalOnboarding get _value => LocalOnboarding(
    displayName: _nameController.text.trim(),
    adultConfirmed: _adultConfirmed,
    termsAccepted: _termsAccepted,
    privacyAccepted: _privacyAccepted,
  );

  @override
  Widget build(BuildContext context) => BibPageShell(
    topBar: const BibTopBar(title: 'Seu espaço privado'),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Antes de continuar, vamos deixar tudo claro',
          style: Theme.of(context).textTheme.headlineMedium,
        ),
        const SizedBox(height: BibSpacing.x3),
        const Text(
          'Uma etapa calma para preparar seu perfil interno. Nada será publicado.',
        ),
        const SizedBox(height: BibSpacing.x6),
        BibTextField(
          controller: _nameController,
          label: 'Como seus amigos chamam você?',
          helper: 'Esse nome será usado apenas em um convite futuro.',
          maxLength: 80,
          onChanged: (_) => setState(() {}),
        ),
        const SizedBox(height: BibSpacing.x4),
        DecoratedBox(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(BibRadii.card),
          ),
          child: CheckboxListTile(
            value: _adultConfirmed,
            onChanged: (value) =>
                setState(() => _adultConfirmed = value ?? false),
            title: const Text('Confirmo que tenho 18 anos ou mais'),
            subtitle: const Text('Não coletamos sua data de nascimento.'),
          ),
        ),
        const SizedBox(height: BibSpacing.x4),
        BibConsentChecklist(
          termsAccepted: _termsAccepted,
          privacyAccepted: _privacyAccepted,
          onTermsChanged: (value) => setState(() => _termsAccepted = value),
          onPrivacyChanged: (value) => setState(() => _privacyAccepted = value),
        ),
        const SizedBox(height: BibSpacing.x6),
        BibPrimaryButton(
          label: 'Continuar',
          onPressed: _value.isComplete ? () => widget.onComplete(_value) : null,
        ),
      ],
    ),
  );
}
