# Capgrid

Capgrid is a sideline box score for a youth basketball parent or bench volunteer. You tag the jersey you are watching, then stamp the stat. The phone keeps the live team totals.

## Architecture

A sheet is a pure fold over an ordered log of marks, and the pin rail is the ADT `Phase = .open | .tagged(Jersey)`.

That split matches the real sideline mistake: stamping a rebound before anyone has said which jersey it belongs to. The fold refuses that stamp. Tag writes a `TagMark` and moves Open to Tagged. Cap on Tagged writes a `CapMark` with a `StatKind` on that jersey and moves Tagged back to Open, so the next stat needs a deliberate tag. Cap on Open writes a `BareMark`, adds no `CapMark`, and leaves the totals alone. Tag while Tagged rewrites the open `TagMark` instead of stacking two seats. Peel appends a `PeelMark` that drops the last `CapMark` only while the sheet is live. Seal appends a `SealMark` and freezes the caps for export. Home points, away points, and each jersey line are `TeamTotals.fold` over the remaining `CapMark`s. They are never stored. A fixture with an empty roster is `Blank`, not an empty sheet.

`SheetStore` is the only state the UI will read. It keeps the archive in memory and asks `SheetVault` to project it. The vault writes one JSON document (`schemaVersion` 1) atomically under Application Support, keeps the previous good file as `.backup`, and mirrors the same bytes in UserDefaults under `cgr.archive.v1`. Saves wait about 400ms, and the app flushes when the scene goes inactive or background.

## Tag, then cap

The home verb is stamp-the-cap. On the Simulator the `cgr.demo.v1` seed writes Eastside Owls vs Northgate with 14 caps across jerseys 4, 11, and 23, then seats jersey 23. The first frame is already Tagged, so the first tap can stamp a cap. After that stamp the rail returns to Open and the next cap is refused until you tag again. Peel takes back the last cap. Seal stops the log so a mistaken tap cannot change the box score you export.

## Art

Watercolor illustration, documentary. Loose wet-on-wet washes, paper grain, soft bleeding edges, quiet courtside framing. Parents on bleachers, a volunteer with a phone, kids mid-play. No text and no logos. Each image set is a cutout (solid subject, transparent corners):

- `cgr_Onboarding1` — what the app is for
- `cgr_Onboarding2` — the primary action, mid-gesture
- `cgr_Onboarding3` — a later moment when the sheet has accumulated meaning
- `cgr_EmptyHome` — a solid closed bowl, crate, or folded cloth waiting to be used
- `cgr_TwistHero` — an emblem of tag-then-cap
- `cgr_EmptyMatches` — a folded team scoresheet and a basketball on a gym bench
- `cgr_SealedBox` — a clipboard holding a finished box score with a pencil across it

The shared base prompt is the documentary watercolor sideline paragraph in SPEC.md section 13.

## How this differs

Pitchtape logs clock-synchronized calls on a running tape. Stintbell banks fair minutes with enter and exit. Chalkthread chains possession on pegs without a box score. Capgrid tags one jersey, then stamps discrete stat caps on a grid, and exports the folded box score. The persisted verb is stamp-the-cap.

## Build

```bash
xcodegen generate
xcodebuild build-for-testing -scheme Capgrid -destination 'generic/platform=iOS Simulator' -jobs 4 CODE_SIGNING_ALLOWED=NO CODE_SIGNING_REQUIRED=NO SWIFT_TREAT_WARNINGS_AS_ERRORS=YES
xcodebuild test-without-building -scheme Capgrid -destination 'platform=iOS Simulator,id=<UDID>' -jobs 4
```

No packages. SwiftUI, Foundation, and later UIKit for the PDF renderer. No camera and no network catalog.
