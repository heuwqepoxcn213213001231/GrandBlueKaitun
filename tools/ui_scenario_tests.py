#!/usr/bin/env python3
"""Static UI contract checks plus deterministic controller behavior models.

These tests do not pretend to execute Roblox.  The model catches ownership and
cancellation regressions deterministically; source checks bind those scenarios
to the Luau implementation.  Runtime-only coverage is printed explicitly.
"""

from __future__ import annotations

import re
import shutil
import subprocess
from dataclasses import dataclass, field
from pathlib import Path
from typing import Callable, Iterable, Optional


ROOT = Path(__file__).resolve().parents[1]
CONTROLLER_PATH = ROOT / "UI" / "ManualController.lua"
HUB_PATH = ROOT / "UI" / "Hub.lua"
NIA_PATH = ROOT / "UI" / "NiaInline.lua"
CATALOG_PATH = ROOT / "UI" / "Catalog.lua"
EXTENSIONS_PATH = ROOT / "UI" / "RuntimeExtensions.lua"
RESOLVER_PATH = ROOT / "UI" / "Resolver.lua"
MATRIX_PATH = ROOT / "research" / "UI_FEATURE_MATRIX.md"
GENERATED_PATH = ROOT / "kaitun_ui.lua"
LUAU_SPEC_PATH = ROOT / "tools" / "ui_controller_spec.luau"
SAVE_PATH = "GBKaitun/UIConfig.json"

OWNERS = {
    "IDLE",
    "FULL_AUTO",
    "MANUAL_QUEST",
    "MANUAL_MOB",
    "MANUAL_BOSS",
    "MANUAL_CHEST",
}
MOB_MODES = ("NEAREST", "ROUND_ROBIN", "FINISH_GROUP", "PRIORITY")
REPEAT_MODES = ("ONE", "ROTATE", "BEST", "NEAREST")

RUNTIME_REQUIRED = (
    "Roblox GUI layout, resize, touch, keyboard, and popup focus behavior",
    "live quest accept/progress/turn-in remotes and repeatable reward timing",
    "enemy, boss, NPC, marker, chest, inventory, shop, and skill resolver data",
    "combat lock ownership and movement cancellation against streamed instances",
    "death-screen interaction, character replacement, and post-respawn restoration",
    "executor filesystem permissions and JSON persistence round-trip",
    "teleport requeue execution in the destination server",
    "code redemption feedback, throttling, and already-used responses",
)


@dataclass
class Result:
    name: str
    passed: bool
    detail: str


class Suite:
    def __init__(self) -> None:
        self.results: list[Result] = []

    def check(self, name: str, condition: bool, detail: str) -> None:
        self.results.append(Result(name, bool(condition), detail))

    def case(self, name: str, callback: Callable[[], None]) -> None:
        try:
            callback()
        except AssertionError as exc:
            self.results.append(Result(name, False, str(exc) or "assertion failed"))
        except Exception as exc:  # deterministic tests should report, not traceback
            self.results.append(Result(name, False, f"{type(exc).__name__}: {exc}"))
        else:
            self.results.append(Result(name, True, "deterministic model"))

    def finish(self) -> int:
        passed = sum(result.passed for result in self.results)
        failed = len(self.results) - passed
        for result in self.results:
            state = "PASS" if result.passed else "FAIL"
            print(f"[{state}] {result.name}: {result.detail}")
        print("[RUNTIME REQUIRED]")
        for item in RUNTIME_REQUIRED:
            print(f"  - {item}")
        print(f"[SUMMARY] pass={passed} fail={failed} runtime_required={len(RUNTIME_REQUIRED)}")
        print("PASS ui_scenario_tests" if failed == 0 else "FAIL ui_scenario_tests")
        return 0 if failed == 0 else 1


def unique(values: Iterable[str]) -> list[str]:
    output: list[str] = []
    seen: set[str] = set()
    for raw in values:
        value = str(raw).strip()
        key = value.lower()
        if value and key not in seen:
            seen.add(key)
            output.append(value)
    return output


@dataclass
class ControllerModel:
    owner: str = "IDLE"
    paused: bool = False
    generation: int = 1
    selected_mobs: list[str] = field(default_factory=list)
    mob_mode: str = "NEAREST"
    mob_target: Optional[str] = None
    selected_quest: Optional[str] = None
    repeatables: list[str] = field(default_factory=list)
    repeat_mode: str = "ONE"
    repeat_active: Optional[str] = None
    repeat_had_live: bool = False
    repeat_cycles: int = 0
    chest_target: Optional[str] = None
    opened_chests: list[str] = field(default_factory=list)
    queue: list[str] = field(default_factory=list)
    status: str = "IDLE"
    cancel_count: int = 0
    destroyed: bool = False
    respawn_held: bool = False

    def invalidate(self, reason: str) -> None:
        self.generation += 1
        self.mob_target = None
        self.chest_target = None
        self.queue.clear()
        self.cancel_count += 1
        self.status = reason

    def set_owner(self, owner: str, reason: str = "owner") -> None:
        assert owner in OWNERS
        self.invalidate(reason)
        self.owner = owner
        self.paused = False
        self.status = "IDLE" if owner == "IDLE" else "READY"

    def stop(self, reason: str = "stopped") -> None:
        self.set_owner("IDLE", reason)

    def set_mobs(self, values: Iterable[str]) -> None:
        next_values = unique(values)
        if next_values != self.selected_mobs:
            self.selected_mobs = next_values
            if self.owner == "MANUAL_MOB":
                self.invalidate("selected_mobs")

    def set_mob_mode(self, mode: str) -> None:
        assert mode in MOB_MODES
        if mode != self.mob_mode:
            self.mob_mode = mode
            if self.owner == "MANUAL_MOB":
                self.invalidate("mob_mode")

    def toggle_mob(self, enabled: bool) -> None:
        if enabled:
            assert self.selected_mobs
            self.set_owner("MANUAL_MOB", "mob_toggle_on")
        else:
            self.stop("mob_toggle_off")

    def choose_mob(self, distances: dict[str, float]) -> Optional[str]:
        candidates = [name for name in self.selected_mobs if name in distances]
        if not candidates:
            self.mob_target = None
            return None
        if self.mob_mode == "PRIORITY":
            selected = candidates[0]
        elif self.mob_mode in {"ROUND_ROBIN", "FINISH_GROUP"}:
            selected = self.mob_target if self.mob_target in candidates else candidates[0]
        else:
            selected = min(
                enumerate(candidates),
                key=lambda row: (distances[row[1]], row[0], row[1]),
            )[1]
        self.mob_target = selected
        return selected

    def set_quest(self, quest: Optional[str]) -> None:
        quest = str(quest).strip() if quest else None
        if quest != self.selected_quest:
            self.selected_quest = quest
            if self.owner == "MANUAL_QUEST":
                self.invalidate("selected_quest")
            self.repeat_active = None
            self.repeat_had_live = False

    def set_repeatables(self, values: Iterable[str]) -> None:
        self.repeatables = unique(values)
        if self.repeat_active not in self.repeatables:
            self.repeat_active = None
            self.repeat_had_live = False

    def select_repeat(self, live: set[str]) -> Optional[str]:
        choices = list(self.repeatables)
        if self.selected_quest and self.selected_quest not in choices:
            choices.insert(0, self.selected_quest)
        if self.repeat_active:
            if self.repeat_active in live:
                self.repeat_had_live = True
                return self.repeat_active
            if self.repeat_had_live:
                self.repeat_cycles += 1
                self.repeat_had_live = False
                self.repeat_active = None
            else:
                return self.repeat_active
        if not choices:
            return None
        selected = self.selected_quest if self.selected_quest in choices else choices[0]
        self.repeat_active = selected
        if selected in live:
            self.repeat_had_live = True
        return selected

    def chest_tick(self, unopened: Iterable[str]) -> Optional[str]:
        assert self.owner == "MANUAL_CHEST"
        available = [name for name in unopened if name not in self.opened_chests]
        if self.chest_target not in available:
            self.chest_target = available[0] if available else None
        if not self.chest_target:
            self.stop("chests_exhausted")
            return None
        opened = self.chest_target
        self.opened_chests.append(opened)
        self.chest_target = None
        return opened

    def on_death_tick(self, busy: bool) -> None:
        if busy:
            if not self.respawn_held:
                self.invalidate("respawn")
                self.respawn_held = True
            self.status = "WAIT_RESPAWN"
            return
        if self.respawn_held:
            self.respawn_held = False
            self.status = "RESUMING"

    def destroy(self) -> None:
        if self.destroyed:
            return
        self.invalidate("destroyed")
        self.owner = "IDLE"
        self.paused = True
        self.destroyed = True


@dataclass
class HubModel:
    controller: ControllerModel
    controls: dict[str, object] = field(default_factory=dict)
    saved: dict[str, object] = field(default_factory=dict)
    destroyed: bool = False

    def change_dropdown(self, name: str, value: object) -> None:
        self.controls[name] = value
        if name == "mobs":
            self.controller.set_mobs(value if isinstance(value, list) else [str(value)])
        elif name == "quest":
            self.controller.set_quest(str(value) if value else None)

    def toggle(self, name: str, enabled: bool) -> None:
        self.controls[name] = enabled
        if name == "mob_farm":
            self.controller.toggle_mob(enabled)
        elif name == "full_auto":
            self.controller.set_owner("FULL_AUTO", "full_auto_on") if enabled else self.controller.stop("full_auto_off")

    def save(self) -> dict[str, object]:
        self.saved = {
            "mobs": list(self.controller.selected_mobs),
            "mob_mode": self.controller.mob_mode,
            "quest": self.controller.selected_quest,
            "ResumeActions": False,
        }
        return dict(self.saved)

    def destroy(self) -> None:
        self.destroyed = True


def assert_mob_toggle() -> None:
    controller = ControllerModel()
    controller.set_mobs(["Bandit", "Marine", "Bandit"])
    hub = HubModel(controller)
    hub.toggle("mob_farm", True)
    assert controller.owner == "MANUAL_MOB"
    assert controller.selected_mobs == ["Bandit", "Marine"]
    hub.toggle("mob_farm", False)
    assert controller.owner == "IDLE"
    assert controller.mob_target is None


def assert_selection_invalidates_target() -> None:
    controller = ControllerModel(owner="MANUAL_MOB", selected_mobs=["Bandit"], mob_target="Bandit")
    generation = controller.generation
    controller.set_mobs(["Marine"])
    assert controller.mob_target is None
    assert controller.generation == generation + 1
    assert controller.cancel_count == 1


def assert_all_mob_modes() -> None:
    distances = {"A": 9.0, "B": 2.0}
    expected = {
        "NEAREST": "B",
        "ROUND_ROBIN": "A",
        "FINISH_GROUP": "A",
        "PRIORITY": "A",
    }
    for mode in MOB_MODES:
        controller = ControllerModel(selected_mobs=["A", "B"])
        controller.set_mob_mode(mode)
        assert controller.choose_mob(distances) == expected[mode]


def assert_repeat_start_and_cycle() -> None:
    controller = ControllerModel(
        owner="MANUAL_QUEST",
        selected_quest="Daily A",
        repeatables=["Daily A", "Daily B"],
    )
    assert controller.select_repeat(set()) == "Daily A"
    assert controller.repeat_active == "Daily A"
    assert controller.select_repeat({"Daily A"}) == "Daily A"
    assert controller.repeat_had_live
    assert controller.select_repeat(set()) == "Daily A"
    assert controller.repeat_cycles == 1
    assert controller.repeat_active == "Daily A"


def assert_quest_switching() -> None:
    controller = ControllerModel(owner="MANUAL_QUEST", selected_quest="Quest A", repeat_active="Quest A")
    generation = controller.generation
    controller.set_quest("Quest B")
    assert controller.selected_quest == "Quest B"
    assert controller.repeat_active is None
    assert controller.generation == generation + 1


def assert_chest_one_at_a_time() -> None:
    controller = ControllerModel(owner="MANUAL_CHEST")
    first = controller.chest_tick(["Chest 1", "Chest 2"])
    assert first == "Chest 1"
    assert controller.opened_chests == ["Chest 1"]
    assert controller.chest_target is None
    controller.stop("cancel")
    assert controller.owner == "IDLE"
    assert controller.chest_target is None


def assert_death_resume() -> None:
    controller = ControllerModel(owner="MANUAL_MOB", selected_mobs=["Bandit"], mob_target="Bandit")
    controller.on_death_tick(True)
    assert controller.owner == "MANUAL_MOB"
    assert controller.status == "WAIT_RESPAWN"
    assert controller.mob_target is None
    controller.on_death_tick(False)
    assert controller.owner == "MANUAL_MOB"
    assert controller.status == "RESUMING"


def assert_manual_full_auto_conflict() -> None:
    controller = ControllerModel(
        owner="MANUAL_MOB",
        selected_mobs=["Bandit"],
        mob_target="Bandit",
        queue=["redeem"],
    )
    generation = controller.generation
    controller.set_owner("FULL_AUTO", "master_toggle")
    assert controller.owner == "FULL_AUTO"
    assert controller.mob_target is None
    assert controller.queue == []
    assert controller.generation == generation + 1


def assert_reload_cleanup() -> None:
    old = ControllerModel(owner="MANUAL_QUEST", queue=["action"])
    hub = HubModel(old)
    hub.destroy()
    old.destroy()
    assert hub.destroyed
    assert old.destroyed and old.owner == "IDLE" and old.queue == []
    old.destroy()
    assert old.owner == "IDLE"


def assert_dropdown_changes_and_safe_save() -> None:
    controller = ControllerModel(owner="MANUAL_MOB", selected_mobs=["A"], mob_target="A")
    hub = HubModel(controller)
    hub.change_dropdown("mobs", ["B", "C"])
    assert controller.selected_mobs == ["B", "C"]
    assert controller.mob_target is None
    hub.change_dropdown("quest", "Quest B")
    assert controller.selected_quest == "Quest B"
    saved = hub.save()
    assert saved["ResumeActions"] is False
    assert "owner" not in saved


def read_source(path: Path, suite: Suite, label: str) -> str:
    if not path.is_file():
        suite.check(f"files.{label}", False, f"missing {path.relative_to(ROOT)}")
        return ""
    try:
        source = path.read_text(encoding="utf-8")
    except (OSError, UnicodeError) as exc:
        suite.check(f"files.{label}", False, str(exc))
        return ""
    suite.check(f"files.{label}", True, f"{len(source.splitlines())} lines")
    return source


def has_all(source: str, markers: Iterable[str]) -> bool:
    return all(marker in source for marker in markers)


def has_any(source: str, markers: Iterable[str]) -> bool:
    return any(marker in source for marker in markers)


def long_waits(source: str) -> list[float]:
    waits: list[float] = []
    for match in re.finditer(r"task\.wait\s*\(\s*([0-9]+(?:\.[0-9]+)?)\s*\)", source):
        value = float(match.group(1))
        if value > 0.35 + 1e-9:
            waits.append(value)
    return waits


def hidden_loop_issues(source: str, label: str) -> list[str]:
    issues: list[str] = []
    if re.search(r"\bwhile\s+true\s+do\b", source):
        issues.append(f"{label}: while true")
    if label == "ManualController" and re.search(r"task\.(?:spawn|defer|delay)\s*\(", source):
        issues.append("ManualController: hidden task scheduling")
    if label == "Hub":
        for spawn in re.finditer(r"task\.spawn\s*\(\s*function", source):
            window = source[spawn.start() : min(len(source), spawn.start() + 1800)]
            for loop in re.finditer(r"\bwhile\b[^\n]*\bdo\b", window):
                loop_window = window[max(0, loop.start() - 180) : loop.end() + 420]
                bounded = has_any(
                    loop_window,
                    (
                        "_destroyed",
                        "_generation",
                        "refreshToken",
                        "statusToken",
                        "GB.dead",
                        "os.clock() -",
                    ),
                )
                if not bounded:
                    issues.append(f"Hub: unguarded spawned loop near offset {spawn.start() + loop.start()}")
    return issues


def button_labels(source: str) -> list[str]:
    labels: list[str] = []
    for match in re.finditer(r":AddButton\s*\(\s*\{", source):
        block = source[match.start() : match.start() + 700]
        text = re.search(r"\bText\s*=\s*([\"'])(.*?)\1", block, re.S)
        if text:
            labels.append(text.group(2))
    return labels


def source_between(generated: str, rel: str) -> str:
    begin = f"-- BEGIN SOURCE: {rel}"
    end = f"-- END SOURCE: {rel}"
    start = generated.find(begin)
    finish = generated.find(end, start + len(begin)) if start >= 0 else -1
    if start < 0 or finish < 0:
        return ""
    return generated[start + len(begin) : finish]


def static_checks(
    suite: Suite,
    controller: str,
    hub: str,
    nia: str,
    generated: str,
) -> None:
    catalog = CATALOG_PATH.read_text(encoding="utf-8") if CATALOG_PATH.is_file() else ""
    extensions = EXTENSIONS_PATH.read_text(encoding="utf-8") if EXTENSIONS_PATH.is_file() else ""
    resolver = RESOLVER_PATH.read_text(encoding="utf-8") if RESOLVER_PATH.is_file() else ""
    matrix = MATRIX_PATH.read_text(encoding="utf-8") if MATRIX_PATH.is_file() else ""
    ui_source = "\n".join((nia, controller, catalog, extensions, hub))
    forbidden_patterns = {
        "Chest.lootUntil": r"\b(?:GB\.)?Chest\.lootUntil\b",
        "Workspace:GetDescendants": r"\b(?:Workspace|workspace):GetDescendants\s*\(",
        "direct CFrame assignment": r"(?:\.\s*|\b)CFrame\s*=",
        "BeginQuest": r"\bBeginQuest\b",
        "LoadCharacter": r"\bLoadCharacter\b",
        "project HttpGet": r"\bHttpGet\b",
    }
    for label, pattern in forbidden_patterns.items():
        suite.check(
            f"static.forbidden.{label}",
            re.search(pattern, ui_source) is None,
            "absent" if re.search(pattern, ui_source) is None else "forbidden reference found",
        )
    waits = long_waits(ui_source)
    suite.check(
        "static.forbidden.long_task_wait",
        not waits,
        "none" if not waits else f"waits over 0.35s: {waits}",
    )

    issues = hidden_loop_issues(controller, "ManualController") + hidden_loop_issues(hub, "Hub")
    suite.check(
        "static.no_hidden_loops",
        not issues,
        "bounded status loop only" if not issues else "; ".join(issues),
    )

    suite.check(
        "static.controller.owner_contract",
        has_all(controller, OWNERS),
        "all six owners present",
    )
    suite.check(
        "static.controller.mob_modes",
        has_all(controller, MOB_MODES)
        and has_all(controller, ("setSelectedMobs", "setMobMode", "chooseMob", "releaseMobTarget")),
        "NEAREST/ROUND_ROBIN/FINISH_GROUP/PRIORITY",
    )
    suite.check(
        "static.controller.selection_cancels_target",
        has_all(controller, ('selectionChanged("selected_mobs"', "invalidateWork", "_mobActiveInstance = nil")),
        "mob selection invalidates generation and target",
    )
    suite.check(
        "static.controller.repeatable_start",
        has_all(controller, ("selectedRepeatables", "selectedQuest", "chooseRepeat", "GB.Quest.doLiveResult")),
        "selected repeatable drives doLiveResult",
    )
    suite.check(
        "static.controller.repeat_cycle_reaccept",
        has_all(controller, ("_repeatHadLive", "_repeatCycles", "_repeatActive = nil", "M._repeatActive = selected")),
        "completion clears active selection for next-tick reaccept",
    )
    suite.check(
        "static.controller.quest_switching",
        has_all(controller, ('selectionChanged("selected_quest"', "setSelectedQuest", "MANUAL_QUEST")),
        "quest dropdown mutation cancels active manual quest work",
    )
    suite.check(
        "static.controller.chest_one_per_tick",
        has_all(controller, ("nearestChest", "_chestTarget", "GB.Chest.openOne", "CHESTS_EXHAUSTED"))
        and "Chest.lootUntil" not in controller,
        "single openOne route with exhaustion/cancel state",
    )
    suite.check(
        "static.controller.death_resume",
        has_all(controller, ("holdForRespawn", "_respawnHeld", "WAIT_RESPAWN", "RESUMING")),
        "owner survives respawn hold",
    )
    suite.check(
        "static.controller.conflict_cancellation",
        has_all(controller, ("setOwner", "invalidateWork", "clearQueue", "cancelRuntime", "FULL_AUTO")),
        "owner transition cancels manual work atomically",
    )
    suite.check(
        "static.controller.boss_once_nonblocking",
        has_all(controller, ("setBossKillLimit", "BOSS_LIMIT_REACHED", "recordBossKill"))
        and "huntUntilDead" not in hub,
        "single-boss action uses owner ticks, not a blocking kill loop",
    )
    suite.check(
        "static.controller.safe_utilities_consumed",
        has_all(controller, ("setUtilityAuto", "runUtilities", "GB.Stats.tick()", "GB.Codes.tick()")),
        "AutoStats/AutoCodes are consumed outside FULL_AUTO",
    )
    suite.check(
        "static.controller.async_cancellable_work",
        has_all(
            controller,
            (
                "dispatchWork",
                "cancelActiveWork",
                "coroutine.create",
                "workTask",
                "SendMouseButtonEvent",
            ),
        ),
        "manual and queued work runs outside the sequential scheduler step",
    )
    suite.check(
        "static.controller.stickiness_consumed",
        has_all(
            controller,
            (
                "setTargetStickiness",
                "setTargetSwitchDistance",
                "_mobLockedAt",
                "M.targetSwitchDistance",
            ),
        ),
        "stickiness and switch distance affect live target retention",
    )

    suite.check(
        "static.hub.contract",
        hub.startswith("return function(GB)")
        and has_all(
            hub,
            (
                "Window",
                "Controls",
                "Refresh",
                "SaveConfig",
                "LoadConfig",
                "ResetConfig",
                "Notify",
                "Destroy",
            ),
        ),
        "factory and public Hub API",
    )
    suite.check(
        "static.hub.redeem_all_manual",
        has_all(hub, ("Codes-Rewards", "enqueue"))
        and has_any(hub, ("Redeem All", "Redeem all", "redeemAll"))
        and has_any(hub, ("Manual Code", "Manual code", "manualCode", "codeTextbox"))
        and has_any(hub, ("GB.Codes.redeem", "GB.Remotes.code", "Codes.redeem")),
        "selected/all/manual redemption uses queued real APIs",
    )
    suite.check(
        "static.hub.map_npc_teleport",
        has_all(hub, ("Teleport", "NPC"))
        and has_any(hub, ("GB.Travel.goIsland", "Travel.goIsland"))
        and has_any(hub, ("resolveNPC", "GB.Resolver.npc"))
        and has_any(hub, ("GB.World.moveTo", "World.moveTo")),
        "map and NPC routes use Travel/Resolver/World",
    )
    suite.check(
        "static.hub.toggle_off",
        has_any(hub, ("mob_toggle_off", "full_auto_off", "toggle_off", "Controller:stop", "Controller.stop"))
        or (
            re.search(r"if\s+enabled\s+then", hub) is not None
            and re.search(r"\b(?:controller|Controller|C):(?:stop|setOwner)\b", hub) is not None
        ),
        "OFF branch returns controller to IDLE",
    )
    suite.check(
        "static.hub.dropdown_changes",
        has_all(hub, ("AddDropdown", "SetOptions"))
        and has_any(hub, ("setSelectedMobs", "setMobs"))
        and has_any(hub, ("setSelectedQuest", "setQuest")),
        "refreshable dropdowns update controller selections",
    )
    suite.check(
        "static.hub.status_0_33_seconds",
        re.search(r"(?:STATUS_[A-Z_]*|task\.wait)\s*(?:=|\()\s*0\.33\b", hub) is not None,
        "0.33-second refresh (~3 Hz)",
    )
    suite.check(
        "static.hub.exact_save_path",
        SAVE_PATH in hub,
        SAVE_PATH,
    )
    suite.check(
        "static.hub.safe_resume_policy",
        "ResumeActions" in hub and has_any(hub, ("false", "== true")),
        "dangerous owner is not restored by default",
    )
    suite.check(
        "static.hub.stop_all_stops_utilities",
        has_all(
            hub,
            (
                "ui_home_stop_all",
                'setUtilityAuto", "AutoStats", false',
                'setUtilityAuto", "AutoCodes", false',
                "GB.Codes.stop",
            ),
        ),
        "Stop All disables owner, utility autos, and code queue",
    )
    suite.check(
        "static.hub.stopped_status_is_cache_only",
        has_all(hub, ("if Config.Enabled == false then", 'runStatus("Stopped", updateStoppedStatus)')),
        "stopped UI skips live status/cache refresh paths",
    )
    suite.check(
        "static.hub.single_code_listener",
        "OnClientEvent" not in hub
        and has_all(hub, ("GB.Codes.onResult", "GB.Codes.redeemAll", "GB.Codes.redeem")),
        "Codes runtime exclusively owns feedback and dequeue",
    )
    suite.check(
        "static.hub.production_catalog_filters",
        has_all(hub, ("skipQuest", "storyMembership", 'npcName ~= "\\\\"', 'Options = { "CURRENT", "Anchor Town" }')),
        "actionable story/repeatable/NPC/chest lists exclude invalid entries",
    )
    suite.check(
        "static.hub.close_stops_owner",
        has_all(
            hub,
            (
                "function M.Destroy",
                'quiesce("ui_destroy")',
                "GB.World.cancelTween",
                "GB.Scheduler.stop",
                "local stop = GB.Stop",
            ),
        ),
        "window destroy fully quiesces runtime and invokes wrapped lifecycle",
    )
    suite.check(
        "static.hub.explicit_rerolls",
        has_all(
            hub,
            (
                "Confirm Next Reroll",
                "Request Aura Color Reroll",
                "Request Trait Slot Reroll",
                "rerollConfirm",
            ),
        ),
        "verified rerolls require one-shot confirmation",
    )

    labels = button_labels(hub)
    unresolved_label = re.compile(
        r"\b(?:Dig|Battlepass|Achievement|General Craft|Unlock Haki|"
        r"Reroll (?:Aura|Race|Trait)|Eat Fruit|Replace Fruit|Backpack Upgrade)\b",
        re.I,
    )
    bad_labels = [label for label in labels if unresolved_label.search(label)]
    direct_unresolved = re.search(
        r"\b(?:ClaimAchievement|ShovelHit)\b|"
        r"\bGB\.(?:Treasure\.dig|Haki\.unlock|RaceTrait\.reroll|Backpack\.upgrade)\s*\(",
        hub,
    )
    suite.check(
        "static.hub.unresolved_actions_absent",
        not bad_labels
        and direct_unresolved is None
        and has_any(hub, ('~= "UNKNOWN"', '~= "UNRESOLVED"', "status-only", "Status only", "UNRESOLVED")),
        "no unresolved action buttons"
        if not bad_labels and direct_unresolved is None
        else f"bad labels={bad_labels} direct={bool(direct_unresolved)}",
    )
    suite.check(
        "static.catalog.data_driven_categories",
        has_all(catalog, ("Fruits", "Weapons", "Subweapons", "Hats", "Pickaxes", "FishingRods", "Ores", "Fish", "TreasureMaps", "categoryOf")),
        "studio-backed names are classification-only",
    )
    suite.check(
        "static.resolver.snapshot_refresh_cleanup",
        has_all(resolver, ("function M.enemySnapshot", "function M.refreshIndexes", "function M.stopIndexes", "dropConns")),
        "live mob list and reload cleanup use shallow indexes",
    )
    suite.check(
        "static.codes.manual_all_cleanup",
        has_all(
            extensions,
            (
                "function Codes.redeem(",
                "function Codes.redeemAll",
                "function Codes.summary",
                "function Codes.destroy",
                "Codes._conn:Disconnect",
            ),
        ),
        "manual/all code flow and connection cleanup exist",
    )
    suite.check(
        "static.stats.custom_ratio_consumed",
        has_all(extensions, ("function Stats.setRatio", "function Stats.setBuild", "GB.Config.StatRatio", "largestDeficit")),
        "custom six-stat weights drive validated investment",
    )
    suite.check(
        "static.extensions.ui_only_runtime",
        has_all(
            extensions,
            (
                "function Codes.redeemAll",
                "function Stats.tick",
                "function Boss.list",
                "function Rewards.claim",
                "function Haki.rerollAuraColor",
                "function RaceTrait.rerollTrait",
            ),
        ),
        "UI-only runtime APIs are present without shared-source drift",
    )
    suite.check(
        "static.matrix.release_ready",
        bool(matrix) and "| PLANNED |" not in matrix and "Implementation status" in matrix,
        "feature matrix has no PLANNED rows",
    )

    suite.check(
        "static.generated.single_chunk",
        bool(generated)
        and generated.startswith("--==================================================\n-- GRAND BLUE KAITUN UI")
        and has_all(
            generated,
            (
                "-- BEGIN SOURCE: UI/NiaInline.lua",
                "-- BEGIN SOURCE: UI/ManualController.lua",
                "-- BEGIN SOURCE: UI/Catalog.lua",
                "-- BEGIN SOURCE: UI/Resolver.lua",
                "-- BEGIN SOURCE: UI/RuntimeExtensions.lua",
                "-- BEGIN SOURCE: src/boot.lua",
                "-- BEGIN SOURCE: UI/Hub.lua",
                'GB.Scheduler.remove("engine")',
                "GB.UIController.tick()",
            ),
        ),
        "all UI/runtime sections and scheduler handoff present",
    )
    suite.check(
        "static.generated.reload_cleanup",
        has_all(
            generated,
            (
                "stopPreviousInstances",
                "GB._uiLifecycleWrapped = true",
                "destroyComponent(GB.UIHub",
                "destroyComponent(GB.Nia",
                "destroyComponent(GB.UIController",
                "destroyComponent(GB.UIExtensions",
                "getgenv()._GBKaitunUnload = GB.unload",
            ),
        ),
        "prior instance and wrapped lifecycle cleanup",
    )
    if generated:
        embedded_controller = source_between(generated, "UI/ManualController.lua")
        embedded_hub = source_between(generated, "UI/Hub.lua")
        suite.check(
            "static.generated.current_ui_sources",
            controller.strip() in embedded_controller and hub.strip() in embedded_hub,
            "generated controller/Hub match source",
        )
    else:
        suite.check("static.generated.current_ui_sources", False, "kaitun_ui.lua missing")


def main() -> int:
    suite = Suite()
    controller = read_source(CONTROLLER_PATH, suite, "ManualController")
    hub = read_source(HUB_PATH, suite, "Hub")
    nia = read_source(NIA_PATH, suite, "NiaInline")
    generated = read_source(GENERATED_PATH, suite, "kaitun_ui")

    suite.case("model.toggle_mob_farm_on_off", assert_mob_toggle)
    suite.case("model.selected_mobs_invalidate_target", assert_selection_invalidates_target)
    suite.case("model.all_four_mob_modes", assert_all_mob_modes)
    suite.case("model.selected_repeatable_start_and_reaccept", assert_repeat_start_and_cycle)
    suite.case("model.quest_switching", assert_quest_switching)
    suite.case("model.chest_one_at_a_time_and_cancel", assert_chest_one_at_a_time)
    suite.case("model.death_resume", assert_death_resume)
    suite.case("model.manual_to_full_auto_cancels_conflict", assert_manual_full_auto_conflict)
    suite.case("model.reload_cleanup", assert_reload_cleanup)
    suite.case("model.dropdown_changes_and_safe_save", assert_dropdown_changes_and_safe_save)

    luau = shutil.which("luau")
    if not luau:
        suite.check("luau.controller_spec", False, "luau interpreter unavailable")
    else:
        result = subprocess.run(
            [luau, str(LUAU_SPEC_PATH)],
            cwd=ROOT,
            stdout=subprocess.PIPE,
            stderr=subprocess.STDOUT,
            text=True,
            check=False,
        )
        detail = result.stdout.strip() or f"exit={result.returncode}"
        suite.check("luau.controller_spec", result.returncode == 0, detail)

    static_checks(suite, controller, hub, nia, generated)
    return suite.finish()


if __name__ == "__main__":
    raise SystemExit(main())
