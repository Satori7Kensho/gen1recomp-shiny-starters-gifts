-- Shiny Starters, Gifts, NPC Trades & Day Care Eggs for Gen1Recomp v1.6.3
-- Gen 1 (Red / Blue / Yellow) + Gen 2 (Gold / Silver / Crystal)
-- + Gen 3 (FireRed / LeafGreen / Ruby / Sapphire / Emerald)
--
-- Only newly received gifts, in-game NPC trades, and Day Care eggs are touched:
--   Gen 1: give_pokemon / trade
--   Gen 2: givepoke / giveegg / Crystal Odd Egg / trade / Day Care collection
--   Gen 3: givemon / giveegg / Day Care collection
--          NPC special:253 (FRLG / Ruby / Sapphire) or :256 (Emerald)
--   Gen 3 Mystery/Event gifts and launcher Box reward eggs have separate options.
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

-- Ruby/Sapphire/Emerald share these internal species ids, which differ
-- from National Pokédex numbers.
local HOENN_STARTERS = {
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

-- Gen 3 may store the full trainer identity in otId (SID in its high half),
-- or supply otSecretId separately. Match the engine's canonical shiny check:
-- an explicit Secret ID takes precedence, including an explicit zero.
local function gen3TrainerIds(mon)
  local full = math.floor(tonumber(mon.otId or mon.trainerId) or 0) % 4294967296
  local tid = full % 65536
  local sid = math.floor(tonumber(mon.otSecretId) or math.floor(full / 65536)) % 65536
  return tid, sid
end

local function gen3ShinyXor(mon, personality)
  if type(mon) ~= "table" then return nil end
  local tid, sid = gen3TrainerIds(mon)
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
  local tid, sid = gen3TrainerIds(mon)
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
    if type(box) == "table" and type(box.mons) == "table" then
      -- PC slots are sparse. ipairs would stop at the first empty slot and
      -- let a previously owned Pokemon be mistaken for a new boxed gift.
      for _, mon in pairs(box.mons) do
        if type(mon) == "table" then seen[mon] = true end
      end
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
      help    = "Force the starter received from Oak, Elm, or Birch's bag to be shiny. Other story gifts use SHINY STORY GIFTS.",
    },
    {
      key     = "shiny_all_gifts",
      type    = "toggle",
      label   = "SHINY STORY GIFTS",
      default = true,
      help    = "Force scripted story gifts and one-time story gift eggs to be shiny. Starters, NPC trades, Mystery/Event gifts and Box rewards use their own settings.",
    },
    {
      key     = "shiny_trades",
      type    = "toggle",
      label   = "SHINY TRADES",
      default = true,
      help    = "Force Pokemon received from in-game NPC trades to be shiny (Gen 1, Gen 2, FireRed/LeafGreen, Ruby/Sapphire/Emerald).",
    },
    {
      key     = "shiny_daycare_eggs",
      type    = "toggle",
      label   = "SHINY DAY CARE EGGS",
      default = true,
      help    = "Make eggs collected from the Day Care hatch shiny in Gen 2 and Gen 3. One-time gift eggs use SHINY STORY GIFTS.",
    },
    {
      key     = "shiny_mystery_event_gifts",
      type    = "toggle",
      label   = "SHINY MYSTERY/EVENT GIFTS",
      default = true,
      help    = "Makes Pokémon and gift eggs received through Mystery Gift or Mystery Event shiny.",
    },
    {
      key     = "shiny_box_rewards",
      type    = "toggle",
      label   = "SHINY BOX REWARDS",
      default = true,
      help    = "Makes newly received Box reward eggs shiny. See README for the required setup.",
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

    -- Native save export reads the separate Secret ID field. Preserve the
    -- same full trainer identity when otId originally held both halves.
    if mon.otSecretId == nil then
      local _, sid = gen3TrainerIds(mon)
      mon.otSecretId = sid
    end

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
          and HOENN_STARTERS[tonumber(species)]
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

  -- Ruby/Sapphire's special:156 opens the starter picker, then its onDone
  -- callback calls Party.giveMonToPlayer directly before the first battle.
  -- Wrap only that picker callback; restore the shared party function even
  -- if the callback fails. Other gifts of Hoenn starter species stay gifts.
  local function wrapRubySapphireStarterChoice(game, session)
    local okChoose, choose = pcall(require, "src.ui.game3.rse.starter_choose")
    local okParty, party = pcall(require, "src.core.game3.party")
    if not okChoose or type(choose) ~= "table" or type(choose.active) ~= "function"
        or not okParty or type(party) ~= "table"
        or type(party.giveMonToPlayer) ~= "function" then
      return false
    end
    local screen = choose.active()
    if type(screen) ~= "table" or type(screen.onDone) ~= "function" then
      return false
    end

    local onDone = screen.onDone
    screen.onDone = function(...)
      local original = party.giveMonToPlayer
      party.giveMonToPlayer = function(receivingSession, species, ...)
        local code, mon, boxId, slotIdx = original(receivingSession, species, ...)
        if receivingSession == session and (code == 0 or code == 1)
            and HOENN_STARTERS[tonumber(species)] and type(mon) == "table"
            and tonumber(mon.species or mon.speciesId) == tonumber(species)
            and opt("shiny_starters", true) then
          applyGen3Shiny(mon, game)
        end
        return code, mon, boxId, slotIdx
      end

      local ok, err = pcall(onDone, ...)
      party.giveMonToPlayer = original
      if not ok then error(err, 0) end
    end
    return true
  end

  -- Gen 3 NPC trades create the received Pokémon in a native special before
  -- the trade scene transfers it. FRLG and Ruby/Sapphire use special:253;
  -- Emerald uses :256.
  -- Emerald's native module forwards to natives_trade but does not expose it
  -- through natives.MODULES, so obtain the shared trade module directly.
  local tradeHooks = {}
  local activeGen3Game = nil

  -- These engine modules also serve the launcher. Keep one wrapper per method
  -- and replace its callback when a new game loads, avoiding nested wrappers.
  local function bindEventHook(moduleName, method, callback)
    local ok, module = pcall(require, moduleName)
    if not ok or type(module) ~= "table" or type(module[method]) ~= "function" then
      return false
    end
    local key = "_shiny_starters_gifts_" .. method
    local state = module[key]
    if type(state) ~= "table" or module[method] ~= state.wrapper then
      state = { original = module[method] }
      state.wrapper = function(...) return state.callback(state.original, ...) end
      module[key] = state
      module[method] = state.wrapper
    end
    state.callback = callback
    return true
  end

  local function eventEnabled(version, launcher)
    if version ~= "ruby" and version ~= "sapphire" and version ~= "emerald"
        and version ~= "firered" and version ~= "leafgreen" then return false end
    local ok, saves = pcall(require, "src.core.SaveData")
    local loaded, settings
    if ok and type(saves.loadOptions) == "function" then
      loaded, settings = pcall(saves.loadOptions)
    end
    if loaded and type(settings) == "table" then
      if type(saves.isSafeMode) == "function" and saves.isSafeMode(settings) then return false end
      if type(saves.modEnabled) == "function"
          and saves.modEnabled(settings, "shiny_starters_gifts", version) == false then return false end
      if launcher then
        local bucket = type(settings.modOptions) == "table"
          and settings.modOptions.shiny_starters_gifts
        local value
        if type(bucket) == "table" then value = bucket.shiny_box_rewards end
        if value ~= nil then return value == true end
        return true -- same default as both option schemas
      end
    elseif launcher then
      -- A launcher claim must use the current saved settings, not a stale game.
      return false
    end
    return opt(launcher and "shiny_box_rewards" or "shiny_mystery_event_gifts", true)
  end

  -- Event eggs can start with an event OT, then take the recipient's OT when
  -- they hatch. Remember only eggs we made shiny so that this ownership change
  -- cannot undo their shininess. Lua saves and Box preserve this receipt marker.
  local EVENT_EGG_MARKER = "shiny_starters_gifts_event_egg"
  local function applyEventShiny(mon, game)
    local changed = applyGen3Shiny(mon, game)
    if changed and (mon.isEgg or mon.egg) then mon[EVENT_EGG_MARKER] = true end
    return changed
  end

  -- Desktop EXIT GAME restarts the Lua process, so the launcher cannot retain
  -- our Gifts.create wrapper. Save a receipt boundary before leaving, then
  -- recognize only new reward eggs actually withdrawn to this exact save.
  -- Box's departure record proves the egg's identity; a species/OT guess would
  -- also affect existing gifts or imported Pokemon. Never rewrite Box storage.
  local BOX_RECEIPTS_KEY = "box_reward_receipts"
  local function receiveBoxRewards(save, loading)
    local version = type(save) == "table" and save.version
    if version ~= "ruby" and version ~= "sapphire" and version ~= "emerald"
        and version ~= "firered" and version ~= "leafgreen" then return end
    local okS, saves = pcall(require, "src.core.SaveData")
    local okB, store = pcall(require, "src.box.Store")
    local okR, records = pcall(require, "src.box.Records")
    if not okS or not okB or not okR or type(saves.persistenceFs) ~= "function"
        or type(saves.saveFilename) ~= "function" or type(store.load) ~= "function"
        or type(records.identity) ~= "function" then return end
    local okFs, fs = pcall(saves.persistenceFs)
    if not okFs or type(fs) ~= "table" then return end
    local okState, state = pcall(store.load, fs)
    local okPath, path = pcall(saves.saveFilename, version)
    if not okState or type(state) ~= "table" or type(state.nextId) ~= "number"
        or not okPath or type(path) ~= "string" then return end

    save.modData = type(save.modData) == "table" and save.modData or {}
    local bucket = save.modData.shiny_starters_gifts
    if type(bucket) ~= "table" then bucket = {}; save.modData.shiny_starters_gifts = bucket end
    local receipts = bucket[BOX_RECEIPTS_KEY]
    local previouslyEnabled = false
    for _, entry in ipairs(save.meta and save.meta.mods or {}) do
      if type(entry) == "table" and entry.id == "shiny_starters_gifts" then
        previouslyEnabled = true
        break
      end
    end
    if type(receipts) ~= "table" or type(receipts.sinceId) ~= "number"
        or type(receipts.handled) ~= "table" or (loading and not previouslyEnabled) then
      bucket[BOX_RECEIPTS_KEY] = { sinceId = state.nextId, handled = {} }
      return -- existing rewards precede activation; do not change them
    end

    local function findEgg(identity)
      local function visit(list)
        for _, mon in pairs(type(list) == "table" and list or {}) do
          if type(mon) == "table" and (mon.isEgg or mon.egg)
              and records.identity(3, mon) == identity then return mon end
        end
      end
      local mon = visit(save.party)
      if mon then return mon end
      for _, box in pairs(save.storage and save.storage.boxes or {}) do
        if type(box) == "table" then
          mon = visit(box.mons)
          if mon then return mon end
        end
      end
    end
    for _, departure in pairs(state.departures or {}) do
      local entry = type(departure) == "table" and departure.entry
      if type(entry) == "table" and entry.generation == 3
          and type(entry.id) == "number" and entry.id >= receipts.sinceId
          and type(entry.gift) == "number" and entry.gift >= 1 and entry.gift <= 4
          and departure.path == path and type(departure.identity) == "string"
          and records.identity(3, entry.mon) == departure.identity then
        local key = tostring(entry.id) .. "|" .. departure.identity
        if not receipts.handled[key] then
          local mon = findEgg(departure.identity)
          if mon and (not opt("shiny_box_rewards", true)
              or applyEventShiny(mon, mod.game)) then
            receipts.handled[key] = true
          end
        end
      end
    end
  end

  if mod.events and type(mod.events.on) == "function" then
    mod.events:on("save.loading", function(ev)
      if type(ev) == "table" then receiveBoxRewards(ev.raw, true) end
    end)
    mod.events:on("save.writing", function(ev)
      if type(ev) == "table" then receiveBoxRewards(ev.save, false) end
    end)
  end

  local function forceNewEventMons(session, seen)
    local function visit(list)
      for _, mon in pairs(type(list) == "table" and list or {}) do
        if type(mon) == "table" and not seen[mon] then
          applyEventShiny(mon, activeGen3Game or mod.game)
        end
      end
    end
    visit(session.party)
    for _, box in pairs(session.storage and session.storage.boxes or {}) do
      if type(box) == "table" then visit(box.mons) end
    end
  end

  local gen3EventHooksInstalled = false
  local function installGen3EventHooks()
    if gen3EventHooksInstalled then return end
    bindEventHook("src.core.game3.mystery_gift", "deliverGift", function(original, session, ...)
      local seen = snapshotGen3Mons({ gen3 = session })
      local result = original(session, ...)
      -- DELIVER_GIVEN is 1. Items/tickets create no new Pokemon to visit.
      if result == 1 and type(session) == "table" and eventEnabled(session.version) then
        forceNewEventMons(session, seen)
      end
      return result
    end)
    bindEventHook("src.core.game3.rs.mystery_event", "run", function(original, bytes, session, ...)
      local seen = snapshotGen3Mons({ gen3 = session })
      local result = original(bytes, session, ...)
      if type(result) == "table" and result.valid and result.save
          and type(session) == "table" and eventEnabled(session.version) then
        forceNewEventMons(session, seen)
      end
      return result
    end)
    bindEventHook("src.box.Gifts", "create", function(original, version, ...)
      local mon, seedOrError = original(version, ...)
      if type(mon) == "table" and eventEnabled(version, true) then
        -- Preserve Box's local RNG and native event metadata. No game stat
        -- refresh is needed for an offline egg from another game's catalog.
        applyEventShiny(mon, nil)
      end
      return mon, seedOrError
    end)
    bindEventHook("src.core.game3.breeding", "hatchMon", function(original, session, mon, ...)
      local receivedShinyEgg = type(mon) == "table" and mon[EVENT_EGG_MARKER]
        and (mon.isEgg or mon.egg)
      local result = original(session, mon, ...)
      if receivedShinyEgg and type(result) == "table" and not result.isEgg and not result.egg then
        -- A received shiny stays shiny even if the option is later turned off.
        applyGen3Shiny(result, activeGen3Game or mod.game)
        result[EVENT_EGG_MARKER] = nil
      end
      return result
    end)
    gen3EventHooksInstalled = true
  end

  local function isEventScript(ctx)
    local vm = ctx and (ctx.vm or ctx.runner)
    local raw = type(vm) == "table" and vm.ctx
    if type(raw) ~= "table" then return false end
    local function eventKey(key)
      return type(key) == "string" and (key:sub(1, 6) == "rsram:"
        or key:sub(1, 8) == "rsevent:")
    end
    if raw.rsRamSession or eventKey(vm._scriptKey) or eventKey(raw.pc and raw.pc.listKey) then
      return true
    end
    for _, frame in ipairs(raw.stack or {}) do
      if eventKey(frame.listKey) then return true end
    end
    return false
  end
  -- The Gen 3 Day Care uses a native special rather than the script giveegg
  -- command. FRLG and Ruby/Sapphire/Emerald share this collection function.
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
          and (version == "firered" or version == "leafgreen" or version == "emerald"
            or version == "ruby" or version == "sapphire")
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
    if version ~= "emerald" and version ~= "firered" and version ~= "leafgreen"
        and version ~= "ruby" and version ~= "sapphire" then
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
      installGen3EventHooks()
      local save = ctx and ctx.save
      local raw = type(save) == "table" and save.gen3 or nil
      if type(raw) == "table" and raw.version == "emerald" then
        installEmeraldStarterHook()
      end
      installGen3DaycareHook()
      installGen3TradeHook(activeGen3Game, raw)

      -- The native opens the screen synchronously, but gives the starter
      -- later. Wrap its live callback after the original special has run.
      if type(raw) == "table" and (raw.version == "ruby" or raw.version == "sapphire")
          and name == "special" and type(args) == "table"
          and tonumber(args.id or args[1]) == 156 then
        local result = next(ctx, name, args, ...)
        wrapRubySapphireStarterChoice(activeGen3Game, raw)
        return result
      end
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
      local vm = ctx and (ctx.vm or ctx.runner)
      if type(vm) == "table" and type(vm.ctx) == "table" and vm.ctx.rsRamSession then
        -- Immediate RS event scripts can operate on a detached session. Their
        -- enclosing event.run wrapper handles gifts after successful validation.
        return next(ctx, name, args, ...)
      end
      local eventScript = isEventScript(ctx)
      local seen = snapshotGen3Mons(save)
      local result = next(ctx, name, args, ...)
      local saveAfter = (ctx and ctx.save) or save
      local mon = findNewGen3Gift(saveAfter, seen)

      if mon then
        if eventScript then
          if opt("shiny_mystery_event_gifts", true) then applyEventShiny(mon, game) end
        elseif shouldForce(mon, generation, mapId, name) then
          applyGen3Shiny(mon, game)
        end
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

  -- Mystery delivery and the Box launcher can run before any script command.
  -- Gen 1/2 boots still avoid loading the Gen 3 engine modules.
  if mod.game and (tonumber(mod.game.generation) == 3
      or (mod.game.data and mod.game.data.gen3Pokemon)) then
    activeGen3Game = mod.game
    installGen3EventHooks()
  end
end
