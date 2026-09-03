import 'dart:async';

import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';

import 'core/app_config.dart';
import 'design_system/bib_components.dart';
import 'design_system/bib_theme.dart';
import 'features/auth/auth_gateway.dart';
import 'features/auth/magic_link_screen.dart';
import 'features/creator/creator_flow.dart';
import 'features/creator/draft.dart';
import 'features/creator/draft_repository.dart';
import 'features/onboarding/onboarding_repository.dart';
import 'features/onboarding/onboarding_screen.dart';

class BeforeIBuyApp extends StatelessWidget {
  BeforeIBuyApp({
    super.key,
    this.config = AppConfig.fromEnvironment,
    this.authGateway,
    OnboardingRepository? onboardingRepository,
    DraftRepository? draftRepository,
    String Function()? createId,
  }) : onboardingRepository =
           onboardingRepository ?? SharedPreferencesOnboardingRepository(),
       draftRepository = draftRepository ?? SharedPreferencesDraftRepository(),
       createId = createId ?? const Uuid().v4;

  final AppConfig config;
  final AuthGateway? authGateway;
  final OnboardingRepository onboardingRepository;
  final DraftRepository draftRepository;
  final String Function() createId;

  @override
  Widget build(BuildContext context) => MaterialApp(
    title: 'Before I Buy',
    debugShowCheckedModeBanner: false,
    theme: buildBibTheme(),
    home: AppFlow(
      config: config,
      authGateway: authGateway,
      onboardingRepository: onboardingRepository,
      draftRepository: draftRepository,
      createId: createId,
    ),
  );
}

enum AppStage {
  configurationMissing,
  loading,
  magicLink,
  waitingForLink,
  onboarding,
  home,
  draft,
  review,
}

class AppFlow extends StatefulWidget {
  const AppFlow({
    super.key,
    required this.config,
    required this.authGateway,
    required this.onboardingRepository,
    required this.draftRepository,
    required this.createId,
  });

  final AppConfig config;
  final AuthGateway? authGateway;
  final OnboardingRepository onboardingRepository;
  final DraftRepository draftRepository;
  final String Function() createId;

  @override
  State<AppFlow> createState() => _AppFlowState();
}

class _AppFlowState extends State<AppFlow> {
  AppStage _stage = AppStage.loading;
  StreamSubscription<AuthStatus>? _authSubscription;
  String _waitingEmail = '';
  LocalOnboarding? _onboarding;
  DraftDilemma? _draft;
  bool _recoveredDraft = false;

  @override
  void initState() {
    super.initState();
    _bootstrap();
  }

  Future<void> _bootstrap() async {
    if (!widget.config.hasSupabaseConfiguration || widget.authGateway == null) {
      if (mounted) setState(() => _stage = AppStage.configurationMissing);
      return;
    }
    _authSubscription = widget.authGateway!.statusChanges.listen((status) {
      if (status == AuthStatus.signedIn) {
        _resolveAuthenticatedState();
      } else if (mounted) {
        setState(() => _stage = AppStage.magicLink);
      }
    });
    if (widget.authGateway!.isAuthenticated) {
      await _resolveAuthenticatedState();
    } else if (mounted) {
      setState(() => _stage = AppStage.magicLink);
    }
  }

  Future<void> _resolveAuthenticatedState() async {
    if (mounted) setState(() => _stage = AppStage.loading);
    final onboarding = await widget.onboardingRepository.load();
    if (!mounted) return;
    _onboarding = onboarding;
    if (onboarding?.isComplete != true) {
      setState(() => _stage = AppStage.onboarding);
      return;
    }
    final draft = await widget.draftRepository.load();
    if (!mounted) return;
    _draft = draft;
    _recoveredDraft = draft != null;
    setState(() => _stage = draft == null ? AppStage.home : AppStage.draft);
  }

  Future<void> _completeOnboarding(LocalOnboarding onboarding) async {
    await widget.onboardingRepository.save(onboarding);
    if (!mounted) return;
    _onboarding = onboarding;
    final draft = await widget.draftRepository.load();
    if (!mounted) return;
    _draft = draft;
    _recoveredDraft = draft != null;
    setState(() => _stage = draft == null ? AppStage.home : AppStage.draft);
  }

  void _createDraft() {
    final draft = _draft ?? DraftDilemma(idempotencyKey: widget.createId());
    _draft = draft;
    _recoveredDraft = false;
    widget.draftRepository.save(draft);
    setState(() => _stage = AppStage.draft);
  }

  void _updateDraft(DraftDilemma draft) {
    _draft = draft;
    widget.draftRepository.save(draft);
    setState(() {});
  }

  @override
  void dispose() {
    _authSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => switch (_stage) {
    AppStage.configurationMissing => const ConfigurationMissingScreen(),
    AppStage.loading => const _LoadingScreen(),
    AppStage.magicLink => MagicLinkScreen(
      authGateway: widget.authGateway!,
      onLinkSent: (email) => setState(() {
        _waitingEmail = email;
        _stage = AppStage.waitingForLink;
      }),
    ),
    AppStage.waitingForLink => WaitingForMagicLinkScreen(
      email: _waitingEmail,
      authGateway: widget.authGateway!,
      onChangeEmail: () => setState(() => _stage = AppStage.magicLink),
    ),
    AppStage.onboarding => OnboardingScreen(
      initialValue: _onboarding,
      onComplete: _completeOnboarding,
    ),
    AppStage.home => CreatorHomeScreen(onCreate: _createDraft),
    AppStage.draft => DraftScreen(
      draft: _draft!,
      recovered: _recoveredDraft,
      onChanged: _updateDraft,
      onReview: () => setState(() => _stage = AppStage.review),
      onBack: () => setState(() => _stage = AppStage.home),
    ),
    AppStage.review => ReviewScreen(
      draft: _draft!,
      recovered: _recoveredDraft,
      onEdit: () => setState(() => _stage = AppStage.draft),
    ),
  };
}

class ConfigurationMissingScreen extends StatelessWidget {
  const ConfigurationMissingScreen({super.key});

  @override
  Widget build(BuildContext context) => const BibPageShell(
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(Icons.settings_outlined, size: 52),
        SizedBox(height: BibSpacing.x5),
        Text(
          'Configuração interna ausente',
          style: TextStyle(fontSize: 26, fontWeight: FontWeight.w700),
        ),
        SizedBox(height: BibSpacing.x3),
        Text(
          'Este build ainda não recebeu a URL e a chave pública do Supabase. Nenhuma conexão foi tentada.',
        ),
        SizedBox(height: BibSpacing.x5),
        BibInlineMessage(
          message:
              'Inicie com SUPABASE_URL e SUPABASE_ANON_KEY via --dart-define. Nunca use service_role no aplicativo.',
        ),
      ],
    ),
  );
}

class _LoadingScreen extends StatelessWidget {
  const _LoadingScreen();

  @override
  Widget build(BuildContext context) => BibPageShell(
    child: Center(
      child: Semantics(
        liveRegion: true,
        label: 'Carregando seu espaço privado',
        child: const CircularProgressIndicator(),
      ),
    ),
  );
}
