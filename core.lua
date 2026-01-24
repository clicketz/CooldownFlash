local addonName, ns = ...

-- ----------------------------------------------------------------------------
-- Upvalues
-- ----------------------------------------------------------------------------
local GetTime = GetTime
local C_Spell = C_Spell
local GetSpellCooldown = C_Spell.GetSpellCooldown
local GetSpellCharges = C_Spell.GetSpellCharges
local GetSpellInfo = C_Spell.GetSpellInfo
local pairs = pairs

-- ----------------------------------------------------------------------------
-- Configuration
-- ----------------------------------------------------------------------------
ns.Defaults = {
    iconSize = 40,
    fadeDuration = 1.5,
    fadeDelay = 1,
    posX = 0,
    posY = 150,
}

local VALID_ERRORS = {
    [ERR_ABILITY_COOLDOWN] = true,
    [ERR_SPELL_COOLDOWN]   = true,
}

-- State
local lastFailedSpellID = nil
local lastFailedTime = 0
local TIME_THRESHOLD = 0.2
local GLOBAL_GCD_SPELL = 61304

-- ----------------------------------------------------------------------------
-- Visuals
-- ----------------------------------------------------------------------------
function ns.CreateFlashFrame()
    local f = CreateFrame("Frame", "CooldownFlashFrame", UIParent)
    f:SetPoint("CENTER")
    f:Hide()
    f:SetAlpha(0)

    f.icon = f:CreateTexture(nil, "BACKGROUND")
    f.icon:SetAllPoints()

    f.cooldown = CreateFrame("Cooldown", "$parentCooldown", f, "CooldownFrameTemplate")
    f.cooldown:SetAllPoints()
    f.cooldown:SetDrawEdge(false)

    f.ag = f:CreateAnimationGroup()
    f.alphaAnim = f.ag:CreateAnimation("Alpha")
    f.alphaAnim:SetFromAlpha(1)
    f.alphaAnim:SetToAlpha(0)
    f.alphaAnim:SetSmoothing("OUT")

    f.ag:SetScript("OnFinished", function() f:Hide() end)

    ns.frame = f
    ns.ApplySettings()
end

function ns.ApplySettings()
    if not ns.frame then return end

    local size = CooldownFlashDB.iconSize
    ns.frame:SetSize(size, size)

    ns.frame:ClearAllPoints()
    ns.frame:SetPoint("CENTER", UIParent, "CENTER", CooldownFlashDB.posX, CooldownFlashDB.posY)

    ns.frame.alphaAnim:SetDuration(CooldownFlashDB.fadeDuration)
    ns.frame.alphaAnim:SetStartDelay(CooldownFlashDB.fadeDelay)
end

function ns.TestFlash()
    if not ns.frame then return end

    ns.frame.icon:SetTexture(134400) -- Question Mark
    ns.frame.cooldown:SetCooldown(GetTime(), 10, 1)

    ns.frame:Show()
    ns.frame:SetAlpha(1)
    if ns.frame.ag:IsPlaying() then ns.frame.ag:Stop() end
    ns.frame.ag:Play()
end

-- ----------------------------------------------------------------------------
-- Logic
-- ----------------------------------------------------------------------------
function ns.TriggerFlash(spellID)
    local cdInfo = GetSpellCooldown(spellID)
    if not cdInfo or cdInfo.isOnGCD then return end

    local spellInfo = GetSpellInfo(spellID)
    if not spellInfo then return end

    ns.frame.icon:SetTexture(spellInfo.iconID)

    -- Passing secret values directly for C to handle
    ns.frame.cooldown:SetCooldown(cdInfo.startTime, cdInfo.duration, cdInfo.modRate)

    ns.frame:Show()
    ns.frame:SetAlpha(1)

    -- Restart animation without checking IsPlaying
    ns.frame.ag:Stop()
    ns.frame.ag:Play()
end

function ns.OnGameplayEvent(self, event, ...)
    if event == "UNIT_SPELLCAST_FAILED" then
        local unit, _, spellID = ...
        if unit == "player" then
            lastFailedSpellID = spellID
            lastFailedTime = GetTime()
        end
    elseif event == "UI_ERROR_MESSAGE" then
        local _, message = ...

        if VALID_ERRORS[message] then
            if (GetTime() - lastFailedTime) < TIME_THRESHOLD then
                if lastFailedSpellID then
                    ns.TriggerFlash(lastFailedSpellID)
                end
            end
        end
    end
end

function ns.SetupGameplayEvents()
    local eventFrame = CreateFrame("Frame")
    eventFrame:RegisterEvent("UNIT_SPELLCAST_FAILED")
    eventFrame:RegisterEvent("UI_ERROR_MESSAGE")
    eventFrame:SetScript("OnEvent", ns.OnGameplayEvent)
end

-- ----------------------------------------------------------------------------
-- Minimap / Addon Compartment
-- ----------------------------------------------------------------------------
function CooldownFlash_OpenOptions()
    if ns.CategoryID then
        Settings.OpenToCategory(ns.CategoryID)
    end
end

function CooldownFlash_OnCompartmentEnter(addonName, button)
    GameTooltip:SetOwner(button, "ANCHOR_LEFT")
    GameTooltip:SetText("CooldownFlash")
    GameTooltip:AddLine("Click to open settings.", 1, 1, 1)
    GameTooltip:Show()
end

function CooldownFlash_OnCompartmentLeave()
    GameTooltip:Hide()
end

-- ----------------------------------------------------------------------------
-- Init
-- ----------------------------------------------------------------------------
function ns.InitDB()
    CooldownFlashDB = CooldownFlashDB or {}
    for k, v in pairs(ns.Defaults) do
        if CooldownFlashDB[k] == nil then
            CooldownFlashDB[k] = v
        end
    end
end

function ns.OnLoad(self, event, name)
    if name ~= addonName then return end

    ns.InitDB()
    ns.CreateFlashFrame()
    ns.SetupOptions()
    ns.SetupGameplayEvents()

    self:UnregisterEvent("ADDON_LOADED")
end

local loader = CreateFrame("Frame")
loader:RegisterEvent("ADDON_LOADED")
loader:SetScript("OnEvent", ns.OnLoad)
