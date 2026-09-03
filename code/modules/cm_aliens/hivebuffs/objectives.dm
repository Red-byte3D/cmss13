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
