//These objects are used in the cardinal sin-themed ruins (i.e. Gluttony, Pride...)

// Greed
/obj/structure/cursed_slot_machine //Greed's slot machine: Used in the Greed ruin. Deals clone damage on each use, with a successful use giving a d20 of fate.
	name = "greed's slot machine"
	desc = "High stakes, high rewards."
	icon = 'icons/obj/economy.dmi'
	icon_state = "slots-off"
	anchored = TRUE
	density = TRUE
	var/win_prob = 5

/obj/structure/cursed_slot_machine/attack_hand(mob/user)
	interact(user)

/obj/structure/cursed_slot_machine/interact(mob/living/carbon/human/user)
	if(!istype(user))
		return

	if(in_use)
		return

	in_use = TRUE
	user.adjustCloneLoss(20)
	if(user.stat)
		to_chat(user, span_userdanger("No... just one more try..."))
		user.gib()
	else
		user.visible_message(span_warning("[user] pulls [src]'s lever with a glint in [user.p_their()] eyes!"), "<span class='warning'>You feel a draining as you pull the lever, but you \
		know it'll be worth it.</span>")
	icon_state = "slots-on"
	playsound(src, 'sound/lavaland/cursed_slot_machine.ogg', 50, 0)
	addtimer(CALLBACK(src, .proc/determine_victor, user), 50)

/obj/structure/cursed_slot_machine/proc/determine_victor(mob/living/user)
	icon_state = "slots-off"
	in_use = FALSE
	if(prob(win_prob))
		playsound(src, 'sound/lavaland/cursed_slot_machine_jackpot.ogg', 50, 0)
		new/obj/structure/cursed_money(get_turf(src))
		if(user)
			to_chat(user, span_boldwarning("You've hit jackpot. Laughter echoes around you as your reward appears in the machine's place."))
		qdel(src)
	else
		if(user)
			to_chat(user, span_boldwarning("Fucking machine! Must be rigged. Still... one more try couldn't hurt, right?"))

/obj/structure/cursed_money
	name = "bag of money"
	desc = "RICH! YES! YOU KNEW IT WAS WORTH IT! YOU'RE RICH! RICH! RICH!"
	icon = 'icons/obj/storage.dmi'
	icon_state = "moneybag"
	anchored = FALSE
	density = TRUE

/obj/structure/cursed_money/Initialize()
	. = ..()
	addtimer(CALLBACK(src, .proc/collapse), 600)

/obj/structure/cursed_money/proc/collapse()
	visible_message("<span class='warning'>[src] falls in on itself, \
		canvas rotting away and contents vanishing.</span>")
	qdel(src)

/obj/structure/cursed_money/attack_hand(mob/living/user)
	. = ..()
	if(.)
		return .

	user.visible_message("<span class='warning'>[user] opens the bag and \
		and removes a die. The bag then vanishes.</span>",
		"<span class='boldwarning'>You open the bag...!</span>\n\
		<span class='danger'>And see a bag full of dice. Confused, \
		you take one... and the bag vanishes.</span>")
	var/turf/T = get_turf(user)
	var/obj/item/dice/d20/fate/one_use/critical_fail = new(T)
	user.put_in_hands(critical_fail)
	qdel(src)

// Gluttony
/obj/effect/gluttony //Gluttony's wall: Used in the Gluttony ruin. Only lets the overweight through.
	name = "gluttony's wall"
	desc = "Only those who truly indulge may pass."
	anchored = TRUE
	density = TRUE
	icon_state = "blob"
	icon = 'icons/mob/blob.dmi'
	color = rgb(145, 150, 0)

/obj/effect/gluttony/CanPass(atom/movable/mover, turf/target)//So bullets will fly over and stuff.
	if(ishuman(mover))
		var/mob/living/carbon/human/H = mover
		if(H.nutrition >= NUTRITION_LEVEL_FAT || HAS_TRAIT(H, TRAIT_FAT))
			H.visible_message(span_warning("[H] pushes through [src]!"), span_notice("You've seen and eaten worse than this."))
			return TRUE
		else
			to_chat(H, span_warning("You're repulsed by even looking at [src]. Only a pig could force themselves to go through it."))
	if(istype(mover, /mob/living/simple_animal/hostile/morph))
		return TRUE
	else
		return FALSE

// Pride
/obj/structure/mirror/magic/pride //Pride's mirror: Used in the Pride ruin.
	name = "pride's mirror"
	desc = "Pride cometh before the..."
	icon_state = "magic_mirror"

/obj/structure/mirror/magic/pride/curse(mob/user)
	user.visible_message("<span class='danger'><B>The ground splits beneath [user] as [user.p_their()] hand leaves the mirror!</B></span>", \
	"<span class='notice'>Perfect. Much better! Now <i>nobody</i> will be able to resist yo-</span>")

	var/turf/T = get_turf(user)
	var/list/levels = GLOB.space_manager.z_list.Copy()
	for(var/level in levels)
		if(!is_teleport_allowed(level))
			levels -= level
	if(user.z != 3) //if you somehow manage to bloody get out of lavaland without closing the UI
		var/turf/return_turf = locate(user.x, user.y, 3) //return to sender
		var/mob/living/carbon/human/fool = user
		if(return_turf && fool)
			to_chat(fool, "<span class='danger'><B>You dare try to play me for a fool?</B></span>")
			fool.monkeyize()
			fool.forceMove(return_turf)
			return
	T.ChangeTurf(/turf/simulated/floor/chasm/pride)
	var/turf/simulated/floor/chasm/C = T
	C.drop(user)

// Envy
/obj/item/kitchen/knife/envy //Envy's knife: Found in the Envy ruin. Attackers take on the appearance of whoever they strike.
	name = "envy's knife"
	desc = "Their success will be yours."
	icon = 'icons/obj/wizard.dmi'
	icon_state = "render"
	item_state = "knife"
	force = 18
	throwforce = 10
	w_class = WEIGHT_CLASS_NORMAL
	hitsound = 'sound/weapons/bladeslice.ogg'

/obj/item/kitchen/knife/envy/afterattack(atom/movable/AM, mob/living/carbon/human/user, proximity)
	. = ..()
	if(!proximity)
		return
	if(!istype(user))
		return
	if(ishuman(AM))
		var/mob/living/carbon/human/H = AM
		if(user.real_name != H.dna.real_name)
			user.real_name = H.dna.real_name
			H.dna.transfer_identity(user)
			user.visible_message(span_warning("[user]'s appearance shifts into [H]'s!"), \
			"<span class='boldannounce'>[H.p_they(TRUE)] think[H.p_s()] [H.p_theyre()] <i>sooo</i> much better than you. Not anymore, [H.p_they()] won't.</span>")

// Sloth
/obj/item/paper/fluff/stations/lavaland/sloth/note
	name = "note from sloth"
	icon_state = "paper_words"
	info = "have not gotten around to finishing my cursed item yet sorry - sloth"
