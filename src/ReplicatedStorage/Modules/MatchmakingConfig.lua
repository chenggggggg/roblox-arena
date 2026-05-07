local MatchmakingConfig = {}

MatchmakingConfig.CountdownSeconds = 3
MatchmakingConfig.TestMatchDurationSeconds = 60
MatchmakingConfig.PlayersPerTestMatch = 2
MatchmakingConfig.TDMPlayersPerTeam = 1
MatchmakingConfig.KillsToWin = 5
MatchmakingConfig.PostMatchReturnSeconds = 5

MatchmakingConfig.GameModes = {
	FFA = {
		displayName = "FFA",
		enabled = true,
	},
	TDM = {
		displayName = "TDM",
		enabled = true,
	},
	CTF = {
		displayName = "CTF",
		enabled = false,
	},
	Domination = {
		displayName = "Domination",
		enabled = false,
	},
}

MatchmakingConfig.TestMatchModes = {
	Melee = {
		arenaName = "MeleeArenaMap",
		locationName = "MeleeArena",
	},
	Ranged = {
		arenaName = "RangedArenaMap",
		locationName = "RangedArena",
	},
}

MatchmakingConfig.QueueOptions = {
	Melee = {
		displayName = "Melee",
		possibleMatchModes = { "Melee" },
	},
	Ranged = {
		displayName = "Ranged",
		possibleMatchModes = { "Ranged" },
	},
	Mixed = {
		displayName = "Mixed",
		possibleMatchModes = { "Melee", "Ranged" },
	},
}

MatchmakingConfig.PracticeModes = {
	Wilderness = {
		displayName = "The Wilderness",
		mapName = "TheWildernessMap",
		locationName = "WildernessPractice",
	},
}

return MatchmakingConfig
