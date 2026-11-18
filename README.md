# Craftsman's Writ Advisor

**Version 0.1.0** · by MendeleevForever · for World of Warcraft: Forever

Find the cheapest Craftsman's Writ to complete in each tier, using the prices from your Auctionator scans.

## What it does

- Lists every Journeyman, Expert and Artisan order with its full cost: the writ's price plus the price of the item the order asks for.
- Ranks the orders in each tier by cost per reputation point and marks the three cheapest with gold, silver and copper medals.
- Greys out orders you have already delivered today, since each order only gives reputation once per day.
- Adds cost details to writ tooltips. Sealed writs show the average cost of the order you might get when you open one.
- Searches Auctionator for a writ and its item with one click while the Auction House is open.

## Requirements

- **Auctionator.** All prices come from Auctionator's scans. Visit the Auction House and run a scan before you use this addon.

## Installation

1. Download `CraftsmansWritAdvisor-0.1.0.zip` and extract it.
2. Copy the `CraftsmansWritAdvisor` folder into your AddOns folder:
   - Live: `World of Warcraft\_forever_\Interface\AddOns\`
   - Beta: `World of Warcraft\_classic_beta_\Interface\AddOns\`
3. Check the path. It should end in `AddOns\CraftsmansWritAdvisor\CraftsmansWritAdvisor.toc`, not in a doubled folder like `AddOns\CraftsmansWritAdvisor\CraftsmansWritAdvisor\`.
4. Start the game. If the addon is missing from the AddOns list, close the game completely and start it again.

## Using it

Type `/cwa` or click **Craftsman's Writ Advisor** in the addon menu on the minimap.

### The list

| Column | Meaning |
|---|---|
| Order | The item the order asks for, with a count if it wants more than one |
| Prof | The profession that makes the item |
| Customer zone | Where you hand the order in |
| Writ AH | The price of the named writ on the Auction House |
| Item AH | The price of the requested item, times the count |
| Total | Writ plus item |
| Cost / rep | Total divided by the reputation the order gives |

Each tier's heading also shows the price of a sealed writ and the average item cost for that tier.

### Icons and labels

| Shown | Meaning |
|---|---|
| Gold, silver, copper coin | The three cheapest orders in the tier, by cost per reputation |
| Green check | Delivered today. It will count again after the daily reset |
| Bag | You have this writ in your bags |
| Clock | The price is older than 7 days |
| EST | No price for the writ itself. The cost shown is the item only |
| Zone with `?` | The customer's zone was reported by players but not confirmed |
| ID? | The item this order asks for is not known yet (see below) |

### Clicking a row

- **Hover** to see the full cost breakdown and the customer's name.
- **Shift-click** to link the writ in chat.
- **Click** while the Auction House is open to search for the writ and its item in Auctionator.

### Options

The checkboxes at the bottom of the window:

- **Hide delivered today** removes orders you have already turned in today.
- **Owned writs/items count as free** treats writs and items already in your bags as costing nothing.
- **Subtract coin pouch (estimate)** takes the usual coin pouch reward off each total. Pouch amounts vary, so this is a rough figure. A green `+` amount means the order should earn more than it costs.

## Commands

| Command | What it does |
|---|---|
| `/cwa` | Open or close the list |
| `/cwa best` | Print the cheapest order of each tier in chat |
| `/cwa rows <number>` | Show this many orders per tier (`/cwa rows all` shows every order) |
| `/cwa done` | Hide or show orders delivered today |
| `/cwa owned` | Count owned writs and items as free, or not |
| `/cwa pouch` | Subtract the estimated coin pouch, or not |
| `/cwa tooltip` | Turn the tooltip details on or off |
| `/cwa stale <days>` | Change how old a price must be before the clock icon appears |
| `/cwa setitem <writ> <item> [count]` | Tell the addon which item an order asks for |
| `/cwa clear <writ>` | Undo a `setitem` |
| `/cwa id` | Print the item ID of whatever is under your mouse |
| `/cwa reset` | Move the window back to the middle of the screen |
| `/cwa help` | List all commands |

## Questions

**Every price says "no price" or a dash.**
Auctionator has no data yet. Open the Auction House, run an Auctionator scan, then press **Refresh** in the window.

**An order shows "ID?" in the item column.**
Four orders ask for an item the addon doesn't know yet: Elixir of Ogre's Strength, Pearl-Handled Dagger, Gyromatic Micro-Adjuster and Potion of Demonslaying. When you find the item, type `/cwa setitem`, then shift-click the writ and then the item into the chat box, and press Enter. If the order wants more than one, add the count at the end.

**Why is an order I own greyed out?**
You already delivered that order today. Each order gives reputation once per day, and you can deliver it again after the daily reset.

**How current are the prices?**
They are the last prices Auctionator saw. A clock icon means a price is more than 7 days old. Scan again for fresh numbers.

**Where are my settings saved?**
In your account's saved variables, so they apply to all your characters.
