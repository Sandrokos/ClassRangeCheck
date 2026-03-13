local _, CRC = ...

--------------------------------------------------
-- RANGE CHECK LOGIC
--------------------------------------------------
function CRC:ShowOutOfRange()
	if self.db.profile.displayMode == "TEXT" then
		self.frame.text:Show()
		self.frame.icon:Hide()
	else
		self.frame.text:Hide()
		self.frame.icon:Show()
	end
end

function CRC:HideOutOfRange()
    self.frame.text:Hide()
	self.frame.icon:Hide()
end

function CRC:CheckRange()
	if self.db.profile.testMode then
		CRC:ShowOutOfRange()
		return
	end

	if not self.globals.cachedEnabled then
		CRC:HideOutOfRange()
		return
	end

	if self.db.profile.showInCombatOnly and not UnitAffectingCombat("player") then
		CRC:HideOutOfRange()
		return
	end

	if not UnitExists("target") or not UnitCanAttack("player", "target") then
		CRC:HideOutOfRange()
		return
	end

	if not self.globals.cachedSpellId then
		CRC:HideOutOfRange()
		return
	end

	local inRange = C_Spell.IsSpellInRange(self.globals.cachedSpellId, "target")
	if inRange == false then
		CRC:ShowOutOfRange()
	else
		CRC:HideOutOfRange()
	end
end