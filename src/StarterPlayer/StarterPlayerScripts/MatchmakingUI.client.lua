local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")
local remotesFolder = ReplicatedStorage:WaitForChild("Remotes")
local joinTestMatchRemote = remotesFolder:WaitForChild("JoinTestMatch")
local returnToLobbyRemote = remotesFolder:WaitForChild("ReturnToLobby")
local joinPracticeModeRemote = remotesFolder:WaitForChild("JoinPracticeMode")
local cancelQueueRemote = remotesFolder:WaitForChild("CancelQueue")
local matchStatusUpdateRemote = remotesFolder:WaitForChild("MatchStatusUpdate")
local matchScoreUpdateRemote = remotesFolder:WaitForChild("MatchScoreUpdate")

local existingGui = playerGui:FindFirstChild("MatchmakingUI")
if existingGui then
	existingGui:Destroy()
end

local existingArenaGui = playerGui:FindFirstChild("ArenaUI")
if existingArenaGui then
	existingArenaGui:Destroy()
end

local screenGui = Instance.new("ScreenGui")
screenGui.Name = "MatchmakingUI"
screenGui.Enabled = false
screenGui.ResetOnSpawn = false
screenGui.Parent = playerGui

local function limitTextSize(textObject, maxTextSize)
	local textSizeLimit = Instance.new("UITextSizeConstraint")
	textSizeLimit.MaxTextSize = maxTextSize
	textSizeLimit.MinTextSize = 12
	textSizeLimit.Parent = textObject
end

local background = Instance.new("Frame")
background.Name = "Background"
background.Size = UDim2.fromScale(1, 1)
background.BackgroundTransparency = 0.35
background.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
background.Parent = screenGui

local panel = Instance.new("Frame")
panel.Name = "Panel"
panel.Size = UDim2.fromScale(0.82, 0.82)
panel.Position = UDim2.fromScale(0.5, 0.5)
panel.AnchorPoint = Vector2.new(0.5, 0.5)
panel.BackgroundColor3 = Color3.fromRGB(30, 30, 35)
panel.BorderSizePixel = 0
panel.Parent = background

local panelSizeLimit = Instance.new("UISizeConstraint")
panelSizeLimit.MaxSize = Vector2.new(420, 420)
panelSizeLimit.MinSize = Vector2.new(280, 340)
panelSizeLimit.Parent = panel

local title = Instance.new("TextLabel")
title.Name = "Title"
title.Size = UDim2.new(1, -40, 0, 50)
title.Position = UDim2.fromOffset(20, 15)
title.BackgroundTransparency = 1
title.Text = "Matchmaking"
title.TextColor3 = Color3.fromRGB(255, 255, 255)
title.TextScaled = true
title.Font = Enum.Font.GothamBold
title.Parent = panel
limitTextSize(title, 30)

local description = Instance.new("TextLabel")
description.Name = "Description"
description.Size = UDim2.new(1, -40, 0, 60)
description.Position = UDim2.fromOffset(20, 80)
description.BackgroundTransparency = 1
description.Text = "Choose a mode to start searching for a PvP match."
description.TextColor3 = Color3.fromRGB(220, 220, 220)
description.TextScaled = true
description.TextWrapped = true
description.Font = Enum.Font.Gotham
description.Parent = panel
limitTextSize(description, 18)

local meleeButton = Instance.new("TextButton")
meleeButton.Name = "JoinMeleeTestMatchButton"
meleeButton.Size = UDim2.new(0.72, 0, 0, 44)
meleeButton.Position = UDim2.fromScale(0.5, 0.42)
meleeButton.AnchorPoint = Vector2.new(0.5, 0.5)
meleeButton.BackgroundColor3 = Color3.fromRGB(60, 120, 255)
meleeButton.BorderSizePixel = 0
meleeButton.Text = "Melee"
meleeButton.TextColor3 = Color3.fromRGB(255, 255, 255)
meleeButton.TextScaled = true
meleeButton.Font = Enum.Font.GothamBold
meleeButton.Parent = panel
limitTextSize(meleeButton, 22)

local rangedButton = Instance.new("TextButton")
rangedButton.Name = "JoinRangedTestMatchButton"
rangedButton.Size = UDim2.new(0.72, 0, 0, 44)
rangedButton.Position = UDim2.fromScale(0.5, 0.55)
rangedButton.AnchorPoint = Vector2.new(0.5, 0.5)
rangedButton.BackgroundColor3 = Color3.fromRGB(60, 170, 120)
rangedButton.BorderSizePixel = 0
rangedButton.Text = "Ranged"
rangedButton.TextColor3 = Color3.fromRGB(255, 255, 255)
rangedButton.TextScaled = true
rangedButton.Font = Enum.Font.GothamBold
rangedButton.Parent = panel
limitTextSize(rangedButton, 22)

local mixedButton = Instance.new("TextButton")
mixedButton.Name = "JoinMixedQueueButton"
mixedButton.Size = UDim2.new(0.72, 0, 0, 44)
mixedButton.Position = UDim2.fromScale(0.5, 0.68)
mixedButton.AnchorPoint = Vector2.new(0.5, 0.5)
mixedButton.BackgroundColor3 = Color3.fromRGB(120, 105, 190)
mixedButton.BorderSizePixel = 0
mixedButton.Text = "Mixed"
mixedButton.TextColor3 = Color3.fromRGB(255, 255, 255)
mixedButton.TextScaled = true
mixedButton.Font = Enum.Font.GothamBold
mixedButton.Parent = panel
limitTextSize(mixedButton, 22)

local practiceButton = Instance.new("TextButton")
practiceButton.Name = "JoinPracticeButton"
practiceButton.Size = UDim2.new(0.72, 0, 0, 44)
practiceButton.Position = UDim2.fromScale(0.5, 0.81)
practiceButton.AnchorPoint = Vector2.new(0.5, 0.5)
practiceButton.BackgroundColor3 = Color3.fromRGB(95, 140, 75)
practiceButton.BorderSizePixel = 0
practiceButton.Text = "Practice"
practiceButton.TextColor3 = Color3.fromRGB(255, 255, 255)
practiceButton.TextScaled = true
practiceButton.Font = Enum.Font.GothamBold
practiceButton.Parent = panel
limitTextSize(practiceButton, 22)

local closeButton = Instance.new("TextButton")
closeButton.Name = "CloseButton"
closeButton.Size = UDim2.new(0.72, 0, 0, 42)
closeButton.Position = UDim2.fromScale(0.5, 0.93)
closeButton.AnchorPoint = Vector2.new(0.5, 0.5)
closeButton.BackgroundColor3 = Color3.fromRGB(80, 80, 85)
closeButton.BorderSizePixel = 0
closeButton.Text = "Close"
closeButton.TextColor3 = Color3.fromRGB(255, 255, 255)
closeButton.TextScaled = true
closeButton.Font = Enum.Font.GothamBold
closeButton.Parent = panel
limitTextSize(closeButton, 20)

local ffaButton = Instance.new("TextButton")
ffaButton.Name = "FFAButton"
ffaButton.Size = UDim2.new(0.72, 0, 0, 50)
ffaButton.Position = UDim2.fromScale(0.5, 0.45)
ffaButton.AnchorPoint = Vector2.new(0.5, 0.5)
ffaButton.BackgroundColor3 = Color3.fromRGB(60, 120, 255)
ffaButton.BorderSizePixel = 0
ffaButton.Text = "FFA"
ffaButton.TextColor3 = Color3.fromRGB(255, 255, 255)
ffaButton.TextScaled = true
ffaButton.Font = Enum.Font.GothamBold
ffaButton.Visible = false
ffaButton.Parent = panel
limitTextSize(ffaButton, 24)

local tdmButton = Instance.new("TextButton")
tdmButton.Name = "TDMButton"
tdmButton.Size = UDim2.new(0.72, 0, 0, 50)
tdmButton.Position = UDim2.fromScale(0.5, 0.61)
tdmButton.AnchorPoint = Vector2.new(0.5, 0.5)
tdmButton.BackgroundColor3 = Color3.fromRGB(60, 170, 120)
tdmButton.BorderSizePixel = 0
tdmButton.Text = "TDM"
tdmButton.TextColor3 = Color3.fromRGB(255, 255, 255)
tdmButton.TextScaled = true
tdmButton.Font = Enum.Font.GothamBold
tdmButton.Visible = false
tdmButton.Parent = panel
limitTextSize(tdmButton, 24)

local backButton = Instance.new("TextButton")
backButton.Name = "BackButton"
backButton.Size = UDim2.new(0.72, 0, 0, 42)
backButton.Position = UDim2.fromScale(0.5, 0.78)
backButton.AnchorPoint = Vector2.new(0.5, 0.5)
backButton.BackgroundColor3 = Color3.fromRGB(80, 80, 85)
backButton.BorderSizePixel = 0
backButton.Text = "Back"
backButton.TextColor3 = Color3.fromRGB(255, 255, 255)
backButton.TextScaled = true
backButton.Font = Enum.Font.GothamBold
backButton.Visible = false
backButton.Parent = panel
limitTextSize(backButton, 20)

local arenaGui = Instance.new("ScreenGui")
arenaGui.Name = "ArenaUI"
arenaGui.Enabled = false
arenaGui.ResetOnSpawn = false
arenaGui.Parent = playerGui

local returnButton = Instance.new("TextButton")
returnButton.Name = "ReturnToLobbyButton"
returnButton.Size = UDim2.fromOffset(180, 44)
returnButton.Position = UDim2.new(1, -20, 0, 20)
returnButton.AnchorPoint = Vector2.new(1, 0)
returnButton.BackgroundColor3 = Color3.fromRGB(80, 80, 85)
returnButton.BorderSizePixel = 0
returnButton.Text = "Return To Lobby"
returnButton.TextColor3 = Color3.fromRGB(255, 255, 255)
returnButton.TextScaled = true
returnButton.Font = Enum.Font.GothamBold
returnButton.Parent = arenaGui
limitTextSize(returnButton, 18)

local cancelQueueButton = Instance.new("TextButton")
cancelQueueButton.Name = "CancelQueueButton"
cancelQueueButton.Size = UDim2.fromOffset(180, 44)
cancelQueueButton.Position = UDim2.new(1, -20, 0, 20)
cancelQueueButton.AnchorPoint = Vector2.new(1, 0)
cancelQueueButton.BackgroundColor3 = Color3.fromRGB(160, 70, 70)
cancelQueueButton.BorderSizePixel = 0
cancelQueueButton.Text = "Cancel Queue"
cancelQueueButton.TextColor3 = Color3.fromRGB(255, 255, 255)
cancelQueueButton.TextScaled = true
cancelQueueButton.Font = Enum.Font.GothamBold
cancelQueueButton.Visible = false
cancelQueueButton.Parent = arenaGui
limitTextSize(cancelQueueButton, 18)

local statusLabel = Instance.new("TextLabel")
statusLabel.Name = "MatchStatusLabel"
statusLabel.Size = UDim2.fromOffset(420, 54)
statusLabel.Position = UDim2.new(0.5, 0, 0, 20)
statusLabel.AnchorPoint = Vector2.new(0.5, 0)
statusLabel.BackgroundColor3 = Color3.fromRGB(30, 30, 35)
statusLabel.BackgroundTransparency = 0.15
statusLabel.BorderSizePixel = 0
statusLabel.Text = ""
statusLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
statusLabel.TextScaled = true
statusLabel.TextWrapped = true
statusLabel.Font = Enum.Font.GothamBold
statusLabel.Visible = false
statusLabel.Parent = arenaGui
limitTextSize(statusLabel, 20)

local scoreLabel = Instance.new("TextLabel")
scoreLabel.Name = "MatchScoreLabel"
scoreLabel.Size = UDim2.fromOffset(260, 60)
scoreLabel.Position = UDim2.new(0, 20, 0, 20)
scoreLabel.BackgroundColor3 = Color3.fromRGB(30, 30, 35)
scoreLabel.BackgroundTransparency = 0.15
scoreLabel.BorderSizePixel = 0
scoreLabel.Text = "Kills: 0 | Deaths: 0"
scoreLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
scoreLabel.TextScaled = true
scoreLabel.TextWrapped = true
scoreLabel.Font = Enum.Font.GothamBold
scoreLabel.Visible = false
scoreLabel.Parent = arenaGui
limitTextSize(scoreLabel, 18)

local selectedQueueOptionName = nil

local function setTypeButtonsVisible(isVisible)
	meleeButton.Visible = isVisible
	rangedButton.Visible = isVisible
	mixedButton.Visible = isVisible
	practiceButton.Visible = isVisible
end

local function setGameModeButtonsVisible(isVisible)
	ffaButton.Visible = isVisible
	tdmButton.Visible = isVisible
	backButton.Visible = isVisible
end

local function showQueueTypeSelection()
	selectedQueueOptionName = nil
	title.Text = "Matchmaking"
	description.Text = "Choose an arena type."
	setTypeButtonsVisible(true)
	setGameModeButtonsVisible(false)
	closeButton.Position = UDim2.fromScale(0.5, 0.93)
end

local function showGameModeSelection(queueOptionName)
	selectedQueueOptionName = queueOptionName
	title.Text = queueOptionName
	description.Text = "Choose a game mode."
	setTypeButtonsVisible(false)
	setGameModeButtonsVisible(true)
	closeButton.Position = UDim2.fromScale(0.5, 0.91)
end

local function joinTestMatch(queueOptionName, gameModeName)
	print("Join " .. queueOptionName .. " " .. gameModeName .. " clicked")
	joinTestMatchRemote:FireServer(queueOptionName, gameModeName)
	screenGui.Enabled = false
	arenaGui.Enabled = true
	cancelQueueButton.Visible = true
	returnButton.Visible = false
	scoreLabel.Visible = false
end

local function joinPracticeMode(practiceModeName)
	print("Join " .. practiceModeName .. " Practice clicked")
	joinPracticeModeRemote:FireServer(practiceModeName)
	screenGui.Enabled = false
	arenaGui.Enabled = true
	cancelQueueButton.Visible = false
	returnButton.Visible = true
	scoreLabel.Visible = false
end

closeButton.MouseButton1Click:Connect(function()
	screenGui.Enabled = false
	showQueueTypeSelection()
end)

screenGui:GetPropertyChangedSignal("Enabled"):Connect(function()
	if screenGui.Enabled then
		showQueueTypeSelection()
	end
end)

meleeButton.MouseButton1Click:Connect(function()
	showGameModeSelection("Melee")
end)

rangedButton.MouseButton1Click:Connect(function()
	showGameModeSelection("Ranged")
end)

mixedButton.MouseButton1Click:Connect(function()
	showGameModeSelection("Mixed")
end)

practiceButton.MouseButton1Click:Connect(function()
	joinPracticeMode("Wilderness")
end)

ffaButton.MouseButton1Click:Connect(function()
	if selectedQueueOptionName then
		joinTestMatch(selectedQueueOptionName, "FFA")
	end
end)

tdmButton.MouseButton1Click:Connect(function()
	if selectedQueueOptionName then
		joinTestMatch(selectedQueueOptionName, "TDM")
	end
end)

backButton.MouseButton1Click:Connect(function()
	showQueueTypeSelection()
end)

returnButton.MouseButton1Click:Connect(function()
	print("Return To Lobby clicked")
	returnToLobbyRemote:FireServer()
	arenaGui.Enabled = false
	statusLabel.Visible = false
	statusLabel.Text = ""
	scoreLabel.Visible = false
end)

cancelQueueButton.MouseButton1Click:Connect(function()
	print("Cancel Queue clicked")
	cancelQueueRemote:FireServer()
	arenaGui.Enabled = false
	cancelQueueButton.Visible = false
	returnButton.Visible = true
	statusLabel.Visible = false
	statusLabel.Text = ""
end)

matchStatusUpdateRemote.OnClientEvent:Connect(function(message)
	if message == "" then
		statusLabel.Visible = false
		statusLabel.Text = ""
		arenaGui.Enabled = false
		cancelQueueButton.Visible = false
		returnButton.Visible = false
		return
	end

	statusLabel.Text = message
	statusLabel.Visible = true

	if string.find(message, "Queued") then
		arenaGui.Enabled = true
		cancelQueueButton.Visible = true
		returnButton.Visible = false
	elseif string.find(message, "starting") or string.find(message, "started") or string.find(message, "Time left") or string.find(message, "ended") then
		arenaGui.Enabled = true
		cancelQueueButton.Visible = false
		returnButton.Visible = true
	end

	if string.find(message, "started") then
		task.delay(3, function()
			if statusLabel.Text == message then
				statusLabel.Visible = false
				statusLabel.Text = ""
			end
		end)
	end
end)

matchScoreUpdateRemote.OnClientEvent:Connect(function(score)
	if not score then
		scoreLabel.Visible = false
		scoreLabel.Text = "Kills: 0 | Deaths: 0"
		return
	end

	if score.gameModeName == "TDM" then
		scoreLabel.Text = score.teamName .. " | Red: " .. score.redScore .. " | Blue: " .. score.blueScore .. "\nKills: " .. score.kills .. " | Deaths: " .. score.deaths
	else
		scoreLabel.Text = "Kills: " .. score.kills .. " | Deaths: " .. score.deaths
	end

	scoreLabel.Visible = true
end)

showQueueTypeSelection()

print("Matchmaking UI loaded")
