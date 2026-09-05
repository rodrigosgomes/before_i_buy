import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../features/creator/draft.dart';
import 'bib_theme.dart';

class BibPageShell extends StatelessWidget {
  const BibPageShell({
    super.key,
    required this.child,
    this.topBar,
    this.bottom,
    this.scrollable = true,
  });

  final Widget child;
  final PreferredSizeWidget? topBar;
  final Widget? bottom;
  final bool scrollable;

  @override
  Widget build(BuildContext context) {
    final content = Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 560),
        child: Padding(
          padding: const EdgeInsets.all(BibSpacing.x4),
          child: scrollable ? SingleChildScrollView(child: child) : child,
        ),
      ),
    );
    return Scaffold(
      appBar: topBar,
      body: SafeArea(child: content),
      bottomNavigationBar: bottom == null
          ? null
          : SafeArea(
              minimum: const EdgeInsets.all(BibSpacing.x4),
              child: Center(
                heightFactor: 1,
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 560),
                  child: bottom,
                ),
              ),
            ),
    );
  }
}

class BibTopBar extends StatelessWidget implements PreferredSizeWidget {
  const BibTopBar({super.key, required this.title, this.onBack, this.actions});

  final String title;
  final VoidCallback? onBack;
  final List<Widget>? actions;

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) => AppBar(
    automaticallyImplyLeading: false,
    leading: onBack == null
        ? null
        : IconButton(
            onPressed: onBack,
            tooltip: 'Voltar',
            icon: const Icon(Icons.arrow_back_rounded),
          ),
    title: Text(title),
    actions: actions,
  );
}

class BibPrimaryButton extends StatelessWidget {
  const BibPrimaryButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.loading = false,
  });

  final String label;
  final VoidCallback? onPressed;
  final bool loading;

  @override
  Widget build(BuildContext context) => Semantics(
    button: true,
    enabled: onPressed != null && !loading,
    child: SizedBox(
      width: double.infinity,
      height: 52,
      child: FilledButton(
        onPressed: loading ? null : onPressed,
        child: loading
            ? const SizedBox.square(
                dimension: 22,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : Text(label),
      ),
    ),
  );
}

class BibSecondaryButton extends StatelessWidget {
  const BibSecondaryButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.loading = false,
  });

  final String label;
  final VoidCallback? onPressed;
  final bool loading;

  @override
  Widget build(BuildContext context) => Semantics(
    button: true,
    enabled: onPressed != null && !loading,
    child: SizedBox(
      width: double.infinity,
      height: 52,
      child: OutlinedButton(
        onPressed: loading ? null : onPressed,
        child: loading
            ? const SizedBox.square(
                dimension: 22,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : Text(label),
      ),
    ),
  );
}

class BibDestructiveButton extends StatelessWidget {
  const BibDestructiveButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.loading = false,
  });

  final String label;
  final VoidCallback? onPressed;
  final bool loading;

  @override
  Widget build(BuildContext context) => Semantics(
    button: true,
    enabled: onPressed != null && !loading,
    child: SizedBox(
      width: double.infinity,
      height: 52,
      child: OutlinedButton(
        style: OutlinedButton.styleFrom(
          foregroundColor: Theme.of(context).colorScheme.error,
          side: BorderSide(color: Theme.of(context).colorScheme.error),
        ),
        onPressed: loading ? null : onPressed,
        child: loading
            ? const SizedBox.square(
                dimension: 22,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : Text(label),
      ),
    ),
  );
}

class BibTextButton extends StatelessWidget {
  const BibTextButton({super.key, required this.label, this.onPressed});

  final String label;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) => ConstrainedBox(
    constraints: const BoxConstraints(minHeight: 48),
    child: TextButton(onPressed: onPressed, child: Text(label)),
  );
}

class BibTextField extends StatelessWidget {
  const BibTextField({
    super.key,
    required this.controller,
    required this.label,
    this.helper,
    this.error,
    this.onChanged,
    this.maxLength,
    this.maxLines = 1,
    this.keyboardType,
    this.autofillHints,
    this.inputFormatters,
  });

  final TextEditingController controller;
  final String label;
  final String? helper;
  final String? error;
  final ValueChanged<String>? onChanged;
  final int? maxLength;
  final int maxLines;
  final TextInputType? keyboardType;
  final Iterable<String>? autofillHints;
  final List<TextInputFormatter>? inputFormatters;

  @override
  Widget build(BuildContext context) => Semantics(
    textField: true,
    label: label,
    value: controller.text,
    child: TextField(
      controller: controller,
      onChanged: onChanged,
      maxLength: maxLength,
      maxLines: maxLines,
      keyboardType: keyboardType,
      autofillHints: autofillHints,
      inputFormatters: inputFormatters,
      decoration: InputDecoration(
        labelText: label,
        helperText: helper,
        errorText: error,
        alignLabelWithHint: maxLines > 1,
      ),
    ),
  );
}

class BibCurrencyField extends StatelessWidget {
  const BibCurrencyField({
    super.key,
    required this.controller,
    required this.onCentsChanged,
    this.error,
  });

  final TextEditingController controller;
  final ValueChanged<int> onCentsChanged;
  final String? error;

  @override
  Widget build(BuildContext context) => BibTextField(
    controller: controller,
    label: 'Preço',
    helper: 'Valor em reais',
    error: error,
    keyboardType: TextInputType.number,
    inputFormatters: [BrCurrencyInputFormatter()],
    onChanged: (value) => onCentsChanged(brlToCents(value)),
  );
}

class BrCurrencyInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final digits = newValue.text.replaceAll(RegExp(r'[^0-9]'), '');
    if (digits.isEmpty) return const TextEditingValue();
    final cents = int.tryParse(digits);
    if (cents == null) return oldValue;
    final text = centsToBrl(cents, includeSymbol: false);
    return TextEditingValue(
      text: text,
      selection: TextSelection.collapsed(offset: text.length),
    );
  }
}

class BibSelectField<T> extends StatelessWidget {
  const BibSelectField({
    super.key,
    required this.label,
    required this.value,
    required this.items,
    required this.onChanged,
  });

  final String label;
  final T value;
  final Map<T, String> items;
  final ValueChanged<T?> onChanged;

  @override
  Widget build(BuildContext context) => DropdownButtonFormField<T>(
    initialValue: value,
    isExpanded: true,
    decoration: InputDecoration(labelText: label),
    items: items.entries
        .map(
          (entry) => DropdownMenuItem<T>(
            value: entry.key,
            child: Text(entry.value, overflow: TextOverflow.ellipsis),
          ),
        )
        .toList(),
    selectedItemBuilder: (context) => items.values
        .map((value) => Text(value, overflow: TextOverflow.ellipsis))
        .toList(),
    onChanged: onChanged,
  );
}

class BibSegmentedChoice<T> extends StatelessWidget {
  const BibSegmentedChoice({
    super.key,
    required this.label,
    required this.options,
    required this.selected,
    required this.onChanged,
  });

  final String label;
  final Map<T, String> options;
  final T selected;
  final ValueChanged<T> onChanged;

  @override
  Widget build(BuildContext context) => Semantics(
    container: true,
    label: label,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: BibSpacing.x2),
        Wrap(
          spacing: BibSpacing.x2,
          runSpacing: BibSpacing.x2,
          children: options.entries
              .map(
                (entry) => ChoiceChip(
                  label: Text(entry.value),
                  selected: entry.key == selected,
                  onSelected: (_) => onChanged(entry.key),
                ),
              )
              .toList(),
        ),
      ],
    ),
  );
}

class BibDraftBanner extends StatelessWidget {
  const BibDraftBanner({super.key, this.recovered = false});

  final bool recovered;

  @override
  Widget build(BuildContext context) => Semantics(
    container: true,
    label: recovered
        ? 'Rascunho recuperado, não compartilhado'
        : 'Rascunho, não compartilhado',
    child: _BibNoticeSurface(
      color: BibColors.infoContainer,
      icon: Icons.lock_outline_rounded,
      title: 'Rascunho — não compartilhado',
      body: recovered
          ? 'Recuperamos seu rascunho neste aparelho. Revise antes de qualquer etapa futura.'
          : 'Salvo somente neste aparelho.',
    ),
  );
}

class BibPrivacyNotice extends StatelessWidget {
  const BibPrivacyNotice({
    super.key,
    required this.title,
    required this.body,
    this.attention = false,
  });

  final String title;
  final String body;
  final bool attention;

  @override
  Widget build(BuildContext context) => _BibNoticeSurface(
    color: attention ? BibColors.warningContainer : BibColors.infoContainer,
    icon: attention ? Icons.info_outline_rounded : Icons.lock_outline_rounded,
    title: title,
    body: body,
  );
}

enum BibMessageKind { info, success, warning, error }

class BibInlineMessage extends StatelessWidget {
  const BibInlineMessage({
    super.key,
    required this.message,
    this.kind = BibMessageKind.info,
  });

  final String message;
  final BibMessageKind kind;

  @override
  Widget build(BuildContext context) {
    final (color, icon) = switch (kind) {
      BibMessageKind.info => (BibColors.infoContainer, Icons.info_outline),
      BibMessageKind.success => (
        const Color(0xFFDCEAE5),
        Icons.check_circle_outline,
      ),
      BibMessageKind.warning => (
        BibColors.warningContainer,
        Icons.warning_amber_rounded,
      ),
      BibMessageKind.error => (const Color(0xFFF6DEDE), Icons.error_outline),
    };
    return Semantics(
      liveRegion: true,
      label: message,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(BibRadii.field),
        ),
        child: Padding(
          padding: const EdgeInsets.all(BibSpacing.x3),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, semanticLabel: ''),
              const SizedBox(width: BibSpacing.x2),
              Expanded(child: Text(message)),
            ],
          ),
        ),
      ),
    );
  }
}

class BibDilemmaSummary extends StatelessWidget {
  const BibDilemmaSummary({super.key, required this.draft});

  final DraftDilemma draft;

  @override
  Widget build(BuildContext context) => Semantics(
    container: true,
    label: 'Resumo do dilema',
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'O que você está considerando',
          style: Theme.of(context).textTheme.labelLarge,
        ),
        const SizedBox(height: BibSpacing.x2),
        Text(draft.itemName, style: Theme.of(context).textTheme.titleLarge),
        Text(centsToBrl(draft.priceCents)),
        Text(draft.category.label),
        Text(draft.purpose.label),
        const SizedBox(height: BibSpacing.x5),
        Text('Por que agora', style: Theme.of(context).textTheme.labelLarge),
        const SizedBox(height: BibSpacing.x2),
        DecoratedBox(
          decoration: BoxDecoration(
            color: BibColors.surfaceSubtle,
            borderRadius: BorderRadius.circular(BibRadii.card),
          ),
          child: Padding(
            padding: const EdgeInsets.all(BibSpacing.x4),
            child: SizedBox(width: double.infinity, child: Text(draft.reason)),
          ),
        ),
        const SizedBox(height: BibSpacing.x5),
        Text('Pausa escolhida', style: Theme.of(context).textTheme.labelLarge),
        Text(draft.pauseLabel),
      ],
    ),
  );
}

class BibGuestPreviewFrame extends StatelessWidget {
  const BibGuestPreviewFrame({
    super.key,
    required this.draft,
    required this.creatorName,
  });

  final String creatorName;

  final DraftDilemma draft;

  @override
  Widget build(BuildContext context) => Semantics(
    container: true,
    label: 'Prévia inerte do convite para convidados',
    child: DecoratedBox(
      decoration: BoxDecoration(
        color: BibColors.surface,
        border: Border.all(color: BibColors.outline),
        borderRadius: BorderRadius.circular(BibRadii.card),
      ),
      child: Padding(
        padding: const EdgeInsets.all(BibSpacing.x4),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const BibInlineMessage(
              message: 'Prévia — nenhuma ação será enviada.',
              kind: BibMessageKind.info,
            ),
            const SizedBox(height: BibSpacing.x4),
            Text(
              '$creatorName pediu sua perspectiva',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: BibSpacing.x3),
            BibDilemmaSummary(draft: draft),
            const SizedBox(height: BibSpacing.x4),
            const Text('Como você imagina que essa escolha vai se sentir?'),
            const SizedBox(height: BibSpacing.x2),
            const _PreviewVoteOption(
              label: 'Comprar — provavelmente vai ficar feliz',
            ),
            const SizedBox(height: BibSpacing.x2),
            const _PreviewVoteOption(label: 'Esperar — ainda é cedo'),
            const SizedBox(height: BibSpacing.x2),
            const _PreviewVoteOption(
              label: 'Deixar pra lá — provavelmente vai ficar feliz',
            ),
          ],
        ),
      ),
    ),
  );
}

class _PreviewVoteOption extends StatelessWidget {
  const _PreviewVoteOption({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) => Semantics(
    button: true,
    enabled: false,
    label: '$label, indisponível na prévia',
    child: SizedBox(
      width: double.infinity,
      height: 52,
      child: OutlinedButton(onPressed: null, child: Text(label)),
    ),
  );
}

class BibStatusChip extends StatelessWidget {
  const BibStatusChip({super.key, required this.label, this.icon});

  final String label;
  final IconData? icon;

  @override
  Widget build(BuildContext context) => Semantics(
    label: label,
    child: Chip(
      avatar: Icon(icon ?? Icons.lock_outline_rounded, size: 18),
      label: Text(label),
    ),
  );
}

class BibConsentChecklist extends StatelessWidget {
  const BibConsentChecklist({
    super.key,
    required this.termsAccepted,
    required this.privacyAccepted,
    required this.onTermsChanged,
    required this.onPrivacyChanged,
  });

  final bool termsAccepted;
  final bool privacyAccepted;
  final ValueChanged<bool> onTermsChanged;
  final ValueChanged<bool> onPrivacyChanged;

  @override
  Widget build(BuildContext context) => Semantics(
    container: true,
    label: 'Aceites internos de demonstração',
    child: Material(
      color: BibColors.surfaceSubtle,
      borderRadius: BorderRadius.circular(BibRadii.card),
      child: Padding(
        padding: const EdgeInsets.all(BibSpacing.x3),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const BibInlineMessage(
              message:
                  'Conteúdo interno de demonstração — sem validade jurídica e sem permissão para publicar.',
              kind: BibMessageKind.warning,
            ),
            CheckboxListTile(
              contentPadding: EdgeInsets.zero,
              value: termsAccepted,
              onChanged: (value) => onTermsChanged(value ?? false),
              title: const Text('Aceito os Termos de demonstração'),
              subtitle: const Text('Lorem ipsum · link jurídico indisponível'),
            ),
            CheckboxListTile(
              contentPadding: EdgeInsets.zero,
              value: privacyAccepted,
              onChanged: (value) => onPrivacyChanged(value ?? false),
              title: const Text(
                'Aceito o Aviso de Privacidade de demonstração',
              ),
              subtitle: const Text('Lorem ipsum · link jurídico indisponível'),
            ),
          ],
        ),
      ),
    ),
  );
}

class _BibNoticeSurface extends StatelessWidget {
  const _BibNoticeSurface({
    required this.color,
    required this.icon,
    required this.title,
    required this.body,
  });

  final Color color;
  final IconData icon;
  final String title;
  final String body;

  @override
  Widget build(BuildContext context) => DecoratedBox(
    decoration: BoxDecoration(
      color: color,
      borderRadius: BorderRadius.circular(BibRadii.card),
    ),
    child: Padding(
      padding: const EdgeInsets.all(BibSpacing.x4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, semanticLabel: ''),
          const SizedBox(width: BibSpacing.x3),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: Theme.of(context).textTheme.labelLarge),
                const SizedBox(height: BibSpacing.x1),
                Text(body),
              ],
            ),
          ),
        ],
      ),
    ),
  );
}
