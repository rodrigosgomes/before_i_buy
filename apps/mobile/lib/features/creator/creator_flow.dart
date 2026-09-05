import 'package:flutter/material.dart';

import '../../design_system/bib_components.dart';
import '../../design_system/bib_theme.dart';
import 'creator_remote_gateway.dart';
import 'draft.dart';

class CreatorHomeScreen extends StatelessWidget {
  const CreatorHomeScreen({
    super.key,
    required this.onCreate,
    this.dilemmas = const [],
    this.onSelectDilemma,
    this.loadError,
    this.onRetry,
    this.onSignOut,
  });

  final VoidCallback onCreate;
  final List<CreatorDilemmaSummary> dilemmas;
  final ValueChanged<CreatorDilemmaSummary>? onSelectDilemma;
  final String? loadError;
  final Future<void> Function()? onRetry;
  final Future<void> Function()? onSignOut;

  PreferredSizeWidget? _buildTopBar() => onSignOut == null
      ? null
      : BibTopBar(
          title: 'Before I Buy',
          actions: [
            IconButton(
              onPressed: onSignOut,
              tooltip: 'Sair da conta',
              icon: const Icon(Icons.logout_rounded),
            ),
          ],
        );

  @override
  Widget build(BuildContext context) {
    final topBar = _buildTopBar();
    if (dilemmas.isNotEmpty) {
      return BibPageShell(
        topBar: topBar,
        bottom: BibPrimaryButton(
          label: 'Criar nova tentação',
          onPressed: onCreate,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Suas decisões com espaço',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: BibSpacing.x2),
            const Text(
              'Acompanhe os votos recebidos ou revogue o acesso quando quiser.',
            ),
            const SizedBox(height: BibSpacing.x5),
            if (loadError != null) ...[
              BibInlineMessage(message: loadError!, kind: BibMessageKind.error),
              const SizedBox(height: BibSpacing.x2),
              BibSecondaryButton(label: 'Tentar atualizar', onPressed: onRetry),
              const SizedBox(height: BibSpacing.x4),
            ],
            ...dilemmas.map(
              (dilemma) => _DilemmaCard(
                dilemma: dilemma,
                onTap: () => onSelectDilemma?.call(dilemma),
              ),
            ),
          ],
        ),
      );
    }

    return BibPageShell(
      topBar: topBar,
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
                if (loadError != null) ...[
                  BibInlineMessage(
                    message: loadError!,
                    kind: BibMessageKind.error,
                  ),
                  const SizedBox(height: BibSpacing.x2),
                  BibSecondaryButton(
                    label: 'Tentar atualizar',
                    onPressed: onRetry,
                  ),
                  const SizedBox(height: BibSpacing.x4),
                ],
                const _Chapter(number: '1', label: 'Conte o que está pensando'),
                const _Chapter(number: '2', label: 'Ouça perspectivas'),
                const _Chapter(number: '3', label: 'Decida você'),
                const SizedBox(height: BibSpacing.x6),
                const BibPrivacyNotice(
                  title: 'Seu espaço é privado',
                  body:
                      'Seus dilemas só abrem para quem receber o link privado.',
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _DilemmaCard extends StatelessWidget {
  const _DilemmaCard({required this.dilemma, required this.onTap});

  final CreatorDilemmaSummary dilemma;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Semantics(
    button: true,
    label:
        'Dilema ${dilemma.itemName}, ${centsToBrl(dilemma.priceCents)}, ${dilemma.isInviteRevoked ? "convite revogado" : "${dilemma.totalVotes} votos"}',
    child: Card(
      margin: const EdgeInsets.only(bottom: BibSpacing.x4),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(BibRadii.card),
        side: const BorderSide(color: BibColors.outline),
      ),
      elevation: 0,
      color: BibColors.surface,
      child: InkWell(
        borderRadius: BorderRadius.circular(BibRadii.card),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(BibSpacing.x4),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      dilemma.itemName,
                      style: Theme.of(context).textTheme.titleMedium,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: BibSpacing.x2),
                  Text(
                    centsToBrl(dilemma.priceCents),
                    style: Theme.of(context).textTheme.labelLarge,
                  ),
                ],
              ),
              const SizedBox(height: BibSpacing.x2),
              if (dilemma.isInviteRevoked)
                const BibStatusChip(
                  label: 'Convite revogado',
                  icon: Icons.block_rounded,
                )
              else if (!dilemma.isVotingOpen)
                const BibStatusChip(
                  label: 'Pausa concluída · votação encerrada',
                  icon: Icons.timer_off_outlined,
                )
              else
                BibStatusChip(
                  label: dilemma.totalVotes == 0
                      ? 'Coletando votos · aguardando respostas'
                      : 'Coletando votos · ${dilemma.totalVotes} ${dilemma.totalVotes == 1 ? "voto" : "votos"}',
                  icon: Icons.how_to_vote_outlined,
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
    this.onSignOut,
  });

  final DraftDilemma draft;
  final bool recovered;
  final ValueChanged<DraftDilemma> onChanged;
  final VoidCallback onReview;
  final VoidCallback onBack;
  final Future<void> Function()? onSignOut;

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
      topBar: BibTopBar(
        title: 'Nova tentação',
        onBack: widget.onBack,
        actions: widget.onSignOut == null
            ? null
            : [
                IconButton(
                  onPressed: widget.onSignOut,
                  tooltip: 'Sair da conta',
                  icon: const Icon(Icons.logout_rounded),
                ),
              ],
      ),
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
    required this.onPreview,
  });

  final DraftDilemma draft;
  final bool recovered;
  final VoidCallback onEdit;
  final VoidCallback onPreview;

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
              'Você verá uma prévia antes de publicar. Nada é enviado nesta tela.',
        ),
        const SizedBox(height: BibSpacing.x5),
        Align(
          alignment: Alignment.center,
          child: BibTextButton(label: 'Editar', onPressed: onEdit),
        ),
        const SizedBox(height: BibSpacing.x2),
        BibPrimaryButton(label: 'Ver prévia do convite', onPressed: onPreview),
      ],
    ),
  );
}

class GuestPreviewScreen extends StatefulWidget {
  const GuestPreviewScreen({
    super.key,
    required this.draft,
    required this.creatorName,
    required this.onBack,
    required this.onPublish,
  });

  final DraftDilemma draft;
  final String creatorName;
  final VoidCallback onBack;
  final Future<String?> Function() onPublish;

  @override
  State<GuestPreviewScreen> createState() => _GuestPreviewScreenState();
}

class _GuestPreviewScreenState extends State<GuestPreviewScreen> {
  var _publishing = false;
  String? _error;

  Future<void> _publish() async {
    setState(() {
      _publishing = true;
      _error = null;
    });
    final error = await widget.onPublish();
    if (!mounted || error == null) return;
    setState(() {
      _publishing = false;
      _error = error;
    });
  }

  @override
  Widget build(BuildContext context) => BibPageShell(
    topBar: BibTopBar(
      title: 'Prévia do convite',
      onBack: _publishing || widget.draft.publicationPending
          ? null
          : widget.onBack,
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'É assim que seu convite vai aparecer',
          style: Theme.of(context).textTheme.headlineMedium,
        ),
        const SizedBox(height: BibSpacing.x3),
        const Text(
          'O link é privado, mas pode ser encaminhado. Você poderá revogá-lo no painel do dilema.',
        ),
        const SizedBox(height: BibSpacing.x5),
        if (widget.draft.publicationPending) ...[
          const BibInlineMessage(
            message:
                'Publicação não confirmada. O convite pode já existir. Confira o conteúdo e tente novamente para recuperar o mesmo convite.',
          ),
          const SizedBox(height: BibSpacing.x4),
        ],
        BibGuestPreviewFrame(
          draft: widget.draft,
          creatorName: widget.creatorName,
        ),
        const SizedBox(height: BibSpacing.x5),
        const BibPrivacyNotice(
          title: 'Prévia social neutra',
          body:
              'Mensageiros não recebem nome, item, preço ou motivo na prévia do link.',
        ),
        if (_error != null) ...[
          const SizedBox(height: BibSpacing.x4),
          BibInlineMessage(message: _error!, kind: BibMessageKind.error),
        ],
        const SizedBox(height: BibSpacing.x6),
        BibPrimaryButton(
          label: 'Publicar convite privado',
          loading: _publishing,
          onPressed: _publishing ? null : _publish,
        ),
      ],
    ),
  );
}

class PublishedDilemmaScreen extends StatefulWidget {
  const PublishedDilemmaScreen({
    super.key,
    required this.draft,
    required this.onShare,
    this.onGoToDashboard,
  });

  final DraftDilemma draft;
  final Future<String?> Function() onShare;
  final VoidCallback? onGoToDashboard;

  @override
  State<PublishedDilemmaScreen> createState() => _PublishedDilemmaScreenState();
}

class _PublishedDilemmaScreenState extends State<PublishedDilemmaScreen> {
  var _sharing = false;
  String? _error;

  Future<void> _share() async {
    setState(() {
      _sharing = true;
      _error = null;
    });
    final error = await widget.onShare();
    if (!mounted) return;
    setState(() {
      _sharing = false;
      _error = error;
    });
  }

  @override
  Widget build(BuildContext context) => BibPageShell(
    topBar: const BibTopBar(title: 'Convite pronto'),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const BibStatusChip(
          label: 'Publicado de forma privada e não listada',
          icon: Icons.lock_outline_rounded,
        ),
        const SizedBox(height: BibSpacing.x5),
        Text(
          'Seu espaço está pronto para receber perspectivas',
          style: Theme.of(context).textTheme.headlineMedium,
        ),
        const SizedBox(height: BibSpacing.x3),
        const Text(
          'Somente quem receber o convite poderá abrir a página de voto.',
        ),
        const SizedBox(height: BibSpacing.x6),
        BibDilemmaSummary(draft: widget.draft),
        const SizedBox(height: BibSpacing.x5),
        const BibPrivacyNotice(
          title: 'Compartilhe com cuidado',
          body:
              'Links podem ser encaminhados. A prévia social permanece neutra.',
          attention: true,
        ),
        if (_error != null) ...[
          const SizedBox(height: BibSpacing.x4),
          BibInlineMessage(message: _error!, kind: BibMessageKind.error),
        ],
        const SizedBox(height: BibSpacing.x6),
        BibPrimaryButton(
          label: 'Compartilhar convite',
          loading: _sharing,
          onPressed: _sharing ? null : _share,
        ),
        if (widget.onGoToDashboard != null) ...[
          const SizedBox(height: BibSpacing.x3),
          BibSecondaryButton(
            label: 'Ver painel de acompanhamento',
            onPressed: _sharing ? null : widget.onGoToDashboard,
          ),
        ],
      ],
    ),
  );
}

class DilemmaDashboardScreen extends StatefulWidget {
  const DilemmaDashboardScreen({
    super.key,
    required this.dilemma,
    required this.onBack,
    this.onShare,
    required this.onRevoke,
    required this.onDelete,
    this.onRefresh,
  });

  final CreatorDilemmaSummary dilemma;
  final VoidCallback onBack;
  final Future<String?> Function()? onShare;
  final Future<String?> Function() onRevoke;
  final Future<String?> Function() onDelete;
  final Future<String?> Function()? onRefresh;

  @override
  State<DilemmaDashboardScreen> createState() => _DilemmaDashboardScreenState();
}

class _DilemmaDashboardScreenState extends State<DilemmaDashboardScreen> {
  var _revoking = false;
  var _deleting = false;
  var _sharing = false;
  var _refreshing = false;
  String? _error;

  Future<void> _handleShare() async {
    if (widget.onShare == null) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Compartilhar este convite?'),
        content: const Text(
          'O link é privado, mas pode ser encaminhado por quem o receber. Você poderá revogá-lo imediatamente neste painel.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Compartilhar'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    setState(() {
      _sharing = true;
      _error = null;
    });
    final error = await widget.onShare!();
    if (!mounted) return;
    setState(() {
      _sharing = false;
      _error = error;
    });
  }

  Future<void> _handleRefresh() async {
    if (widget.onRefresh == null || _refreshing) return;
    setState(() {
      _refreshing = true;
      _error = null;
    });
    final error = await widget.onRefresh!();
    if (!mounted) return;
    setState(() {
      _refreshing = false;
      _error = error;
    });
  }

  Future<void> _confirmRevocation() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Revogar convite?'),
        content: const Text(
          'O link deixará de funcionar imediatamente para qualquer pessoa. Ninguém mais poderá votar. Os votos já recebidos continuarão visíveis para você.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Manter convite'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Revogar'),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    setState(() {
      _revoking = true;
      _error = null;
    });
    final error = await widget.onRevoke();
    if (!mounted) return;
    setState(() {
      _revoking = false;
      _error = error;
    });
  }

  Future<void> _confirmDeletion() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Apagar dilema?'),
        content: const Text(
          'Esta ação é definitiva e removerá este dilema, o link de convite e todos os votos registrados.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Apagar definitivamente'),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    setState(() {
      _deleting = true;
      _error = null;
    });
    final error = await widget.onDelete();
    if (!mounted) return;
    setState(() {
      _deleting = false;
      _error = error;
    });
  }

  @override
  Widget build(BuildContext context) {
    final dilemma = widget.dilemma;
    return BibPageShell(
      topBar: BibTopBar(
        title: 'Painel do dilema',
        onBack: widget.onBack,
        actions: [
          if (widget.onRefresh != null)
            IconButton(
              icon: _refreshing
                  ? const SizedBox.square(
                      dimension: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.refresh_rounded),
              tooltip: 'Atualizar perspectivas',
              onPressed: _sharing || _revoking || _deleting || _refreshing
                  ? null
                  : _handleRefresh,
            ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (dilemma.isInviteRevoked)
            const BibStatusChip(
              label: 'Convite revogado · votação encerrada',
              icon: Icons.block_rounded,
            )
          else if (!dilemma.isVotingOpen)
            const BibStatusChip(
              label: 'Pausa concluída · votação encerrada',
              icon: Icons.timer_off_outlined,
            )
          else
            const BibStatusChip(
              label: 'Coletando votos de amigos',
              icon: Icons.how_to_vote_outlined,
            ),
          const SizedBox(height: BibSpacing.x4),
          Text(
            dilemma.itemName,
            style: Theme.of(context).textTheme.headlineMedium,
          ),
          const SizedBox(height: BibSpacing.x1),
          Text(
            centsToBrl(dilemma.priceCents),
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
          const SizedBox(height: BibSpacing.x4),
          Text(dilemma.reason),
          const SizedBox(height: BibSpacing.x5),
          const Divider(),
          const SizedBox(height: BibSpacing.x5),
          Text(
            'Perspectivas recebidas',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: BibSpacing.x3),
          if (dilemma.totalVotes == 0) ...[
            DecoratedBox(
              decoration: BoxDecoration(
                color: BibColors.surfaceSubtle,
                borderRadius: BorderRadius.circular(BibRadii.card),
              ),
              child: const Padding(
                padding: EdgeInsets.all(BibSpacing.x4),
                child: SizedBox(
                  width: double.infinity,
                  child: Column(
                    children: [
                      Icon(
                        Icons.hourglass_empty_rounded,
                        size: 36,
                        color: BibColors.textSecondary,
                      ),
                      SizedBox(height: BibSpacing.x2),
                      Text(
                        'Aguardando votos',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      SizedBox(height: BibSpacing.x1),
                      Text(
                        'Compartilhe o convite com pessoas próximas para receber perspectivas sinceras.',
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ] else ...[
            Text(
              'Total: ${dilemma.totalVotes} ${dilemma.totalVotes == 1 ? "voto" : "votos"}',
              style: Theme.of(context).textTheme.labelLarge,
            ),
            const SizedBox(height: BibSpacing.x3),
            _VoteDistributionBar(
              label: 'Comprar',
              count: dilemma.buyCount,
              percentage: dilemma.buyPercentage,
            ),
            const SizedBox(height: BibSpacing.x3),
            _VoteDistributionBar(
              label: 'Esperar',
              count: dilemma.waitCount,
              percentage: dilemma.waitPercentage,
            ),
            const SizedBox(height: BibSpacing.x3),
            _VoteDistributionBar(
              label: 'Deixar pra lá',
              count: dilemma.skipCount,
              percentage: dilemma.skipPercentage,
            ),
            const SizedBox(height: BibSpacing.x4),
            const BibPrivacyNotice(
              title: 'Privacidade garantida',
              body:
                  'A distribuição é anônima. Nenhuma resposta individual é identificada.',
            ),
          ],
          if (_error != null) ...[
            const SizedBox(height: BibSpacing.x4),
            BibInlineMessage(message: _error!, kind: BibMessageKind.error),
          ],
          const SizedBox(height: BibSpacing.x6),
          if (dilemma.isVotingOpen && widget.onShare != null) ...[
            BibPrimaryButton(
              label: 'Compartilhar convite',
              loading: _sharing,
              onPressed: _sharing || _revoking || _deleting
                  ? null
                  : _handleShare,
            ),
            const SizedBox(height: BibSpacing.x3),
          ],
          if (dilemma.isVotingOpen) ...[
            BibSecondaryButton(
              label: 'Revogar convite',
              loading: _revoking,
              onPressed: _sharing || _revoking || _deleting
                  ? null
                  : _confirmRevocation,
            ),
            const SizedBox(height: BibSpacing.x3),
          ],
          BibDestructiveButton(
            label: 'Apagar dilema',
            loading: _deleting,
            onPressed: _sharing || _revoking || _deleting
                ? null
                : _confirmDeletion,
          ),
        ],
      ),
    );
  }
}

class _VoteDistributionBar extends StatelessWidget {
  const _VoteDistributionBar({
    required this.label,
    required this.count,
    required this.percentage,
  });

  final String label;
  final int count;
  final double percentage;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Flexible(
            child: Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
          const SizedBox(width: BibSpacing.x2),
          Text(
            '$count (${percentage.toStringAsFixed(0)}%)',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ],
      ),
      const SizedBox(height: BibSpacing.x1),
      ClipRRect(
        borderRadius: BorderRadius.circular(BibRadii.button),
        child: LinearProgressIndicator(
          value: percentage > 0 ? (percentage / 100).clamp(0.0, 1.0) : 0.0,
          minHeight: 12,
        ),
      ),
    ],
  );
}
