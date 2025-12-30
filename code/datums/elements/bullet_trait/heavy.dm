/datum/element/bullet_trait_heavy

	element_flags =  ELEMENT_DETACH|ELEMENT_BESPOKE
	id_arg_index = 2

/datum/element/bullet_trait_heavy/Attach(datum/target, heavy_stacks = 1)
	. = ..()
	if(!istype(target, /obj/projectile))
		return ELEMENT_INCOMPATIBLE

	RegisterSignal(target, COMSIG_BULLET_ACT_LIVING, PROC_REF(add_stacks), override = TRUE)
	target.AddComponent(/datum/component/status_effect/heavy_stun_build)


/datum/element/bullet_trait_heavy/proc/add_stacks(datum/target, mob/living/projectile_target, damage, damage_actual)
	SIGNAL_HANDLER

	var/mob/living/carbon/target_shot = projectile_target

	target_shot.AddComponent(/datum/component/status_effect/heavy_stun_build)

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
		heavy_stacks++
		to_chat(world, SPAN_NOTICE("Hit"))


/datum/component/status_effect/heavy_stun_build/proc/add_stacks()
	heavy_stacks++



/datum/effects/heavy_revolver
	effect_name = "heavy revolver stacks"
	duration = null
	flags = DEL_ON_DEATH | INF_DURATION // We always clean ourselves up

	var/stack_count = 1
	var/max_stacks = 5

/datum/effects/heavy_revolver/New(mob/living/carbon/human/H, mob/from = null, last_dmg_source = null, zone = "chest")
	. = ..(H, from, last_dmg_source, zone)
	H.update_xeno_hostile_hud()


/datum/effects/heavy_revolver/validate_atom(mob/living/carbon/human/H)
	if (H.stat == DEAD)
		return FALSE

	return ..()

/datum/effects/heavy_revolver/process_mob()
	. = ..()
	if (!istype(affected_atom, /mob/living/carbon/human))
		return
	if (stack_count <= 0)
			qdel(src)
			return

	var/mob/living/carbon/human/H = affected_atom
	H.update_xeno_hostile_hud()


/datum/effects/heavy_revolver/Destroy()
	if (!ishuman(affected_atom))
		return ..()

	var/mob/living/carbon/human/human = affected_atom
	if(!QDELETED(human))
		addtimer(CALLBACK(human, TYPE_PROC_REF(/mob/living/carbon/human, update_xeno_hostile_hud)), 3)

	return ..()

/datum/effects/heavy_revolver/proc/increment_stack_count()


