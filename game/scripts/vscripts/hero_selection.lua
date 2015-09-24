if HeroSelection == nil then
	HeroSelection = class({})
end

function HeroSelection:Setup(players, availableHeroes, teamColors)
	self.SelectionTimer = 0
	self.SelectionTimerTime = 20
	self.PreGameTime = 0--3
	self.Players = players
	self.TeamColors = teamColors
	self.AvailableHeroes = availableHeroes
end

function HeroSelection:UpdateSelectedHeroes()
	local selected = {}

	for _, player in pairs(self.Players) do
		selected[player.id] = player.selectedHero or "null"
	end

	CustomNetTables:SetTableValue("main", "selectedHeroes", selected)
end

function HeroSelection:OnHover(args)
	local table = {}
	local player = self.Players[args.PlayerID]
	local hero = args.hero

	if self.AvailableHeroes[hero] == nil and hero ~= nil then
		return
	end

	if player.selectionLocked then
		return
	end

	table.player = args.PlayerID
	table.hero = hero
	CustomGameEventManager:Send_ServerToAllClients("selection_hero_hover_client", table)
end

function HeroSelection:OnClick(args)
	local table = {}
	local player = self.Players[args.PlayerID]
	local hero = args.hero

	if self.AvailableHeroes[hero] == nil then
		return
	end

	if player.selectionLocked then
		return
	end

	player.selectionLocked = true
	player.selectedHero = hero

	local allLocked = true
	for _, playerClass in pairs(self.Players) do
		if not playerClass.selectionLocked then
			allLocked = false
		end
	end

	if allLocked and self.SelectionTimer > 3 then
		self.SelectionTimer = 3
		self:SendTimeToPlayers()
	end

	self:UpdateSelectedHeroes()
end

function HeroSelection:AssignRandomHeroes()
	for i, player in pairs(self.Players) do
		if not player.selectionLocked then
			local table = {}
			local index = 0

			for i, _ in pairs(self.AvailableHeroes) do
				table[index] = i
				index = index + 1
			end

			player.selectionLocked = true
			player.selectedHero = table[RandomInt(0, index - 1)]
		end
	end

	self:UpdateSelectedHeroes()
end

function HeroSelection:SendTimeToPlayers()
	CustomGameEventManager:Send_ServerToAllClients("timer_tick", { time = self.SelectionTimer })
end

function HeroSelection:Start(callback)
	print("Starting hero selection")

	self.SelectionTimer = self.SelectionTimerTime
	self:SendTimeToPlayers()

	for _, player in pairs(self.Players) do
		player.selectedHero = nil
		player.selectionLocked = false
		player.fallSpeed = 0
	end

	self:UpdateSelectedHeroes()

	Timers:CreateTimer(1, function()
			self.SelectionTimer = self.SelectionTimer - 1
			self:SendTimeToPlayers()

			if self.SelectionTimer == 0 then
				self:AssignRandomHeroes()

				Timers:CreateTimer(self.PreGameTime, function ()
					callback()
					end
				)

				return false
			end

			return 1.0
		end
	)
end