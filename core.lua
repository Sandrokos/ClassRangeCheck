local _, CRC = ...

local function StartRangeTicker()
	if CRC.globals.updateTicker then
		CRC.globals.updateTicker:Cancel()
	end
	CRC.globals.updateTicker = C_Timer.NewTicker(CRC.db.profile.updateInterval, function() CRC:CheckRange() end)
end

function CRC:RestartTicker()
	self:StopRangeTicker()
	StartRangeTicker()
end

function CRC:StopRangeTicker()

	if self.globals.updateTicker then
		self.globals.updateTicker:Cancel()
		self.globals.updateTicker = nil
	end

end

local loader = CreateFrame("Frame")

loader:RegisterEvent("PLAYER_LOGIN")
loader:RegisterEvent("PLAYER_SPECIALIZATION_CHANGED")
loader:RegisterEvent("PLAYER_REGEN_DISABLED")
loader:RegisterEvent("PLAYER_REGEN_ENABLED")
loader:RegisterEvent("PLAYER_TARGET_CHANGED")

loader:SetScript("OnEvent", function(self, event)
	if event == "PLAYER_LOGIN" then
		CRC:InitDisplay()
		CRC:InitMoveFrame()
		CRC:CachePlayerInfo()
		CRC:RegisterAceConfig()
		if not CRC.db.profile.showInCombatOnly then
			StartRangeTicker()
		end
	end

	if event == "PLAYER_SPECIALIZATION_CHANGED" then
		CRC:CachePlayerInfo()
		if CRC.db.profile.showInCombatOnly then
			CRC:RestartTicker()
		else
			CRC:StopRangeTicker()
		end
	end

	if event == "PLAYER_REGEN_DISABLED" then
		-- entered combat
		if CRC.globals.cachedEnabled and CRC.db.profile.showInCombatOnly then
			StartRangeTicker()
		end
	end

	if event == "PLAYER_REGEN_ENABLED" then
		-- left combat
		if not UnitExists("target") and CRC.globals.cachedEnabled and not CRC.db.profile.showInCombatOnly then
			CRC:StopRangeTicker()
		end
	end

	if event == "PLAYER_TARGET_CHANGED" then
		-- run an immediate check
		if CRC.globals.cachedEnabled then
			CRC:CheckRange()
		end
	end
end)

SLASH_CRC1 = "/crc"
SLASH_CRC2 = "/classrangecheck"

SlashCmdList["CRC"] = function(msg)
	msg = msg:lower():trim()
	if msg == "reset" then
		-- Reset profile to defaults
		CRC.db:ResetProfile()
		ReloadUI()
	else
		CRC.AceConfigDialog:Open("ClassRangeCheck")
		-- Use OnHide of the actual options panel
		local aceFrame = CRC.AceConfigDialog.OpenFrames and CRC.AceConfigDialog.OpenFrames["ClassRangeCheck"]
		if aceFrame and aceFrame.frame then
			aceFrame.frame:HookScript("OnHide", function(self)
				if CRC.db.profile.testMode and CRC.globals.unlockedFrameEnabled == false then
					CRC.db.profile.testMode = false
				end
			end)
		end
	end
end
