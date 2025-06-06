//replaces our stun baton code with /tg/station's code
/obj/item/melee/baton
	name = "stunbaton"
	desc = "A stun baton for incapacitating people with."
	icon_state = "stunbaton"
	item_state = "baton"
	slot_flags = SLOT_BELT
	force = 15
	sharp = FALSE
	edge = FALSE
	throwforce = 7
	flags = NOCONDUCT
	w_class = ITEMSIZE_NORMAL
	drop_sound = 'sound/items/drop/metalweapon.ogg'
	pickup_sound = 'sound/items/pickup/metalweapon.ogg'
	origin_tech = list(TECH_COMBAT = 2)
	attack_verb = list("beaten")
	var/lightcolor = "#FF6A00"
	var/stunforce = 0
	var/agonyforce = 60
	var/status = 0		//whether the thing is on or not
	var/obj/item/cell/bcell = null
	var/hitcost = 240
	var/grip_safety = TRUE
	var/taped_safety = FALSE

/obj/item/melee/baton/Initialize(mapload)
	. = ..()
	update_icon()

/obj/item/melee/baton/get_cell()
	return bcell

/obj/item/melee/baton/MouseDrop(obj/over_object as obj)
	if(!canremove)
		return

	if (ishuman(usr) || issmall(usr)) //so monkeys can take off their backpacks -- Urist

		if (istype(usr.loc,/obj/mecha)) // stops inventory actions in a mech. why?
			return

		if (!( istype(over_object, /obj/screen) ))
			return ..()

		//makes sure that the thing is equipped, so that we can't drag it into our hand from miles away.
		//there's got to be a better way of doing this.
		if (!(src.loc == usr) || (src.loc && src.loc.loc == usr))
			return

		if (( usr.restrained() ) || ( usr.stat ))
			return

		if ((src.loc == usr) && !(istype(over_object, /obj/screen)) && !usr.unEquip(src))
			return

		switch(over_object.name)
			if("r_hand")
				usr.u_equip(src)
				usr.put_in_r_hand(src)
			if("l_hand")
				usr.u_equip(src)
				usr.put_in_l_hand(src)
		src.add_fingerprint(usr)

/obj/item/melee/baton/loaded/Initialize(mapload) //this one starts with a cell pre-installed.
	bcell = new/obj/item/cell/device/weapon(src)
	. = ..()

/obj/item/melee/baton/proc/deductcharge()
	if(status == 1)		//Only deducts charge when it's on
		if(bcell)
			if(bcell.checked_use(hitcost))
				return 1
			else
				return 0
	return null

/obj/item/melee/baton/proc/powercheck()
	if(bcell)
		if(bcell.charge < hitcost)
			status = 0
			update_icon()

/obj/item/melee/baton/update_icon()
	if(status)
		icon_state = "[initial(name)]_active"
	else if(!bcell)
		icon_state = "[initial(name)]_nocell"
	else
		icon_state = "[initial(name)]"

	if(icon_state == "[initial(name)]_active")
		set_light(2, 1, lightcolor)
	else
		set_light(0)

/obj/item/melee/baton/dropped(mob/user)
	..()
	if(status && grip_safety && !taped_safety)
		status = 0
		visible_message(span_warning("\The [src]'s grip safety engages!"))
	update_icon()

/obj/item/melee/baton/examine(mob/user)
	. = ..()

	if(Adjacent(user))
		if(taped_safety)
			. += span_warning("Someone has wrapped tape around the grip!")
		if(bcell)
			. += span_notice("The baton is [round(bcell.percent())]% charged.")
		if(!bcell)
			. += span_warning("The baton does not have a power source installed.")

/obj/item/melee/baton/attackby(obj/item/W, mob/user)
	if(istype(W, /obj/item/cell))
		if(istype(W, /obj/item/cell/device))
			if(!bcell)
				user.drop_item()
				W.loc = src
				bcell = W
				to_chat(user, span_notice("You install a cell in [src]."))
				update_icon()
			else
				to_chat(user, span_notice("[src] already has a cell."))
		else
			to_chat(user, span_notice("This cell is not fitted for [src]."))
	if(istype(W, /obj/item/tape_roll) || istype(W, /obj/item/taperoll))
		if(grip_safety && !taped_safety)	//no point letting people wrap tape around the grips of batons without a safety
			to_chat(user, span_notice("You firmly wrap tape around the baton's grip, disabling the safety system."))
			playsound(src, 'sound/effects/tape.ogg',25)
			taped_safety = TRUE
		else if(grip_safety && taped_safety)
			to_chat(user, span_notice("The grip safety has already been taped down."))
	if(istype(W, /obj/item/tool/screwdriver))
		if(taped_safety)
			to_chat(user, span_notice("You painstakingly scrape away the tape over the grip safety."))
			taped_safety = FALSE

/obj/item/melee/baton/attack_hand(mob/user as mob)
	if(user.get_inactive_hand() == src)
		if(bcell)
			bcell.update_icon()
			user.put_in_hands(bcell)
			bcell = null
			to_chat(user, span_notice("You remove the cell from the [src]."))
			status = 0
			update_icon()
			return
		..()
	else
		return ..()

/obj/item/melee/baton/attack_self(mob/user)
	if(bcell && bcell.charge >= hitcost)
		status = !status
		to_chat(user, span_notice("[src] is now [status ? "on" : "off"]."))
		playsound(src, "sparks", 75, 1, -1)
		update_icon()
	else
		status = 0
		if(!bcell)
			to_chat(user, span_warning("[src] does not have a power source!"))
		else
			to_chat(user, span_warning("[src] is out of charge."))
	add_fingerprint(user)

/obj/item/melee/baton/attack(mob/M, mob/user)
	if(status && (CLUMSY in user.mutations) && prob(50))
		to_chat(user, span_danger("You accidentally hit yourself with the [src]!"))
		user.Weaken(30)
		deductcharge(hitcost)
		return
	deductcharge(hitcost)
	return ..()

/obj/item/melee/baton/apply_hit_effect(mob/living/target, mob/living/user, var/hit_zone)
	if(isrobot(target))
		return ..()

	var/agony = agonyforce
	var/stun = stunforce
	var/obj/item/organ/external/affecting = null
	if(ishuman(target))
		var/mob/living/carbon/human/H = target
		affecting = H.get_organ(hit_zone)

	if(user.a_intent == I_HURT) //CHOMPEdit: No disarm. ONLY HARM.
		. = ..()
		//whacking someone causes a much poorer electrical contact than deliberately prodding them.
		agony *= 0.5
		stun *= 0.5
	else if(!status)
		if(affecting)
			target.visible_message(span_warning("[target] has been prodded in the [affecting.name] with [src] by [user]. Luckily it was off."))
		else
			target.visible_message(span_warning("[target] has been prodded with [src] by [user]. Luckily it was off."))
	else
		if(affecting)
			target.visible_message(span_danger("[target] has been prodded in the [affecting.name] with [src] by [user]!"))
		else
			target.visible_message(span_danger("[target] has been prodded with [src] by [user]!"))
		playsound(src, 'sound/weapons/egloves.ogg', 50, 1, -1)

	//stun effects
	if(status)
		target.stun_effect_act(stun, agony, hit_zone, src)
		msg_admin_attack("[key_name(user)] stunned [key_name(target)] with the [src].")

		if(ishuman(target))
			var/mob/living/carbon/human/H = target
			H.forcesay(GLOB.hit_appends)
	powercheck()

/obj/item/melee/baton/emp_act(severity)
	if(bcell)
		bcell.emp_act(severity)	//let's not duplicate code everywhere if we don't have to please.
	..()

//Makeshift stun baton. Replacement for stun gloves.
/obj/item/melee/baton/cattleprod
	name = "stunprod"
	desc = "An improvised stun baton."
	icon_state = "stunprod_nocell"
	item_state = "prod"
	force = 3
	throwforce = 5
	stunforce = 0
	agonyforce = 60	//same force as a stunbaton, but uses way more charge.
	hitcost = 2500	//runs off the same kind of big batteries as APCs, not small cells!
	attack_verb = list("poked")
	slot_flags = null
	grip_safety = FALSE

/obj/item/melee/baton/cattleprod/attackby(obj/item/W, mob/user)
	if(istype(W, /obj/item/cell))
		if(!istype(W, /obj/item/cell/device))
			if(!bcell)
				user.drop_item()
				W.loc = src
				bcell = W
				to_chat(user, span_notice("You install a cell in [src]."))
				update_icon()
			else
				to_chat(user, span_notice("[src] already has a cell."))
		else
			to_chat(user, span_notice("This cell is not fitted for [src]."))

/obj/item/melee/baton/get_description_interaction()
	var/list/results = list()

	if(bcell)
		results += "[desc_panel_image("offhand")]to remove the weapon cell."
	else
		results += "[desc_panel_image("weapon cell")]to add a new weapon cell."

	results += ..()

	return results

// Rare version of a baton that causes lesser lifeforms to really hate the user and attack them.
/obj/item/melee/baton/shocker
	name = "shocker"
	desc = "A device that appears to arc electricity into a target to incapacitate or otherwise hurt them, similar to a stun baton.  It looks inefficent."
	description_info = "Hitting a lesser lifeform with this while it is on will compel them to attack you above other nearby targets.  Otherwise \
	it works like a regular stun baton, just less effectively."
	icon_state = "shocker"
	force = 10
	throwforce = 5
	agonyforce = 25 // Less efficent than a regular baton.
	attack_verb = list("poked")

/obj/item/melee/baton/shocker/apply_hit_effect(mob/living/target, mob/living/user, var/hit_zone)
	..(target, user, hit_zone)
	if(status && target.has_AI())
		target.taunt(user)
