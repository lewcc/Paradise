/mob/living/simple_animal/mouse
	name = "mouse"
	real_name = "mouse"
	desc = "It's a small, disease-ridden rodent."
	icon_state = "mouse_gray"
	icon_living = "mouse_gray"
	icon_dead = "mouse_gray_dead"
	icon_resting = "mouse_gray_sleep"
	speak = list("Squeek!","SQUEEK!","Squeek?")
	speak_emote = list("squeeks","squeaks","squiks")
	emote_hear = list("squeeks","squeaks","squiks")
	emote_see = list("runs in a circle", "shakes", "scritches at something")
	var/squeak_sound = 'sound/creatures/mousesqueak.ogg'
	speak_chance = 1
	turns_per_move = 5
	see_in_dark = 6
	maxHealth = 5
	health = 5
	butcher_results = list(/obj/item/reagent_containers/food/snacks/meat = 1)
	response_help  = "pets"
	response_disarm = "gently pushes aside"
	response_harm   = "stamps on"
	density = 0
	ventcrawler = 2
	pass_flags = PASSTABLE | PASSGRILLE | PASSMOB
	mob_biotypes = MOB_ORGANIC | MOB_BEAST
	mob_size = MOB_SIZE_TINY
	var/mouse_color //brown, gray and white, leave blank for random
	layer = MOB_LAYER
	atmos_requirements = list("min_oxy" = 16, "max_oxy" = 0, "min_tox" = 0, "max_tox" = 1, "min_co2" = 0, "max_co2" = 5, "min_n2" = 0, "max_n2" = 0)
	minbodytemp = 223		//Below -50 Degrees Celcius
	maxbodytemp = 323	//Above 50 Degrees Celcius
	universal_speak = 0
	can_hide = 1
	holder_type = /obj/item/holder/mouse
	can_collar = 1
	gold_core_spawnable = FRIENDLY_SPAWN
	var/chew_probability = 1

/mob/living/simple_animal/mouse/Initialize(mapload)
	. = ..()
	AddComponent(/datum/component/squeak, list('sound/creatures/mousesqueak.ogg' = 1), 100, extrarange = SHORT_RANGE_SOUND_EXTRARANGE) //as quiet as a mouse or whatever

/mob/living/simple_animal/mouse/handle_automated_action()
	if(prob(chew_probability) && isturf(loc))
		var/turf/simulated/floor/F = get_turf(src)
		if(istype(F) && !F.intact)
			var/obj/structure/cable/C = locate() in F
			if(C && prob(15))
				if(C.avail() && !HAS_TRAIT(src, TRAIT_SHOCKIMMUNE))
					visible_message(span_warning("[src] chews through [C]. It's toast!"))
					playsound(src, 'sound/effects/sparks2.ogg', 100, 1)
					toast() // mmmm toasty.
				else
					visible_message(span_warning("[src] chews through [C]."))
				investigate_log("was chewed through by a mouse in [get_area(F)]([F.x], [F.y], [F.z] - [ADMIN_JMP(F)])","wires")
				C.deconstruct()

/mob/living/simple_animal/mouse/handle_automated_speech()
	..()
	if(prob(speak_chance) && !incapacitated())
		playsound(src, squeak_sound, 100, 1)

/mob/living/simple_animal/mouse/handle_automated_movement()
	. = ..()
	if(IS_HORIZONTAL(src))
		if(prob(1))
			stand_up()
		else if(prob(5))
			custom_emote(EMOTE_AUDIBLE, "snuffles")
	else if(prob(0.5))
		lay_down()

/mob/living/simple_animal/mouse/New()
	..()
	if(!mouse_color)
		mouse_color = pick( list("brown","gray","white") )
	icon_state = "mouse_[mouse_color]"
	icon_living = "mouse_[mouse_color]"
	icon_dead = "mouse_[mouse_color]_dead"
	icon_resting = "mouse_[mouse_color]_sleep"
	desc = "It's a small [mouse_color] rodent, often seen hiding in maintenance areas and making a nuisance of itself."

/mob/living/simple_animal/mouse/attack_hand(mob/living/carbon/human/M as mob)
	if(M.a_intent == INTENT_HELP)
		get_scooped(M, TRUE)
	..()

/mob/living/simple_animal/mouse/start_pulling(atom/movable/AM, state, force = pull_force, show_message = FALSE)//Prevents mouse from pulling things
	if(istype(AM, /obj/item/reagent_containers/food/snacks/cheesewedge))
		return ..() // Get dem
	if(show_message)
		to_chat(src, span_warning("You are too small to pull anything except cheese."))
	return

/mob/living/simple_animal/mouse/Crossed(AM as mob|obj, oldloc)
	if(ishuman(AM))
		if(!stat)
			var/mob/M = AM
			to_chat(M, span_notice("[bicon(src)] Squeek!"))
	..()

/mob/living/simple_animal/mouse/proc/toast()
	add_atom_colour("#3A3A3A", FIXED_COLOUR_PRIORITY)
	desc = "It's toast."
	death()

/mob/living/simple_animal/mouse/proc/splat()
	icon_dead = "mouse_[mouse_color]_splat"
	icon_state = "mouse_[mouse_color]_splat"

/mob/living/simple_animal/mouse/death(gibbed)
	// Only execute the below if we successfully died
	playsound(src, squeak_sound, 40, 1)
	. = ..(gibbed)
	if(!.)
		return FALSE
	layer = MOB_LAYER
	if(client)
		client.time_died_as_mouse = world.time

/*
 * Mouse types
 */

/mob/living/simple_animal/mouse/white
	mouse_color = "white"
	icon_state = "mouse_white"

/mob/living/simple_animal/mouse/gray
	mouse_color = "gray"
	icon_state = "mouse_gray"

/mob/living/simple_animal/mouse/brown
	mouse_color = "brown"
	icon_state = "mouse_brown"

//TOM IS ALIVE! SQUEEEEEEEE~K :)
/mob/living/simple_animal/mouse/brown/Tom
	name = "Tom"
	real_name = "Tom"
	desc = "Jerry the cat is not amused."
	response_help  = "pets"
	response_disarm = "gently pushes aside"
	response_harm   = "splats"
	unique_pet = TRUE
	gold_core_spawnable = NO_SPAWN

/mob/living/simple_animal/mouse/brown/Tom/Initialize(mapload)
	. = ..()
	// Tom fears no cable.
	ADD_TRAIT(src, TRAIT_SHOCKIMMUNE, SPECIES_TRAIT)

/mob/living/simple_animal/mouse/blobinfected
	maxHealth = 100
	health = 100
	atmos_requirements = list("min_oxy" = 0, "max_oxy" = 0, "min_tox" = 0, "max_tox" = 0, "min_co2" = 0, "max_co2" = 0, "min_n2" = 0, "max_n2" = 0)
	minbodytemp = 0
	gold_core_spawnable = NO_SPAWN
	var/cycles_alive = 0
	var/cycles_limit = 60
	var/has_burst = FALSE

/mob/living/simple_animal/mouse/blobinfected/Life()
	cycles_alive++
	var/timeleft = (cycles_limit - cycles_alive) * 2
	if(ismob(loc)) // if someone ate it, burst immediately
		burst(FALSE)
	else if(timeleft < 1) // if timer expired, burst.
		burst(FALSE)
	else if(cycles_alive % 2 == 0) // give the mouse/player a countdown reminder every 2 cycles
		to_chat(src, span_warning("[timeleft] seconds until you burst, and become a blob..."))
	return ..()

/mob/living/simple_animal/mouse/blobinfected/death(gibbed)
	burst(gibbed)
	return ..(gibbed)

/mob/living/simple_animal/mouse/blobinfected/proc/burst(gibbed)
	if(has_burst)
		return FALSE
	var/turf/T = get_turf(src)
	if(!is_station_level(T.z) || isspaceturf(T))
		to_chat(src, "<span class='userdanger'>You feel ready to burst, but this isn't an appropriate place!  You must return to the station!</span>")
		return FALSE
	has_burst = TRUE
	var/datum/mind/blobmind = mind
	var/client/C = client
	if(istype(blobmind) && istype(C))
		var/obj/structure/blob/core/core = new(T, C, 3)
		core.lateblobtimer()
		qdel(blobmind) // Delete the old mind. THe blob will make a new one
	else
		new /obj/structure/blob/core(T) // Ghosts will be prompted to control it.
	if(ismob(loc)) // in case some taj/etc ate the mouse.
		var/mob/M = loc
		M.gib()
	if(!gibbed)
		gib()

/mob/living/simple_animal/mouse/blobinfected/get_scooped(mob/living/carbon/grabber)
	to_chat(grabber, span_warning("You try to pick up [src], but they slip out of your grasp!"))
	to_chat(src, span_warning("[src] tries to pick you up, but you wriggle free of their grasp!"))

/mob/living/simple_animal/mouse/decompile_act(obj/item/matter_decompiler/C, mob/user)
	if(!(istype(user, /mob/living/silicon/robot/drone)))
		user.visible_message(span_notice("[user] sucks [src] into its decompiler. There's a horrible crunching noise."), \
		span_warning("It's a bit of a struggle, but you manage to suck [src] into your decompiler. It makes a series of visceral crunching noises."))
		new/obj/effect/decal/cleanable/blood/splatter(get_turf(src))
		C.stored_comms["wood"] += 2
		C.stored_comms["glass"] += 2
		qdel(src)
		return TRUE
	return ..()
