function TableConcat(t1,t2)
    for i=1,#t2 do
        t1[#t1+i] = t2[i]
    end
    return t1
end

-- split string by seperator
function split(inputstr, sep)
        if sep == nil then
                sep = "%s"
        end
        local t={}
        for str in string.gmatch(inputstr, "([^"..sep.."]+)") do
                table.insert(t, str)
        end
        return t
end


-- local shop position
shop_pos = {x=0,y=0}

-- force objects
fA = nil
fB = nil

-- all saved positions
positions = {}

-- set default non-shop members
script.on_init(function()
	for i=4, #game.forces do
		global[game.forces[i].name] = false
	end
end)

-- close or open shop to can be invited by other players
commands.add_command("close_shop",
[[true/false]],
function(command)
	invoker = game.get_player(command.player_index)

	str2bool = { ["false"] = false, ["true"] = true  }
	is_close = str2bool[command.parameter]
	if command.parameter == nil then
		if global[invoker.force.name] == nil then
			global[invoker.force.name] = true
			invoker.print("Shop closed")
			return
		end

		is_close = not global[invoker.force.name]
	end

	if is_close then
		global[invoker.force.name] = true
		invoker.print("Shop closed")
	else
		global[invoker.force.name] = false
		invoker.print("Shop opened, everyone can call you")
	end
end)

-- start shop session by forceA and forceB
commands.add_command("start_shop",
[[forceA forceB]],
function(command)
	invoker = game.get_player(command.player_index)
	if fA ~= nil or fB ~= nil then
	 	invoker.print("Shop point in occupied by forces \""..fA.name.."\" and \""..fB.name.."\"")
		return
	end

	if command.parameter == nil or command.parameter == '' then
		invoker.print("Use this command with two force names")
		return
	end

	parameter = split(command.parameter, ' ')
	fA = game.forces[parameter[1]]
	fB = game.forces[parameter[2]]
	if fA == nil or fB == nil then
		invoker.print("One of entered forces doesn't exist")
		fA = nil
		fB = nil
		return
	end
	if global[fA.name] == nil or global[fB.name] == nil 
		or global[fA.name] or global[fB.name] then
		fA = nil
		fB = nil
		invoker.print("One or more of selected teams are member of non-shop list")
		return
	end

	game.print("Forces \""..fA.name.."\" and \""..fB.name.."\" enter the shop.")

	fA.set_friend(fB, true)
	fB.set_friend(fA, true)
	fA.set_cease_fire(fB, true)
	fB.set_cease_fire(fA, true)

	players = TableConcat(fA.players, fB.players)
	for i=1, #players do
		table.insert(positions, {players[i].name, players[i].position})
		players[i].teleport({shop_pos.x + i,shop_pos.y})
	end
end)

-- end shop session
commands.add_command("end_shop",
nil,
function(command)
	invoker = game.get_player(command.player_index)
	if invoker.force ~= fA and invoker.force ~= fB then
		invoker.print("Only shop members can end_shop")
		return
	end

	game.print("Shop point was freed.")
	for i=1, #positions do
		game.get_player(positions[i][1]).teleport(positions[i][2])
	end

	fA.set_friend(fB, false)
	fB.set_friend(fA, false)
	fA.set_cease_fire(fB, false)
	fB.set_cease_fire(fA, false)
	fA = nil
	fB = nil
	positions = {}
end)

-- set new shop position for force
commands.add_command("set_shop",
nil,
function(command)
	invoker = game.get_player(command.player_index)
	if not invoker.admin then
		invoker.print("Only admin can change shop point")
		return
	end
	shop_pos = invoker.position
	game.print("Shop position now setted to:")
	game.print(shop_pos)
end)
