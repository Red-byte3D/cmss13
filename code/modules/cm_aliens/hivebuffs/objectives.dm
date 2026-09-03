/obj/effect/landmark/xeno_objective_spawn/Initialize(mapload, ...)
	. = ..()
	GLOB.xeno_objective_landmarks += src
	if(mapload)
		addtimer(CALLBACK(src, PROC_REF(announce_incoming)), rand(2 MINUTES, 3 MINUTES))

/obj/effect/landmark/xeno_objective_spawn/proc/announce_incoming()
	if(!length(GLOB.xeno_objective_landmarks))
		return

	var/obj/effect/landmark/xeno_objective_spawn/chosen = pick(GLOB.xeno_objective_landmarks)

	for(var/obj/effect/landmark/xeno_objective_spawn/other_landmark in GLOB.xeno_objective_landmarks)
		if(other_landmark != chosen)
			GLOB.xeno_objective_landmarks -= other_landmark
			qdel(other_landmark)

	var/area/objective_area = get_area(chosen)
	xeno_announcement(SPAN_XENOANNOUNCE("The weeds have given us a boon at [objective_area]. Move forward and claim it now.."), XENO_HIVE_NORMAL, XENO_GENERAL_ANNOUNCE)

	addtimer(CALLBACK(chosen, PROC_REF(spawn_objective)), 1 MINUTES)

/obj/effect/landmark/xeno_objective_spawn/proc/spawn_objective()
	for(var/turf/closed/wall/resin/resin_turf in range(2, src))
		resin_turf.ScrapeAway() // Theres no way this is the only way to do this. it sucks.

	new /obj/effect/alien/resin/xeno_objective(loc)
	GLOB.xeno_objective_landmarks -= src
	qdel(src)

// REWARDS, i put it here because i dont want to bloat the main files
/datum/action/xeno_action/activable/build_tunnel/queen
	name = "Dig Royal Tunnel"
	action_icon_state = "build_tunnel"
	plasma_cost = 0
	xeno_cooldown = 0
	action_type = XENO_ACTION_CLICK





/datum/action/xeno_action/activable/build_tunnel/queen/use_ability(atom/target_atom, mods)
	var/mob/living/carbon/xenomorph/queen/queen = owner

	. = ..()
	if(!istype(queen))
		return

	if(!queen.ovipositor)
		to_chat(queen, SPAN_XENOWARNING("We must be seated upon our ovipositor to do this."))
		return

	var/datum/hive_status/hive = queen.hive
	if(hive?.tunnel_used)
		to_chat(queen, SPAN_XENOWARNING("We already put down a tunnel."))
		return

	if(mods && mods[CLICK_CATCHER])
		return

	var/turf/target_turf = get_turf(target_atom)
	if(!target_turf)
		return

	var/area/target_area = get_area(target_turf)
	if(!target_turf.can_dig_xeno_tunnel() || !is_ground_level(target_turf.z) || target_area.flags_area & AREA_NOTUNNEL)
		to_chat(queen, SPAN_XENOWARNING("We cannot carve through that kind of floor."))
		return

	if(locate(/obj/structure/tunnel) in target_turf)
		to_chat(queen, SPAN_XENOWARNING("There already is a tunnel there."))
		return

	if(isnull(target_area) || !target_area.is_resin_allowed)
		to_chat(queen, SPAN_XENOWARNING("This area is unsuited to host the hive!"))
		return

	if(!do_after(queen, 10 SECONDS, INTERRUPT_ALL|BEHAVIOR_IMMOBILE, BUSY_ICON_BUILD))
		to_chat(queen, SPAN_WARNING("Our tunnel caves in as we stop plasing it."))
		return

	if(hive.tunnel_used)
		return

	new /obj/structure/tunnel(target_turf, queen.hivenumber)
	hive.tunnel_used = TRUE
	remove_action(queen, /datum/action/xeno_action/activable/build_tunnel/queen)

	xeno_message(SPAN_XENOANNOUNCE("The Queen has carved a royal tunnel at [get_area_name(target_turf)]."), 3, queen.hivenumber)

	return TRUE
