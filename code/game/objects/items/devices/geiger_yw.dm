/obj/item/geiger/wall
	name = "mounted geiger counter"
	desc = "A wall mounted device used for detecting and measuring radiation in an area."
	icon = 'icons/obj/devices_yw.dmi'
	icon_state = "geiger_wall"
	item_state = "geiger_wall"
	anchored = 1
	scanning = 1
	radiation_count = 0
	plane = TURF_PLANE
	layer = ABOVE_TURF_LAYER
	w_class = ITEMSIZE_LARGE
	flags = NOBLOODY
	var/circuit = /obj/item/circuitboard/geiger
	var/number = 0
	var/last_tick //used to delay the powercheck
	var/wiresexposed = 0

/obj/item/geiger/wall/Initialize(mapload)
	. = ..()
	START_PROCESSING(SSobj, src)
	soundloop = new(list(src), FALSE)

/obj/item/geiger/wall/Destroy()
	STOP_PROCESSING(SSobj, src)
	QDEL_NULL(soundloop)
	return ..()
/*
/obj/item/geiger/wall/process()
	get_radiation()

/obj/item/geiger/wall/proc/get_radiation()
	if(!scanning)
		return
	radiation_count = SSradiation.get_rads_at_turf(get_turf(src))
	update_icon()
	update_sound()

/obj/item/geiger/wall/examine(mob/user)
	..(user)
	get_radiation()
	to_chat(user, span_warning("[scanning ? "Ambient" : "Stored"] radiation level: [radiation_count ? radiation_count : "0"]Bq."))

/obj/item/geiger/wall/rad_act(amount)
	if(!amount || !scanning)
		return FALSE

	if(amount > radiation_count)
		radiation_count = amount

	update_icon()
	update_sound()
*/

/obj/item/geiger/wall/attack_self(var/mob/user)
	scanning = !scanning
	update_icon()
	update_sound()
	to_chat(user, span_notice("[icon2html(src,user.client)] You switch [scanning ? "on" : "off"] \the [src]."))

/obj/item/geiger/wall/update_icon()
	if(!scanning)
		icon_state = "geiger_wall-p"
		return 1

	switch(radiation_count)
		if(null)
			icon_state = "geiger_level_1"
		if(-INFINITY to RAD_LEVEL_LOW)
			icon_state = "geiger_level_1"
		if(RAD_LEVEL_LOW to RAD_LEVEL_MODERATE)
			icon_state = "geiger_level_2"
		if(RAD_LEVEL_MODERATE to RAD_LEVEL_HIGH)
			icon_state = "geiger_level_3"
		if(RAD_LEVEL_HIGH to RAD_LEVEL_VERY_HIGH)
			icon_state = "geiger_level_4"
		if(RAD_LEVEL_VERY_HIGH to INFINITY)
			icon_state = "geiger_level_5"
/*
/obj/item/geiger/wall/process()
	if(((world.timeofday - last_tick) > 30) || ((world.timeofday - last_tick) < 0))
		last_tick = world.timeofday

		if(!src.loc)
			scanning = 0
		else
			var/area/A = get_area(src)
			if(!A)
				scanning = 0
			else
				scanning = A.powered(EQUIP) // set "on" to the power status

		if(!scanning)
			if(wiresexposed)
				icon_state = "geiger_wall-p_open"
			else
				icon_state = "geiger_wall-p"
		else
			if(wiresexposed)
				icon_state = "geiger_wall-p_open"
			else
				icon_state = initial(icon_state) */

/obj/item/geiger/wall/attack_ai(mob/user as mob)
	src.add_fingerprint(user)
	spawn (0)
		attack_self(user)

/obj/item/geiger/wall/attack_hand(mob/user as mob)
	src.add_fingerprint(user)
	spawn (0)
		attack_self(user)
