/datum/martial_art/adminfu
	name = "Way of the Dancing Admin"
	has_explaination_verb = TRUE
	combos = list(/datum/martial_combo/adminfu/healing_palm)

/datum/martial_art/adminfu/harm_act(mob/living/carbon/human/A, mob/living/carbon/human/D)
	MARTIAL_ARTS_ACT_CHECK
	if(!D.stat)//do not kill what is dead...
		A.do_attack_animation(D)
		D.visible_message(span_warning("[A] manifests a large glowing toolbox and shoves it in [D]'s chest!"), \
							"<spac class='userdanger'>[A] shoves a mystical toolbox in your chest!</span>")
		D.death()

		return TRUE


/datum/martial_art/adminfu/disarm_act(mob/living/carbon/human/A, mob/living/carbon/human/D)
	MARTIAL_ARTS_ACT_CHECK
	A.do_attack_animation(D)
	D.Stun(50 SECONDS)
	return TRUE

/datum/martial_art/adminfu/grab_act(mob/living/carbon/human/A, mob/living/carbon/human/D)
	MARTIAL_ARTS_ACT_CHECK
	var/obj/item/grab/G = D.grabbedby(A,1)
	if(G)
		G.state = GRAB_NECK
	return TRUE

/datum/martial_art/adminfu/explaination_header(user)
	to_chat(user, "[span_notice("Grab")]: Automatic Neck Grab.")
	to_chat(user, "[span_notice("Disarm")]: Stun/weaken")
	to_chat(user, "[span_notice("Harm")]: Death.")

/obj/item/adminfu_scroll
	name = "frayed scroll"
	desc = "An aged and frayed scrap of paper written in shifting runes. There are hand-drawn illustrations of pugilism."
	icon = 'icons/obj/wizard.dmi'
	icon_state ="scroll2"
	var/used = 0

/obj/item/adminfu_scroll/attack_self(mob/user as mob)
	if(!ishuman(user))
		return
	if(!used)
		var/mob/living/carbon/human/H = user
		var/datum/martial_art/adminfu/F = new/datum/martial_art/adminfu(null)
		F.teach(H)
		to_chat(H, span_boldannounce("You have learned the ancient martial art of the Admins."))
		used = 1
		desc = "It's completely blank."
		name = "empty scroll"
		icon_state = "blankscroll"
