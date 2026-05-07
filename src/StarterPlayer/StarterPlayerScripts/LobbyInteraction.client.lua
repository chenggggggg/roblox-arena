local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")

local player = Players.LocalPlayer

local INTERACTION_DISTANCE = 10
local CLOSE_DISTANCE = 13

local matchmakingNPC = workspace:WaitForChild("Lobby")
	:WaitForChild("NPCs")
	:WaitForChild("MatchmakingNPC")

local function getCharacterRootPart()
	local character = player.Character or player.CharacterAdded:Wait()
	return character:FindFirstChild("HumanoidRootPart")
end

local function getNPCPosition()
	if matchmakingNPC:IsA("Model") then
		local primaryPart = matchmakingNPC.PrimaryPart
		if primaryPart then
			return primaryPart.Position
		end

		local anyPart = matchmakingNPC:FindFirstChildWhichIsA("BasePart", true)
		if anyPart then
			return anyPart.Position
		end
	end

	if matchmakingNPC:IsA("BasePart") then
		return matchmakingNPC.Position
	end

	return nil
end

local function getDistanceFromNPC()
	local rootPart = getCharacterRootPart()
	local npcPosition = getNPCPosition()

	if not rootPart or not npcPosition then
		return math.huge
	end

	return (rootPart.Position - npcPosition).Magnitude
end

local function isNearMatchmakingNPC()
	return getDistanceFromNPC() <= INTERACTION_DISTANCE
end

local function getMatchmakingUI()
	local playerGui = player:WaitForChild("PlayerGui")
	local matchmakingGui = playerGui:FindFirstChild("MatchmakingUI")

	if not matchmakingGui then
		return nil
	end

	if not matchmakingGui:IsA("ScreenGui") then
		warn("MatchmakingUI exists, but it is not a ScreenGui. It is a " .. matchmakingGui.ClassName)
		return nil
	end

	return matchmakingGui
end

local function openMatchmakingUI()
	local matchmakingGui = getMatchmakingUI()

	if not matchmakingGui then
		warn("MatchmakingUI was not found in PlayerGui.")
		return
	end

	matchmakingGui.Enabled = true
end

local function closeMatchmakingUI()
	local matchmakingGui = getMatchmakingUI()

	if not matchmakingGui then
		return
	end

	matchmakingGui.Enabled = false
end

UserInputService.InputBegan:Connect(function(input, gameProcessed)
	if gameProcessed then
		return
	end

	if input.KeyCode == Enum.KeyCode.E then
		if isNearMatchmakingNPC() then
			openMatchmakingUI()
		else
			print("You are too far from the matchmaking NPC.")
		end
	end
end)

RunService.RenderStepped:Connect(function()
	local matchmakingGui = getMatchmakingUI()

	if not matchmakingGui or not matchmakingGui.Enabled then
		return
	end

	if getDistanceFromNPC() > CLOSE_DISTANCE then
		closeMatchmakingUI()
	end
end)

print("Lobby interaction client loaded")