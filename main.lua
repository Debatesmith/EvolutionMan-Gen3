-- Evolution Man: FireRed v1.0.0
-- Adds a Gentleman to Celadon Dept. Store 2F who performs native trade
-- evolutions for P2000 without requiring a link partner.

return function(mod)
  local serviceSource = assert(mod:read("evolution_service.lua"))
  local Service = assert(load(serviceSource,
    "@firered_evolution_man/evolution_service.lua"))()

  local Runtime = require("src.core.game3.runtime")
  local Map = require("src.core.game3.map")
  local Collision = require("src.core.game3.collision")
  local Objects = require("src.core.game3.objects")
  local Player = require("src.core.game3.player")
  local Evolution = require("src.core.game3.evolution")
  local EvolutionScene = require("src.ui.game3.evolution_scene")
  local PartyMenu = require("src.ui.game3.party_menu")
  local Message = require("src.ui.game3.message")
  local Choice = require("src.ui.game3.choice")
  local Audio = require("src.core.game3.audio")

  local MAP_ID = "FR_CELADON_CITY_DEPARTMENT_STORE_2F"
  local LOCAL_ID = 240
  local MARKER = "__fireredEvolutionMan"
  local SCRIPT_KEY = "firered_evolution_man:talk"
  local GENTLEMAN_GFX = 61

  -- The center aisle of Celadon 2F. Each candidate is checked against the
  -- active ROM-derived collision map and every live event object before use.
  local CANDIDATES = {
    { 4, 6 }, { 5, 6 }, { 6, 6 },
    { 4, 7 }, { 5, 7 }, { 6, 7 },
    { 4, 8 }, { 5, 8 }, { 6, 8 },
    { 4, 10 }, { 6, 10 },
  }

  local function logInfo(text)
    if mod.log and mod.log.info then mod.log:info(text) end
  end

  local function logWarn(text)
    if mod.log and mod.log.warn then mod.log:warn(text) end
  end

  local function session()
    return Runtime.getSession and Runtime.getSession() or nil
  end

  local function isOurs(target)
    return target and target.def and
      (target.def[MARKER] == true or target.def.scriptKey == SCRIPT_KEY)
  end

  local function eventAt(mapDef, x, y)
    local Space = package.loaded["src.core.game3.scripting.space"]
    local bundle = Space and Space.bundle
    local ev = bundle and bundle.events and bundle.events[MAP_ID]
    for _, row in ipairs((ev and ev.warps) or
        (mapDef and mapDef.warps) or {}) do
      if tonumber(row.x) == x and tonumber(row.y) == y then return true end
    end
    for _, row in ipairs((ev and ev.coordEvents) or
        (mapDef and mapDef.coordEvents) or {}) do
      if tonumber(row.x) == x and tonumber(row.y) == y then return true end
    end
    return false
  end

  local function freeTalkableCell(game, mapDef, x, y)
    if Objects.at(x, y) or eventAt(mapDef, x, y) then return false end
    local elevation = Collision.elevationAt and Collision.elevationAt(x, y)
    local ok = Collision.canEnter(game, x, y, { elevation = elevation })
    if not ok then return false end

    local neighbors = {
      { x, y + 1 }, { x, y - 1 }, { x + 1, y }, { x - 1, y },
    }
    for _, cell in ipairs(neighbors) do
      local nx, ny = cell[1], cell[2]
      local ne = Collision.elevationAt and Collision.elevationAt(nx, ny)
      if Collision.canEnter(game, nx, ny, { elevation = ne }) then
        return true
      end
    end
    return false
  end

  local function findLocalId()
    if not Objects.find(LOCAL_ID) then
      local used = false
      for _, def in ipairs(Objects._defs or {}) do
        if tonumber(def.localId or def.index) == LOCAL_ID then
          used = true
          break
        end
      end
      if not used then return LOCAL_ID end
    end
    for id = 239, 200, -1 do
      local used = Objects.find(id) ~= nil
      if not used then
        for _, def in ipairs(Objects._defs or {}) do
          if tonumber(def.localId or def.index) == id then
            used = true
            break
          end
        end
      end
      if not used then return id end
    end
    return nil
  end

  local function installNpc(game, reason)
    local save = session()
    if not save or save.map ~= MAP_ID or Objects._mapId ~= MAP_ID then
      return false
    end

    for _, target in ipairs(Objects.forDraw()) do
      if isOurs(target) then return true end
    end
    for _, def in ipairs(Objects._defs or {}) do
      if def[MARKER] or def.scriptKey == SCRIPT_KEY then
        return Objects.addObject(tonumber(def.localId or def.index))
      end
    end

    local mapDef = Map.currentDef and Map.currentDef() or nil
    local x, y
    for _, cell in ipairs(CANDIDATES) do
      if freeTalkableCell(game, mapDef, cell[1], cell[2]) then
        x, y = cell[1], cell[2]
        break
      end
    end
    if not x then
      logWarn("Evolution Man: no verified free cell on Celadon Dept. Store 2F")
      return false
    end

    local localId = findLocalId()
    if not localId then
      logWarn("Evolution Man: no free FireRed local object id")
      return false
    end

    local def = {
      localId = localId,
      index = localId,
      kind = 0,
      x = x,
      y = y,
      elevation = Collision.elevationAt and Collision.elevationAt(x, y) or 3,
      graphics = GENTLEMAN_GFX,
      graphicsId = GENTLEMAN_GFX,
      sprite = "SPRITE_GENTLEMAN",
      movement = "STAY",
      movementType = 8,
      range = "DOWN",
      rangeX = 0,
      rangeY = 0,
      trainerType = 0,
      trainerRange = 0,
      sight = 0,
      flag = 0,
      scriptKey = SCRIPT_KEY,
      [MARKER] = true,
    }
    table.insert(Objects._defs, def)
    if not Objects.addObject(localId) then
      table.remove(Objects._defs)
      logWarn("Evolution Man: FireRed event-object spawn failed")
      return false
    end

    logInfo(("Evolution Man: spawned at %s (%d,%d) [%s]")
      :format(MAP_ID, x, y, tostring(reason or "unknown")))
    return true
  end

  local function say(text, done)
    Message.show(text, { session = session(), done = done })
  end

  local function finish(text)
    say(text)
  end

  local function startEvolution(mon, previewTarget)
    local save = session()
    if not save or not Service.canAfford(save) then
      finish("Looks like you're short on cash.")
      return false
    end

    local currentTarget = Service.previewTarget(Evolution, mon, save)
    if not currentTarget or currentTarget ~= previewTarget then
      finish("That one won't evolve that way!")
      return false
    end

    local ok, started = pcall(EvolutionScene.start, mon, currentTarget, {
      canStop = false,
      session = save,
      bag = save.bag,
      savedSong = Audio._mapSong,
      via = "trade",
      onDone = function(result)
        if result == "evolved" then
          finish("There you go! Take good care of it!")
        else
          finish("Huh? Something interrupted the evolution.")
        end
      end,
    })
    if not ok or not started then
      logWarn("Evolution Man: native evolution scene failed to start: " ..
        tostring(started))
      finish("Sorry--I couldn't start the evolution.")
      return false
    end

    -- Commit FireRed's trade side effects only after the scene exists. This
    -- consumes a matching held trade item; ordinary trade evolutions do not
    -- touch the held item. Payment is committed at the same safe boundary.
    local committedTarget = Evolution.tradeTarget(mon, save)
    if committedTarget ~= currentTarget then
      logWarn("Evolution Man: trade target changed during scene startup")
    end
    Service.charge(save)
    return true
  end

  local function choosePokemon()
    local save = session()
    if not save or type(save.party) ~= "table" or #save.party == 0 then
      finish("You don't have a POKéMON with you!")
      return
    end

    PartyMenu.show(save.party, save.move_overlay or save.moveOverlay, {
      mode = "choose",
      session = save,
      bag = save.bag,
      onSelect = function(_, mon)
        if not mon then
          finish("Suit yourself.")
          return
        end
        local target = Service.previewTarget(Evolution, mon, save)
        if not target then
          finish("That one won't evolve that way!")
          return
        end
        if not Service.canAfford(save) then
          finish("Looks like you're short on cash.")
          return
        end
        say("Here we go!", function()
          startEvolution(mon, target)
        end)
      end,
    })
  end

  local function offer(game, target)
    local save = session()
    if not save then return end
    Objects.facePlayer(target.localId, game)
    say("Yo! I can trigger a TRADE evolution right here--no link cable needed! Only ¥2000.",
      function()
        if not Service.canAfford(save) then
          finish("Come back when you've got ¥2000!")
          return
        end
        say("Want me to do it? It's ¥2000 a pop.", function()
          Choice.yesNo(function(yes)
            Message.close()
            if yes then choosePokemon() else finish("Suit yourself.") end
          end)
        end)
      end)
  end

  mod.hooks:wrap("world.talk", function(next, game, target)
    if isOurs(target) then
      offer(game, target)
      return true
    end
    return next(game, target)
  end)

  mod.events:on("map.entered", function(payload)
    if payload and payload.mapId == MAP_ID then
      installNpc(Runtime._game, "map_entered")
    end
  end)

  mod.events:on("map.reloaded", function(payload)
    if payload and payload.mapId == MAP_ID then
      installNpc(Runtime._game, "map_reloaded")
    end
  end)

  mod.events:on("game.ready", function(payload)
    local game = payload and payload.game or Runtime._game
    if session() and session().map == MAP_ID then
      installNpc(game, "game_ready")
    end
  end)

  logInfo("Evolution Man: FireRed v1.0.0 loaded (service fee ¥2000)")
end
