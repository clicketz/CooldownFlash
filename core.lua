local addonName, ns = ...

-- Performance Upvalues
local GetTime = GetTime
local C_Spell = C_Spell
local GetSpellCooldown = C_Spell.GetSpellCooldown
local GetSpellInfo = C_Spell.GetSpellInfo

-- Constants
local VALID_ERRORS = {
    [ERR_ABILITY_COOLDOWN] = true,
    [ERR_SPELL_COOLDOWN]   = true,
}
local TIME_THRESHOLD = 0.2

-- State
local lastFailedSpellID = nil
local lastFailedTime = 0

-- ----------------------------------------------------------------------------
-- Core Visual Logic
-- ----------------------------------------------------------------------------

-- Shared function to display the frame (used by Trigger and Test)
local function DisplayFlash(texture, startTime, duration, modRate)
    if not ns.frame then return end

    ns.frame.icon:SetTexture(texture)
    -- Use SetCooldown directly to handle Secret values safely
    ns.frame.cooldown:SetCooldown(startTime, duration, modRate)

    ns.frame:Show()
    ns.frame:SetAlpha(1)

    -- Restart animation
    ns.frame.ag:Stop()
    ns.frame.ag:Play()
end

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
    DisplayFlash(134400, GetTime(), 10, 1) -- 134400 is "Interface/Icons/QuestionMark"
end

function ns.TriggerFlash(spellID)
    if CooldownFlashDB.ignoredSpells and CooldownFlashDB.ignoredSpells[spellID] then return end

    local cdInfo = GetSpellCooldown(spellID)
    if not cdInfo or cdInfo.isOnGCD then return end

    local spellInfo = GetSpellInfo(spellID)
    if not spellInfo then return end

    DisplayFlash(spellInfo.iconID, cdInfo.startTime, cdInfo.duration, cdInfo.modRate)
end

-- ----------------------------------------------------------------------------
-- Event Handling
-- ----------------------------------------------------------------------------
local function OnGameplayEvent(self, event, ...)
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
local function OnLoad(self, event, name)
    if name ~= addonName then return end

    ns.Config.InitDB()
    ns.CreateFlashFrame()
    ns.SetupOptions()

    local eventFrame = CreateFrame("Frame")
    eventFrame:RegisterEvent("UNIT_SPELLCAST_FAILED")
    eventFrame:RegisterEvent("UI_ERROR_MESSAGE")
    eventFrame:SetScript("OnEvent", OnGameplayEvent)

    self:UnregisterEvent("ADDON_LOADED")
end

local loader = CreateFrame("Frame")
loader:RegisterEvent("ADDON_LOADED")
loader:SetScript("OnEvent", OnLoad)
