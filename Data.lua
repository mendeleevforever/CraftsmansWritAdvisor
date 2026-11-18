local addonName, ns = ...

-- ============================================================
-- Craftsman's Writ data (patch 1.60.1)
--
-- Writ item IDs, the item each writ asks for, and quest IDs are
-- from the 1.60.1 game files as listed by warcraftmaps.com
-- (data updated 17 Nov 2026). Tier is set by writ ID range,
-- which matches the tier tables on wow.gg and conquestcapped.com.
-- Customers are from conquestcapped.com (15 Nov 2026); a zone
-- ending in "?" is a player report without a confirmed NPC.
-- Every order wants one item except Crafted Solid Shot (x200).
--
-- Four requested items have no item record in the game files
-- (item = nil). Fix them in game with /cwa setitem.
-- ============================================================

ns.TIERS = {
    { key = "Journeyman", rep = 75,  sealed = 262888, first = 264011, last = 264055,
      pouch = 3350, color = { 0.290, 0.639, 1.000 } },
    { key = "Expert",     rep = 125, sealed = 262889, first = 264056, last = 264115,
      pouch = 7000, color = { 0.761, 0.482, 1.000 } },
    { key = "Artisan",    rep = 200, sealed = 262890, first = 264116, last = 264160,
      pouch = 7500, color = { 1.000, 0.604, 0.180 } },
}
-- pouch = rough midpoint of reported coin pouch values, in copper
-- (Journeyman 22-45s, Expert 50-90s, Artisan about 75s).

ns.WRITS = {}

-- W(writID, itemID, qty, profession, skill, item name, zone, customer)
local function W(id, item, qty, prof, skill, name, zone, npc)
    ns.WRITS[id] = { id = id, item = item, qty = qty, prof = prof, skill = skill,
                     name = name, zone = zone, npc = npc }
end

-- ── JOURNEYMAN (75 rep) ─────────────────────────────────────
W(264011,   nil,   1, "Alch", 175, "Elixir of Ogre's Strength",     "Alterac Mountains",    "Sos'mol")
W(264012,  3383,   1, "Alch", 120, "Elixir of Wisdom",              "Arathi Highlands",     "Muggol Breezebeard")
W(264013,  3385,   1, "Alch", 145, "Lesser Mana Potion",            "Ashenvale",            "Ash'alari")
W(264014,  6048,   1, "Alch", 135, "Shadow Protection Potion",      "Duskwood",             "Kzixx")
W(264015,  5634,   1, "Alch", 150, "Free Action Potion",            "Hillsbrad Foothills",  "Webbed Mudsnout Gnoll")
W(264016,  3390,   1, "Alch", 140, "Elixir of Lesser Agility",      "Stonetalon Mountains", "Ziz Fizziks")
W(264017,  3388,   1, "Alch", 150, "Lesser Troll's Blood Elixir",   "Stranglethorn Vale",   "Short John Mithril")
W(264018,  8951,   1, "Alch", 215, "Elixir of Defense",             "Thousand Needles",     "Rizzle Brassbolts")
W(264019,  5996,   1, "Alch", 120, "Draught of Water Breathing",    "Wetlands",             "Kixxle")
W(264020,   nil,   1, "BS",   115, "Pearl-Handled Dagger",          "Alterac Mountains",    "Alan Sneeks")
W(264021, 11128,   1, "BS",   130, "Golden Rod",                    "Arathi Highlands",     "Muggol Breezebeard")
W(264022,  5541,   1, "BS",   115, "Iridescent Hammer",             "Ashenvale",            "Cowardly Peon")
W(264023, 15869,   1, "BS",    75, "Silver Skeleton Key",           "Duskwood",             "Battered Trunk (crypt)")
W(264024,  3491,   1, "BS",   135, "Heavy Bronze Mace",             "Hillsbrad Foothills",  "Gorgrash")
W(264025,  2865,   1, "BS",    95, "Rough Bronze Leggings",         "Stonetalon Mountains", "Ziz Fizziks")
W(264026,  3485,   1, "BS",   125, "Green Iron Gauntlets",          "Stranglethorn Vale",   "\"Sea Wolf\" MacKinley")
W(264027,  3848,   1, "BS",   110, "Big Bronze Knife",              "Thousand Needles",     "\"Plucky\" Johnson")
W(264028,  3484,   1, "BS",   120, "Green Iron Boots",              "Wetlands",             "Kixxle")
W(264029,  5507,   1, "Eng",  160, "Ornate Spyglass",               "Alterac Mountains",    "Alan Sneeks")
W(264030,  4384,   1, "Eng",  175, "Explosive Sheep",               "Arathi Highlands",     "Alyce")
W(264031,  4383,   1, "Eng",  145, "Moonsight Rifle",               "Ashenvale",            "Grembly")
W(264032,  4381,   1, "Eng",  140, "Minor Recombobulator",          "Duskwood",             "Kzixx")
W(264033,  6712,   1, "Eng",  115, "Practice Lock",                 "Hillsbrad Foothills",  "Gorgrash")
W(264034,  4373,   1, "Eng",  120, "Shadow Goggles",                "Stonetalon Mountains", "Ziz Fizziks")
W(264035,  7506,   1, "Eng",  125, "Gnomish Universal Remote",      "Stranglethorn Vale",   "Scooty")
W(264036,  4380,   1, "Eng",  140, "Big Bronze Bomb",               "Thousand Needles",     "Razzeric")
W(264037,  8069, 200, "Eng",  125, "Crafted Solid Shot",            "Wetlands",             "Kixxle")
W(264038, 18662,   1, "LW",   125, "Heavy Leather Ball",            "Alterac Mountains",    "Sos'mol")
W(264039,  5958,   1, "LW",    80, "Fine Leather Pants",            "Arathi Highlands",     "Alyce")
W(264040,  7349,   1, "LW",   110, "Herbalist's Gloves",            "Ashenvale",            "Murache")
W(264041,  2317,   1, "LW",    75, "Dark Leather Tunic",            "Duskwood",             "Kzixx")
W(264042,  7358,   1, "LW",   115, "Pilferer's Gloves",             "Hillsbrad Foothills",  "Kris Legace")
W(264043,  7371,   1, "LW",   145, "Heavy Quiver",                  "Stonetalon Mountains", "Ziz Fizziks")
W(264044,  4252,   1, "LW",   115, "Dark Leather Shoulders",        "Stranglethorn Vale",   "Narkk")
W(264045,  4254,   1, "LW",   125, "Barbaric Gloves",               "Thousand Needles",     "Goblin Pit Boss")
W(264046,  7284,   1, "LW",    95, "Red Whelp Gloves",              "Wetlands",             "Kixxle")
W(264047,  5766,   1, "Tail", 130, "Lesser Wizard's Robe",          "Alterac Mountains",    "Alan Sneeks")
W(264048,  6263,   1, "Tail",  75, "Blue Overalls",                 "Arathi Highlands",     "Alyce")
W(264049,  7048,   1, "Tail", 130, "Azure Silk Hood",               "Ashenvale",            "Cowardly Peon")
W(264050,  4245,   1, "Tail", 145, "Small Silk Pack",               "Duskwood",             "Kzixx")
W(264051,  4317,   1, "Tail", 100, "Phoenix Pants",                 "Alterac Mountains",    "Bath'rah the Windwatcher")
W(264052,  4313,   1, "Tail",  75, "Red Woolen Boots",              "Stonetalon Mountains", "Ziz Fizziks")
W(264053, 10048,   1, "Tail",  70, "Colorful Kilt",                 "Stranglethorn Vale",   "Hekshi")
W(264054,  6264,   1, "Tail",  90, "Greater Adept's Robe",          "Thousand Needles",     "Magus Tirth")
W(264055,  4321,   1, "Tail", 115, "Spider Silk Slippers",          "Wetlands",             "Kixxle")

-- ── EXPERT (125 rep) ────────────────────────────────────────
W(264056,  6050,   1, "Alch", 190, "Frost Protection Potion",       "Badlands",             "Lotwil Veriatus")
W(264057,  3823,   1, "Alch", 185, "Lesser Invisibility Potion",    "Desolace",             "Centaur Pariah")
W(264058,  4623,   1, "Alch", 215, "Lesser Stoneshield Potion",     "Dustwallow Marsh",     "Mudcrush Durtfeet")
W(264059,  6052,   1, "Alch", 190, "Nature Protection Potion",      "Felwood",              "Greta Mosshoof")
W(264060, 10592,   1, "Alch", 220, "Catseye Draught",               "Feralas",              "Scout Raroul")
W(264061,  5633,   1, "Alch", 175, "Great Rage Potion",             "Moonglade",            "Dendrite Starblaze")
W(264062,  3827,   1, "Alch", 180, "Mana Potion",                   "Riverglades",          "Spek")
W(264063,  6049,   1, "Alch", 165, "Fire Protection Potion",        "Searing Gorge",        "Durganon")
W(264064,  3824,   1, "Alch", 165, "Shadow Oil",                    "Swamp of Sorrows",     "Mukomonji")
W(264065,  9061,   1, "Alch", 210, "Goblin Rocket Fuel",            "Tanaris",              "Alchemist Pestlezugg")
W(264066,  8949,   1, "Alch", 205, "Elixir of Agility",             "The Hinterlands",      "Juo")
W(264067,  9144,   1, "Alch", 225, "Wildvine Potion",               "Un'Goro Crater",       "Spark Nilminer")
W(264068,  7922,   1, "BS",   210, "Steel Plate Helm",              "Badlands",             "Furious Shadowforge Digger")
W(264069,  9060,   1, "BS",   200, "Inlaid Mithril Cylinder",       "Desolace",             "Bibbly F'utzbuckle")
W(264070,  6041,   1, "BS",   165, "Steel Weapon Chain",            "Dustwallow Marsh",     "Ugbert")
W(264071,  7928,   1, "BS",   200, "Ornate Mithril Shoulders",      "Felwood",              "Taronn Redfeather")
W(264072,  7942,   1, "BS",   195, "Blue Glittering Axe",           "Feralas",              "Scout Raroul")
W(264073,  3853,   1, "BS",   155, "Moonsteel Broadsword",          "Moonglade",            "Meliri")
W(264074,  3837,   1, "BS",   165, "Golden Scale Coif",             "Riverglades",          "Spek")
W(264075,  7964,   1, "BS",   175, "Solid Sharpening Stone",        "Searing Gorge",        "Master Smith Burninate")
W(264076,  7943,   1, "BS",   200, "Wicked Mithril Blade",          nil,                    nil)
W(264077, 11144,   1, "BS",   180, "Truesilver Rod",                "Tanaris",              "Spigot Operator Luglunket")
W(264078,  9366,   1, "BS",   180, "Golden Scale Gauntlets",        nil,                    nil)
W(264079,  7941,   1, "BS",   210, "Heavy Mithril Axe",             "Un'Goro Crater",       "Torwa Pathfinder")
W(264080,  4396,   1, "Eng",  200, "Mechanical Dragonling",         "Badlands?",            nil)
W(264081,  4392,   1, "Eng",  185, "Advanced Target Dummy",         "Desolace",             "Bibbly F'utzbuckle")
W(264082,  4393,   1, "Eng",  185, "Craftsman's Monocle",           "Dustwallow Marsh",     "The Ravenous")
W(264083,  4395,   1, "Eng",  195, "Goblin Land Mine",              "Felwood",              "Jessir Moonbow")
W(264084, 10501,   1, "Eng",  220, "Catseye Ultra Goggles",         "Feralas",              "Scout Raroul")
W(264085, 10560,   1, "Eng",  200, "Unstable Trigger",              "Moonglade",            "Narianna")
W(264086,  4852,   1, "Eng",  185, "Flash Bomb",                    "Riverglades",          "Spek")
W(264087, 10500,   1, "Eng",  225, "Fire Goggles",                  "Searing Gorge",        "Durganon")
W(264088, 10514,   1, "Eng",  215, "Mithril Frag Bomb",             "Swamp of Sorrows",     "Bullets Bigblast")
W(264089,   nil,   1, "Eng",  175, "Gyromatic Micro-Adjuster",      "Tanaris",              "Jhordy Lapforge")
W(264090, 11590,   1, "Eng",  200, "Mechanical Repair Kit",         "The Hinterlands",      "Rhapsody Shindigger")
W(264091, 16005,   1, "Eng",  285, "Dark Iron Bomb",                nil,                    nil)
W(264092,  8174,   1, "LW",   175, "Comfortable Leather Hat",       "Badlands",             "Garek")
W(264093,  5965,   1, "LW",   125, "Guardian Cloak",                "Desolace",             "Azore Aldamort")
W(264094,  7378,   1, "LW",   180, "Dusky Bracers",                 "Dustwallow Marsh",     "The Ravenous")
W(264095,  8214,   1, "LW",   200, "Wild Leather Helmet",           "Felwood",              "Ivy Leafrunner")
W(264096,  8210,   1, "LW",   195, "Wild Leather Shoulders",        "Feralas?",             nil)
W(264097,  8217,   1, "LW",   220, "Quickdraw Quiver",              "Moonglade",            "Narianna")
W(264098,  7391,   1, "LW",   175, "Swift Boots",                   "Riverglades",          "Spek")
W(264099,  8192,   1, "LW",   185, "Nightscape Shoulders",          "Searing Gorge",        "Evonice Sootsmoker")
W(264100,  8201,   1, "LW",   195, "Big Voodoo Mask",               "Swamp of Sorrows",     "Mukomonji")
W(264101,  8200,   1, "LW",   190, "Big Voodoo Robe",               "Tanaris",              "Yeh'kinya")
W(264102,  8189,   1, "LW",   205, "Turtle Scale Breastplate",      "The Hinterlands",      "Juo")
W(264103,  8218,   1, "LW",   220, "Thick Leather Ammo Pouch",      "Un'Goro Crater",       "Nergal")
W(264104, 10050,   1, "Tail", 205, "Mageweave Bag",                 "Badlands",             "Rigglefuzz")
W(264105, 10023,   1, "Tail", 205, "Shadoweave Gloves",             "Desolace",             "Willow")
W(264106,  7063,   1, "Tail", 170, "Crimson Silk Robe",             "Dustwallow Marsh",     "Tabetha")
W(264107, 10004,   1, "Tail", 195, "Shadoweave Robe",               "Felwood",              "Eridan Bluewind")
W(264108, 22246,   1, "Tail", 190, "Enchanted Mageweave Pouch",     "Felwood?",             nil)
W(264109,  4329,   1, "Tail", 165, "Star Belt",                     "Moonglade",            "Mylentha Riverbend")
W(264110,  9998,   1, "Tail", 185, "Black Mageweave Vest",          "Riverglades",          "Spek")
W(264111, 10009,   1, "Tail", 180, "Red Mageweave Pants",           "Searing Gorge",        "Lookout Captain Lolo Longstriker")
W(264112, 10052,   1, "Tail", 185, "Orange Martial Shirt",          "Swamp of Sorrows",     "Bullets Bigblast")
W(264113, 10008,   1, "Tail", 180, "White Bandit Mask",             "Tanaris",              "Vizzklick")
W(264114, 10042,   1, "Tail", 205, "Cindercloth Robe",              "The Hinterlands",      "Atal'ai Exile")
W(264115,  7061,   1, "Tail", 160, "Earthen Silk Belt",             "Un'Goro Crater",       "Petra Grossen")

-- ── ARTISAN (200 rep) ───────────────────────────────────────
W(264116,   nil,   1, "Alch", 265, "Potion of Demonslaying",        "Azshara",              "Archmage Xylem")
W(264117, 12190,   1, "Alch", 245, "Dreamless Sleep Potion",        "Blasted Lands",        "Kum'isha the Collector")
W(264118, 13457,   1, "Alch", 290, "Greater Fire Protection Potion", nil,                   nil)
W(264119,  9233,   1, "Alch", 265, "Draught of Detect Demon",       "Deadwind Pass",        "Hastings")
W(264120,  9088,   1, "Alch", 240, "Gift of Arthas",                "Eastern Plaguelands",  "Adon")
W(264121, 13513,   1, "Alch", 300, "Flask of Chromatic Resistance", nil,                    nil)
W(264122,  3387,   1, "Alch", 250, "Limited Invulnerability Potion", nil,                   nil)
W(264123, 18253,   1, "Alch", 300, "Major Rejuvenation Potion",     nil,                    nil)
W(264124, 246948,  1, "Alch", 250, "Distilled Firewater",           nil,                    nil)
W(264125, 12417,   1, "BS",   270, "Radiant Circlet",               nil,                    nil)
W(264126, 12416,   1, "BS",   235, "Radiant Belt",                  "Blasted Lands",        "Kum'isha the Collector")
W(264127,  7929,   1, "BS",   225, "Orcish War Leggings",           nil,                    nil)
W(264128,  7969,   1, "BS",   210, "Mithril Spurs",                 "Deadwind Pass?",       nil)
W(264129, 12422,   1, "BS",   275, "Imperial Plate Chest",          nil,                    nil)
W(264130, 20549,   1, "BS",   300, "Darkrune Gauntlets",            nil,                    nil)
W(264131, 12775,   1, "BS",   255, "Huge Thorium Battleaxe",        nil,                    nil)
W(264132, 15872,   1, "BS",   250, "Arcanite Skeleton Key",         nil,                    nil)
W(264133,  7947,   1, "BS",   230, "Ebon Shiv",                     nil,                    nil)
W(264134, 16023,   1, "Eng",  275, "Masterwork Target Dummy",       nil,                    nil)
W(264135, 10504,   1, "Eng",  265, "Green Lens",                    nil,                    nil)
W(264136, 15996,   1, "Eng",  265, "Lifelike Mechanical Toad",      nil,                    nil)
W(264137, 18645,   1, "Eng",  265, "Gnomish Alarm-O-Bot",           nil,                    nil)
W(264138, 18587,   1, "Eng",  265, "Goblin Jumper Cables XL",       nil,                    nil)
W(264139, 18232,   1, "Eng",  300, "Field Repair Bot 74A",          nil,                    nil)
W(264140, 18631,   1, "Eng",  260, "Truesilver Transformer",        "Silithus",             "Khur Hornstriker")
W(264141, 10548,   1, "Eng",  240, "Sniper Scope",                  nil,                    nil)
W(264142, 21277,   1, "Eng",  320, "Tranquil Mechanical Yeti",      nil,                    nil)
W(264143, 15087,   1, "LW",   265, "Wicked Leather Pants",          nil,                    nil)
W(264144, 18258,   1, "LW",   285, "Gordok Ogre Suit",              nil,                    nil)
W(264145, 15053,   1, "LW",   260, "Volcanic Breastplate",          nil,                    nil)
W(264146, 15094,   1, "LW",   265, "Runic Leather Headband",        "Deadwind Pass",        "Hastings")
W(264147, 15084,   1, "LW",   240, "Wicked Leather Bracers",        "Eastern Plaguelands",  "Quartermaster Miranda Breechlock")
W(264148, 15075,   1, "LW",   265, "Chimeric Vest",                 nil,                    nil)
W(264149, 15080,   1, "LW",   270, "Heavy Scorpid Helm",            nil,                    nil)
W(264150, 15092,   1, "LW",   250, "Runic Leather Bracers",         "Western Plaguelands",  "Fallen Adventurer")
W(264151, 15071,   1, "LW",   250, "Frostsaber Boots",              nil,                    nil)
W(264152, 14130,   1, "Tail", 260, "Wizardweave Turban",            nil,                    nil)
W(264153, 14046,   1, "Tail", 215, "Runecloth Bag",                 "Blasted Lands",        "Kum'isha the Collector")
W(264154, 13864,   1, "Tail", 235, "Runecloth Boots",               "Burning Steppes",      "Gorzeeki Wildeyes")
W(264155, 10036,   1, "Tail", 140, "Tuxedo Jacket",                 "Deadwind Pass",        "Hastings")
W(264156, 14108,   1, "Tail", 240, "Felcloth Boots",                nil,                    nil)
W(264157, 22251,   1, "Tail", 230, "Cenarion Herb Bag",             nil,                    nil)
W(264158, 10025,   1, "Tail", 200, "Shadoweave Mask",               "Silithus",             "Hermit Ortell")
W(264159, 14141,   1, "Tail", 225, "Ghostweave Vest",               nil,                    nil)
W(264160, 21340,   1, "Tail", 215, "Soul Pouch",                    "Winterspring?",        nil)

-- ============================================================
-- Derived lookups
-- ============================================================
-- Quest ID = writ ID - 169800 for every writ except 264011.
local QUEST_OFFSET = 169800
local QUEST_EXCEPTIONS = { [264011] = 94004 }

ns.TIER_BY_KEY   = {}
ns.SEALED        = {}   -- [sealed writ itemID] = tier key
ns.QUEST_TO_WRIT = {}   -- [questID] = writID
ns.TRACKED_ITEMS = {}   -- every item ID whose cached name or price matters

for _, tier in ipairs(ns.TIERS) do
    ns.TIER_BY_KEY[tier.key] = tier
    ns.SEALED[tier.sealed] = tier.key
    ns.TRACKED_ITEMS[tier.sealed] = true
    tier.ids = {}
    for id = tier.first, tier.last do
        local w = ns.WRITS[id]
        if w then
            w.tier = tier.key
            w.quest = QUEST_EXCEPTIONS[id] or (id - QUEST_OFFSET)
            ns.QUEST_TO_WRIT[w.quest] = id
            ns.TRACKED_ITEMS[id] = true
            if w.item then ns.TRACKED_ITEMS[w.item] = true end
            tier.ids[#tier.ids + 1] = id
        end
    end
end
