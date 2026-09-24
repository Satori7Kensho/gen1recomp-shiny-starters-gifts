# v1.3.0 release verification

The focused option-separation checks below passed on the user's installation
with rc2. Final v1.3.0 preserves that gameplay code and launcher schema; only
version metadata/comment and documentation changed. No additional long
playthrough or repeat of these passing tests is required to finalize this
release with the documented scope.

The exact engine/ROM revisions for these user tests were not supplied.

## Completed gameplay checks

| Done | Event | Starters | Gifts | Trades | Reported result |
| --- | --- | --- | --- | --- | --- |
| Yes | LeafGreen lab Squirtle | ON | OFF | OFF | Shiny |
| Yes | LeafGreen lab Squirtle | OFF | ON | OFF | Ordinary |
| Yes | LeafGreen lab Squirtle | OFF | OFF | ON | Ordinary |
| Yes | Yellow Bulbasaur gift | OFF | ON | OFF | Shiny |
| Yes | Yellow Bulbasaur gift | ON | OFF | OFF | Ordinary |
| Yes | Yellow Bulbasaur gift | OFF | OFF | ON | Ordinary |
| Yes | Yellow Bulbasaur gift | OFF | OFF | OFF | Ordinary |
| Yes | FireRed Farfetch'd NPC trade | OFF | OFF | ON | Shiny |
| Yes | FireRed Farfetch'd NPC trade | ON | OFF | OFF | Ordinary |
| Yes | FireRed Farfetch'd NPC trade | OFF | ON | OFF | Ordinary |
| Yes | FireRed Farfetch'd NPC trade | ON | ON | OFF | Ordinary |

- [x] LeafGreen shiny Squirtle remained shiny after saving, disabling all three
  switches, fully restarting, and loading that saved game.
- [x] Yellow's later gift of a starter species followed Gifts rather than Starters.

These checkmarks describe user reports, not assistant-run gameplay or new
diagnostic captures. Yellow starter Pikachu was also reported shiny, but its
complete option settings were not recorded. FireRed shiny colors were visible;
the user did not see a summary star, and no star/UI fix is claimed.

## Optional broader coverage: not established by these results

These items limit broader claims; they are not a request to replay whole games
before using this release. Earlier beta/harness results remain separately
documented in README.md.

- [ ] Independent starter/gift routing in the other declared games, including
  fresh Gen 2/Crystal cases and the remaining Gen 1/Gen 3 titles/events.
- [ ] Gen 3 ordinary gifts and gifts sent directly to PC storage with the final
  independent-switch routing (earlier beta conversion evidence exists).
- [ ] Natural gift-egg acquisition and hatching, with the gift switch toggled.
- [ ] Separate LeafGreen NPC-trade gameplay confirmation.
- [ ] NPC-trade shiny save/reload persistence; LeafGreen starter persistence
  does not establish this separate event path.
- [ ] Actual player-to-player/link-trade sessions; their handlers are untouched.
- [ ] Additional ROM revisions, custom starter scripts, or later engine versions.
- [ ] Remaining option combinations and all-OFF checks outside the listed cases,
  plus gameplay cancellation/wrong-species checks where not already reported.

## If extending coverage later

Use a save from before receiving the Pokemon or egg, restore the same checkpoint
for comparisons, and fully restart after changing settings. Turning a switch OFF
does not undo an existing shiny. "Unforced" permits a natural shiny or a result
from another mod. Record the game, exact engine/ROM version, event, three option
values, observed result, and any save/reload check. Mark unavailable cases not run.
