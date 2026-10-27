-- Launcher / Mod Manager option schema for Shiny Starters, Gifts, NPC Trades & Day Care Eggs.
-- Keep keys/defaults synchronized with main.lua's mod.options:define() rows.
-- The manifest's options_schema field lets the launcher show these settings
-- before a game is started.

return {
  {
    key = "shiny_starters",
    type = "toggle",
    label = "SHINY STARTERS",
    default = true,
    description = "Force the starter received from Oak, Elm, or Birch's bag to be shiny. Other story gifts use SHINY STORY GIFTS.",
  },
  {
    key = "shiny_all_gifts",
    type = "toggle",
    label = "SHINY STORY GIFTS",
    default = true,
    description = "Force scripted story gifts and one-time story gift eggs to be shiny. Starters, NPC trades, Mystery/Event gifts and Box rewards use their own settings.",
  },
  {
    key = "shiny_trades",
    type = "toggle",
    label = "SHINY TRADES",
    default = true,
    description = "Force Pokemon received from supported in-game NPC trades to be shiny.",
  },
  {
    key = "shiny_daycare_eggs",
    type = "toggle",
    label = "SHINY DAY CARE EGGS",
    default = true,
    description = "Make eggs collected from the Day Care hatch shiny in Gen 2 and Gen 3. One-time gift eggs use SHINY STORY GIFTS.",
  },
  {
    key = "shiny_mystery_event_gifts",
    type = "toggle",
    label = "SHINY MYSTERY/EVENT GIFTS",
    default = true,
    description = "Makes Pokémon and gift eggs received through Mystery Gift or Mystery Event shiny.",
  },
  {
    key = "shiny_box_rewards",
    type = "toggle",
    label = "SHINY BOX REWARDS",
    default = true,
    description = "Makes newly received Box reward eggs shiny. See README for the required setup.",
  },
}
