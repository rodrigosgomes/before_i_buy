import 'package:flutter/material.dart';

import '../../design_system/bib_components.dart';
import '../../design_system/bib_theme.dart';
import 'draft.dart';

class CreatorHomeScreen extends StatelessWidget {
  const CreatorHomeScreen({super.key, required this.onCreate});

  final VoidCallback onCreate;

  @override
  Widget build(BuildContext context) => BibPageShell(
    scrollable: false,
    bottom: BibPrimaryButton(
      label: 'Criar minha primeira tentação',
      onPressed: onCreate,
    ),
    child: LayoutBuilder(
      builder: (context, constraints) => SingleChildScrollView(
        child: ConstrainedBox(
          constraints: BoxConstraints(minHeight: constraints.maxHeight),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                Icons.chat_bubble_outline_rounded,
                size: 56,
                color: Theme.of(context).colorScheme.primary,
                semanticLabel: 'Conversa privada',
              ),
              const SizedBox(height: BibSpacing.x5),
              Text(
                'Um pouco de espaço antes de decidir',
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              const SizedBox(height: BibSpacing.x3),
              const Text(
                'Organize a vontade, peça perspectiva a pessoas próximas e escolha no seu tempo.',
              ),
              const SizedBox(height: BibSpacing.x6),
              const _Chapter(number: '1', label: 'Conte o que está pensando'),
              const _Chapter(number: '2', label: 'Ouça perspectivas'),
              const _Chapter(number: '3', label: 'Decida você'),
              const SizedBox(height: BibSpacing.x6),
              const BibPrivacyNotice(
                title: 'Seu espaço é privado',
                body:
                    'Seus dilemas só abrirão para quem receber um link em uma etapa futura.',
              ),
            ],
          ),
        ),
      ),
    ),
  );
}

class _Chapter extends StatelessWidget {
  const _Chapter({required this.number, required this.label});
  final String number;
  final String label;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: BibSpacing.x3),
    child: Row(
      children: [
        CircleAvatar(
          radius: 18,
          backgroundColor: BibColors.surfaceSubtle,
          foregroundColor: BibColors.textPrimary,
          child: Text(number),
        ),
        const SizedBox(width: BibSpacing.x3),
        Expanded(child: Text(label)),
      ],
    ),
  );
}

class DraftScreen extends StatefulWidget {
  const DraftScreen({
    super.key,
    required this.draft,
    required this.recovered,
    required this.onChanged,
    required this.onReview,
    required this.onBack,
  });

  final DraftDilemma draft;
  final bool recovered;
  final ValueChanged<DraftDilemma> onChanged;
  final VoidCallback onReview;
  final VoidCallback onBack;

  @override
  State<DraftScreen> createState() => _DraftScreenState();
}

class _DraftScreenState extends State<DraftScreen> {
  late final TextEditingController _itemController;
  late final TextEditingController _priceController;
  late final TextEditingController _reasonController;
  var _showErrors = false;

  @override
  void initState() {
    super.initState();
    _itemController = TextEditingController(text: widget.draft.itemName);
    _priceController = TextEditingController(
      text: widget.draft.priceCents == 0
          ? ''
          : centsToBrl(widget.draft.priceCents, includeSymbol: false),
    );
    _reasonController = TextEditingController(text: widget.draft.reason);
  }

  @override
  void dispose() {
    _itemController.dispose();
    _priceController.dispose();
    _reasonController.dispose();
    super.dispose();
  }

  void _change(DraftDilemma value) {
    widget.onChanged(value);
    if (_showErrors) setState(() {});
  }

  void _review() {
    if (!widget.draft.isValid) {
      setState(() => _showErrors = true);
      return;
    }
    widget.onReview();
  }

  @override
  Widget build(BuildContext context) {
    final errors = _showErrors
        ? widget.draft.validationErrors
        : const <DraftField, String>{};
    return BibPageShell(
      topBar: BibTopBar(title: 'Nova tentação', onBack: widget.onBack),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          BibDraftBanner(recovered: widget.recovered),
          const SizedBox(height: BibSpacing.x5),
          BibTextField(
            controller: _itemController,
            label: 'Nome do item',
            helper: 'De 2 a 80 caracteres',
            maxLength: 80,
            error: errors[DraftField.itemName],
            onChanged: (value) =>
                _change(widget.draft.copyWith(itemName: value)),
          ),
          const SizedBox(height: BibSpacing.x4),
          BibCurrencyField(
            controller: _priceController,
            error: errors[DraftField.price],
            onCentsChanged: (value) =>
                _change(widget.draft.copyWith(priceCents: value)),
          ),
          const SizedBox(height: BibSpacing.x4),
          BibSelectField<ItemCategory>(
            label: 'Categoria',
            value: widget.draft.category,
            items: {
              for (final value in ItemCategory.values) value: value.label,
            },
            onChanged: (value) {
              if (value != null) {
                _change(widget.draft.copyWith(category: value));
              }
            },
          ),
          const SizedBox(height: BibSpacing.x5),
          DecoratedBox(
            decoration: BoxDecoration(
              color: BibColors.surfaceSubtle,
              borderRadius: BorderRadius.circular(BibRadii.hero),
            ),
            child: Padding(
              padding: const EdgeInsets.all(BibSpacing.x4),
              child: BibTextField(
                controller: _reasonController,
                label: 'Por que você está pensando nisso agora?',
                helper:
                    'O que você espera que isso mude, substitua ou torne possível?',
                maxLength: 500,
                maxLines: 5,
                error: errors[DraftField.reason],
                onChanged: (value) =>
                    _change(widget.draft.copyWith(reason: value)),
              ),
            ),
          ),
          const SizedBox(height: BibSpacing.x5),
          BibSegmentedChoice<DraftPurpose>(
            label: 'É para quem?',
            options: {
              for (final purpose in DraftPurpose.values) purpose: purpose.label,
            },
            selected: widget.draft.purpose,
            onChanged: (value) =>
                _change(widget.draft.copyWith(purpose: value)),
          ),
          const SizedBox(height: BibSpacing.x5),
          BibSegmentedChoice<int>(
            label: 'Quanto espaço você quer antes de decidir?',
            options: const {24: '24 horas', 72: '3 dias', 168: '7 dias'},
            selected: widget.draft.pauseHours,
            onChanged: (value) =>
                _change(widget.draft.copyWith(pauseHours: value)),
          ),
          const SizedBox(height: BibSpacing.x5),
          const BibPrivacyNotice(
            title: 'Salvo neste aparelho',
            body:
                'Revisar organiza o conteúdo, mas não publica nem compartilha nada.',
          ),
          const SizedBox(height: BibSpacing.x6),
          BibPrimaryButton(label: 'Revisar', onPressed: _review),
        ],
      ),
    );
  }
}

class ReviewScreen extends StatelessWidget {
  const ReviewScreen({
    super.key,
    required this.draft,
    required this.recovered,
    required this.onEdit,
  });

  final DraftDilemma draft;
  final bool recovered;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) => BibPageShell(
    topBar: BibTopBar(title: 'Revisar', onBack: onEdit),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Tudo certo para pedir uma perspectiva?',
          style: Theme.of(context).textTheme.headlineMedium,
        ),
        const SizedBox(height: BibSpacing.x3),
        const Text('Confira com calma. Nada foi compartilhado ainda.'),
        const SizedBox(height: BibSpacing.x5),
        BibDraftBanner(recovered: recovered),
        const SizedBox(height: BibSpacing.x6),
        BibDilemmaSummary(draft: draft),
        const SizedBox(height: BibSpacing.x6),
        const BibPrivacyNotice(
          title: 'Continua privado',
          body:
              'Prévia, publicação e compartilhamento serão habilitados somente em uma próxima etapa.',
        ),
        const SizedBox(height: BibSpacing.x5),
        Align(
          alignment: Alignment.center,
          child: BibTextButton(label: 'Editar', onPressed: onEdit),
        ),
        const SizedBox(height: BibSpacing.x2),
        const BibPrimaryButton(
          label: 'Publicação disponível na próxima etapa',
          onPressed: null,
        ),
      ],
    ),
  );
}
