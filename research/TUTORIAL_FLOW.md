# Tutorial Flow

**Source:** Studio place `118635363908336` — `RS.Modules.QuestInfo.Functions.TutorialFolder` (14 modules) + `TutorialLocal` + `BackpackLocal` + `ScreenShadow`.

Internal ID = module name. Visible text is fallback only.

| StepId | Visible instruction | Trigger | Required action | Completion condition | Relevant GUI | Relevant callback | Related quest | Status |
|---|---|---|---|---|---|---|---|---|
| PunchTraining | (cinematic, no text) | Introduction near dummy | Walk to TrainingDummy tag | Dummy within 8 studs | `Assets.UI.Cinematic` | CollectionService GetTagged TrainingDummy | Introduction | IMPLEMENTED (combat dummy) |
| EquipStrongPunch | Select the 'Strong Punch' skill scroll / Press the button to unlock the skill | Basics EquipSkill | Scroll ImageButton → ConsumeSkillScroll + Skill Equip | Skill equipped / cond 1/1 | EquipStrongPunch / hotbar | Skills.equip | Basics | RUNTIME_VERIFIED |
| CastStrongPunch | (hotbar highlight) | Basics Cast | Click hotbar Strong Punch after overlay dismiss | Cast cond 1/1 | Hotbar ToolFrame | Skills.cast | Basics | RUNTIME_VERIFIED |
| InvestStats | Open the menu / Invest a point in to a stat | Basics Required TotalStatPoints | Topbar Menu → Radar stat ImageButton | StatPoints invested | `TopbarStandard.Holders.Left.Menu` + Radar | StatPoints Invest | Basics | RUNTIME_VERIFIED |
| ForceOpenLogbook | Open the menu / Open the Logbook / Open the Tutorial / Read the first tutorial page | Basics Open Logbook | Menu → Logbook → Tutorial → Controls → OpenLogbookHelp | Open Logbook cond | Logbook UI | QuestEvents.OpenLogbookHelp | Basics | RUNTIME_VERIFIED |
| EquipFlintlock | Open the backpack. / Hold and drag the Flintlock to the weapon slot. / Drop it on the weapon slot. | Gearing Up Equip Flintlock | Open backpack (`BackpackToggle:Fire(true)` / topbar Backpack) then `SaveOrder("Weapon2", key)` | Flintlock Title in Equips.Slots; Equip 0/1→1/1 | `PlayerGui.QuestOverlay` + `TopbarStandard.Holders.Left.Backpack` + `Backpack.BackpackFrame.Scale.Storage` + Equips.Slots.Weapon2 | BackpackLocal OpenStorage + MoveToolToSlot → SaveOrder | Gearing Up | IMPLEMENTED 1.1.2 |
| SellWatch | Ask to sell your goods / Sell the Stolen Watch / Sell it! | Gearing Up Sell | Dialogue sell + SellItem | Sell cond | DialogueUI + SellMenu | Shop.sellNamed | Gearing Up | IMPLEMENTED (quest action = tutorial) |
| UpgradeFlintlock | Select Flintlock / Click Upgrade | First Upgrade Upgrade | Blacksmith FlintlockHolder + UpgradeButton | Upgrade cond | Blacksmith UI | Events.Upgrade | First Upgrade | IMPLEMENTED |
| EquippedWeapon | Select Flintlock / Click Upgrade | First Upgrade (alias sequence) | Same as UpgradeFlintlock | Upgrade cond | Blacksmith UI | ScreenShadow.RunSequence | First Upgrade | IMPLEMENTED |
| SmeltTutorial | Select Copper Bar / Click Craft | First Upgrade Smelt | Crafting Copper Bar + Craft | Smelt cond | Crafting UI | LifeSkills / Craft | First Upgrade | IMPLEMENTED |
| CraftStoneRing | Open your backpack / Select Stone Ring Recipe / Press the button to learn the recipe | Miners Stone Ring | Backpack + consume recipe | Craft cond | Backpack + recipe scroll | Consume path | Miners Stone Ring | PARTIAL |
| UnsheathWeapon | Toggle your weapon | later combat tutorial | ControlsUI.Container.Equip | sheath state | ControlsUI | PressKey / sheath bind | — | UNRESOLVED runtime |
| UpgradeSkill | (button) | skill upgrade tutorial | TutorialEvent FireServer("UpgradeSkill") | TutorialsCompleted | skill UI | TutorialEvent | — | UNRESOLVED |
| Pets | (button) | pet tutorial | TutorialEvent FireServer("Pets") | TutorialsCompleted | Pets UI | TutorialEvent | — | UNRESOLVED |
| Mining | TutorialScreen Mining | first pickaxe equip | TutorialEvent client "Mining" | Data.TutorialsCompleted.Mining | TutorialScreen | TutorialLocal CloseGUI → FireServer | First Upgrade | dismiss overlay only |
| Unlock Skill | PRESS ANYWHERE / Unlock Skill | skill unlock (`TutorialEvent` queue) | `TutorialLocal` `UIS.InputBegan` MouseButton1/Touch/ButtonX after ClickToContinue visible (~0.75s). `ClickToContinue` is **TextLabel**. Last stage `CloseGUI` → `TutorialEvent:FireServer(name)` | `TutorialScreen.Enabled=false` + server TutorialsCompleted | `PlayerGui.TutorialScreen` | `TutorialLocal` InputBegan → AdvanceStage/CloseGUI | Basics / Mining / later tutorials | RUNTIME_VERIFIED ContinueOverlay 1.1.5 |
| SkillObtained | PRESS ANYWHERE TO CONTINUE / Gunshot Active Skill | `Events.PassiveDisplay` → `Queue` → `Notify` (transient **event**, not a persistent tutorial flag) | Wait **3s**, then `UIS.InputBegan`. Accept Touch / MouseButton1 / ButtonX. `gameProcessed=true` returns unless ButtonX. `ContinueButton` is **TextLabel Active=false**. No GuiButton. | Handler: Debris CantAttack, `Event:Fire(true)`, disconnect, `Enabled=false` + Attribute false, `UI_Utilities.Unhide`, if `ModuleType=="Tool"` then `PromptSkillEquip:FireServer(name)`, `AdvanceQueue` | `PlayerGui.SkillObtained` (`RS.ScreenGuis.SkillObtained`) | `PassiveObtained` InputBegan (invoke connection / ButtonX). **Never hide GUI.** Validate overlay gone. | Gearing Up after Equip Flintlock (Gunshot default ModuleType Tool) | IMPLEMENTED ContinueOverlay 1.1.5 |

## Gate types (1.1.5)

| Type | Example | Execute | Validate |
|---|---|---|---|
| `ContinueOverlay` | SkillObtained / TutorialScreen "PRESS ANYWHERE TO CONTINUE" | Invoke game `UIS.InputBegan` handler (PassiveObtained / TutorialLocal). Do not `Enabled=false` / Destroy. | Overlay `Enabled` + Attribute `Enabled` both false. Release Tutorial owner. Refresh PlayerData + State + Quest + Planner. |
| `ActionRequired` | "Open the backpack." | Perform gameplay/UI action (BackpackToggle, menu click). | Instruction text / backpack open / quest condition changes. |
| `EquipRequired` | Equip Flintlock 0/1 | Open backpack + `SaveOrder` gear slot. HeldItem is not enough. | Flintlock Title under Equips.Slots; Equip 1/1. |
| `Dialogue` | Sell Watch / talk | DialogueUI click path. | DialogueUI.Enabled false or quest stage change. |
| `UISelection` | Skill scroll unlock | Click the verified ImageButton. | Scroll consumed / skill owned. |
| `InputRequired` | Unsheath / Dash / Block | PressKey / ControlsUI bind. | Game state flag. |

SkillObtained is an **event-spawned overlay**. There is no server tutorial completion flag to wait on. Completion = `Notify` InputBegan ran and `AdvanceQueue` finished.

## SkillObtained / Gunshot — verified implementation

GUI: `PlayerGui.SkillObtained` cloned from `RS.ScreenGuis.SkillObtained`.

| Object | Class | Role |
|---|---|---|
| SkillObtained | ScreenGui | `Enabled` + Attribute `Enabled` |
| Frame.SkillName | TextLabel | payload (e.g. Gunshot) |
| Frame.Header | TextLabel | "Active Skill" |
| Frame.Description | TextLabel | skill description |
| Frame.ContinueButton | TextLabel | "PRESS ANYWHERE TO CONTINUE" — **not a button**, `Active=false` |
| PassiveObtained | LocalScript | owner of continuation |
| Visuals | LocalScript | listens `Event` BindableEvent for FX only |
| Event | BindableEvent | visuals; `Fire(true)` is close FX, not completion |

`Gunshot` (`RS.Modules.SkillInformation.Skills.Gun.Gunshot`) does not set `ModuleType`. Default from `SkillInfoUtilities.ReturnDefaultTable` is **`Tool`**. The real InputBegan handler therefore fires `PromptSkillEquip:FireServer("Gunshot")`. Invoking that remote without the handler skips Unhide / CantAttack Debris / AdvanceQueue.

Old dismiss (`firesignal` / `Enabled=false`) hid or claimed success without running the handler. Card stayed, or listener stayed armed.

## Other continue overlays (Studio)

| Overlay | Continuation | Notes |
|---|---|---|
| `TutorialScreen` | Same InputBegan rule; `ClickToContinue` TextLabel; multi-stage then `TutorialEvent:FireServer` | `WaitForClear` waits for SkillObtained first |
| `QuestOverlay` / `ScreenShadow` | **ActionRequired**, not continue | "Open the backpack." etc. |
| `DialogueUI` | Dialogue buttons | not press-anywhere |
| No `ItemObtained` ScreenGui | — | not present in this place |

## Gearing Up Equip — runtime evidence (1.1.2)

## Gearing Up Equip — runtime evidence (1.1.2)

QuestInfo:

```
CreateCondition(stage, "Equip", "Flintlock")
CreateFunction(cond, "Client", "EquipFlintlock")
```

`EquipFlintlock.Init` does **not** credit the quest. It only coaches the player:

1. Wait `ClientCache.Data.Inventory` has Name==Flintlock
2. While not `IsEquipped` (Flintlock Title under Equips.Slots):
   - Storage.Visible == false → highlight `TopbarStandard.Holders.Left.Backpack`, message **"Open the backpack."**
   - Storage open, not dragging → highlight Flintlock frame + Weapon2, **"Hold and drag the Flintlock to the weapon slot."**
   - Dragging → **"Drop it on the weapon slot."**
3. Complete when Flintlock appears in Equips.Slots

`HeldItem:FireServer("Equip", key)` only holds the tool (hotbar). Server Equip quest watches **gear slot** (`SaveOrder`), so 0/1 stays 0/1.

Verified client bind: `BackpackLocal.MoveToolToSlot` → `Events.SaveOrder:FireServer(slot, key)`.

Open backpack: `Events.BackpackToggle:Fire(true)` selects the TopbarPlus icon → `OpenStorage()` (`Storage.Visible = true`).
