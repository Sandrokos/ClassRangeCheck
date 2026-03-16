local _, CRC = ...

--------------------------------------------------
-- DEFAULT SPELLS (used if player has them)
--------------------------------------------------

local defaultSpells = {

	-- Warrior (classID 1)
	[1] = {
		[71] = 1464, -- Arms → Slam
		[72] = 23881, -- Fury → Bloodthirst
		[73] = 23922 -- Protection → Shield Slam
	},

	-- Paladin (classID 2)
	[2] = {
		[65] = 82326, -- Holy → Holy Light
		[66] = 53600, -- Protection → Shield of the Righteous
		[70] = 35395 -- Retribution → Crusader Strike
	},

	-- Hunter (classID 3)
	[3] = {
		[253] = 217200, -- Beast Mastery → Barbed Shot
		[254] = 19434, -- Marksmanship → Aimed Shot
		[255] = 185358 -- Survival → Arcane Shot
	},

	-- Rogue (classID 4)
	[4] = {
		[259] = 1752, -- Assassination → Sinister Strike
		[260] = 1752, -- Outlaw → Sinister Strike
		[261] = 53 -- Subtlety → Backstab
	},

	-- Priest (classID 5)
	[5] = {
		[256] = 585, -- Discipline → Smite
		[257] = 585, -- Holy → Smite
		[258] = 8092 -- Shadow → Mind Blast
	},

	-- Death Knight (classID 6)
	[6] = {
		[250] = 49998, -- Blood → Death Strike
		[251] = 49143, -- Frost → Frost Strike
		[252] = 47541 -- Unholy → Death Coil
	},

	-- Shaman (classID 7)
	[7] = {
		[262] = 188196, -- Elemental → Lightning Bolt
		[263] = 17364, -- Enhancement → Stormstrike
		[264] = 8004 -- Restoration → Healing Surge
	},

	-- Mage (classID 8)
	[8] = {
		[62] = 30451, -- Arcane → Arcane Blast
		[63] = 133, -- Fire → Fireball
		[64] = 116 -- Frost → Frostbolt
	},

	-- Warlock (classID 9)
	[9] = {
		[265] = 686, -- Affliction → Shadow Bolt
		[266] = 686, -- Demonology → Shadow Bolt
		[267] = 116858 -- Destruction → Chaos Bolt
	},

	-- Monk (classID 10)
	[10] = {
		[268] = 100780, -- Brewmaster → Tiger Palm
		[269] = 100780, -- Windwalker → Tiger Palm
		[270] = 116670 -- Mistweaver → Vivify
	},

	-- Druid (classID 11)
	[11] = {
		[102] = 5176, -- Balance → Wrath
		[103] = 1822, -- Feral → Rake
		[104] = 33917, -- Guardian → Mangle
		[105] = 8936 -- Restoration → Regrowth
	},

	-- Demon Hunter (classID 12)
	[12] = {
		[577] = 162243, -- Havoc → Demon Bite
		[581] = 203782, -- Vengeance → Shear
		[1480] = 473662 -- Devourer → Consume
	},

	-- Evoker (classID 13)
	[13] = {
		[1467] = 362969, -- Devastation → Azure Strike
		[1468] = 362969, -- Preservation → Azure Strike
		[1473] = 361469 -- Augmentation → Eruption
	}
}

--------------------------------------------------
-- DEFAULTS
--------------------------------------------------

local defaults = {
	profile = {
		-- General settings
		displayMode = "TEXT",
		testModeEnabled = false,
		showInCombatOnly = true,

		-- Text Settings
		outRangeText = "Out of Range",
		font = "Friz Quadrata TT",
		fontSize = 18,

		-- Texture settings
		textureChoice = "DoubleCrescent",
		texturePath = "Interface\\AddOns\\ClassRangeCheck\\Media\\double_crescent.tga",
		textureSizeX = 120,
		textureSizeY = 120,

		-- Shared Settings
		color = { 1, 0, 0, 1 },
		posX = 0,
		posY = 0,
		updateInterval = 0.33,

		-- Class/Spec Spells
		spellDictionary = {}
	}
}

--------------------------------------------------
-- Load Libraries
--------------------------------------------------
CRC.AceDb = LibStub("AceDB-3.0")
CRC.AceConfig = LibStub("AceConfig-3.0")
CRC.AceConfigDialog = LibStub("AceConfigDialog-3.0")

--------------------------------------------------
-- GLOBAL VARIABLES
--------------------------------------------------
CRC.globals = {}
CRC.globals.cachedSpellId = nil
CRC.globals.cachedEnabled = nil
CRC.globals.updateTicker = nil
CRC.globals.unlockedFrameEnabled = nil

--------------------------------------------------
-- CONSTANTS
--------------------------------------------------
CRC.constants = {}
CRC.constants.addonName = "ClassRangeCheck"
CRC.constants.mediaPath = "Interface\\AddOns\\ClassRangeCheck\\Media\\"
CRC.constants.databaseName = "ClassRangeCheckDB1"

--------------------------------------------------
-- INIT Cache
--------------------------------------------------
function CRC:CachePlayerInfo()
	local specID = PlayerUtil.GetCurrentSpecID()
	local _, _, classId = UnitClass("player")

	local classTable = self.db.profile.spellDictionary[classId]
	if not classTable then return end

	local spec = classTable[specID]
	if not spec then return end

	self.globals.cachedSpellId = spec.spellId
	self.globals.cachedEnabled = spec.enabled
end
CRC.db = CRC.AceDb:New(CRC.constants.databaseName, defaults, true)

if next(CRC.db.profile.spellDictionary) == nil then
	for classId, specs in pairs(defaultSpells) do
		CRC.db.profile.spellDictionary[classId] = {}

		for specId, spellId in pairs(specs) do
			CRC.db.profile.spellDictionary[classId][specId] = {
				enabled = true,
				spellId = spellId
			}
		end
	end
end