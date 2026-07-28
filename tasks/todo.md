# Testabilidade do WatchTracker

## Fase 0 — Fazer a suíte passar
- [x] Corrigir `MockMediaDetailService`: placeholder `<#code#>`, `fetchRecommendationsResult` tipado como `[Int]`, label de tupla `tvId`→`type`, linha duplicada comentada
- [x] Apagar o stub vazio `WatchTrackerTests.swift`
- [x] Corrigir teste desatualizado: cap de sugestões é 8 desde o commit `88f5b55`, não 5

## Fase 1 — Costuras de injeção (cirúrgico)
- [x] `APIClient`: `init(session:tokenProvider:clock:)` público; `makeDecoder()`/`makeEncoder()`/`validateResponse` internos
- [x] `ProfileServiceProtocol` + `ProfileService`; `ProfileViewModel.init(service:)`
- [x] `AnalyticsTracking` → injetado em `MediaDetailViewModel` e `DiscoverViewModel`
- [x] `NotificationScheduling` → injetado em `WatchlistViewModel` e `UpcomingViewModel`
- [x] `NotificationService`: helpers puros `airDate`/`triggerComponents`/identificadores
- [x] `UpcomingViewModel`: `calendar` e `now` injetáveis
- [x] `DiscoverViewModel`: `userDefaults`, `clock`, `now`; `searchTask`/`providerTask` observáveis; helpers de merge internos
- [x] `ImportViewModel`: `importItems(_:)` extraído, `batchSize` injetável
- [x] `APIError: Equatable`

## Fase 2 — Testes do Core
- [x] Helpers: `StubURLProtocol`, `ImmediateClock`, `MockAnalytics`, `MockNotificationScheduler`, `MockProfileService`, `MockImportService`
- [x] Network: `APIClientTests`, `EndpointCoverageTests`, `APIErrorTests`
- [x] Models: `WatchItem`, `Episode`/`Season`, enums, `ProfileStats`, `StreamingProvider`, `ImportModels`, URLs de itens
- [x] Services: `ProviderLinkBuilder`, `FeedbackComposer`, `ProfileService`, planejamento de notificações, `AppRouter`
- [x] Extensions: `Error.userFacingMessage`, `Strings.Rating.mood` + chaves parametrizadas, `Bundle+AppInfo`

## Fase 3 — Testes das Features
- [x] `ProfileViewModelTests` (novo)
- [x] `ImportViewModelTests` (novo)
- [x] `LetterboxdParserTests` + `CSVParserTests` (novos)
- [x] `DiscoverViewModelTests` migrado para clock determinístico + helpers de merge + persistência de provider
- [x] `MediaDetailViewModelSupplementalTests` (ratings, recomendações, cache, analytics)
- [x] `WatchlistViewModelNotificationTests`
- [x] `UpcomingViewModelTests` com calendário/agora fixos

## Fase 4 — Infra
- [x] `codeCoverageEnabled = YES` no `WatchTracker.xcscheme`
- [x] `scripts/test.sh` com resolução de simulador por udid e relatório de cobertura
- [x] Target de teste: `SDKROOT = auto`, `SUPPORTED_PLATFORMS`, `MARKETING_VERSION` 1.1.0 → 1.3.0

---

## Review

### Resultado
- Suíte: **vermelha (não compilava) → verde**, 3 execuções seguidas sem flakiness
- Cobertura de `WatchTracker.app`: **11,56% → 20,33%**
- Arquivos de teste: 16 → 30; execuções de teste: ~150 → 557

### Bugs de produção encontrados pelos testes
1. **`ProviderLinkBuilder`** usava `.urlQueryAllowed`, que não escapa `&`. Um título como "Fire & Blood" truncava a busca do provedor em "Fire". Corrigido com um `CharacterSet` que remove os sub-delimitadores.
2. **`DateFormatter` sem `Locale(identifier: "en_US_POSIX")`** em `NextEpisode.isReleased`, `UpcomingEpisode.localDaysUntilAir` e `NotificationService.scheduleNotifications`. Sob um calendário não-gregoriano no dispositivo, o parse de `yyyy-MM-dd` falha silenciosamente e todos os lembretes de episódio somem. `Episode.hasAired` já fazia certo — padronizado.
3. **`SearchHistoryManager.remove`** comparava case-sensitive enquanto `save` deduplica case-insensitive: uma busca salva como "Batman" não podia ser removida pela linha "batman" do histórico.

### Decisões
- Injeção por *default argument*, então nenhum call-site de View mudou.
- `ImmediateClock` escrito à mão no target de teste em vez de adicionar `swift-clocks` como dependência (ele só existe transitivamente via Supabase).
- `StubURLProtocol` associa stubs por configuração de sessão (header token) em vez de `URLProtocol.registerClass` global, para não quebrar sob execução paralela.

### Fora de escopo (registrado)
- `AuthService` / `SupabaseManager`: sem protocolo; `init()` já dispara listeners, exigiria refatoração ampla.
- `AISuggestionsViewModel` / `AIService`: sem protocolo, gate `iOS 26`, `FoundationModels` no dispositivo.
- Validação de senha do `AuthView`: vive `private` dentro da View, precisaria ser extraída para um tipo testável.
