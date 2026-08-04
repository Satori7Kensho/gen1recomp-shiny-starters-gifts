-- Shiny Gifts & Starters v1.1 
-- Compatible with the main shiny mod, Wilds of Kanto, voxel, followers, etc.

return function(mod)
  local Stats   = require("src.pokemon.Stats")
  local Pokemon = require("src.pokemon.Pokemon")
  local Commands = require("src.script.Commands")

  local SHINY_ATK = { 2, 3, 6, 7, 10, 11, 14, 15 }

  local STARTERS = {
    BULBASAUR  = true,
    CHARMANDER = true,
    SQUIRTLE   = true,
    PIKACHU    = true,
  }

  local function makeShinyDVs()
    local rng = (love and love.math and love.math.random) or math.random
    local atk = SHINY_ATK[rng(#SHINY_ATK)]
    local dvs = {
      attack  = atk,
      defense = 10,
      speed   = 10,
      special = 10,
    }
    dvs.hp = (dvs.attack % 2) * 8
           + (dvs.defense % 2) * 4
           + (dvs.speed % 2) * 2
           + (dvs.special % 2)
    return dvs
  end

  local function applyShiny(mon, data)
    if not mon then return mon end
    local dvs = makeShinyDVs()
    mon.dvs   = dvs
    mon.shiny = true
    local def = data and data.pokemon and data.pokemon[mon.species]
    if def and def.baseStats then
      mon.stats = Stats.calc(def, mon.level or 1, dvs, mon.statExp)
      mon.hp    = mon.stats.hp
    end
    return mon
  end

  -- Options
  mod.options:define({
    {
      key     = "shiny_starters",
      type    = "toggle",
      label   = "SHINY STARTERS",
      default = true,
      help    = "Force the player's starter to be shiny.",
    },
    {
      key     = "shiny_all_gifts",
      type    = "toggle",
      label   = "SHINY ALL GIFTS",
      default = false,
      help    = "Force every story gift (fossils, Lapras, Eevee, etc.) to be shiny.",
    },
  })

  local function opt(key, default)
    local ok, val = pcall(mod.options.get, mod.options, key)
    if ok and val ~= nil then return val end
    return default
  end

  -- Only intercept the official gift command (very precise, no wild interference)
  local origGive = Commands.give_pokemon
  if type(origGive) == "function" then
    Commands.give_pokemon = function(ctx, species, level, ...)
      -- Let the normal before_give event fire first (other mods may listen)
      local gift = { ctx = ctx, species = species, level = level }
      if ctx and ctx.game and ctx.game.mods then
        ctx.game.mods.events:emit("pokemon.before_give", gift)
      end

      -- Decide whether to force shiny
      local sp = tostring(gift.species or species):upper():gsub("[^%w_]", "_")
      local force = false
      if opt("shiny_all_gifts", false) then
        force = true
      elseif opt("shiny_starters", true) and STARTERS[sp] then
        force = true
      end

      -- Call original (which creates the mon)
      local result = origGive(ctx, gift.species or species, gift.level or level, ...)

      -- After the mon has been created and added, force shiny if requested
      -- (we look in the party for the newest matching mon)
      if force and ctx and ctx.save and ctx.save.party then
        local party = ctx.save.party
        for i = #party, 1, -1 do
          local mon = party[i]
          if mon and tostring(mon.species):upper():gsub("[^%w_]", "_") == sp then
            applyShiny(mon, ctx.game and ctx.game.data)
            break
          end
        end
      end

      return result
    end
  end
end
