import 'package:flutter/material.dart';
import 'draft.dart';

class CreatorFlow extends StatefulWidget {
  const CreatorFlow({super.key});
  @override
  State<CreatorFlow> createState() => _CreatorFlowState();
}

class _CreatorFlowState extends State<CreatorFlow> {
  var stage = 0;
  var onboarded = false;
  DraftDilemma draft = const DraftDilemma();
  @override
  Widget build(BuildContext c) {
    if (!onboarded) {
      return _Onboarding(onDone: () => setState(() => onboarded = true));
    }
    return stage == 0
        ? _Home(onCreate: () => setState(() => stage = 1))
        : stage == 1
        ? _Draft(
            draft: draft,
            onChanged: (d) => setState(() => draft = d),
            onReview: () => setState(() => stage = 2),
          )
        : _Review(draft: draft, onEdit: () => setState(() => stage = 1));
  }
}

class _Shell extends StatelessWidget {
  const _Shell({required this.child});
  final Widget child;
  @override
  Widget build(BuildContext c) => SafeArea(
    child: Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 560),
        child: Padding(padding: const EdgeInsets.all(16), child: child),
      ),
    ),
  );
}

class _Onboarding extends StatefulWidget {
  const _Onboarding({required this.onDone});
  final VoidCallback onDone;
  @override
  State<_Onboarding> createState() => _OnboardingState();
}

class _OnboardingState extends State<_Onboarding> {
  final name = TextEditingController();
  var adult = false, terms = false, privacy = false;
  @override
  Widget build(BuildContext c) {
    final ready = name.text.trim().isNotEmpty && adult && terms && privacy;
    return Scaffold(
      body: _Shell(
        child: ListView(
          children: [
            Text(
              'Antes de publicar, vamos deixar tudo claro',
              style: Theme.of(c).textTheme.headlineMedium,
            ),
            const SizedBox(height: 12),
            const Text(
              'Demonstração interna — este conteúdo não tem validade jurídica e não habilita beta.',
            ),
            TextField(
              controller: name,
              onChanged: (_) => setState(() {}),
              decoration: const InputDecoration(
                labelText: 'Como seus amigos chamam você?',
              ),
            ),
            CheckboxListTile(
              value: adult,
              onChanged: (v) => setState(() => adult = v ?? false),
              title: const Text('Confirmo que tenho 18 anos ou mais'),
            ),
            CheckboxListTile(
              value: terms,
              onChanged: (v) => setState(() => terms = v ?? false),
              title: const Text('Termos de demonstração (Lorem ipsum)'),
            ),
            CheckboxListTile(
              value: privacy,
              onChanged: (v) => setState(() => privacy = v ?? false),
              title: const Text(
                'Aviso de privacidade de demonstração (Lorem ipsum)',
              ),
            ),
            SizedBox(
              height: 52,
              child: FilledButton(
                onPressed: ready ? widget.onDone : null,
                child: const Text('Continuar'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Home extends StatelessWidget {
  const _Home({required this.onCreate});
  final VoidCallback onCreate;
  @override
  Widget build(BuildContext c) => Scaffold(
    body: _Shell(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Spacer(),
          Text(
            'Um pouco de espaço antes de decidir',
            style: Theme.of(c).textTheme.headlineMedium,
          ),
          const SizedBox(height: 12),
          const Text(
            'Organize a vontade, peça perspectiva a pessoas próximas e escolha no seu tempo.',
          ),
          const SizedBox(height: 24),
          const Text(
            'Conte o que está pensando\nOuça perspectivas\nDecida você',
          ),
          const Spacer(),
          SizedBox(
            width: double.infinity,
            height: 52,
            child: FilledButton(
              onPressed: onCreate,
              child: const Text('Criar minha primeira tentação'),
            ),
          ),
        ],
      ),
    ),
  );
}

class _Draft extends StatelessWidget {
  const _Draft({
    required this.draft,
    required this.onChanged,
    required this.onReview,
  });
  final DraftDilemma draft;
  final ValueChanged<DraftDilemma> onChanged;
  final VoidCallback onReview;
  @override
  Widget build(BuildContext c) => Scaffold(
    appBar: AppBar(title: const Text('Nova tentação')),
    body: _Shell(
      child: ListView(
        children: [
          Card(
            child: const Padding(
              padding: EdgeInsets.all(16),
              child: Text('Rascunho — não compartilhado'),
            ),
          ),
          TextField(
            controller: TextEditingController(text: draft.itemName),
            onChanged: (v) => onChanged(draft.copyWith(itemName: v)),
            decoration: const InputDecoration(
              labelText: 'Nome do item',
              helperText: 'De 2 a 80 caracteres',
            ),
          ),
          TextField(
            controller: TextEditingController(
              text: draft.priceCents == 0 ? '' : draft.priceCents.toString(),
            ),
            keyboardType: TextInputType.number,
            onChanged: (v) =>
                onChanged(draft.copyWith(priceCents: brlToCents(v))),
            decoration: const InputDecoration(
              labelText: 'Preço',
              prefixText: 'R\$ ',
            ),
          ),
          TextField(
            controller: TextEditingController(text: draft.reason),
            maxLines: 4,
            onChanged: (v) => onChanged(draft.copyWith(reason: v)),
            decoration: const InputDecoration(
              labelText: 'Por que você está pensando nisso agora?',
              helperText: 'De 10 a 500 caracteres',
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 52,
            child: FilledButton(
              onPressed: draft.valid ? onReview : null,
              child: const Text('Revisar'),
            ),
          ),
        ],
      ),
    ),
  );
}

class _Review extends StatelessWidget {
  const _Review({required this.draft, required this.onEdit});
  final DraftDilemma draft;
  final VoidCallback onEdit;
  @override
  Widget build(BuildContext c) => Scaffold(
    appBar: AppBar(title: const Text('Revisar')),
    body: _Shell(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Tudo certo para pedir uma perspectiva?',
            style: Theme.of(c).textTheme.headlineMedium,
          ),
          const Text('Confira com calma. Nada foi compartilhado ainda.'),
          const SizedBox(height: 20),
          Text(draft.itemName, style: Theme.of(c).textTheme.titleLarge),
          Text(centsToBrl(draft.priceCents)),
          Text(draft.reason),
          const Spacer(),
          OutlinedButton(onPressed: onEdit, child: const Text('Editar')),
          SizedBox(
            width: double.infinity,
            height: 52,
            child: FilledButton(
              onPressed: null,
              child: const Text('Publicação disponível na próxima etapa'),
            ),
          ),
        ],
      ),
    ),
  );
}
