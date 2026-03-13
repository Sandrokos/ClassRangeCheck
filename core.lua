local LSM = LibStub("LibSharedMedia-3.0")
local AceDB = LibStub("AceDB-3.0")


--------------------------------------------------
-- MEDIA PATH
--------------------------------------------------
local mediaPath = "Interface\\AddOns\\ClassRangeCheck\\Media\\"

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
		textureChoice = "Ring",
		texturePath = "Interface\\AddOns\\ClassRangeCheck\\Media\\ring.tga",
		textureSizeX = 20,
		textureSizeY = 20,

		-- Shared Settings
		color = { 1, 0, 0, 1 },
		posX = 0,
		posY = 0,
		updateInterval = 0.33,

		-- Class/Spec Spells
		spellDictionary = {}
	}
}

local db = AceDB:New("ClassRangeCheckDB1", defaults, true)
if next(db.profile.spellDictionary) == nil then
	for classId, specs in pairs(defaultSpells) do
		db.profile.spellDictionary[classId] = {}

		for specId, spellId in pairs(specs) do
			db.profile.spellDictionary[classId][specId] = {
				enabled = true,
				spellId = spellId
			}
		end
	end
end

--------------------------------------------------
-- GLOBAL VARIABLES
--------------------------------------------------
local cachedSpellId = nil
local cachedEnabled = nil
local updateTicker = nil
local unlockedFrameEnabled = nil

local MediaTextures = {
    Circle         = "Interface\\AddOns\\ClassRangeCheck\\Media\\circle.tga",
    Crosshair      = "Interface\\AddOns\\ClassRangeCheck\\Media\\crosshair.tga",
    Ring         	= "Interface\\AddOns\\ClassRangeCheck\\Media\\ring.tga",
    Moon       		= "Interface\\AddOns\\ClassRangeCheck\\Media\\moon.tga",
    DoubleCrescent = "Interface\\AddOns\\ClassRangeCheck\\Media\\double_crescent.tga",
}

local MediaTextureValues = {}

for name, path in pairs(MediaTextures) do
    local displayName = name:gsub("%.tga$", "")
    MediaTextureValues[displayName] = "|T" .. path .. ":16:16|t "
end

--------------------------------------------------
-- DISPLAY
--------------------------------------------------
local rangeTextFrame = CreateFrame("Frame", "ClassRangeCheckFrame", UIParent)

local rangeTextFontSettings = rangeTextFrame:CreateFontString(nil, "OVERLAY")

local iconFrame = rangeTextFrame:CreateTexture(nil, "OVERLAY")
iconFrame:SetPoint("CENTER")
iconFrame:SetSize(db.profile.textureSizeX, db.profile.textureSizeY) -- default size, will scale later
iconFrame:Hide()

local highlight = rangeTextFrame:CreateTexture(nil, "BACKGROUND")
highlight:SetAllPoints(rangeTextFrame)
highlight:SetColorTexture(1, 1, 0, 0.2)
highlight:Hide()

local function UpdateText()
	local fontPath = LSM:Fetch("font", db.profile.font)
		or LSM:Fetch("font", "Friz Quadrata TT")
	rangeTextFontSettings:SetFont(fontPath, db.profile.fontSize, "OUTLINE")

	local color = db.profile.color or { 1, 0, 0, 1 }
	rangeTextFontSettings:SetTextColor(color[1], color[2], color[3], color[4])
end

local function UpdateTexture()
	local sizeX = db.profile.textureSizeX or defaults.profile.textureSizeX
	local sizeY = db.profile.textureSizeY or defaults.profile.textureSizeY
	iconFrame:SetSize(sizeX, sizeY)

	local texturePath = db.profile.texturePath or defaults.profile.texturePath
	iconFrame:SetTexture(texturePath)

	local color = db.profile.color or { 1, 0, 0, 1 }
	iconFrame:SetVertexColor(color[1], color[2], color[3], color[4])
end

local function InitDisplay()

		rangeTextFrame:SetSize(240, 60)
		rangeTextFrame:SetPoint("CENTER", UIParent, "CENTER", db.profile.posX, db.profile.posY)

		rangeTextFontSettings:SetPoint("CENTER")
		UpdateText()
		rangeTextFontSettings:SetText(db.profile.outRangeText)
	
		iconFrame:SetPoint("CENTER")
		UpdateTexture()


	-- highlight for dragging feedback
	highlight:SetAllPoints(rangeTextFrame)
	highlight:SetColorTexture(1, 1, 0, 0.2)
	highlight:Hide()
end

-- MINI FRAME for drag options
local moveFrame = CreateFrame("Frame", nil, UIParent, "BackdropTemplate")
moveFrame:SetSize(300, 150)
moveFrame:SetPoint("TOP", UIParent, "TOP", 0, -30)

moveFrame:SetBackdrop({
	bgFile = "Interface/Tooltips/UI-Tooltip-Background",
	edgeFile = "Interface/Tooltips/UI-Tooltip-Border",
	edgeSize = 14,
})
moveFrame:SetBackdropColor(0, 0, 0, 0.8)
moveFrame:Hide()

local moveText = moveFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
moveText:SetPoint("TOP", 0, -10)
moveText:SetText("Move Range Text")

local resetTextButton = CreateFrame("Button", nil, moveFrame, "UIPanelButtonTemplate")
resetTextButton:SetSize(120, 26)
resetTextButton:SetPoint("CENTER", 0, 10)
resetTextButton:SetText("Reset to Default")
resetTextButton:SetScript("OnClick", function()
	db.profile.posX = 0
	db.profile.posY = 0
	rangeTextFrame:ClearAllPoints()
	rangeTextFrame:SetPoint("CENTER", UIParent, "CENTER", 0, 0)
end)

local lockButton = CreateFrame("Button", nil, moveFrame, "UIPanelButtonTemplate")
lockButton:SetSize(120, 26)
lockButton:SetPoint("BOTTOM", 0, 10)
lockButton:SetText("Lock Position")

-- initialize frame drag scripts
rangeTextFrame:RegisterForDrag("LeftButton")
rangeTextFrame:SetScript("OnDragStart", function(self)
	if db.profile.testMode then self:StartMoving() end
end)
rangeTextFrame:SetScript("OnDragStop", function(self)
	if db.profile.testMode then
		self:StopMovingOrSizing()
		local x, y = self:GetCenter()
		local ux, uy = UIParent:GetCenter()
		db.profile.posX = x - ux
		db.profile.posY = y - uy
	end
end)

--------------------------------------------------
-- INIT Cache
--------------------------------------------------
local function CachePlayerInfo()
	local specID = PlayerUtil.GetCurrentSpecID()
	local _, _, classId = UnitClass("player")

	local classTable = db.profile.spellDictionary[classId]
	if not classTable then return end

	local spec = classTable[specID]
	if not spec then return end

	cachedSpellId = spec.spellId
	cachedEnabled = spec.enabled
end

--------------------------------------------------
-- RANGE CHECK LOGIC
--------------------------------------------------
local function ShowOutOfRange()
	if db.profile.displayMode == "TEXT" then
		rangeTextFontSettings:SetText(db.profile.outRangeText)
		iconFrame:Hide()
	else
		rangeTextFontSettings:SetText("")
		iconFrame:Show()
	end
end

local function CheckRange()
	if db.profile.testMode then
		ShowOutOfRange()
		return
	end

	if not cachedEnabled then
		rangeTextFontSettings:SetText("")
		iconFrame:Hide()
		return
	end

	if db.profile.showInCombatOnly and not UnitAffectingCombat("player") then
		rangeTextFontSettings:SetText("")
		iconFrame:Hide()
		return
	end

	if not UnitExists("target") or not UnitCanAttack("player", "target") then
		rangeTextFontSettings:SetText("")
		iconFrame:Hide()
		return
	end

	if not cachedSpellId then
		rangeTextFontSettings:SetText("")
		iconFrame:Hide()
		return
	end

	local inRange = C_Spell.IsSpellInRange(cachedSpellId, "target")
	if inRange == false then
		ShowOutOfRange()
	else
		rangeTextFontSettings:SetText("")
		iconFrame:Hide()
	end
end

local function StartUpdateTicker()
	if updateTicker then
		updateTicker:Cancel()
	end
	updateTicker = C_Timer.NewTicker(db.profile.updateInterval, CheckRange)
end

local function RestartTicker()
	if updateTicker then
		updateTicker:Cancel()
		updateTicker = nil
	end
	StartUpdateTicker()
end

local AceConfig = LibStub("AceConfig-3.0")
local AceConfigDialog = LibStub("AceConfigDialog-3.0")

-- MOVABLE RANGE TEXT
local function UnlockFrame()
	-- hide the AceConfig options panel
	if AceConfigDialog.OpenFrames and AceConfigDialog.OpenFrames["ClassRangeCheck"] then
		AceConfigDialog:Close("ClassRangeCheck")
	end

	db.profile.testMode = true
	rangeTextFrame:EnableMouse(true)
	rangeTextFrame:SetMovable(true)

	highlight:Show()
	moveFrame:Show()
end

local function LockFrame()
	db.profile.testMode = false
	rangeTextFrame:EnableMouse(false)
	rangeTextFrame:SetMovable(false)
	unlockedFrameEnabled = false
	highlight:Hide()
	moveFrame:Hide()

	-- show the AceConfig options panel again
	C_Timer.After(0.1, function()
		AceConfigDialog:Open("ClassRangeCheck")
	end)
end

lockButton:SetScript("OnClick", function()
	LockFrame()
end)


local function BuildClassSpellOptions()
	local options = {}
	for classId, specs in pairs(db.profile.spellDictionary) do
		local className, classTag = GetClassInfo(classId)
		if not className then
			className = "Class " .. classId
			classTag = "class" .. classId
		end

		options[classTag] = {
			type = "group",
			name = className,
			order = classId,
			args = {}
		}

		for specId, _ in pairs(specs) do
			local specName = select(2, GetSpecializationInfoByID(specId)) or ("Spec " .. specId)
			options[classTag].args["spec" .. specId] = {
				type = "group",
				name = specName,
				inline = true,
				args = {
					enabled = {
						type = "toggle",
						name = "Enable",
						get = function()
							return db.profile.spellDictionary[classId][specId].enabled
						end,
						set = function(_, v)
							db.profile.spellDictionary[classId][specId].enabled = v
						end
					},
					spell = {
						type = "input",
						name = "Spell ID",
						get = function()
							return tostring(db.profile.spellDictionary[classId][specId].spellId or "")
						end,
						set = function(_, v)
							local id = tonumber(v)
							if id and C_Spell.GetSpellInfo(id) then
								db.profile.spellDictionary[classId][specId].spellId = id
							end
						end
					},
					spellName = {
						type = "description",
						name = function()
							local spellId = db.profile.spellDictionary[classId][specId].spellId
							local spellInfo = C_Spell.GetSpellInfo(spellId)
							if spellInfo then
								return "|T" .. spellInfo.iconID .. ":16|t " .. spellInfo.name
							else
								return "Invalid Spell"
							end
						end
					}
				}
			}
		end
	end
	return options
end

local options = {
	type = "group",
	name = "Class Range Check",
	args = {
		general = {
			type = "group",
			name = "General",
			order = 1,
			args = {
				testMode = {
					type = "toggle",
					name = "Test Mode",
					get = function() return db.profile.testMode end,
					set = function(_, v) db.profile.testMode = v end,
					order = 1
				},
				unlockFrame = {
					type = "execute",
					name = "Unlock Frame",
					func = function()
						unlockedFrameEnabled = true
						UnlockFrame()
					end,
					order = 2
				},
				showInCombat = {
					type = "toggle",
					name = "Only Show in Combat?",
					get = function() return db.profile.showInCombatOnly end,
					set = function(_, v) db.profile.showInCombatOnly = v end,
					order = 3
				},
				updateInterval = {
					type = "range",
					name = "Update Interval",
					min = 0.01,
					max = 1,
					step = 0.01,
					get = function() return db.profile.updateInterval end,
					set = function(_, v)
						db.profile.updateInterval = v
						RestartTicker()
					end,
					order = 4
				},
				color = {
					type = "color",
					name = "Color",
					get = function()
						local c = db.profile.color
						return c[1], c[2], c[3], c[4]
					end,
					set = function(_, r, g, b, a)
						db.profile.color = { r, g, b, a }
						UpdateText()
						UpdateTexture()
					end,
					order = 5
				},
				displayMode = {
					type = "select",
					name = "Display Mode",
					values =
					{
						TEXT = "TEXT",
						TEXTURE = "TEXTURE"
					},
					get = function()
						return db.profile.displayMode
					end,
					set = function(_, v)
						db.profile.displayMode = v
						RestartTicker()
					end,
					order = 6
				}
			},
		},
			textSettings = {
				type = "group",
				name = "Text",
				order = 2,
				hidden = function() return db.profile.displayMode ~= "TEXT" end,
				args = {
					text = {
						type = "input",
						name = "Out of Range Text",
						get = function() return db.profile.outRangeText end,
						set = function(_, v) db.profile.outRangeText = v end
					},
					font = {
						type = "select",
						dialogControl = "LSM30_Font",
						name = "Font",
						values = AceGUIWidgetLSMlists.font,
						get = function() return db.profile.font end,
						set = function(_, v)
							db.profile.font = v
							UpdateText()
						end
					},
					fontSize = {
						type = "range",
						name = "Font Size",
						min = 8,
						max = 60,
						step = 1,
						get = function() return db.profile.fontSize end,
						set = function(_, v)
							db.profile.fontSize = v
							UpdateText()
						end
					},
				}
			},
			textureSettings = {
				type = "group",
				name = "Texture",
				order = 3,
				hidden = function() return db.profile.displayMode ~= "TEXTURE" end,
				args = {
					texture = {
						type = "select",
						name = "Texture",
						values = MediaTextureValues,
						get = function() return db.profile.textureChoice end,
						set = function(_, v) 
							db.profile.textureChoice = v
							db.profile.texturePath = MediaTextures[v]
							UpdateTexture() end
					},
					textureSizeX = {
						type = "range",
						name = "Texture Size X",
						min = 10,
						max = 500,
						step = 10,
						get = function() return db.profile.textureSizeX end,
						set = function(_, v)
							db.profile.textureSizeX = v
							UpdateTexture()
						end
					},
					textureSizeY = {
						type = "range",
						name = "Texture Size Y",
						min = 10,
						max = 500,
						step = 10,
						get = function() return db.profile.textureSizeY end,
						set = function(_, v)
							db.profile.textureSizeY = v
							UpdateTexture()
						end
					},
				}
			},
			classSpells = {
				type = "group",
				name = "Class Configs",
				order = 4,
				args = BuildClassSpellOptions()
			}
		}
	}



AceConfig:RegisterOptionsTable("ClassRangeCheck", options)

AceConfigDialog:AddToBlizOptions(
	"ClassRangeCheck",
	"ClassRangeCheck"
)

local loader = CreateFrame("Frame")

loader:RegisterEvent("PLAYER_LOGIN")
loader:RegisterEvent("PLAYER_SPECIALIZATION_CHANGED")

loader:SetScript("OnEvent", function(self, event)
	if event == "PLAYER_LOGIN" then
		InitDisplay()
		CachePlayerInfo()
		StartUpdateTicker()
	end

	if event == "PLAYER_SPECIALIZATION_CHANGED" then
		CachePlayerInfo()
	end
end)

SLASH_CRC1 = "/crc"
SLASH_CRC2 = "/classrangecheck"

SlashCmdList["CRC"] = function(msg)
	msg = msg:lower():trim()
	if msg == "reset" then
		-- Reset profile to defaults
		db:ResetProfile()
		ReloadUI()
	else
		AceConfigDialog:Open("ClassRangeCheck")
		-- Use OnHide of the actual options panel
		local aceFrame = AceConfigDialog.OpenFrames and AceConfigDialog.OpenFrames["ClassRangeCheck"]
		if aceFrame and aceFrame.frame then
			aceFrame.frame:HookScript("OnHide", function(self)
				if db.profile.testMode and unlockedFrameEnabled == false then
					db.profile.testMode = false
				end
			end)
		end
	end
end
