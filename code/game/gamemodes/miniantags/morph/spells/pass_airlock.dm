// TODO refactor when spell code is component based instead of OO based
/obj/effect/proc_holder/spell/morph_spell/pass_airlock
	name = "Pass Airlock"
	desc = "Reform yourself so you can fit through a non bolted airlock. Takes a while to do and can only be used in a non disguised form."
	action_background_icon_state = "bg_morph"
	action_icon_state = "morph_airlock"
	clothes_req = FALSE
	charge_max = 10 SECONDS
	selection_activated_message = span_sinister("Click on an airlock to try pass it.")

/obj/effect/proc_holder/spell/morph_spell/pass_airlock/create_new_targeting()
	var/datum/spell_targeting/click/T = new
	T.range = 1
	T.allowed_type = /obj/machinery/door/airlock
	T.click_radius = -1
	return T


/obj/effect/proc_holder/spell/morph_spell/pass_airlock/can_cast(mob/living/simple_animal/hostile/morph/user, charge_check, show_message)
	. = ..()
	if(!.)
		return

	if(user.morphed)
		if(show_message)
			to_chat(user, span_warning("You can only pass through airlocks in your true form!"))
		return FALSE

/obj/effect/proc_holder/spell/morph_spell/pass_airlock/cast(list/targets, mob/living/simple_animal/hostile/morph/user)
	var/obj/machinery/door/airlock/A = targets[1]
	if(A.locked)
		to_chat(user, span_warning("[A] is bolted shut! You're unable to create a crack to pass through!"))
		revert_cast(user)
		return
	user.visible_message(span_warning("[user] starts pushing itself against [A]!"), span_sinister("You try to pry [A] open enough to get through."))
	if(!do_after(user, 6 SECONDS, FALSE, user, TRUE, list(CALLBACK(src, .proc/pass_check, user, A)), FALSE))
		if(user.morphed)
			to_chat(user, span_warning("You need to stay in your true form to pass through [A]!"))
		else if(A.locked)
			to_chat(user, span_warning("[A] is bolted shut! You're unable to create a crack to pass through!"))
		else
			to_chat(user, span_warning("You need to stay still to pass through [A]!"))
		revert_cast(user)
		return

	user.visible_message(span_warning("[user] briefly opens [A] slightly and passes through!"), span_sinister("You slide through the open crack in [A]."))
	user.forceMove(A.loc) // Move into the turf of the airlock


/obj/effect/proc_holder/spell/morph_spell/pass_airlock/proc/pass_check(mob/living/simple_animal/hostile/morph/user, obj/machinery/door/airlock/A)
	return user.morphed || A.locked
