BrainLaBomb — Design System Document
  
  ---
  COLORS
  
  Background Colors

  ┌────────────────────┬────────────────────────────────────────┬──────────────────┬───────────────────────────────────────────────────────────┐
  │        Role        │                 Value                  │  CSS Equivalent  │                          Used In                          │
  ├────────────────────┼────────────────────────────────────────┼──────────────────┼───────────────────────────────────────────────────────────┤
  │ Primary background │ Color.black                            │ #000000          │ ContentView, DecisionCardView, StoriesView, CardBackView, │
  │                    │                                        │                  │  HomeView                                                 │
  ├────────────────────┼────────────────────────────────────────┼──────────────────┼───────────────────────────────────────────────────────────┤
  │ Secondary          │ Color(hex: "#0A0A0A")                  │ #0A0A0A          │ SettingsView, OnboardingView                              │
  │ background         │                                        │                  │                                                           │
  ├────────────────────┼────────────────────────────────────────┼──────────────────┼───────────────────────────────────────────────────────────┤
  │ Near-black surface │ Color(red: 0.039, green: 0.039, blue:  │ #0A0A0A          │ CardBackView "chat about this" button                     │
  │                    │ 0.039)                                 │                  │                                                           │
  ├────────────────────┼────────────────────────────────────────┼──────────────────┼───────────────────────────────────────────────────────────┤
  │ Elevated surface 1 │ Color(white: 0.05)                     │ #0D0D0D          │ Plan card unselected background                           │
  ├────────────────────┼────────────────────────────────────────┼──────────────────┼───────────────────────────────────────────────────────────┤
  │ Elevated surface 2 │ Color(white: 0.08)                     │ #141414          │ Plan card selected background, quiz pill unselected       │
  ├────────────────────┼────────────────────────────────────────┼──────────────────┼───────────────────────────────────────────────────────────┤
  │ Elevated surface 3 │ Color(white: 0.12)                     │ #1F1F1F          │ Debug capsule backgrounds, subtle dividers, progress      │
  │                    │                                        │                  │ track (onboarding)                                        │
  ├────────────────────┼────────────────────────────────────────┼──────────────────┼───────────────────────────────────────────────────────────┤
  │ Elevated surface 4 │ Color(white: 0.14)                     │ #242424          │ Stories debug circle buttons                              │
  ├────────────────────┼────────────────────────────────────────┼──────────────────┼───────────────────────────────────────────────────────────┤
  │ Elevated surface 5 │ Color(white: 0.16)                     │ #292929          │ Tooltip background                                        │
  ├────────────────────┼────────────────────────────────────────┼──────────────────┼───────────────────────────────────────────────────────────┤
  │ Elevated surface 6 │ Color(white: 0.18)                     │ #2E2E2E          │ Debug bar (DecisionCardView), separator rules in Stories  │
  ├────────────────────┼────────────────────────────────────────┼──────────────────┼───────────────────────────────────────────────────────────┤
  │ Elevated surface 7 │ Color(white: 0.22)                     │ #383838          │ Story progress bar track                                  │
  ├────────────────────┼────────────────────────────────────────┼──────────────────┼───────────────────────────────────────────────────────────┤
  │ Elevated surface 8 │ Color(white: 0.28)                     │ #474747          │ Debug button active state                                 │
  ├────────────────────┼────────────────────────────────────────┼──────────────────┼───────────────────────────────────────────────────────────┤
  │ Paywall video      │ Color.black.opacity(0.72)              │ rgba(0,0,0,0.72) │ PaywallView video background dim                          │
  │ overlay            │                                        │                  │                                                           │
  └────────────────────┴────────────────────────────────────────┴──────────────────┴───────────────────────────────────────────────────────────┘
  
  Text Colors

  ┌─────────────────────┬─────────────────────────────────────┬────────────────────────┬───────────────────────────────────────────────────────┐
  │        Role         │                Value                │     CSS Equivalent     │                        Used In                        │
  ├─────────────────────┼─────────────────────────────────────┼────────────────────────┼───────────────────────────────────────────────────────┤
  │ Primary text        │ Color.white                         │ #FFFFFF                │ Headlines, body, CTAs                                 │
  ├─────────────────────┼─────────────────────────────────────┼────────────────────────┼───────────────────────────────────────────────────────┤
  │ Secondary text      │ Color.white.opacity(0.5)            │ rgba(255,255,255,0.5)  │ Onboarding supporting copy                            │
  ├─────────────────────┼─────────────────────────────────────┼────────────────────────┼───────────────────────────────────────────────────────┤
  │ Icon buttons        │ Color.white.opacity(0.7)            │ rgba(255,255,255,0.7)  │ HomeView history/settings icons                       │
  ├─────────────────────┼─────────────────────────────────────┼────────────────────────┼───────────────────────────────────────────────────────┤
  │ Metadata captions   │ Color.white.opacity(0.3)            │ rgba(255,255,255,0.3)  │ DecisionCardView "RESULTS AFTER SIMULATING..."        │
  ├─────────────────────┼─────────────────────────────────────┼────────────────────────┼───────────────────────────────────────────────────────┤
  │ Card border stroke  │ Color.white.opacity(0.35)           │ rgba(255,255,255,0.35) │ Decision card border (both sides)                     │
  ├─────────────────────┼─────────────────────────────────────┼────────────────────────┼───────────────────────────────────────────────────────┤
  │ Dim captions        │ Color(white: 0.25)                  │ #404040                │ HomeView "what's your situation?"                     │
  ├─────────────────────┼─────────────────────────────────────┼────────────────────────┼───────────────────────────────────────────────────────┤
  │ Muted labels        │ Color(white: 0.3)                   │ #4D4D4D                │ Settings section headers, fine print, paywall links   │
  ├─────────────────────┼─────────────────────────────────────┼────────────────────────┼───────────────────────────────────────────────────────┤
  │ Pattern insight     │ Color(white: 0.35)                  │ #595959                │ Pattern identity insight (italic)                     │
  ├─────────────────────┼─────────────────────────────────────┼────────────────────────┼───────────────────────────────────────────────────────┤
  │ Archetype           │ Color(white: 0.38)                  │ #616161                │ Archetype description in archetypeCard                │
  │ description         │                                     │                        │                                                       │
  ├─────────────────────┼─────────────────────────────────────┼────────────────────────┼───────────────────────────────────────────────────────┤
  │ Secondary values    │ Color(white: 0.4)                   │ #666666                │ Settings values, plan card subtitle/detail,           │
  │                     │                                     │                        │ StoriesView captions                                  │
  ├─────────────────────┼─────────────────────────────────────┼────────────────────────┼───────────────────────────────────────────────────────┤
  │ Outcome labels      │ Color(white: 0.42)                  │ #6B6B6B                │ Outcome row title and explanation                     │
  ├─────────────────────┼─────────────────────────────────────┼────────────────────────┼───────────────────────────────────────────────────────┤
  │ Navigation / close  │ Color(white: 0.45)                  │ #737373                │ Back chevron, lock icon, background image tint        │
  ├─────────────────────┼─────────────────────────────────────┼────────────────────────┼───────────────────────────────────────────────────────┤
  │ Why/Trade offs      │ Color(white: 0.5)                   │ #808080                │ CardBackView bullet points, lock icon                 │
  │ bullets             │                                     │                        │                                                       │
  ├─────────────────────┼─────────────────────────────────────┼────────────────────────┼───────────────────────────────────────────────────────┤
  │ Card section labels │ Color(white: 0.55)                  │ #8C8C8C                │ StoriesView cardHeading labels                        │
  ├─────────────────────┼─────────────────────────────────────┼────────────────────────┼───────────────────────────────────────────────────────┤
  │ Settings row values │ Color(white: 0.6)                   │ #999999                │ Settings row value text                               │
  ├─────────────────────┼─────────────────────────────────────┼────────────────────────┼───────────────────────────────────────────────────────┤
  │ SimpleRow text      │ Color(white: 0.65)                  │ #A6A6A6                │ StoriesView simpleRow                                 │
  ├─────────────────────┼─────────────────────────────────────┼────────────────────────┼───────────────────────────────────────────────────────┤
  │ Tooltip text        │ Color(white: 0.72)                  │ #B8B8B8                │ StoriesView tooltip                                   │
  ├─────────────────────┼─────────────────────────────────────┼────────────────────────┼───────────────────────────────────────────────────────┤
  │ Destructive         │ Color(red: 0.8, green: 0.2, blue:   │ #CC3333                │ "clear think history" (Settings danger zone)          │
  │                     │ 0.2)                                │                        │                                                       │
  └─────────────────────┴─────────────────────────────────────┴────────────────────────┴───────────────────────────────────────────────────────┘

  Dividers

  ┌─────────────────────────────┬────────────────────┬────────────────┐
  │            Role             │       Value        │ CSS Equivalent │
  ├─────────────────────────────┼────────────────────┼────────────────┤
  │ Primary divider             │ Color(white: 0.1)  │ #1A1A1A        │
  ├─────────────────────────────┼────────────────────┼────────────────┤
  │ Secondary divider           │ Color(white: 0.12) │ #1F1F1F        │
  ├─────────────────────────────┼────────────────────┼────────────────┤
  │ Subtle rule                 │ Color(white: 0.18) │ #2E2E2E        │
  ├─────────────────────────────┼────────────────────┼────────────────┤
  │ OnboardingView section rule │ Color(white: 0.07) │ #121212        │
  ├─────────────────────────────┼────────────────────┼────────────────┤
  │ Dot separator (fine print)  │ Color(white: 0.15) │ #262626        │
  └─────────────────────────────┴────────────────────┴────────────────┘
  
  Pattern Progress Bar
  
  ┌──────────────────┬──────────────────────────────┐
  │      State       │            Value             │
  ├──────────────────┼──────────────────────────────┤
  │ Filled segment   │ Color.white                  │
  ├──────────────────┼──────────────────────────────┤
  │ Unfilled segment │ Color(white: 0.15) / #262626 │
  └──────────────────┴──────────────────────────────┘

  ---
  TYPOGRAPHY

  Custom Fonts

  Two custom fonts are used. All UI defaults to HelveticaNeue. Poppins appears exclusively on the decision card back.

  ---
  HelveticaNeue — Primary Font

  ┌──────┬─────────────────────────────────────────────────────────────────────────────────────────────────────────────────┐
  │ Size │                                                      Usage                                                      │
  ├──────┼─────────────────────────────────────────────────────────────────────────────────────────────────────────────────┤
  │ 48pt │ Home headline ("Every choice is a simulation."), lineSpacing 4                                                  │
  ├──────┼─────────────────────────────────────────────────────────────────────────────────────────────────────────────────┤
  │ 42pt │ PaywallView headline ("your brain. / fully awake.")                                                             │
  ├──────┼─────────────────────────────────────────────────────────────────────────────────────────────────────────────────┤
  │ 38pt │ Pattern identity name (StoriesView), blurred archetype name                                                     │
  ├──────┼─────────────────────────────────────────────────────────────────────────────────────────────────────────────────┤
  │ 34pt │ TrialStartSheet title                                                                                           │
  ├──────┼─────────────────────────────────────────────────────────────────────────────────────────────────────────────────┤
  │ 32pt │ Settings header, onboarding paywall heading                                                                     │
  ├──────┼─────────────────────────────────────────────────────────────────────────────────────────────────────────────────┤
  │ 28pt │ "RECOMMENDATION" (DecisionCardView), archetype name (archetypeCard), story card subheadings                     │
  ├──────┼─────────────────────────────────────────────────────────────────────────────────────────────────────────────────┤
  │ 22pt │ Reasoning text (StoriesView card1/card1b), historyInsight text, lineSpacing 6/8                                 │
  ├──────┼─────────────────────────────────────────────────────────────────────────────────────────────────────────────────┤
  │ 18pt │ Archetype description (archetypeCard), boundary card message (CardBackView)                                     │
  ├──────┼─────────────────────────────────────────────────────────────────────────────────────────────────────────────────┤
  │ 17pt │ "Think" button (HomeView), PaywallView CTA, settings unlock button                                              │
  ├──────┼─────────────────────────────────────────────────────────────────────────────────────────────────────────────────┤
  │ 16pt │ StoriesView version2 simulate text                                                                              │
  ├──────┼─────────────────────────────────────────────────────────────────────────────────────────────────────────────────┤
  │ 15pt │ Settings row labels, PaywallView plan card title, PaywallView feature rows, chat/paywall buttons in StoriesView │
  ├──────┼─────────────────────────────────────────────────────────────────────────────────────────────────────────────────┤
  │ 14pt │ "Here's what those looked like" (StoriesView), StoriesView minority explanation                                 │
  ├──────┼─────────────────────────────────────────────────────────────────────────────────────────────────────────────────┤
  │ 13pt │ Outcome row explanations, pattern section descriptions, paywall plan subtitle/detail                            │
  ├──────┼─────────────────────────────────────────────────────────────────────────────────────────────────────────────────┤
  │ 12pt │ Pattern "your archetype" / "of thinkers share this" labels, paywall link text (restore/terms/privacy)           │
  ├──────┼─────────────────────────────────────────────────────────────────────────────────────────────────────────────────┤
  │ 11pt │ Paywall fine print ("3 days free, then $99.99/year...")                                                         │
  ├──────┼─────────────────────────────────────────────────────────────────────────────────────────────────────────────────┤
  │ 13pt │ cardHeading (StoriesView) — uppercased                                                                          │
  └──────┴─────────────────────────────────────────────────────────────────────────────────────────────────────────────────┘
  
  ---
  Poppins-Regular — Card Back Only

  ┌──────┬───────────────────────────────────────────────────────────────┐
  │ Size │                             Usage                             │
  ├──────┼───────────────────────────────────────────────────────────────┤
  │ 24pt │ "Why" and "Trade offs" section headers (CardBackView)         │
  ├──────┼───────────────────────────────────────────────────────────────┤
  │ 20pt │ Boundary card message (CardBackView)                          │
  ├──────┼───────────────────────────────────────────────────────────────┤
  │ 18pt │ Full verdict text when truncated (CardBackView)               │
  ├──────┼───────────────────────────────────────────────────────────────┤
  │ 15pt │ "chat about this" / "view full report" buttons (CardBackView) │
  ├──────┼───────────────────────────────────────────────────────────────┤
  │ 14pt │ Why and Trade offs bullet point text (CardBackView)           │
  └──────┴───────────────────────────────────────────────────────────────┘

  ---
  System Font (SF Pro) — Utility & Onboarding

  ┌───────────────────────┬──────────────────────────────────────────────────────────────┐
  │     Size / Weight     │                            Usage                             │
  ├───────────────────────┼──────────────────────────────────────────────────────────────┤
  │ 32pt bold             │ Onboarding screen headlines                                  │
  ├───────────────────────┼──────────────────────────────────────────────────────────────┤
  │ 28pt bold             │ Quiz question headlines, notifications screen                │
  ├───────────────────────┼──────────────────────────────────────────────────────────────┤
  │ 24pt bold             │ "How it works" block titles                                  │
  ├───────────────────────┼──────────────────────────────────────────────────────────────┤
  │ 22pt light            │ Onboarding supporting copy, "trained for the way you think." │
  ├───────────────────────┼──────────────────────────────────────────────────────────────┤
  │ 17pt bold             │ Onboarding primary CTA buttons                               │
  ├───────────────────────┼──────────────────────────────────────────────────────────────┤
  │ 17pt regular          │ "not yet" secondary button                                   │
  ├───────────────────────┼──────────────────────────────────────────────────────────────┤
  │ 16pt regular          │ Quiz pill options                                            │
  ├───────────────────────┼──────────────────────────────────────────────────────────────┤
  │ 16pt light            │ "How it works" body text                                     │
  ├───────────────────────┼──────────────────────────────────────────────────────────────┤
  │ 15pt medium           │ Settings "done" button                                       │
  ├───────────────────────┼──────────────────────────────────────────────────────────────┤
  │ 15pt regular          │ Settings toggle label, notification row                      │
  ├───────────────────────┼──────────────────────────────────────────────────────────────┤
  │ 14pt regular          │ Quiz counter "01 of 03", plan card price                     │
  ├───────────────────────┼──────────────────────────────────────────────────────────────┤
  │ 13pt regular          │ Disclaimer text, settings disclaimers, trial timeline text   │
  ├───────────────────────┼──────────────────────────────────────────────────────────────┤
  │ 12pt regular          │ "once a week. never spam.", feedback sub-caption             │
  ├───────────────────────┼──────────────────────────────────────────────────────────────┤
  │ 11pt medium           │ Settings section headers (tracking 1.5), Stories info button │
  ├───────────────────────┼──────────────────────────────────────────────────────────────┤
  │ 10pt bold             │ "3 DAYS FREE" plan badge                                     │
  ├───────────────────────┼──────────────────────────────────────────────────────────────┤
  │ 9pt medium monospaced │ Debug model/tier badge on card                               │
  └───────────────────────┴──────────────────────────────────────────────────────────────┘
  
  Monospaced (design: .monospaced)
  
  ┌─────────────┬─────────────────────────────────────────────────────────────────────────────────┐
  │    Size     │                                      Usage                                      │
  ├─────────────┼─────────────────────────────────────────────────────────────────────────────────┤
  │ 11pt medium │ HomeView debug bar buttons (MOCK/LIVE/HAIKU/SONNET), Stories HAIKU/SONNET badge │
  ├─────────────┼─────────────────────────────────────────────────────────────────────────────────┤
  │ 10pt medium │ "what's your situation?" HomeView caption, tracking 2                           │
  └─────────────┴─────────────────────────────────────────────────────────────────────────────────┘

  ---
  Letter Tracking
  
  ┌───────────────┬──────────────────────────────────────────────────────┐
  │     Value     │                       Used In                        │
  ├───────────────┼──────────────────────────────────────────────────────┤
  │ tracking(2)   │ "what's your situation?" caption                     │
  ├───────────────┼──────────────────────────────────────────────────────┤
  │ tracking(1.5) │ Settings section headers, error view label           │
  ├───────────────┼──────────────────────────────────────────────────────┤
  │ tracking(1)   │ DecisionCardView "RESULTS AFTER SIMULATING..." label │
  └───────────────┴──────────────────────────────────────────────────────┘

  ---
  BUTTON STYLES

  Primary Button — Filled White

  background:       #FFFFFF
  text:             #000000
  font:             HelveticaNeue 17pt (most views) / SF Pro 17pt bold (Onboarding)
  padding vertical: 18pt (HomeView, PaywallView) / 16pt (Onboarding, Settings-unlock)
  corner radius:    14pt (HomeView, PaywallView) / 16pt (Onboarding) / 10pt (Settings unlock)
  width:            full width (maxWidth: .infinity)

  Used for: "Think" (Home), "start my 3-day free trial" (Paywall), "I'm ready" / "continue" / "let's go" (Onboarding), "unlock unlimited thinks"
  (Settings), "new think" (StoriesView), "view full report" (CardBackView).

  ---
  Secondary Button — Outlined

  background:       transparent 
  text:             #FFFFFF
  border:           #FFFFFF, 1pt stroke
  font:             SF Pro 17pt regular
  padding vertical: 16pt
  corner radius:    16pt 
  width:            full width

  Used for: "not yet" (Onboarding notifications), "continue for free" (Onboarding paywall).
  
  ---
  Tertiary Button — Dark Capsule (Chat/Locked)

  background:       #0A0A0A  (Color red: 0.039...)
  text (active):    #FFFFFF
  text (locked):    Color(white: 0.4) / #666666
  border (active):  #FFFFFF, 1pt
  border (locked):  Color(white: 0.25) / #404040, 1pt
  font:             Poppins-Regular 15pt
  shape:            Capsule
  padding:          horizontal 22pt, vertical 16pt

  Used for: "chat about this" (CardBackView).
  
  ---
  Inline Lock CTA — Capsule

  background:  #FFFFFF
  text:        #000000
  font:        SF Pro 14pt bold
  shape:       Capsule
  padding:     horizontal 24–28pt, vertical 10–12pt

  Used for: "unlock pro →" (StoriesView paywall gate, pattern lock overlay).

  ---
  Plan Card — Selectable

  selected:   background Color(white: 0.08) / #141414, border #FFFFFF 1pt
  unselected: background Color(white: 0.05) / #0D0D0D, border Color(white: 0.12) 1pt
  corner radius: 12pt
  padding:    16pt all sides

  ---
  Quiz Pill — Selectable

  selected:   background #FFFFFF, text #000000
  unselected: background Color(white: 0.08) / #141414, text #FFFFFF
  font:       SF Pro 16pt regular
  corner radius: 12pt
  padding:    vertical 14pt, horizontal 20pt

  ---
  CARD STYLES

  Decision Card (Front & Back)

  corner radius:  10pt
  border:         Color.white.opacity(0.35), lineWidth: 0.5
  shadow:         Color.white.opacity(0.06), radius: 24, offset: 0,0
  aspect ratio:   0.68 (width:height)
  card back bg:   Color.black

  Tooltip   

  background:     Color(white: 0.16) / #292929
  corner radius:  10pt
  padding:        13pt all sides
  text color:     Color(white: 0.72) / #B8B8B8
  font:           HelveticaNeue 12pt

  Settings Row

  horizontal padding: 24pt
  vertical padding:   14pt
  divider:            Color(white: 0.1) / #1A1A1A, height 1pt, horizontal inset 24pt

  ---
  SPACING AND LAYOUT

  Horizontal Padding

  ┌───────┬─────────────────────────────────────────────────────────────────────────────┐
  │ Value │                                   Context                                   │
  ├───────┼─────────────────────────────────────────────────────────────────────────────┤
  │ 28pt  │ Primary content (HomeView body, StoriesView cards, DecisionCardView labels) │
  ├───────┼─────────────────────────────────────────────────────────────────────────────┤
  │ 24pt  │ PaywallView, SettingsView, Onboarding                                       │
  ├───────┼─────────────────────────────────────────────────────────────────────────────┤
  │ 22pt  │ CardBackView buttons                                                        │
  ├───────┼─────────────────────────────────────────────────────────────────────────────┤
  │ 18pt  │ CardBackView content (Why/Tradeoffs), Stories progress bar                  │
  ├───────┼─────────────────────────────────────────────────────────────────────────────┤
  │ 16pt  │ HomeView top navigation bar                                                 │
  └───────┴─────────────────────────────────────────────────────────────────────────────┘
  
  Vertical Spacing

  ┌───────┬───────────────────────────────────────────────────────────────────────────┐
  │ Value │                                  Context                                  │
  ├───────┼───────────────────────────────────────────────────────────────────────────┤
  │ 72pt  │ StoriesView card heading top padding (accounts for progress bar + chrome) │
  ├───────┼───────────────────────────────────────────────────────────────────────────┤
  │ 56pt  │ HomeView "Think" button bottom padding                                    │
  ├───────┼───────────────────────────────────────────────────────────────────────────┤
  │ 52pt  │ Onboarding button bottom padding                                          │
  ├───────┼───────────────────────────────────────────────────────────────────────────┤
  │ 36pt  │ StoriesView bottom button row                                             │
  ├───────┼───────────────────────────────────────────────────────────────────────────┤
  │ 28pt  │ Standard between-section gap                                              │
  ├───────┼───────────────────────────────────────────────────────────────────────────┤
  │ 26pt  │ Between outcome rows                                                      │
  ├───────┼───────────────────────────────────────────────────────────────────────────┤
  │ 24pt  │ Section header top padding (Settings), between plan cards                 │
  ├───────┼───────────────────────────────────────────────────────────────────────────┤
  │ 20pt  │ CardBackView button bottom padding                                        │
  ├───────┼───────────────────────────────────────────────────────────────────────────┤
  │ 16pt  │ Paywall feature row vertical padding, settings header bottom padding      │
  ├───────┼───────────────────────────────────────────────────────────────────────────┤
  │ 14pt  │ Settings row vertical padding                                             │
  ├───────┼───────────────────────────────────────────────────────────────────────────┤
  │ 12pt  │ Between plan cards, between buttons                                       │
  ├───────┼───────────────────────────────────────────────────────────────────────────┤
  │ 10pt  │ Between quiz pills, between plan card fields                              │
  └───────┴───────────────────────────────────────────────────────────────────────────┘
  
  ---
  MOTION AND ANIMATION
  
  ┌───────────────────────────────┬────────────────────────────────────────────────┬───────────────┐
  │            Element            │                   Animation                    │   Duration    │
  ├───────────────────────────────┼────────────────────────────────────────────────┼───────────────┤
  │ App state transitions         │ .easeInOut                                     │ 0.35s         │
  ├───────────────────────────────┼────────────────────────────────────────────────┼───────────────┤
  │ Onboarding screen changes     │ .easeInOut                                     │ 0.4s          │
  ├───────────────────────────────┼────────────────────────────────────────────────┼───────────────┤
  │ Stories card transitions      │ .easeInOut                                     │ 0.2s          │
  ├───────────────────────────────┼────────────────────────────────────────────────┼───────────────┤
  │ Stories last-card button fade │ .easeInOut                                     │ 0.25s         │
  ├───────────────────────────────┼────────────────────────────────────────────────┼───────────────┤
  │ Card arrival (spring up)      │ .spring(response: 1.0, dampingFraction: 0.85)  │ —             │
  ├───────────────────────────────┼────────────────────────────────────────────────┼───────────────┤
  │ Card flip (tap)               │ .easeInOut                                     │ 0.44s         │
  ├───────────────────────────────┼────────────────────────────────────────────────┼───────────────┤
  │ Card snap after drag          │ .spring(response: 0.38, dampingFraction: 0.68) │ —             │
  ├───────────────────────────────┼────────────────────────────────────────────────┼───────────────┤
  │ Gyroscope tilt                │ .easeOut                                       │ 0.1s          │
  ├───────────────────────────────┼────────────────────────────────────────────────┼───────────────┤
  │ History panel open            │ .spring(response: 0.35, dampingFraction: 0.85) │ —             │
  ├───────────────────────────────┼────────────────────────────────────────────────┼───────────────┤
  │ History panel swipe dismiss   │ .spring(response: 0.28, dampingFraction: 0.9)  │ —             │
  ├───────────────────────────────┼────────────────────────────────────────────────┼───────────────┤
  │ Paywall swipe dismiss         │ .easeOut                                       │ 0.2s          │
  ├───────────────────────────────┼────────────────────────────────────────────────┼───────────────┤
  │ Paywall snap-back             │ .spring(response: 0.35, dampingFraction: 0.85) │ —             │
  ├───────────────────────────────┼────────────────────────────────────────────────┼───────────────┤
  │ Processing dots               │ .easeInOut per dot, timer interval 0.35s       │ 0.3s          │
  ├───────────────────────────────┼────────────────────────────────────────────────┼───────────────┤
  │ Onboarding progress fill      │ .linear                                        │ 2.0s          │
  ├───────────────────────────────┼────────────────────────────────────────────────┼───────────────┤
  │ Story auto-advance            │ 30fps timer                                    │ 7.0s per card │
  └───────────────────────────────┴────────────────────────────────────────────────┴───────────────┘
  
  ---
  DESIGN LANGUAGE SUMMARY
  
  BrainLaBomb is pure black. The entire chromatic range of the UI is black-to-white — no hues, no gradients, no tints. White is used in one mode
  only: full white for primary CTAs and active states, and cascading white opacities (0.7 → 0.5 → 0.4 → 0.3 → 0.25...) for every tier of text
  hierarchy. The result is a monolithic, editorial aesthetic — it reads like a newspaper printed at night with a single ink.

  HelveticaNeue is the brand typeface — its uncompromising Swiss rationalism runs through every headline, label, and button in the app, giving it a
   deliberate, no-nonsense voice that matches the product's tone ("simulate before you decide"). Poppins appears only on the card back as a subtle
  contrast, softening that one surface to feel more conversational.

  Interaction is physical: the decision card tilts with the gyroscope, flips in 3D on drag or tap, and springs onto screen from below. Gestures —
  swipe-to-dismiss, hold-to-pause in Stories — make the app feel tactile rather than tapped. The overall experience signals intelligence and
  restraint rather than delight and color.

  ---
  No ColorExtensions.swift found in the project. The Color(hex:) initializer used throughout the app is defined as an extension elsewhere in the 
  project. Only one hex value is used in production UI: #0A0A0A.
