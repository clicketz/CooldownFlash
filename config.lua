local _, ns = ...

ns.Config = {}

-- Default settings used if DB is empty
ns.Config.Defaults = {
    iconSize = 40,
    fadeDuration = 1.5,
    fadeDelay = 1,
    posX = 0,
    posY = 150,
    ignoredSpells = {}, -- [spellID] = true
}

-- Initialize the database
function ns.Config.InitDB()
    if not CooldownFlashDB then CooldownFlashDB = {} end

    -- Fill in any missing keys with defaults
    for k, v in pairs(ns.Config.Defaults) do
        if CooldownFlashDB[k] == nil then
            CooldownFlashDB[k] = v
        end
    end
end

ns.Config.InitDB()
