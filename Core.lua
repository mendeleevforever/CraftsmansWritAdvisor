local addonName, ns = ...

-- ============================================================
-- Craftsman's Writ Advisor - Core
-- Namespace, saved variables, the single event frame, the
-- combat queue, the secret-value guard and the /cwa command.
-- ============================================================

local GetMeta = (C_AddOns and C_AddOns.GetAddOnMetadata) or GetAddOnMetadata
ns.version = (GetMeta and GetMeta(addonName, "Version")) or "?"
ns.TAG = "|cffd4a017CWA:|r"
ns.cacheGen = 0

-- ------------------------------------------------------------
-- Defaults. Merged onto the saved table inside ADDON_LOADED.
-- ------------------------------------------------------------
ns.DEFAULTS = {
    schema      = 1,
    rowsPerTier = 12,    -- 0 shows every order in a tier
    hideDone    = false, -- hide orders already delivered today
    ownedFree   = false, -- writs/items already in your bags cost nothing
    pouchNet    = false, -- subtract the estimated coin pouch from the total
    tooltip     = true,  -- add the cost breakdown to writ tooltips
    staleDays   = 7,     -- flag prices older than this many days
    window      = {},    -- saved window position
    overrides   = {},    -- [writID] = { item = itemID, qty = n }
}

local function MergeDefaults(dst, src)
    for k, v in pairs(src) do
        if type(v) == "table" then
            if type(dst[k]) ~= "table" then dst[k] = {} end
            MergeDefaults(dst[k], v)
        elseif dst[k] == nil then
            dst[k] = v
        end
    end
    return dst
end

-- ------------------------------------------------------------
-- Secret-value guard. Midnight's disarmament can hand addons
-- "secret" values that throw on comparison or arithmetic. This
-- addon reads no unit data, but every value that comes from
-- outside the addon passes through this check before a branch,
-- a comparison or a print.
-- ------------------------------------------------------------
local issecretvalue = issecretvalue
function ns.IsSecret(v)
    if issecretvalue == nil then return false end
    return issecretvalue(v) == true
end

function ns.Print(fmt, ...)
    local n = select("#", ...)
    if n == 0 then
        print(ns.TAG .. " " .. tostring(fmt))
        return
    end
    local args = {}
    for i = 1, n do
        local v = select(i, ...)
        if ns.IsSecret(v) then v = "?" end
        args[i] = v
    end
    print(ns.TAG .. " " .. fmt:format(unpack(args, 1, n)))
end

-- ------------------------------------------------------------
-- Money formatting. Negative amounts are profit (only possible
-- with the coin-pouch estimate on) and print green with a "+".
-- ------------------------------------------------------------
local GOLD   = "|TInterface\\MoneyFrame\\UI-GoldIcon:0:0:2:0|t"
local SILVER = "|TInterface\\MoneyFrame\\UI-SilverIcon:0:0:2:0|t"
local COPPER = "|TInterface\\MoneyFrame\\UI-CopperIcon:0:0:2:0|t"
ns.DASH = "|cff7d705a\226\128\148|r"

function ns.Coins(copper)
    if copper == nil or ns.IsSecret(copper) or type(copper) ~= "number" then
        return ns.DASH
    end
    local profit = copper < 0
    if profit then copper = -copper end
    copper = math.floor(copper + 0.5)
    local g = math.floor(copper / 10000)
    local s = math.floor((copper % 10000) / 100)
    local c = copper % 100
    local parts = {}
    if g > 0 then parts[#parts + 1] = g .. GOLD end
    if s > 0 then parts[#parts + 1] = s .. SILVER end
    if c > 0 or #parts == 0 then parts[#parts + 1] = c .. COPPER end
    local text = table.concat(parts, " ")
    if profit then return "|cff40ff40+" .. text .. "|r" end
    return text
end

-- ------------------------------------------------------------
-- Combat queue. Nothing this addon creates is protected, so
-- calls pass straight through today. If a protected frame is
-- ever involved, the closure waits for PLAYER_REGEN_ENABLED.
-- Keyed so a repeated request replaces the queued one.
-- ------------------------------------------------------------
local pendingByKey, pendingOrder = {}, {}

function ns.AfterCombat(key, fn)
    if not InCombatLockdown() then
        fn()
        return true
    end
    if pendingByKey[key] == nil then
        pendingOrder[#pendingOrder + 1] = key
    end
    pendingByKey[key] = fn
    return false
end

function ns.SetShownSafe(frame, shown)
    if frame:IsProtected() then
        return ns.AfterCombat(frame, function() frame:SetShown(shown) end)
    end
    frame:SetShown(shown)
    return true
end

-- ------------------------------------------------------------
-- Cache invalidation and a debounced window refresh.
-- ------------------------------------------------------------
local refreshPending = false

function ns.Invalidate()
    ns.cacheGen = ns.cacheGen + 1
    if refreshPending then return end
    refreshPending = true
    local function run()
        refreshPending = false
        if ns.RebuildWindow then ns.RebuildWindow() end
    end
    if C_Timer and C_Timer.After then
        C_Timer.After(0.3, run)
    else
        run()
    end
end

-- ------------------------------------------------------------
-- The one event frame and its handler table.
-- ------------------------------------------------------------
local eventFrame = CreateFrame("Frame")
local handlers = {}

function handlers.ADDON_LOADED(name)
    if name ~= addonName then return end
    local saved = CraftsmansWritAdvisorDB
    if type(saved) ~= "table" then saved = {} end
    CraftsmansWritAdvisorDB = MergeDefaults(saved, ns.DEFAULTS)
    ns.db = CraftsmansWritAdvisorDB
    eventFrame:UnregisterEvent("ADDON_LOADED")
end

function handlers.PLAYER_LOGIN()
    ns.InitPricing()
    ns.InitTooltips()
    ns.Print("v%s loaded. /cwa opens the list, /cwa help lists commands.", ns.version)
    if not ns.AuctionatorAPI() then
        ns.Print("Auctionator was not found. Prices will stay empty until it is installed and has scanned the AH.")
    end
end

function handlers.PLAYER_REGEN_ENABLED()
    local order = pendingOrder
    local byKey = pendingByKey
    pendingOrder, pendingByKey = {}, {}
    for i = 1, #order do
        local fn = byKey[order[i]]
        local ok, err = pcall(fn)
        if not ok then geterrorhandler()(err) end
    end
end

function handlers.BAG_UPDATE_DELAYED()
    ns.Invalidate()
end

function handlers.QUEST_TURNED_IN(questID)
    if ns.IsSecret(questID) then return end
    if ns.QUEST_TO_WRIT[questID] then ns.Invalidate() end
end

function handlers.ITEM_DATA_LOAD_RESULT(itemID, success)
    if ns.IsSecret(itemID) or not success then return end
    if ns.TRACKED_ITEMS[itemID] then ns.Invalidate() end
end

function handlers.AUCTION_HOUSE_SHOW()
    if ns.UpdateAHHint then ns.UpdateAHHint() end
end

function handlers.AUCTION_HOUSE_CLOSED()
    if ns.UpdateAHHint then ns.UpdateAHHint() end
end

eventFrame:SetScript("OnEvent", function(_, event, ...)
    local fn = handlers[event]
    if fn then fn(...) end
end)

local function EventExists(event)
    if C_EventUtils and C_EventUtils.IsEventValid then
        return C_EventUtils.IsEventValid(event)
    end
    return true
end

for event in pairs(handlers) do
    if EventExists(event) then
        local ok = pcall(eventFrame.RegisterEvent, eventFrame, event)
        if not ok then ns.missingEvents = (ns.missingEvents or "") .. " " .. event end
    else
        ns.missingEvents = (ns.missingEvents or "") .. " " .. event
    end
end

-- ------------------------------------------------------------
-- Slash command. One table keyed by verb.
-- ------------------------------------------------------------
local function OnOff(v) return v and "|cff40ff40on|r" or "|cffff6060off|r" end

local function Toggle(key, label)
    ns.db[key] = not ns.db[key]
    ns.Print("%s: %s", label, OnOff(ns.db[key]))
    ns.Invalidate()
end

-- Pulls item IDs out of plain numbers and shift-clicked links, in order.
local function ParseIDs(text)
    local s = text:gsub("|Hitem:(%d+)[^|]*|h.-|h", " %1 ")
    s = s:gsub("|c%x%x%x%x%x%x%x%x", ""):gsub("|cn[^:]*:", ""):gsub("|r", "")
    local ids = {}
    for n in s:gmatch("%d+") do ids[#ids + 1] = tonumber(n) end
    return ids
end

local commands = {}

function commands.help()
    ns.Print("commands:")
    print("  /cwa                Toggle the writ list")
    print("  /cwa best           Print the cheapest order of each tier")
    print("  /cwa rows <n|all>   Orders shown per tier (now: " .. (ns.db.rowsPerTier == 0 and "all" or ns.db.rowsPerTier) .. ")")
    print("  /cwa done           Hide orders delivered today (" .. OnOff(ns.db.hideDone) .. ")")
    print("  /cwa owned          Writs/items in your bags count as free (" .. OnOff(ns.db.ownedFree) .. ")")
    print("  /cwa pouch          Subtract the estimated coin pouch (" .. OnOff(ns.db.pouchNet) .. ")")
    print("  /cwa tooltip        Cost lines on writ tooltips (" .. OnOff(ns.db.tooltip) .. ")")
    print("  /cwa stale <days>   Flag prices older than this (now: " .. ns.db.staleDays .. ")")
    print("  /cwa setitem <writ> <item> [qty]   Set or fix the item a writ asks for (IDs or links)")
    print("  /cwa clear <writ>   Remove a setitem override")
    print("  /cwa id             Print the ID of the item under your mouse")
    print("  /cwa probe          Check which APIs this client build has")
    print("  /cwa reset          Recenter the window")
end

function commands.show() ns.ToggleWindow(true) end

function commands.best()
    for _, tier in ipairs(ns.TIERS) do
        local res = ns.TierResults(tier.key)
        local b = res.best
        if b then
            ns.Print("%s: %s - %s total, %s per rep%s", tier.key, ns.OrderName(b),
                ns.Coins(b.total), ns.Coins(b.perRep), b.writ.zone and (" - " .. b.writ.zone) or "")
        else
            ns.Print("%s: no order has both a writ price and an item price yet. Scan the AH with Auctionator.", tier.key)
        end
    end
end

function commands.rows(arg)
    arg = (arg or ""):lower()
    local n = (arg == "all") and 0 or tonumber(arg)
    if not n or n < 0 then
        ns.Print("Usage: /cwa rows <number|all>")
        return
    end
    ns.db.rowsPerTier = math.floor(n)
    ns.Print("Orders per tier: %s", n == 0 and "all" or tostring(ns.db.rowsPerTier))
    ns.Invalidate()
end

function commands.done()    Toggle("hideDone",  "Hide orders delivered today") end
function commands.owned()   Toggle("ownedFree", "Owned writs/items count as free") end
function commands.pouch()   Toggle("pouchNet",  "Subtract estimated coin pouch") end
function commands.tooltip() Toggle("tooltip",   "Tooltip lines") end

function commands.stale(arg)
    local n = tonumber(arg)
    if not n or n < 1 then
        ns.Print("Usage: /cwa stale <days>")
        return
    end
    ns.db.staleDays = math.floor(n)
    ns.Print("Prices older than %d days are flagged.", ns.db.staleDays)
    ns.Invalidate()
end

function commands.setitem(arg)
    local ids = ParseIDs(arg or "")
    local writID, itemID, qty = ids[1], ids[2], ids[3]
    if not (writID and ns.WRITS[writID]) or not itemID then
        ns.Print("Usage: /cwa setitem <writ ID or link> <item ID or link> [qty]")
        return
    end
    ns.db.overrides[writID] = { item = itemID, qty = (qty and qty > 0) and qty or nil }
    ns.TRACKED_ITEMS[itemID] = true
    ns.RequestItem(itemID)
    ns.Print("%s now asks for x%d item %d.", ns.WRITS[writID].name, qty or ns.WRITS[writID].qty, itemID)
    ns.Invalidate()
end

function commands.clear(arg)
    local writID = ParseIDs(arg or "")[1]
    if not writID or not ns.db.overrides[writID] then
        ns.Print("No override for that writ.")
        return
    end
    ns.db.overrides[writID] = nil
    ns.Print("Override removed for writ %d.", writID)
    ns.Invalidate()
end

function commands.id()
    local link
    if TooltipUtil and TooltipUtil.GetDisplayedItem then
        local _, l = TooltipUtil.GetDisplayedItem(GameTooltip)
        link = l
    elseif GameTooltip.GetItem then
        local _, l = GameTooltip:GetItem()
        link = l
    end
    if not link or ns.IsSecret(link) then
        ns.Print("Hover an item first, then type /cwa id.")
        return
    end
    local id = tonumber(link:match("item:(%d+)"))
    local note = ""
    if id and ns.WRITS[id] then note = " (" .. ns.WRITS[id].tier .. " writ)" end
    if id and ns.SEALED[id] then note = " (sealed " .. ns.SEALED[id] .. " writ)" end
    ns.Print("%s - item ID |cffffff00%s|r%s", link, tostring(id), note)
end

function commands.probe() ns.Probe() end

function commands.reset()
    ns.db.window = {}
    if ns.ResetWindowPosition then ns.ResetWindowPosition() end
    ns.Print("Window recentered.")
end

SLASH_CRAFTSMANSWRITADVISOR1 = "/cwa"
SlashCmdList.CRAFTSMANSWRITADVISOR = function(msg)
    if not ns.db then
        ns.Print("Still loading.")
        return
    end
    msg = strtrim(msg or "")
    local verb, rest = msg:match("^(%S*)%s*(.-)$")
    verb = (verb or ""):lower()
    if verb == "" then
        ns.ToggleWindow()
        return
    end
    local fn = commands[verb]
    if fn then
        fn(rest)
    else
        ns.Print("Unknown command '%s'. Type /cwa help.", verb)
    end
end

-- ------------------------------------------------------------
-- Capability probe. Prints what this client build exposes.
-- ------------------------------------------------------------
local function Has(v) return v and "|cff40ff40yes|r" or "|cffff6060no|r" end

function ns.Probe()
    local version, build, _, toc = GetBuildInfo()
    ns.Print("probe on %s.%s, interface %s", tostring(version), tostring(build), tostring(toc))
    print(("  WOW_PROJECT_ID %s (MAINLINE %s, CLASSIC %s, CAMELOT %s)"):format(
        tostring(WOW_PROJECT_ID), tostring(WOW_PROJECT_MAINLINE), tostring(WOW_PROJECT_CLASSIC),
        tostring(WOW_PROJECT_CAMELOT)))
    local api = ns.AuctionatorAPI()
    print("  Auctionator API v1: " .. Has(api)
        .. "   RegisterForDBUpdate: " .. Has(api and api.RegisterForDBUpdate)
        .. "   MultiSearchExact: " .. Has(api and api.MultiSearchExact))
    print("  C_Item.GetItemInfo: " .. Has(C_Item and C_Item.GetItemInfo)
        .. "   C_Item.GetItemCount: " .. Has(C_Item and C_Item.GetItemCount)
        .. "   RequestLoadItemDataByID: " .. Has(C_Item and C_Item.RequestLoadItemDataByID))
    print("  C_QuestLog.IsQuestFlaggedCompleted: " .. Has(C_QuestLog and C_QuestLog.IsQuestFlaggedCompleted)
        .. "   TooltipDataProcessor: " .. Has(TooltipDataProcessor and TooltipDataProcessor.AddTooltipPostCall))
    print("  issecretvalue: " .. Has(issecretvalue)
        .. "   C_EventUtils.IsEventValid: " .. Has(C_EventUtils and C_EventUtils.IsEventValid)
        .. "   HandleModifiedItemClick: " .. Has(HandleModifiedItemClick)
        .. "   AddonCompartmentFrame: " .. Has(AddonCompartmentFrame))
    if ns.missingEvents then
        print("  Events this build rejected:" .. ns.missingEvents)
    end
    local sampleWrit, sampleItem = 264034, 4373 -- Shadow Goggles
    print(("  Sample: writ %d price %s, item %d price %s, quest %d done today: %s"):format(
        sampleWrit, ns.Coins(ns.GetPrice(sampleWrit)), sampleItem, ns.Coins(ns.GetPrice(sampleItem)),
        ns.WRITS[sampleWrit].quest, tostring(ns.IsDoneToday(ns.WRITS[sampleWrit]))))
end

-- ------------------------------------------------------------
-- Addon compartment (the minimap addon menu). These three must
-- be globals because the TOC names them.
-- ------------------------------------------------------------
local function FindFrameArg(...)
    for i = 1, select("#", ...) do
        local v = select(i, ...)
        if type(v) == "table" and v.GetObjectType then return v end
    end
end

function CraftsmansWritAdvisor_OnAddonCompartmentClick()
    if ns.db then ns.ToggleWindow() end
end

function CraftsmansWritAdvisor_OnAddonCompartmentEnter(...)
    local owner = FindFrameArg(...)
    if not owner or not ns.db then return end
    GameTooltip:SetOwner(owner, "ANCHOR_LEFT")
    GameTooltip:AddLine("Craftsman's Writ Advisor")
    for _, tier in ipairs(ns.TIERS) do
        local b = ns.TierResults(tier.key).best
        GameTooltip:AddDoubleLine(tier.key .. ":", b and (ns.OrderName(b) .. "  " .. ns.Coins(b.total)) or ns.DASH,
            1, 0.82, 0, 1, 1, 1)
    end
    GameTooltip:AddLine("Click to open. /cwa help lists commands.", 0.6, 0.6, 0.6)
    GameTooltip:Show()
end

function CraftsmansWritAdvisor_OnAddonCompartmentLeave()
    GameTooltip:Hide()
end
