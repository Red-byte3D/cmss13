/obj/structure/machinery/embedded_controller
	var/datum/computer/file/embedded_program/program //the currently executing program

	name = "Embedded Controller"
	anchored = TRUE

	use_power = USE_POWER_IDLE
	idle_power_usage = 10

	var/on = 1

/obj/structure/machinery/embedded_controller/proc/post_signal(datum/signal/signal, comm_line)
	return 0

/obj/structure/machinery/embedded_controller/receive_signal(datum/signal/signal, receive_method, receive_param)
	if(!signal || signal.encryption)
		return

	if(program)
		program.receive_signal(signal, receive_method, receive_param)
			//spawn(5) program.process() //no, program.process sends some signals and machines respond and we here again and we lag -rastaf0

/obj/structure/machinery/embedded_controller/process()
	if(program)
		program.process()

	update_icon()
	src.updateDialog()

/obj/structure/machinery/embedded_controller/attack_remote(mob/user as mob)
	src.ui_interact(user)

/obj/structure/machinery/embedded_controller/attack_hand(mob/user as mob)
	src.ui_interact(user)

/obj/structure/machinery/embedded_controller/ui_interact()
	return

/obj/structure/machinery/embedded_controller/radio
	icon = 'icons/obj/structures/machinery/airlock_machines.dmi'
	icon_state = "airlock_control_standby"
	power_channel = POWER_CHANNEL_ENVIRON
	density = FALSE

	var/id_tag
	//var/radio_power_use = 50 //power used to xmit signals

	var/frequency = 1379
	var/radio_filter = null
	var/datum/radio_frequency/radio_connection
	unslashable = TRUE
	unacidable = TRUE

/obj/structure/machinery/embedded_controller/radio/Initialize()
	. = ..()
	set_frequency(frequency)

/obj/structure/machinery/embedded_controller/radio/Destroy()
	SSradio.remove_object(src, frequency)
	radio_connection = null
	return ..()

/obj/structure/machinery/embedded_controller/radio/update_icon()
	if(on && program)
		if(program.memory["processing"])
			icon_state = "airlock_control_process"
		else
			icon_state = "airlock_control_standby"
	else
		icon_state = "airlock_control_off"

/obj/structure/machinery/embedded_controller/radio/post_signal(datum/signal/signal, filter = null)
	signal.transmission_method = TRANSMISSION_RADIO
	if(radio_connection)
		//use_power(radio_power_use) //neat idea, but causes way too much lag.
		return radio_connection.post_signal(src, signal, filter)
	else
		qdel(signal)

/obj/structure/machinery/embedded_controller/radio/proc/set_frequency(new_frequency)
	SSradio.remove_object(src, frequency)
	frequency = new_frequency
	radio_connection = SSradio.add_object(src, frequency, radio_filter)
