--[[
   Copyright (c) The OpenRA Developers and Contributors
   This file is part of OpenRA, which is free software. It is made
   available to you under the terms of the GNU General Public License
   as published by the Free Software Foundation, either version 3 of
   the License, or (at your option) any later version. For more
   information, see COPYING.
]]

Teams = {

    Init = function(aiPlayer, humanPlayer)
        Teams.Player = aiPlayer
        Teams.Human = humanPlayer
    end;

    CreateTeam = function(trigName, team)
        print('+ CreateTeam Trig:'..trigName)
        local members = {}
        -- Recruit idle units into our team
        for type, amount in pairs(team.Units) do
            idleUnits = Utils.Where(Teams.Player.GetActorsByType(type),
                function(actor) return actor.IsIdle end)
            local some = Utils.Take(amount, idleUnits)
            for idx, actor in ipairs(some) do
                table.insert(members, actor)
            end
            print(string.format('Trig %s: Recruit %d of %d %s', trigName, #some, amount, type))
        end
        -- Give orders to the new team
        if team.Patrol then
            local path = {}
            for idx, wpNum in ipairs(team.Patrol.Waypoints) do
                local waypoint = Waypoints['waypoint'..tostring(wpNum)]
                print(string.format('Trig %s: Patrol (%d,%d)', trigName,
                    waypoint.Location.X, waypoint.Location.Y))
                table.insert(path, waypoint)
            end
            Patrol(members, path, DateTime.Seconds(6 * team.Patrol.Wait))
        elseif team.Attack_Base then
            for idx, wpNum in ipairs(team.Attack_Base.Waypoints) do
                local waypoint = Waypoints['waypoint'..tostring(wpNum)]
                print(string.format('Trig %s: Attack_Base (%d,%d)', trigName,
                    waypoint.Location.X, waypoint.Location.Y))
                Utils.Do(members, function(actor)
                    if not actor or actor.IsDead then
                        return
                    end
                    actor.AttackMove(waypoint.Location, 1)
                end)
            end
        elseif team.Attack_Units then
            for idx, wpNum in ipairs(team.Attack_Units.Waypoints) do
                local waypoint = Waypoints['waypoint'..tostring(wpNum)]
                print(string.format('Trig %s: Attack_Units (%d,%d)', trigName,
                    waypoint.Location.X, waypoint.Location.Y))
                Utils.Do(members, function(actor)
                    if not actor or actor.IsDead then
                        return
                    end
                    actor.AttackMove(waypoint.Location, 1)
                end)
            end
        elseif team.Orders then
            for idx, orderElt in ipairs(team.Orders) do
                -- Grab the first key in the table
                local order = pairs(orderElt)(orderElt)
                local arg = orderElt[order]
                print(string.format("  [%d] %s = %s", idx, order, arg))
                order = string.upper(order)
                if order == 'MOVE' then
                    ---_G not defined??
                    local waypoint = Waypoints['waypoint'..tostring(arg)]
                    print(string.format('Trig %s: Waypoint %d: (%d,%d)', trigName,
                        arg, waypoint.Location.X, waypoint.Location.Y))
                    MoveAndIdle(members, {waypoint})
                elseif order == 'ATTACK UNITS' then
                    print('TODO ATTACK UNITS')
                elseif order == 'ATTACK BASE' then
                    print('TODO ATTACK BASE')
                else
                    print(string.format('Trig %s: Unknown order %s ', trigName,
                        order))
                end
            end
        else
            print('Trig %s: WARN Team is missing orders', trigName)
        end
        print('- CreateTeam '..trigName)
    end;

    SendWaves = function(counter, Waves)
        if counter <= #Waves then
            local team = Waves[counter]

            for type, amount in pairs(team.units) do
                MoveAndHunt(Utils.Take(amount, Teams.Player.GetActorsByType(type)), team.waypoints)
            end

            Trigger.AfterDelay(DateTime.Seconds(team.delay), function() SendWaves(counter + 1, Waves) end)
        end
    end;
}

Triggers = {

    Init = function(triggers)
        for trigName, trigger in pairs(triggers) do
            print(string.format('DBG Initializing trigger %s: %s', trigName, trigger.Action))
            if trigger.Action == 'Create Team' then
                trigger.TriggerId = Trigger.AfterDelay(trigger.Interval,
                    function()
                        print(string.format('DBG Trigger %s: Creating team after %d ticks', trigName, trigger.Interval))
                        Teams.CreateTeam(trigName, trigger.Team)
                        trigger.TriggerId = nil
                    end)
            elseif trigger.Action == 'Player Enters' then
                trigger.TriggerId = Trigger.OnEnteredFootprint(trigger.CellTrigger,
                    function(actor, id)
                        if actor.Owner == Teams.Human then
                            print(string.format('DBG Trigger %s: Cell trigger ', trigName))
                            Teams.CreateTeam(trigName, trigger.Team)
                            Trigger.RemoveFootprintTrigger(id) -- One shot
                            trigger.TriggerId = nil
                        end
                end)
            else
                print(string.format('ERROR Trigger %s Unknown action %s', trigName, trigger.Action))
            end
        end
    end;
}
