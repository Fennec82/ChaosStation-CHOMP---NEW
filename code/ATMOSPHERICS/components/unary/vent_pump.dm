#define DEFAULT_PRESSURE_DELTA 10000

#define EXTERNAL_PRESSURE_BOUND ONE_ATMOSPHERE
#define INTERNAL_PRESSURE_BOUND 0
#define PRESSURE_CHECKS 1

#define PRESSURE_CHECK_EXTERNAL 1
#define PRESSURE_CHECK_INTERNAL 2

/obj/machinery/atmospherics/unary/vent_pump
	icon = 'icons/atmos/vent_pump.dmi'
	icon_state = "map_vent"
	pipe_state = "uvent"

	name = "Air Vent"
	desc = "Has a valve and pump attached to it"
	use_power = USE_POWER_OFF
	idle_power_usage = 150		//internal circuitry, friction losses and stuff
	power_rating = 30000			//7500 W ~ 10 HP //VOREStation Edit - 30000 W

	connect_types = CONNECT_TYPE_REGULAR|CONNECT_TYPE_SUPPLY //connects to regular and supply pipes
	blocks_emissive = FALSE

	var/area/initial_loc
	level = 1
	var/area_uid
	var/id_tag = null

	var/pump_direction = 1 //0 = siphoning, 1 = releasing

	var/external_pressure_bound = EXTERNAL_PRESSURE_BOUND
	var/internal_pressure_bound = INTERNAL_PRESSURE_BOUND

	var/pressure_checks = PRESSURE_CHECKS
	//1: Do not pass external_pressure_bound
	//2: Do not pass internal_pressure_bound
	//3: Do not pass either

	// Used when handling incoming radio signals requesting default settings
	var/external_pressure_bound_default = EXTERNAL_PRESSURE_BOUND
	var/internal_pressure_bound_default = INTERNAL_PRESSURE_BOUND
	var/pressure_checks_default = PRESSURE_CHECKS

	var/frequency = 1439
	var/datum/radio_frequency/radio_connection

	var/radio_filter_out
	var/radio_filter_in

	//var/datum/looping_sound/air_pump/soundloop
	var/static/start_sound = 'sound/machines/air_pump/airpumpstart.ogg'
	var/static/stop_sound = 'sound/machines/air_pump/airpumpshutdown.ogg'


/obj/machinery/atmospherics/unary/vent_pump/on
	use_power = USE_POWER_IDLE
	icon_state = "map_vent_out"

/obj/machinery/atmospherics/unary/vent_pump/aux
	icon_state = "map_vent_aux"
	icon_connect_type = "-aux"
	connect_types = CONNECT_TYPE_AUX //connects to aux pipes

/obj/machinery/atmospherics/unary/vent_pump/siphon
	pump_direction = 0

/obj/machinery/atmospherics/unary/vent_pump/siphon/on
	use_power = USE_POWER_IDLE
	icon_state = "map_vent_in"

/obj/machinery/atmospherics/unary/vent_pump/siphon/on/atmos
	use_power = USE_POWER_IDLE
	icon_state = "map_vent_in"
	external_pressure_bound = 0
	external_pressure_bound_default = 0
	internal_pressure_bound = 2000
	internal_pressure_bound_default = 2000
	pressure_checks = 2
	pressure_checks_default = 2

/obj/machinery/atmospherics/unary/vent_pump/Initialize(mapload)
	. = ..()

	air_contents.volume = ATMOS_DEFAULT_VOLUME_PUMP

	icon = null
	initial_loc = get_area(loc)
	area_uid = "\ref[initial_loc]"
	if (!id_tag)
		assign_uid()
		id_tag = num2text(uid)

/obj/machinery/atmospherics/unary/vent_pump/proc/update_area()
	initial_loc = get_area(loc)
	area_uid = "\ref[initial_loc]"
	assign_uid()
	id_tag = num2text(uid)


/obj/machinery/atmospherics/unary/vent_pump/Destroy()
	SSmachines.wake_vent(WEAKREF(src)) // So we are removed from hibernating list
	unregister_radio(src, frequency)
	if(initial_loc)
		initial_loc.air_vent_info -= id_tag
		initial_loc.air_vent_names -= id_tag
	//QDEL_NULL(soundloop)
	return ..()

/obj/machinery/atmospherics/unary/vent_pump/high_volume
	name = "Large Air Vent"
	power_channel = EQUIP
	power_rating = 45000	//15 kW ~ 20 HP //VOREStation Edit - 45000

/obj/machinery/atmospherics/unary/vent_pump/high_volume/aux
	icon_state = "map_vent_aux"
	icon_connect_type = "-aux"
	connect_types = CONNECT_TYPE_AUX //connects to aux pipes

/obj/machinery/atmospherics/unary/vent_pump/high_volume/Initialize(mapload)
	. = ..()
	air_contents.volume = ATMOS_DEFAULT_VOLUME_PUMP + 800

// VOREStation Edit Start - Wall mounted vents
/obj/machinery/atmospherics/unary/vent_pump/high_volume/wall_mounted
	name = "Wall Mounted Air Vent"

/obj/machinery/atmospherics/unary/vent_pump/high_volume/wall_mounted/can_unwrench()
	return FALSE // No way to construct these, so don't let them be removed.

// Return the air from the turf in "front" of us (opposite the way the pipe is facing)
/obj/machinery/atmospherics/unary/vent_pump/high_volume/wall_mounted/return_air()
	var/turf/T = get_step(src, GLOB.reverse_dir[dir])
	if(isnull(T))
		return ..()
	return T.return_air()

// VOREStation Edit End

/obj/machinery/atmospherics/unary/vent_pump/engine
	name = "Engine Core Vent"
	power_channel = ENVIRON
	power_rating = 30000	//15 kW ~ 20 HP

/obj/machinery/atmospherics/unary/vent_pump/engine/Initialize(mapload)
	. = ..()
	air_contents.volume = ATMOS_DEFAULT_VOLUME_PUMP + 500 //meant to match air injector

/obj/machinery/atmospherics/unary/vent_pump/update_icon(var/safety = 0)
	if(!check_icon_cache())
		return

	cut_overlays()

	var/vent_icon = "vent"

	var/turf/T = get_turf(src)
	if(!istype(T))
		return

	if(!T.is_plating() && node && node.level == 1 && istype(node, /obj/machinery/atmospherics/pipe))
		vent_icon += "h"

	if(welded)
		vent_icon += "weld"
		playsound(src, stop_sound, 25, ignore_walls = FALSE, preference = /datum/preference/toggle/air_pump_noise)

	else if(!use_power || !node || (stat & (NOPOWER|BROKEN)))
		vent_icon += "off"
		playsound(src, stop_sound, 25, ignore_walls = FALSE, preference = /datum/preference/toggle/air_pump_noise)
	else
		vent_icon += "[pump_direction ? "out" : "in"]"
		playsound(src, start_sound, 25, ignore_walls = FALSE, preference = /datum/preference/toggle/air_pump_noise)


	add_overlay(icon_manager.get_atmos_icon("device", , , vent_icon))

/obj/machinery/atmospherics/unary/vent_pump/update_underlays()
	if(..())
		underlays.Cut()
		var/turf/T = get_turf(src)
		if(!istype(T))
			return
		if(!T.is_plating() && node && node.level == 1 && istype(node, /obj/machinery/atmospherics/pipe))
			return
		else
			if(node)
				add_underlay(T, node, dir, node.icon_connect_type)
			else
				add_underlay(T,, dir)

/obj/machinery/atmospherics/unary/vent_pump/hide()
	update_icon()
	update_underlays()

/obj/machinery/atmospherics/unary/vent_pump/proc/can_pump()
	if(stat & (NOPOWER|BROKEN))
		return 0
	if(!use_power)
		return 0
	if(welded)
		return 0
	return 1

/obj/machinery/atmospherics/unary/vent_pump/process()
	..()

	if (!node)
		update_use_power(USE_POWER_OFF)
	if(!can_pump())
		return 0

	var/datum/gas_mixture/environment = return_air() // VOREStation Edit - Use our own proc

	var/power_draw = -1

	//Figure out the target pressure difference
	var/pressure_delta = get_pressure_delta(environment)
	//src.visible_message("DEBUG >>> [src]: pressure_delta = [pressure_delta]")

	if((environment.temperature || air_contents.temperature) && pressure_delta > 0.5)
		if(pump_direction) //internal -> external
			var/transfer_moles = calculate_transfer_moles(air_contents, environment, pressure_delta)
			power_draw = pump_gas(src, air_contents, environment, transfer_moles, power_rating)
		else //external -> internal
			var/transfer_moles = calculate_transfer_moles(environment, air_contents, pressure_delta, (network)? network.volume : 0)

			//limit flow rate from turfs
			transfer_moles = min(transfer_moles, environment.total_moles*air_contents.volume/environment.volume)	//group_multiplier gets divided out here
			power_draw = pump_gas(src, environment, air_contents, transfer_moles, power_rating)

	else
		//If we're in an area that is fucking ideal, and we don't have to do anything, chances are we won't next tick either so why redo these calculations?
		//JESUS FUCK.  THERE ARE LITERALLY 250 OF YOU MOTHERFUCKERS ON ZLEVEL ONE AND YOU DO THIS SHIT EVERY TICK WHEN VERY OFTEN THERE IS NO REASON TO

		if(pump_direction && pressure_checks == PRESSURE_CHECK_EXTERNAL && Master.iteration > 10)	//99% of all vents
			//Fucking hibernate because you ain't doing shit.
			SSmachines.hibernate_vent(src)

	if (power_draw >= 0)
		last_power_draw = power_draw
		use_power(power_draw)
		if(network)
			network.update = 1

	return 1

/obj/machinery/atmospherics/unary/vent_pump/proc/get_pressure_delta(datum/gas_mixture/environment)
	var/pressure_delta = DEFAULT_PRESSURE_DELTA
	var/environment_pressure = environment.return_pressure()

	if(pump_direction) //internal -> external
		if(pressure_checks & PRESSURE_CHECK_EXTERNAL)
			pressure_delta = min(pressure_delta, external_pressure_bound - environment_pressure) //increasing the pressure here
		if(pressure_checks & PRESSURE_CHECK_INTERNAL)
			pressure_delta = min(pressure_delta, air_contents.return_pressure() - internal_pressure_bound) //decreasing the pressure here
	else //external -> internal
		if(pressure_checks & PRESSURE_CHECK_EXTERNAL)
			pressure_delta = min(pressure_delta, environment_pressure - external_pressure_bound) //decreasing the pressure here
		if(pressure_checks & PRESSURE_CHECK_INTERNAL)
			pressure_delta = min(pressure_delta, internal_pressure_bound - air_contents.return_pressure()) //increasing the pressure here

	return pressure_delta

/obj/machinery/atmospherics/unary/vent_pump/proc/broadcast_status()
	if(!radio_connection)
		return 0

	var/datum/signal/signal = new
	signal.transmission_method = TRANSMISSION_RADIO //radio signal
	signal.source = src

	signal.data = list(
		"area" = src.area_uid,
		"tag" = src.id_tag,
		"device" = "AVP",
		"power" = use_power,
		"direction" = pump_direction?("release"):("siphon"),
		"checks" = pressure_checks,
		"internal" = internal_pressure_bound,
		"external" = external_pressure_bound,
		"timestamp" = world.time,
		"sigtype" = "status",
		"power_draw" = last_power_draw,
		"flow_rate" = last_flow_rate,
	)

	if(!initial_loc.air_vent_names[id_tag])
		var/new_name = "[initial_loc.name] Vent Pump #[initial_loc.air_vent_names.len+1]"
		initial_loc.air_vent_names[id_tag] = new_name
		src.name = new_name
	initial_loc.air_vent_info[id_tag] = signal.data

	radio_connection.post_signal(src, signal, radio_filter_out)

	return 1


/obj/machinery/atmospherics/unary/vent_pump/atmos_init()
	..()

	//some vents work his own special way
	radio_filter_in = frequency==1439?(RADIO_FROM_AIRALARM):null
	radio_filter_out = frequency==1439?(RADIO_TO_AIRALARM):null
	if(frequency)
		set_frequency(frequency)

/obj/machinery/atmospherics/unary/vent_pump/proc/set_frequency(new_frequency)
	radio_connection = register_radio(src, frequency, new_frequency, radio_filter_in)
	frequency = new_frequency
	broadcast_status()

/obj/machinery/atmospherics/unary/vent_pump/receive_signal(datum/signal/signal)
	if(stat & (NOPOWER|BROKEN))
		return

	SSmachines.wake_vent(WEAKREF(src))

	//log_admin("DEBUG \[[world.timeofday]\]: /obj/machinery/atmospherics/unary/vent_pump/receive_signal([signal.debug_print()])")
	if(!signal.data["tag"] || (signal.data["tag"] != id_tag) || (signal.data["sigtype"]!="command"))
		return 0

	if(signal.data["purge"] != null)
		pressure_checks &= ~1
		pump_direction = 0

	if(signal.data["stabalize"] != null)
		pressure_checks |= 1
		pump_direction = 1

	if(signal.data["power"] != null)
		update_use_power(text2num(signal.data["power"]))

	if(signal.data["power_toggle"] != null)
		update_use_power(!use_power)

	if(signal.data["checks"] != null)
		if (signal.data["checks"] == "default")
			pressure_checks = pressure_checks_default
		else
			pressure_checks = text2num(signal.data["checks"])

	if(signal.data["checks_toggle"] != null)
		pressure_checks = (pressure_checks?0:3)

	if(signal.data["direction"] != null)
		pump_direction = text2num(signal.data["direction"])

	if(signal.data["set_internal_pressure"] != null)
		if (signal.data["set_internal_pressure"] == "default")
			internal_pressure_bound = internal_pressure_bound_default
		else
			internal_pressure_bound = between(0,text2num(signal.data["set_internal_pressure"]),ONE_ATMOSPHERE*50)

	if(signal.data["set_external_pressure"] != null)
		if (signal.data["set_external_pressure"] == "default")
			external_pressure_bound = external_pressure_bound_default
		else
			external_pressure_bound = between(0,text2num(signal.data["set_external_pressure"]),ONE_ATMOSPHERE*50)

	if(signal.data["adjust_internal_pressure"] != null)
		internal_pressure_bound = between(0,internal_pressure_bound + text2num(signal.data["adjust_internal_pressure"]),ONE_ATMOSPHERE*50)

	if(signal.data["adjust_external_pressure"] != null)
		external_pressure_bound = between(0,external_pressure_bound + text2num(signal.data["adjust_external_pressure"]),ONE_ATMOSPHERE*50)

	if("reset_external_pressure" in signal.data)
		external_pressure_bound = ONE_ATMOSPHERE

	if("reset_internal_pressure" in signal.data)
		internal_pressure_bound = 0

	if(signal.data["init"] != null)
		name = signal.data["init"]
		return

	if(signal.data["status"] != null)
		addtimer(CALLBACK(src, PROC_REF(broadcast_status)), 2, TIMER_DELETE_ME)
		return //do not update_icon

		//log_admin("DEBUG \[[world.timeofday]\]: vent_pump/receive_signal: unknown command \"[signal.data["command"]]\"\n[signal.debug_print()]")
	addtimer(CALLBACK(src, PROC_REF(broadcast_status)), 2, TIMER_DELETE_ME)
	update_icon()
	return

/obj/machinery/atmospherics/unary/vent_pump/attackby(obj/item/W, mob/user)
	if(W.has_tool_quality(TOOL_WELDER))
		var/obj/item/weldingtool/WT = W.get_welder()
		if (WT.remove_fuel(0,user))
			to_chat(user, span_notice("Now welding the vent."))
			if(do_after(user, 20 * WT.toolspeed))
				if(!src || !WT.isOn()) return
				playsound(src, WT.usesound, 50, 1)
				if(!welded)
					user.visible_message(span_bold("\The [user]") + " welds the vent shut.", span_notice("You weld the vent shut."), "You hear welding.")
					welded = 1
					update_icon()
				else
					user.visible_message(span_notice("[user] unwelds the vent."), span_notice("You unweld the vent."), "You hear welding.")
					welded = 0
					update_icon()
			else
				to_chat(user, span_notice("The welding tool needs to be on to start this task."))
		else
			to_chat(user, span_warning("You need more welding fuel to complete this task."))
			return 1
	if(W.has_tool_quality(TOOL_MULTITOOL))
		var/choice = tgui_alert(user, "[src] has an ID of \"[id_tag]\" and a frequency of [frequency]. What would you like to change?", "[src] ID", list("ID Tag", "Frequency", "Nothing"))
		switch(choice)
			if("ID Tag")
				var/new_id = tgui_input_text(user, "[src] has an ID of \"[id_tag]\". What would you like it to be?", "[src] ID", id_tag, 30, FALSE, TRUE)
				if(new_id)
					id_tag = new_id

			if("Frequency")
				var/new_frequency = tgui_input_number(user, "[src] has a frequency of [frequency]. What would you like it to be?", "[src] frequency", frequency, RADIO_HIGH_FREQ, RADIO_LOW_FREQ)
				if(new_frequency)
					new_frequency = sanitize_frequency(new_frequency, RADIO_LOW_FREQ, RADIO_HIGH_FREQ)
					set_frequency(new_frequency)
		return TRUE
	else
		..()

/obj/machinery/atmospherics/unary/vent_pump/examine(mob/user)
	. = ..()
	if(Adjacent(user))
		. += "A small gauge in the corner reads [round(last_flow_rate, 0.1)] L/s; [round(last_power_draw)] W"
	else
		. += "You are too far away to read the gauge."
	if(welded)
		. += "It seems welded shut."

/obj/machinery/atmospherics/unary/vent_pump/power_change()
	var/old_stat = stat
	..()
	if(old_stat != stat)
		update_icon()

/obj/machinery/atmospherics/unary/vent_pump/attackby(var/obj/item/W as obj, var/mob/user as mob)
	if (!W.has_tool_quality(TOOL_WRENCH))
		return ..()
	if (!(stat & NOPOWER) && use_power)
		to_chat(user, span_warning("You cannot unwrench \the [src], turn it off first."))
		return 1
	var/turf/T = src.loc
	if (node && node.level==1 && isturf(T) && !T.is_plating())
		to_chat(user, span_warning("You must remove the plating first."))
		return 1
	if(!can_unwrench())
		to_chat(user, span_warning("You cannot unwrench \the [src], it is too exerted due to internal pressure."))
		add_fingerprint(user)
		return 1
	playsound(src, W.usesound, 50, 1)
	to_chat(user, span_notice("You begin to unfasten \the [src]..."))
	if (do_after(user, 40 * W.toolspeed))
		user.visible_message( \
			span_infoplain(span_bold("\The [user]") + " unfastens \the [src]."), \
			span_notice("You have unfastened \the [src]."), \
			"You hear a ratchet.")
		deconstruct()

#undef DEFAULT_PRESSURE_DELTA

#undef EXTERNAL_PRESSURE_BOUND
#undef INTERNAL_PRESSURE_BOUND
#undef PRESSURE_CHECKS

#undef PRESSURE_CHECK_EXTERNAL
#undef PRESSURE_CHECK_INTERNAL
