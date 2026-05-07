local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local CombatConfig = require(ReplicatedStorage.Modules.CombatConfig)

local remotesFolder = ReplicatedStorage:FindFirstChild("Remotes")
if not remotesFolder then
	remotesFolder = Instance.new("Folder")
	remotesFolder.Name = "Remotes"
	remotesFolder.Parent = ReplicatedStorage
end

local punchRemote = remotesFolder:FindFirstChild("PunchRequest")
if not punchRemote then
	punchRemote = Instance.new("RemoteEvent")
	punchRemote.Name = "PunchRequest"
	punchRemote.Parent = remotesFolder
end

local lastPunchTimes = {}

local function getCharacterParts(player)
	local character = player.Character
	if not character then
		return nil
	end

	local humanoid = character:FindFirstChildOfClass("Humanoid")
	local rootPart = character:FindFirstChild("HumanoidRootPart")

	if not humanoid or not rootPart then
		return nil
	end

	if humanoid.Health <= 0 then
		return nil
	end

	return character, humanoid, rootPart
end

local function awardKill(attacker)
	local leaderstats = attacker:FindFirstChild("leaderstats")
	if not leaderstats then
		return
	end

	local kills = leaderstats:FindFirstChild("Kills")
	if kills then
		kills.Value += 1
	end
end

local function findPunchTarget(attacker)
	local attackerCharacter, attackerHumanoid, attackerRoot = getCharacterParts(attacker)
	if not attackerCharacter or not attackerHumanoid or not attackerRoot then
		return nil
	end

	local bestTargetHumanoid = nil
	local bestTargetPlayer = nil
	local bestDistance = CombatConfig.PunchRange

	for _, possibleTarget in Players:GetPlayers() do
		if possibleTarget ~= attacker then
			local targetCharacter, targetHumanoid, targetRoot = getCharacterParts(possibleTarget)

			if targetCharacter and targetHumanoid and targetRoot then
				local offset = targetRoot.Position - attackerRoot.Position
				local distance = offset.Magnitude

				if distance <= CombatConfig.PunchRange then
					local directionToTarget = offset.Unit
					local facingDirection = attackerRoot.CFrame.LookVector
					local dot = facingDirection:Dot(directionToTarget)

					if dot >= CombatConfig.PunchAngle and distance < bestDistance then
						bestDistance = distance
						bestTargetHumanoid = targetHumanoid
						bestTargetPlayer = possibleTarget
					end
				end
			end
		end
	end

	return bestTargetHumanoid, bestTargetPlayer
end

local function canPunch(player)
	local now = os.clock()
	local lastPunchTime = lastPunchTimes[player]

	if lastPunchTime and now - lastPunchTime < CombatConfig.PunchCooldown then
		return false
	end

	lastPunchTimes[player] = now
	return true
end

punchRemote.OnServerEvent:Connect(function(player)
	if not canPunch(player) then
		return
	end

	local targetHumanoid, targetPlayer = findPunchTarget(player)
	if not targetHumanoid or not targetPlayer then
		return
	end

	local healthBeforeDamage = targetHumanoid.Health

	targetHumanoid:TakeDamage(CombatConfig.PunchDamage)

	if healthBeforeDamage > 0 and healthBeforeDamage <= CombatConfig.PunchDamage then
		awardKill(player)
	end
end)

Players.PlayerRemoving:Connect(function(player)
	lastPunchTimes[player] = nil
end)

print("Combat server loaded")