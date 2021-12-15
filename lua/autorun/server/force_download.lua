if SERVER then
    local resource = resource

    ---------------
    -- Materials --
    ---------------

    -- Celebration
    resource.AddSingleFile("materials/vgui/confetti.png")

    -- Items
    resource.AddFile("materials/vgui/ttt/icon_bombstation.vmt")
    resource.AddFile("materials/vgui/ttt/icon_brainwash.vmt")
    resource.AddFile("materials/vgui/ttt/icon_cure.vmt")
    resource.AddFile("materials/vgui/ttt/icon_exor.vmt")
    resource.AddFile("materials/vgui/ttt/icon_fakecure.vmt")
    resource.AddFile("materials/vgui/ttt/icon_meddefib.vmt")
    resource.AddFile("materials/vgui/ttt/icon_regen.vmt")
    resource.AddFile("materials/vgui/ttt/icon_speed.vmt")
    resource.AddFile("materials/vgui/ttt/icon_stationbomb.vmt")

    -- Radar
    resource.AddFile("materials/vgui/ttt/beacon_back.vmt")
    resource.AddFile("materials/vgui/ttt/beacon_det.vmt")
    resource.AddFile("materials/vgui/ttt/beacon_rev.vmt")

    -- Round Summary
    resource.AddSingleFile("materials/vgui/ttt/score_disconicon.png")
    resource.AddSingleFile("materials/vgui/ttt/score_skullicon.png")

    -- Shop
    resource.AddSingleFile("materials/vgui/ttt/equip/briefcase.png")
    resource.AddSingleFile("materials/vgui/ttt/equip/coin.png")
    resource.AddSingleFile("materials/vgui/ttt/equip/package.png")
    resource.AddFile("materials/vgui/ttt/slot_cap.vmt")

    -- Target ID
    resource.AddFile("materials/vgui/ttt/sprite_roleback.vmt")
    resource.AddSingleFile("materials/vgui/ttt/sprite_roleback_noz.vmt")
    resource.AddFile("materials/vgui/ttt/sprite_rolefront.vmt")
    resource.AddSingleFile("materials/vgui/ttt/sprite_rolefront_noz.vmt")
    resource.AddSingleFile("materials/vgui/ttt/sprite_target_noz.vmt")
    resource.AddSingleFile("materials/vgui/ttt/sprite_target.vtf")

    -- Misc
    resource.AddFile("materials/thieves/footprint.vmt")
    resource.AddFile("materials/vgui/ttt/tele_mark.vmt")
    resource.AddSingleFile("materials/vgui/ttt/ulx_ttt.png")

    -- Tutorial
    resource.AddSingleFile("materials/vgui/ttt/help/tut02_death_arrow.png")
    resource.AddSingleFile("materials/vgui/ttt/help/tut02_found_arrow.png")
    resource.AddSingleFile("materials/vgui/ttt/help/tut02_corpse_info.png")
    resource.AddSingleFile("materials/vgui/ttt/help/tut03_shop.png")

    ------------
    -- Sounds --
    ------------

    -- Celebration
    resource.AddSingleFile("sound/birthday.wav")

    -- Hit Markers
    resource.AddSingleFile("sound/hitmarkers/mlghit.wav")
end