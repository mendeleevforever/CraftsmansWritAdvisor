local addonName, ns = ...

-- ============================================================
-- Pricing: Auctionator's public API (Auctionator.API.v1) only.
-- Nothing here reads Auctionator's saved variables directly.
-- ============================================================

local GetItemInfo  = C_Item and C_Item.GetItemInfo
local GetItemCount = (C_Item and C_Item.GetItemCount) or GetItemCount
local RequestLoad  = C_Item and C_Item.RequestLoadItemDataByID

function ns.AuctionatorAPI()
    local a = Auctionator
    if type(a) ~= "table" or type(a.API) ~= "table" or type(a.API.v1) ~= "table" then return nil end
    return a.API.v1
end

local function SafeNumber(v)
    if v == nil or ns.IsSecret(v) or type(v) ~= "number" then return nil end
    return v
end

function ns.InitPricing()
    local api = ns.AuctionatorAPI()
    if api and api.RegisterForDBUpdate and not ns.dbUpdateHooked then
        local ok = pcall(api.RegisterForDBUpdate, addonName, function() ns.Invalidate() end)
        ns.dbUpdateHooked = ok
    end
end

-- Last scanned price in copper, or nil.
function ns.GetPrice(itemID)
    if not itemID then return nil end
    local api = ns.AuctionatorAPI()
    if not api or not api.GetAuctionPriceByItemID then return nil end
    local ok, price = pcall(api.GetAuctionPriceByItemID, addonName, itemID)
    price = ok and SafeNumber(price) or nil
    if price and price > 0 then return price end
    return nil
end

-- Days since Auctionator last saw the item; nil means never or over 21 days.
function ns.GetAge(itemID)
    if not itemID then return nil end
    local api = ns.AuctionatorAPI()
    if not api or not api.GetAuctionAgeByItemID then return nil end
    local ok, age = pcall(api.GetAuctionAgeByItemID, addonName, itemID)
    return ok and SafeNumber(age) or nil
end

-- Count in bags (the writ and the item must be in your bags at hand-in).
function ns.GetCount(itemID)
    if not itemID or not GetItemCount then return 0 end
    local ok, n = pcall(GetItemCount, itemID)
    return (ok and SafeNumber(n)) or 0
end

function ns.IsDoneToday(writ)
    if not writ.quest or not (C_QuestLog and C_QuestLog.IsQuestFlaggedCompleted) then return false end
    local done = C_QuestLog.IsQuestFlaggedCompleted(writ.quest)
    if ns.IsSecret(done) then return false end
    return done == true
end

-- ------------------------------------------------------------
-- Item names and links (nil until cached; request and wait for
-- ITEM_DATA_LOAD_RESULT, handled in Core.lua).
-- ------------------------------------------------------------
local requested = {}

function ns.RequestItem(itemID)
    if not itemID or requested[itemID] or not RequestLoad then return end
    requested[itemID] = true
    RequestLoad(itemID)
end

function ns.RequestAllItems()
    for itemID in pairs(ns.TRACKED_ITEMS) do ns.RequestItem(itemID) end
end

function ns.ItemName(itemID, fallback)
    if itemID and GetItemInfo then
        local name = GetItemInfo(itemID)
        if name and not ns.IsSecret(name) then return name end
        ns.RequestItem(itemID)
    end
    return fallback or ("Item #" .. tostring(itemID))
end

function ns.ItemLink(itemID)
    if not itemID or not GetItemInfo then return nil end
    local _, link = GetItemInfo(itemID)
    if link and not ns.IsSecret(link) then return link end
    ns.RequestItem(itemID)
    return nil
end

-- The item and quantity a writ asks for, after /cwa setitem overrides.
function ns.WritItem(writID)
    local w = ns.WRITS[writID]
    local o = ns.db and ns.db.overrides[writID]
    local item = (o and o.item) or w.item
    local qty = (o and o.qty) or w.qty or 1
    return item, qty
end

function ns.OrderName(r)
    local name = ns.ItemName(r.itemID, r.writ.itemName or r.writ.name)
    if r.qty > 1 then return ("x%d %s"):format(r.qty, name) end
    return name
end

-- ------------------------------------------------------------
-- One writ's numbers.
--   total    = writ AH + item AH x qty (minus pouch if enabled)
--   complete = both prices known (only these are ranked)
--   estimate = item price known, writ price missing
-- ------------------------------------------------------------
function ns.Evaluate(writID)
    local db = ns.db
    local w = ns.WRITS[writID]
    local tier = ns.TIER_BY_KEY[w.tier]
    local itemID, qty = ns.WritItem(writID)
    local r = { id = writID, writ = w, tier = tier, itemID = itemID, qty = qty }

    r.done    = ns.IsDoneToday(w)
    r.ownWrit = ns.GetCount(writID) > 0
    r.ownItem = itemID ~= nil and ns.GetCount(itemID) >= qty

    r.writPrice = ns.GetPrice(writID)
    r.itemUnit  = ns.GetPrice(itemID)
    r.itemTotal = r.itemUnit and (r.itemUnit * qty) or nil

    local writCost, itemCost = r.writPrice, r.itemTotal
    if db.ownedFree and r.ownWrit then writCost = 0 end
    if db.ownedFree and r.ownItem then itemCost = 0 end

    if writCost and itemCost then
        r.total, r.complete = writCost + itemCost, true
    elseif itemCost then
        r.total, r.estimate = itemCost, true
    end
    if r.total and db.pouchNet then r.total = r.total - tier.pouch end
    if r.total then r.perRep = r.total / tier.rep end

    local function IsStale(id, price)
        if not price then return false end
        local age = ns.GetAge(id)
        return age == nil or age > db.staleDays
    end
    r.stale = IsStale(writID, r.writPrice) or IsStale(itemID, r.itemUnit)
    return r
end

-- Sort class: 1 complete & deliverable, 2 estimate, 3 done today, 4 no price.
local function SortClass(r)
    if r.done then return 3 end
    if r.complete then return 1 end
    if r.estimate then return 2 end
    return 4
end

local function SortResults(a, b)
    local ca, cb = a.class, b.class
    if ca ~= cb then return ca < cb end
    if a.total and b.total and a.total ~= b.total then return a.total < b.total end
    return a.writ.name < b.writ.name
end

-- ------------------------------------------------------------
-- A tier's sorted list, top-3 ranks and sealed-writ summary,
-- optionally limited to one customer zone. Ranks are within the
-- zone. The sealed-writ average always covers the whole tier,
-- because a sealed writ can open into any order.
-- Cached per tier and zone until ns.Invalidate() bumps ns.cacheGen.
-- ------------------------------------------------------------
local cache = {}

function ns.TierResults(tierKey, zoneKey)
    if zoneKey == nil then zoneKey = ns.ZONE_ALL end
    local cacheKey = tierKey .. "|" .. zoneKey
    local c = cache[cacheKey]
    if c and c.gen == ns.cacheGen then return c end

    local tier = ns.TIER_BY_KEY[tierKey]
    local list, hidden, inZone = {}, 0, 0
    local fillSum, fillCount = 0, 0

    for _, id in ipairs(tier.ids) do
        local r = ns.Evaluate(id)
        r.class = SortClass(r)
        if r.itemTotal then
            fillSum, fillCount = fillSum + r.itemTotal, fillCount + 1
        end
        if zoneKey == ns.ZONE_ALL or r.writ.zoneKey == zoneKey then
            inZone = inZone + 1
            if ns.db.hideDone and r.done then
                hidden = hidden + 1
            else
                list[#list + 1] = r
            end
        end
    end
    table.sort(list, SortResults)

    local rank, priced = {}, 0
    for _, r in ipairs(list) do
        if r.class == 1 then
            priced = priced + 1
            if priced <= 3 then rank[r.id] = priced end
        end
    end

    c = {
        gen         = ns.cacheGen,
        tier        = tier,
        zone        = zoneKey,
        inZone      = inZone,
        list        = list,
        rank        = rank,
        priced      = priced,
        hiddenDone  = hidden,
        best        = (list[1] and list[1].class == 1) and list[1] or nil,
        sealedPrice = ns.GetPrice(tier.sealed),
        avgFill     = fillCount > 0 and (fillSum / fillCount) or nil,
        avgCount    = fillCount,
    }
    cache[tierKey] = c
    return c
end

-- ------------------------------------------------------------
-- Auctionator search (AH must be open; called from a row click).
-- ------------------------------------------------------------
function ns.IsAHOpen()
    if AuctionHouseFrame and AuctionHouseFrame:IsShown() then return true end
    if AuctionFrame and AuctionFrame:IsShown() then return true end
    return false
end

function ns.SearchAuctionator(writID)
    local api = ns.AuctionatorAPI()
    local search = api and (api.MultiSearchExact or api.MultiSearch)
    if not search then
        ns.Print("Auctionator's search API was not found.")
        return
    end
    if not ns.IsAHOpen() then
        ns.Print("Open the Auction House, then click a row to search for that writ and its item.")
        return
    end
    local w = ns.WRITS[writID]
    local itemID = ns.WritItem(writID)
    local terms = { ns.ItemName(writID, "Craftsman's Writ: " .. w.name) }
    if itemID then terms[2] = ns.ItemName(itemID, w.itemName or w.name) end
    local ok, err = pcall(search, addonName, terms)
    if not ok then ns.Print("Auctionator search failed: %s", tostring(err)) end
end
