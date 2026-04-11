# CLAUDE.md — MoneyFlow AI Finance Tracker

The authoritative guide for Claude Code when working in this repository.

Synthesised from: anthropics/financial-services-plugins, mubaraknumann/MyFinances, vp-k/flutter-craft, ssoad/flutter_riverpod_clean_architecture, and Dribbble top-400 expense-tracker UI patterns (2025).

---

## 1. AGENT PERSONALITY

Be direct and ruthlessly honest. No pleasantries, no unnecessary acknowledgments.

When code is wrong, say so immediately with the fix. When an approach is inefficient, name the better alternative. Skip "I understand" and "Great question." Quality and accuracy are the only priorities. Challenge assumptions. Ask one sharp clarifying question when requirements are ambiguous.

---

## 2. PROJECT OVERVIEW

**App name:** MoneyFlow AI  
**Package:** `moneyflow_ai`  
**Stack:** Flutter 3.x · Dart SDK ^3.11.4 · Riverpod 2.6 · Dio 5.7 · Drift 2.26 · fl_chart 0.70

**What this app does:**  
Personal finance tracker for Indian users. Tracks income, expenses, budgets, investments, insurance, vehicles, documents, recurring transactions, and AI insights. Includes offline-first sync (Drift → REST API), WhatsApp integration, and an AI insight card on the home screen.

**Environment modes:**

- `kNoApiMode = true` → runs entirely offline from Drift seed data (demo/dev mode)
- `kNoApiMode = false` → syncs with remote REST API via Dio + `LedgerSyncService`

---

## 3. REPOSITORY STRUCTURE

```
flutter-app/
├── lib/
│   ├── main.dart
│   ├── app.dart                         # MaterialApp + theme + ProviderScope
│   ├── core/
│   │   ├── api_config.dart              # kNoApiMode, base URL
│   │   ├── api_base_resolve.dart        # Platform-aware base URL resolver
│   │   ├── api_envelope.dart            # Standard {data, error} response wrapper
│   │   ├── dio_errors.dart              # Human-readable DioException messages
│   │   ├── providers.dart               # tokenStorageProvider, dioProvider
│   │   ├── storage/token_storage.dart   # SharedPreferences: JWT + email
│   │   ├── theme/
│   │   │   ├── app_theme.dart           # ThemeData light + dark (Material 3)
│   │   │   ├── ledger_tokens.dart       # LedgerGap, LedgerMotion, ledgerAmbientFabShadows
│   │   │   └── money_flow_tokens.dart   # MfSpace, MfRadius, MfPalette, MfMotion,
│   │   │                                # MoneyFlowThemeExtension, MoneyFlowThemeX
│   │   ├── design_system/
│   │   │   ├── app_button.dart          # AppButton (primary/secondary/ghost)
│   │   │   ├── app_card.dart            # AppCard (glass variant)
│   │   │   ├── app_skeleton.dart        # AppSkeleton shimmer
│   │   │   └── transaction_tile.dart    # TransactionTile (staggered entry anim)
│   │   ├── navigation/
│   │   │   └── ledger_page_routes.dart  # LedgerPageRoutes.fadeSlide<T>()
│   │   ├── offline/
│   │   │   ├── db/ledger_database.dart  # Drift tables: expenses, income, ...
│   │   │   ├── sync/ledger_sync_service.dart # pullAndFlush, deleteExpenseOffline
│   │   │   └── no_api_seed_data.dart    # Demo seed (kNoApiMode)
│   │   ├── application/theme_mode_provider.dart
│   │   └── widgets/
│   │       ├── ledger_ui.dart           # LedgerGlassBar, LedgerPrimaryGradientButton, ...
│   │       └── ledger_async_states.dart # LedgerEmptyState, LedgerErrorState, skeletons
│   └── features/
│       ├── shell/presentation/app_shell.dart       # IndexedStack + bottom nav
│       ├── auth/                                    # Login/register (JWT)
│       ├── dashboard/                               # Home screen + DashboardScreen
│       ├── expenses/                                # ExpenseListScreen + AddExpenseScreen
│       ├── income/                                  # Income list + add
│       ├── accounts/                                # Bank accounts
│       ├── budgets/                                 # Monthly budget caps
│       ├── investments/                             # Portfolio
│       ├── insurance/                               # Coverage
│       ├── vehicles/                                # Vehicle assets
│       ├── documents/                               # Scanned docs / PDF viewer
│       ├── reports/                                 # Charts (monthly/annual)
│       ├── insights/                                # AI insights
│       ├── notifications/                           # Alert centre
│       ├── recurring/                               # Recurring transactions
│       ├── profile/                                 # User profile + settings
│       └── whatsapp/                                # WhatsApp link status
├── assets/google_fonts/                             # Inter, Manrope, Plus Jakarta Sans, ...
├── pubspec.yaml
└── DESIGN.md                                        # Design system specification
```

---

## 4. STATE MANAGEMENT RULES

**Always use Riverpod. Never use setState except for purely local ephemeral UI state (e.g. password visibility toggle, tab index).**

### Provider naming

```dart
// Data providers (AsyncNotifierProvider or FutureProvider)
final expensesProvider        = FutureProvider<List<Map<String,dynamic>>>((ref) => ...);
final dashboardOverviewProvider = FutureProvider<Map<String,dynamic>>((ref) => ...);

// Notifiers
final sessionProvider = NotifierProvider<SessionNotifier, bool>(() => SessionNotifier());
final themeModeProvider = NotifierProvider<ThemeModeNotifier, ThemeMode>(() => ...);
```

### Invalidation pattern

```dart
// After a write, invalidate ALL affected providers in one call:
ref.invalidate(expensesProvider);
ref.invalidate(dashboardOverviewProvider);
ref.invalidate(categoryBreakdownProvider);
// Then await the primary one to confirm fresh data before returning:
await ref.read(dashboardOverviewProvider.future);
```

### Async state rendering (mandatory pattern)

```dart
ref.watch(someProvider).when(
  data:    (d) => _buildContent(d),
  loading: () => const LedgerExpenseListSkeleton(count: 5),
  error:   (e, _) => LedgerErrorState(
    title: 'Could not load X',
    message: e is DioException ? dioErrorMessage(e) : e.toString(),
    onRetry: () => ref.invalidate(someProvider),
  ),
);
```

---

## 5. DESIGN SYSTEM — TOKENS & RULES

### Spacing (use MfSpace, never raw numbers)

| Token | Value | Use |
|-------|-------|-----|
| `MfSpace.xs` | 4px | Icon-to-label gap |
| `MfSpace.sm` | 8px | Within-component gap |
| `MfSpace.md` | 12px | Between related elements |
| `MfSpace.lg` | 16px | Card inner padding (horizontal) |
| `MfSpace.xl` | 20px | Section gap |
| `MfSpace.xxl` | 24px | Screen horizontal padding |
| `MfSpace.xxxl` | 32px | Large section separator |

### Border radius (use MfRadius)

| Token | Value |
|-------|-------|
| `MfRadius.sm` | 12px — chips, small buttons |
| `MfRadius.md` | 16px — inputs, secondary cards |
| `MfRadius.lg` | 20px — primary cards |
| `MfRadius.xl` | 24px — hero cards, bottom sheets |

### Color semantics (NEVER hardcode; always use ColorScheme or MfPalette)

| Purpose | Token |
|---------|-------|
| Income / positive | `MfPalette.success` (#10B981) or `context.mf.success` |
| Expense / negative | `Color(0xFFE11D48)` |
| Savings / primary CTA | `cs.primary` (#4F46E5) |
| Warning / budget alert | `MfPalette.warning` (#F59E0B) |
| AI card gradient | `cs.primary → cs.primaryContainer` |

### Currency display rule

**ALL money values MUST be displayed with ₹ prefix and formatted with intl:**

```dart
import 'package:intl/intl.dart';
final _fmt = NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 0);
String formatAmount(dynamic raw) {
  final n = double.tryParse(raw?.toString() ?? '0') ?? 0;
  return _fmt.format(n);           // → ₹1,24,500
}
```

Never display raw numeric strings like `1500` or `'0'` in the UI.

### Typography

| Role | Font | Weight | Size |
|------|------|--------|------|
| Display amounts | Manrope | 700/800 | 28–44px |
| Screen titles | Plus Jakarta Sans | 700/800 | 24–28px |
| Section headers | Manrope | 700 | 16–17px |
| Body / lists | Inter | 400/500 | 13–15px |
| Labels / captions | Inter | 500 | 10–12px |

### No-border rule (from DESIGN.md)

Never use `1px solid border` to separate content sections. Use background tonal shifts (`surfaceContainerLowest` on `surface`) and vertical spacing instead. Exception: glass cards may use `Colors.white.withValues(alpha: 0.12)` border.

---

## 6. COMPONENT CONTRACTS

### AppButton

```dart
AppButton(
  label: 'Add expense',
  icon: Icons.add_rounded,
  variant: AppButtonVariant.primary,  // primary | secondary | ghost
  onPressed: () => ...,
  loading: false,
  expand: true,   // set false for inline buttons
)
```

### TransactionTile

```dart
TransactionTile(
  title: cat,
  subtitle: note.isNotEmpty ? note : date,
  amountLabel: '-₹1,200',      // already formatted with ₹
  leadingLabel: 'F',            // first letter for avatar
  isExpense: true,              // drives avatar + amount colour
  animationIndex: i,            // stagger index (0–8)
  endAction: ...,               // optional trailing widget
)
```

### AppCard (glass variant)

```dart
AppCard(
  glass: true,
  padding: const EdgeInsets.all(MfSpace.xxl),
  onTap: () => ...,
  child: ...,
)
```

### LedgerEmptyState

```dart
LedgerEmptyState(
  title: 'No expenses yet',
  subtitle: 'Add a transaction to see it here.',
  icon: Icons.receipt_long_outlined,
  actionLabel: 'Add expense',   // null → no button rendered
  onAction: () => ...,          // null → no button rendered
)
```

---

## 7. SCREEN IMPLEMENTATION PATTERNS

### Standard list screen

```dart
Scaffold(
  backgroundColor: cs.surface,
  appBar: AppBar(title: const Text('Screen title')),
  floatingActionButton: FloatingActionButton.extended(
    onPressed: () => Navigator.of(context).push(
      LedgerPageRoutes.fadeSlide<void>(const AddExpenseScreen()),
    ),
    icon: const Icon(Icons.add_rounded),
    label: const Text('Add'),
  ),
  body: asyncValue.when(
    data: (list) => RefreshIndicator(
      onRefresh: () async { await ref.read(ledgerSyncServiceProvider).pullAndFlush(); },
      child: ListView.builder(
        padding: EdgeInsets.fromLTRB(
          MfSpace.xxl, MfSpace.sm, MfSpace.xxl,
          MediaQuery.of(context).padding.bottom + 88,  // clear FAB
        ),
        itemCount: list.length,
        itemBuilder: (_, i) => ...,
      ),
    ),
    loading: () => const TransactionListSkeleton(count: 8),
    error:   (e, _) => LedgerErrorState(...),
  ),
)
```

### Navigation (always use LedgerPageRoutes for feature pushes)

```dart
Navigator.of(context).push(LedgerPageRoutes.fadeSlide<void>(const SomeScreen()));
// MaterialPageRoute only for legacy modal flows
```

---

## 8. OFFLINE-FIRST RULES

- All writes go through `LedgerSyncService` (never direct Dio calls from widgets).
- `pullAndFlush()` fetches from API and overwrites the local Drift DB.
- `deleteExpenseOffline(id)` marks local row deleted; sync pushes on next `pullAndFlush`.
- In `kNoApiMode`, `ensureNoApiSeed()` populates Drift with demo data on first launch.
- Providers read from Drift only; the sync service is the bridge.

```dart
// Write pattern
try {
  await ref.read(ledgerSyncServiceProvider).deleteExpenseOffline(id);
  if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(...);
} on DioException catch (e) {
  if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text(dioErrorMessage(e)), behavior: SnackBarBehavior.floating),
  );
}
```

---

## 9. KNOWN BUGS — FIX BEFORE ADDING FEATURES

| ID | File | Bug | Fix |
|----|------|-----|-----|
| BUG-01 | `core/design_system/transaction_tile.dart` | `?endAction,` — **compile error**, invalid Dart syntax | Change to `if (endAction != null) endAction!,` |
| BUG-02 | `features/shell/presentation/app_shell.dart` | `SafeArea(top:false)` inside Scaffold bottom nav = double padding on Android gesture-nav | Remove SafeArea; use `MediaQuery.of(context).padding.bottom` manually |
| BUG-03 | `features/auth/presentation/login_screen.dart` | Keyboard covers form on phones <700dp | Replace mobile `CustomScrollView` with `SingleChildScrollView(physics: ClampingScrollPhysics())` |
| BUG-04 | `features/auth/presentation/login_screen.dart` | No password show/hide toggle | Add `bool _passVisible` state + `suffixIcon: IconButton(...)` per password field |
| BUG-05 | `features/expenses/presentation/expense_list_screen.dart` | No FAB to add expenses from Expenses tab | Add `FloatingActionButton.extended(...)` |
| BUG-06 | `features/expenses/presentation/expense_list_screen.dart` | No swipe-to-delete | Wrap tiles in `Dismissible` with `confirmDismiss` dialog |
| BUG-07 | `features/dashboard/presentation/dashboard_quick_access.dart` | `childAspectRatio: 1.02` clips subtitle on 3-col phone layout | Set ratio per crossAxisCount: `4→1.1`, `3→0.92`, `2→1.0` |
| BUG-08 | All screens | Raw numbers displayed without ₹ prefix | Apply `formatAmount()` everywhere |

**Fix in this order:** BUG-01 → BUG-02 → BUG-03/04 → BUG-05/06 → BUG-07 → BUG-08.

Running `flutter analyze` must return 0 errors before a PR is created.

---

## 10. UI IMPROVEMENT TASKS (TRENDING 2025 — DRIBBBLE ANALYSIS)

Based on analysis of the top 400+ Dribbble expense-tracker shots and benchmarking against CRED, Niyo, Revolut, and Groww — the patterns that drive the most engagement and premium perception for Indian fintech apps:

### T-01: Aurora Animated Background (Home screen)

The single highest-engagement pattern on Dribbble 2025. Replaces the flat `surfaceContainerLowest` canvas with a living aurora.

```dart
// In MoneyFlowHomeScreen, wrap body in Stack:
Stack(children: [
  _AuroraBackground(),   // AnimationController + CustomPainter, 4 drifting blobs
  RefreshIndicator(child: CustomScrollView(...)),
])
```

Aurora blobs:

- Blob 1: `Color(0xFF6D28D9)`, radius 0.5, driftPeriod 10s, offset `Offset(0.15, 0.2)`
- Blob 2: `Color(0xFF2563EB)`, radius 0.4, driftPeriod 8s, offset `Offset(0.75, 0.1)`
- Blob 3: `Color(0xFFEC4899)`, radius 0.35, driftPeriod 12s, offset `Offset(0.2, 0.7)`
- Blob 4: `Color(0xFF06B6D4)`, radius 0.3, driftPeriod 9s, offset `Offset(0.8, 0.8)`

All blobs: opacity 0.30, filter: `ImageFilter.blur(sigmaX:60, sigmaY:60)`. Background: `Color(0xFF0A0F2C)` in dark / `Color(0xFFF0F4FF)` in light.

### T-02: Net Worth Hero Card — Glassmorphism

Replace the opaque gradient hero card with a true glass card.

```dart
// _NetWorthHero → wrap in ClipRRect(borderRadius:24) + BackdropFilter:
ClipRRect(
  borderRadius: BorderRadius.circular(MfRadius.xl),
  child: BackdropFilter(
    filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
    child: Container(
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(MfRadius.xl),
        border: Border.all(color: Colors.white.withValues(alpha: 0.15)),
        gradient: LinearGradient(
          begin: Alignment.topLeft, end: Alignment.bottomRight,
          colors: [
            cs.primary.withValues(alpha: 0.55),
            cs.primaryContainer.withValues(alpha: 0.40),
          ],
        ),
      ),
      ...
    ),
  ),
)
```

### T-03: Bento Grid — Metric Tiles (Dashboard)

Replace the 2×2 `_MetricCardsRow` with a proper bento grid using `CustomMultiChildLayout` or `Wrap` with explicit tile sizes. Each tile gets:

- Small coloured dot (6px, top-left)
- Label: Inter 500, 10px, UPPERCASE, `cs.onSurface.withValues(alpha:0.45)`
- Value: Manrope 700, 20px, colour-coded
- Micro trend arrow: `↑ 12%` in green / `↓ 4%` in red

Tile sizes (375pt screen width, 16pt horizontal padding, 10pt gap):

- Full-width tile: width = `double.infinity`, height = 80
- Half-width tile: width = `(screenWidth - 32 - 10) / 2`, height = 80
- One-third tile: width = `(screenWidth - 32 - 20) / 3`, height = 80

### T-04: Category Progress Bars (Expenses screen)

The most-liked Dribbble pattern for expense breakdown. Add to `ExpenseListScreen` above the list, OR as a new "Breakdown" section on DashboardScreen.

```dart
// Per category: label + amount right-aligned + gradient progress bar
// Bar height: 5px, borderRadius: 99px
// Income gradient: Color(0xFF10B981) → Color(0xFF10B981).withValues(alpha:0.35)
// Shopping gradient: Color(0xFF8B5CF6) → Color(0xFF8B5CF6).withValues(alpha:0.35)
// Food gradient: Color(0xFFEF4444) → Color(0xFFEF4444).withValues(alpha:0.35)
// Transport gradient: Color(0xFFF59E0B) → Color(0xFFF59E0B).withValues(alpha:0.35)
// Animate bar fill: Tween<double>(begin:0, end:fraction), 600ms, Curves.easeOutCubic
```

### T-05: Floating Bottom Nav (replacing fixed bar)

```dart
// In AppShell, replace Scaffold.bottomNavigationBar with a Stack overlay:
Scaffold(
  body: Stack(children: [
    IndexedStack(index: _index, children: [...]),
    Positioned(
      bottom: MediaQuery.of(context).padding.bottom + 12,
      left: 16, right: 16,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(28),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
          child: Container(
            height: 64,
            decoration: BoxDecoration(
              color: isDark
                  ? Colors.white.withValues(alpha: 0.08)
                  : Colors.white.withValues(alpha: 0.85),
              borderRadius: BorderRadius.circular(28),
              border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
            ),
            child: NavigationBar(
              height: 64,
              backgroundColor: Colors.transparent,
              labelBehavior: NavigationDestinationLabelBehavior.onlyShowSelected,
              ...
            ),
          ),
        ),
      ),
    ),
  ]),
)
```

### T-06: Animated Transaction Entry

```dart
// TransactionTile already uses TweenAnimationBuilder.
// Enhance: add SlideTransition alongside FadeTransition:
Transform.translate(
  offset: Offset(0, 20 * (1 - t)),  // was 12 — more dramatic entry
  child: Opacity(opacity: t, child: child),
)
// Also add scale: Transform.scale(scale: 0.95 + 0.05 * t)
```

### T-07: AI Insight Card — upgrade gradient

```dart
// Current: cs.primary → cs.primaryContainer
// Upgrade: sparkle shimmer effect using AnimatedContainer + shimmer pass
// New gradient: 135deg
//   Color(0xFF6D28D9).withValues(alpha: 0.95)
//   Color(0xFFEC4899).withValues(alpha: 0.80)
//   Color(0xFF3B82F6).withValues(alpha: 0.60)
// Add a subtle white shimmer sweep every 4s using AnimationController
```

### T-08: Dark Mode Color Corrections

```dart
// _heroGradientStart/End are hardcoded — invisible in dark mode.
// Fix:
final heroStart = cs.brightness == Brightness.dark
    ? cs.primaryContainer.withValues(alpha: 0.9)
    : const Color(0xFF000B60);
final heroEnd = cs.brightness == Brightness.dark
    ? cs.primary.withValues(alpha: 0.7)
    : const Color(0xFF1E3A5F);

// _FintechCard shadow fix for dark mode:
BoxShadow(
  color: cs.shadow.withValues(
    alpha: cs.brightness == Brightness.dark ? 0.30 : 0.06,
  ),
  blurRadius: 24, offset: const Offset(0, 10),
)
```

---

## 11. FEATURE DEVELOPMENT WORKFLOW

When adding any new feature, follow this sequence:

1. **Data layer** — Add Drift table columns if needed; run `dart run build_runner build`
2. **API layer** — Add method to the feature's `*_api.dart` (Dio calls)
3. **Provider layer** — Add/update `*_providers.dart` (FutureProvider or AsyncNotifier)
4. **Sync layer** — If write operation, add method to `LedgerSyncService`
5. **UI layer** — Build screen; consume providers with `.when()`; use design tokens only
6. **Navigation** — Register route in `ledger_page_routes.dart` if needed
7. **Tests** — `flutter test` must pass; `flutter analyze` must return 0 errors

### Feature file template

```
lib/features/<name>/
├── data/<name>_api.dart          # Dio methods
├── application/<name>_providers.dart  # Riverpod providers
└── presentation/<name>_screen.dart    # Widget (ConsumerWidget or ConsumerStatefulWidget)
```

---

## 12. CODE QUALITY RULES

### Null safety

Never use `!` on dynamic map values. Use `?? fallback` instead:

```dart
// Wrong: e['amount']!
// Right: e['amount']?.toString() ?? '0'
```

### unawaited

Import explicitly: `import 'dart:async' show unawaited;`  
Use for fire-and-forget refresh calls inside `setState` or lifecycle methods.

### withValues vs withOpacity

**Always** use `color.withValues(alpha: 0.5)` — `withOpacity` is deprecated in Flutter 3.27+.

### BuildContext across async gaps

Always check `if (context.mounted)` before using `context` after any `await`.

### Avoid in build methods

- No `ref.read()` during build — use `ref.watch()`
- No direct Dio calls — always go through providers or `LedgerSyncService`
- No `double.parse()` without `tryParse()` fallback

---

## 13. COMMANDS

```bash
# Run app
flutter run

# Run with specific device
flutter run -d <device_id>

# Analyze (must be 0 errors before commit)
flutter analyze

# Tests
flutter test

# Regenerate Drift code after schema changes
dart run build_runner build --delete-conflicting-outputs

# Format all Dart files
dart format lib/

# Build release APK
flutter build apk --release --split-per-abi
```

---

## 14. ENVIRONMENT & API CONFIGURATION

```dart
// lib/core/api_config.dart
const bool kNoApiMode = true;   // ← flip to false to enable live API
```

Base URL resolution (platform-aware):

- Android emulator: `http://10.0.2.2:8000`
- iOS simulator: `http://127.0.0.1:8000`
- Real device: set via env or build config

Token storage keys (SharedPreferences):

- `access_token` — JWT access token
- `refresh_token` — JWT refresh token
- `session_id` — optional session identifier
- `user_email` — cached user email for greeting

---

## 15. TESTING CHECKLIST (run after any significant change)

- [ ] `flutter analyze` → 0 errors, 0 warnings
- [ ] `flutter test` → all tests pass
- [ ] App builds: `flutter build apk --debug`
- [ ] Login: password show/hide works on both fields
- [ ] Login: keyboard opens → form remains scrollable and visible
- [ ] Home screen: balance shows ₹ prefix with Indian number format
- [ ] Expenses tab: FAB visible above bottom nav
- [ ] Expenses tab: swipe left on tile → confirmation dialog → item removed
- [ ] Dashboard quick-access: all 11 tiles show icon + title + subtitle on 360dp phone
- [ ] Navigation bar: no double padding on Android gesture-navigation device
- [ ] Pull-to-refresh: triggers `pullAndFlush()` and re-renders with new data
- [ ] Dark mode: all cards visible, amounts readable, hero card distinct from background
- [ ] `kNoApiMode = true`: app runs fully offline with seed data
- [ ] `kNoApiMode = false`: app connects to local API and syncs correctly

---

## 16. DO NOT

- Do NOT use `setState` for data fetching — use providers
- Do NOT call Dio directly from widgets — use providers or `LedgerSyncService`
- Do NOT hardcode colours — use `cs.*`, `MfPalette.*`, or `context.mf.*`
- Do NOT use raw number strings in the UI — always format with `formatAmount()`
- Do NOT add third-party packages without checking if the existing stack covers the need
- Do NOT break the `kNoApiMode` offline path when adding API features
- Do NOT use `withOpacity()` — use `withValues(alpha: ...)` (Flutter 3.27+)
- Do NOT use `context` after an `await` without `if (context.mounted)` guard
- Do NOT ship a PR with `flutter analyze` warnings
