#!/usr/bin/env python3
"""Classify every QuestInfo stage into Goal + AcquireMethod. No invented NPCs/items."""

from __future__ import annotations

import json
import re
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
QUESTS_PATH = ROOT / "research" / "quests.json"

SHOP = {
    "Flintlock": 150,
    "Cutlass": 200,
    "Rowboat": 50,
    "Transponder Snail": 100,
    "Rusty Pickaxe": 25,
    "Rusty Shovel": 25,
    "Wooden Rod": 75,
    "Worm": 5,
    "Apple": 5,
    "Lemon": 5,
    "Banana": 5,
    "Carrot": 5,
    "Potato": 5,
    "Eggplant": 5,
    "Pet Food": 100,
}

ORES = {
    "Copper Ore",
    "Iron Ore",
    "Lead Ore",
    "Silver Ore",
    "Gold Ore",
    "Diamond Ore",
    "Emerald Ore",
    "Obsidian",
}
BARS = {"Copper Bar", "Iron Bar", "Silver Bar", "Gold Bar", "Lead"}
FOOD = {"Apple", "Lemon", "Banana", "Carrot", "Potato", "Eggplant", "Apple Pot Pie", "Dish"}
FISH = {"Carp", "Worm", "Soggy Boot"}

BOSSES = {
    "Afuaru, The Hoarder",
    "Axe-Hand Logan",
    "Choppy The Clown",
    "The Beast?",
    "Soro",
    "Blonde Goblin",
    "Circus Lion",
    '"Barrel Clown" Binki',
    '"Hypnotist" Mango',
}

KILL_BY_QUEST = {
    "Stephon's Tormentor": '"Barrel Clown" Binki',
    "The Wandering Hypnotist": '"Hypnotist" Mango',
}

SKIP = {
    "Debug Quest",
    "Debug Quest 2",
    "Daily Quest Test",
    "Weekly Quest Test",
    "Jack's Daily Haul",
    "Kim Wu's Daily Quota",
    "Joe's Daily Chores",
    "Remy's Daily Order",
    "The Stolen Tip Jar",
    "Officer Investigation",
    "Leveling Skill",
    "Aim Training",
}

NEVER_SKIP = {"Escort The Mayor", "The Wandering Hypnotist"}

ANCHOR_STORY = [
    "Introduction",
    "Basics",
    "Pirate Fan Letter",
    "Gearing Up",
    "The Hoarder",
    "First Upgrade",
    "Tea Party Crashers",
    "Captain's Brat",
    "Feral Dog",
    "Gate of Authority",
    "Captive Swordsman",
    "Axe-Handed Tyrant",
    "A Voice in a Shell",
    "Setting Sail",
]
CLOWN_STORY = [
    "A Joke Gone Too Far",
    "Sabotage The Cannon",
    "Lion's Victim",
    "Stephon's Tormentor",
    "Butcher's Business",
    "Circus Suppliers",
    "Clown Captives",
    "Revenge of the Nibblebottom",
    "Escort The Mayor",
    "Mayor's Stache",
    "Clown Town's Militia",
    "The Ringmaster",
    "Journey to Maple Village",
]
MAPLE_STORY = [
    "The Island's Protector",
    "Proof of Pirates",
    "Something Isn't Right",
    "Pirate Instructions",
    "The Wandering Hypnotist",
    "The Beast of Maple Village",
    "Missing Servants",
    "Expose the Butler",
    "Raid Preparations",
    "Stocked for a Siege",
    "Destroy the Signalers",
    "The Black Noir Raid",
]
MAIN_ROUTE = ANCHOR_STORY + CLOWN_STORY + MAPLE_STORY

HANDLED = {
    "Talk",
    "Automatic Talk",
    "Kill",
    "Defeat",
    "Hit",
    "Destroy",
    "Shoot",
    "Purchase",
    "Sell",
    "Equip",
    "Upgrade",
    "EquipSkill",
    "Cast",
    "Required",
    "Collect",
    "CollectLocal",
    "CollectLocalItem",
    "Loot",
    "Mine",
    "Smelt",
    "Fish",
    "Plant",
    "Harvest",
    "Water",
    "Fertilize",
    "Cook",
    "Perfect Cook",
    "Craft",
    "Deliver",
    "Donate",
    "GiveItemTo",
    "Interact",
    "Investigate",
    "Wake",
    "Check On",
    "Open",
    "Free",
    "Visit",
    "Reach",
    "Spawn",
    "Escort",
    "Dash",
    "Block",
    "Travel",
    "Boss",
    "Unlock",
    "Deliver Object",
    "Reach Maple Village",
    "Investigate The Footsteps (1)",
    "Investigate The Footsteps (2)",
    "Investigate The Wreckage",
    "Investigate The Beast's Den",
    "Investigate The Garden",
    "Investigate The Fountain",
    "Defend",
}

UNRESOLVED_TYPES = {
    "Defend",
    "Craft",
    "Emote",
    "Convince",
    "Dig",
    "Steal",
    "Cash Out",
    "Unlock Skill",
}

ITEM_OVERRIDE = {
    "Pirate Fan Letter": {
        "method": "EnemyDrop",
        "source": "Corrupt Marine",
        "source_location": "Anchor Town",
        "confidence": "STATIC_VERIFIED",
        "note": "QuestInfo marker tag Corrupt Marine; description coughs it up. Not Strong Marine.",
    },
    "Pirate Instructions": {
        "method": "EnemyDrop",
        "source": "Black Noir Officer",
        "source_location": "Maple Village",
        "confidence": "STATIC_VERIFIED",
        "note": "QuestInfo marker Black Noir Officer Marker; beat officers until drop.",
    },
    "Afuaru's Key": {
        "method": "BossDrop",
        "source": "Afuaru, The Hoarder",
        "source_location": "Anchor Town",
        "confidence": "STATIC_VERIFIED",
    },
    "Stolen Watch": {
        "method": "EnemyDrop",
        "source": "Corrupt Marine",
        "source_location": "Anchor Town",
        "confidence": "STATIC_VERIFIED",
        "note": "quests[].drops on Pirate Fan Letter; Gearing Up Sell.",
    },
    "Rusty Pickaxe": {
        "method": "ShopPurchase",
        "source": "Rusty Pickaxe",
        "source_location": "Anchor Town",
        "gold": 25,
        "confidence": "STATIC_VERIFIED",
    },
    "Flintlock": {
        "method": "ShopPurchase",
        "source": "Flintlock",
        "source_location": "Anchor Town",
        "gold": 150,
        "confidence": "STATIC_VERIFIED",
    },
    "Transponder Snail": {
        "method": "ShopPurchase",
        "source": "Transponder Snail",
        "source_location": "Anchor Town",
        "gold": 100,
        "confidence": "STATIC_VERIFIED",
    },
    "Rowboat": {
        "method": "ShopPurchase",
        "source": "Rowboat",
        "source_location": "Anchor Town",
        "gold": 50,
        "confidence": "STATIC_VERIFIED",
    },
    "Copper Ore": {"method": "Mining", "source": "Copper Ore", "source_location": "Anchor Town", "confidence": "STATIC_VERIFIED"},
    "Iron Ore": {"method": "Mining", "source": "Iron Ore", "source_location": "Anchor Town", "confidence": "STATIC_VERIFIED"},
    "Lead Ore": {"method": "Mining", "source": "Lead Ore", "source_location": "Maple Village", "confidence": "STATIC_VERIFIED"},
    "Copper Bar": {"method": "Crafting", "source": "Furnace", "source_location": "Anchor Town", "confidence": "STATIC_VERIFIED"},
    "Afuaru's Chests": {"method": "Chest", "source": "Afuaru's Chests", "source_location": "Anchor Town", "confidence": "STATIC_VERIFIED"},
}

DROP_RE = re.compile(
    r"coughs it up|until one of them drop|beat them up|beat up the|stole .*letter",
    re.I,
)
PURCHASE_RE = re.compile(r"purchase|buy a |buy the ", re.I)
MINE_RE = re.compile(r"\bmine\b|mining", re.I)

RUNTIME_VERIFIED_KEYS = {
    ("Introduction", "Talk", "Officer Graves"),
    ("Introduction", "Hit", "Training Dummy"),
    ("Introduction", "Dash", ""),
    ("Introduction", "Block", ""),
    ("Basics", "Talk", "Officer Graves"),
    ("Basics", "EquipSkill", "Strong Punch"),
    ("Basics", "Cast", "Strong Punch"),
    ("Basics", "Required", "TotalStatPoints"),
    ("Basics", "Open", "Logbook"),
}

MARKER_OVERRIDE = {
    "Reach Maple Village": "Maple Village Marker",
    "Investigate The Footsteps (1)": "Campsite Footsteps Marker",
    "Investigate The Footsteps (2)": "Campsite Footsteps Marker",
    "Investigate The Wreckage": "Beast Wreckage Marker",
    "Investigate The Beast's Den": "Beast Den Marker",
    "Investigate The Garden": "Mansion Garden Marker",
    "Investigate The Fountain": "Mansion Fountain Marker",
}


def load_quests() -> list[dict]:
    data = json.loads(QUESTS_PATH.read_text(encoding="utf-8"))
    return data["quests"]


def strip_marker(tag: str | None) -> str | None:
    if not tag:
        return None
    t = tag.strip()
    if t.endswith(" Marker"):
        t = t[: -len(" Marker")].strip()
    if t.endswith(" (Dialogue)"):
        t = t[: -len(" (Dialogue)")].strip()
    return t or None


def cond_target(cond: dict) -> str:
    t = cond.get("target") or cond.get("Target") or ""
    if isinstance(t, dict):
        t = t.get("Name") or t.get("name") or ""
    return "" if t == "\\" else str(t)


def cond_type(cond: dict) -> str:
    return str(cond.get("type") or cond.get("Type") or "")


def cond_amount(cond: dict) -> int:
    return int(cond.get("amount") or cond.get("Amount") or 1)


def stage_marker(stage: dict, cond: dict | None = None) -> str | None:
    markers = stage.get("markers") or []
    typ = cond_type(cond) if cond else ""
    if typ in MARKER_OVERRIDE:
        return MARKER_OVERRIDE[typ]
    if not markers:
        return None
    if cond and len(markers) > 1:
        tgt = cond_target(cond)
        for m in markers:
            tag = m.get("tag")
            if tag == tgt or strip_marker(tag) == tgt:
                return tag
    return markers[0].get("tag")


def kill_name(quest: dict, raw: str) -> str:
    qn = quest.get("name")
    if qn in KILL_BY_QUEST:
        return KILL_BY_QUEST[qn]
    return raw


def enemy_names(quests: list[dict]) -> set[str]:
    names: set[str] = set()
    for q in quests:
        for k in q.get("kills") or []:
            t = k.get("target")
            if t and t != "\\":
                names.add(t)
                names.add(strip_marker(t) or t)
        for st in q.get("stages") or []:
            for c in st.get("conditions") or []:
                if cond_type(c) in {"Kill", "Defeat", "Hit", "Destroy", "Shoot"}:
                    t = kill_name(q, cond_target(c))
                    if t:
                        names.add(t)
                        names.add(strip_marker(t) or t)
            for m in st.get("markers") or []:
                tag = m.get("tag") or ""
                if tag.endswith(" Marker") or "Marine" in tag or "Pirate" in tag or "Clown" in tag:
                    names.add(strip_marker(tag) or tag)
    names.update(BOSSES)
    names.add("Corrupt Marine")
    names.add("Black Noir Officer")
    names.add("Corrupt Marine Officer")
    names.add("Corrupt Guard")
    return {n for n in names if n}


def handler_for(goal: str, method: str | None, typ: str) -> str:
    if typ in UNRESOLVED_TYPES and typ == "Defend":
        return "UNKNOWN"
    if typ == "Craft":
        return "UNKNOWN"
    table = {
        "Talk": "Quest.talk",
        "Kill": "Combat.attack",
        "LevelGate": "DecisionEngine.levelFarm",
        "Invest": "Stats.investMinimum",
        "Skill": "Skills.equip/cast",
        "Sell": "Shop.sellNamed",
        "Equip": "Equipment.equipNamed",
        "Upgrade": "Equipment.upgradeNamed",
        "Travel": "Travel.goIsland",
        "Spawn": "Boat.spawnRowboat",
        "Escort": "Quest.escort",
        "CombatAction": "Combat.dash/block",
        "Interact": "Quest.goTagged",
        "Deliver": "Quest.talk",
        "DeliverObject": "Quest.goTagged",
        "OpenLogbook": "Quest.openLogbook",
    }
    if goal in table:
        return table[goal]
    if goal == "AcquireItem":
        return {
            "AlreadyOwned": "PlayerData.hasItem",
            "WorldPickup": "Acquire.WorldPickup",
            "EnemyDrop": "Acquire.AcquireFromEnemyDrop",
            "BossDrop": "Acquire.AcquireFromEnemyDrop",
            "ShopPurchase": "Shop.buy",
            "QuestReward": "Acquire.QuestReward",
            "Interactable": "Acquire.Interactable",
            "Mining": "LifeSkills.mineToward",
            "Fishing": "LifeSkills.fishToward",
            "Farming": "LifeSkills.farmToward",
            "Cooking": "LifeSkills.cookToward",
            "Crafting": "LifeSkills.mineToward",
            "Chest": "Chest.openNearby",
            "Treasure": "Treasure",
            "Dialogue": "Quest.talk",
            "OtherVerified": "Acquire.OtherVerified",
        }.get(method or "", "Acquire.AcquireItem")
    if typ in HANDLED:
        return "Quest.handleCondition"
    return "UNKNOWN"


def classify_objective(quest: dict, stage: dict, cond: dict, enemies: set[str]) -> dict:
    typ = cond_type(cond)
    target = cond_target(cond)
    amount = cond_amount(cond)
    island = quest.get("island") or ""
    desc = stage.get("description") or cond.get("description") or ""
    marker = stage_marker(stage, cond)
    source_loc = island
    prereq = list(quest.get("prerequisites") or [])
    qn = quest["name"]

    if typ in {"Kill", "Defeat"}:
        target = kill_name(quest, target)
    if typ == "Dash":
        target = target or "Press Q"
    if typ == "Block":
        target = target or "Hold F"

    goal = "Other"
    method = None
    source = target
    confidence = "STATIC_VERIFIED"
    status = "IMPLEMENTED"
    note = ""

    if typ in UNRESOLVED_TYPES and typ != "Craft":
        goal = "Unresolved"
        method = None
        source = target
        status = "UNRESOLVED"
        confidence = "UNKNOWN"
        if qn in NEVER_SKIP and typ != "Defend":
            status = "RUNTIME_REQUIRED"
    elif typ == "Craft":
        goal = "AcquireItem"
        method = "Crafting"
        source = target
        status = "UNRESOLVED"
        confidence = "UNKNOWN"
        note = "Craft remote args UNKNOWN"
    elif typ in {"Talk", "Automatic Talk"}:
        goal = "Talk"
        source = target
    elif typ in {"Kill", "Defeat", "Hit", "Destroy", "Shoot"}:
        goal = "Kill"
        source = target
        if marker:
            source_loc = island
    elif typ == "Required" and target == "Level":
        goal = "LevelGate"
        source = None
        status = "IMPLEMENTED"
    elif typ == "Required" and target == "TotalStatPoints":
        goal = "Invest"
        source = None
    elif typ in {"EquipSkill", "Cast"}:
        goal = "Skill"
        source = target
        status = "RUNTIME_VERIFIED" if (qn, typ, target) in RUNTIME_VERIFIED_KEYS else "IMPLEMENTED"
    elif typ == "Purchase":
        goal = "AcquireItem"
        method = "ShopPurchase"
        source = target
        if target in SHOP:
            note = f"gold {SHOP[target]}"
    elif typ == "Sell":
        goal = "Sell"
        source = target
    elif typ == "Equip":
        goal = "Equip"
        source = target
    elif typ == "Upgrade":
        goal = "Upgrade"
        source = target
    elif typ == "Mine":
        goal = "AcquireItem"
        method = "Mining"
        source = target
    elif typ == "Smelt":
        goal = "AcquireItem"
        method = "Crafting"
        source = "Furnace"
        note = "marker Furnace; EquipAndActivate only"
    elif typ == "Fish":
        goal = "AcquireItem"
        method = "Fishing"
        source = target
        status = "IMPLEMENTED"
        note = "cast packet UNRESOLVED; move+rod only"
    elif typ in {"Plant", "Harvest", "Water", "Fertilize"}:
        goal = "AcquireItem"
        method = "Farming"
        source = target
    elif typ in {"Cook", "Perfect Cook"}:
        goal = "AcquireItem"
        method = "Cooking"
        source = target
    elif typ in {"Deliver", "Donate", "GiveItemTo"}:
        goal = "Deliver"
        source = target
    elif typ == "Deliver Object":
        goal = "DeliverObject"
        source = target
    elif typ == "Spawn":
        goal = "Spawn"
        source = target
    elif typ == "Escort":
        goal = "Escort"
        source = target
        status = "IMPLEMENTED"
        note = "player-tagged escort model; defend nearby Party hostiles"
    elif typ in {"Dash", "Block"}:
        goal = "CombatAction"
        source = None
        status = "RUNTIME_VERIFIED"
    elif typ in {"Reach", "Travel"} or (typ or "").startswith("Reach "):
        goal = "Travel"
        source = target or "Maple Village"
    elif typ == "Unlock" or (typ or "").startswith("Investigate") or typ in {
        "Interact",
        "Investigate",
        "Wake",
        "Check On",
        "Open",
        "Free",
        "Visit",
    }:
        if typ == "Open" and target == "Logbook":
            goal = "OpenLogbook"
            source = "Logbook"
            status = "RUNTIME_VERIFIED"
        else:
            goal = "Interact"
            source = MARKER_OVERRIDE.get(typ) or marker or target
    elif typ in {"Collect", "CollectLocal", "CollectLocalItem", "Loot"}:
        goal = "AcquireItem"
        ov = ITEM_OVERRIDE.get(target)
        same_kills = [
            kill_name(quest, cond_target(c))
            for c in (stage.get("conditions") or [])
            if cond_type(c) in {"Kill", "Defeat"}
        ]
        mark_src = strip_marker(marker)
        if ov:
            method = ov["method"]
            source = ov.get("source")
            source_loc = ov.get("source_location") or island
            confidence = ov.get("confidence") or "STATIC_VERIFIED"
            note = ov.get("note") or ""
        elif target in SHOP or PURCHASE_RE.search(desc):
            method = "ShopPurchase"
            source = target
            if target in SHOP:
                note = f"gold {SHOP[target]}"
        elif target in ORES or MINE_RE.search(desc):
            method = "Mining"
            source = target
        elif target in BARS:
            method = "Crafting"
            source = "Furnace"
        elif typ == "Loot" or "Chest" in (target or ""):
            method = "Chest"
            source = target
        elif DROP_RE.search(desc) or (mark_src and mark_src in enemies and typ == "Collect"):
            method = "BossDrop" if (mark_src in BOSSES or (same_kills and same_kills[0] in BOSSES)) else "EnemyDrop"
            source = mark_src or (same_kills[0] if same_kills else None)
            if not source:
                status = "UNRESOLVED"
                confidence = "UNKNOWN"
                note = "KillUntilDrop text but no QuestInfo marker/kill target"
            else:
                note = note or f"KillUntilDrop marker={marker}"
        elif same_kills:
            method = "BossDrop" if same_kills[0] in BOSSES else "EnemyDrop"
            source = same_kills[0]
        elif typ in {"CollectLocal", "CollectLocalItem"}:
            method = "WorldPickup"
            source = marker or target
        elif target in FOOD:
            method = "Farming" if target != "Dish" else "Cooking"
            source = target
        else:
            method = "WorldPickup"
            source = marker or target
            if not source:
                status = "UNRESOLVED"
                confidence = "UNKNOWN"
    else:
        goal = "Other"
        method = "OtherVerified" if typ in HANDLED else None
        source = target or marker
        if typ not in HANDLED:
            status = "UNRESOLVED"
            confidence = "UNKNOWN"

    if qn in SKIP:
        status = "UNRESOLVED"
        note = (note + " ; skip stub").strip(" ;")

    if (qn, typ, target) in RUNTIME_VERIFIED_KEYS:
        status = "RUNTIME_VERIFIED"

    if typ == "Escort" and status != "IMPLEMENTED":
        status = "IMPLEMENTED"

    if goal == "AcquireItem" and method in {"EnemyDrop", "BossDrop"} and not source:
        status = "UNRESOLVED"

    validation = f"live {typ} {target or '-'} count {amount}"
    if goal == "AcquireItem":
        validation = f"inventory/quest {target} {amount}"

    return {
        "quest": qn,
        "quest_type": quest.get("type"),
        "folder": quest.get("folder"),
        "stage": int(stage.get("i", 0)) + 1,
        "stage_i": int(stage.get("i", 0)),
        "island": island,
        "objective": typ,
        "goal": goal,
        "target": target,
        "amount": amount,
        "acquire": method,
        "source": source,
        "source_location": source_loc,
        "marker": marker,
        "prerequisites": prereq,
        "handler": handler_for(goal, method, typ),
        "validation": validation,
        "confidence": confidence,
        "status": status,
        "description": desc,
        "note": note,
        "unlocks_next": quest.get("unlocks_next"),
        "automatic": quest.get("automatic"),
        "need_level": quest.get("need_level") or 0,
    }


def classify_all(quests: list[dict] | None = None) -> list[dict]:
    quests = quests or load_quests()
    enemies = enemy_names(quests)
    rows: list[dict] = []
    for q in quests:
        stages = q.get("stages") or []
        if not stages:
            rows.append(
                {
                    "quest": q["name"],
                    "quest_type": q.get("type"),
                    "folder": q.get("folder"),
                    "stage": 0,
                    "stage_i": -1,
                    "island": q.get("island") or "",
                    "objective": "",
                    "goal": "Unresolved",
                    "target": "",
                    "amount": 0,
                    "acquire": None,
                    "source": None,
                    "source_location": q.get("island") or "",
                    "marker": None,
                    "prerequisites": list(q.get("prerequisites") or []),
                    "handler": "UNKNOWN",
                    "validation": "none",
                    "confidence": "UNKNOWN",
                    "status": "UNRESOLVED",
                    "description": "empty stub",
                    "note": "no stages in QuestInfo",
                    "unlocks_next": q.get("unlocks_next"),
                    "automatic": q.get("automatic"),
                    "need_level": q.get("need_level") or 0,
                }
            )
            continue
        for st in stages:
            conds = st.get("conditions") or []
            if not conds:
                rows.append(
                    classify_objective(
                        q,
                        st,
                        {"type": "Unknown", "target": "", "amount": 1},
                        enemies,
                    )
                )
                rows[-1]["status"] = "UNRESOLVED"
                rows[-1]["handler"] = "UNKNOWN"
                continue
            for cond in conds:
                rows.append(classify_objective(q, st, cond, enemies))
    return rows


def item_specs(rows: list[dict]) -> dict:
    items = dict(ITEM_OVERRIDE)
    for r in rows:
        if r["goal"] != "AcquireItem" or not r["target"]:
            continue
        name = r["target"]
        if name in items:
            continue
        items[name] = {
            "method": r["acquire"] or "WorldPickup",
            "source": r["source"],
            "source_location": r["source_location"],
            "confidence": r["confidence"],
            "note": r.get("note") or "",
        }
    return items


def subgoals() -> dict:
    return {
        "First Upgrade": [
            {"goal": "HaveGold", "amount": 25, "item": "Gold"},
            {"goal": "AcquireItem", "item": "Rusty Pickaxe", "method": "ShopPurchase", "amount": 1},
            {"goal": "AcquireItem", "item": "Copper Ore", "method": "Mining", "amount": 2},
            {"goal": "AcquireItem", "item": "Copper Bar", "method": "Crafting", "amount": 2},
            {"goal": "Upgrade", "item": "Flintlock", "amount": 1},
        ]
    }


def coverage(rows: list[dict]) -> dict:
    def bucket(pred):
        rs = [r for r in rows if pred(r)]
        return {
            "stages": len(rs),
            "planned": sum(1 for r in rs if r["goal"] and r["goal"] != "Unresolved"),
            "implemented": sum(1 for r in rs if r["status"] in {"IMPLEMENTED", "RUNTIME_VERIFIED", "STATIC_VERIFIED"}),
            "runtime_verified": sum(1 for r in rs if r["status"] == "RUNTIME_VERIFIED"),
            "runtime_required": sum(1 for r in rs if r["status"] == "RUNTIME_REQUIRED"),
            "unresolved": sum(1 for r in rs if r["status"] == "UNRESOLVED"),
        }

    quests = {r["quest"] for r in rows}
    return {
        "quests": len(quests),
        "all": bucket(lambda _: True),
        "anchor": bucket(lambda r: r["quest"] in ANCHOR_STORY),
        "clown": bucket(lambda r: r["quest"] in CLOWN_STORY),
        "maple": bucket(lambda r: r["quest"] in MAPLE_STORY),
        "main_route": bucket(lambda r: r["quest"] in MAIN_ROUTE),
    }
