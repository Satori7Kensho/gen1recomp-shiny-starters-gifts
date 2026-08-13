-- Shiny Gifts & Starters v1.2.0
-- Gen 1 (Red / Blue / Yellow) + Gen 2 (Gold)
--
-- Only scripted gifts are touched:
--   Gen 1: give_pokemon
--   Gen 2: givepoke / giveegg
--
-- Real shiny-compatible DVs are written instead of only setting a visual flag.
-- This keeps Gold gifts shiny when they are rebuilt later from their stored DVs.

local Stats = require("src.pokemon.Stats")

local SHINY_ATK = { 2, 3, 6, 7, 10, 11, 14, 15 }

local STARTERS = {
  -- Gen 1
  BULBASAUR  = true,
  CHARMANDER = true,
  SQUIRTLE   = true,
  PIKACHU    = true,

  -- Gen 2
  CHIKORITA = true,
  CYNDAQUIL = true,
  TOTODILE  = true,
}

-- Gold needs its own stat/gender refresh after its DVs are replaced.
-- Keep this lazy so a Gen 1 boot never loads a Gen 2 engine module.
local Gen2Mon
local function getGen2Mon()
  if not Gen2Mon then
    Gen2Mon = require("src.battle.gen2.Mon")
  end
  return Gen2Mon
end

local function normalize(species)
  return tostring(species or ""):upper():gsub("[^%w_]", "_")
end

local function makeShinyDVs()
  local rng = (love and love.math and love.math.random) or math.random
  local dvs = {
    attack  = SHINY_ATK[rng(#SHINY_ATK)],
    defense = 10,
    speed   = 10,
    special = 10,
  }

  -- HP DV is derived from the low bit of the other four DVs in Gen 1/2.
  dvs.hp = (dvs.attack % 2) * 8
         + (dvs.defense % 2) * 4
         + (dvs.speed % 2) * 2
         + (dvs.special % 2)

  return dvs
end

-- Record the exact monster table objects that existed before a gift command.
-- That lets us identify the newly-created gift afterward without guessing by
-- species (important when the player already owns another of the same species).
local function addSeen(seen, list)
  if type(list) ~= "table" then return end
  for _, mon in ipairs(list) do
    if type(mon) == "table" then
      seen[mon] = true
    end
  end
end

local function snapshotMons(save)
  local seen = {}
  if type(save) ~= "table" then return seen end

  addSeen(seen, save.party)

  -- Gen 1 can send a gift to a PC box when the party is full.
  if type(save.boxes) == "table" then
    for _, box in ipairs(save.boxes) do
      addSeen(seen, box)
    end
  end

  -- Older Gen 1 saves may still have the legacy single-box field until the
  -- box code migrates it into save.boxes.
  addSeen(seen, save.box)

  return seen
end

local function firstUnseen(list, seen)
  if type(list) ~= "table" then return nil end
  for _, mon in ipairs(list) do
    if type(mon) == "table" and not seen[mon] then
      return mon
    end
  end
  return nil
end

local function findNewGift(save, seen, includeBoxes)
  if type(save) ~= "table" then return nil end

  local mon = firstUnseen(save.party, seen)
  if mon then return mon end

  if includeBoxes and type(save.boxes) == "table" then
    for _, box in ipairs(save.boxes) do
      mon = firstUnseen(box, seen)
      if mon then return mon end
    end
  end

  if includeBoxes then
    mon = firstUnseen(save.box, seen)
    if mon then return mon end
  end

  return nil
end

return function(mod)
  mod.options:define({
    {
      key     = "shiny_starters",
      type    = "toggle",
      label   = "SHINY STARTERS",
      default = true,
      help    = "Force the player's starter to be shiny (Gen 1 + Gen 2).",
    },
    {
      key     = "shiny_all_gifts",
      type    = "toggle",
      label   = "SHINY ALL GIFTS",
      default = false,
      help    = "Force every scripted story gift (including Gold gift eggs) to be shiny.",
    },
  })

  local function opt(key, default)
    local ok, value = pcall(function()
      return mod.options:get(key)
    end)
    if ok and value ~= nil then return value end
    return default
  end

  local function shouldForce(species)
    if opt("shiny_all_gifts", false) then
      return true
    end
    return opt("shiny_starters", true)
      and STARTERS[normalize(species)] == true
  end

  local function applyGen1Shiny(mon, game)
    if not mon then return end

    -- If another shiny mod already produced canonical shiny DVs, preserve them.
    if Stats.isShiny and Stats.isShiny(mon.dvs) then
      mon.shiny = true
      return
    end

    local dvs = makeShinyDVs()
    mon.dvs = dvs
    mon.shiny = true

    local data = game and game.data
    local def = data and data.pokemon and data.pokemon[mon.species]
    if def and def.baseStats and Stats.calc then
      mon.stats = Stats.calc(def, mon.level or 1, dvs, mon.statExp)
      if mon.stats and mon.stats.hp then
        -- A newly received gift should arrive at full HP.
        mon.hp = mon.stats.hp
      end
    end
  end

  local function applyGen2Shiny(mon, game)
    if not mon then return end

    local Mon = getGen2Mon()

    -- Preserve an already-canonical shiny from another mod.
    if Mon.vanillaShiny and Mon.vanillaShiny(mon.dvs) then
      mon.shiny = true
      return
    end

    local dvs = makeShinyDVs()
    mon.dvs = dvs

    local data = game and game.data

    -- Gold calculates stats and gender from the original DVs during Mon.new,
    -- so refresh both after replacing those DVs.
    if Mon.refreshStats then
      Mon.refreshStats(mon, data)
    end

    local def = data and data.pokemon and data.pokemon[mon.species]
    if def and Mon.gender then
      mon.gender = Mon.gender(def, dvs, {
        species = mon.species,
        level = mon.level or 1,
      })
    end

    mon.shiny = true

    if mon.isEgg then
      -- Gold gift eggs intentionally stay at 0 HP until they hatch.
      mon.hp = 0
    elseif mon.maxHp then
      -- Newly received non-egg gifts arrive fully healed.
      mon.hp = mon.maxHp
    end
  end

  -- script.command is shared by Gen 1 and Gold. Let the vanilla command create
  -- and add the mon first, then modify only that exact newly-created gift.
  -- Wild encounters never pass through these gift command names.
  mod.hooks:wrap("script.command", function(next, ctx, name, args, ...)
    local gen2 = ctx and ctx.generation == 2

    local isGift
    if gen2 then
      isGift = (name == "givepoke" or name == "giveegg")
    else
      isGift = (name == "give_pokemon")
    end

    if not isGift then
      return next(ctx, name, args, ...)
    end

    -- mod.game is the supported live-game facade for both generations.
    -- ctx.game / ctx.save are useful Gen 1 fallbacks.
    local game = mod.game or (ctx and ctx.game)
    local save = (game and game.save) or (ctx and ctx.save)

    if type(save) ~= "table" then
      return next(ctx, name, args, ...)
    end

    local seen = snapshotMons(save)

    -- Run the real command exactly once. It may yield for UI; when it returns,
    -- the gift has either been added or the give failed.
    local result = next(ctx, name, args, ...)

    -- Gold's givepoke/giveegg are party-only. Gen 1 give_pokemon may box.
    local mon = findNewGift(save, seen, not gen2)

    if mon and shouldForce(mon.species) then
      if gen2 then
        applyGen2Shiny(mon, game)
      else
        applyGen1Shiny(mon, game)
      end
    end

    return result
  end)
end
