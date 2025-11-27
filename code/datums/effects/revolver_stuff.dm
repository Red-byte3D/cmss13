/datum/effects/revolver_damage_stacks

effect_name = "heavy exhaustion stacks"
duration = null
flags = DEL_ON_DEATH | INF_DURATION


var/stack_count = 1
var/max_stacks = 3
COOLDOWN_DECLARE(stack_reset)
COOLDOWN_DECLARE(stack_)

/datum/effects/revolver_damage_stacks/New(mob/living/carbon/human/H, mob/from = null, last_dmg_source = null, zone = "chest")
	COOLDOWN_START(src, stack_reset, 5 SECONDS)
	. = ..(H, from, last_dmg_source, zone)


/datum/effects/revolver_damage_stacks/validate_atom(mob/living/carbon/shot_target)
	if (shot_target.stat == DEAD)
		return FALSE

	return ..()


/datum/effects/revolver_damage_stacks/process_mob()
	. = ..()

	if(!iscarbon(affected_atom))
		return


	if(COOLDOWN_FINISHED(src, stack_reset))
		stack_count = 0

		if(stack_count <= 0)
			qdel(src)
			return

	var/mob/living/carbon/target_shot = affected_atom
	affected_atom.overlays += image('icons/mob/xenonids/effects.dmi', "acid2")
