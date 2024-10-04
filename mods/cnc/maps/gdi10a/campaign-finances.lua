--[[
   Copyright (c) The OpenRA Developers and Contributors
   This file is part of OpenRA, which is free software. It is made
   available to you under the terms of the GNU General Public License
   as published by the Free Software Foundation, either version 3 of
   the License, or (at your option) any later version. For more
   information, see COPYING.
]]

BankBalance = function(Player)
	return Player.Resources + Player.Cash
end

BankDeduct = function(Player, cost)
	if cost > BankBalance(Player) then
		Media.Debug(tostring(Player) .. ' cannot afford $' .. cost)
	end
	local spendRes = math.min(cost, Player.Resources)
	Player.Resources = Player.Resources - spendRes
	local spendCash = math.max(0, cost - spendRes)
	Player.Cash = Player.Cash - spendCash
end
