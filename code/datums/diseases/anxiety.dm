/datum/disease/anxiety
	name = "Severe Anxiety"
	form = "Infection"
	max_stages = 4
	spread_text = "On contact"
	spread_flags = CONTACT_GENERAL
	cure_text = "Ethanol"
	cures = list("ethanol")
	agent = "Excess Lepidopticides"
	viable_mobtypes = list(/mob/living/carbon/human, /mob/living/carbon/human/monkey)
	desc = "If left untreated subject will regurgitate butterflies."
	severity = MEDIUM

/datum/disease/anxiety/stage_act()
	..()
	switch(stage)
		if(2) //also changes say, see say.dm
			if(prob(5))
				to_chat(affected_mob, span_notice("You feel anxious."))
		if(3)
			if(prob(10))
				to_chat(affected_mob, span_notice("Your stomach flutters."))
			if(prob(5))
				to_chat(affected_mob, span_notice("You feel panicky."))
			if(prob(2))
				to_chat(affected_mob, "<span class='danger'>You're overtaken with panic!</span>")
				affected_mob.AdjustConfused(rand(4 SECONDS, 6 SECONDS))
		if(4)
			if(prob(10))
				to_chat(affected_mob, "<span class='danger'>You feel butterflies in your stomach.</span>")
			if(prob(5))
				affected_mob.visible_message("<span class='danger'>[affected_mob] stumbles around in a panic.</span>", \
												"<span class='userdanger'>You have a panic attack!</span>")
				affected_mob.AdjustConfused(rand(12 SECONDS, 16 SECONDS))
				affected_mob.AdjustJitter(rand(12 SECONDS, 16 SECONDS))
			if(prob(2))
				affected_mob.visible_message("<span class='danger'>[affected_mob] coughs up butterflies!</span>", \
													"<span class='userdanger'>You cough up butterflies!</span>")
				for(var/i in 1 to 2)
					var/mob/living/simple_animal/butterfly/B = new(affected_mob.loc)
					addtimer(CALLBACK(B, /mob/living/simple_animal/butterfly/.proc/decompose), rand(5, 25) SECONDS)

/**
 * Made so severe anxiety does not overload the SSmob while keeping it's effect
 */
/mob/living/simple_animal/butterfly/proc/decompose()
	visible_message(span_notice("[src] decomposes due to being outside of its original habitat for too long!"),
					"<span class='userdanger'>You decompose for being too long out of your habitat!</span>")
	melt()
