local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

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

local matchKillAwardedEvent = ServerScriptService:FindFirstChild("MatchKillAwarded")
if not matchKillAwardedEvent then
	matchKillAwardedEvent = Instance.new("BindableEvent")
	matchKillAwardedEvent.Name = "MatchKillAwarded"
	matchKillAwardedEvent.Parent = ServerScriptService
end

local canDamagePlayerFunction = ServerScriptService:FindFirstChild("CanDamagePlayer")
if not canDamagePlayerFunction then
	canDamagePlayerFunction = Instance.new("BindableFunction")
	canDamagePlayerFunction.Name = "CanDamagePlayer"
	canDamagePlayerFunction.Parent = ServerScriptService
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

local function canPunch(player)
	local now = os.clock()
	local lastPunchTime = lastPunchTimes[player]

	if lastPunchTime and now - lastPunchTime < CombatConfig.PunchCooldown then
		return false
	end

	lastPunchTimes[player] = now
	return true
end

local function canDamagePlayer(attacker, target)
	local success, result = pcall(function()
		return canDamagePlayerFunction:Invoke(attacker, target)
	end)

	if not success then
		return false
	end

	return result == true
end

local function isBetterPunchTarget(attackerRoot, targetRoot, bestDistance)
	local offset = targetRoot.Position - attackerRoot.Position
	local distance = offset.Magnitude

	if distance > CombatConfig.PunchRange or distance >= bestDistance then
		return false, distance
	end

	local directionToTarget = offset.Unit
	local facingDirection = attackerRoot.CFrame.LookVector
	local dot = facingDirection:Dot(directionToTarget)

	return dot >= CombatConfig.PunchAngle, distance
end

local function findDamageablePunchTarget(attacker)
	local attackerCharacter, attackerHumanoid, attackerRoot = getCharacterParts(attacker)
	if not attackerCharacter or not attackerHumanoid or not attackerRoot then
		return nil
	end

	local bestTargetHumanoid = nil
	local bestTargetPlayer = nil
	local bestDistance = CombatConfig.PunchRange

	for _, possibleTarget in Players:GetPlayers() do
		if possibleTarget ~= attacker and canDamagePlayer(attacker, possibleTarget) then
			local targetCharacter, targetHumanoid, targetRoot = getCharacterParts(possibleTarget)

			if targetCharacter and targetHumanoid and targetRoot then
				local isBetterTarget, distance = isBetterPunchTarget(attackerRoot, targetRoot, bestDistance)

				if isBetterTarget then
					bestDistance = distance
					bestTargetHumanoid = targetHumanoid
					bestTargetPlayer = possibleTarget
				end
			end
		end
	end

	return bestTargetHumanoid, bestTargetPlayer
end

punchRemote.OnServerEvent:Connect(function(player)
	if not canPunch(player) then
		return
	end

	local targetHumanoid, targetPlayer = findDamageablePunchTarget(player)
	if not targetHumanoid or not targetPlayer then
		return
	end

	local healthBeforeDamage = targetHumanoid.Health

	targetHumanoid:TakeDamage(CombatConfig.PunchDamage)

	if healthBeforeDamage > 0 and healthBeforeDamage <= CombatConfig.PunchDamage then
		awardKill(player)
		matchKillAwardedEvent:Fire(player, targetPlayer)
	end
end)

Players.PlayerRemoving:Connect(function(player)
	lastPunchTimes[player] = nil
end)

print("Combat server loaded")
