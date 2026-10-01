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
    description = "Force the starter received from Oak, Elm, or Birch's bag to be shiny. Other gifts use SHINY GIFTS.",
  },
  {
    key = "shiny_all_gifts",
    type = "toggle",
    label = "SHINY GIFTS",
    default = true,
    description = "Force scripted gifts and gift eggs to be shiny. Excludes the lab starter and NPC trades.",
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
    description = "Make eggs collected from the Day Care hatch shiny in Gen 2 and Gen 3. One-time gift eggs use SHINY GIFTS.",
  },
}
