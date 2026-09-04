import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';

import 'core/app_config.dart';
import 'design_system/bib_components.dart';
import 'design_system/bib_theme.dart';
import 'features/auth/auth_gateway.dart';
import 'features/auth/google_sign_in_screen.dart';
import 'features/creator/creator_flow.dart';
import 'features/creator/creator_remote_gateway.dart';
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
    CreatorProfileGateway? creatorProfileGateway,
    DilemmaPublicationGateway? publicationGateway,
    InviteShareGateway? shareGateway,
    String Function()? createId,
    TargetPlatform? platform,
  }) : onboardingRepository =
           onboardingRepository ?? SharedPreferencesOnboardingRepository(),
       draftRepository = draftRepository ?? SharedPreferencesDraftRepository(),
       creatorProfileGateway =
           creatorProfileGateway ?? MemoryCreatorProfileGateway(),
       publicationGateway =
           publicationGateway ?? MemoryDilemmaPublicationGateway(),
       shareGateway = shareGateway ?? MemoryInviteShareGateway(),
       createId = createId ?? const Uuid().v4,
       platform = platform ?? defaultTargetPlatform;

  final AppConfig config;
  final AuthGateway? authGateway;
  final OnboardingRepository onboardingRepository;
  final DraftRepository draftRepository;
  final CreatorProfileGateway creatorProfileGateway;
  final DilemmaPublicationGateway publicationGateway;
  final InviteShareGateway shareGateway;
  final String Function() createId;
  final TargetPlatform platform;

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
      creatorProfileGateway: creatorProfileGateway,
      publicationGateway: publicationGateway,
      shareGateway: shareGateway,
      createId: createId,
      platform: platform,
    ),
  );
}

enum AppStage {
  configurationMissing,
  loading,
  googleSignIn,
  onboarding,
  profileSync,
  home,
  draft,
  review,
  preview,
  published,
}

class AppFlow extends StatefulWidget {
  const AppFlow({
    super.key,
    required this.config,
    required this.authGateway,
    required this.onboardingRepository,
    required this.draftRepository,
    required this.creatorProfileGateway,
    required this.publicationGateway,
    required this.shareGateway,
    required this.createId,
    required this.platform,
  });

  final AppConfig config;
  final AuthGateway? authGateway;
  final OnboardingRepository onboardingRepository;
  final DraftRepository draftRepository;
  final CreatorProfileGateway creatorProfileGateway;
  final DilemmaPublicationGateway publicationGateway;
  final InviteShareGateway shareGateway;
  final String Function() createId;
  final TargetPlatform platform;

  @override
  State<AppFlow> createState() => _AppFlowState();
}

class _AppFlowState extends State<AppFlow> {
  AppStage _stage = AppStage.loading;
  StreamSubscription<AuthStatus>? _authSubscription;
  LocalOnboarding? _onboarding;
  DraftDilemma? _draft;
  bool _recoveredDraft = false;
  DraftDilemma? _publishedDraft;
  Uri? _publishedInviteUri;

  @override
  void initState() {
    super.initState();
    _bootstrap();
  }

  Future<void> _bootstrap() async {
    if (!widget.config.isReadyFor(widget.platform) ||
        widget.authGateway == null) {
      if (mounted) setState(() => _stage = AppStage.configurationMissing);
      return;
    }
    _authSubscription = widget.authGateway!.statusChanges.listen((status) {
      if (status == AuthStatus.signedIn) {
        _resolveAuthenticatedState();
      } else if (mounted) {
        setState(() => _stage = AppStage.googleSignIn);
      }
    });
    if (widget.authGateway!.isAuthenticated) {
      await _resolveAuthenticatedState();
    } else if (mounted) {
      setState(() => _stage = AppStage.googleSignIn);
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
    final profileStatus = await widget.creatorProfileGateway.status();
    if (!mounted) return;
    if (profileStatus != CreatorProfileStatus.ready) {
      setState(() => _stage = AppStage.profileSync);
      return;
    }
    await _loadDraftAfterProfile();
  }

  Future<void> _completeOnboarding(LocalOnboarding onboarding) async {
    await widget.onboardingRepository.save(onboarding);
    if (!mounted) return;
    _onboarding = onboarding;
    setState(() => _stage = AppStage.profileSync);
  }

  Future<void> _loadDraftAfterProfile() async {
    final draft = await widget.draftRepository.load();
    if (!mounted) return;
    _draft = draft;
    _recoveredDraft = draft != null;
    setState(() => _stage = draft == null ? AppStage.home : AppStage.draft);
  }

  Future<String?> _syncProfile() async {
    try {
      await widget.creatorProfileGateway.sync(_onboarding!);
      if (!mounted) return null;
      await _loadDraftAfterProfile();
      return null;
    } catch (_) {
      return 'Não foi possível salvar seu perfil agora. Tente novamente.';
    }
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

  Future<String?> _publish() async {
    final draft = _draft;
    final linkBuilder = GuestInviteLinkBuilder(
      widget.config.guestInviteBaseUri,
    );
    if (draft == null || widget.config.guestInviteBaseUri == null) {
      return 'O convite ainda não está configurado para este ambiente.';
    }
    try {
      final published = await widget.publicationGateway.publish(draft);
      final inviteUri = linkBuilder.build(published.inviteToken);
      await widget.draftRepository.clear();
      if (!mounted) return null;
      setState(() {
        _publishedDraft = draft;
        _publishedInviteUri = inviteUri;
        _draft = null;
        _recoveredDraft = false;
        _stage = AppStage.published;
      });
      return null;
    } catch (_) {
      return 'Não foi possível publicar agora. Seu rascunho continua salvo.';
    }
  }

  Future<String?> _share() async {
    try {
      await widget.shareGateway.share(_publishedInviteUri!);
      return null;
    } catch (_) {
      return 'Não foi possível abrir o compartilhamento agora.';
    }
  }

  @override
  void dispose() {
    _authSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => switch (_stage) {
    AppStage.configurationMissing => ConfigurationMissingScreen(
      missing: widget.config.missingFor(widget.platform),
    ),
    AppStage.loading => const _LoadingScreen(),
    AppStage.googleSignIn => GoogleSignInScreen(
      authGateway: widget.authGateway!,
    ),
    AppStage.onboarding => OnboardingScreen(
      initialValue: _onboarding,
      onComplete: _completeOnboarding,
    ),
    AppStage.profileSync => RemoteProfileSyncScreen(onSync: _syncProfile),
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
      onPreview: () => setState(() => _stage = AppStage.preview),
    ),
    AppStage.preview => GuestPreviewScreen(
      draft: _draft!,
      onBack: () => setState(() => _stage = AppStage.review),
      onPublish: _publish,
    ),
    AppStage.published => PublishedDilemmaScreen(
      draft: _publishedDraft!,
      onShare: _share,
    ),
  };
}

class ConfigurationMissingScreen extends StatelessWidget {
  const ConfigurationMissingScreen({super.key, required this.missing});

  final List<String> missing;

  @override
  Widget build(BuildContext context) => BibPageShell(
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Icon(Icons.settings_outlined, size: 52),
        const SizedBox(height: BibSpacing.x5),
        const Text(
          'Configuração interna ausente',
          style: TextStyle(fontSize: 26, fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: BibSpacing.x3),
        const Text(
          'Este build ainda não recebeu toda a configuração pública necessária. Nenhuma conexão foi tentada.',
        ),
        const SizedBox(height: BibSpacing.x5),
        BibInlineMessage(
          message:
              'Configure: ${missing.join(', ')}. Use --dart-define-from-file=config/local.json e nunca use service_role no aplicativo.',
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
