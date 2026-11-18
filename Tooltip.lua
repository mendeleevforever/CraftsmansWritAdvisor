local addonName, ns = ...

-- ============================================================
-- Tooltip lines on named writs and sealed writs.
-- ============================================================

local GOLD_R, GOLD_G, GOLD_B = 1, 0.82, 0
local DIM_R, DIM_G, DIM_B = 0.75, 0.75, 0.75

local function Hex(rgb)
    return ("%02x%02x%02x"):format(rgb[1] * 255, rgb[2] * 255, rgb[3] * 255)
end

local function AddWritLines(tooltip, writID)
    local res = ns.TierResults(ns.WRITS[writID].tier)
    local r
    for _, x in ipairs(res.list) do
        if x.id == writID then r = x break end
    end
    r = r or ns.Evaluate(writID) -- hidden by /cwa done
    local tier, w = r.tier, r.writ

    tooltip:AddLine(" ")
    tooltip:AddLine(("|cff%s[CWA] %s order|r  |cffa8987a%d rep|r"):format(Hex(tier.color), tier.key, tier.rep))

    if r.itemID then
        local itemText = r.itemTotal and ns.Coins(r.itemTotal) or "|cffaaaaaano price|r"
        tooltip:AddDoubleLine("Wants: " .. ns.OrderName(r), itemText, DIM_R, DIM_G, DIM_B, 1, 1, 1)
        if r.qty > 1 and r.itemUnit then
            tooltip:AddDoubleLine("  each", ns.Coins(r.itemUnit), DIM_R, DIM_G, DIM_B, DIM_R, DIM_G, DIM_B)
        end
    else
        tooltip:AddLine("Wants: " .. w.name .. " |cffff8040(item ID unknown: /cwa setitem " .. writID .. " <item>)|r",
            DIM_R, DIM_G, DIM_B, true)
    end
    tooltip:AddDoubleLine("Writ on the AH:", r.writPrice and ns.Coins(r.writPrice) or "|cffaaaaaano price|r",
        DIM_R, DIM_G, DIM_B, 1, 1, 1)

    if r.complete then
        tooltip:AddDoubleLine("Total:", ns.Coins(r.total), GOLD_R, GOLD_G, GOLD_B, 1, 1, 1)
        tooltip:AddDoubleLine("Cost per rep:", ns.Coins(r.perRep), GOLD_R, GOLD_G, GOLD_B, 1, 1, 0.6)
    elseif r.estimate then
        tooltip:AddDoubleLine("Item cost only:", ns.Coins(r.total), GOLD_R, GOLD_G, GOLD_B, 1, 1, 1)
        tooltip:AddDoubleLine("Cost per rep (est):", ns.Coins(r.perRep), GOLD_R, GOLD_G, GOLD_B, 0.8, 0.8, 0.6)
    else
        tooltip:AddLine("|cffaaaaaaNo Auctionator price yet. Scan the AH.|r")
    end

    local rank = res.rank[writID]
    if r.complete and not r.done then
        local pos = 0
        for i, x in ipairs(res.list) do
            if x.id == writID then pos = i break end
        end
        local medal = rank and " |cffffd100(top 3)|r" or ""
        tooltip:AddLine(("Rank %d of %d priced %s orders%s"):format(pos, res.priced, tier.key, medal), 0.9, 0.84, 0.68)
    end

    if w.npc then
        tooltip:AddLine("Deliver to " .. w.npc .. ", " .. (w.zone or "?"), 0.6, 0.8, 1, true)
    elseif w.zone then
        tooltip:AddLine("Customer reported in " .. w.zone:gsub("%?$", "") .. " (not confirmed)", 0.6, 0.8, 1, true)
    end
    if r.done then
        tooltip:AddLine("Delivered today. Counts again after the daily reset.", 0.4, 1, 0.4, true)
    end
    if r.stale then
        tooltip:AddLine(("Price data is more than %d days old."):format(ns.db.staleDays), 1, 0.5, 0.25)
    end
    if ns.db.pouchNet then
        tooltip:AddLine("Totals subtract an estimated coin pouch.", 0.6, 0.6, 0.6)
    end
    tooltip:AddLine("|cff555555/cwa for the full list|r")
end

local function AddSealedLines(tooltip, sealedID)
    local res = ns.TierResults(ns.SEALED[sealedID])
    local tier = res.tier

    tooltip:AddLine(" ")
    tooltip:AddLine(("|cff%s[CWA] Opens a random %s order|r  |cffa8987a%d rep|r"):format(
        Hex(tier.color), tier.key, tier.rep))
    if res.avgFill then
        tooltip:AddDoubleLine(("Average item cost (%d of %d orders):"):format(res.avgCount, #tier.ids),
            ns.Coins(res.avgFill), DIM_R, DIM_G, DIM_B, 1, 1, 1)
        if res.sealedPrice then
            local total = res.sealedPrice + res.avgFill
            tooltip:AddDoubleLine("Sealed + average item:", ns.Coins(total), GOLD_R, GOLD_G, GOLD_B, 1, 1, 1)
            tooltip:AddDoubleLine("  per rep:", ns.Coins(total / tier.rep), GOLD_R, GOLD_G, GOLD_B, 1, 1, 0.6)
        end
    end
    local b = res.best
    if b then
        tooltip:AddDoubleLine("Cheapest named order:", ns.OrderName(b), DIM_R, DIM_G, DIM_B, 1, 1, 1)
        tooltip:AddDoubleLine("  total / per rep:", ns.Coins(b.total) .. "  /  " .. ns.Coins(b.perRep),
            DIM_R, DIM_G, DIM_B, 1, 1, 0.6)
    else
        tooltip:AddLine("|cffaaaaaaNo complete order prices yet. Scan the AH.|r")
    end
    tooltip:AddLine("|cff555555/cwa for the full list|r")
end

local function OnItemTooltip(tooltip, itemID)
    if not ns.db or not ns.db.tooltip then return end
    if tooltip == ShoppingTooltip1 or tooltip == ShoppingTooltip2 then return end
    if ns.WRITS[itemID] then
        AddWritLines(tooltip, itemID)
        tooltip:Show()
    elseif ns.SEALED[itemID] then
        AddSealedLines(tooltip, itemID)
        tooltip:Show()
    end
end

function ns.InitTooltips()
    if ns.tooltipsHooked then return end
    ns.tooltipsHooked = true

    if TooltipDataProcessor and TooltipDataProcessor.AddTooltipPostCall
        and Enum and Enum.TooltipDataType and Enum.TooltipDataType.Item then
        TooltipDataProcessor.AddTooltipPostCall(Enum.TooltipDataType.Item, function(tooltip, data)
            local id = data and data.id
            if id == nil or ns.IsSecret(id) or type(id) ~= "number" then return end
            OnItemTooltip(tooltip, id)
        end)
        return
    end

    -- Fallback for builds without TooltipDataProcessor.
    local function OnSetItem(tooltip)
        local _, link = tooltip:GetItem()
        if not link or ns.IsSecret(link) then return end
        local id = tonumber(link:match("item:(%d+)"))
        if id then OnItemTooltip(tooltip, id) end
    end
    for _, tt in ipairs({ GameTooltip, ItemRefTooltip }) do
        if tt and tt.HasScript and tt:HasScript("OnTooltipSetItem") then
            tt:HookScript("OnTooltipSetItem", OnSetItem)
        end
    end
end
