# Shiny Gifts & Starters v1.3.0

A [Gen1Recomp](https://github.com/bryanthaboi/gen1recomp) mod with independent
options for shiny lab starters, scripted gifts, and in-game NPC trades.

The focused gameplay checks passed for LeafGreen's Squirtle starter, Yellow's
Bulbasaur gift, FireRed's Farfetch'd trade, and LeafGreen shiny save/reload
persistence. Final v1.3.0 uses the same gameplay code and launcher options as
the tested rc2. Only the version metadata/comment and documentation changed.

## Installation

1. Fully close Gen1Recomp.
2. Replace the old Shiny Gifts & Starters folder/package with this release.
   Keep only one active copy; remove/disable old trade probes and egg-test mods.
3. Extract the ZIP so the files are directly under
   `mods/shiny_starters_gifts/`, including `manifest.json`, `main.lua`, and
   `options.lua`. Avoid an extra nested folder.
4. Reopen the launcher, enable the mod, and confirm it shows **1.3.0**.
   Check the three option values; existing settings use the same saved keys.
5. Fully restart after changing options, then receive a new Pokemon to use
   those settings. Preserve a save from before an event if you want to repeat it.

The upgrade does not reset Pokemon, saves, or existing shininess. The ZIP does
not contain game saves, ROMs, extracted assets, test harnesses, or engine source.

## Independent options

All three switches default to ON and are available in the launcher.

| Option | Effect |
| --- | --- |
| SHINY STARTERS | Makes the starter received at Oak's or Elm's lab shiny. |
| SHINY GIFTS | Makes other supported scripted gifts and gift eggs shiny. Excludes the lab starter and NPC trades. |
| SHINY TRADES | Makes Pokemon received from supported in-game NPC trades shiny. |

**Each switch controls its own category.** Yellow's later Bulbasaur, Charmander,
and Squirtle gifts follow Gifts, even though those species are starters in other
games. Gift eggs follow Gifts, including an egg of a starter species.

OFF leaves an event unforced; it does not remove shininess from Pokemon already
received. Natural shinies or shininess caused by another mod can still occur.
All OFF leaves all three categories unforced by this mod.

The visible SHINY ALL GIFTS option is now named SHINY GIFTS. Its saved key
`shiny_all_gifts` is retained. Mod ID, saved option keys, and defaults are unchanged.

## Requirements and scope

- Declared minimum: **Gen1Recomp v0.3.5**, mod API 2.
- Declared games: Red, Blue, Yellow, Gold, Silver, Crystal, FireRed, LeafGreen.
- Permission: `engine_internals`, needed for the existing generation-specific paths.
- The minimum and game declarations are compatibility metadata, not evidence
  that every game, ROM revision, or later engine version has been tested.
- Gen 3 NPC-trade internals were inspected in v0.3.5. A future engine change
  may require a compatibility update.

Player-to-player/link trades, wild encounters, trainer Pokemon, and Pokemon
already owned are outside this mod's conversion paths. The final build does
not hook link-trade handlers; a live link session was not tested for this release.

## Gameplay results

These are user-reported results from rc2, whose gameplay code is unchanged in
final v1.3.0. The exact engine/ROM revisions for these runs were not supplied,
so no additional version-specific runtime claim is made.

| Game and event | Settings tested | Result |
| --- | --- | --- |
| LeafGreen lab Squirtle | Each switch enabled individually | Shiny with Starters only; ordinary with Gifts only or Trades only. |
| LeafGreen shiny Squirtle persistence | Save, disable all switches, fully restart and reload | Squirtle remained shiny. |
| Yellow Cerulean Bulbasaur gift | Each switch enabled individually; all OFF | Shiny with Gifts only; ordinary with Starters only, Trades only, or all OFF. |
| FireRed Spearow to Farfetch'd NPC trade | Trades only; Trades OFF with Starters only, Gifts only, or both ON | Shiny with Trades only; ordinary in all three tested Trades-OFF cases. |

The user also observed shiny starter Pikachu in Yellow; the full settings were
not recorded for that observation. FireRed shiny colors appeared in the reported
run, but a summary star was absent. This release does not change that UI or claim
to fix the missing star. Stats alone do not establish shininess.

These focused option-separation checks are complete for the listed cases.
There is no need to repeat them for a version/documentation-only promotion.
See [REGRESSION_CHECKLIST.md](REGRESSION_CHECKLIST.md) for the detailed completed
checks and optional coverage that remains untested.

## Earlier beta evidence

The following results predate rc2's independent option routing. They support
the retained conversion paths and are not relabeled as final-build playtests.

| Case | Earlier evidence and limit |
| --- | --- |
| Yellow NPC trade | User received shiny Mr. Mime for Clefairy; does not separately verify Red/Blue trades. |
| Crystal NPC trade | User received shiny Onix for Bellsprout on v0.3.1; does not separately verify Gold/Silver trades. |
| Crystal starters and ordinary gifts | Successful tests recorded in prior beta notes. |
| FireRed starter, ordinary gift, boxed gift | Successful data-level tests recorded in prior beta notes. |
| FireRed gift persistence | Prior shiny PID save/close/reload check passed; does not establish NPC-trade persistence. |
| LeafGreen starter | Prior v0.3.1 diagnostic reported shiny XOR 5 and the engine shiny check true. |
| Gen 3 gift eggs | A command harness exercised the real `giveegg` path, reporting shiny XOR 4 and the engine shiny check true. Natural gift acquisition and hatching, and separate runs in both titles, were not established. |
| FireRed native trade handoff | A probe confirmed `natives_trade._offered` reaches the party. Beta.6 changed PID 353977303 to 616498903, producing XOR 2 and `SummaryData.isShiny = true` on `_offered`. The later rc2 user test above confirmed a visibly shiny received Farfetch'd. |

The historical v0.3.1 results do not lower this release's declared v0.3.5 minimum.
LeafGreen NPC trades, fresh results for every other title, natural eggs/hatching,
and actual link sessions are not covered by the focused rc2 gameplay results.

## Implementation and preserved behavior

Gen 1 uses `give_pokemon`; Gen 2/Crystal use `givepoke` and `giveegg`. Their NPC
trades use the shared `trade` command. The mod modifies the newly received
Pokemon's stored shiny-compatible DVs, preserving already-canonical shiny DVs.
Gen 2 stats/gender are refreshed and gift eggs retain their pre-hatch zero HP.
Changing DVs can change Gen 1/2 stats and gender.

FireRed/LeafGreen gifts use `givemon` and `giveegg`. The retained Gen III PID
search uses OT ID, Secret ID (zero if absent), and PID halves to obtain shiny
XOR 0-7 while preserving nature, the low PID byte (gender), and ability parity.
It handles gifts placed in Gen 3 PC storage without overriding displayed shininess.

For Gen 3 NPC trades, the original `natives.ALLOW["special:253"]` runs first and
creates `natives_trade._offered`. The mod makes that object shiny before special
254 runs the vanilla trade scene and transfers it. Special 254, shared transfer
functions, and player-to-player/link-trade handlers are not wrapped.

Starter routing checks species and the script's lab location before the gift
handler runs. Other scripted gifts and every gift egg use Gifts. Custom starter
scripts outside the recognized lab locations have not been verified.

The beta diagnostic writers, pending-trade diagnostic state, and beta-only
update watcher were removed before rc2. This release creates no beta/probe
diagnostic files or overlays and does not delete old logs.

## Validation

The release build runs the official v0.3.5 modkit's strict fixture validation,
distribution lint, Gen 2/Gen 3 compatibility checks, and package gate. A LuaJIT
regression harness checks the independent option matrix, conversion behavior,
gift/egg/box/trade/pass-through/cancellation cases, PID traits, the real Gen 3
script context, and the v0.3.5 native handoff with controlled ROM/UI substitutes.

Offline checks supplement the specific user gameplay results above. They do not
prove untested natural events or all game/version combinations. The compatibility
analyzers retain one unresolved lazy Gen 2 module-return note (`main.lua:44`),
which is recorded as a static-analysis limitation.

## License

MIT. See [LICENSE](LICENSE).
