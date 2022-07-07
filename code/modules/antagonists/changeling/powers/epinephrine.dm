/datum/action/changeling/epinephrine
	name = "Epinephrine Overdose"
	desc = "We evolve additional sacs of adrenaline throughout our body. Costs 30 chemicals."
	helptext = "Removes all stuns instantly and adds a short term reduction in further stuns. Can be used while unconscious. Continued use poisons the body."
	button_icon_state = "adrenaline"
	chemical_cost = 30
	dna_cost = 2
	req_human = TRUE
	req_stat = UNCONSCIOUS
	power_type = CHANGELING_PURCHASABLE_POWER

//Recover from stuns.
/datum/action/changeling/epinephrine/sting_action(mob/living/user)
	if(IS_HORIZONTAL(user))
		to_chat(user, span_notice("We arise."))
	else
		to_chat(user, span_notice("Adrenaline rushes through us."))
	user.SetSleeping(0)
	user.WakeUp()
	user.SetParalysis(0)
	user.SetStunned(0)
	user.SetWeakened(0)
	user.setStaminaLoss(0)
	user.SetKnockDown(0)
	user.reagents.add_reagent("synaptizine", 15)
	user.reagents.add_reagent("stimulative_agent", 1)

	SSblackbox.record_feedback("nested tally", "changeling_powers", 1, list("[name]"))
	return TRUE
