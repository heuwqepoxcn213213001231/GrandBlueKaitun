#!/usr/bin/env python3
"""Behavioral static assertions for continuous / zero-idle progression."""

from __future__ import annotations

from pathlib import Path
import re

ROOT = Path(__file__).resolve().parents[1]
FAILS: list[str] = []


def fail(msg: str) -> None:
    FAILS.append(msg)


def read(rel: str) -> str:
    return (ROOT / rel).read_text(encoding="utf-8")


def main() -> int:
    engine = read("Progression/DecisionEngine.lua")
    quest = read("Systems/Quest.lua")
    player = read("Game/PlayerData.lua")
    remotes = read("Game/Remotes.lua")
    broker = read("Core/RemoteBroker.lua")
    scheduler = read("Core/Scheduler.lua")
    combat = read("Systems/Combat.lua")
    loader = read("loader.lua")
    kaitun = read("kaitun.lua")
    world = read("Game/World.lua")
    config = read("Config.lua")
    stats = read("Systems/Stats.lua")

    if "farmSession" not in engine:
        fail("FarmSession missing")
    if "function M.markRealProgress" not in engine:
        fail("markRealProgress missing")
    if "fastFarmPath" not in engine:
        fail("repeatable fast path missing")
    if "scoreActive" not in engine:
        fail("multi-quest scoring missing")
    if re.search(r"progressed\s*=\s*true[\s\S]{0,80}lock_active", engine):
        fail("lock_active still treated as progressed=true")
    if 'reason = "lock_active"' not in engine or "progressed = false" not in engine:
        fail("lock_active must set progressed=false")
    if "BUG_NO_PLAN" not in engine:
        fail("BUG_NO_PLAN idle classification missing")
    if "WAIT_DATA" not in engine:
        fail("WAIT_DATA idle reason missing")
    if "cycle_reaccept" not in engine:
        fail("turn-in → immediate reaccept missing")

    if "function M.request" not in broker:
        fail("RemoteBroker.request missing")
    if "GetDataQuests" not in remotes or "requestQuests" not in remotes:
        fail("Remotes.requestQuests missing")
    if "requestStats" not in remotes:
        fail("Remotes.requestStats missing")
    if "function M.requestLive" not in player:
        fail("PlayerData.requestLive missing")
    if "GB.Remotes.getQuests()" in player.split("function M.refreshLive", 1)[-1][:1800]:
        fail("refreshLive still InvokeServer getQuests on calling thread")
    if "GB.Remotes.getStats()" in player.split("function M.pullStats", 1)[-1][:800]:
        fail("pullStats still InvokeServer on calling thread")
    if "GB.Remotes.getStats()" in stats:
        fail("Stats.tick path still calls GetStats sync")

    if "function M.nudge" not in scheduler:
        fail("Scheduler.nudge missing")
    if "def(\"Tick\", 0.15)" not in config:
        fail("Tick not 0.15")

    if "task.wait(0.05)" not in quest:
        fail("Quest wait loops not event-adaptive 0.05")
    if "timeout = timeout or 5.4" in quest:
        fail("waitQuestAccepted still uses 5.4s idle timeout")
    if "task.wait(0.35)" in quest.split("function waitQuestAccepted", 1)[0][-200:] and False:
        pass

    if "function GB.SelfCheck" not in kaitun:
        fail("SelfCheck missing")
    if "IdleReason" not in kaitun:
        fail("SelfCheck IdleReason missing")

    if "DEFAULT_BOOTSTRAP_REF" in loader:
        fail("loader still pins DEFAULT_BOOTSTRAP_REF")
    if "PinBuild" not in loader:
        fail("loader does not pin content to build.commit")
    if "GB_DEV_MODULAR" not in loader:
        fail("loader missing modular-dev gate")
    if "Stale GB_BASE_URL" not in loader:
        fail("loader must ignore production GB_BASE_URL pins")

    if "pos.Y > 120" not in world:
        fail("travel sky clamp missing")
    if 'perfCount("WorkspaceDeepScan"' in world:
        fail("World still increments WorkspaceDeepScan in normal path")
    if "markContextDirty(\"target_dead\")" not in combat:
        fail("target death does not dirty engine")
    if "hoverFloorY" not in combat:
        fail("hoverFloorY missing")
    if "b:Fire(config)" in remotes:
        fail("DialogueBindable Fire still live")
    if "dialogueChoice" not in remotes:
        fail("Choice remote missing")
    if "alt_condition_pending" not in quest:
        fail("multi-talk still loops all conditions in one tick")
    if "talk not credited" in quest.split("if typ == \"Talk\"", 1)[-1][:900]:
        fail("Talk path still noteFail after one blocked wait")

    resolver = read("Game/Resolver.lua")
    recovery = read("Core/Recovery.lua")
    if "function M.taggedLeaf" not in resolver:
        fail("Resolver.taggedLeaf missing")
    if "function M.isMarkerContainer" not in resolver:
        fail("Resolver.isMarkerContainer missing")
    if "function M.standOn" not in world:
        fail("World.standOn missing")
    if "investigateMarker" not in quest:
        fail("Quest.investigateMarker missing")
    if "refuse container" not in world:
        fail("World must refuse Markers folder travel")
    if "isInteractLike" not in recovery:
        fail("Recovery isInteractLike missing")
    if 'string.sub(typ, 1, 11) == "Investigate"' not in recovery:
        fail("Recovery must skip enemy for Investigate*")
    if "if not curQuest then" not in engine:
        fail("WAIT_DATA must not fire while a live quest is cached")
    if 'string.sub(typ, 1, 11) == "Investigate"' not in engine:
        fail("scoreActive missing Investigate bias")
    if "function M.findQuestBeam" not in resolver:
        fail("Resolver.findQuestBeam missing")
    if "function M.scanMarkerFolder" not in resolver:
        fail("Resolver.scanMarkerFolder missing")
    if "zone-only" not in quest:
        fail("Investigate must Enter Zone even on marker miss")
    if "INVESTIGATE_ORIGIN" not in read("Game/QuestData.lua"):
        fail("Investigate origin fallback missing")
    if "function M.findHudAdornee" not in resolver:
        fail("Resolver.findHudAdornee missing")
    if "dismiss participate" not in quest:
        fail("Investigate must dismiss participate prompt")
    if "function guiTextOf" not in quest:
        fail("Quest guiTextOf missing")
    if "doLive_error" not in quest:
        fail("doLiveResult must not rethrow into DecisionEngine")
    if 'tostring(d.Text or "")' in quest:
        fail("Quest still reads .Text on possibly-ImageButton")
    if '["Investigate The Footsteps (1)"] = "Black Noir Campsite 1"' not in read("Game/QuestData.lua"):
        fail("Investigate (1) must fall back to Black Noir Campsite 1")
    if "waitTaggedLeaf(tag, 0.8)" in quest:
        fail("Investigate still blocks decide on waitTaggedLeaf")
    if "isInteractLike(o.Type)" not in recovery:
        fail("Recovery still fingerprint-defers Investigate")
    if "function startSessionLog" not in loader:
        fail("loader missing session writefile log")
    if 'GBKaitun/logs/latest.txt' not in loader:
        fail("loader missing latest.txt log path")
    if "_GBKaitunLogWrite" not in read("Core/Logger.lua"):
        fail("Logger must tee suppressed lines to writefile")
    if 'GB.Resolver.enemies("Black Noir Pirate")' in quest:
        fail("Investigate must not teleport onto a pirate")
    if "usableInvestigateDest" not in quest:
        fail("Investigate dest filter missing")
    if '["Journey to Maple Village"] = 70' not in read("Game/QuestData.lua"):
        fail("STORY_DONE_AT must imply Journey done at lv70+")
    if '["Setting Sail"] = 30' not in read("Game/QuestData.lua"):
        fail("STORY_DONE_AT must imply Setting Sail done at lv30+")
    if "function storyPos" not in read("Game/QuestData.lua"):
        fail("impliedFinished missing later-story evidence")
    if "GB.PlayerData._current" not in world:
        fail("islandFromProgress must prefer live quest island")
    if "investigate %s -> %s" not in quest:
        fail("Investigate must travel to quest island when dest is missing")
    if "mapleLive" not in read("Systems/Travel.lua"):
        fail("goIsland must allow Maple when Maple story is live")
    if "function M.findPlace" not in resolver:
        fail("Resolver.findPlace missing")
    if "function M.goPlace" not in world:
        fail("World.goPlace missing")
    if "investigate stream HUD" not in quest:
        fail("Investigate must hop HUD to stream camp")
    if "onWantedIsland" not in quest:
        fail("Investigate must not stream-pull Maple spawn while already there")
    if "GB.World.pullStream(wantIsland)" in quest and "onWantedIsland" not in quest:
        fail("pullStream Maple spawn loop still unguarded")

    if FAILS:
        print("FAIL scenario_tests")
        for row in FAILS:
            print(" ", row)
        return 1
    print("PASS scenario_tests")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
