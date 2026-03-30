local addonName, ns = ...

-- Upvalues
local GetTime = GetTime
local GetSpellCooldown = C_Spell.GetSpellCooldown
local GetSpellCooldownDuration = C_Spell.GetSpellCooldownDuration
local GetSpellInfo = C_Spell.GetSpellInfo
local GetCursorPosition = GetCursorPosition
local InCombatLockdown = InCombatLockdown

-- Constants
local SPAM_THROTTLE = 0.1
local SUCCESS_GRACE_PERIOD = 1.0 -- Seconds to ignore errors after a successful cast
local BASE_SIZE = 36             -- Standard Blizzard ActionButton size

-- State
local lastFlashTime = 0
local lastSuccessTime = {} -- [spellID] = timestamp

-- Screen Metrics Cache
local cachedUIScale = 1
local cachedScreenW = 0
local cachedScreenH = 0

-- Test
local testDurationObj

local function RefreshScreenMetrics()
    cachedUIScale = UIParent:GetEffectiveScale()
    cachedScreenW = UIParent:GetWidth()
    cachedScreenH = UIParent:GetHeight()
end

local function CursorTracker_OnUpdate(self)
    local cursorX, cursorY = GetCursorPosition()

    -- convert absolute cursor position to UIParent coordinates
    local uiX = cursorX / cachedUIScale
    local uiY = cursorY / cachedUIScale

    local frameScale = self:GetScale()
    local halfSize = (BASE_SIZE * frameScale) / 2

    local offsetX = CooldownFlashDB.posX
    local offsetY = CooldownFlashDB.posY

    local targetX = uiX + offsetX
    local targetY = uiY + offsetY

    -- boundary checks (flip the offset if we push off the edge of the screen)
    local offLeft = (targetX - halfSize) < 0
    local offRight = (targetX + halfSize) > cachedScreenW
    local offBottom = (targetY - halfSize) < 0
    local offTop = (targetY + halfSize) > cachedScreenH

    if offLeft or offRight then
        offsetX = -offsetX
        targetX = uiX + offsetX
    end
    if offBottom or offTop then
        offsetY = -offsetY
        targetY = uiY + offsetY
    end

    -- final clamp to guarantee it stays entirely visible on screen
    if targetX - halfSize < 0 then targetX = halfSize end
    if targetX + halfSize > cachedScreenW then targetX = cachedScreenW - halfSize end
    if targetY - halfSize < 0 then targetY = halfSize end
    if targetY + halfSize > cachedScreenH then targetY = cachedScreenH - halfSize end

    -- convert back to the frame's local scaled coordinate space for SetPoint
    local finalX = targetX / frameScale
    local finalY = targetY / frameScale

    if self._lastX ~= finalX or self._lastY ~= finalY then
        self:ClearAllPoints()
        self:SetPoint("CENTER", UIParent, "BOTTOMLEFT", finalX, finalY)
        self._lastX = finalX
        self._lastY = finalY
    end
end

local function DisplayFlash(spellID, texture, durationObj)
    if ns.frame:IsShown() and ns.frame.currentSpellID == spellID and ns.frame.ag:IsPlaying() then
        return
    end

    ns.frame.currentSpellID = spellID
    ns.frame.Icon:SetTexture(texture)

    ns.frame.Cooldown:SetCooldownFromDurationObject(durationObj)

    if CooldownFlashDB.anchor == "Cursor" then
        ns.frame:SetScript("OnUpdate", CursorTracker_OnUpdate)
    else
        ns.frame:SetScript("OnUpdate", nil)
        ns.frame._lastX = nil
        ns.frame._lastY = nil
    end

    ns.frame:Show()
    ns.frame:SetAlpha(1)

    ns.frame.ag:Stop()
    ns.frame.ag:Play()
end

function ns.CreateFlashFrame()
    local f = CreateFrame("Button", "CooldownFlashFrame", UIParent)
    f:Hide()
    f:EnableMouse(false)

    f.Icon = f:CreateTexture(nil, "BACKGROUND")
    f.Icon:SetAllPoints()

    -- Create our own textures so we don't have to deal
    -- with fixing actionbuttontemplate regions

    -- Masque attaches the skin's border to this region.
    f.Normal = f:CreateTexture(nil, "BORDER")
    f.Normal:SetAllPoints()
    f.Normal:SetTexture(nil)

    -- pushed texture (unused atm)
    f.Pushed = f:CreateTexture(nil, "ARTWORK")
    f.Pushed:SetAllPoints()
    f.Pushed:SetTexture(nil)
    f:SetPushedTexture(f.Pushed)

    -- highlight texture (unused atm)
    f.Highlight = f:CreateTexture(nil, "HIGHLIGHT")
    f.Highlight:SetAllPoints()
    f.Highlight:SetTexture(nil)
    f:SetHighlightTexture(f.Highlight)

    -- cooldown spiral
    f.Cooldown = CreateFrame("Cooldown", "$parentCooldown", f, "CooldownFrameTemplate")
    f.Cooldown:SetAllPoints()
    f.Cooldown:SetDrawEdge(false)

    -- animation
    f.ag = f:CreateAnimationGroup()
    f.alphaAnim = f.ag:CreateAnimation("Alpha")
    f.alphaAnim:SetFromAlpha(1)
    f.alphaAnim:SetToAlpha(0)
    f.alphaAnim:SetSmoothing("OUT")
    f.ag:SetScript("OnFinished", function()
        f:Hide()
        f:SetScript("OnUpdate", nil)
        f._lastX = nil
        f._lastY = nil
    end)

    ns.frame = f

    -- apply settings before skinning for masque
    ns.ApplySettings()
    ns.Skin.Register(f)
end

function ns.ApplySettings()
    -- lock the frame to BASE_SIZE and use scale so subregions scale properly
    local userSize = CooldownFlashDB.iconSize
    local scale = userSize / BASE_SIZE

    ns.frame:SetSize(BASE_SIZE, BASE_SIZE)
    ns.frame:SetScale(scale)

    if CooldownFlashDB.anchor ~= "Cursor" then
        local x = CooldownFlashDB.posX / scale
        local y = CooldownFlashDB.posY / scale
        ns.frame:ClearAllPoints()
        ns.frame:SetPoint("CENTER", UIParent, "CENTER", x, y)
        ns.frame:SetScript("OnUpdate", nil)
    end

    ns.frame.alphaAnim:SetDuration(CooldownFlashDB.fadeDuration)
    ns.frame.alphaAnim:SetStartDelay(CooldownFlashDB.fadeDelay)

    ns.Skin.ReSkin()
end

function ns.TestFlash()
    testDurationObj:SetTimeFromStart(GetTime(), 10, 1)

    -- 0 ID for test, 134400 is "Interface/Icons/QuestionMark"
    DisplayFlash(0, 134400, testDurationObj)
end

local function TryFlash(spellID)
    if CooldownFlashDB.ignoredSpells[spellID] then return end

    local now = GetTime()
    if (now - lastFlashTime) < SPAM_THROTTLE then return end

    local lastSuccess = lastSuccessTime[spellID]
    if lastSuccess and (now - lastSuccess) < SUCCESS_GRACE_PERIOD then return end

    local cdInfo = GetSpellCooldown(spellID)
    if not cdInfo or cdInfo.isOnGCD then return end

    if cdInfo.isActive then
        local spellInfo = GetSpellInfo(spellID)
        if spellInfo then
            lastFlashTime = now
            local durationObj = GetSpellCooldownDuration(spellID)
            DisplayFlash(spellID, spellInfo.iconID, durationObj)
        end
    end
end

local function OnGameplayEvent(self, event, ...)
    if event == "UNIT_SPELLCAST_FAILED" then
        local _, _, spellID = ...
        TryFlash(spellID)
    elseif event == "UNIT_SPELLCAST_SUCCEEDED" then
        local _, _, spellID = ...
        -- Store the time we successfully cast this spell
        lastSuccessTime[spellID] = GetTime()
    elseif event == "UI_SCALE_CHANGED" or event == "DISPLAY_SIZE_CHANGED" then
        RefreshScreenMetrics()
    end
end

local function OpenSettings()
    if InCombatLockdown() then
        print("|cfffffd8fCooldownFlash|r: Settings cannot be opened while in combat.")
        return
    end

    if Settings and Settings.OpenToCategory then
        Settings.OpenToCategory(ns.CategoryID)
    else
        InterfaceOptionsFrame_OpenToCategory(addonName)
    end
end

function CooldownFlash_OpenOptions()
    OpenSettings()
end

function CooldownFlash_OnCompartmentEnter(_, button)
    GameTooltip:SetOwner(button, "ANCHOR_LEFT")
    GameTooltip:SetText(addonName, 1, 1, 1)
    GameTooltip:AddLine("Click to open settings.", 1, 1, 1)
    GameTooltip:Show()
end

function CooldownFlash_OnCompartmentLeave()
    GameTooltip:Hide()
end

-- Slash Handler
function ns.SlashCommandHandler(msg)
    local command = msg:lower()

    if command == "test" then
        ns.TestFlash()
    else
        OpenSettings()
    end
end

function ns.SetupSlashHandler()
    SLASH_COOLDOWNFLASH1 = "/cdf"
    SLASH_COOLDOWNFLASH2 = "/cooldownflash"
    SlashCmdList["COOLDOWNFLASH"] = function(msg) ns.SlashCommandHandler(msg) end
end

-- Initializations
local function OnLoad()
    ns.Config.InitDB()
    RefreshScreenMetrics()

    testDurationObj = C_DurationUtil.CreateDuration()

    ns.CreateFlashFrame()
    ns.SetupOptions()
    ns.SetupSlashHandler()

    local eventFrame = CreateFrame("Frame")
    eventFrame:RegisterUnitEvent("UNIT_SPELLCAST_FAILED", "player")
    eventFrame:RegisterUnitEvent("UNIT_SPELLCAST_SUCCEEDED", "player")
    eventFrame:RegisterEvent("UI_SCALE_CHANGED")
    eventFrame:RegisterEvent("DISPLAY_SIZE_CHANGED")

    eventFrame:SetScript("OnEvent", OnGameplayEvent)
end

EventRegistry:RegisterFrameEventAndCallback("PLAYER_LOGIN", OnLoad)
