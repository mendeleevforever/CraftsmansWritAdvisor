local addonName, ns = ...

-- ============================================================
-- Window: dark leather with gold trim, one section per tier,
-- rows sorted by cost per reputation. Nothing here is protected.
-- ============================================================

local FRAME_NAME = "CraftsmansWritAdvisorFrame"
local WINDOW_W, WINDOW_H = 900, 666
local ROW_H, SECTION_H, MORE_H = 18, 40, 16
local SCROLL_LEFT = 20
local CHILD_W = 830

local MainFrame
local ROW_POOL, SECTION_POOL = {}, {}

-- Palette (r, g, b)
local C = {
    bg        = { 0.118, 0.082, 0.051 },
    gold      = { 0.541, 0.416, 0.173 },
    goldLight = { 0.722, 0.569, 0.235 },
    outline   = { 0.169, 0.118, 0.055 },
    inner     = { 0.290, 0.212, 0.094 },
    rule      = { 0.420, 0.314, 0.137 },
    header    = { 0.831, 0.627, 0.090 },
    text      = { 0.902, 0.839, 0.682 },
    money     = { 0.937, 0.894, 0.784 },
    muted     = { 0.612, 0.553, 0.439 },
    cpr       = { 1.000, 0.957, 0.816 },
}

-- Columns inside a row: x = left edge, w = width
local COLS = {
    rank   = { x = 4,   w = 18 },
    status = { x = 24,  w = 30 },
    order  = { x = 56,  w = 196 },
    prof   = { x = 256, w = 34 },
    zone   = { x = 294, w = 132 },
    writ   = { x = 430, w = 84,  right = true },
    item   = { x = 518, w = 92,  right = true },
    total  = { x = 614, w = 96,  right = true },
    cpr    = { x = 714, w = 108, right = true },
}
local TEXT_COLS = { "status", "order", "prof", "zone", "writ", "item", "total", "cpr" }

local RANK_STYLE = {
    { icon = "Interface\\MoneyFrame\\UI-GoldIcon",   tint = { 1.00, 0.82, 0.00, 0.20 }, color = { 1.00, 0.82, 0.00 } },
    { icon = "Interface\\MoneyFrame\\UI-SilverIcon", tint = { 0.78, 0.78, 0.84, 0.18 }, color = { 0.78, 0.78, 0.82 } },
    { icon = "Interface\\MoneyFrame\\UI-CopperIcon", tint = { 0.77, 0.45, 0.23, 0.24 }, color = { 0.77, 0.45, 0.23 } },
}

local ICON_DONE  = "|TInterface\\RaidFrame\\ReadyCheck-Ready:13:13|t"
local ICON_BAG   = "|TInterface\\Icons\\INV_Misc_Bag_08:13:13|t"
local ICON_STALE = "|TInterface\\Icons\\INV_Misc_PocketWatch_01:13:13|t"

local function Hex(rgb)
    return ("%02x%02x%02x"):format(rgb[1] * 255, rgb[2] * 255, rgb[3] * 255)
end

local function AddBorder(frame, layer, rgb, alpha, thickness, inset)
    local function edge()
        local t = frame:CreateTexture(nil, layer)
        t:SetColorTexture(rgb[1], rgb[2], rgb[3], alpha)
        return t
    end
    local top, bottom, left, right = edge(), edge(), edge(), edge()
    top:SetPoint("TOPLEFT", inset, -inset)
    top:SetPoint("TOPRIGHT", -inset, -inset)
    top:SetHeight(thickness)
    bottom:SetPoint("BOTTOMLEFT", inset, inset)
    bottom:SetPoint("BOTTOMRIGHT", -inset, inset)
    bottom:SetHeight(thickness)
    left:SetPoint("TOPLEFT", inset, -inset)
    left:SetPoint("BOTTOMLEFT", inset, inset)
    left:SetWidth(thickness)
    right:SetPoint("TOPRIGHT", -inset, -inset)
    right:SetPoint("BOTTOMRIGHT", -inset, inset)
    right:SetWidth(thickness)
end

-- ------------------------------------------------------------
-- Row behaviour: hover shows the writ tooltip (with our lines),
-- modified click links it, plain click searches Auctionator.
-- ------------------------------------------------------------
local function RowOnEnter(self)
    if not self.writID then return end
    GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
    if GameTooltip.SetItemByID then
        GameTooltip:SetItemByID(self.writID)
    else
        GameTooltip:SetHyperlink("item:" .. self.writID)
    end
    GameTooltip:Show()
end

local function RowOnLeave()
    GameTooltip:Hide()
end

local function RowOnClick(self)
    if not self.writID then return end
    if IsModifiedClick("CHATLINK") or IsModifiedClick("DRESSUP") then
        local link = ns.ItemLink(self.writID)
        if link and HandleModifiedItemClick then
            HandleModifiedItemClick(link)
        else
            ns.Print("That writ isn't cached yet. Try again in a moment.")
        end
        return
    end
    ns.SearchAuctionator(self.writID)
end

local function GetRow(child, idx)
    if ROW_POOL[idx] then return ROW_POOL[idx] end
    local row = CreateFrame("Button", nil, child)
    row:SetHeight(ROW_H)
    row:RegisterForClicks("LeftButtonUp")

    row.bg = row:CreateTexture(nil, "BACKGROUND")
    row.bg:SetAllPoints()
    local hl = row:CreateTexture(nil, "HIGHLIGHT")
    hl:SetAllPoints()
    hl:SetColorTexture(1, 0.85, 0.4, 0.10)

    row.medal = row:CreateTexture(nil, "ARTWORK")
    row.medal:SetSize(14, 14)
    row.medal:SetPoint("LEFT", COLS.rank.x, 0)

    row.fs = {}
    for _, key in ipairs(TEXT_COLS) do
        local col = COLS[key]
        local font = (key == "cpr") and "GameFontNormal" or "GameFontNormalSmall"
        local fs = row:CreateFontString(nil, "OVERLAY", font)
        fs:SetPoint("LEFT", col.x, 0)
        fs:SetWidth(col.w)
        fs:SetJustifyH(col.right and "RIGHT" or "LEFT")
        fs:SetWordWrap(false)
        row.fs[key] = fs
    end

    row:SetScript("OnEnter", RowOnEnter)
    row:SetScript("OnLeave", RowOnLeave)
    row:SetScript("OnClick", RowOnClick)
    ROW_POOL[idx] = row
    return row
end

local function GetSection(child, idx)
    if SECTION_POOL[idx] then return SECTION_POOL[idx] end
    local sec = {}
    sec.title = child:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    sec.title:SetJustifyH("LEFT")
    sec.sealed = child:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    sec.sealed:SetJustifyH("RIGHT")
    sec.sealed:SetWidth(470)
    sec.summary = child:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    sec.summary:SetJustifyH("LEFT")
    sec.summary:SetWidth(CHILD_W - 12)
    sec.summary:SetWordWrap(false)
    sec.rule = child:CreateTexture(nil, "ARTWORK")
    sec.rule:SetHeight(1)
    sec.more = child:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
    sec.more:SetJustifyH("LEFT")
    SECTION_POOL[idx] = sec
    return sec
end

local function HideSection(sec)
    sec.title:Hide(); sec.sealed:Hide(); sec.summary:Hide(); sec.rule:Hide(); sec.more:Hide()
end

-- ------------------------------------------------------------
-- Customer zone filter. Uses Blizzard's dropdown menu
-- (WowStyle1DropdownTemplate) when the client has it, and falls
-- back to a button that cycles through the zones.
-- ------------------------------------------------------------
local zoneDropdown, zoneCycle

local function RefreshZoneControl()
    if zoneDropdown then
        zoneDropdown:GenerateMenu()
    elseif zoneCycle then
        zoneCycle:SetText(ns.ZoneLabel(ns.db.zoneFilter))
    end
end

function ns.SetZoneFilter(key, fromMenu)
    if key ~= ns.ZONE_ALL and not ns.ZONE_BY_KEY[key] then key = ns.ZONE_ALL end
    ns.db.zoneFilter = key
    if MainFrame then MainFrame.scroll:SetVerticalScroll(0) end
    if fromMenu and C_Timer and C_Timer.After then
        C_Timer.After(0, RefreshZoneControl) -- let the menu close first
    else
        RefreshZoneControl()
    end
    ns.Invalidate()
end

local function ZoneMenuText(z)
    return ("%s  |cff9c8d70(%d)|r"):format(z.label, z.count)
end

local function BuildZoneDropdown(f, anchor)
    local ok, dd = pcall(CreateFrame, "DropdownButton", nil, f, "WowStyle1DropdownTemplate")
    if not ok or not dd then return false end
    if not dd.SetupMenu or not dd.GenerateMenu then
        dd:Hide()
        return false
    end
    dd:SetPoint("LEFT", anchor, "RIGHT", 8, 0)
    dd:SetWidth(230)
    if dd.SetSelectionTranslator then
        dd:SetSelectionTranslator(function() return ns.ZoneLabel(ns.db.zoneFilter) end)
    end
    dd:SetupMenu(function(_, root)
        if root.SetTag then root:SetTag("MENU_CRAFTSMANSWRITADVISOR_ZONE") end
        local function IsSelected(key) return ns.db.zoneFilter == key end
        local function SetSelected(key) ns.SetZoneFilter(key, true) end
        root:CreateRadio("All zones", IsSelected, SetSelected, ns.ZONE_ALL)
        if root.CreateDivider then root:CreateDivider() end
        for _, z in ipairs(ns.ZONES) do
            root:CreateRadio(ZoneMenuText(z), IsSelected, SetSelected, z.key)
        end
        if root.SetScrollMode then root:SetScrollMode(20 * 18) end
    end)
    zoneDropdown = dd
    ns.zoneDropdownStyle = "Blizzard dropdown menu"
    return true
end

local function BuildZoneCycleButton(f, anchor)
    local btn = CreateFrame("Button", nil, f, "UIPanelButtonTemplate")
    btn:SetSize(230, 22)
    btn:SetPoint("LEFT", anchor, "RIGHT", 8, 0)
    btn:RegisterForClicks("LeftButtonUp", "RightButtonUp")
    btn:SetScript("OnClick", function(_, button)
        local keys = { ns.ZONE_ALL }
        local current = 1
        for _, z in ipairs(ns.ZONES) do keys[#keys + 1] = z.key end
        for i, k in ipairs(keys) do
            if k == ns.db.zoneFilter then current = i end
        end
        local step = (button == "RightButton") and -1 or 1
        ns.SetZoneFilter(keys[((current - 1 + step) % #keys) + 1])
    end)
    btn:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_BOTTOM")
        GameTooltip:AddLine("Customer zone")
        GameTooltip:AddLine("Left-click for the next zone, right-click for the previous one.", 1, 1, 1, true)
        GameTooltip:AddLine("/cwa zone <name> jumps straight to a zone.", 0.7, 0.7, 0.7, true)
        GameTooltip:Show()
    end)
    btn:SetScript("OnLeave", function() GameTooltip:Hide() end)
    zoneCycle = btn
    ns.zoneDropdownStyle = "cycle button (Blizzard dropdown template not found)"
end

local function BuildZoneControl(f, x, y)
    local label = f:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    label:SetPoint("TOPLEFT", x, y)
    label:SetText("Customer zone:")
    label:SetTextColor(C.header[1], C.header[2], C.header[3])
    if not BuildZoneDropdown(f, label) then
        BuildZoneCycleButton(f, label)
    end
    RefreshZoneControl()
end

-- ------------------------------------------------------------
-- Frame construction
-- ------------------------------------------------------------
local function MakeCheck(parent, label, key, x, y)
    local cb = CreateFrame("CheckButton", nil, parent, "UICheckButtonTemplate")
    cb:SetSize(22, 22)
    cb:SetPoint("BOTTOMLEFT", x, y)
    local fs = parent:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    fs:SetPoint("LEFT", cb, "RIGHT", 2, 1)
    fs:SetText(label)
    cb:SetScript("OnClick", function(self)
        ns.db[key] = self:GetChecked() and true or false
        ns.Invalidate()
    end)
    cb.key = key
    return cb
end

local function ApplyPosition(f)
    f:ClearAllPoints()
    local w = ns.db.window
    if w and w.point then
        f:SetPoint(w.point, UIParent, w.relPoint or w.point, w.x or 0, w.y or 0)
    else
        f:SetPoint("CENTER")
    end
end

local function MakeMainFrame()
    if MainFrame then return MainFrame end

    local f = CreateFrame("Frame", FRAME_NAME, UIParent)
    f:SetSize(WINDOW_W, WINDOW_H)
    f:SetFrameStrata("DIALOG")
    f:SetMovable(true)
    f:EnableMouse(true)
    f:SetClampedToScreen(true)
    f:RegisterForDrag("LeftButton")
    f:SetScript("OnDragStart", f.StartMoving)
    f:SetScript("OnDragStop", function(self)
        self:StopMovingOrSizing()
        local point, _, relPoint, x, y = self:GetPoint(1)
        ns.db.window = { point = point, relPoint = relPoint, x = x, y = y }
    end)
    f:Hide()
    ApplyPosition(f)
    tinsert(UISpecialFrames, FRAME_NAME) -- Escape closes it

    local bg = f:CreateTexture(nil, "BACKGROUND")
    bg:SetColorTexture(C.bg[1], C.bg[2], C.bg[3], 0.97)
    bg:SetAllPoints()
    AddBorder(f, "BORDER",  C.outline, 1, 2, -2)
    AddBorder(f, "BORDER",  C.gold,    1, 3,  0)
    AddBorder(f, "ARTWORK", C.inner,   1, 1,  3)

    -- Title plate over the top edge
    local plate = CreateFrame("Frame", nil, f)
    plate:SetSize(330, 34)
    plate:SetPoint("TOP", 0, 18)
    plate:SetFrameLevel(f:GetFrameLevel() + 5)
    local pbg = plate:CreateTexture(nil, "BACKGROUND")
    pbg:SetColorTexture(0.165, 0.114, 0.063, 1)
    pbg:SetAllPoints()
    AddBorder(plate, "BORDER", C.outline,   1, 2, -2)
    AddBorder(plate, "BORDER", C.goldLight, 1, 2,  0)
    local icon = plate:CreateTexture(nil, "ARTWORK")
    icon:SetSize(22, 22)
    icon:SetPoint("LEFT", 10, 0)
    icon:SetTexture(134327)
    local title = plate:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    title:SetPoint("CENTER", 12, 0)
    title:SetText("Craftsman's Writ Advisor")
    title:SetTextColor(1, 0.82, 0)

    local close = CreateFrame("Button", nil, f, "UIPanelCloseButton")
    close:SetPoint("TOPRIGHT", -4, -4)
    close:SetScript("OnClick", function() ns.SetShownSafe(f, false) end)

    -- Zone filter row, then the fixed column headers
    BuildZoneControl(f, SCROLL_LEFT, -26)
    local headerY = -64
    local headers = {
        { "order", "Order (item wanted)" }, { "prof", "Prof" }, { "zone", "Customer zone" },
        { "writ", "Writ AH" }, { "item", "Item AH" }, { "total", "Total" }, { "cpr", "Cost / rep" },
    }
    for _, h in ipairs(headers) do
        local col = COLS[h[1]]
        local fs = f:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        fs:SetPoint("TOPLEFT", SCROLL_LEFT + col.x, headerY)
        fs:SetWidth(col.w)
        fs:SetJustifyH(col.right and "RIGHT" or "LEFT")
        fs:SetText(h[2])
        if h[1] == "cpr" then
            fs:SetTextColor(1, 0.82, 0)
        else
            fs:SetTextColor(C.header[1], C.header[2], C.header[3])
        end
    end
    local headRule = f:CreateTexture(nil, "ARTWORK")
    headRule:SetColorTexture(C.rule[1], C.rule[2], C.rule[3], 1)
    headRule:SetPoint("TOPLEFT", SCROLL_LEFT, headerY - 18)
    headRule:SetPoint("TOPRIGHT", -20, headerY - 18)
    headRule:SetHeight(1)

    -- Scrolling body
    local scroll = CreateFrame("ScrollFrame", "CraftsmansWritAdvisorScroll", f, "UIPanelScrollFrameTemplate")
    scroll:SetPoint("TOPLEFT", SCROLL_LEFT, headerY - 22)
    scroll:SetPoint("BOTTOMRIGHT", -40, 80)
    local child = CreateFrame("Frame", nil, scroll)
    child:SetSize(CHILD_W, 10)
    scroll:SetScrollChild(child)

    -- Footer
    local footRule = f:CreateTexture(nil, "ARTWORK")
    footRule:SetColorTexture(C.rule[1], C.rule[2], C.rule[3], 1)
    footRule:SetPoint("BOTTOMLEFT", SCROLL_LEFT, 74)
    footRule:SetPoint("BOTTOMRIGHT", -20, 74)
    footRule:SetHeight(1)

    f.checks = {
        MakeCheck(f, "Hide delivered today",           "hideDone",  SCROLL_LEFT,       46),
        MakeCheck(f, "Owned writs/items count as free", "ownedFree", SCROLL_LEFT + 190, 46),
        MakeCheck(f, "Subtract coin pouch (estimate)",  "pouchNet",  SCROLL_LEFT + 420, 46),
    }

    local legend = f:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    legend:SetPoint("BOTTOMLEFT", SCROLL_LEFT + 4, 28)
    legend:SetJustifyH("LEFT")
    legend:SetTextColor(0.72, 0.65, 0.52)
    legend:SetText(
        "|TInterface\\MoneyFrame\\UI-GoldIcon:12:12|t |TInterface\\MoneyFrame\\UI-SilverIcon:12:12|t "
        .. "|TInterface\\MoneyFrame\\UI-CopperIcon:12:12|t cheapest per tier    "
        .. ICON_DONE .. " delivered today (not ranked)    " .. ICON_BAG .. " writ in bags    "
        .. ICON_STALE .. " old price    |cff9c8d70EST|r no writ price    zone? = unconfirmed")

    local hint = f:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
    hint:SetPoint("BOTTOMLEFT", SCROLL_LEFT + 4, 12)
    hint:SetJustifyH("LEFT")
    f.hint = hint

    local refresh = CreateFrame("Button", nil, f, "UIPanelButtonTemplate")
    refresh:SetSize(110, 24)
    refresh:SetPoint("BOTTOMRIGHT", -20, 44)
    refresh:SetText("Refresh")
    refresh:SetScript("OnClick", function() ns.Invalidate() end)

    f:SetScript("OnShow", function()
        ns.RequestAllItems()
        ns.UpdateAHHint()
        ns.RebuildWindow()
    end)

    f.scroll, f.child = scroll, child
    MainFrame = f
    return f
end

-- ------------------------------------------------------------
-- Public window functions
-- ------------------------------------------------------------
function ns.ToggleWindow(forceShow)
    local f = MakeMainFrame()
    local show = forceShow or not f:IsShown()
    ns.SetShownSafe(f, show)
end

function ns.ResetWindowPosition()
    if MainFrame then ApplyPosition(MainFrame) end
end

function ns.UpdateAHHint()
    if not MainFrame then return end
    local text
    if not ns.AuctionatorAPI() then
        text = "|cffff8040Auctionator not found. Install it and scan the AH to get prices.|r"
    elseif ns.IsAHOpen() then
        text = "|cff40ff40AH open:|r click a row to search for the writ and its item in Auctionator. Shift-click links it."
    else
        text = "Hover a row for details. Shift-click links the writ. With the AH open, click a row to search it in Auctionator."
    end
    MainFrame.hint:SetText(text)
end

local function SetCols(row, r, rank, style)
    local fs = row.fs
    local w = r.writ

    -- Status icons
    local status = ""
    if r.done then status = status .. ICON_DONE end
    if r.ownWrit then status = status .. ICON_BAG end
    if r.stale and not r.done then status = status .. ICON_STALE end
    fs.status:SetText(status)

    -- Order
    local name = ns.OrderName(r)
    if style then
        fs.order:SetText(("%d. %s"):format(rank, name))
        fs.order:SetTextColor(style.color[1], style.color[2], style.color[3])
    else
        fs.order:SetText(name)
        fs.order:SetTextColor(C.text[1], C.text[2], C.text[3])
    end

    fs.prof:SetText(w.prof)
    fs.prof:SetTextColor(C.muted[1], C.muted[2], C.muted[3])
    fs.zone:SetText(w.zone or ns.DASH)
    fs.zone:SetTextColor(C.muted[1], C.muted[2], C.muted[3])

    -- Writ price
    if ns.db.ownedFree and r.ownWrit then
        fs.writ:SetText("|cff9c8d70owned|r")
    else
        fs.writ:SetText(r.writPrice and ns.Coins(r.writPrice) or ns.DASH)
    end

    -- Item price
    if not r.itemID then
        fs.item:SetText("|cffff8040ID?|r")
    elseif ns.db.ownedFree and r.ownItem then
        fs.item:SetText("|cff9c8d70owned|r")
    else
        fs.item:SetText(r.itemTotal and ns.Coins(r.itemTotal) or "|cff8a7c62no price|r")
    end
    fs.writ:SetTextColor(C.money[1], C.money[2], C.money[3])
    fs.item:SetTextColor(C.money[1], C.money[2], C.money[3])
    fs.total:SetTextColor(C.money[1], C.money[2], C.money[3])

    -- Total and cost per rep
    if r.complete then
        fs.total:SetText(ns.Coins(r.total))
        fs.cpr:SetText(ns.Coins(r.perRep))
        if style then
            fs.cpr:SetTextColor(style.color[1], style.color[2], style.color[3])
        else
            fs.cpr:SetTextColor(C.cpr[1], C.cpr[2], C.cpr[3])
        end
    elseif r.estimate then
        fs.total:SetText(ns.DASH)
        fs.cpr:SetText("|cff9c8d70EST|r  " .. ns.Coins(r.perRep))
        fs.cpr:SetTextColor(C.muted[1], C.muted[2], C.muted[3])
    else
        fs.total:SetText("")
        fs.cpr:SetText("")
    end
end

function ns.RebuildWindow()
    local f = MainFrame
    if not f or not f:IsShown() or not ns.db then return end
    local child = f.child

    for _, cb in ipairs(f.checks) do cb:SetChecked(ns.db[cb.key] and true or false) end

    local y, rowIdx = -4, 0
    local limit = ns.db.rowsPerTier

    local zone = ns.db.zoneFilter
    local filtered = zone ~= ns.ZONE_ALL

    for secIdx, tier in ipairs(ns.TIERS) do
        local res = ns.TierResults(tier.key, zone)
        local sec = GetSection(child, secIdx)

        local count = filtered and ("%d of %d orders"):format(res.inZone, #tier.ids)
                               or ("%d orders"):format(#tier.ids)
        sec.title:ClearAllPoints()
        sec.title:SetPoint("TOPLEFT", COLS.rank.x, y)
        sec.title:SetText(("|cff%s%s|r   |cffa8987a%d rep per order   %s|r"):format(
            Hex(tier.color), tier.key, tier.rep, count))
        sec.title:Show()

        local sealed = "Sealed writ: " .. (res.sealedPrice and ns.Coins(res.sealedPrice) or ns.DASH)
        if res.avgFill then
            sealed = sealed .. "    average item: " .. ns.Coins(res.avgFill)
        end
        sec.sealed:ClearAllPoints()
        sec.sealed:SetPoint("TOPRIGHT", child, "TOPLEFT", CHILD_W - 8, y - 2)
        sec.sealed:SetText(sealed)
        sec.sealed:SetTextColor(C.muted[1], C.muted[2], C.muted[3])
        sec.sealed:Show()

        local b = res.best
        local summary
        if filtered and res.inZone == 0 then
            summary = ("|cffaaaaaaNo %s orders are delivered in %s.|r"):format(tier.key, ns.ZoneLabel(zone))
        elseif b then
            summary = ("Cheapest: |cffffd100%s|r  %s total, |cffffd100%s|r per rep%s"):format(
                ns.OrderName(b), ns.Coins(b.total), ns.Coins(b.perRep),
                b.writ.zone and ("  |cffa8987a(" .. b.writ.zone .. ")|r") or "")
        elseif not ns.AuctionatorAPI() then
            summary = "|cffff8040No Auctionator data.|r"
        else
            summary = "|cffaaaaaaNo order has both a writ price and an item price yet. Scan the AH with Auctionator.|r"
        end
        if res.hiddenDone > 0 then
            summary = summary .. ("   |cff9c8d70(%d delivered today hidden)|r"):format(res.hiddenDone)
        end
        sec.summary:ClearAllPoints()
        sec.summary:SetPoint("TOPLEFT", COLS.rank.x, y - 17)
        sec.summary:SetText(summary)
        sec.summary:Show()

        sec.rule:ClearAllPoints()
        sec.rule:SetPoint("TOPLEFT", 0, y - SECTION_H + 4)
        sec.rule:SetPoint("TOPRIGHT", 0, y - SECTION_H + 4)
        sec.rule:SetColorTexture(C.gold[1], C.gold[2], C.gold[3], 0.55)
        sec.rule:Show()
        y = y - SECTION_H

        local shown = 0
        for _, r in ipairs(res.list) do
            if limit > 0 and shown >= limit then break end
            shown = shown + 1
            rowIdx = rowIdx + 1
            local row = GetRow(child, rowIdx)
            row:ClearAllPoints()
            row:SetPoint("TOPLEFT", 0, y)
            row:SetPoint("TOPRIGHT", 0, y)
            row.writID = r.id

            local rank = res.rank[r.id]
            local style = rank and RANK_STYLE[rank]
            if style then
                row.bg:SetColorTexture(style.tint[1], style.tint[2], style.tint[3], style.tint[4])
                row.medal:SetTexture(style.icon)
                row.medal:Show()
            else
                if rowIdx % 2 == 0 then
                    row.bg:SetColorTexture(0.353, 0.263, 0.125, 0.22)
                else
                    row.bg:SetColorTexture(0, 0, 0, 0)
                end
                row.medal:Hide()
            end
            SetCols(row, r, rank, style)
            row:SetAlpha(r.done and 0.55 or 1)
            row:Show()
            y = y - ROW_H
        end

        local remaining = #res.list - shown
        if remaining > 0 then
            sec.more:ClearAllPoints()
            sec.more:SetPoint("TOPLEFT", COLS.order.x, y - 2)
            sec.more:SetText(("+ %d more %s orders  (/cwa rows all)"):format(remaining, tier.key))
            sec.more:Show()
            y = y - MORE_H
        else
            sec.more:Hide()
        end
        y = y - 10
    end

    for i = rowIdx + 1, #ROW_POOL do
        ROW_POOL[i].writID = nil
        ROW_POOL[i]:Hide()
    end
    for i = #ns.TIERS + 1, #SECTION_POOL do HideSection(SECTION_POOL[i]) end

    child:SetSize(CHILD_W, math.abs(y) + 8)
end
