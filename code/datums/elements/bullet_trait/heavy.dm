/datum/element/bullet_trait_heavy

	element_flags =  ELEMENT_DETACH|ELEMENT_BESPOKE
	id_arg_index = 2

/datum/element/bullet_trait_heavy/Attach(datum/target, heavy_stacks = 1)
	. = ..()
	if(!istype(target, /obj/projectile))
		return ELEMENT_INCOMPATIBLE

	RegisterSignal(target, COMSIG_BULLET_ACT_LIVING, PROC_REF(add_stacks), override = TRUE)


/datum/element/bullet_trait_heavy/proc/add_stacks(datum/target, mob/living/projectile_target, damage, damage_actual)
	SIGNAL_HANDLER

	var/mob/living/carbon/target_shot = projectile_target



/datum/component/status_effect/heavy_stun_build

	dupe_mode = COMPONENT_DUPE_UNIQUE_PASSARGS
	var/heavy_stacks = 0
	var/heavy_icon
	var/max_stacks = 3

/datum/component/status_effect/heavy_stun_build/Initialize(heavy_stacks, max_stacks = 3)
	. = ..()
	src.heavy_stacks = heavy_stacks
	src.max_stacks = max_stacks


/datum/component/status_effect/heavy_stun_build/process(delta_time)
	var/atom/parent_atom = parent

	if(isxeno(parent))
		var/mob/living/carbon/xenomorph/target_atom = parent_atom
		if(target_atom.tier > 2)
			return ..()
		target_atom.add_stacks()
		to_chat(world, SPAN_NOTICE("Hit"))


/datum/component/status_effect/heavy_stun_build/proc/add_stacks()
	heavy_stacks++

