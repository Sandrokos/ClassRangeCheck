local _, CRC = ...

CRC.mediaTextures = {
    Circle = CRC.constants.mediaPath .. "circle.tga",
    Crosshair = CRC.constants.mediaPath .. "crosshair.tga",
    Ring = CRC.constants.mediaPath .. "ring.tga",
    Moon = CRC.constants.mediaPath .. "moon.tga",
    DoubleCrescent = CRC.constants.mediaPath .. "double_crescent.tga"
}

CRC.mediaTextureValues = {}

for name, path in pairs(CRC.mediaTextures) do
    CRC.mediaTextureValues[name] = "|T" .. path .. ":16:16|t "
end