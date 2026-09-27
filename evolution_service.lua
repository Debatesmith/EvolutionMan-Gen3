local Service = {}

Service.COST = 2000

function Service.previewTarget(Evolution, mon, session)
  if not (Evolution and mon) then return nil end
  local target = Evolution.targetSpecies(
    mon, Evolution.EVO_MODE_TRADE, nil)
  target = tonumber(target) or 0
  if target == 0 then return nil end
  if Evolution.nationalAllows
      and not Evolution.nationalAllows(target, session) then
    return nil
  end
  return target
end

function Service.canAfford(session)
  return (tonumber(session and session.money) or 0) >= Service.COST
end

function Service.charge(session)
  if not Service.canAfford(session) then return false end
  session.money = math.max(0,
    math.floor(tonumber(session.money) or 0) - Service.COST)
  return true
end

return Service
