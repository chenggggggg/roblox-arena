local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")
local ServerScriptService = game:GetService("ServerScriptService")

local MatchmakingConfig = require(ReplicatedStorage.Modules.MatchmakingConfig)

local TEST_MATCH_MODES = MatchmakingConfig.TestMatchModes
local QUEUE_OPTIONS = MatchmakingConfig.QueueOptions
local GAME_MODES = MatchmakingConfig.GameModes
local PRACTICE_MODES = MatchmakingConfig.PracticeModes

local playerLocations = {}
local activeCountdowns = {}
local activeMatches = {}
local matchScores = {}
local queuedModes = {}
local queuedDisplays = {}
local matchmakingQueues = {}
local TEST_MATCH_DURATION_SECONDS = MatchmakingConfig.TestMatchDurationSeconds
local COUNTDOWN_SECONDS = MatchmakingConfig.CountdownSeconds
local PLAYERS_PER_TEST_MATCH = MatchmakingConfig.PlayersPerTestMatch
local TDM_PLAYERS_PER_TEAM = MatchmakingConfig.TDMPlayersPerTeam
local KILLS_TO_WIN = MatchmakingConfig.KillsToWin
local POST_MATCH_RETURN_SECONDS = MatchmakingConfig.PostMatchReturnSeconds
local endMatch

local remotesFolder = ReplicatedStorage:FindFirstChild("Remotes")
if not remotesFolder then
	remotesFolder = Instance.new("Folder")
	remotesFolder.Name = "Remotes"
	remotesFolder.Parent = ReplicatedStorage
end

local joinTestMatchRemote = remotesFolder:FindFirstChild("JoinTestMatch")
if not joinTestMatchRemote then
	joinTestMatchRemote = Instance.new("RemoteEvent")
	joinTestMatchRemote.Name = "JoinTestMatch"
	joinTestMatchRemote.Parent = remotesFolder
end

local returnToLobbyRemote = remotesFolder:FindFirstChild("ReturnToLobby")
if not returnToLobbyRemote then
	returnToLobbyRemote = Instance.new("RemoteEvent")
	returnToLobbyRemote.Name = "ReturnToLobby"
	returnToLobbyRemote.Parent = remotesFolder
end

local joinPracticeModeRemote = remotesFolder:FindFirstChild("JoinPracticeMode")
if not joinPracticeModeRemote then
	joinPracticeModeRemote = Instance.new("RemoteEvent")
	joinPracticeModeRemote.Name = "JoinPracticeMode"
	joinPracticeModeRemote.Parent = remotesFolder
end

local cancelQueueRemote = remotesFolder:FindFirstChild("CancelQueue")
if not cancelQueueRemote then
	cancelQueueRemote = Instance.new("RemoteEvent")
	cancelQueueRemote.Name = "CancelQueue"
	cancelQueueRemote.Parent = remotesFolder
end

local matchStatusUpdateRemote = remotesFolder:FindFirstChild("MatchStatusUpdate")
if not matchStatusUpdateRemote then
	matchStatusUpdateRemote = Instance.new("RemoteEvent")
	matchStatusUpdateRemote.Name = "MatchStatusUpdate"
	matchStatusUpdateRemote.Parent = remotesFolder
end

local matchScoreUpdateRemote = remotesFolder:FindFirstChild("MatchScoreUpdate")
if not matchScoreUpdateRemote then
	matchScoreUpdateRemote = Instance.new("RemoteEvent")
	matchScoreUpdateRemote.Name = "MatchScoreUpdate"
	matchScoreUpdateRemote.Parent = remotesFolder
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

local function setPlayerLocation(player, locationName)
	playerLocations[player.UserId] = locationName
	print(player.Name .. " is now in " .. locationName .. ".")
end

local function resetMatchScore(player)
	matchScores[player.UserId] = {
		kills = 0,
		deaths = 0,
	}

	matchScoreUpdateRemote:FireClient(player, matchScores[player.UserId])
end

local function fireScoreUpdate(player, matchState)
	local score = matchScores[player.UserId]
	if not score then
		return
	end

	if matchState and matchState.gameModeName == "TDM" then
		matchScoreUpdateRemote:FireClient(player, {
			kills = score.kills,
			deaths = score.deaths,
			gameModeName = "TDM",
			teamName = matchState.playerTeams[player.UserId],
			redScore = matchState.teamScores.Red,
			blueScore = matchState.teamScores.Blue,
		})
	else
		matchScoreUpdateRemote:FireClient(player, score)
	end
end

local function fireScoreUpdateToMatch(matchState)
	for _, player in matchState.players do
		if player.Parent == Players then
			fireScoreUpdate(player, matchState)
		end
	end
end

local function addMatchDeath(player)
	local score = matchScores[player.UserId]
	if not score then
		return
	end

	score.deaths += 1
	fireScoreUpdate(player, activeMatches[player.UserId])
end

local function addMatchKill(attacker, target)
	local attackerScore = matchScores[attacker.UserId]
	if not attackerScore then
		return
	end

	if not activeMatches[attacker.UserId] or not activeMatches[target.UserId] then
		return
	end

	if activeMatches[attacker.UserId] ~= activeMatches[target.UserId] then
		return
	end

	if playerLocations[attacker.UserId] ~= playerLocations[target.UserId] then
		return
	end

	local matchState = activeMatches[attacker.UserId]
	attackerScore.kills += 1

	if matchState and matchState.gameModeName == "TDM" then
		local attackerTeam = matchState.playerTeams[attacker.UserId]
		if not attackerTeam then
			return
		end

		matchState.teamScores[attackerTeam] += 1
		fireScoreUpdateToMatch(matchState)

		if matchState.teamScores[attackerTeam] >= KILLS_TO_WIN then
			endMatch(matchState, attackerTeam .. " team reached " .. KILLS_TO_WIN .. " kills.")
		end
	else
		fireScoreUpdate(attacker, matchState)

		if matchState and attackerScore.kills >= KILLS_TO_WIN then
			endMatch(matchState, attacker.Name .. " reached " .. KILLS_TO_WIN .. " kills.")
		end
	end
end

local function canDamagePlayer(attacker, target)
	if playerLocations[attacker.UserId] == "WildernessPractice" and playerLocations[target.UserId] == "WildernessPractice" then
		return true
	end

	if not activeMatches[attacker.UserId] or not activeMatches[target.UserId] then
		return false
	end

	if activeMatches[attacker.UserId] ~= activeMatches[target.UserId] then
		return false
	end

	if playerLocations[attacker.UserId] ~= playerLocations[target.UserId] then
		return false
	end

	local matchState = activeMatches[attacker.UserId]
	if matchState.gameModeName == "TDM" and matchState.playerTeams[attacker.UserId] == matchState.playerTeams[target.UserId] then
		return false
	end

	return true
end

local teleportPlayerToTestArena
local teleportPlayerToPracticeMap
local teleportPlayerToLobby

local TEAM_COLORS = {
	Red = Color3.fromRGB(255, 70, 70),
	Blue = Color3.fromRGB(70, 140, 255),
}

local function clearTeamIndicator(player)
	local character = player.Character
	if not character then
		return
	end

	local existingHighlight = character:FindFirstChild("TDMTeamHighlight")
	if existingHighlight then
		existingHighlight:Destroy()
	end
end

local function applyTeamIndicator(player, teamName)
	clearTeamIndicator(player)

	local character = player.Character
	local teamColor = TEAM_COLORS[teamName]
	if not character or not teamColor then
		return
	end

	local highlight = Instance.new("Highlight")
	highlight.Name = "TDMTeamHighlight"
	highlight.FillColor = teamColor
	highlight.OutlineColor = teamColor
	highlight.FillTransparency = 0.75
	highlight.OutlineTransparency = 0
	highlight.DepthMode = Enum.HighlightDepthMode.Occluded
	highlight.Parent = character
end

local function getQueueKey(queueOptionName, gameModeName)
	return queueOptionName .. "_" .. gameModeName
end

local function getQueueDisplayName(queueOptionName, gameModeName)
	return queueOptionName .. " " .. gameModeName
end

local function getGameModeNameFromQueueKey(queueKey)
	return string.match(queueKey, "_([^_]+)$")
end

local function getOrCreateQueue(queueOptionName, gameModeName)
	local queueKey = getQueueKey(queueOptionName, gameModeName)
	if not matchmakingQueues[queueKey] then
		matchmakingQueues[queueKey] = {}
	end

	return queueKey, matchmakingQueues[queueKey]
end

local function getPlayersNeededForGameMode(gameModeName)
	if gameModeName == "TDM" then
		return TDM_PLAYERS_PER_TEAM * 2
	end

	return PLAYERS_PER_TEST_MATCH
end

local function assignTeams(matchState)
	matchState.teamScores = {
		Red = 0,
		Blue = 0,
	}
	matchState.playerTeams = {}

	if matchState.gameModeName ~= "TDM" then
		return
	end

	for index, player in matchState.players do
		if index % 2 == 1 then
			matchState.playerTeams[player.UserId] = "Red"
		else
			matchState.playerTeams[player.UserId] = "Blue"
		end
	end
end

local function getHighestScore(playersInMatch)
	local highestScore = nil
	local tiedPlayers = {}

	for _, player in playersInMatch do
		local score = matchScores[player.UserId]
		local kills = 0
		if score then
			kills = score.kills
		end

		if not highestScore or kills > highestScore then
			highestScore = kills
			tiedPlayers = { player }
		elseif kills == highestScore then
			table.insert(tiedPlayers, player)
		end
	end

	return highestScore or 0, tiedPlayers
end

local function getWinningTeam(matchState)
	if matchState.teamScores.Red > matchState.teamScores.Blue then
		return "Red", matchState.teamScores.Red
	elseif matchState.teamScores.Blue > matchState.teamScores.Red then
		return "Blue", matchState.teamScores.Blue
	end

	return nil, matchState.teamScores.Red
end

local function buildMatchEndMessage(matchState, reason)
	if matchState.gameModeName == "TDM" then
		local winningTeam, winningScore = getWinningTeam(matchState)
		local resultText = "Draw"

		if winningTeam then
			resultText = winningTeam .. " team wins"
		end

		return matchState.gameModeName .. " " .. matchState.modeName .. " match ended! " .. resultText .. " with " .. winningScore .. " kills. " .. reason
	end

	local highestScore, tiedPlayers = getHighestScore(matchState.players)
	local resultText = "Draw"

	if #tiedPlayers == 1 then
		resultText = tiedPlayers[1].Name .. " wins"
	end

	return matchState.gameModeName .. " " .. matchState.modeName .. " match ended! " .. resultText .. " with " .. highestScore .. " kills. " .. reason
end

endMatch = function(matchState, reason)
	if not matchState or matchState.ended then
		return
	end

	matchState.ended = true

	local endedMessage = buildMatchEndMessage(matchState, reason)
	print(endedMessage)

	for _, player in matchState.players do
		if player.Parent == Players and playerLocations[player.UserId] == matchState.locationName then
			local score = matchScores[player.UserId]
			if score and matchState.gameModeName == "TDM" then
				matchStatusUpdateRemote:FireClient(player, endedMessage .. "\nRed: " .. matchState.teamScores.Red .. " | Blue: " .. matchState.teamScores.Blue)
			elseif score then
				matchStatusUpdateRemote:FireClient(player, endedMessage .. "\nKills: " .. score.kills .. " | Deaths: " .. score.deaths)
			else
				matchStatusUpdateRemote:FireClient(player, endedMessage)
			end
		end

		activeMatches[player.UserId] = nil
		clearTeamIndicator(player)
	end

	task.spawn(function()
		for secondsLeft = POST_MATCH_RETURN_SECONDS, 1, -1 do
			for _, player in matchState.players do
				if player.Parent == Players and playerLocations[player.UserId] == matchState.locationName and not activeMatches[player.UserId] then
					matchStatusUpdateRemote:FireClient(player, "Returning to lobby in " .. secondsLeft .. "...")
				end
			end

			task.wait(1)
		end

		for _, player in matchState.players do
			if player.Parent == Players and playerLocations[player.UserId] == matchState.locationName and not activeMatches[player.UserId] then
				teleportPlayerToLobby(player)
				setPlayerLocation(player, "Lobby")
				matchScores[player.UserId] = nil
				matchStatusUpdateRemote:FireClient(player, "")
				matchScoreUpdateRemote:FireClient(player, nil)
			end
		end
	end)
end

local function startTestMatchCountdown(matchState)
	local activePlayerIds = {}
	for _, player in matchState.players do
		activePlayerIds[player.UserId] = true
		activeCountdowns[player.UserId] = true
	end

	local function isPlayerStillInMatch(player)
		return activePlayerIds[player.UserId]
			and activeCountdowns[player.UserId]
			and playerLocations[player.UserId] == matchState.locationName
	end

	local function isMatchStillValid()
		for _, player in matchState.players do
			if not isPlayerStillInMatch(player) then
				return false
			end
		end

		return true
	end

	local function sendStatusToMatch(message)
		for _, player in matchState.players do
			matchStatusUpdateRemote:FireClient(player, message)
		end
	end

	task.spawn(function()
		for secondsLeft = COUNTDOWN_SECONDS, 1, -1 do
			if not isMatchStillValid() then
				print(matchState.modeName .. " test match countdown cancelled.")
				return
			end

			local countdownMessage = matchState.gameModeName .. " " .. matchState.modeName .. " match starting in " .. secondsLeft .. "..."
			print(countdownMessage)
			sendStatusToMatch(countdownMessage)
			task.wait(1)
		end

		if not isMatchStillValid() then
			print(matchState.modeName .. " test match countdown cancelled.")
			return
		end

		local startedMessage = matchState.gameModeName .. " " .. matchState.modeName .. " match started! First to " .. KILLS_TO_WIN .. " kills wins."
		print(startedMessage)

		for _, player in matchState.players do
			local playerMessage = startedMessage
			if matchState.gameModeName == "TDM" then
				playerMessage = playerMessage .. "\nYou are on " .. matchState.playerTeams[player.UserId] .. " team."
			end

			matchStatusUpdateRemote:FireClient(player, playerMessage)
		end

		for _, player in matchState.players do
			activeCountdowns[player.UserId] = nil
			activeMatches[player.UserId] = matchState
		end

		for secondsLeft = TEST_MATCH_DURATION_SECONDS, 1, -1 do
			if matchState.ended then
				return
			end

			for _, player in matchState.players do
				if not activeMatches[player.UserId] or playerLocations[player.UserId] ~= matchState.locationName then
					activePlayerIds[player.UserId] = nil
				end
			end

			if next(activePlayerIds) == nil then
				print(matchState.modeName .. " test match timer cancelled.")
				return
			end

			for _, player in matchState.players do
				if activePlayerIds[player.UserId] then
					matchStatusUpdateRemote:FireClient(player, "Time left: " .. secondsLeft)
				end
			end

			task.wait(1)
		end

		endMatch(matchState, "Time expired.")
	end)
end

local function startTestMatchForPlayers(playersInMatch, modeName, modeInfo, gameModeName)
	print("Starting " .. gameModeName .. " " .. modeName .. " test match with " .. #playersInMatch .. " players.")

	local matchState = {
		players = playersInMatch,
		modeName = modeName,
		gameModeName = gameModeName,
		locationName = modeInfo.locationName,
		ended = false,
		playerTeams = {},
		teamScores = {
			Red = 0,
			Blue = 0,
		},
	}

	assignTeams(matchState)

	for _, player in playersInMatch do
		queuedModes[player.UserId] = nil
		queuedDisplays[player.UserId] = nil
		setPlayerLocation(player, modeInfo.locationName)
		resetMatchScore(player)
		fireScoreUpdate(player, matchState)
		teleportPlayerToTestArena(player, modeInfo, matchState.playerTeams[player.UserId])

		if gameModeName == "TDM" then
			applyTeamIndicator(player, matchState.playerTeams[player.UserId])
		else
			clearTeamIndicator(player)
		end
	end

	startTestMatchCountdown(matchState)
end

local function removePlayerFromQueue(player)
	local queueKey = queuedModes[player.UserId]
	if not queueKey then
		return nil
	end

	local queue = matchmakingQueues[queueKey]
	if queue then
		for index = #queue, 1, -1 do
			if queue[index] == player then
				table.remove(queue, index)
			end
		end
	end

	queuedModes[player.UserId] = nil
	queuedDisplays[player.UserId] = nil
	matchStatusUpdateRemote:FireClient(player, "")
	return queueKey
end

local function sendQueueStatus(queueKey, gameModeName)
	local queue = matchmakingQueues[queueKey]
	if not queue then
		return
	end

	gameModeName = gameModeName or getGameModeNameFromQueueKey(queueKey)
	local playersNeeded = getPlayersNeededForGameMode(gameModeName)

	for _, queuedPlayer in queue do
		local queueDisplayName = queuedDisplays[queuedPlayer.UserId] or queueKey
		matchStatusUpdateRemote:FireClient(queuedPlayer, "Queued for " .. queueDisplayName .. ". Players: " .. #queue .. "/" .. playersNeeded)
	end
end

local function chooseMatchMode(queueOptionName)
	local queueOption = QUEUE_OPTIONS[queueOptionName]
	if not queueOption then
		return nil
	end

	local possibleMatchModes = queueOption.possibleMatchModes
	local chosenModeName = possibleMatchModes[math.random(1, #possibleMatchModes)]
	return chosenModeName, TEST_MATCH_MODES[chosenModeName]
end

local function tryStartQueuedMatch(queueOptionName, gameModeName)
	local queueKey = getQueueKey(queueOptionName, gameModeName)
	local queue = matchmakingQueues[queueKey]
	if not queue then
		return
	end

	local playersNeeded = getPlayersNeededForGameMode(gameModeName)

	while #queue >= playersNeeded do
		local playersInMatch = {}

		for _ = 1, playersNeeded do
			local queuedPlayer = table.remove(queue, 1)
			if queuedPlayer and queuedPlayer.Parent == Players then
				table.insert(playersInMatch, queuedPlayer)
			end
		end

		if #playersInMatch == playersNeeded then
			local chosenModeName, modeInfo = chooseMatchMode(queueOptionName)
			if modeInfo then
				startTestMatchForPlayers(playersInMatch, chosenModeName, modeInfo, gameModeName)
			end
		else
			for _, player in playersInMatch do
				table.insert(queue, 1, player)
			end

			break
		end
	end
end

local function addPlayerToQueue(player, queueOptionName, gameModeName)
	local queueKey, queue = getOrCreateQueue(queueOptionName, gameModeName)
	if not queue then
		warn(player.Name .. " requested an invalid matchmaking queue.")
		return
	end

	if playerLocations[player.UserId] ~= "Lobby" then
		matchStatusUpdateRemote:FireClient(player, "Return to the lobby before queueing again.")
		return
	end

	if queuedModes[player.UserId] then
		matchStatusUpdateRemote:FireClient(player, "Already queued for " .. (queuedDisplays[player.UserId] or queuedModes[player.UserId]) .. ".")
		return
	end

	table.insert(queue, player)
	queuedModes[player.UserId] = queueKey
	queuedDisplays[player.UserId] = getQueueDisplayName(queueOptionName, gameModeName)

	local playersNeeded = getPlayersNeededForGameMode(gameModeName)
	local queueMessage = "Queued for " .. queuedDisplays[player.UserId] .. ". Players: " .. #queue .. "/" .. playersNeeded
	print(player.Name .. " entered " .. queuedDisplays[player.UserId] .. " queue. Queue size: " .. #queue)
	matchStatusUpdateRemote:FireClient(player, queueMessage)
	sendQueueStatus(queueKey, gameModeName)

	tryStartQueuedMatch(queueOptionName, gameModeName)
end

local function movePlayerToPart(player, targetPart)
	local character = player.Character or player.CharacterAdded:Wait()
	local humanoidRootPart = character:WaitForChild("HumanoidRootPart", 5)
	if not humanoidRootPart then
		warn("Could not find HumanoidRootPart for " .. player.Name .. ".")
		return
	end

	humanoidRootPart.CFrame = targetPart.CFrame + Vector3.new(0, 4, 0)
end

local function findArenaMap(arenaName)
	local arenasFolder = Workspace:FindFirstChild("Arenas")
	local arenaMap = nil
	if arenasFolder then
		arenaMap = arenasFolder:FindFirstChild(arenaName)
	else
		arenaMap = Workspace:FindFirstChild(arenaName)
	end

	return arenaMap
end

local function findFirstBasePart(container)
	for _, child in container:GetChildren() do
		if child:IsA("BasePart") then
			return child
		end
	end

	return nil
end

local function findTeamSpawn(spawnsFolder, teamName)
	if not teamName then
		return nil
	end

	local possibleFolderNames = {
		teamName,
		teamName .. "Spawns",
		teamName .. "TeamSpawns",
	}

	for _, folderName in possibleFolderNames do
		local teamSpawnsFolder = spawnsFolder:FindFirstChild(folderName)
		if teamSpawnsFolder then
			local teamSpawn = findFirstBasePart(teamSpawnsFolder)
			if teamSpawn then
				return teamSpawn
			end
		end
	end

	local possiblePartNames = {
		teamName .. "Spawn",
		teamName .. "_Spawn",
		"Spawn_" .. teamName,
		"TestArenaSpawn_" .. teamName,
	}

	for _, partName in possiblePartNames do
		local teamSpawn = spawnsFolder:FindFirstChild(partName)
		if teamSpawn and teamSpawn:IsA("BasePart") then
			return teamSpawn
		end
	end

	return nil
end

local function findArenaSpawn(arenaMap, teamName)
	local spawnsFolder = arenaMap:FindFirstChild("Spawns")
	if not spawnsFolder then
		return nil
	end

	local teamSpawn = findTeamSpawn(spawnsFolder, teamName)
	if teamSpawn then
		return teamSpawn
	end

	local testArenaSpawn = spawnsFolder:FindFirstChild("TestArenaSpawn")
	if testArenaSpawn then
		return testArenaSpawn
	end

	return findFirstBasePart(spawnsFolder)
end

local function findRandomSpawnInFolder(spawnsFolder)
	local spawnParts = {}

	for _, child in spawnsFolder:GetChildren() do
		if child:IsA("BasePart") then
			table.insert(spawnParts, child)
		end
	end

	if #spawnParts == 0 then
		return nil
	end

	return spawnParts[math.random(1, #spawnParts)]
end

teleportPlayerToTestArena = function(player, modeInfo, teamName)
	local arenaMap = findArenaMap(modeInfo.arenaName)
	if not arenaMap then
		warn("Could not find " .. modeInfo.arenaName .. " in Workspace.Arenas or Workspace.")
		return
	end

	local spawnsFolder = arenaMap:FindFirstChild("Spawns")
	if not spawnsFolder then
		warn("Could not find " .. modeInfo.arenaName .. ".Spawns.")
		return
	end

	local arenaSpawn = findArenaSpawn(arenaMap, teamName)
	if not arenaSpawn then
		warn("Could not find a spawn part inside " .. modeInfo.arenaName .. ".Spawns.")
		return
	end

	movePlayerToPart(player, arenaSpawn)
end

teleportPlayerToPracticeMap = function(player, practiceInfo)
	local practiceMap = Workspace:FindFirstChild(practiceInfo.mapName)
	if not practiceMap then
		warn("Could not find Workspace." .. practiceInfo.mapName .. ".")
		return
	end

	local spawnsFolder = practiceMap:FindFirstChild("Spawns")
	if not spawnsFolder then
		warn("Could not find " .. practiceInfo.mapName .. ".Spawns.")
		return
	end

	local practiceSpawn = findRandomSpawnInFolder(spawnsFolder)
	if not practiceSpawn then
		warn("Could not find a spawn part inside " .. practiceInfo.mapName .. ".Spawns.")
		return
	end

	movePlayerToPart(player, practiceSpawn)
end

teleportPlayerToLobby = function(player)
	local lobby = Workspace:FindFirstChild("Lobby")
	if not lobby then
		warn("Could not find Workspace.Lobby.")
		return
	end

	local spawnsFolder = lobby:FindFirstChild("Spawns")
	if not spawnsFolder then
		warn("Could not find Workspace.Lobby.Spawns.")
		return
	end

	local lobbySpawn = spawnsFolder:FindFirstChild("LobbySpawn")
	if not lobbySpawn then
		warn("Could not find Workspace.Lobby.Spawns.LobbySpawn.")
		return
	end

	movePlayerToPart(player, lobbySpawn)
end

local function movePlayerToCurrentLocationSpawn(player)
	local currentLocation = playerLocations[player.UserId]
	local matchState = activeMatches[player.UserId]
	local teamName = nil
	if matchState and matchState.gameModeName == "TDM" then
		teamName = matchState.playerTeams[player.UserId]
	end

	if currentLocation == "MeleeArena" then
		teleportPlayerToTestArena(player, TEST_MATCH_MODES.Melee, teamName)
	elseif currentLocation == "RangedArena" then
		teleportPlayerToTestArena(player, TEST_MATCH_MODES.Ranged, teamName)
	elseif currentLocation == "WildernessPractice" then
		teleportPlayerToPracticeMap(player, PRACTICE_MODES.Wilderness)
	else
		teleportPlayerToLobby(player)
	end
end

joinTestMatchRemote.OnServerEvent:Connect(function(player, queueOptionName, gameModeName)
	local queueOption = QUEUE_OPTIONS[queueOptionName]
	if not queueOption then
		warn(player.Name .. " requested an invalid queue option.")
		return
	end

	if not GAME_MODES[gameModeName] or not GAME_MODES[gameModeName].enabled then
		warn(player.Name .. " requested an invalid game mode.")
		return
	end

	print("[" .. player.Name .. "] requested to join the " .. queueOptionName .. " " .. gameModeName .. " queue.")

	-- Future: Add player to a larger server-owned matchmaking system.
	-- Future: Reserve private server and teleport matched players to a separate arena place.
	addPlayerToQueue(player, queueOptionName, gameModeName)
end)

joinPracticeModeRemote.OnServerEvent:Connect(function(player, practiceModeName)
	local practiceInfo = PRACTICE_MODES[practiceModeName]
	if not practiceInfo then
		warn(player.Name .. " requested an invalid practice mode.")
		return
	end

	local removedModeName = removePlayerFromQueue(player)
	if removedModeName then
		sendQueueStatus(removedModeName)
	end

	if activeMatches[player.UserId] then
		endMatch(activeMatches[player.UserId], player.Name .. " left the match.")
	end

	activeCountdowns[player.UserId] = nil
	activeMatches[player.UserId] = nil
	matchScores[player.UserId] = nil
	clearTeamIndicator(player)

	setPlayerLocation(player, practiceInfo.locationName)
	teleportPlayerToPracticeMap(player, practiceInfo)

	matchStatusUpdateRemote:FireClient(player, practiceInfo.displayName .. " practice mode")
	matchScoreUpdateRemote:FireClient(player, nil)
	print(player.Name .. " joined " .. practiceInfo.displayName .. ".")
end)

returnToLobbyRemote.OnServerEvent:Connect(function(player)
	print("[" .. player.Name .. "] requested to return to the lobby.")
	local removedModeName = removePlayerFromQueue(player)
	if removedModeName then
		sendQueueStatus(removedModeName)
	end

	if activeMatches[player.UserId] then
		endMatch(activeMatches[player.UserId], player.Name .. " returned to the lobby.")
	end

	teleportPlayerToLobby(player)

	setPlayerLocation(player, "Lobby")
	activeCountdowns[player.UserId] = nil
	activeMatches[player.UserId] = nil
	matchScores[player.UserId] = nil
	clearTeamIndicator(player)
	matchStatusUpdateRemote:FireClient(player, "")
	matchScoreUpdateRemote:FireClient(player, nil)
end)

cancelQueueRemote.OnServerEvent:Connect(function(player)
	local removedModeName = removePlayerFromQueue(player)
	if not removedModeName then
		matchStatusUpdateRemote:FireClient(player, "You are not currently queued.")
		return
	end

	print(player.Name .. " cancelled " .. removedModeName .. " queue.")
	matchStatusUpdateRemote:FireClient(player, "Queue cancelled.")
	sendQueueStatus(removedModeName)
end)

matchKillAwardedEvent.Event:Connect(function(attacker, target)
	addMatchKill(attacker, target)
end)

canDamagePlayerFunction.OnInvoke = function(attacker, target)
	return canDamagePlayer(attacker, target)
end

Players.PlayerAdded:Connect(function(player)
	setPlayerLocation(player, "Lobby")

	player.CharacterAdded:Connect(function()
		task.wait(0.75)
		movePlayerToCurrentLocationSpawn(player)

		local matchState = activeMatches[player.UserId]
		if matchState and matchState.gameModeName == "TDM" then
			applyTeamIndicator(player, matchState.playerTeams[player.UserId])
		else
			clearTeamIndicator(player)
		end

		local character = player.Character
		if not character then
			return
		end

		local humanoid = character:FindFirstChildOfClass("Humanoid")
		if not humanoid then
			return
		end

		humanoid.Died:Connect(function()
			if activeMatches[player.UserId] then
				addMatchDeath(player)
			end
		end)
	end)
end)

Players.PlayerRemoving:Connect(function(player)
	local removedModeName = removePlayerFromQueue(player)
	if removedModeName then
		sendQueueStatus(removedModeName)
	end

	if activeMatches[player.UserId] then
		endMatch(activeMatches[player.UserId], player.Name .. " left the game.")
	end

	playerLocations[player.UserId] = nil
	activeCountdowns[player.UserId] = nil
	activeMatches[player.UserId] = nil
	matchScores[player.UserId] = nil
	queuedDisplays[player.UserId] = nil
	clearTeamIndicator(player)
end)

print("Matchmaking server loaded")
