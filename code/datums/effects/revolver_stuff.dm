/datum/effects/revolver_damage_stacks

	effect_name = "heavy exhaustion stacks"
	duration = null
	flags = DEL_ON_DEATH | INF_DURATION


	var/stack_count = 1
	var/max_stacks = 3
	var/last_decrement_time = 0
	var/time_between_decrements = 40
	var/last_increment_time = 0
	var/increment_grace_time = 50
	COOLDOWN_DECLARE(stack_reset)

/datum/effects/revolver_damage_stacks/New(mob/living/carbon/human/H, mob/from = null, last_dmg_source = null, zone = "chest")
	COOLDOWN_START(src, stack_reset, 5 SECONDS)
	. = ..(H, from, last_dmg_source, zone)


/datum/effects/revolver_damage_stacks/validate_atom(mob/living/carbon/shot_target)
	if (shot_target.stat == DEAD)
		return FALSE

	return ..()

/datum/effects/revolver_damage_stacks/process_mob()
	. = ..()
	var/mob/living/carbon/target_shot = affected_atom



	if(!iscarbon(target_shot))
		return

	target_shot.overlays += image('icons/mob/xenonids/effects.dmi', "revolver_1")


	if(COOLDOWN_FINISHED(src, stack_reset))
		stack_count = 0

		if(stack_count <= 0)
			affected_atom.overlays -= image('icons/mob/xenonids/effects.dmi', "acid2")
			qdel(src)
			return

/datum/effects/revolver_damage_stacks/proc/increment_stack_count()
	var/stun_duration = 1 SECONDS

	if(!iscarbon(affected_atom))
		return

	var/mob/living/carbon/targetted_mob = affected_atom
	stack_count++

	if(stack_count == 2)
		targetted_mob.apply_effect(0.5 SECONDS, SLOW)
	if(stack_count == 3)
		targetted_mob.apply_effect(0.5 SECONDS, WEAKEN)
