/mob/dead/observer/DblClickOn(atom/A, params)
	if(check_click_intercept(params, A))
		return

	if(can_reenter_corpse && mind && mind.current)
		if(A == mind.current || (mind.current in A)) // double click your corpse or whatever holds it
			reenter_corpse()						// (cloning scanner, body bag, closet, mech, etc)
			return									// seems legit.

	// Things you might plausibly want to follow
	if(ismovableatom(A))
		ManualFollow(A)

	// Otherwise jump
	else if(A.loc)
		abstract_move(get_turf(A))
		update_parallax_contents()

/mob/dead/observer/ClickOn(var/atom/A, var/params)
	if(check_click_intercept(params,A))
		return

	var/list/modifiers = params2list(params)
	if(modifiers["shift"] && modifiers["middle"])
		ShiftMiddleClickOn(A)
		return
	if(modifiers["shift"] && modifiers["ctrl"])
		CtrlShiftClickOn(A)
		return
	if(modifiers["middle"])
		MiddleClickOn(A)
		return
	if(modifiers["shift"])
		ShiftClickOn(A)
		return
	if(modifiers["alt"])
		AltClickOn(A)
		return
	if(modifiers["ctrl"])
		CtrlClickOn(A)
		return

	if(world.time <= next_move)
		return
	// You are responsible for checking config.ghost_interaction when you override this function
	// Not all of them require checking, see below
	A.attack_ghost(src)

// Oh by the way this didn't work with old click code which is why clicking shit didn't spam you
/atom/proc/attack_ghost(mob/dead/observer/user)
	if(SEND_SIGNAL(src, COMSIG_ATOM_ATTACK_GHOST, user) & COMPONENT_NO_ATTACK_HAND)
		return TRUE
	if(user.client)
		if(user.gas_scan && atmosanalyzer_scan(user, src))
			return TRUE
		else if(IsAdminGhost(user))
			attack_ai(user)
		else if(user.client.prefs.inquisitive_ghost)
			user.examinate(src)
	return FALSE

/mob/living/attack_ghost(mob/dead/observer/user)
	if(user.client && user.health_scan)
		healthscan(user, src, 1, TRUE)
		chemscan(user, src, 1, TRUE)
	return ..()

// ---------------------------------------
// And here are some good things for free:
// Now you can click through portals, wormholes, gateways, and teleporters while observing. -Sayu

/obj/machinery/gateway/centerstation/attack_ghost(mob/user)
	if(awaygate)
		user.abstract_move(awaygate.loc)
	else
		to_chat(user, "[src] has no destination.")
	return ..()

/obj/machinery/gateway/centeraway/attack_ghost(mob/user)
	if(stationgate)
		user.abstract_move(stationgate.loc)
	else
		to_chat(user, "[src] has no destination.")
	return ..()

/obj/machinery/teleport/hub/attack_ghost(mob/user)
	if(!power_station?.engaged || !power_station.teleporter_console || !power_station.teleporter_console.target_ref)
		return ..()

	var/atom/target = power_station.teleporter_console.target_ref.resolve()
	if(!target)
		power_station.teleporter_console.target_ref = null
		return ..()

	user.abstract_move(get_turf(target))
