---- Event display information for Event Log in the Round Report

---- Usage:
-- Declare a *unique* event identifier in a shared file, eg.
-- EVENT_PANTS = 800
--
-- Use SCORE:AddEvent serverside in whatever way you want.
--
-- Clientside, tell CLSCORE how to display it, like so:
--
-- CLSCORE.DeclareEventDisplay(EVENT_PANTS,
--                            { text = function(e)
--                                        return "Someone wore " .. e.num .. "pants."
--                                     end,
--                              icon = function(e)
--                                        return myiconmaterial, "MyTooltip"
--                                     end
--                            })

-- Note that custom events don't have to be in this file, just any file that is
-- loaded on the client.

-- Translation helpers
local T  = LANG.GetTranslation
local PT = LANG.GetParamTranslation

-- Icons we'll use
local magnifier_icon = Material("icon16/magnifier.png")
local bomb_icon    = Material("icon16/bomb.png")
local wrong_icon   = Material("icon16/cross.png")
local right_icon   = Material("icon16/tick.png")
local shield_icon  = Material("icon16/shield.png")
local star_icon    = Material("icon16/star.png")
local app_icon     = Material("icon16/application.png")
local credit_icon = Material("icon16/coins.png")
local wrench_icon  = Material("icon16/wrench.png")

local zombie_icon = Material("icon16/user_green.png")
local vampire_icon = Material("icon16/user_gray.png")
local traitor_icon = Material("icon16/user_red.png")
local heart_icon = Material("icon16/heart.png")
local disconnect_icon = Material("icon16/disconnect.png")
local swap_icon = Material("icon16/arrow_refresh_small.png")
local promotion_icon = Material("icon16/award_star_add.png")
local clown_icon = Material("icon16/emoticon_evilgrin.png")
local drunk_icon = Material("icon16/drink_empty.png")
local haunt_icon = Material("icon16/group.png")
local bodysnatch_icon = Material("icon16/user_edit.png")
local info_icon = Material("icon16/information.png")

-- Shorter name, using it lots
local Event = CLSCORE.DeclareEventDisplay

local is_dmg = util.BitSet

local function StartsWithVowel(word)
    local firstletter = string.sub(word, 1, 1)
    return firstletter == "a" or
        firstletter == "e" or
        firstletter == "i" or
        firstletter == "o" or
        firstletter == "u"
end

-- Round end event
Event(EVENT_FINISH,
      { text = function(e)
                  if e.win == WIN_TRAITOR then
                     return T("ev_win_traitor")
                  elseif e.win == WIN_INNOCENT then
                     return T("ev_win_inno")
                  elseif e.win == WIN_JESTER then
                     return T("ev_win_jester")
                  elseif e.win == WIN_CLOWN then
                     return T("ev_win_clown")
                  elseif e.win == WIN_OLDMAN then
                     return T("ev_win_oldman")
                  elseif e.win == WIN_KILLER then
                     return T("ev_win_killer")
                  elseif e.win == WIN_TIMELIMIT then
                     return T("ev_win_time")
                  end
               end,
        icon = function(e)
                  if e.win == WIN_TRAITOR then
                     return star_icon, "Traitors won"
                  elseif e.win == WIN_INNOCENT then
                     return star_icon, "Innocents won"
                  elseif e.win == WIN_JESTER then
                     return star_icon, "Jester won"
                  elseif e.win == WIN_CLOWN then
                     return star_icon, "Clown won"
                  elseif e.win == WIN_OLDMAN then
                     return star_icon, "Old Man also won"
                  elseif e.win == WIN_KILLER then
                     return star_icon, "Killer won"
                  else
                     return star_icon, "Timelimit"
                  end
               end
     })

-- Round start event
Event(EVENT_GAME,
      { text = function(e)
                  if e.state == ROUND_ACTIVE then return T("ev_start") end
               end,
        icon = function(e)
                  return app_icon, "Game"
               end
      })

-- Roles
Event(EVENT_SPAWN,
      { text = function(e)
                  if e.ply then
                    local rolestring = ROLE_STRINGS[e.rol]
                    local a = StartsWithVowel(rolestring) and "an" or "a"
                    return PT("ev_spawn", {player = e.ply,
                                           a = a,
                                           role = rolestring})
                  end
               end,
        icon = function(e)
                  return app_icon, "Game"
               end
      })
Event(EVENT_ROLECHANGE,
      { text = function(e)
                  if e.ply then
                    local rolestring = ROLE_STRINGS[e.rol]
                    local a = StartsWithVowel(rolestring) and "an" or "a"
                    return PT("ev_role_changed", {player = e.ply,
                                                  a = a,
                                                  role = rolestring})
                  end
               end,
        icon = function(e)
                  return app_icon, "Game"
               end
      })

-- Credits event
Event(EVENT_CREDITFOUND,
      { text = function(e)
                  return PT("ev_credit", {finder = e.ni,
                                          num = e.cr,
                                          player = e.b})
               end,
        icon = function(e)
                  return credit_icon, "Credit found"
               end
     })

Event(EVENT_BODYFOUND,
      { text = function(e)
                  return PT("ev_body", {finder = e.ni, victim = e.b})
               end,
        icon = function(e)
                  return magnifier_icon, "Body discovered"
               end
     })

-- C4 fun
Event(EVENT_C4DISARM,
      { text = function(e)
                  return PT(e.s and "ev_c4_disarm1" or "ev_c4_disarm2",
                            {player = e.ni, owner = e.own or "aliens"})
               end,
        icon = function(e)
                  return wrench_icon, "C4 disarm"
               end
     })

Event(EVENT_C4EXPLODE,
      { text = function(e)
                  return PT("ev_c4_boom", {player = e.ni})
               end,
        icon = function(e)
                  return bomb_icon, "C4 exploded"
               end
     })

Event(EVENT_C4PLANT,
      { text = function(e)
                  return PT("ev_c4_plant", {player = e.ni})
               end,
        icon = function(e)
                  return bomb_icon, "C4 planted"
               end
     })

-- Helper fn for kill events
local function GetWeaponName(gun)
   local wname = nil

   -- Standard TTT weapons are sent as numeric IDs to save bandwidth
   if tonumber(gun) then
      wname = EnumToWep(gun)
   elseif isstring(gun) then
      -- Custom weapons or ones that are otherwise ID-less are sent as
      -- string
      local wep = util.WeaponForClass(gun)
      wname = wep and wep.PrintName
   end

   return wname
end

-- Generating the text for a kill event requires a lot of logic for special
-- cases, resulting in a long function, so defining it separately here.
local function KillText(e)
   local dmg = e.dmg

   local trap = dmg.n
   if trap == "" then trap = nil end

   local weapon = GetWeaponName(dmg.g)
   if weapon then
      weapon = LANG.TryTranslation(weapon)
   end

   -- there is only ever one piece of equipment present in a language string,
   -- all the different names like "trap", "tool" and "weapon" are aliases.
   local eq = trap or weapon

   local params = {victim = e.vic.ni, attacker = e.att.ni, trap = eq, tool = eq, weapon = eq}

   local txt = nil

   if e.att.sid64 == e.vic.sid64 then
      if is_dmg(dmg.t, DMG_BLAST) then

         txt = trap and "ev_blowup_trap" or "ev_blowup"

      elseif is_dmg(dmg.t, DMG_SONIC) then
         txt = "ev_tele_self"
      else
         txt = trap and "ev_sui_using" or "ev_sui"
      end
   end

   -- txt will be non-nil if it was a suicide, don't need to do any of the
   -- rest in that case
   if txt then
      return PT(txt, params)
   end

   -- we will want to know if the death was caused by a player or not
   -- (eg. push vs fall)
   local ply_attacker = true

   -- if we are dealing with an accidental trap death for example, we want to
   -- use the trap name as "attacker"
   if e.att.ni == "" then
      ply_attacker = false

      params.attacker = trap or T("something")
   end

   -- typically the "_using" strings are only for traps
   local using = (not weapon)

   if is_dmg(dmg.t, DMG_FALL) then
      if ply_attacker then
         txt = "ev_fall_pushed"
      else
         txt = "ev_fall"
      end
   elseif is_dmg(dmg.t, DMG_BULLET) then
      txt = "ev_shot"

      using = true
   elseif is_dmg(dmg.t, DMG_DROWN) then
      txt = "ev_drown"
   elseif is_dmg(dmg.t, DMG_BLAST) then
      txt = "ev_boom"
   elseif is_dmg(dmg.t, DMG_BURN) or is_dmg(dmg.t, DMG_DIRECT) then
      txt = "ev_burn"
   elseif is_dmg(dmg.t, DMG_CLUB) then
      txt = "ev_club"
   elseif is_dmg(dmg.t, DMG_SLASH) then
      txt = "ev_slash"
   elseif is_dmg(dmg.t, DMG_SONIC) then
      txt = "ev_tele"
   elseif is_dmg(dmg.t, DMG_PHYSGUN) then
      txt = "ev_goomba"
      using = false
   elseif is_dmg(dmg.t, DMG_CRUSH) then
      txt = "ev_crush"
   else
      txt = "ev_other"
   end

   if ply_attacker and (trap or weapon) and using then
      txt = txt .. "_using"
   end

   return PT(txt, params)
end

Event(EVENT_KILL,
{
    text = KillText,
    icon = function(e)
        if e.att.sid64 == e.vic.sid64 or e.att.sid64 == -1 then
            return wrong_icon, "Suicide"
        end

        local attacker = (e.att.tr and "Traitor") or (e.att.jes and "Jester") or (e.att.ind and "Independent") or "Innocent"
        local victim = (e.vic.tr and "Traitor") or (e.vic.jes and "Jester") or (e.vic.ind and "Independent") or "Innocent"
        if e.tk then
            return wrong_icon, "Teamkill"
        elseif e.att.tr or e.att.ind then
            return right_icon, attacker.." killed "..victim
        else
            return shield_icon, attacker.." killed "..victim
        end
    end
})

Event(EVENT_HYPNOTISED, {
        text = function(e)
                  return PT("ev_hypno", {victim = e.vic})
               end,
        icon = function(e)
                    return traitor_icon, "Hypnotised"
                end})

Event(EVENT_DEFIBRILLATED, {
        text = function(e)
                  return PT("ev_defi", {victim = e.vic})
               end,
        icon = function(e)
                    return heart_icon, "Defibrillated"
                end})

Event(EVENT_DISCONNECTED, {
        text = function(e)
                  return PT("ev_disco", {victim = e.vic})
               end,
        icon = function(e)
                    return disconnect_icon, "Disconnected"
                end})

Event(EVENT_SWAPPER, {
    text = function(e)
        return PT("ev_swap", {victim = e.vic, attacker = e.att})
    end,
    icon = function(e)
        return swap_icon, "Swapped"
    end})

Event(EVENT_PROMOTION, {
    text = function(e)
        return PT("ev_promote", {player = e.ply})
    end,
    icon = function(e)
        return promotion_icon, "Promotion"
    end})

Event(EVENT_CLOWNACTIVE, {
    text = function(e)
        return PT("ev_clown", {player = e.ply})
    end,
    icon = function(e)
        return clown_icon, "Killer Clown"
    end})

Event(EVENT_DRUNKSOBER, {
    text = function(e)
        return PT("ev_drunk", {player = e.ply, team = e.team})
    end,
    icon = function(e)
        return drunk_icon, "Drunk Sober"
    end})

Event(EVENT_HAUNT, {
    text = function(e)
        return PT("ev_haunt", {victim = e.vic, attacker = e.att})
    end,
    icon = function(e)
        return haunt_icon, "Haunt"
    end})

Event(EVENT_BODYSNATCH, {
    text = function(e)
        return PT("ev_bodysnatch", {victim = e.vic, attacker = e.att, role = e.role})
    end,
    icon = function(e)
        return bodysnatch_icon, "Bodysnatch"
    end})

Event(EVENT_LOG, {
        text = function(e)
                    return e.txt
                end,
        icon = function(e)
                    return info_icon, "Information"
                end})