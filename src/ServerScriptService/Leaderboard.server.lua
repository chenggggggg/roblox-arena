local Players = game:GetService("Players")

local function createLeaderstats(player)
	local leaderstats = Instance.new("Folder")
	leaderstats.Name = "leaderstats"
	leaderstats.Parent = player

	local kills = Instance.new("IntValue")
	kills.Name = "Kills"
	kills.Value = 0
	kills.Parent = leaderstats

	local deaths = Instance.new("IntValue")
	deaths.Name = "Deaths"
	deaths.Value = 0
	deaths.Parent = leaderstats
end

local function setupCharacterDeathTracking(player, character)
	local humanoid = character:WaitForChild("Humanoid")

	humanoid.Died:Connect(function()
		local leaderstats = player:FindFirstChild("leaderstats")
		if not leaderstats then
			return
		end

		local deaths = leaderstats:FindFirstChild("Deaths")
		if deaths then
			deaths.Value += 1
		end
	end)
end

Players.PlayerAdded:Connect(function(player)
	createLeaderstats(player)

	player.CharacterAdded:Connect(function(character)
		setupCharacterDeathTracking(player, character)
	end)
end)