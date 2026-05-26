# BrainLaBomb — Full Session Handoff

**Project:** BrainLaBomb — iOS SwiftUI decision-making app  
**Date of handoff:** 2026-05-26  
**Working directory:** `/Users/andrewwilson/my projects/brainlabomb`  
**Xcode project:** `BrainLaBomb.xcodeproj` (generated via xcodegen from `project.yml`)  
**Git remote:** `https://github.com/Andrew-2120042/brain-app.git`  
**Last known git push:** commit `cd88e54` — history isolation refactor, boundary card, HistoryPanelView reactive fix, and supporting changes. Do NOT push again until explicitly told to.

---

## What This App Does

User opens the app → types a situation/decision → app runs two API calls to Anthropic:

**Call 1 (firstPass):** Classifies the input — should it ask a follow-up question? Returns `needsQuestion`, `question`, and `mode` (DECISION / DIRECTION / EMOTIONAL).

**Call 2 (secondPass):** Full simulation. Returns verdict, confidence, reasoning, whyPoints, tradeoffs, majority/minority outcomes, archetype, patternNote, historyInsight, whatYoureNotSaying, whatUsuallyHelps.

Result shows as a **flip card** (front = verdict + confidence + simulation count, back = Why + Trade offs + two buttons). From the back card the user can open **StoriesView** (story-style swipeable cards with full report) or **ChatView** (chat about the decision — Pro only).

History panel shows all past thinks, tapping one reopens the card. Pattern identity is generated after every 5th think.

---

## File Map — Every File and What It Does

| File | Role |
|------|------|
| `Constants.swift` | All API config, prompts (`firstPassSystemPrompt`, `secondPassSystemPrompt`, `anchoringRules`, `haikuSystemPrompt`, `patternAnalysisPrompt`), app constants |
| `Models.swift` | All data models: `DecisionResult`, `DecisionReport`, `DecisionArchetype`, `OutcomeRow`, `Think`, `ChatBubble`, `PatternIdentity`, `PatternData`, mock data |
| `AppViewModel.swift` | Central state machine. `AppState` enum drives the whole app. Handles tier logic, think counters, history persistence, pattern analysis trigger |
| `APIClient.swift` | Three API calls: `firstPass`, `secondPass`, `analyzePattern`. Both `firstPass` and `secondPass` have a silent Sonnet fallback when Haiku returns non-JSON (see Phase 31). No streaming — full response. |
| `ContentView.swift` | Root switch on `viewModel.appState` — routes to correct screen. Also hosts onboarding fullScreenCover. |
| `HomeView.swift` | Home screen with two layout versions (v1 = full button, v2 = underline text). Debug bar at top: mock/live toggle, v1/v2 toggle, tier toggle, haiku toggle, notif debug, BDRY button, CORRUPT button. History panel slides in from left. Settings sheet. |
| `DecisionCardView.swift` | The flip card screen. Has gyroscope tilt, drag-to-rotate, tap-to-flip, spring arrival animation. Front = `DecisionCard`, Back = `CardBackView`. Also has layout switcher debug bar (A-E). |
| `DecisionCard.swift` | Front face of the card. 5 layout variants (A-E). Renders verdict, confidence, simulation count. |
| `CardBackView.swift` | Back face of card. Renders Why + Trade offs (scrollable). Two action buttons: "chat about this" (Pro only, lock icon for free) and "view full report". Has `verdictIsTruncated` logic — shows full verdict at top of back only if front text was cut off. |
| `StoriesView.swift` | Story-style view with progress bars. 5-6 cards depending on history. See card breakdown below. |
| `ChatView.swift` | Chat interface. Haiku-only. Pro tier only. Persists messages per think. |
| `HistoryPanelView.swift` | Slides in from left. Shows past thinks as cards. Tapping opens card + chat. Swipe right to close. |
| `PatternView.swift` | Pattern identity reveal. Shown in stories as card 5/6. Also accessible from settings debug. |
| `PaywallView.swift` | Paywall screen. Video background (`paywall_bg.mov`). Tappable Core/Pro plan cards. CTA text and fine print change based on selection. |
| `OnboardingView.swift` | 12-screen onboarding with video background, quiz, animated brain build, notifications request, inline paywall, and thank-you. Shows once on first launch. `hasCompletedOnboarding` in UserDefaults. Debug: Settings → debug → "replay onboarding". Has `#if DEBUG` overlay: screen nav pill + BG toggle + screen size readout. |
| `OnboardingVideoController.swift` | Manages the single persistent `AVPlayer` for onboarding. Parses `onboarding_timeline.json`, loops alive sections, plays transitions on Next tap, then loops next alive section. One player lives for the entire onboarding session. |
| `onboarding_master_timeline.mp4` | Master onboarding video (in app bundle). 1290×2796 portrait, ~94s, 60fps. |
| `onboarding_timeline.json` | Timeline JSON for the onboarding video. Array of `{type, startMs, endMs, shapeTitle}` objects. Types: `"alive"` (loops) and `"transition"` (plays once). |
| `InputPageView.swift` | "What's on your mind?" text input screen. |
| `QuestionCardView.swift` | Follow-up question screen. Appears only when firstPass says `needsQuestion: true`. |
| `SimulatingView.swift` | Loading screen shown during API calls. |
| `SettingsView.swift` | Settings sheet. Clear all data, tier info. Has debug pattern inject. |
| `LoopingVideoView.swift` | Reusable AVPlayer wrapper for looping MP4/MOV files. |
| `NotificationManager.swift` | Push notification setup. `scheduleTestNotification()` sends instantly. |
| `DecisionEngine.swift` | Older engine file — may be leftover/unused. Check before touching. |
| `VideoPlaceholderView.swift` | Placeholder — may be unused. |
| `CardThicknessOverlay.swift` | Was added for the 3D thickness effect during card flip, then removed. The file may still exist but the feature was reverted. |
| `Secrets.swift` | Contains `anthropicAPIKey` string. NOT committed to git. |

---

## StoriesView Card Breakdown (6 cards max)

| Index | Card | Content |
|-------|------|---------|
| 0 | REASONING | Big flowing reasoning paragraph. Heading "REASONING". |
| 1 | Card 2 — mode-dependent | **DECISION:** majority outcome rows with %. **DIRECTION:** majority outcome rows with %. **EMOTIONAL:** whatYoureNotSaying field + reasoning at larger font. |
| 2 | Card 3 — mode-dependent | **DECISION:** minority outcome rows. **DIRECTION:** minority outcome rows. **EMOTIONAL:** whatUsuallyHelps field. |
| 3 | ARCHETYPE | Blurred + locked for free tier. Shows archetype name, description, percentage. Unlock Pro button in middle. |
| 4 | FROM YOUR THINKS (historyInsight) | Only shows if `historyInsight` is non-empty AND think count >= 5. Otherwise goes straight to patternCard. |
| 5 | PATTERN CARD | Pattern identity. Blurred + locked for free tier. Two buttons at bottom: "new think" and "continue in chat" (chat hidden for non-Pro). |

---

## Tier System

### Free
- 5 lifetime thinks (tracked in `UserDefaults` key `thinksUsed`)
- After 5 thinks → paywall
- No chat
- Archetype card blurred/locked
- Pattern card blurred/locked
- Model: Sonnet

### Core — $39.99 / 6 months
- 500 total thinks
- First 350 → Sonnet (`Constants.model` = `claude-sonnet-4-20250514`)
- Remaining 150 → Haiku (`claude-haiku-4-5-20251001`)
- No chat
- Everything else unlocked
- Tracked: `coreThinksUsed` in UserDefaults

### Pro — $99.99 / year
- Unlimited thinks
- First 200/month → Sonnet
- 200+ → Haiku
- Chat unlocked (Haiku only, always)
- Everything unlocked
- Tracked: `monthlyThinkCount` (resets monthly)

### Debug Tier Toggle
In DEBUG builds, top-right of home screen has FREE / CORE / PRO cycle button. Also HAIKU / SONNET toggle to force-override model. Also MOCK / LIVE toggle.

RevenueCat is NOT integrated yet. All tier logic is currently gated on `debugTier` in DEBUG and returns `.free` in release.

---

## Prompts — Location and Current State

All prompts live in `Constants.swift`.

### `firstPassSystemPrompt` (lines 25–79)
First API call. Classifies input, decides if follow-up question needed. Returns JSON with `needsQuestion`, `question`, `mode`. Handles emotional/crisis signals by forcing `needsQuestion: false`.

### `secondPassSystemPrompt` (lines 81–311)
Main Sonnet prompt. Full decision simulation. Returns the big JSON with all fields. Has:
- Boundary responses (crisis, violence, off-topic, sexual, jailbreak)
- YOUR VOICE section with concrete examples
- FIVE LAYERS (EMOTIONAL, SOCIAL, BODY, EGO, TIME) — reason silently before writing
- MODE BEHAVIOR (DECISION, DIRECTION, EMOTIONAL)
- MIXED INPUT RULE
- Full JSON schema in the prompt itself
- ARCHETYPE RULES (6 types: Overthinker, Gut Truster, Optimizer, Avoider, Realist, Thinker)
- NUMBER RULES, OUTCOME RULES
- WHY POINTS AND TRADEOFFS section
- WHAT YOU'RE NOT SAYING and WHAT USUALLY HELPS (EMOTIONAL mode only)
- HISTORY INSIGHT rules

### `anchoringRules` (lines 313–416)
Appended to Sonnet's secondPass call only. Contains:
- VERDICT ANCHORING RULE — verdict must be locked to a specific detail from their input
- HISTORY USAGE RULE — use history silently, never announce it
- REASONING IS PURELY ABOUT TODAY — zero past-think references in reasoning
- ALL HISTORY OBSERVATIONS GO TO historyInsight ONLY
- patternNote is per-think observation, NOT cross-session
- NEVER ASSUME FACTS FROM HISTORY — extensive with examples

### `haikuSystemPrompt` (lines 419–868)
Dedicated Haiku prompt — completely separate from Sonnet, not a stripped version. Has:
- More explicit MODE DETECTION (Rules 1–7) — much more detailed than Sonnet's
- VERDICT ANCHORING RULE (same as Sonnet)
- HISTORY USAGE RULE + NEVER ASSUME FACTS FROM HISTORY (same as Sonnet)
- Detailed per-field word count limits (verdict < 12 words, whyPoints each < 8 words, etc.)
- CONSISTENCY RULES (percentage math must add up)
- whatYoureNotSaying formatted as 3 separate lines (not paragraph like Sonnet)
- whatUsuallyHelps as 3 actionable lines (not paragraph)
- Archetype list includes "The Stoic" (7 types vs Sonnet's 6)
- RETURN FORMAT with blank JSON template

### `patternAnalysisPrompt` (lines 871–916)
Third API call (Sonnet). Runs after every 5th think. Returns `needsMoreData` or `patternIdentity` with name, description, percentage, insight.

---

## What Sonnet Has That Haiku Is Missing (NOT YET ADDED)

FIVE THINKING LAYERS was added to Haiku (see Phase 17 below). Remaining gaps still not ported:

1. **YOUR VOICE** — the "you sound like this / you do NOT sound like this" examples with the unemployment example sentence
2. **MIXED INPUT RULE** — "If the situation feels emotional BUT contains a clear action question — always use DECISION mode and populate ALL fields fully"
3. **Emotional extraction examples** — "I miss her → do I reach out or give it time" examples
4. **ONE FINAL RULE** — "If your response would embarrass a brilliant, honest, caring human mentor — rewrite it"
5. **LIFESTYLE DECISIONS** explicit paragraph

---

## What Was Built (Chronological)

### Phase 1 — App Foundation
- Built the entire app from scratch. Decision card with 5 layout variants (A-E). Video backgrounds for each layout. Card flip (drag-to-rotate + tap). Gyroscope tilt. Card arrival spring animation.
- Tried CardThicknessOverlay for 3D thickness effect during flip — **removed**, user didn't like it.
- Video trimming experiments for the cosmos background videos — landed on keeping existing cuts.
- Settled on float design (black background, `float_bg` image, card with 0.5px white border at 35% opacity + soft white shadow). All other layout variants (video version, light version) were removed.

### Phase 2 — Stories / Full Report
- Built StoriesView as Instagram-style story cards with progress bars.
- Long iteration on headings (all caps, first letter capital, font sizes, line under heading — line was removed).
- Settled on Helvetica Neue font for headings in stories, Poppins for card content.
- Reasoning card: one flowing paragraph, left-aligned.
- Hold to pause stories. Progress bars. Auto-advance at 7 seconds.

### Phase 3 — Home Page
- Two home versions (v1 and v2). Currently v1 is shown by default (full "Think" button).
- v2 has underline text "simulate before you decide." — both are kept, toggled via debug.
- Background: two looping videos (`home_bg.mp4` and `home_bg5.mp4`). Toggle between them with version button.
- Text: "Every choice is a simulation."
- Removed: "BrainLaBomb" logo, old taglines.

### Phase 4 — Backend
- Added full `APIClient.swift` with 3 API calls.
- Added `Constants.swift` with API key (in `Secrets.swift`) and prompts.
- Added `Models.swift` with flat-JSON decoding for `DecisionResult`.
- MOCK / LIVE toggle in `@AppStorage("debug_useMockData")`.

### Phase 5 — Question Card
- `QuestionCardView` — slides in when brain needs one more piece of info.
- Flow: home → input → (processingFirst) → [optional: question] → (processingSecond) → result.
- Keyboard closes before transitioning to processing screen.

### Phase 6 — Chat
- `ChatView` — chat about a specific think. Uses Haiku model. Pro only.
- Chat persists per think in `thinkHistory` (saved to UserDefaults).
- "chat about this" button on back of card (locked with lock icon for non-Pro).
- "continue in chat" button in last story card (hidden entirely for non-Pro).

### Phase 7 — History Panel
- `HistoryPanelView` slides from left edge.
- Shows thinks as cards with question text and verdict.
- Tapping a think opens its card. From there can open chat (which loads existing messages).
- Swipe right to dismiss panel.
- History icon top-left of home screen.

### Phase 8 — Pattern Identity
- After every 5th think → runs `patternAnalysisPrompt` silently in background.
- `PatternData` stored in UserDefaults.
- Shown in stories as card 5 (pattern card). Blurred and locked for free/core tier.
- PatternView is also referenced from settings debug.
- `injectMockPatternData()` debug function available.

### Phase 9 — Onboarding (v1)
- `OnboardingView` — 3 screens, shows on first launch, then never again.
- `hasCompletedOnboarding` in UserDefaults.

### Phase 10 — Paywall
- `PaywallView` with video background (`paywall_bg.mov` = `Screen Recording 2026-05-11 at 1.56.31 PM.mov`).
- Shows Core and Pro tiers with features list.
- Text styled to match app voice.

### Phase 11 — Tier Enforcement
- Free: 5 think limit enforced in `AppViewModel.submitQuestion`. Redirects to paywall.
- Core: `coreThinksUsed` counter. 350 → Sonnet, then Haiku. No chat.
- Pro: monthly counter. 200 → Sonnet, then Haiku. Chat unlocked.
- Debug tier toggle in HomeView top bar. Cycles FREE → CORE → PRO.

### Phase 12 — historyInsight Card
- Added `historyInsight` field to API response.
- In `anchoringRules` and `haikuSystemPrompt`: cross-session observations ONLY go in `historyInsight`. Never in reasoning, verdict, whyPoints, tradeoffs.
- New story card "FROM YOUR THINKS" shows `historyInsight`. Appears between archetype and pattern cards.
- Only renders if `historyInsight` is non-empty AND think count >= 5.

### Phase 13 — patternNote Wiring
- `patternNote` was decoded but not shown. Added a small italic line on the archetype card in stories to display it.

### Phase 14 — History Contamination Fix
- Issue: brain was assuming facts from past thinks (e.g., "you're leaving anyway" when user never said that today).
- Added `HISTORY BAN FOR BOTH FIELDS` section to Sonnet prompt's WHY POINTS AND TRADEOFFS.
- Added `NEVER ASSUME FACTS FROM HISTORY` to both Sonnet (via `anchoringRules`) and Haiku prompt — both already had this but added more examples.
- This was the last prompt change made. Both Sonnet and Haiku have these rules now.

### Phase 15 — Haiku Dedicated Prompt
- Previously Haiku used same prompt as Sonnet with `tighteningInstructions` appended in `APIClient.swift`.
- Replaced with fully dedicated `haikuSystemPrompt` in `Constants.swift`.
- `APIClient.secondPass` now routes to `haikuSystemPrompt` when `useHaiku: true`.
- Removed `tighteningInstructions` from `APIClient.swift` entirely.
- Removed debug toggles for "tight" and "anchoring" from HomeView (they were debug buttons for the old system).

### Phase 16 — Card Size Fix
- Card was occasionally showing smaller than expected, especially when opening from history.
- Fixed by ensuring `cardScale` starts at correct value and spring animation targets `1.0`.
- Card dimensions hardcoded consistently.

### Phase 17 — FIVE THINKING LAYERS Added to Haiku
- Sonnet already had the FIVE LAYERS section (EMOTIONAL, SOCIAL, BODY, EGO, TIME) at line 144 of `secondPassSystemPrompt`.
- Haiku had none of it. Added as `FIVE THINKING LAYERS` block in `haikuSystemPrompt` after the VOICE section, before MODE DETECTION.
- Includes all five layers with descriptions + HOW TO USE instructions explaining they are a diagnostic tool, not a template, and never appear as separate sections in output.
- `haiku_prompt.md` file created at project root — snapshot of the full Haiku prompt as plain text for reference.

### Phase 18 — firstPass JSON Decode Fix
- `firstPass` was crashing with "JSON decode failed: The data couldn't be read because it is missing" when the model wrapped its response in ` ```json ` fences.
- Root cause: `firstPass` had no `cleanJSON` call — raw response went straight to `JSONDecoder`.
- Fix: added `cleanJSON(responseText)` call in `firstPass`, same as `secondPass` already had.
- Also improved `firstPass` catch block to include `cleanedResponse` in the error message (was previously a vague error with no raw output).

### Phase 19 — cleanJSON Hardened (Preamble Stripping)
- `cleanJSON` previously only stripped ` ```json` and ` ``` ` fences using `hasPrefix`/`hasSuffix`.
- If the model added ANY preamble text before the fence (e.g. "Here is the response:"), the fence check would fail and the raw text reached the decoder.
- Fix: added `firstBrace...lastBrace` slicing after fence stripping — always cuts from first `{` to last `}` regardless of what came before or after.
- This is a belt-and-suspenders approach: fence stripping handles the normal case, brace slicing handles any edge case.
- `analyzePattern` catch block also fixed — was a bare `try` that would throw instead of returning nil on decode failure. Wrapped in do-catch, logs in DEBUG, returns nil silently in release.

### Phase 20 — firstPass Haiku Support
- `firstPass` was hardcoded to `Constants.model` (Sonnet) regardless of any debug toggle.
- When `forceHaikuMode` was on, only `secondPass` used Haiku — `firstPass` still used Sonnet. Not true full-Haiku testing.
- Fix: added `useHaiku: Bool = false` parameter to `firstPass` in `APIClient.swift`. Selects `modelToUse` the same way `secondPass` does.
- `AppViewModel.submitQuestion` updated to pass `shouldUseHaiku` to `firstPass`.
- `firstPassSystemPrompt` unchanged — it works correctly for both models.
- `haikuSystemPrompt` QUESTION DETECTION section updated with strict format instruction: "first character of your entire response must be `{`" — prevents markdown fence wrapping at the prompt level.

### Phase 21 — Deep Architecture Audit (Read Only)
Full audit of `APIClient.swift`, `AppViewModel.swift`, `Constants.swift`, `Models.swift`. Key findings:
- **No prompt caching** — every call pays full system prompt token cost. Not implemented.
- **No temperature set** — defaults to 1.0. Contributes to verdict inconsistency between runs.
- **Pro monthly Haiku threshold off by one** — `shouldUseHaiku` checks `monthlyThinkCount > 200` but counter is read before increment, so effectively 201 Sonnet thinks before Haiku kicks in.
- **`clearAllData()` missing keys** — doesn't clear `monthlyThinkCount` or `lastMonthlyReset`.
- **`mode` field decode is case-sensitive** — if model returns "Emotional" instead of "EMOTIONAL" the whole decode fails.
- **API key compiled into binary** — extractable from IPA. Needs backend proxy before App Store.
- **No IAP flow** — paywall is decorative in production. RevenueCat not integrated.
- **No retry logic** — any network failure goes straight to error screen.
- **429/500 errors show raw status code** — not user-friendly messages.

### Phase 22 — Onboarding Expanded to 10 Screens
Rewrote `OnboardingView.swift` from 3 screens to a full 10-screen flow:
- **Screen 0** — "your brain is a liar." hero statement with "let's see" CTA.
- **Screen 1** — "most people decide like this." explanation of gut feeling vs simulation.
- **Screen 2** — "meet your brain." intro to the app concept.
- **Screen 3** — Quiz 1: decision style (gut vs. data vs. overthink).
- **Screen 4** — Quiz 2: what trips you up (fear / logic / emotion / opinion).
- **Screen 5** — Animated brain building. Progress bar fills over 2s. Headline crossfades from "building your brain." to "your brain is ready." Auto-advances to screen 6.
- **Screen 6** — How it works: 3-step explainer (type → brain simulates → see the outcome).
- **Screen 7** — Notifications permission. "yes, find me" triggers `UNUserNotificationCenter.requestAuthorization`, "not yet" skips. Both advance to screen 8.
- **Screen 8** — Inline paywall. Scrollable. Free / Core / Pro plan cards. "start my 3-day free trial" CTA for Pro (selected by default). `TODO: RevenueCat` purchase call — currently just advances to screen 9.
- **Screen 9** — Thank-you screen. "you're in." Auto-advances after 3s and calls `onComplete()`.
- `hasCompletedOnboarding` in UserDefaults still owns gating. ContentView unchanged.
- Progress bar uses `scaleEffect(x: progress, y: 1, anchor: .leading)` — no GeometryReader needed.
- Text crossfade on screen 5 uses `.id(brainReady).transition(.opacity)` pattern.

### Phase 23 — PaywallView Plan Selection
Updated `PaywallView.swift` to support plan switching:
- Added `@State private var selectedPlan: Int = 1` (0=Core, 1=Pro).
- Replaced single price block with two tappable `paywallPlanCard()` cards (Core = $39.99/6mo, Pro = $99.99/yr with 3-day trial).
- CTA text changes based on selection: Core → "get Core — $39.99", Pro → "start my 3-day free trial".
- Fine print line below CTA only shows for Pro selection.
- Cards use HelveticaNeue to match rest of app. Selected card gets white border + slightly lighter background.

### Phase 24 — Debug Replay Onboarding
- Added `#if DEBUG` `debugSection` to `SettingsView.swift` with "replay onboarding" row.
- Tapping it: sets `hasCompletedOnboarding = false`, posts `Notification.Name.replayOnboarding`, dismisses settings.
- `ContentView.swift` wired to receive this notification with `.onReceive` → sets `showOnboarding = true`.
- `Notification.Name.replayOnboarding` extension added to `ContentView.swift`.

### Phase 25 — Haiku Prompt: LANGUAGE LEVEL + BALANCE RULE
Added two new blocks to the VOICE section of `haikuSystemPrompt` in `Constants.swift`:
- **LANGUAGE LEVEL** — "write like you're texting a smart friend, not briefing a board. no jargon. no formal sentence structures. short. real. the kind of thing someone screenshots and sends to their therapist."
- **BALANCE RULE** — "every verdict needs friction. if you're telling them to do it, name what they're giving up. if you're telling them not to, name what they're missing. a verdict with no tension isn't honest. it's just validation."
These are Haiku-specific. `secondPassSystemPrompt` and `anchoringRules` unchanged.

### Phase 26 — Pattern Card Insight Truncation Fix
In `StoriesView.swift`, the `pattern.identity.insight` text was truncating in constrained layouts.
- Added `.fixedSize(horizontal: false, vertical: true)` to allow vertical growth.
- Added `.multilineTextAlignment(.leading)` for consistent alignment.

### Phase 27 — resetBrainMemory + patternData Nil Fix
Two fixes in `AppViewModel.swift`:
1. `patternData` computed property setter was encoding `nil` as JSON `null` and re-writing the UserDefaults key even when clearing. Fixed to call `UserDefaults.standard.removeObject(forKey:)` on nil.
2. `resetBrainMemory()` was not clearing `patternData` in memory — it removed from UserDefaults but the in-memory computed property still returned stale cached value. Fixed by adding `patternData = nil` call (triggers the corrected setter).

### Phase 28 — shouldUseHaiku Debug Toggle Fix
`shouldUseHaiku` in `AppViewModel` had a bug: the DEBUG block only returned `true` for Haiku but fell through to `return true` unconditionally, so selecting SONNET in the debug bar still used Haiku model.
- Fixed by replacing `if forceHaikuMode { return true }` + fall-through with `return forceHaikuMode` — the toggle now directly controls the return value.

### Phase 29 — REASONING IS PURELY ABOUT TODAY Reframe (Haiku Only)
Replaced the old REASONING block in `haikuSystemPrompt` with a new framing: history is not just prohibited from reasoning — it is *invisible* to reasoning. The brain reads history for context, then closes it, then writes reasoning.
- Key additions: "Reasoning has no access to history. None. Not because the history doesn't exist — it does. But reasoning is the one field where history is completely invisible."
- Explicit "History has its place — historyInsight and patternNote. Those fields exist specifically so reasoning doesn't have to carry that weight."
- Only `haikuSystemPrompt` changed. `anchoringRules` (used for Sonnet) has its own REASONING block and was not touched.

### Phase 30 — History Isolation + Boundary Card + HistoryPanelView Reactivity
(completed in previous session, last push was `cd88e54`)

**History isolation:** `secondPass` no longer receives `thinkHistory`. All history work moved to `analyzePattern` (Call 3). `PatternData` now carries both `patternIdentity` and `historyInsight`. `historyInsight` story card now reads from `viewModel.patternData?.historyInsight` (not `result.report.historyInsight`).

**Boundary card back:** `CardBackView` detects boundary responses via `isBoundaryResponse` (`confidence == 0 && verdict contains "can't help" or "isn't something"`). Boundary back shows "this one's worth talking to someone about." with no buttons. `.frame(maxWidth: .infinity, maxHeight: .infinity)` added before `.background` to prevent card shape collapse.

**HistoryPanelView reactivity:** Was using `@State private var thinks` loaded once from UserDefaults — clear history had no effect. Replaced with `displayThinks` computed property reading `viewModel.thinkHistory.reversed()` directly. Clear now works instantly.

**BDRY debug button:** In HomeView's `#if DEBUG` block, sets `viewModel.appState = .result(DecisionResult.boundary)` for testing boundary card.

**`shouldUseHaiku` fix:** Was `#if DEBUG return forceHaikuMode #endif return true` — compiler treated the second return as unreachable in DEBUG builds. Fixed to `#if DEBUG return forceHaikuMode #else return true #endif`.

**Info.plist orientations:** Added all four `UISupportedInterfaceOrientations` to satisfy App Store validation.

**firstPassSystemPrompt life change clarification:** Added `CRITICAL` block distinguishing crisis signals (no future imagined) from life change signals (future imagined, even vaguely). "I want to quit everything" → simulate as DIRECTION.

**LANGUAGE LEVEL recalibration (Haiku only):** Replaced with "smart friend who thinks deeply, aim between medium and intermediate" framing. Includes wrong/right examples showing the target register.

### Phase 31 — Paywall Screen Safe Area Fix
(what was previously called Phase 30 in earlier drafts)
Onboarding screen 8 (`screenPaywall`) was starting with a fixed `Spacer().frame(height: 60)` inside a ZStack where `Color.ignoresSafeArea()` forces full-screen layout. On devices with tall safe areas (Dynamic Island = ~59pt), this left almost no breathing room.
- Fixed by wrapping the ScrollView in a `GeometryReader` and using `proxy.safeAreaInsets.top + 24` as the top spacer height.
- Adapts correctly to iPhone SE (no notch), standard notch, and Dynamic Island devices.

### Phase 32 — Sonnet Fallback for Haiku Format Failures

Added silent Sonnet fallback to both `firstPass` and `secondPass` in `APIClient.swift`.

**Trigger condition:** Only fires when `extractJSONDictionary` returns `nil` — meaning Haiku returned something with zero valid JSON anywhere (pure plain text, empty string, completely malformed). Does NOT trigger on: valid JSON with missing fields, valid JSON that fails Codable decode, network errors or timeouts.

**firstPass fallback:** Retries with `Constants.model` (Sonnet). System prompt stays as `firstPassSystemPrompt` — same prompt works for both models. Returns normally if Sonnet succeeds. Throws "Both Haiku and Sonnet returned non-JSON" only if both fail.

**secondPass fallback:** Retries with `Constants.model` AND swaps system prompt to `secondPassSystemPrompt + anchoringRules`. This swap is intentional — Sonnet needs its own prompt, not `haikuSystemPrompt`. `result.modelUsed` is stamped `Constants.model` on fallback → SONNET badge shows in debug.

**Debug flow for testing:**
- `forceCorrupt: Bool = false` parameter added to both `firstPass` and `secondPass`
- `AppViewModel.forceNextResponseCorrupt: @Published Bool = false` (DEBUG only)
- CORRUPT button in HomeView debug bar toggles this flag
- When ON, Haiku response is replaced with `"This is intentionally corrupted plain text..."` before JSON parsing → fallback fires → Sonnet runs → card shows with SONNET badge
- Auto-resets to `false` in `runSecondPass` after the think completes (success or error)
- `#if DEBUG` print warnings appear in console when fallback fires

**Badge behavior:** `DecisionCardView` already checks `result.modelUsed.contains("haiku")` — no change needed. Haiku path stamps `"claude-haiku-4-5-20251001"`, Sonnet fallback stamps `"claude-sonnet-4-20250514"`.

### Phase 34 — Onboarding Particle System (Built then Replaced)

Built a native Swift particle field system for the onboarding background:
- `BrainLaBomb/Particles/ParticleField.swift` — force-based particle engine (curl noise, SDF brain attraction, dual attractors, inward spiral). 3,000 particles, CADisplayLink at 60fps, linear drag integration.
- `BrainLaBomb/Particles/ParticleFieldView.swift` — SwiftUI Canvas renderer with perspective projection (cameraZ=260, fov=400) and depth-based alpha/size attenuation.
- `BrainLaBomb/Particles/FieldNoise.swift` — SeededRNG, trig-based smooth noise, curl noise, brain SDF and normals.
- `FieldState` enum maps each onboarding screen to a force configuration: dormant, expanding, signaling, conflict, compressing, forming, living, calming, fading.
- This system was fully built and working. **Superseded by the video system in Phase 35 but files remain in the project.**

### Phase 35 — Video-Based Onboarding System

Replaced the particle system with a pre-rendered MP4 video + JSON timeline approach. The goal: deterministic cinematic particle morphing (matching the WebGL prototype's quality) without the compute cost.

**Architecture:**
- `OnboardingVideoController` — `ObservableObject` holding one persistent `AVPlayer`. Parses `onboarding_timeline.json` on init. Two modes: `loopAlive(at:)` uses `addBoundaryTimeObserver` to seek back to `startMs` when playback hits `endMs`. `playNextTransition(onScreenAdvance:)` stops the loop, calls `onScreenAdvance()` immediately (UI changes now, video plays behind), plays the transition, then at `endMs` calls `loopAlive` for the next alive segment.
- `VideoPlayerView` — `UIViewRepresentable` wrapping `AVPlayerLayer` via `OnboardingPlayerHostView: UIView` with `layerClass = AVPlayerLayer.self`.
- `OnboardingView` — replaced `@StateObject var particles = ParticleField()` with `@StateObject var video = OnboardingVideoController()`. Video plays fullscreen behind all UI content. `.onAppear { video.start() }` kicks off the first alive loop.

**Key behaviour:**
- ONE `AVPlayer` instance for the entire onboarding session. Never recreated, never reloaded.
- Transitions: `onScreenAdvance` fires immediately on button tap → text cross-fades in → video transition plays behind new content.
- After the last JSON segment, `playNextTransition` falls through and calls `onScreenAdvance()` immediately (no video change, the screen just advances).
- All 6 main Next/continue buttons wired through `playNextTransition`. Auto-advances and paywall/done buttons use direct `currentScreen = N`.

**JSON structure (onboarding_timeline.json):**
```json
[
  { "type": "alive", "startMs": 0, "endMs": 10000, "shapeTitle": "..." },
  { "type": "transition", "startMs": 10000, "endMs": 14000, "shapeTitle": "..." },
  ...
]
```
13 segments total: 7 alive (each 10s) + 6 transitions (each 4s) = 94s total.

**Screen → video mapping:**
| Screen | Alive loop | Transition on Next |
|--------|-----------|-------------------|
| 0 | 0–10000ms | 10000–14000ms |
| 1 | 14000–24000ms | 24000–28000ms |
| 2 (consent) | 28000–38000ms | 38000–42000ms |
| 3 (quiz 1) | 42000–52000ms | 52000–56000ms |
| 4 (quiz 2) | 56000–66000ms | 66000–70000ms |
| 5 (quiz 3) | 70000–80000ms | 80000–84000ms |
| 6+ | 84000–94000ms | none (falls through) |

**Onboarding screen layout changes:**
- Screen 0: text left-aligned, anchored to lower portion (single top `Spacer()` pushes text down). Empty upper area for video.
- Screen 1: text left-aligned, top-anchored (`Spacer().frame(height: 24)` at top). Empty lower area.
- Screen 2 (consent): same top-anchor pattern.

**Text/copy updates:**
- Proper sentence capitalisation throughout screens 0 and 1.
- Screen 1 body: removed `\n\n` double line break, made single `\n` between "possible outcomes." and "Then handed back to you."
- Button: "that's different" → "That's different".

**Animation:**
- Screen transitions: `.easeOut(duration: 1.0).delay(0.1)` on the ZStack.
- Entry transition: `.asymmetric(insertion: .opacity.combined(with: .offset(y: 10)), removal: .opacity)` — text floats up 10pt while fading in, plain fade on exit.

**Debug overlay (`#if DEBUG`):**
- Screen nav pill: `‹ N / 12 ›` — bypasses video controller, directly sets `currentScreen`.
- BG toggle: "BG ON/OFF" pill — hides `VideoPlayerView` for pure black background testing. Turns yellow when off.
- Size readout: `WxH  T:top B:bottom` safe area insets in points.

**Bundle files added:**
- `BrainLaBomb/onboarding_master_timeline.mp4` — 266MB, 1290×2796 portrait, 94s
- `BrainLaBomb/onboarding_timeline.json` — 13-segment timeline

**Size note:** 266MB is too large for App Store. Before shipping: compress with H.265 (`ffmpeg -i input.mp4 -vcodec libx265 -crf 28 output.mp4`) or host remotely and download on first launch.

### Phase 36 — Bonus: Intro Video Generator

`/Users/andrewwilson/Downloads/generate_intro.py` — Python script that generates a 5-second 1920×1080 MP4 using Pillow + opencv. Animation: single "0" fades in → zooms to fill screen → dissolves into scattered BrainLaBomb-themed data (probability values, B/R/A/I/N letters, hex bytes, simulation counts) → data flood fills screen → fades to black. Output: `brainlabomb_intro.mp4`. Run with `python3 generate_intro.py`. Intended for launch screen / onboarding intro use.

### Phase 33 — Debug Defaults Changed

- `AppViewModel.debugTier` default: `.free` → `.pro` (resets each launch — not persisted)
- `AppViewModel.forceHaikuMode` default: `false` → `true` (resets each launch — not persisted)
- `Constants.useMockData` code default: `true` → `false`
- `HomeView` and `HistoryPanelView` `@AppStorage("debug_useMockData")` default: `true` → `false`
- Note: mock/live is UserDefaults-persisted. Existing installs keep their stored value. Toggle the MOCK button once in the debug bar to flip to LIVE if you've already launched before.

---

## Things That Were Tried But Reverted or Removed

- **3D thickness overlay during flip** — `CardThicknessOverlay.swift` was added, then the feature was entirely removed at user request. File may still exist.
- **Multiple home screen versions (v3, v4)** — tested different videos, settled on v1 and v5 (renamed to v1 and v2 in the final code with `home_bg.mp4` and `home_bg5.mp4`).
- **Floating hover animation on card** — card used to slowly float up and down after arriving. Removed. Now: arrives with spring, stays still.
- **Tilt + rotate arrival animation** — card was tilted as it arrived, then snapped to straight. Removed. Now arrives straight up.
- **Video background for card screen** — tested cosmos video behind the card. Removed in favor of float design (black + `float_bg` image).
- **Layout debug visible in production** — debug bar (layout A-E switcher) is `#if DEBUG` only. In release builds: random layout picked on load.
- **Verdict tightening instructions** — used to be appended to Haiku calls in `APIClient.swift` as `tighteningInstructions`. Removed when dedicated `haikuSystemPrompt` was added.
- **"Ran X simulations" text on back card** — removed.
- **Separate ambient question flow** — `needsAmbientQuestion` and `ambientQuestion` fields exist in the model and prompt but the UI flow for them was never fully built. They decode but nothing renders them.

---

## Known Issues / Not Yet Done

- **RevenueCat not integrated** — all tier checks in production fall back to `.free`. `canChat` and `isPaidTier` both return `false` in release. Has `// TODO: RevenueCat` comments everywhere.
- **`ambientQuestion` / `needsAmbientQuestion`** — fields exist in model and prompt, never wired into UI.
- **Haiku missing Sonnet's voice/five-layers** — see "What Sonnet Has That Haiku Is Missing" section above. Gaps identified, not yet added.
- **`DecisionEngine.swift` and `VideoPlaceholderView.swift`** — possibly unused/leftover. Verify before touching.
- **No actual in-app purchase flow** — paywall shows tiers but "unlock" button doesn't do anything yet.
- **Card from history sometimes shows smaller** — partially fixed, may still rarely occur.

---

## How to Build and Run

```
# Build via xcodegen
cd /Users/andrewwilson/my\ projects/brainlabomb
xcodegen generate
open BrainLaBomb.xcodeproj
# Select simulator (iPhone 16 Pro)
# Cmd+R to build and run
```

The API key lives in `BrainLaBomb/Secrets.swift` as:
```swift
enum Secrets {
    static let anthropicAPIKey = "sk-ant-..."
}
```
This file is in `.gitignore` and was NOT pushed.

---

## Where Key Values Live

| Thing | Location |
|-------|----------|
| API key | `Secrets.swift` → `Secrets.anthropicAPIKey` |
| Sonnet model ID | `Constants.model` = `"claude-sonnet-4-20250514"` |
| Haiku model ID | `"claude-haiku-4-5-20251001"` (hardcoded in `APIClient.firstPass` and `APIClient.secondPass`) |
| Free think limit | `Constants.maxFreeThinks` = 5 |
| Core think limit | `AppViewModel.coreThinkLimit` = 500 |
| Core Sonnet limit | `AppViewModel.coreSonnetLimit` = 350 |
| Pro monthly Sonnet limit | `AppViewModel.shouldUseHaiku` → 200 |
| Think history key | `Constants.thinkHistoryKey` = `"thinkHistory"` |
| Thinks used key | `Constants.thinksUsedKey` = `"thinksUsed"` |
| Mock data toggle | `@AppStorage("debug_useMockData")` |
| Home video 1 | `home_bg.mp4` in bundle |
| Home video 2 | `home_bg5.mp4` in bundle (was `1777736409349093.MP4`) |
| Card float background | `float_bg` image in Assets |
| Paywall video | `paywall_bg.mov` in bundle |
| Onboarding flag | `UserDefaults "hasCompletedOnboarding"` |
| Onboarding video | `onboarding_master_timeline.mp4` in bundle (266MB, 1290×2796, 94s) |
| Onboarding timeline | `onboarding_timeline.json` in bundle (13 segments) |
| Intro generator script | `/Users/andrewwilson/Downloads/generate_intro.py` |

---

## Key Architecture Notes

- `AppViewModel` is an `ObservableObject` passed down through all views as `@ObservedObject`. It owns the state machine.
- `DecisionResult` has a **flat JSON decoder** — the API returns all fields at root level but Swift model wraps some into `DecisionReport`. The encoder/decoder handle the mapping.
- `reasoning` in `DecisionReport` is `[String]` even though the API returns a single string — it's wrapped in `[reasoningStr]` on decode. StoriesView uses `.joined(separator: " ")` to display it.
- Chat messages are stored in `Think.chatMessages: [ChatBubble]` and persisted in the think history array.
- Pattern analysis runs automatically every 5th think (`thinkHistory.count % 5 == 0`). No UI indication when it runs.
- The `historyInsight` story card only renders if `viewModel.patternData?.historyInsight` is non-empty (checked in `shouldShowHistoryCard`), making `totalCards` either 5 or 6. In DEBUG, `debugForceDoubleHistory` can force it to show.
- `firstPass` and `secondPass` both have a silent Sonnet fallback — fires only when `extractJSONDictionary` returns nil. `secondPass` fallback also swaps the system prompt from `haikuSystemPrompt` to `secondPassSystemPrompt + anchoringRules`.

---

## Next Steps (What Was Being Worked On)

The session ended after Phase 36 (onboarding video system + intro generator). Changes are NOT yet pushed — do not push until explicitly told.

The natural next actions are:

**Onboarding video:**
1. Compress `onboarding_master_timeline.mp4` before shipping — 266MB is too large. Use H.265: `ffmpeg -i onboarding_master_timeline.mp4 -vcodec libx265 -crf 28 -preset medium onboarding_compressed.mp4`. Target <60MB. OR host remotely and stream on first launch.
2. Polish onboarding screen layouts for screens 3–11 now that the video system is wired.
3. Map more onboarding screens to video segments as the video timeline grows.

**Core app:**
4. Wire RevenueCat for real tier enforcement — paywall "start trial" / "get Core" buttons currently just advance to screen 11 with `TODO: RevenueCat` comments.
5. Build the actual purchase flow in PaywallView (standalone paywall, not just onboarding).
6. Decide whether to port remaining Sonnet voice sections into Haiku (see "What Sonnet Has That Haiku Is Missing" above).
7. Fix `mode` field decode to be case-insensitive (risk: "Emotional" vs "EMOTIONAL" crashes decode) — `DecisionMode` already handles this via custom `init(from:)` but verify in practice.
8. Fix `resetBrainMemory()` / `clearAllData()` to also clear `monthlyThinkCount` and `lastMonthlyReset`.
9. Add backend proxy for API key before App Store submission.
10. Test Sonnet fallback end-to-end: use CORRUPT button, verify SONNET badge appears, verify CORRUPT auto-resets.
