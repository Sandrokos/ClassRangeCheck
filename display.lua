local _, CRC = ...

--------------------------------------------------
-- DISPLAY
--------------------------------------------------
local frame = CreateFrame("Frame", "ClassRangeCheckFrame", UIParent)
CRC.frame = frame

local moveFrame = CreateFrame("Frame", nil, UIParent, "BackdropTemplate")
CRC.moveFrame = moveFrame

frame:SetSize(240,60)
frame:SetPoint("CENTER")

-- initialize frame drag scripts
frame:RegisterForDrag("LeftButton")
frame:SetScript("OnDragStart", function(self)
	if self.db.profile.testMode then self:StartMoving() end
end)
frame:SetScript("OnDragStop", function(self)
	if self.db.profile.testMode then
		self:StopMovingOrSizing()
		local x, y = self:GetCenter()
		local ux, uy = UIParent:GetCenter()
		self.db.profile.posX = x - ux
		self.db.profile.posY = y - uy
	end
end)

frame.text = frame:CreateFontString(nil,"OVERLAY")
frame.text:SetPoint("CENTER")

frame.icon = frame:CreateTexture(nil,"OVERLAY")
frame.icon:SetPoint("CENTER")

frame.highlight = frame:CreateTexture(nil, "BACKGROUND")

moveFrame.text = moveFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
local resetButton = CreateFrame("Button", nil, moveFrame, "UIPanelButtonTemplate")
CRC.resetButton = resetButton

local lockButton = CreateFrame("Button", nil, moveFrame, "UIPanelButtonTemplate")
CRC.lockButton = lockButton

function CRC:UpdateText()
	local db = self.db.profile
    local font = LibStub("LibSharedMedia-3.0"):Fetch("font", db.font)

    self.frame.text:SetFont(font, db.fontSize, "OUTLINE")
    self.frame.text:SetTextColor(unpack(db.color))
end

function CRC:UpdateTexture()
	local db = self.db.profile

    self.frame.icon:SetSize(db.textureSizeX, db.textureSizeY)
    self.frame.icon:SetTexture(db.texturePath)
    self.frame.icon:SetVertexColor(unpack(db.color))
end

function CRC:InitDisplay()
    local db = self.db.profile
    self.frame.text:SetSize(240, 60)
    self.frame.text:SetPoint("CENTER", UIParent, "CENTER", db.posX, db.posY)
    CRC:UpdateText()
    self.frame.text:SetText(db.outRangeText)
    self.frame.text:Hide()

    self.frame.icon:SetPoint("CENTER")
    CRC:UpdateTexture()
    self.frame.icon:Hide()

	self.frame.highlight:SetAllPoints(self.frame)
	self.frame.highlight:SetColorTexture(1, 1, 0, 0.2)
	self.frame.highlight:Hide()
end

-- MINI FRAME for drag options
function CRC:InitMoveFrame()
    self.moveFrame:SetSize(300, 150)
    self.moveFrame:SetPoint("TOP", UIParent, "TOP", 0, -30)
    self.moveFrame:SetBackdrop({
        bgFile = "Interface/Tooltips/UI-Tooltip-Background",
        edgeFile = "Interface/Tooltips/UI-Tooltip-Border",
        edgeSize = 14,
    })
    self.moveFrame:SetBackdropColor(0, 0, 0, 0.8)
    self.moveFrame:Hide()

    self.moveFrame.text:SetPoint("TOP", 0, -10)
    self.moveFrame.text:SetText("Move Range Text")

    
    self.resetButton:SetSize(120, 26)
    self.resetButton:SetPoint("CENTER", 0, 10)
    self.resetButton:SetText("Reset to Default")
    self.resetButton:SetScript("OnClick", function()
        self.db.profile.posX = 0
        self.db.profile.posY = 0
        self.frame:ClearAllPoints()
        self.frame.text:SetPoint("CENTER", UIParent, "CENTER", 0, 0)
    end)

    self.lockButton:SetSize(120, 26)
    self.lockButton:SetPoint("BOTTOM", 0, 10)
    self.lockButton:SetText("Lock Position")
end