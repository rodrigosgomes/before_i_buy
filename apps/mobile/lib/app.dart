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
import 'features/creator/active_invite_repository.dart';
import 'features/creator/draft_repository.dart';
import 'features/onboarding/onboarding_repository.dart';
import 'features/onboarding/onboarding_screen.dart';

class BeforeIBuyApp extends StatelessWidget {
  BeforeIBuyApp({
    super.key,
    this.config = AppConfig.fromEnvironment,
    this.authGateway,
    this.onboardingRepository,
    this.draftRepository,
    this.activeInviteRepository,
    CreatorProfileGateway? creatorProfileGateway,
    DilemmaPublicationGateway? publicationGateway,
    CreatorDilemmaGateway? dilemmaGateway,
    InviteShareGateway? shareGateway,
    String Function()? createId,
    TargetPlatform? platform,
    Future<void> Function()? purgeLegacyInvites,
  }) : creatorProfileGateway =
           creatorProfileGateway ?? MemoryCreatorProfileGateway(),
       publicationGateway =
           publicationGateway ?? MemoryDilemmaPublicationGateway(),
       dilemmaGateway = dilemmaGateway ?? MemoryCreatorDilemmaGateway(),
       shareGateway = shareGateway ?? MemoryInviteShareGateway(),
       createId = createId ?? const Uuid().v4,
       platform = platform ?? defaultTargetPlatform,
       purgeLegacyInvites =
           purgeLegacyInvites ?? LegacyActiveInviteStorage.purgeAll;

  final AppConfig config;
  final AuthGateway? authGateway;
  final OnboardingRepository? onboardingRepository;
  final DraftRepository? draftRepository;
  final ActiveInviteRepository? activeInviteRepository;
  final CreatorProfileGateway creatorProfileGateway;
  final DilemmaPublicationGateway publicationGateway;
  final CreatorDilemmaGateway dilemmaGateway;
  final InviteShareGateway shareGateway;
  final String Function() createId;
  final TargetPlatform platform;
  final Future<void> Function() purgeLegacyInvites;

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
      activeInviteRepository: activeInviteRepository,
      creatorProfileGateway: creatorProfileGateway,
      publicationGateway: publicationGateway,
      dilemmaGateway: dilemmaGateway,
      shareGateway: shareGateway,
      createId: createId,
      platform: platform,
      purgeLegacyInvites: purgeLegacyInvites,
    ),
  );
}

enum AppStage {
  privacyCleanupFailed,
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
  dashboard,
}

class AppFlow extends StatefulWidget {
  const AppFlow({
    super.key,
    required this.config,
    required this.authGateway,
    required this.onboardingRepository,
    required this.draftRepository,
    this.activeInviteRepository,
    required this.creatorProfileGateway,
    required this.publicationGateway,
    required this.dilemmaGateway,
    required this.shareGateway,
    required this.createId,
    required this.platform,
    required this.purgeLegacyInvites,
  });

  final AppConfig config;
  final AuthGateway? authGateway;
  final OnboardingRepository? onboardingRepository;
  final DraftRepository? draftRepository;
  final ActiveInviteRepository? activeInviteRepository;
  final CreatorProfileGateway creatorProfileGateway;
  final DilemmaPublicationGateway publicationGateway;
  final CreatorDilemmaGateway dilemmaGateway;
  final InviteShareGateway shareGateway;
  final String Function() createId;
  final TargetPlatform platform;
  final Future<void> Function() purgeLegacyInvites;

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
  String? _publishedDilemmaId;
  Uri? _publishedInviteUri;
  List<CreatorDilemmaSummary> _dilemmas = const [];
  CreatorDilemmaSummary? _selectedDilemma;
  Uri? _activeInviteUri;
  ActiveInviteRepository? _sessionInviteRepository;
  String? _dilemmaLoadError;
  String? _userId;
  int _sessionGeneration = 0;
  Future<void> _draftWrites = Future.value();
  Object? _draftWriteError;
  bool _publishing = false;

  OnboardingRepository get _onboardingRepository =>
      widget.onboardingRepository ??
      SharedPreferencesOnboardingRepository(userId: _userId!);
  DraftRepository get _draftRepository =>
      widget.draftRepository ??
      SharedPreferencesDraftRepository(userId: _userId!);
  ActiveInviteRepository get _activeInviteRepository =>
      _sessionInviteRepository!;

  bool _isCurrent(int generation) =>
      mounted &&
      generation == _sessionGeneration &&
      _userId != null &&
      widget.authGateway?.userId == _userId;

  void _sessionChanged() {
    final userId = widget.authGateway!.userId;
    if (userId == _userId && userId != null) return;
    _sessionGeneration++;
    _userId = userId;
    _onboarding = null;
    _draft = null;
    _publishedDraft = null;
    _publishedDilemmaId = null;
    _publishedInviteUri = null;
    _dilemmas = const [];
    _selectedDilemma = null;
    _activeInviteUri = null;
    _sessionInviteRepository = userId == null
        ? null
        : widget.activeInviteRepository ?? MemoryActiveInviteRepository();
    _dilemmaLoadError = null;
    _publishing = false;
    _draftWriteError = null;
    _draftWrites = Future.value();
    if (userId == null) {
      if (mounted) setState(() => _stage = AppStage.googleSignIn);
    } else {
      _resolveAuthenticatedState();
    }
  }

  void _saveDraft(DraftDilemma draft) {
    final repository = _draftRepository;
    final generation = _sessionGeneration;
    _draftWrites = _draftWrites
        .then((_) => repository.save(draft))
        .then((_) {
          if (_isCurrent(generation)) _draftWriteError = null;
        })
        .catchError((Object error) {
          if (_isCurrent(generation)) _draftWriteError = error;
        });
  }

  @override
  void initState() {
    super.initState();
    _bootstrap();
  }

  Future<void> _bootstrap() async {
    try {
      await widget.purgeLegacyInvites();
    } catch (_) {
      if (mounted) setState(() => _stage = AppStage.privacyCleanupFailed);
      return;
    }
    if (!widget.config.isReadyFor(widget.platform) ||
        widget.authGateway == null) {
      if (mounted) setState(() => _stage = AppStage.configurationMissing);
      return;
    }
    _authSubscription = widget.authGateway!.statusChanges.listen((_) {
      _sessionChanged();
    });
    _sessionChanged();
  }

  Future<void> _resolveAuthenticatedState() async {
    final generation = _sessionGeneration;
    final onboardingRepository = _onboardingRepository;
    final draftRepository = _draftRepository;
    if (mounted) setState(() => _stage = AppStage.loading);
    final onboarding = await onboardingRepository.load();
    if (!_isCurrent(generation)) return;
    _onboarding = onboarding;
    if (onboarding?.isComplete != true) {
      setState(() => _stage = AppStage.onboarding);
      return;
    }
    final draft = await draftRepository.load();
    if (!_isCurrent(generation)) return;
    if (draft != null) {
      _showDraft(draft);
      return;
    }
    final profileStatus = await widget.creatorProfileGateway.status();
    if (!_isCurrent(generation)) return;
    setState(
      () => _stage = profileStatus == CreatorProfileStatus.needsSync
          ? AppStage.profileSync
          : AppStage.home,
    );
    if (profileStatus == CreatorProfileStatus.needsSync) {
      setState(() => _stage = AppStage.profileSync);
      return;
    }
    try {
      final dilemmas = await widget.dilemmaGateway.fetchDilemmas();
      if (!_isCurrent(generation)) return;
      setState(() {
        _dilemmas = dilemmas;
        _dilemmaLoadError = null;
        _stage = AppStage.home;
      });
    } catch (_) {
      if (!_isCurrent(generation)) return;
      setState(() {
        _dilemmas = const [];
        _dilemmaLoadError = 'Não foi possível carregar seus dilemas agora.';
        _stage = AppStage.home;
      });
    }
  }

  Future<void> _completeOnboarding(LocalOnboarding onboarding) async {
    final generation = _sessionGeneration;
    await _onboardingRepository.save(onboarding);
    if (!_isCurrent(generation)) return;
    _onboarding = onboarding;
    setState(() => _stage = AppStage.profileSync);
  }

  void _showDraft(DraftDilemma? draft) {
    _draft = draft;
    _recoveredDraft = draft != null;
    setState(
      () => _stage = draft == null
          ? AppStage.home
          : draft.publicationPending
          ? AppStage.preview
          : AppStage.draft,
    );
  }

  Future<String?> _syncProfile() async {
    final generation = _sessionGeneration;
    final repository = _draftRepository;
    try {
      await widget.creatorProfileGateway.sync(_onboarding!);
      if (!_isCurrent(generation)) return null;
      final draft = await repository.load();
      if (!_isCurrent(generation)) return null;
      _showDraft(draft);
      if (draft != null) {
        _showDraft(draft);
        return null;
      }
      final dilemmas = await widget.dilemmaGateway.fetchDilemmas();
      if (!_isCurrent(generation)) return null;
      setState(() {
        _dilemmas = dilemmas;
        _dilemmaLoadError = null;
        _stage = AppStage.home;
      });
      return null;
    } catch (_) {
      return 'Não foi possível salvar seu perfil agora. Tente novamente.';
    }
  }

  void _createDraft() {
    final draft = _draft ?? DraftDilemma(idempotencyKey: widget.createId());
    _draft = draft;
    _recoveredDraft = false;
    _saveDraft(draft);
    setState(() => _stage = AppStage.draft);
  }

  void _updateDraft(DraftDilemma draft) {
    if (_publishing || _draft?.publicationPending == true) return;
    _draft = draft;
    _saveDraft(draft);
    setState(() {});
  }

  Future<String?> _publish() async {
    final draft = _draft;
    final generation = _sessionGeneration;
    if (_publishing || !_isCurrent(generation)) return null;
    if (draft == null ||
        !draft.isValid ||
        widget.config.guestInviteBaseUri == null) {
      return 'O convite ainda não está configurado para este ambiente.';
    }
    final repository = _draftRepository;
    final inviteRepository = _activeInviteRepository;
    _publishing = true;
    try {
      final profileStatus = await widget.creatorProfileGateway.status();
      if (!_isCurrent(generation)) return null;
      if (profileStatus == CreatorProfileStatus.needsSync) {
        setState(() => _stage = AppStage.profileSync);
        return null;
      }
      if (profileStatus == CreatorProfileStatus.unavailable) {
        return 'Sem conexão para publicar. Seu rascunho continua salvo.';
      }
      await _draftWrites;
      if (!_isCurrent(generation)) return null;
      if (_draftWriteError != null) {
        return 'Não foi possível salvar neste aparelho. Tente novamente.';
      }
      final pending = draft.copyWith(publicationPending: true);
      await repository.save(pending);
      if (!_isCurrent(generation)) return null;
      setState(() => _draft = pending);
      final published = await widget.publicationGateway.publish(pending);
      if (!_isCurrent(generation)) return null;
      final inviteUri = GuestInviteLinkBuilder(
        widget.config.guestInviteBaseUri,
      ).build(published.inviteToken);
      await inviteRepository.saveInviteUri(published.dilemmaId, inviteUri);
      await repository.clear();
      List<CreatorDilemmaSummary> updatedDilemmas = _dilemmas;
      try {
        updatedDilemmas = await widget.dilemmaGateway.fetchDilemmas();
      } catch (_) {
        // Best-effort sync; publication and active invite retention already succeeded.
      }
      if (!_isCurrent(generation)) return null;
      setState(() {
        _publishedDraft = draft;
        _publishedDilemmaId = published.dilemmaId;
        _publishedInviteUri = inviteUri;
        _dilemmas = updatedDilemmas;
        _draft = null;
        _recoveredDraft = false;
        _stage = AppStage.published;
      });
      return null;
    } catch (_) {
      return _draft?.publicationPending == true
          ? 'Não recebemos a confirmação. Tente novamente para recuperar o mesmo convite.'
          : 'Não foi possível salvar neste aparelho. Tente novamente.';
    } finally {
      if (_isCurrent(generation)) _publishing = false;
    }
  }

  Future<String?> _refreshDilemmas() async {
    final generation = _sessionGeneration;
    try {
      final dilemmas = await widget.dilemmaGateway.fetchDilemmas();
      if (!_isCurrent(generation)) return null;
      setState(() {
        _dilemmas = dilemmas;
        _dilemmaLoadError = null;
        if (_selectedDilemma != null) {
          _selectedDilemma = dilemmas.firstWhere(
            (d) => d.id == _selectedDilemma!.id,
            orElse: () => _selectedDilemma!,
          );
        }
      });
      return null;
    } catch (_) {
      if (!_isCurrent(generation)) return null;
      const error = 'Não foi possível atualizar as perspectivas agora.';
      setState(() => _dilemmaLoadError = error);
      return error;
    }
  }

  Future<void> _openDashboard(CreatorDilemmaSummary dilemma) async {
    final generation = _sessionGeneration;
    final inviteUri = await _activeInviteRepository.getInviteUri(dilemma.id);
    if (!_isCurrent(generation)) return;
    setState(() {
      _selectedDilemma = dilemma;
      _activeInviteUri = inviteUri;
      _stage = AppStage.dashboard;
    });
  }

  Future<String?> _revokeInvite(String dilemmaId) async {
    final generation = _sessionGeneration;
    final inviteRepository = _activeInviteRepository;
    try {
      await widget.dilemmaGateway.revokeInvite(dilemmaId);
      if (!_isCurrent(generation)) return null;
      setState(() {
        _activeInviteUri = null;
        _dilemmas = [
          for (final d in _dilemmas)
            if (d.id == dilemmaId) d.copyWith(isInviteRevoked: true) else d,
        ];
        if (_selectedDilemma?.id == dilemmaId) {
          _selectedDilemma = _selectedDilemma!.copyWith(isInviteRevoked: true);
        }
      });
    } catch (_) {
      return 'Não foi possível revogar o convite agora.';
    }
    try {
      await inviteRepository.removeInviteUri(dilemmaId);
    } catch (_) {
      // The server result is authoritative; a stale local link is invalid.
    }
    if (_isCurrent(generation)) await _refreshDilemmas();
    return null;
  }

  Future<String?> _deleteDilemma(String dilemmaId) async {
    final generation = _sessionGeneration;
    final inviteRepository = _activeInviteRepository;
    try {
      await widget.dilemmaGateway.deleteDilemma(dilemmaId);
      if (!_isCurrent(generation)) return null;
      setState(() {
        _dilemmas = _dilemmas.where((d) => d.id != dilemmaId).toList();
        _selectedDilemma = null;
        _activeInviteUri = null;
        _stage = AppStage.home;
      });
    } catch (_) {
      return 'Não foi possível apagar o dilema agora.';
    }
    try {
      await inviteRepository.removeInviteUri(dilemmaId);
    } catch (_) {
      // The deleted server resource remains deleted even if local cleanup fails.
    }
    if (_isCurrent(generation)) await _refreshDilemmas();
    return null;
  }

  Future<String?> _shareFromDashboard() async {
    if (_activeInviteUri == null) return null;
    try {
      await widget.shareGateway.share(_activeInviteUri!);
      return null;
    } catch (_) {
      return 'Não foi possível abrir o compartilhamento agora.';
    }
  }

  Future<String?> _share() async {
    if (!_isCurrent(_sessionGeneration) || _publishedInviteUri == null) {
      return null;
    }
    try {
      await widget.shareGateway.share(_publishedInviteUri!);
      return null;
    } catch (_) {
      return 'Não foi possível abrir o compartilhamento agora.';
    }
  }

  Future<void> _signOut() async {
    try {
      await widget.authGateway?.signOut();
    } finally {
      if (mounted && widget.authGateway?.userId == null) {
        setState(() => _stage = AppStage.googleSignIn);
      }
    }
  }

  @override
  void dispose() {
    _authSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => switch (_stage) {
    AppStage.privacyCleanupFailed => PrivacyCleanupFailedScreen(
      onRetry: _bootstrap,
    ),
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
    AppStage.home => CreatorHomeScreen(
      onCreate: _createDraft,
      dilemmas: _dilemmas,
      onSelectDilemma: _openDashboard,
      loadError: _dilemmaLoadError,
      onRetry: () async {
        await _refreshDilemmas();
      },
      onSignOut: _signOut,
    ),
    AppStage.draft => DraftScreen(
      draft: _draft!,
      recovered: _recoveredDraft,
      onChanged: _updateDraft,
      onReview: () => setState(() => _stage = AppStage.review),
      onBack: () => setState(() => _stage = AppStage.home),
      onSignOut: _signOut,
    ),
    AppStage.review => ReviewScreen(
      draft: _draft!,
      recovered: _recoveredDraft,
      onEdit: () => setState(() => _stage = AppStage.draft),
      onPreview: () => setState(() => _stage = AppStage.preview),
    ),
    AppStage.preview => GuestPreviewScreen(
      draft: _draft!,
      creatorName: _onboarding!.displayName.trim(),
      onBack: () {
        if (!_publishing && _draft?.publicationPending != true) {
          setState(() => _stage = AppStage.review);
        }
      },
      onPublish: _publish,
    ),
    AppStage.published => PublishedDilemmaScreen(
      draft: _publishedDraft!,
      onShare: _share,
      onGoToDashboard: () {
        final dilemma = _dilemmas.firstWhere(
          (d) => d.id == _publishedDilemmaId,
          orElse: () => CreatorDilemmaSummary(
            id: _publishedDilemmaId ?? '',
            itemName: _publishedDraft!.itemName,
            priceCents: _publishedDraft!.priceCents,
            currency: 'BRL',
            category: _publishedDraft!.category,
            purpose: _publishedDraft!.purpose,
            reason: _publishedDraft!.reason,
            pauseDueAt: DateTime.now().add(
              Duration(hours: _publishedDraft!.pauseHours),
            ),
            state: 'collecting_votes',
            isInviteRevoked: false,
            createdAt: DateTime.now(),
            buyCount: 0,
            waitCount: 0,
            skipCount: 0,
            totalVotes: 0,
          ),
        );
        _openDashboard(dilemma);
      },
    ),
    AppStage.dashboard => DilemmaDashboardScreen(
      dilemma: _selectedDilemma!,
      onBack: () => setState(() => _stage = AppStage.home),
      onShare: _activeInviteUri == null ? null : _shareFromDashboard,
      onRevoke: () => _revokeInvite(_selectedDilemma!.id),
      onDelete: () => _deleteDilemma(_selectedDilemma!.id),
      onRefresh: _refreshDilemmas,
    ),
  };
}

class PrivacyCleanupFailedScreen extends StatelessWidget {
  const PrivacyCleanupFailedScreen({super.key, required this.onRetry});

  final Future<void> Function() onRetry;

  @override
  Widget build(BuildContext context) => BibPageShell(
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Icon(Icons.privacy_tip_outlined, size: 52),
        const SizedBox(height: BibSpacing.x5),
        const Text(
          'Proteção local pendente',
          style: TextStyle(fontSize: 26, fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: BibSpacing.x3),
        const Text(
          'Não foi possível concluir uma limpeza de segurança neste aparelho. '
          'Tente novamente para continuar.',
        ),
        const SizedBox(height: BibSpacing.x5),
        FilledButton(onPressed: onRetry, child: const Text('Tentar novamente')),
      ],
    ),
  );
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
