-- Shiny Starters, Gifts, NPC Trades & Day Care Eggs for Gen1Recomp v1.4.0
-- Gen 1 (Red / Blue / Yellow) + Gen 2 (Gold / Silver / Crystal)
-- + Gen 3 (FireRed / LeafGreen / Emerald)
--
-- Only scripted gifts, in-game NPC trades, and Day Care eggs are touched:
--   Gen 1: give_pokemon / trade
--   Gen 2: givepoke / giveegg / Crystal Odd Egg / trade / Day Care collection
--   Gen 3: givemon / giveegg / Day Care collection
--          NPC special:253 (FRLG) or :256 (Emerald)
--
-- Gen 1/2 use real shiny-compatible DVs.
-- Gen 3 uses a real shiny PID derived from OT ID / Secret ID while
-- preserving the generated Pokemon's nature, gender byte, and ability parity.

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

-- FireRed/LeafGreen internal species ids for the three Kanto starters.
local GEN3_STARTERS = {
  [1] = true, -- Bulbasaur
  [4] = true, -- Charmander
  [7] = true, -- Squirtle
}

-- Emerald's internal species ids differ from National Pokédex numbers.
local EMERALD_STARTERS = {
  [277] = true, -- Treecko
  [280] = true, -- Torchic
  [283] = true, -- Mudkip
}

-- Gen 2 needs its own stat/gender refresh after its DVs are replaced.
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


-- Gen 3 shiny rule:
--   TID xor SID xor PID_low xor PID_high < 8
-- Keep this implementation local so Gen 1/2 boots do not need Gen 3 modules.
local function xor16(a, b)
  a = math.floor(tonumber(a) or 0) % 65536
  b = math.floor(tonumber(b) or 0) % 65536
  local result, place = 0, 1
  for _ = 1, 16 do
    local abit, bbit = a % 2, b % 2
    if abit ~= bbit then result = result + place end
    a = math.floor(a / 2)
    b = math.floor(b / 2)
    place = place * 2
  end
  return result
end

local function gen3ShinyXor(mon, personality)
  if type(mon) ~= "table" then return nil end
  local tid = math.floor(tonumber(mon.otId) or 0) % 65536
  local sid = math.floor(tonumber(mon.otSecretId) or 0) % 65536
  local p = math.floor(tonumber(personality or mon.personality) or 0)
  local lo = p % 65536
  local hi = math.floor(p / 65536) % 65536
  return xor16(xor16(tid, sid), xor16(lo, hi))
end

local function makeGen3ShinyPid(mon)
  local original = tonumber(mon and mon.personality)
  if not original then return nil, "missing personality" end
  original = math.floor(original)

  local sx = gen3ShinyXor(mon, original)
  if sx and sx < 8 then
    return original, "already shiny"
  end

  -- Preserve nature (PID % 25), the low PID byte (gender), and PID parity
  -- (ability slot) while choosing a PID whose shiny XOR is 0..7.
  local nature = tonumber(mon.nature)
  if nature == nil then nature = original % 25 end
  nature = math.floor(nature) % 25

  local lowByte = original % 256
  local tid = math.floor(tonumber(mon.otId) or 0) % 65536
  local sid = math.floor(tonumber(mon.otSecretId) or 0) % 65536
  local trainerXor = xor16(tid, sid)

  for upperLowByte = 0, 255 do
    local pidLo = lowByte + upperLowByte * 256
    for desired = 0, 7 do
      local pidHi = xor16(xor16(trainerXor, pidLo), desired)
      local candidate = pidLo + pidHi * 65536
      if candidate % 25 == nature then
        return candidate, "changed"
      end
    end
  end

  return nil, "no compatible PID found"
end

local function addGen3StorageSeen(seen, raw)
  local storage = type(raw) == "table" and raw.storage or nil
  local boxes = type(storage) == "table" and storage.boxes or nil
  if type(boxes) ~= "table" then return end
  for _, box in pairs(boxes) do
    if type(box) == "table" then
      addSeen(seen, box.mons)
    end
  end
end

local function snapshotGen3Mons(save)
  local seen = {}
  local raw = type(save) == "table" and save.gen3 or nil
  if type(raw) ~= "table" then return seen end
  addSeen(seen, raw.party)
  addGen3StorageSeen(seen, raw)
  return seen
end

local function findNewGen3Gift(save, seen)
  local raw = type(save) == "table" and save.gen3 or nil
  if type(raw) ~= "table" then return nil, nil end

  local mon = firstUnseen(raw.party, seen)
  if mon then return mon, "party" end

  local storage = raw.storage
  local boxes = type(storage) == "table" and storage.boxes or nil
  if type(boxes) == "table" then
    for b, box in pairs(boxes) do
      if type(box) == "table" and type(box.mons) == "table" then
        for s, candidate in pairs(box.mons) do
          if type(candidate) == "table" and not seen[candidate] then
            return candidate, ("box %s slot %s"):format(tostring(b), tostring(s))
          end
        end
      end
    end
  end

  return nil, nil
end

return function(mod)
  mod.options:define({
    {
      key     = "shiny_starters",
      type    = "toggle",
      label   = "SHINY STARTERS",
      default = true,
      help    = "Force the starter received from Oak, Elm, or Birch's bag to be shiny. Other gifts use SHINY GIFTS.",
    },
    {
      key     = "shiny_all_gifts",
      type    = "toggle",
      label   = "SHINY GIFTS",
      default = true,
      help    = "Force scripted gifts and gift eggs to be shiny. Excludes the lab starter and NPC trades.",
    },
    {
      key     = "shiny_trades",
      type    = "toggle",
      label   = "SHINY TRADES",
      default = true,
      help    = "Force Pokemon received from in-game NPC trades to be shiny (Gen 1, Gen 2, FireRed/LeafGreen, Emerald).",
    },
    {
      key     = "shiny_daycare_eggs",
      type    = "toggle",
      label   = "SHINY DAY CARE EGGS",
      default = true,
      help    = "Make eggs collected from the Day Care hatch shiny in Gen 2 and Gen 3. One-time gift eggs use SHINY GIFTS.",
    },
  })

  local function opt(key, default)
    local ok, value = pcall(function()
      return mod.options:get(key)
    end)
    if ok and value ~= nil then return value end
    return default
  end

  -- Capture the script's map before the gift command can yield for UI.
  -- Gen 2 supplies mapId; Gen 1/3 expose the current map through overworld.
  local function giftMapId(ctx)
    if not ctx then return nil end
    local map = ctx.map or (ctx.overworld and ctx.overworld.map)
    return ctx.mapId or (map and map.id)
  end

  local function shouldForce(mon, generation, mapId, command)
    local species = mon.species or mon.speciesId
    local starterSpecies = generation == 3 and GEN3_STARTERS[tonumber(species)]
      or (generation ~= 3 and STARTERS[normalize(species)])
    local starterLab = (generation == 1 and mapId == "OAKS_LAB")
      or (generation == 2 and mapId == "ELMS_LAB")
      -- Gen 3's compatibility facade spells the lab OAKS_LAB; its raw
      -- script-context fallback uses FR_OAKS_LAB.
      or (generation == 3 and (mapId == "OAKS_LAB" or mapId == "FR_OAKS_LAB"))

    -- A starter-species gift elsewhere (such as Yellow's Kanto gifts) is a
    -- gift, as is every gift egg. Only the lab starter uses SHINY STARTERS.
    if starterSpecies and starterLab and command ~= "giveegg"
       and not mon.isEgg and not mon.egg then
      return opt("shiny_starters", true)
    end
    return opt("shiny_all_gifts", true)
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

    -- Gen 2 calculates stats and gender from the original DVs during Mon.new,
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
      -- Gen 2 gift eggs intentionally stay at 0 HP until they hatch.
      mon.hp = 0
    elseif mon.maxHp then
      -- Newly received non-egg gifts arrive fully healed.
      mon.hp = mon.maxHp
    end
  end

  local function applyGen3Shiny(mon, game)
    if not mon then return false, "missing mon" end

    local pid, why = makeGen3ShinyPid(mon)
    if not pid then return false, why end

    -- Do not rely on Gen 3's explicit isShiny override; the PID itself is
    -- made canonical so the shiny state survives save/reload.
    mon.isShiny = nil
    mon.personality = pid

    local P = game and game.data and game.data.gen3Pokemon
    local species = tonumber(mon.species or mon.speciesId)

    if P then
      if P.natureId then mon.nature = P.natureId(pid) end
      if species and P.gender then mon.gender = P.gender(species, pid) end
      if species and P.abilityId then
        local ability = P.abilityId(species, pid)
        mon.ability = ability
        mon.abilityId = ability
      end
      if P.applyStats then P.applyStats(mon) end
    else
      -- Nature is still safe to refresh without the optional facade.
      mon.nature = pid % 25
    end

    -- Compatibility hint for display mods; Gen 3's shiny determination
    -- comes from the canonical PID above, not this convenience field.
    mon.shiny = true
    return true, why
  end

  -- Gen 2 Day Care eggs are built before collection, but collectEgg moves the
  -- same egg table into the party. Change it only after a successful pickup;
  -- an egg already waiting at the Day Care will still follow the option then.
  local gen2DaycareHookInstalled = false
  local function installGen2DaycareHook()
    if gen2DaycareHookInstalled then return true end
    local ok, breeding = pcall(require, "src.core.gen2.Breeding")
    if not ok or type(breeding) ~= "table" or type(breeding.collectEgg) ~= "function" then
      return false
    end

    local original = breeding.collectEgg
    breeding.collectEgg = function(data, save, ...)
      local received, egg = original(data, save, ...)
      if received and type(egg) == "table" and egg.isEgg
          and opt("shiny_daycare_eggs", true) then
        applyGen2Shiny(egg, { data = data })
      end
      return received, egg
    end
    gen2DaycareHookInstalled = true
    return true
  end

  -- Emerald's starter is given by an async native callback after the player
  -- chooses a Poké Ball on Route 101, rather than by the givemon command.
  local emeraldStarterHookInstalled = false
  local function installEmeraldStarterHook()
    if emeraldStarterHookInstalled then return true end
    local ok, field = pcall(require, "src.core.game3.scripting.natives_field_rse")
    if not ok or type(field) ~= "table" or type(field.giveStarter) ~= "function" then
      return false
    end

    local original = field.giveStarter
    field.giveStarter = function(ctx, selection, session)
      local save = type(session) == "table" and { gen3 = session } or nil
      local seen = save and snapshotGen3Mons(save) or nil
      local species, code = original(ctx, selection, session)

      if save and (code == 0 or code == 1)
          and session.version == "emerald"
          and EMERALD_STARTERS[tonumber(species)]
          and opt("shiny_starters", true) then
        local mon = findNewGen3Gift(save, seen)
        if mon and tonumber(mon.species or mon.speciesId) == tonumber(species) then
          applyGen3Shiny(mon, mod.game)
        end
      end

      return species, code
    end
    emeraldStarterHookInstalled = true
    return true
  end

  -- Gen 3 NPC trades create the received Pokémon in a native special before
  -- the trade scene transfers it. FRLG uses special:253; Emerald uses :256.
  -- Emerald's native module forwards to natives_trade but does not expose it
  -- through natives.MODULES, so obtain the shared trade module directly.
  local tradeHooks = {}
  local activeGen3Game = nil
  -- The Gen 3 Day Care uses a native special rather than the script giveegg
  -- command. Both FRLG and Emerald call this shared egg-collection function.
  local gen3DaycareHookInstalled = false
  local function installGen3DaycareHook()
    if gen3DaycareHookInstalled then return true end
    local ok, breeding = pcall(require, "src.core.game3.breeding")
    if not ok or type(breeding) ~= "table"
        or type(breeding.giveEggFromDaycare) ~= "function" then
      return false
    end

    local original = breeding.giveEggFromDaycare
    breeding.giveEggFromDaycare = function(session, ...)
      local egg = original(session, ...)
      local version = type(session) == "table" and session.version or nil
      if type(egg) == "table" and egg.isEgg
          and (version == "firered" or version == "leafgreen" or version == "emerald")
          and opt("shiny_daycare_eggs", true) then
        applyGen3Shiny(egg, activeGen3Game)
      end
      return egg
    end
    gen3DaycareHookInstalled = true
    return true
  end
  local function installGen3TradeHook(game, session)
    activeGen3Game = game or activeGen3Game
    local version = type(session) == "table" and session.version or nil
    if version ~= "emerald" and version ~= "firered" and version ~= "leafgreen" then
      return false
    end

    local ok, natives = pcall(require, "src.core.game3.scripting.natives")
    if not ok or type(natives) ~= "table" then
      return false
    end

    -- Binding a different game rebuilds ALLOW; reinstall if it was rebuilt.
    if type(natives.ensureBound) == "function" then
      local bound = pcall(natives.ensureBound, session)
      if not bound then return false end
    end
    local allow = natives.ALLOW
    local okTrade, trade = pcall(require, "src.core.game3.scripting.natives_trade")
    if type(allow) ~= "table" or not okTrade or type(trade) ~= "table" then
      return false
    end

    local key = version == "emerald" and "special:256" or "special:253"
    if tradeHooks[key] and allow[key] == tradeHooks[key] then return true end
    local original = allow[key]
    if type(original) ~= "function" then
      return false
    end

    local wrapper = function(...)
      local results = table.pack and table.pack(original(...)) or { original(...) }

      -- The vanilla special has now created the received NPC-trade Pokemon.
      local mon = trade._offered
      if opt("shiny_trades", true) and type(mon) == "table" then
        applyGen3Shiny(mon, activeGen3Game)
      end

      if table.unpack and results.n then
        return table.unpack(results, 1, results.n)
      end
      return unpack(results)
    end

    allow[key] = wrapper
    tradeHooks[key] = wrapper
    return true
  end

  -- script.command is shared across the supported engines. Let the vanilla
  -- gift command create/store the Pokemon first, then modify only that exact
  -- newly-created object. Wild encounters never pass through these commands.
  mod.hooks:wrap("script.command", function(next, ctx, name, args, ...)
    local generation = tonumber(ctx and ctx.generation) or 1

    -- Install native hooks only after the live Gen 3 scripting runtime exists.
    if generation == 3 then
      local liveGame = (ctx and ctx.game) or mod.game
      activeGen3Game = liveGame or activeGen3Game
      local save = ctx and ctx.save
      local raw = type(save) == "table" and save.gen3 or nil
      if type(raw) == "table" and raw.version == "emerald" then
        installEmeraldStarterHook()
      end
      installGen3DaycareHook()
      installGen3TradeHook(activeGen3Game, raw)
    elseif generation == 2 then
      installGen2DaycareHook()
    end

    -- Gen 1/2 in-game NPC trades use the shared `trade` script command.
    if generation ~= 3 and name == "trade" then
      local game = (ctx and ctx.game) or mod.game
      local save = (ctx and ctx.save) or (game and game.save)

      if type(save) ~= "table" or not opt("shiny_trades", true) then
        return next(ctx, name, args, ...)
      end

      local seen = snapshotMons(save)
      local result = next(ctx, name, args, ...)

      -- A successful NPC trade removes the selected party mon and inserts
      -- a newly-created received mon. Cancelled/wrong-species attempts create
      -- nothing, so firstUnseen simply returns nil.
      local mon = firstUnseen(save.party, seen)
      if mon then
        if generation == 2 then
          applyGen2Shiny(mon, game)
        else
          applyGen1Shiny(mon, game)
        end
      end

      return result
    end

    local isGift
    local crystalOddEgg = false

    if generation == 3 then
      isGift = (name == "givemon" or name == "giveegg")
    elseif generation == 2 then
      -- Crystal's one-time Odd Egg is created by `special GiveOddEgg`, not
      -- `giveegg`. The VM passes its decoded row as the fourth hook argument.
      local row = select(1, ...)
      local vm = ctx and ctx.vm
      crystalOddEgg = name == "special" and type(row) == "table"
        and type(vm) == "table" and type(vm.specialName) == "function"
        and vm:specialName(row.id) == "GiveOddEgg"
      isGift = (name == "givepoke" or name == "giveegg" or crystalOddEgg)
    else
      isGift = (name == "give_pokemon")
    end

    if not isGift then
      return next(ctx, name, args, ...)
    end

    local game = (ctx and ctx.game) or mod.game
    local save = (ctx and ctx.save) or (game and game.save)

    if type(save) ~= "table" then
      return next(ctx, name, args, ...)
    end

    local mapId = giftMapId(ctx)

    if generation == 3 then
      local seen = snapshotGen3Mons(save)
      local result = next(ctx, name, args, ...)
      local saveAfter = (ctx and ctx.save) or save
      local mon = findNewGen3Gift(saveAfter, seen)

      if mon and shouldForce(mon, generation, mapId, name) then
        applyGen3Shiny(mon, game)
      end

      return result
    end

    -- Preserve the known-working Gen 1/2 path.
    local seen = snapshotMons(save)
    local result = next(ctx, name, args, ...)

    -- Gen 2's givepoke/giveegg are party-only. Gen 1 give_pokemon may box.
    local mon = findNewGift(save, seen, generation ~= 2)

    if mon and (not crystalOddEgg or mon.isEgg)
        and shouldForce(mon, generation, mapId, name) then
      if generation == 2 then
        applyGen2Shiny(mon, game)
      else
        applyGen1Shiny(mon, game)
      end
    end

    return result
  end)
end
