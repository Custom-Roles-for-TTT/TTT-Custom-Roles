---- English language strings

local L = LANG.CreateLanguage("English")

--- General text used in various places
L.hidden = "Hidden"
L.last_words = "Last Words"

L.terrorists = "Terrorists"
L.spectators = "Spectators"

L.traitor = "Traitor"
L.traitors = "Traitors"
L.monster = "Monster"
L.monsters = "Monsters"
L.jester = "Jester"
L.jesters = "Jesters"
L.independent = "Independent"
L.independents = "Independents"
L.innocent = "Innocent"
L.innocents = "Innocents"
L.detective = "Detective"
L.detectives = "Detectives"

L.shoprole = "Shop Role"

--- Round status messages
L.round_minplayers = "Not enough players to start a new round..."
L.round_voting = "Vote in progress, delaying new round by {num} seconds..."
L.round_begintime = "A new round begins in {num} seconds. Prepare yourself."
L.round_selected = "The {role} have been selected."
L.round_started = "The round has begun!"
L.round_restart = "The round has been forced to restart by an admin."

L.round_traitors_one = "{role}, you stand alone."
L.round_traitors_more = "{role}, these are your allies: {names}"

L.win_prevented = "Map was prevented from ending the round."
L.win_showreport = "Let's look at the round report for {num} seconds."
L.win_time = "Time has run out. The {role} win."
L.win_traitor = "The {role} have won!"
L.win_innocent = "The {role} have been defeated!"
L.win_monster = "The monsters have taken over!"
L.win_draw = "Time ran out! It's a draw!"

L.limit_round = "Round limit reached. {mapname} will load soon."
L.limit_time = "Time limit reached. {mapname} will load soon."
L.limit_left = "{num} round(s) or {time} minutes remaining before the map changes to {mapname}."

--- Credit awards
L.credit_all = "{role}, you have been awarded {num} equipment credit(s) for your performance."
L.credit_search = "{role}, you have been awarded {num} equipment credit(s) because {source} searched a body."
L.credit_kill = "You have received {num} credit(s) for killing {role}."

--- Karma
L.karma_dmg_full = "Your Karma is {amount}, so you deal full damage this round!"
L.karma_dmg_other = "Your Karma is {amount}. As a result all damage you deal is reduced by {num}%"

--- Body identification messages
L.body_found = "{finder} found the body of {victim}. They were {role}"
L.body_found_updated = "{finder} has uncovered more information about {victim}. They were {role}"

L.body_confirm = "{finder} confirmed the death of {victim}."

L.body_call = "{player} called {role} to the body of {victim}!"
L.body_call_error = "You must confirm the death of this player before calling {role}!"

L.body_burning = "Ouch! This corpse is on fire!"
L.body_credits = "You found {num} credit(s) on the body!"

--- Menus and windows
L.close = "Close"
L.cancel = "Cancel"

-- For navigation buttons
L.next = "Next"
L.prev = "Previous"

-- Equipment buying menu
L.equip_title = "Equipment"
L.equip_tabtitle = "Order Equipment"

L.equip_status = "Ordering status"
L.equip_cost = "You have {num} credit(s) remaining."
L.equip_help_cost = "Every piece of equipment you buy costs 1 credit."

L.equip_help_carry = "You can only buy things for which you have room."
L.equip_carry = "You can carry this equipment."
L.equip_carry_own = "You are already carrying this item."
L.equip_carry_slot = "You are already carrying a weapon in slot {slot}."

L.equip_help_stock = "Of certain items you can only buy one per round."
L.equip_stock_deny = "This item is no longer in stock."
L.equip_stock_req_deny  = "Another item must be purchased before this becomes available."
L.equip_stock_ok = "This item is in stock."

L.equip_custom = "Custom item added by this server."

L.equip_spec_name = "Name"
L.equip_spec_type = "Type"
L.equip_spec_desc = "Description"

L.equip_confirm = "Buy equipment"

-- Disguiser tab in equipment menu
L.disg_name = "Disguiser"
L.disg_menutitle = "Disguise control"
L.disg_not_owned = "You are not carrying a Disguiser!"
L.disg_enable = "Enable disguise"

L.disg_help1 = "When your disguise is active, your name, health and karma do not show when someone looks at you. In addition, you will be hidden from radar."
L.disg_help2 = "Press Numpad Enter to toggle the disguise without using the menu. You can also bind a different key to 'ttt_toggle_disguise' using the console."

-- Radar tab in equipment menu
L.radar_name = "Radar"
L.radar_menutitle = "Radar control"
L.radar_not_owned = "You are not carrying a Radar!"
L.radar_scan = "Perform scan"
L.radar_auto = "Auto-repeat scan"
L.radar_help = "Scan results show for {num} seconds, after which the Radar will have recharged and can be used again."
L.radar_charging = "Your Radar is still charging!"

-- Transfer tab in equipment menu
L.xfer_name = "Transfer"
L.xfer_menutitle = "Transfer credits"
L.xfer_no_credits = "You have no credits to give!"
L.xfer_send = "Send a credit"
L.xfer_help = "You can only transfer credits to fellow {role} players."

L.xfer_no_recip = "Recipient not valid, credit transfer aborted."
L.xfer_no_credits = "Insufficient credits for transfer."
L.xfer_success = "Credit transfer to {player} completed."
L.xfer_received = "{player} has given you {num} credit."

-- Radio tab in equipment menu
L.radio_name = "Radio"
L.radio_help = "Click a button to make your Radio play that sound."
L.radio_notplaced = "You must place the Radio to play sound on it."

-- Radio soundboard buttons
L.radio_button_scream = "Scream"
L.radio_button_expl = "Explosion"
L.radio_button_pistol = "Pistol shots"
L.radio_button_m16 = "M16 shots"
L.radio_button_deagle = "Deagle shots"
L.radio_button_mac10 = "MAC10 shots"
L.radio_button_shotgun = "Shotgun shots"
L.radio_button_rifle = "Rifle shot"
L.radio_button_huge = "H.U.G.E burst"
L.radio_button_c4 = "C4 beeping"
L.radio_button_burn = "Burning"
L.radio_button_steps = "Footsteps"


-- Intro screen shown after joining
L.intro_help = "If you're new to the game, press F1 for instructions!"

-- Radiocommands/quickchat
L.quick_title = "Quickchat keys"

L.quick_yes = "Yes."
L.quick_no = "No."
L.quick_help = "Help!"
L.quick_imwith = "I'm with {player}."
L.quick_see = "I see {player}."
L.quick_suspect = "{player} acts suspicious."
L.quick_traitor = "{player} is {atraitor}!"
L.quick_inno = "{player} is {aninnocent}."
L.quick_check = "Anyone still alive?"

-- {player} in the quickchat text normally becomes a player nickname, but can
-- also be one of the below.  Keep these lowercase.
L.quick_nobody = "nobody"
L.quick_disg = "someone in disguise"
L.quick_corpse = "an unidentified body"
L.quick_corpse_id = "{player}'s corpse"

--- Body search window
L.search_title = "Body Search Results"
L.search_info = "Information"
L.search_confirm = "Confirm Death"
L.search_call = "Call {role}"
L.search_sample = "Take DNA Sample"
L.search_scan_open = "Open DNA Scanner"

-- Descriptions of pieces of information found
L.search_nick = "This is the body of {player}."
L.search_role = "This person was {role}."
L.search_team = "This person was on the {team} team."
L.search_killer_team = "The killer was on the {team} team."
L.search_killer_team_innocent = "The clumsy execution implies this person\nwas killed by necessity."
L.search_killer_team_traitor = "This person was killed expertly."
L.search_killer_team_independent = "You can tell that the killer was working\nalone... somehow."
L.search_killer_team_monster = "Markings on the body imply that a Monster\nwas responsible."
L.search_killer_team_jester = "The body is covered in... confetti?"

L.search_words = "Something tells you some of this person's last words were: '{lastwords}'"
L.search_armor = "They were wearing nonstandard body armor."
L.search_disg = "They were carrying a device that could hide their identity."
L.search_radar = "They were carrying some sort of radar. It is no longer functioning."
L.search_speed = "Surgically attached to their legs were devices that appeared to make them move faster."
L.search_regen = "You find a device hooked into their veins that seems to cause some sort of increased healing factor. It cannot be removed."
L.search_c4 = "In a pocket you found a note. It states that cutting wire {num} will safely disarm the bomb."

L.search_dmg_crush = "Many of their bones are broken. It seems the impact of a heavy object killed them."
L.search_dmg_bullet = "It is obvious they were shot to death."
L.search_dmg_fall = "They fell to their death."
L.search_dmg_boom = "Their wounds and singed clothes indicate an explosion caused their end."
L.search_dmg_club = "The body is bruised and battered. Clearly they were clubbed to death."
L.search_dmg_drown = "The body shows the telltale signs of drowning."
L.search_dmg_stab = "They were stabbed and cut before quickly bleeding to death."
L.search_dmg_burn = "Smells like roasted terrorist around here..."
L.search_dmg_tele = "It looks like their DNA was scrambled by tachyon emissions!"
L.search_dmg_car = "When this terrorist crossed the road, they were run over by a reckless driver."
L.search_dmg_other = "You cannot find a specific cause of this terrorist's death."

L.search_weapon = "It appears a {weapon} was used to kill them."
L.search_head = "The fatal wound was a headshot. No time to scream."
L.search_time = "They died roughly {time} before you conducted the search."
L.search_dna = "Retrieve a sample of the killer's DNA with a DNA Scanner. The DNA sample will decay roughly {time} from now."

L.search_kills1 = "You found a list of kills that confirms the death of {player}."
L.search_kills2 = "You found a list of kills with these names:"
L.search_eyes = "Using your investigative skills, you identified the last person they saw: {player}. Their killer, or a coincidence?"


-- Scoreboard
L.sb_playing = "You are playing {map} with {version} on..."
L.sb_mapchange = "Map changes in {num} rounds or in {time}"

L.sb_mia = "Missing In Action"
L.sb_confirmed = "Confirmed Dead"
L.sb_investigated = "Investigated"

L.sb_ping = "Ping"
L.sb_deaths = "Deaths"
L.sb_score = "Score"
L.sb_karma = "Karma"
L.sb_role = "Role"

L.sb_info_help = "Search this player's body, and you can review the results here."

L.sb_tag_friend = "FRIEND"
L.sb_tag_susp = "SUSPECT"
L.sb_tag_avoid = "AVOID"
L.sb_tag_kill = "KILL"
L.sb_tag_miss = "MISSING"

--- Help and settings menu (F1)

L.help_title = "Help and Settings"

-- Tabs
L.help_tut = "Tutorial"
L.help_tut_tip = "How TTT works, in just a few steps"
L.help_tut_find_role = "Find my role"

L.help_settings = "Config"
L.help_settings_tip = "Client-side configuration"

L.help_roles = "Roles"
L.help_roles_tip = "Client-side role configuration"

-- Settings
L.set_title_gui = "Interface settings"

L.set_tips = "Show gameplay tips at the bottom of the screen while spectating"

L.set_startpopup = "Start of round info popup duration"
L.set_startpopup_tip = "When the round starts, a small popup appears at the bottom of your screen for a few seconds. Change the time it displays for here."

L.set_cross_opacity = "Ironsight crosshair opacity"
L.set_cross_disable = "Disable crosshair completely"
L.set_minimal_id = "Minimalist Target ID under crosshair (no karma text, hints, etc)"
L.set_healthlabel = "Show health status label on health bar"
L.set_lowsights = "Lower weapon when using ironsights"
L.set_lowsights_tip = "Enable to position the weapon model lower on the screen while using ironsights. This will make it easier to see your target, but it will look less realistic."
L.set_fastsw = "Fast weapon switch"
L.set_fastsw_tip = "Enable to cycle through weapons without having to click again to use weapon. Enable show menu to show switcher menu."
L.set_fastsw_menu = "Enable menu with fast weapon switch"
L.set_fastswmenu_tip = "When fast weapons switch is enabled, the menu switcher menu will popup."
L.set_wswitch = "Disable weapon switch menu auto-closing"
L.set_wswitch_tip = "By default the weapon switcher automatically closes a few seconds after you last scroll. Enable this to make it stay up."
L.set_swselect = "Close menu when weapon selected"
L.set_swselect_tip = "By default the weapon switcher closes when a weapon is selected. Disable this to make it stay up. Ignored when fast switching is enabled."
L.set_cues = "Play sound cue when a round begins or ends"
L.set_msg_cue = "Play sound cue when a notification appears"
L.set_msg_cue_tip = "Whether to play a sound whenever a popup message appears (Popup messages appear in the top right corner when rounds begin/end and when bodies are found/searched)"
L.set_raw_karma = "Show the raw karma value"
L.set_raw_karma_tip = "Shows the raw karma value in the scoreboard instead of the percentage of damage each player deals"
L.set_karma_total_pct = "Show karma as percent of total"
L.set_karma_total_pct_tip = "Shows the karma value in the scoreboard as a percentage of the total karma possible instead of the percentage of damage each player deals"
L.set_color_mode = "Color settings"
L.set_hide_role = "Hide your role in the HUD"
L.set_hide_role_tip = "By default your role will appear in the bottom left of the HUD. Turn this on to prevent screen cheating."
L.set_hide_ammo = "Hide your weapon ammo in the HUD"
L.set_hide_ammo_tip = "By default your weapon ammo will appear in the bottom left of the HUD. Turn this on if you have another addon that does that for you."
L.set_radio_button = "Radio menu button"
L.set_radio_button_tip = "What button to press to open/close the radio menu"
L.set_bypass_culling = "Bypass map culling"
L.set_bypass_culling_tip = "Whether to bypass vis leafs and culling in maps for player icons and highlighting. Disable for performance if you don't care about icons and highlighting lagging behind players sometimes."
L.set_distance_unit = "Distance unit"
L.set_distance_unit_tip = "What distance unit to display. Used for things like radar"
L.set_cheatsheat_hotkey = "Cheat sheet hotkey"
L.set_cheatsheat_hotkey_tip = "What button to hold to open the cheat sheet"

L.set_title_play = "Gameplay settings"

L.set_specmode = "Spectate-only mode (always stay spectator)"
L.set_specmode_tip = "Spectate-only mode will prevent you from respawning when a new round starts, instead you stay Spectator."
L.set_mute = "Mute living players when dead"
L.set_mute_tip = "Enable to mute living players while you are dead/spectator."

L.set_title_lang = "Language settings"

-- It may be best to leave this next one english, so english players can always
-- find the language setting even if it's set to a language they don't know.
L.set_lang = "Select language:"


--- Weapons and equipment, HUD and messages

-- Equipment actions, like buying and dropping
L.buy_no_stock = "This weapon is out of stock: you already bought it this round."
L.buy_pending = "You already have an order pending, wait until you receive it."
L.buy_received = "You have received your special equipment."
L.buy_received_delay = "You will receive your special equipment when you activate."
L.buy_favorite_toggle = "Toggle favorite"
L.buy_random = "Buy random equipment"

L.drop_no_room = "You have no room here to drop your weapon!"

L.disg_turned_on = "Disguise enabled!"
L.disg_turned_off = "Disguise disabled."

-- Equipment item descriptions
L.item_passive = "Passive effect item"
L.item_active = "Active use item"
L.item_weapon = "Weapon"

L.item_armor = "Body Armor"
L.item_armor_desc = [[
Reduces bullet damage by 30% when
you get hit.

Default equipment for Detectives.]]

L.item_radar = "Radar"
L.item_radar_desc = [[
Allows you to scan for life signs.

Starts automatic scans as soon as you
buy it. Configure it in Radar tab of this
menu.]]

L.item_disg = "Disguiser"
L.item_disg_desc = [[
Hides your ID info while on. Also avoids
being the person last seen by a victim.

Toggle in the Disguise tab of this menu
or press Numpad Enter.]]

L.item_speed = "Speed Boost"
L.item_speed_desc = [[
Increases the speed boost given while
holding claws from 35% to 50%.]]

L.item_regen = "Regeneration"
L.item_regen_desc = [[
Passively regenerate health at a
rate of 1.5 HP every second.]]

-- C4
L.c4_hint = "Press {usekey} to arm or disarm."
L.c4_no_disarm = "You cannot disarm another {traitor}'s C4 unless they are dead."
L.c4_disarm_warn = "A C4 explosive you planted has been disarmed."
L.c4_armed = "You have successfully armed the bomb."
L.c4_disarmed = "You have successfully disarmed the bomb."
L.c4_no_room = "You cannot carry this C4."

L.c4_desc = "Powerful timed explosive."

L.c4_arm = "Arm C4"
L.c4_arm_timer = "Timer"
L.c4_arm_seconds = "Seconds until detonation:"
L.c4_arm_attempts = "In disarm attempts, {num} of the 6 wires will cause instant detonation when cut."

L.c4_remove_title = "Removal"
L.c4_remove_pickup = "Pick up C4"
L.c4_remove_destroy1 = "Destroy C4"
L.c4_remove_destroy2 = "Confirm: destroy"

L.c4_disarm = "Disarm C4"
L.c4_disarm_cut = "Click to cut wire {num}"

L.c4_disarm_t = "Cut a wire to disarm the bomb. As you are {traitor}, every wire is safe. {innocent} don't have it so easy!"
L.c4_disarm_owned = "Cut a wire to disarm the bomb. It's your bomb, so every wire will disarm it."
L.c4_disarm_other = "Cut a safe wire to disarm the bomb. It will explode if you get it wrong!"

L.c4_status_armed = "ARMED"
L.c4_status_disarmed = "DISARMED"

-- Visualizer
L.vis_name = "Visualizer"
L.vis_hint = "Press {usekey} to pick up ({detective} only)."

L.vis_help_pri = "{primaryfire} drops the activated device."

L.vis_desc = [[
Crime scene visualization device.

Analyzes a corpse to show how
the victim was killed, but only if
they died of gunshot wounds.]]

-- Decoy
L.decoy_name = "Decoy"
L.decoy_no_room = "You cannot carry this decoy."
L.decoy_broken = "Your Decoy has been destroyed!"

L.decoy_help_pri = "{primaryfire} plants the Decoy."

L.decoy_desc = [[
Shows a fake radar sign to {detective},
and makes their DNA scanner show the
location of the Decoy if they scan for
your DNA.]]

-- Defuser
L.defuser_name = "Defuser"
L.defuser_help = "{primaryfire} defuses targeted C4."

L.defuser_desc = [[
Instantly defuse a C4 explosive.

Unlimited uses. C4 will be easier to
notice if you carry this.]]

-- Flare gun
L.flare_name = "Flare gun"
L.flare_desc = [[
Can be used to burn corpses so that
they are never found. Limited ammo.

Burning a corpse makes a distinct
sound.]]

-- Health station
L.hstation_name = "Health Station"
L.hstation_hint = "Hold {usekey} to receive health. Charge: {num}."
L.hstation_hint_reduce = "Hold {usekey} to reduce max health. Charge: {num}."
L.hstation_broken = "Your Health Station has been destroyed!"
L.hstation_help = "{primaryfire} places the Health Station."

L.hstation_desc = [[
Allows people to heal when placed.

Slow recharge. Anyone can use it, and
it can be damaged. Can be checked for
DNA samples of its users.]]

-- Knife
L.knife_name = "Knife"
L.knife_thrown = "Thrown knife"

L.knife_desc = [[
Kills wounded targets instantly and
silently, but only has a single use.

Can be thrown using alternate fire.]]

-- Poltergeist
L.polter_desc = [[
Plants thumpers on objects to shove
them around violently.

The energy bursts damage people in
close proximity.]]

-- Radio
L.radio_broken = "Your Radio has been destroyed!"
L.radio_help_pri = "{primaryfire} places the Radio."

L.radio_desc = [[
Plays sounds to distract or deceive.

Place the radio somewhere, and then
play sounds on it using the Radio tab
in this menu.]]

-- Silenced pistol
L.sipistol_name = "Silenced Pistol"

L.sipistol_desc = [[
Low-noise handgun, uses normal pistol
ammo.

Victims will not scream when killed.]]

-- Newton launcher
L.newton_name = "Newton launcher"

L.newton_desc = [[
Push people from a safe distance.

Infinite ammo, but slow to fire.]]

-- Binoculars
L.binoc_name = "Binoculars"
L.binoc_desc = [[
Zoom in on corpses and identify them
from a long distance away.

Unlimited uses, but identification
takes a few seconds.]]

L.binoc_help_pri = "Hold {primaryfire} to identify a body"
L.binoc_help_sec = "Press {secondaryfire} to change zoom level"

-- UMP
L.ump_desc = [[
Experimental SMG that disorients
targets.

Uses standard SMG ammo.]]

-- DNA scanner
L.dna_name = "DNA scanner"
L.dna_identify = "Corpse must be identified to retrieve killer's DNA."
L.dna_notfound = "No DNA sample found on target."
L.dna_limit = "Storage limit reached. Remove old samples to add new ones."
L.dna_decayed = "DNA sample of the killer has decayed."
L.dna_killer = "Collected a sample of the killer's DNA from the corpse!"
L.dna_no_killer = "The DNA could not be retrieved (killer disconnected?)."
L.dna_armed = "This bomb is live! Disarm it first!"
L.dna_object = "Collected {num} new DNA sample(s) from the object."
L.dna_gone = "DNA not detected in area."

L.dna_desc = [[
Collect DNA samples from things
and use them to find the DNA's owner.

Use on fresh corpses to get the killer's DNA
and track them down.]]

L.dna_menu_title = "DNA scanning controls"
L.dna_menu_sample = "DNA sample found on {source}"
L.dna_menu_remove = "Remove selected"
L.dna_menu_help1 = "These are DNA samples you have collected."
L.dna_menu_help2 = [[
When charged, you can scan for the location of
the player the selected DNA sample belongs to.
Finding distant targets drains more energy.]]

L.dna_menu_scan = "Scan"
L.dna_menu_repeat = "Auto-repeat"
L.dna_menu_ready = "READY"
L.dna_menu_charge = "CHARGING"
L.dna_menu_select = "SELECT SAMPLE"

L.dna_help_primary = "{primaryfire} to collect a DNA sample"
L.dna_help_secondary = "{secondaryfire} to open scan controls"

-- Magneto stick
L.magnet_name = "Magneto-stick"
L.magnet_help = "{primaryfire} to attach body to surface."

-- Grenades and misc
L.grenade_smoke = "Smoke grenade"
L.grenade_fire = "Incendiary grenade"

L.unarmed_name = "Holstered"
L.crowbar_name = "Crowbar"
L.pistol_name = "Pistol"
L.rifle_name = "Rifle"
L.shotgun_name = "Shotgun"

-- Teleporter
L.tele_name = "Teleporter"
L.tele_failed = "Teleport failed."
L.tele_marked = "Teleport location marked."

L.tele_no_ground = "Cannot teleport unless standing on solid ground!"
L.tele_no_crouch = "Cannot teleport while crouched!"
L.tele_no_mark = "No location marked. Mark a destination before teleporting."

L.tele_no_mark_ground = "Cannot mark a teleport location unless standing on solid ground!"
L.tele_no_mark_crouch = "Cannot mark a teleport location while crouched!"

L.tele_help_pri = "{primaryfire} teleports to marked location."
L.tele_help_sec = "{secondaryfire} marks current location."

L.tele_desc = [[
Teleport to a previously marked spot.

Teleporting makes noise, and the
number of uses is limited.]]

-- Ammo names, shown when picked up
L.ammo_pistol = "9mm ammo"

L.ammo_smg1 = "SMG ammo"
L.ammo_buckshot = "Shotgun ammo"
L.ammo_357 = "Rifle ammo"
L.ammo_alyxgun = "Deagle ammo"
L.ammo_ar2altfire = "Flare ammo"
L.ammo_gravity = "Poltergeist ammo"


--- HUD interface text

-- Round status
L.round_wait = "Waiting"
L.round_prep = "Preparing"
L.round_active = "In progress"
L.round_post = "Round over"

-- Health, ammo and time area
L.overtime = "OVERTIME"
L.hastemode = "HASTE MODE"

-- TargetID health status
L.hp_healthy = "Healthy"
L.hp_hurt = "Hurt"
L.hp_wounded = "Wounded"
L.hp_badwnd = "Badly Wounded"
L.hp_death = "Near Death"

-- TargetID karma status
L.karma_max = "Renowned"
L.karma_high = "Reputable"
L.karma_med = "Questionable"
L.karma_low = "Dangerous"
L.karma_min = "Liability"

-- TargetID misc
L.corpse = "Corpse"
L.corpse_hint = "Press {usekey} to search."
L.corpse_hint_covert = "Press {usekey} to search. Press {walkkey}+{usekey} to search covertly."
L.corpse_hint_possess = "Press {usekey} to possess this corpse."
L.corpse_hint_search_possess = "Press {usekey} to search. Press {walkkey}+{usekey} to possess this corpse."
L.corpse_hint_call = "Press {usekey} to call {adetective}."

L.target_disg = " (DISGUISED)"
L.target_unid = "Unidentified body"

L.target_credits = "Search to receive unspent credits"

L.target_unknown_team = "UNKNOWN {targettype}"
L.target_unconfirmed_role = "UNCONFIRMED {targettype}"
L.target_not_role = "NON-{targettype}"

-- Traitor buttons (HUD buttons with hand icons that only traitors can see)
L.tbut_single = "Single use"
L.tbut_reuse = "Reusable"
L.tbut_retime = "Reusable after {num} seconds"
L.tbut_help = "Press {key} to activate"

-- Equipment info lines (on the left above the health/ammo panel)
L.disg_hud = "Disguised. Your name is hidden."
L.radar_hud = "Radar ready for next scan in: {time}"

-- Spectator muting of living/dead
L.mute_living = "Living players muted"
L.mute_specs = "Spectators muted"
L.mute_all = "All muted"
L.mute_off = "None muted"

-- Prop possession
L.punch_title = "PUNCH-O-METER"
L.punch_help = "Move keys or jump: punch object. Crouch: leave object."
L.punch_bonus = "Your bad score lowered your punch-o-meter limit by {num}"
L.punch_malus = "Your good score increased your punch-o-meter limit by {num}!"

-- Spectators
L.spec_help = "Click to spectate players, or press {usekey} on a physics object to possess it."

--- Info popups shown when the round starts

-- These are spread over multiple lines, hence the square brackets instead of
-- quotes. That's a Lua thing. Every line break (enter) will show up in-game.
L.info_popup_monster_comrades = [[Work with your allies to kill all others.

These are your comrades:
{allylist}]]

L.info_popup_monster_alone = [[You have no allies this round.

Kill all others to win!]]

L.info_popup_monster_illusionist = [[Work with your allies to kill all others.
BUT BEWARE! There is {anillusionist} that is preventing you from knowing who your comrades are.]]

L.info_popup_traitor_comrades = [[Work with fellow {traitors} to kill all others.
But take care, or your treason may be discovered...

These are your comrades:
{traitorlist}]]

L.info_popup_traitor_alone = [[You have no fellow {traitors} this round.

Kill all others to win!]]

L.info_popup_traitor_glitch = [[Work with fellow {traitors} to kill all others.
BUT BEWARE! There was {aglitch} in the system and one among you does not seek the same goal.

These may or may not be your comrades:
{traitorlist}]]

L.info_popup_traitor_illusionist = [[Work with fellow {traitors} to kill all others.
BUT BEWARE! There is {anillusionist} that is preventing you from knowing who your comrades are.]]

--- Various other text
L.name_kick = "A player was automatically kicked for changing their name during a round."

L.idle_popup = [[You were idle for {num} seconds and were moved into Spectator-only mode as a result. While you are in this mode, you will not spawn when a new round starts.

You can toggle Spectator-only mode at any time by pressing {helpkey} and unchecking the box in the Config tab. You can also choose to disable it right now.]]

L.idle_popup_close = "Do nothing"
L.idle_popup_off = "Disable Spectator-only mode now"

L.idle_warning = "Warning: you appear to be idle/AFK, and will be made to spectate unless you show activity!"

L.spec_mode_warning = "You are in Spectator Mode and will not spawn when a round starts. To disable this mode, press F1, go to Config and uncheck 'Spectate-only mode'."


--- Tips, shown at bottom of screen to spectators

-- Tips panel
L.tips_panel_title = "Tips"
L.tips_panel_tip = "Tip:"

-- Tip texts

L.tip1 = "{traitors} can search a corpse silently, without confirming the death, by holding {walkkey} and pressing {usekey} on the corpse."

L.tip2 = "Arming a C4 explosive with a longer timer will increase the number of wires that cause it to explode instantly when an innocent attempts to disarm it. It will also beep softer and less often."

L.tip3 = "{detectives} can search a corpse to find who is 'reflected in its eyes'. This is the last person the dead guy saw. That does not have to be the killer if they were shot in the back."

L.tip4 = "No one will know you have died until they find your dead body and identify you by searching it."

L.tip5 = "When {atraitor} kills {adetective}, they instantly receive a credit reward."

L.tip6 = "When {atraitor} dies, all {detectives} are rewarded equipment credits."

L.tip7 = "When the {traitors} have made significant progress in killing {innocents}, they will receive an equipment credit as reward."

L.tip8 = "Roles with shops can collect unspent equipment credits from the dead bodies of other roles with shops."

L.tip9 = "The Poltergeist can turn any physics object into a deadly projectile. Each punch is accompanied by a blast of energy hurting anyone nearby."

L.tip10 = "Keep an eye on colored messages in the top right. These will be important for you."

L.tip11 = "As a role with a shop, keep in mind you are rewarded extra equipment credits if you and your comrades perform well. Make sure you remember to spend them!"

L.tip12 = "The {detective}'s DNA Scanner can be used to gather DNA samples from weapons and items and then scan to find the location of the player who used them. Useful when you can get a sample from a corpse or a disarmed C4!"

L.tip13 = "When you are close to someone you kill, some of your DNA is left on the corpse. This DNA can be used with {adetective}'s DNA Scanner to find your current location. Better hide the body after you knife someone!"

L.tip14 = "The further you are away from someone you kill, the faster your DNA sample on their body will decay."

L.tip15 = "Are you {atraitor} and going sniping? Consider trying out the Disguiser. If you miss a shot, run away to a safe spot, disable the Disguiser, and no one will know it was you who was shooting at them."

L.tip16 = "As {atraitor}, the Teleporter can help you escape when chased, and allows you to quickly travel across a big map. Make sure you always have a safe position marked."

L.tip17 = "Are the {innocents} all grouped up and hard to pick off? Consider trying out the Radio to play sounds of C4 or a firefight to lead some of them away."

L.tip18 = "Using the Radio as {atraitor}, you can play sounds through your Equipment Menu after the radio has been placed. Queue up multiple sounds by clicking multiple buttons in the order you want them."

L.tip19 = "As {adetective}, if you have leftover credits you could give a trusted {innocent} a Defuser. Then you can spend your time doing the serious investigative work and leave the risky bomb defusal to them."

L.tip20 = "The {detective}'s Binoculars allow long-range searching and identifying of corpses. Bad news if the {traitors} were hoping to use a corpse as bait. Of course, while using the Binoculars {adetective} is unarmed and distracted..."

L.tip21 = "The {detective}'s Health Station lets wounded players recover. Of course, those wounded people could be {traitors}..."

L.tip22 = "The Health Station records a DNA sample of everyone who uses it. {detectives} can use this with the DNA Scanner to find out who has been healing up."

L.tip23 = "Unlike weapons and C4, the Radio equipment for {traitors} does not contain a DNA sample of the person who planted it. Don't worry about {detectives} finding it and blowing your cover."

L.tip24 = "Press {helpkey} to view a short tutorial or modify some TTT-specific settings. For example, you can permanently disable these tips there."

L.tip25 = "When {adetective} searches a body, the result is available to all players via the scoreboard by clicking on the name of the dead person."

L.tip26 = "In the scoreboard, a magnifying glass icon next to someone's name indicates you have search information about that person. If the icon is bright, the data comes from {adetective} and may contain additional information."

L.tip27 = "As {adetective}, corpses with a magnifying glass after the nickname have been searched by {adetective} and their results are available to all players via the scoreboard."

L.tip28 = "Spectators can press {mutekey} to cycle through muting other spectators or living players."

L.tip29 = "If the server has installed additional languages, you can switch to a different language at any time in the Config menu."

L.tip30 = "Quickchat or 'radio' commands can be used by pressing {radiokey}."

L.tip31 = "As Spectator, press {duckkey} to unlock your mouse cursor and click the buttons on this tips panel. Press {duckkey} again to go back to mouseview."

L.tip32 = "The Crowbar's secondary fire will push other players."

L.tip33 = "Firing through the ironsights of a weapon will slightly increase your accuracy and decrease recoil. Crouching does not."

L.tip34 = "Smoke grenades are effective indoors, especially for creating confusion in crowded rooms."

L.tip35 = "As {atraitor}, remember you can carry dead bodies and hide them from the prying eyes of the {innocents} and their {detectives}."

L.tip36 = "The tutorial available under {helpkey} contains an overview of the most important keys of the game."

L.tip37 = "On the scoreboard, click the name of a living player and you can select a tag for them such as 'suspect' or 'friend'. This tag will show up if you have them under your crosshair."

L.tip38 = "Many of the placeable equipment items (such as C4, Radio) can be stuck on walls using secondary fire."

L.tip39 = "C4 that explodes due to a mistake in disarming it has a smaller explosion than C4 that reaches zero on its timer."

L.tip40 = "If it says 'HASTE MODE' above the round timer, the round will at first be only a few minutes long, but with every death the available time increases (like capturing a point in TF2). This mode puts the pressure on the {traitors} to keep things moving."

-- 9/22/21
L.tip41 = "You can adjust a player's microphone volume by right-clicking their mute button at the end of the scoreboard."

--- Round report

L.report_title = "Round report"

-- Tabs
L.report_tab_summary = "Summary"
L.report_tab_summary_tip = "Round summary"
L.report_tab_hilite = "Highlights"
L.report_tab_hilite_tip = "Round highlights"
L.report_tab_events = "Events"
L.report_tab_events_tip = "Log of the events that happened this round"
L.report_tab_scores = "Scores"
L.report_tab_scores_tip = "Points scored by each player in this round alone"

-- Sumamry tab
L.summary_role_changed = "{starting} changed to {ending}"

-- Highlights tab
L.hilite_win_role_plural = "THE {role} WIN"
L.hilite_win_role_singular = "THE {role} WINS"
L.hilite_win_role_singular_additional = "AND THE {role} WINS"
L.hilite_win_draw = "IT'S A DRAW"

L.hilite_players1 = "{numplayers} players took part, {numtraitors} were {traitors}"
L.hilite_players2 = "{numplayers} players took part, one of them the {traitor}"

L.hilite_duration = "The round lasted {time}"

-- Event log tab
L.report_save = "Save Log .txt"
L.report_save_tip = "Saves the Event Log to a text file"
L.report_save_error = "No Event Log data to save."
L.report_save_result = "The Event Log has been saved to:"

-- Score tab columns
L.col_time = "Time"
L.col_event = "Event"
L.col_player = "Player"
L.col_role = "Starting Role"
L.col_kills1 = "Inno. kills"
L.col_kills2 = "{traitor} kills"
L.col_kills3 = "{jester} kills"
L.col_kills4 = "Indep. kills"
L.col_kills5 = "Mon. kills"
L.col_totalkills = "Total kills"
L.col_points = "Points"
L.col_team = "Team bonus"
L.col_total = "Total points"

-- Name of a trap that killed us that has not been named by the mapper
L.something = "something"

-- Kill events
L.ev_blowup = "{victim} blew themselves up"
L.ev_blowup_trap = "{victim} was blown up by {trap}"

L.ev_tele_self = "{victim} telefragged themselves"
L.ev_sui = "{victim} killed themselves"
L.ev_sui_using = "{victim} killed themselves using {tool}"

L.ev_fall = "{victim} fell to their death"
L.ev_fall_pushed = "{victim} fell to their death after {attacker} pushed them"
L.ev_fall_pushed_using = "{victim} fell to their death after {attacker} used {trap} to push them"

L.ev_shot = "{victim} was shot by {attacker}"
L.ev_shot_using = "{victim} was shot by {attacker} using a {weapon}"

L.ev_drown = "{victim} was drowned by {attacker}"
L.ev_drown_using = "{victim} was drowned by {trap} triggered by {attacker}"

L.ev_boom = "{victim} was exploded by {attacker}"
L.ev_boom_using = "{victim} was blown up by {attacker} using {trap}"

L.ev_burn = "{victim} was fried by {attacker}"
L.ev_burn_using = "{victim} was burned by {trap} due to {attacker}"

L.ev_club = "{victim} was beaten up by {attacker}"
L.ev_club_using = "{victim} was pummeled to death by {attacker} using {trap}"

L.ev_slash = "{victim} was stabbed by {attacker}"
L.ev_slash_using = "{victim} was cut up by {attacker} using {trap}"

L.ev_tele = "{victim} was telefragged by {attacker}"
L.ev_tele_using = "{victim} was atomized by {trap} set by {attacker}"

L.ev_goomba = "{victim} was crushed by the massive bulk of {attacker}"

L.ev_crush = "{victim} was crushed by {attacker}"
L.ev_crush_using = "{victim} was crushed by {trap} of {attacker}"

L.ev_other = "{victim} was killed by {attacker}"
L.ev_other_using = "{victim} was killed by {attacker} using {trap}"

-- Other events
L.ev_body = "{finder} found the corpse of {victim}"
L.ev_c4_plant = "{player} planted C4"
L.ev_c4_boom = "The C4 planted by {player} exploded"
L.ev_c4_disarm1 = "{player} disarmed C4 planted by {owner}"
L.ev_c4_disarm2 = "{player} failed to disarm C4 planted by {owner}"
L.ev_credit = "{finder} found {num} credit(s) on the corpse of {player}"

L.ev_start = "The round started"
L.ev_spawn = "{player} spawned as {a} {role}"
L.ev_role_changed = "{player} changed roles to {a} {role}"
L.ev_win_traitor = "The dastardly {role} won the round!"
L.ev_win_inno = "The lovable {role} won the round!"
L.ev_win_monster = "The evil monsters have won the round!"
L.ev_win_time = "The {role} ran out of time and lost!"
L.ev_win_draw = "Time ran out, resulting in a draw!"
L.ev_win_icon = "{role} won"
L.ev_win_icon_time = "Time Limit"
L.ev_win_icon_also = "{role} also won"
L.ev_win_unknown = "Unknown win type with ID: {id}"

--- Awards/highlights

L.aw_sui1_title = "Suicide Cult Leader"
L.aw_sui1_text = "showed the other suiciders how to do it by being the first to go."

L.aw_sui2_title = "Lonely and Depressed"
L.aw_sui2_text = "was the only one who killed themselves."

L.aw_exp1_title = "Explosives Research Grant"
L.aw_exp1_text = "was recognized for their research on explosions. {num} test subjects helped out."

L.aw_exp2_title = "Field Research"
L.aw_exp2_text = "tested their own resistance to explosions. It was not high enough."

L.aw_fst1_title = "First Blood"
L.aw_fst1_text = "delivered the first {innocent} death at {traitor}'s hands."

L.aw_fst2_title = "First Bloody Stupid Kill"
L.aw_fst2_text = "scored the first kill by shooting a fellow {traitor}. Good job."

L.aw_fst3_title = "First Blooper"
L.aw_fst3_text = "was the first to kill. Too bad it was {innocent} comrade."

L.aw_fst4_title = "First Blow"
L.aw_fst4_text = "struck the first blow for the {innocent} by making the first death {traitor}'s."

L.aw_all1_title = "Deadliest Among Equals"
L.aw_all1_text = "was responsible for killing every {traitor} this round."

L.aw_all2_title = "Lone Wolf"
L.aw_all2_text = "was responsible for killing every {innocent} this round."

L.aw_all3_title = "Van Helsing"
L.aw_all3_text = "was responsible for every {monster} killed this round."

L.aw_nkt1_title = "I Got One, Boss!"
L.aw_nkt1_text = "managed to kill a single {innocent}. Sweet!"

L.aw_nkt2_title = "A Bullet For Two"
L.aw_nkt2_text = "showed the first one was not a lucky shot by killing another."

L.aw_nkt3_title = "Serial {traitor}"
L.aw_nkt3_text = "ended three {innocent} lives of terrorism today."

L.aw_nkt4_title = "Wolf Among More Sheep-Like Wolves"
L.aw_nkt4_text = "eats {innocent} for dinner. A dinner of {num} courses."

L.aw_nkt5_title = "Counter-Terrorism Operative"
L.aw_nkt5_text = "gets paid per kill. Can now buy another luxury yacht."

L.aw_nki1_title = "Betray This"
L.aw_nki1_text = "found {traitor}. Shot {traitor}. Easy."

L.aw_nki2_title = "Applied to the Justice Squad"
L.aw_nki2_text = "escorted two {traitor} to the great beyond."

L.aw_nki3_title = "Do {traitor} Dream Of Traitorous Sheep?"
L.aw_nki3_text = "put three {traitor} to rest."

L.aw_nki4_title = "Internal Affairs Employee"
L.aw_nki4_text = "gets paid per kill. Can now order their fifth swimming pool."

L.aw_fal1_title = "No Mr. Bond, I Expect You To Fall"
L.aw_fal1_text = "pushed someone off a great height."

L.aw_fal2_title = "Floored"
L.aw_fal2_text = "let their body hit the floor after falling from a significant altitude."

L.aw_fal3_title = "The Human Meteorite"
L.aw_fal3_text = "crushed someone by falling on them from a great height."

L.aw_hed1_title = "Efficiency"
L.aw_hed1_text = "discovered the joy of headshots and made {num}."

L.aw_hed2_title = "Neurology"
L.aw_hed2_text = "removed the brains from {num} heads for a closer examination."

L.aw_hed3_title = "Videogames Made Me Do It"
L.aw_hed3_text = "applied their murder simulation training and headshotted {num} foes."

L.aw_cbr1_title = "Thunk Thunk Thunk"
L.aw_cbr1_text = "has a mean swing with the crowbar, as {num} victims found out."

L.aw_cbr2_title = "Freeman"
L.aw_cbr2_text = "covered their crowbar in the brains of no less than {num} people."

L.aw_pst1_title = "Persistent Little Bugger"
L.aw_pst1_text = "scored {num} kills using the pistol. Then they went on to hug someone to death."

L.aw_pst2_title = "Small Caliber Slaughter"
L.aw_pst2_text = "killed a small army of {num} with a pistol. Presumably installed a tiny shotgun inside the barrel."

L.aw_sgn1_title = "Easy Mode"
L.aw_sgn1_text = "applies the buckshot where it hurts, murdering {num} targets."

L.aw_sgn2_title = "A Thousand Little Pellets"
L.aw_sgn2_text = "didn't really like their buckshot, so they gave it all away. {num} recipients did not live to enjoy it."

L.aw_rfl1_title = "Point and Click"
L.aw_rfl1_text = "shows all you need for {num} kills is a rifle and a steady hand."

L.aw_rfl2_title = "I Can See Your Head From Here"
L.aw_rfl2_text = "knows their rifle. Now {num} other people know the rifle too."

L.aw_dgl1_title = "It's Like A Tiny Rifle"
L.aw_dgl1_text = "is getting the hang of the Desert Eagle and killed {num} people."

L.aw_dgl2_title = "Eagle Master"
L.aw_dgl2_text = "blew away {num} people with the deagle."

L.aw_mac1_title = "Pray and Slay"
L.aw_mac1_text = "killed {num} people with the MAC10, but won't say how much ammo they needed."

L.aw_mac2_title = "Mac and Cheese"
L.aw_mac2_text = "wonders what would happen if they could wield two MAC10s. {num} times two?"

L.aw_sip1_title = "Be Quiet"
L.aw_sip1_text = "shut {num} people up with the silenced pistol."

L.aw_sip2_title = "Silenced Assassin"
L.aw_sip2_text = "killed {num} people who did not hear themselves die."

L.aw_knf1_title = "Knife Knowing You"
L.aw_knf1_text = "stabbed someone in the face over the internet."

L.aw_knf2_title = "Where Did You Get That From?"
L.aw_knf2_text = "was not a Traitor, but still killed someone with a knife."

L.aw_knf3_title = "Such A Knife Man"
L.aw_knf3_text = "found {num} knives lying around, and made use of them."

L.aw_knf4_title = "World's Knifest Man"
L.aw_knf4_text = "killed {num} people with a knife. Don't ask me how."

L.aw_flg1_title = "To The Rescue"
L.aw_flg1_text = "used their flares to signal for {num} deaths."

L.aw_flg2_title = "Flare Indicates Fire"
L.aw_flg2_text = "taught {num} men about the danger of wearing flammable clothing."

L.aw_hug1_title = "A H.U.G.E Spread"
L.aw_hug1_text = "was in tune with their H.U.G.E, somehow managing to make their bullets hit {num} people."

L.aw_hug2_title = "A Patient Para"
L.aw_hug2_text = "just kept firing, and saw their H.U.G.E patience rewarded with {num} kills."

L.aw_msx1_title = "Putt Putt Putt"
L.aw_msx1_text = "picked off {num} people with the M16."

L.aw_msx2_title = "Mid-range Madness"
L.aw_msx2_text = "knows how to take down targets with the M16, scoring {num} kills."

L.aw_tkl1_title = "Made An Oopsie"
L.aw_tkl1_text = "had their finger slip just when they were aiming at a buddy."

L.aw_tkl2_title = "Double-Oops"
L.aw_tkl2_text = "thought they got {traitor} twice, but was wrong both times."

L.aw_tkl3_title = "Karma-conscious"
L.aw_tkl3_text = "couldn't stop after killing two teammates. Three is their lucky number."

L.aw_tkl4_title = "Teamkiller"
L.aw_tkl4_text = "murdered the entirety of their team. OMGBANBANBAN."

L.aw_tkl5_title = "Roleplayer"
L.aw_tkl5_text = "was roleplaying a madman, honest. That's why they killed most of their team."

L.aw_tkl6_title = "Moron"
L.aw_tkl6_text = "couldn't figure out which side they were on, and killed over half of their comrades."

L.aw_tkl7_title = "Redneck"
L.aw_tkl7_text = "protected their turf real good by killing over a quarter of their teammates."

L.aw_brn1_title = "Like Grandma Used To Make Them"
L.aw_brn1_text = "fried several people to a nice crisp."

L.aw_brn2_title = "Pyroid"
L.aw_brn2_text = "was heard cackling loudly after burning one of their many victims."

L.aw_brn3_title = "Pyrrhic Burnery"
L.aw_brn3_text = "burned them all, but is now all out of incendiary grenades! How will they cope!?"

L.aw_fnd1_title = "Coroner"
L.aw_fnd1_text = "found {num} bodies lying around."

L.aw_fnd2_title = "Gotta Catch Em All"
L.aw_fnd2_text = "found {num} corpses for their collection."

L.aw_fnd3_title = "Death Scent"
L.aw_fnd3_text = "keeps stumbling on random corpses, {num} times this round."

L.aw_crd1_title = "Recycler"
L.aw_crd1_text = "scrounged up {num} leftover credits from corpses."

L.aw_tod1_title = "Pyrrhic Victory"
L.aw_tod1_text = "died only seconds before their team won the round."

L.aw_tod2_title = "I Hate This Game"
L.aw_tod2_text = "died right after the start of the round."


--- New and modified pieces of text are placed below this point, marked with the
--- version in which they were added, to make updating translations easier.


--- v23
L.set_avoid_det = "Avoid being selected as {detective}"
L.set_avoid_det_tip = "Enable this to ask the server not to select you as {detective} if possible. Does not mean you are {traitor} more often."

--- v24
L.drop_no_ammo = "Insufficient ammo in your weapon's clip to drop as an ammo box."

--- v31
L.set_cross_brightness = "Crosshair brightness"
L.set_cross_size = "Crosshair size"

--- 5-25-15
L.hat_retrieve = "You picked up {detective}'s hat."

--- 3-9-2017
L.sb_sortby = "Sort By:"

--- 2018-07-24
L.equip_tooltip_main = "Equipment menu"
L.equip_tooltip_radar = "Radar control"
L.equip_tooltip_disguise = "Disguise control"
L.equip_tooltip_radio = "Radio control"
L.equip_tooltip_xfer = "Transfer credits"

L.confgrenade_name = "Discombobulator"
L.polter_name = "Poltergeist"
L.stungun_name = "UMP Prototype"

L.knife_instant = "INSTANT KILL"

L.dna_hud_type = "TYPE"
L.dna_hud_body = "BODY"
L.dna_hud_item = "ITEM"

L.binoc_zoom_level = "LEVEL"
L.binoc_body = "BODY DETECTED"

L.idle_popup_title = "Idle"

--- 2021-06-07
L.sb_playervolume = "Player Volume"

-- Custom Events
L.ev_defi = "{victim} was respawned"
L.ev_disco = "{victim} disconnected"

-- Role Weapons Configuration
L.roleweapons_title = "Role Weapons Configuration"
L.roleweapons_tabtitle = "Role Weapons"
L.roleweapons_tabtitle_tooltip = "Configure which buyable weapons are added or excluded from a role's shop"
L.roleweapons_confirm = "Update"
L.roleweapons_option_none = "None"
L.roleweapons_option_none_tooltip = "Use the default buying configuration for the weapon"
L.roleweapons_option_include = "Include"
L.roleweapons_option_include_tooltip = "Mark this weapon as explicitly buyable"
L.roleweapons_option_exclude = "Exclude"
L.roleweapons_option_exclude_tooltip = "Mark this weapon as explicitly NOT buyable"
L.roleweapons_option_norandom = "No Random"
L.roleweapons_option_norandom_tooltip = "Ensure this weapon stays in the shop, regardless of randomization"
L.roleweapons_option_loadout = "Loadout"
L.roleweapons_option_loadout_tooltip = "Add this to the role's loadout, giving it to them for free each round"
L.roleweapons_select_searchrole = "-Search Role-"
L.roleweapons_select_searchrole_tooltip = "Which role shop to search within"
L.roleweapons_select_saverole = "-Save Role-"
L.roleweapons_select_saverole_tooltip = "Which role shop to affect by these configuration changes"
L.roleweapons_commandtitle = "Commands"
L.roleweapons_commandtitle_tooltip = "Run commands to help manage role weapons configurations"
L.roleweapons_command_print = "Print Configurations"
L.roleweapons_command_print_desc = "Print the current configuration in the server console, highlighting anything invalid."
L.roleweapons_command_clean = "Clean Invalid Configurations"
L.roleweapons_command_clean_desc = "Removes any invalid configurations. WARNING: This CANNOT be undone!"
L.roleweapons_command_reload = "Reload Configurations"
L.roleweapons_command_reload_desc = "Reloads the configurations from the server's filesystem."
L.roleweapons_buyable_tooltip = "Buyable"
L.roleweapons_exclude_tooltip = "Excluded"
L.roleweapons_norandom_tooltip = "Randomization Bypassed"
L.roleweapons_loadout_tooltip = "In Loadout"

-- Role Packs Configuration
L.rolepacks_title = "Role Packs Configuration"
L.rolepacks_role_tabtitle = "Roles"
L.rolepacks_role_tabtitle_tooltip = "Configure which roles spawn in each role pack"
L.rolepacks_roleblock_tabtitle = "Role Blocks"
L.rolepacks_roleblock_tabtitle_tooltip = "Configure which roles blocks are in effect in each role pack"
L.rolepacks_weapon_tabtitle = "Weapons"
L.rolepacks_weapon_tabtitle_tooltip = "Configure which weapons are buyable in each role pack"
L.rolepacks_convar_tabtitle = "ConVars"
L.rolepacks_convar_tabtitle_tooltip = "Configure which ConVars are changed in each role pack"
L.rolepacks_add = "Add"
L.rolepacks_rename = "Rename"
L.rolepacks_delete = "Delete"
L.rolepacks_save = "Save"
L.rolepacks_apply = "Apply to Server"
L.rolepacks_clear = "Disable Active Role Pack"
L.rolepacks_add_role = "Add role"
L.rolepacks_delete_role = "Delete role"
L.rolepacks_add_slot = "Add slot"
L.rolepacks_delete_slot = "Delete slot"
L.rolepacks_use_default = "Use Default"

-- Role Blocks Configuration
L.roleblocks_title = "Role Blocks Configuration"
L.roleblocks_add_group = "Add group"
L.roleblocks_delete_group = "Delete group"

-- Player name disguising
L.player_name_disguised = "{name} (Disguised as {disguise})"