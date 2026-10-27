# Shiny Starters, Gifts, NPC Trades & Day Care Eggs for Gen1Recomp

A small quality-of-life companion mod for [Gen1Recomp](https://github.com/bryanthaboi/gen1recomp) that lets you receive shiny starters, shiny scripted story gift Pokémon, shiny Pokémon via in-game NPC trades, shiny eggs from the Day Care, shiny Gen 3 Mystery/Event gifts, and Box reward eggs.

**v1.6.3 adds a separate Shiny Box Rewards option, independent of Shiny Mystery/Event Gifts.**

Requires **Gen1Recomp v0.3.5 or later**.

The mod and your chosen options must be enabled **before receiving the Pokémon**.

> **Important:** Fully close and reopen Gen1Recomp after enabling the mod or changing its options, before receiving your Pokémon.

## Supported Games

- Pokémon Red, Blue, and Yellow (Gen 1)
- Pokémon Gold, Silver, and Crystal (Gen 2)
- Pokémon FireRed and LeafGreen (Gen 3)
- Pokémon Ruby and Sapphire (Gen 3)
- Pokémon Emerald (Gen 3)

## Options

- **SHINY STARTERS** – Makes your starting Pokémon from Oak’s or Elm’s lab or Birch’s bag shiny.
- **SHINY STORY GIFTS** – Makes other scripted story gift Pokémon and gift eggs shiny.
- **SHINY TRADES** – Makes Pokémon received from in-game NPC trades shiny.
- **SHINY DAY CARE EGGS** – Makes eggs collected from the Day Care hatch shiny in Gold, Silver, Crystal, FireRed, LeafGreen, Ruby, Sapphire, and Emerald.
- **SHINY MYSTERY/EVENT GIFTS** – Makes Pokémon and gift eggs received through Mystery Gift or Mystery Event shiny.
- **SHINY BOX REWARDS** – Makes newly received Box reward eggs shiny. See the required setup below.

> **Important:** **SHINY MYSTERY/EVENT GIFTS** applies to Pokémon and eggs received directly as gifts. Event tickets and item rewards keep their normal behavior. **Pokémon encountered after unlocking an event still use the game's normal encounter rules and are not guaranteed to be shiny.**

| Option | Effect |
| --- | --- |
| SHINY STARTERS | Makes the starter received from Oak, Elm, or Birch's bag shiny. |
| SHINY STORY GIFTS | Makes other scripted gifts and one-time gift eggs shiny. |
| SHINY TRADES | Makes Pokémon received from in-game NPC trades shiny. |
| SHINY DAY CARE EGGS | Makes repeatable Day Care breeding eggs hatch shiny in Gen 2 and Gen 3. |
| SHINY MYSTERY/EVENT GIFTS | Makes directly delivered Gen 3 Mystery Gift and Mystery Event Pokémon and eggs shiny. |
| SHINY BOX REWARDS | Makes new launcher Box reward eggs shiny using the setup below. |

**Each option controls only its own category.** All six default to ON, and you can turn each one on or off independently. Existing option choices are retained.

### Special cases

| Pokémon or egg | Option |
| --- | --- |
| Yellow's starting Pikachu | **SHINY STARTERS** |
| Yellow's later Bulbasaur, Charmander, and Squirtle gifts | **SHINY STORY GIFTS** |
| Ruby, Sapphire, and Emerald's one-time Wynaut Egg in Lavaridge | **SHINY STORY GIFTS** |
| Crystal's one-time Odd Egg from the Route 34 Day Care Man | **SHINY STORY GIFTS** |
| Repeatable eggs bred at the Day Care | **SHINY DAY CARE EGGS** |
| Gen 3 Wonder Card and Ruby/Sapphire Mystery Event Pokémon and eggs | **SHINY MYSTERY/EVENT GIFTS** |
| Box's Swablu, Zigzagoon, Skitty, and Pichu reward eggs | **SHINY BOX REWARDS** |

Enable the relevant option before receiving the Pokémon or egg, and check an egg's shiny color after it hatches. Crystal's Odd Egg can also be shiny naturally without the mod.

> **Important:** **Keep the mod enabled until Mystery/Event and Box eggs hatch. Hatch these eggs before exporting them outside Gen1Recomp.**

### Box reward eggs

New Box reward eggs need this setup:

1. Enable the mod and **SHINY BOX REWARDS** for the receiving Gen 3 game.
2. Continue the save that will receive the reward, then **SAVE in game once before returning to the launcher**. Opening the title screen alone is not enough; you must select **CONTINUE** and save in game before returning to the launcher.
3. Return to the launcher, open Box, select that same save, claim a new reward egg, and withdraw it into that game's PC.
4. Launch the game and **CONTINUE the same save with SHINY BOX REWARDS ON**. The egg becomes shiny on this load; Box may show its original appearance beforehand.
5. Take the egg from the PC and hatch it with the mod still enabled.

This applies to new reward eggs, not Pokémon you already own or ordinary Box deposits, withdrawals, or imports. If you first continue with the option OFF after withdrawing a new reward, turning it ON later will not change that egg.

## How It Works

The mod changes the newly received Pokémon’s saved data to make it shiny. Turning an option off later does not remove shininess from Pokémon you have already received.

## Installation

### Mod Index

If available through the Gen1Recomp Mod Index, install or update the mod through the mod manager.

### Manual Installation

1. Download the [latest release ZIP](https://github.com/Satori7Kensho/gen1recomp-shiny-starters-gifts/releases/latest).
2. Fully close Gen1Recomp.
3. Create `mods/shiny_starters_gifts/` in your Gen1Recomp folder, then extract the release ZIP's root-level files into that folder. When updating, replace the previous files.
4. Enable the mod and choose your options in the launcher or mod manager.
5. **Fully close and reopen Gen1Recomp before receiving your Pokémon.**

Keep only one active copy of the mod installed.

## Compatibility

The mod applies to starters, scripted gifts, in-game NPC trades, Day Care eggs, directly delivered Gen 3 Mystery/Event gifts, and new Box reward eggs. It does not change:

- Wild encounter shiny rates
- Trainer Pokémon
- Pokémon you already own
- Player-to-player or link trades

**Event tickets and item rewards keep their normal behavior. Pokémon encountered after unlocking an event still use the game's normal encounter rules.**

Shiny appearance depends on the game’s visuals and any visual mods you use.

During FireRed and Emerald egg-hatch testing on Gen1Recomp v0.3.40, the hatch scene sometimes changed from a shiny sprite to a normal-colored animated sprite. The hatched Pokémon remained shiny. Crystal's Odd Egg displayed shiny throughout its hatch scene.

## What’s New in v1.6.3

- Added a separate **SHINY BOX REWARDS** option, independent of **SHINY MYSTERY/EVENT GIFTS**.
- Added the required save, claim, withdraw, and continue instructions for new Box reward eggs.

## Earlier v1.5.0–v1.6.2 changes

- Added Ruby and Sapphire support for starters, scripted gifts, NPC trades, and Day Care eggs.
- Added Gen 3 Mystery/Event gift support and a saved handoff for launcher Box reward eggs.
- Renamed **SHINY GIFTS** to **SHINY STORY GIFTS** to distinguish ordinary story gifts from event and Box rewards.

## Earlier v1.4.0 changes

- Added Emerald starter support for Birch's bag on Route 101.
- Extended scripted gift and NPC trade hooks to Emerald.
- Added a separate option for repeatable Day Care eggs in Gen 2 and Gen 3 (default ON).
- Included Crystal's one-time Odd Egg under SHINY GIFTS; it uses a separate game event from bred Day Care eggs.

## Earlier v1.3.0 changes

- Added FireRed and LeafGreen support.
- Added an option for shiny in-game NPC trades.

## License

MIT. See [LICENSE](LICENSE).

