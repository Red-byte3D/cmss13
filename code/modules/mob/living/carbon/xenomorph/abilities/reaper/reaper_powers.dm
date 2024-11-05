/datum/action/xeno_action/activable/raise_servant/use_ability(atom/target)
	var/mob/living/carbon/xenomorph/xeno = owner
	var/datum/behavior_delegate/base_reaper/reaper = xeno.behavior_delegate

	var/turf/target_turf = get_turf(target)
	var/obj/effect/alien/weeds/target_weeds = locate(/obj/effect/alien/weeds) in target_turf

	if(length(reaper.servants) >= reaper.servant_max)
		for(var/mob/living/simple_animal/hostile/alien/rotdrone/rotxeno in reaper.servants)
			if(!can_see(xeno, target, 10))
				return
			if(target == xeno)
				servant_recall(rotxeno, xeno)
				to_chat(xeno, SPAN_XENONOTICE("We recall our servant."))
				return
			else if(iscarbon(target))
				var/mob/living/carbon/cartar = target
				if(cartar.stat == DEAD)
					to_chat(xeno, SPAN_XENONOTICE("They are dead, why do we want send our servant to them?"))
					return
				if(!xeno.can_not_harm(cartar))
					to_chat(xeno, SPAN_XENOWARNING("We order our servant to attack [cartar]!"))
					servant_attack(rotxeno, cartar)
					return
				else
					to_chat(xeno, SPAN_XENONOTICE("We order our servant to escort [cartar]."))
					servant_escort(rotxeno, cartar)
					return
			else if(isStructure(target))
				servant_moveto_structure(rotxeno, target)
				to_chat(xeno, SPAN_XENONOTICE("We order our servant to go to [target]."))
				return
			else if(isturf(target) || (target_weeds && istype(target_turf, /turf/open)))
				servant_moveto_turf(rotxeno, target)
				to_chat(xeno, SPAN_XENONOTICE("We order our servant to go to [target]."))
				return
			else
				to_chat(xeno, SPAN_XENOWARNING("We fail to give orders."))
				return

	if(!xeno.check_state())
		return

	if(!action_cooldown_check())
		return

	if(reaper.making_servant == TRUE)
		to_chat(xeno, SPAN_XENOWARNING("We are already making a servant!"))
		return

	if(reaper.flesh_resin < resin_cost)
		to_chat(xeno, SPAN_XENOWARNING("We don't have enough flesh resin!"))
		return

	if(!check_and_use_plasma_owner())
		return

	create_servant()
	reaper.flesh_resin -= resin_cost
	apply_cooldown()
	return ..()

/datum/action/xeno_action/activable/raise_servant/proc/create_servant(datum/action/xeno_action/activable/raise_servant/action_def, atom/target)
	var/mob/living/carbon/xenomorph/xeno = owner
	var/datum/behavior_delegate/base_reaper/reaper = xeno.behavior_delegate
	if(!xeno.check_state())
		return

	if(!istype(xeno))
		return

	xeno.visible_message(SPAN_XENOWARNING("[xeno] bends over and starts spewing large amounts of rancid, black ooze at it's feet, grasping at it as it cascades down!"), \
	SPAN_XENOWARNING("We regurgitate a mix of plasma and flesh resin, moulding it into a loyal servant!"))
	reaper.making_servant = TRUE

	if(!do_after(xeno, creattime, INTERRUPT_ALL|BEHAVIOR_IMMOBILE, ACTION_PURPLE_POWER_UP))
		reaper.making_servant = FALSE
		return

	xeno.visible_message(SPAN_XENOWARNING("As [xeno] rises, the lump of decomposing sludge shudders and grows, animating into a melting, odd-looking Drone!"), \
	SPAN_XENOWARNING("With much effort, we compel the mound of flesh resin to take shape and rise!"))
	var/mob/living/simple_animal/hostile/alien/rotdrone/rotxeno = new(xeno.loc, xeno)

	new_servant(rotxeno)
	reaper.making_servant = FALSE

/datum/action/xeno_action/activable/raise_servant/proc/new_servant(mob/living/simple_animal/hostile/alien/rotdrone/new_servant)
	var/mob/living/carbon/xenomorph/xeno = owner
	var/datum/behavior_delegate/base_reaper/reaper = xeno.behavior_delegate

	if(!istype(new_servant))
		return
	new_servant.alpha = 0
	animate(new_servant, alpha = 255, time = 2 SECONDS, easing = QUAD_EASING)
	playsound(new_servant, 'sound/voice/alien_roar_unused.ogg', 50, TRUE)

	RegisterSignal(new_servant, list(COMSIG_MOB_DEATH, COMSIG_PARENT_QDELETING), PROC_REF(remove_servant))
	reaper.servants += new_servant

/datum/action/xeno_action/activable/raise_servant/proc/remove_servant(datum/source)
	var/mob/living/carbon/xenomorph/xeno = owner
	var/datum/behavior_delegate/base_reaper/reaper = xeno.behavior_delegate
	SIGNAL_HANDLER
	to_chat(xeno, SPAN_XENOWARNING("We feel our servant has perished!"))
	reaper.servants -= source
	UnregisterSignal(source, list(COMSIG_MOB_DEATH, COMSIG_PARENT_QDELETING))

/datum/action/xeno_action/activable/raise_servant/proc/servant_recall(mob/living/simple_animal/hostile/alien/rotdrone/servant, mob/living/carbon/xenomorph/master)
	if(!istype(servant))
		return
	servant.got_orders = FALSE
	servant.is_fighting = FALSE
	walk_to(servant, master, rand(1, 2), 4)

/datum/action/xeno_action/activable/raise_servant/proc/servant_attack(mob/living/simple_animal/hostile/alien/rotdrone/servant, mob/living/carbon/target)
	if(!istype(servant))
		return
	servant.got_orders = TRUE
	servant.is_fighting = TRUE
	servant.mastertarget = target
	walk_to(servant, servant.mastertarget, 1, 4)

/datum/action/xeno_action/activable/raise_servant/proc/servant_escort(mob/living/simple_animal/hostile/alien/rotdrone/servant, mob/living/carbon/target)
	if(!istype(servant))
		return
	servant.got_orders = TRUE
	servant.escorting = TRUE
	servant.escort = target
	walk_to(servant, servant.escort, rand(1, 2), 4)

/datum/action/xeno_action/activable/raise_servant/proc/servant_moveto_turf(mob/living/simple_animal/hostile/alien/rotdrone/servant, turf/target)
	if(!istype(servant))
		return
	servant.got_orders = TRUE
	walk_to(servant, target, 0, 4)

/datum/action/xeno_action/activable/raise_servant/proc/servant_moveto_structure(mob/living/simple_animal/hostile/alien/rotdrone/servant, turf/target)
	if(!istype(servant))
		return
	servant.got_orders = TRUE
	walk_to(servant, target, 1, 4)


/datum/action/xeno_action/activable/martyr_reaper/use_ability(atom/target)
	var/mob/living/carbon/xenomorph/xeno = owner
	var/datum/behavior_delegate/base_reaper/reaper = xeno.behavior_delegate

	var/turf/target_turf = get_turf(target)
	var/obj/effect/alien/weeds/target_weeds = locate(/obj/effect/alien/weeds) in target_turf

	if(length(reaper.servants) >= reaper.servant_max)
		for(var/mob/living/simple_animal/hostile/alien/rotdrone/rotxeno in reaper.servants)
			if(!can_see(xeno, target, 10))
				return
			else if(isturf(target) || (target_weeds && istype(target_turf, /turf/open)))
				martyr_reaper_blowup(rotxeno, target)
				to_chat(xeno, SPAN_XENONOTICE("We order our servant to go to [target]."))
				return

	if(!xeno.check_state())
		return

	if(!action_cooldown_check())
		return

	if(!check_and_use_plasma_owner())
		return


	apply_cooldown()
	return ..()

/datum/action/xeno_action/activable/martyr_reaper/proc/martyr_reaper_blowup(mob/living/simple_animal/hostile/alien/rotdrone/servant, turf/target)
	if(!istype(servant))
		return
	servant.got_orders = TRUE
	walk_to(servant, target, 1, 1, 50)
