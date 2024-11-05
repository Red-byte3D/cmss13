/datum/action/xeno_action/activable/raise_servant
	name = "Raise Servant"
	ability_name = "raise servant"
	action_icon_state = "unburrow"
	macro_path = /datum/action/xeno_action/verb/verb_raise_servant
	action_type = XENO_ACTION_CLICK
	ability_primacy = XENO_PRIMARY_ACTION_3
	xeno_cooldown = 20 SECONDS
	plasma_cost = 100
	var/resin_cost = 200
	var/creattime = 10 SECONDS
	var/pause_duration = 20 SECONDS

/datum/action/xeno_action/activable/weed_nade
	name = "Lob Resin"
	action_icon_state = "prae_dodge"
	plasma_cost = 300
	action_type = XENO_ACTION_CLICK
	xeno_cooldown = 10 SECONDS

	var/explode_delay = 1 SECONDS
	var/priming_delay = 1 SECONDS

/datum/action/xeno_action/activable/martyr_reaper
	name = "Martyr"
	action_icon_state = "prae_dodge"
	plasma_cost = 150
	action_type = XENO_ACTION_CLICK
	xeno_cooldown = 5

