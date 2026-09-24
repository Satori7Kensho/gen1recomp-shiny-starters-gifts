-- Launcher / Mod Manager option schema for Shiny Starters, Gifts & NPC Trades.
-- Keep keys/defaults synchronized with main.lua's mod.options:define() rows.
-- The manifest's options_schema field lets the launcher show these settings
-- before a game is started.

return {
  {
    key = "shiny_starters",
    type = "toggle",
    label = "SHINY STARTERS",
    default = true,
    description = "Force the starter received at Oak's or Elm's lab to be shiny. Other gifts use SHINY GIFTS.",
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
}
