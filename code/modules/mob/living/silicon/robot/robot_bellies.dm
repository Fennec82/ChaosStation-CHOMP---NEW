/mob/living/silicon/robot/proc/update_multibelly()
	vore_icon_bellies = list() //Clear any belly options that may not exist now
	vore_capacity_ex = list()
	vore_fullness_ex = list()
	if(sprite_datum.belly_capacity_list.len)
		for(var/belly in sprite_datum.belly_capacity_list) //vore icons list only contains a list of names with no associated data
			vore_capacity_ex[belly] = sprite_datum.belly_capacity_list[belly] //I dont know why but this wasnt working when I just
			vore_fullness_ex[belly] = 0 //set the lists equal to the old lists
			vore_icon_bellies += belly
		for(var/belly in sprite_datum.belly_light_list)
			vore_light_states[belly] = 0
	else if(sprite_datum.has_vore_belly_sprites)
		vore_capacity_ex = list("sleeper" = 1)
		vore_fullness_ex = list("sleeper" = 0)
		vore_icon_bellies = list("sleeper")
		if(sprite_datum.has_sleeper_light_indicator)
			vore_light_states = list("sleeper" = 0)
			sprite_datum.belly_light_list = list("sleeper")
	handle_belly_update() //Set how full the newly defined bellies are, if they're already full

/mob/living/silicon/robot/proc/reset_belly_lights(var/b_class)
	if(sprite_datum.belly_light_list.len && sprite_datum.belly_light_list.Find(b_class))
		vore_light_states[b_class] = 0

/mob/living/silicon/robot/proc/update_belly_lights(var/b_class)
	if(sprite_datum.belly_light_list.len && sprite_datum.belly_light_list.Find(b_class))
		vore_light_states[b_class] = 2
		for (var/belly in vore_organs)
			var/obj/belly/B = belly
			if(b_class == "sleeper" && (B.silicon_belly_overlay_preference == "Vorebelly" || B.silicon_belly_overlay_preference == "Both") || b_class != "sleeper")
				if(B.digest_mode != DM_DIGEST || B.belly_sprite_to_affect != b_class || !B.contents.len)
					continue
				for(var/contents in B.contents)
					if(isliving(contents))
						vore_light_states[b_class] = 1
						return

/mob/living/silicon/robot/vs_animate(var/belly_class)
	if(!sprite_datum.has_vore_struggle_sprite)
		return
	if(belly_class == "sleeper" && sleeper_state == 0 && vore_selected.silicon_belly_overlay_preference == "Sleeper")
		return
	var/vs_fullness = vore_fullness_ex[belly_class]
	if(resting)
		cut_overlay(sprite_datum.get_belly_resting_overlay(src, vs_fullness, belly_class))
		add_overlay("[sprite_datum.get_belly_resting_overlay(src, vs_fullness, belly_class)]-struggle")
	else
		cut_overlay(sprite_datum.get_belly_overlay(src, vs_fullness, belly_class))
		add_overlay("[sprite_datum.get_belly_overlay(src, vs_fullness, belly_class)]-struggle")
	addtimer(CALLBACK(src, PROC_REF(end_vs_animate), belly_class), 1.2 SECONDS)

/mob/living/silicon/robot/proc/end_vs_animate(var/belly_class)
	var/vs_fullness = vore_fullness_ex[belly_class]
	if(resting)
		cut_overlay("[sprite_datum.get_belly_resting_overlay(src, vs_fullness, belly_class)]-struggle")
	else
		cut_overlay("[sprite_datum.get_belly_overlay(src, vs_fullness, belly_class)]-struggle")
	if(vs_fullness > 0)
		if(resting)
			add_overlay(sprite_datum.get_belly_resting_overlay(src, vs_fullness, belly_class))
		else
			add_overlay(sprite_datum.get_belly_overlay(src, vs_fullness, belly_class))
