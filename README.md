# Shiny Starters, Gifts, NPC Trades & Day Care Eggs for Gen1Recomp

A small quality-of-life companion mod for [Gen1Recomp](https://github.com/bryanthaboi/gen1recomp) that lets you receive shiny starters, shiny scripted story gift Pokémon, shiny Pokémon via in-game NPC trades, and shiny eggs from the Day Care.

**v1.4.0 adds Emerald support and a separate Shiny Day Care Eggs option.**

Requires **Gen1Recomp v0.3.5 or later**.

The mod and your chosen options must be enabled **before receiving the Pokémon**.

> **Important:** Fully close and reopen Gen1Recomp after enabling the mod or changing its options, before receiving your Pokémon.

## Supported Games

- Pokémon Red, Blue, and Yellow (Gen 1)
- Pokémon Gold, Silver, and Crystal (Gen 2)
- Pokémon FireRed and LeafGreen (Gen 3)
- Pokémon Emerald (Gen 3 beta)

## Options

- **SHINY STARTERS** – Makes your starting Pokémon from Oak’s or Elm’s lab or Birch’s bag shiny.
- **SHINY GIFTS** – Makes other scripted story gift Pokémon and gift eggs shiny.
- **SHINY TRADES** – Makes Pokémon received from in-game NPC trades shiny.
- **SHINY DAY CARE EGGS** – Makes eggs collected from the Day Care hatch shiny in Gold, Silver, Crystal, FireRed, LeafGreen, and Emerald.

| Option | Effect |
| --- | --- |
| SHINY STARTERS | Makes the starter received from Oak, Elm, or Birch's bag shiny. |
| SHINY GIFTS | Makes other scripted gifts and one-time gift eggs shiny. |
| SHINY TRADES | Makes Pokémon received from in-game NPC trades shiny. |
| SHINY DAY CARE EGGS | Makes repeatable Day Care breeding eggs hatch shiny in Gen 2 and Gen 3. |

**Each option controls only its own category.** All four default to ON, and you can turn each one on or off independently.

### Special cases

| Pokémon or egg | Option |
| --- | --- |
| Yellow's starting Pikachu | **SHINY STARTERS** |
| Yellow's later Bulbasaur, Charmander, and Squirtle gifts | **SHINY GIFTS** |
| Emerald's one-time Wynaut Egg in Lavaridge | **SHINY GIFTS** |
| Crystal's one-time Odd Egg from the Route 34 Day Care Man | **SHINY GIFTS** |
| Repeatable eggs bred at the Day Care | **SHINY DAY CARE EGGS** |

Enable the relevant option before receiving the Pokémon or egg, and check an egg's shiny color after it hatches. Crystal's Odd Egg can also be shiny naturally without the mod.

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

The mod applies to starters, scripted gifts, in-game NPC trades, and Day Care eggs. It does not change:

- Wild encounter shiny rates
- Trainer Pokémon
- Pokémon you already own
- Player-to-player or link trades

Shiny appearance depends on the game’s visuals and any visual mods you use.

During FireRed and Emerald egg-hatch testing on Gen1Recomp v0.3.40, the hatch scene sometimes changed from a shiny sprite to a normal-colored animated sprite. The hatched Pokémon remained shiny. Crystal's Odd Egg displayed shiny throughout its hatch scene.

## What’s New in v1.4.0

- Added Emerald starter support for Birch's bag on Route 101.
- Extended scripted gift and NPC trade hooks to Emerald.
- Added a separate option for repeatable Day Care eggs in Gen 2 and Gen 3 (default ON).
- Included Crystal's one-time Odd Egg under SHINY GIFTS; it uses a separate game event from bred Day Care eggs.

## Earlier v1.3.0 changes

- Added FireRed and LeafGreen support.
- Added an option for shiny in-game NPC trades.

## License

MIT. See [LICENSE](LICENSE).
