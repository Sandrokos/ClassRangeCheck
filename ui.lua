--------------------------------------------------
-- UI
--------------------------------------------------
local _, CRC = ...

-- MOVABLE RANGE TEXT
function CRC:UnlockFrame()
    -- hide the AceConfig options panel
    if self.AceConfigDialog.OpenFrames and self.AceConfigDialog.OpenFrames[self.constants.addonName] then
        self.AceConfigDialog:Close(self.constants.addonName)
    end

    self.db.profile.testMode = true
    self.frame:EnableMouse(true)
    self.frame:SetMovable(true)

    self.frame.highlight:Show()
    self.moveFrame:Show()
end

function CRC:LockFrame()
    self.db.profile.testMode = false
    self.frame:EnableMouse(false)
    self.frame:SetMovable(false)

    self.globals.unlockedFrameEnabled = false

    self.frame.highlight:Hide()
    self.moveFrame:Hide()

    -- show the AceConfig options panel again
    C_Timer.After(0.1, function()
        self.AceConfigDialog:Open(self.constants.addonName)
    end)
end

CRC.lockButton:SetScript("OnClick", function()
    CRC:LockFrame()
end)

local function BuildClassSpellOptions()
    local options = {}
    for classId, specs in pairs(CRC.db.profile.spellDictionary) do
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
                            return CRC.db.profile.spellDictionary[classId][specId].enabled
                        end,
                        set = function(_, v)
                            CRC.db.profile.spellDictionary[classId][specId].enabled = v
                            CRC:CachePlayerInfo()
                        end
                    },
                    spell = {
                        type = "input",
                        name = "Spell ID",
                        get = function()
                            return tostring(CRC.db.profile.spellDictionary[classId][specId].spellId or "")
                        end,
                        set = function(_, v)
                            local id = tonumber(v)
                            if id and C_Spell.GetSpellInfo(id) then
                                CRC.db.profile.spellDictionary[classId][specId].spellId = id
                                CRC:CachePlayerInfo()
                            end
                        end
                    },
                    spellName = {
                        type = "description",
                        name = function()
                            local spellId = CRC.db.profile.spellDictionary[classId][specId].spellId
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
                    get = function() return CRC.db.profile.testMode end,
                    set = function(_, v)
                        CRC.db.profile.testMode = v
                        CRC:CheckRange()
                    end,
                    order = 1
                },
                unlockFrame = {
                    type = "execute",
                    name = "Unlock Frame",
                    func = function()
                        CRC.globals.unlockedFrameEnabled = true
                        CRC:UnlockFrame()
                    end,
                    order = 2
                },
                showInCombat = {
                    type = "toggle",
                    name = "Only Show in Combat?",
                    get = function() return CRC.db.profile.showInCombatOnly end,
                    set = function(_, v) CRC.db.profile.showInCombatOnly = v end,
                    order = 3
                },
                updateInterval = {
                    type = "range",
                    name = "Update Interval",
                    min = 0.01,
                    max = 1,
                    step = 0.01,
                    get = function() return CRC.db.profile.updateInterval end,
                    set = function(_, v)
                        CRC.db.profile.updateInterval = v
                    end,
                    order = 4
                },
                color = {
                    type = "color",
                    name = "Color",
                    get = function()
                        local c = CRC.db.profile.color
                        return c[1], c[2], c[3], c[4]
                    end,
                    set = function(_, r, g, b, a)
                        CRC.db.profile.color = { r, g, b, a }
                        CRC:UpdateText()
                        CRC:UpdateTexture()
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
                        return CRC.db.profile.displayMode
                    end,
                    set = function(_, v)
                        CRC.db.profile.displayMode = v
                        CRC:CheckRange()
                    end,
                    order = 6
                }
            },
        },
        textSettings = {
            type = "group",
            name = "Text",
            order = 2,
            hidden = function() return CRC.db.profile.displayMode ~= "TEXT" end,
            args = {
                text = {
                    type = "input",
                    name = "Out of Range Text",
                    get = function() return CRC.db.profile.outRangeText end,
                    set = function(_, v) CRC.db.profile.outRangeText = v end
                },
                font = {
                    type = "select",
                    dialogControl = "LSM30_Font",
                    name = "Font",
                    values = AceGUIWidgetLSMlists.font,
                    get = function() return CRC.db.profile.font end,
                    set = function(_, v)
                        CRC.db.profile.font = v
                        CRC:UpdateText()
                    end
                },
                fontSize = {
                    type = "range",
                    name = "Font Size",
                    min = 8,
                    max = 60,
                    step = 1,
                    get = function() return CRC.db.profile.fontSize end,
                    set = function(_, v)
                        CRC.db.profile.fontSize = v
                        CRC:UpdateText()
                    end
                },
            }
        },
        textureSettings = {
            type = "group",
            name = "Texture",
            order = 3,
            hidden = function() return CRC.db.profile.displayMode ~= "TEXTURE" end,
            args = {
                texture = {
                    type = "select",
                    name = "Texture",
                    values = CRC.mediaTextureValues,
                    get = function() return CRC.db.profile.textureChoice end,
                    set = function(_, v)
                        CRC.db.profile.textureChoice = v
                        CRC.db.profile.texturePath = CRC.mediaTextures[v]
                        CRC:UpdateTexture()
                    end
                },
                textureSizeX = {
                    type = "range",
                    name = "Texture Size X",
                    min = 10,
                    max = 500,
                    step = 10,
                    get = function() return CRC.db.profile.textureSizeX end,
                    set = function(_, v)
                        CRC.db.profile.textureSizeX = v
                        CRC:UpdateTexture()
                    end
                },
                textureSizeY = {
                    type = "range",
                    name = "Texture Size Y",
                    min = 10,
                    max = 500,
                    step = 10,
                    get = function() return CRC.db.profile.textureSizeY end,
                    set = function(_, v)
                        CRC.db.profile.textureSizeY = v
                        CRC:UpdateTexture()
                    end
                },
            }
        },
        classSpells = {
            type = "group",
            name = "Class Configs",
            order = 4,
            args = {
                info = {
                    type = "description",
                    name =
                    "Select which spell will be used to check range for each specialization. The addon will show the out-of-range text/texture if the spell cannot reach your target.",
                    order = 0,
                    fontSize = "medium",
                }
            }
        }
    }
}

local classOptions = BuildClassSpellOptions()
for k, v in pairs(classOptions) do
	options.args["classSpells"].args[k] = v
end


function CRC:RegisterAceConfig()
    self.AceConfig:RegisterOptionsTable(self.constants.addonName, options)
    self.AceConfigDialog:AddToBlizOptions(
        self.constants.addonName,
        self.constants.addonName
    )
end
