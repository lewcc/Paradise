/*
 * GAMEMODES (by Rastaf0)
 *
 * In the new mode system all special roles are fully supported.
 * You can have proper wizards/traitors/changelings/cultists during any mode.
 * Only two things really depends on gamemode:
 * 1. Starting roles, equipment and preparations
 * 2. Conditions of finishing the round.
 *
 */


/datum/game_mode
	var/name = "invalid"
	var/config_tag = null
	var/intercept_hacked = FALSE
	var/votable = TRUE
	/// This var is solely to track gamemodes to track suicides/cryoing/etc and doesnt declare this a "free for all" gamemode. This is for data tracking purposes only.
	var/tdm_gamemode = FALSE
	var/probability = 0
	var/station_was_nuked = FALSE //see nuclearbomb.dm and malfunction.dm
	var/explosion_in_progress = FALSE //sit back and relax
	var/list/restricted_jobs = list()	// Jobs it doesn't make sense to be.  I.E chaplain or AI cultist
	var/list/secondary_restricted_jobs = list() // Same as above, but for secondary antagonists
	var/list/protected_jobs = list()	// Jobs that can't be traitors
	var/list/protected_species = list() // Species that can't be traitors
	var/list/secondary_protected_species = list() // Same as above, but for secondary antagonists
	var/required_players = 0
	var/required_enemies = 0
	var/recommended_enemies = 0
	var/secondary_enemies = 0
	var/secondary_enemies_scaling = 0 // Scaling rate of secondary enemies
	var/newscaster_announcements = null
	var/ert_disabled = FALSE
	var/uplink_welcome = "Syndicate Uplink Console:"

	var/list/player_draft_log = list()
	var/list/datum/mind/xenos = list()
	var/list/datum/mind/eventmiscs = list()
	var/list/blob_overminds = list()

	var/list/datum/station_goal/station_goals = list() // A list of all station goals for this game mode
	var/list/datum/station_goal/secondary/secondary_goals = list() // A list of all secondary goals issued

	/// Each item in this list can only be rolled once on average.
	var/list/single_antag_positions = list("Head of Personnel", "Chief Engineer", "Research Director", "Chief Medical Officer", "Quartermaster")

/datum/game_mode/proc/announce() //to be calles when round starts
	to_chat(world, "<B>Notice</B>: [src] did not define announce()")


///can_start()
///Checks to see if the game can be setup and ran with the current number of players or whatnot.
/datum/game_mode/proc/can_start()
	var/playerC = 0
	for(var/mob/new_player/player in GLOB.player_list)
		if((player.client)&&(player.ready))
			playerC++

	if(!GLOB.configuration.gamemode.enable_gamemode_player_limit || (playerC >= required_players))
		return 1
	return 0

//pre_pre_setup() For when you really don't want certain jobs ingame.
/datum/game_mode/proc/pre_pre_setup()

	return 1

///pre_setup()
///Attempts to select players for special roles the mode might have.
/datum/game_mode/proc/pre_setup()

	return 1


///post_setup()
///Everyone should now be on the station and have their normal gear.  This is the place to give the special roles extra things
/datum/game_mode/proc/post_setup()

	spawn (ROUNDSTART_LOGOUT_REPORT_TIME)
		display_roundstart_logout_report()

	INVOKE_ASYNC(src, PROC_REF(set_mode_in_db)) // Async query), dont bother slowing roundstart

	generate_station_goals()
	generate_station_trait_report()

	GLOB.start_state = new /datum/station_state()
	GLOB.start_state.count()
	return 1

///process()
///Called by the gameticker
/datum/game_mode/process()
	return 0

// I wonder what this could do guessing by the name
/datum/game_mode/proc/set_mode_in_db()
	if(SSticker?.mode && SSdbcore.IsConnected())
		var/datum/db_query/query_round_game_mode = SSdbcore.NewQuery("UPDATE round SET game_mode=:gm WHERE id=:rid", list(
			"gm" = SSticker.mode.name,
			"rid" = GLOB.round_id
		))
		// We dont do anything with output. Dont bother wrapping with if()
		query_round_game_mode.warn_execute()
		qdel(query_round_game_mode)

/datum/game_mode/proc/check_finished() //to be called by ticker
	if((SSshuttle.emergency && SSshuttle.emergency.mode >= SHUTTLE_ENDGAME) || station_was_nuked)
		return 1
	return 0

/datum/game_mode/proc/declare_completion()
	var/clients = 0
	var/surviving_humans = 0
	var/surviving_total = 0
	var/ghosts = 0
	var/escaped_humans = 0
	var/escaped_total = 0
	var/escaped_on_pod_1 = 0
	var/escaped_on_pod_2 = 0
	var/escaped_on_pod_3 = 0
	var/escaped_on_pod_5 = 0
	var/escaped_on_shuttle = 0

	var/list/area/escape_locations = list(/area/shuttle/escape, /area/shuttle/escape_pod1/centcom, /area/shuttle/escape_pod2/centcom, /area/shuttle/escape_pod3/centcom, /area/shuttle/escape_pod5/centcom)

	if(SSshuttle.emergency.mode < SHUTTLE_ENDGAME) //shuttle didn't get to centcom
		escape_locations -= /area/shuttle/escape

	for(var/mob/M in GLOB.player_list)
		if(M.client)
			clients++
			if(ishuman(M))
				if(!M.stat)
					surviving_humans++
					if(M.loc && M.loc.loc && (M.loc.loc.type in escape_locations))
						escaped_humans++
			if(!M.stat)
				surviving_total++
				if(M.loc && M.loc.loc && (M.loc.loc.type in escape_locations))
					escaped_total++

				if(M.loc && M.loc.loc && M.loc.loc.type == SSshuttle.emergency.areaInstance.type && SSshuttle.emergency.mode >= SHUTTLE_ENDGAME)
					escaped_on_shuttle++

				if(M.loc && M.loc.loc && M.loc.loc.type == /area/shuttle/escape_pod1/centcom)
					escaped_on_pod_1++
				if(M.loc && M.loc.loc && M.loc.loc.type == /area/shuttle/escape_pod2/centcom)
					escaped_on_pod_2++
				if(M.loc && M.loc.loc && M.loc.loc.type == /area/shuttle/escape_pod3/centcom)
					escaped_on_pod_3++
				if(M.loc && M.loc.loc && M.loc.loc.type == /area/shuttle/escape_pod5/centcom)
					escaped_on_pod_5++

			if(isobserver(M))
				ghosts++

	if(clients)
		SSblackbox.record_feedback("nested tally", "round_end_stats", clients, list("clients"))
	if(ghosts)
		SSblackbox.record_feedback("nested tally", "round_end_stats", ghosts, list("ghosts"))
	if(surviving_humans)
		SSblackbox.record_feedback("nested tally", "round_end_stats", surviving_humans, list("survivors", "human"))
	if(surviving_total)
		SSblackbox.record_feedback("nested tally", "round_end_stats", surviving_total, list("survivors", "total"))
	if(escaped_humans)
		SSblackbox.record_feedback("nested tally", "round_end_stats", escaped_humans, list("escapees", "human"))
	if(escaped_total)
		SSblackbox.record_feedback("nested tally", "round_end_stats", escaped_total, list("escapees", "total"))
	if(escaped_on_shuttle)
		SSblackbox.record_feedback("nested tally", "round_end_stats", escaped_on_shuttle, list("escapees", "on_shuttle"))
	if(escaped_on_pod_1)
		SSblackbox.record_feedback("nested tally", "round_end_stats", escaped_on_pod_1, list("escapees", "on_pod_1"))
	if(escaped_on_pod_2)
		SSblackbox.record_feedback("nested tally", "round_end_stats", escaped_on_pod_2, list("escapees", "on_pod_2"))
	if(escaped_on_pod_3)
		SSblackbox.record_feedback("nested tally", "round_end_stats", escaped_on_pod_3, list("escapees", "on_pod_3"))
	if(escaped_on_pod_5)
		SSblackbox.record_feedback("nested tally", "round_end_stats", escaped_on_pod_5, list("escapees", "on_pod_5"))
	for(var/tech_id in SSeconomy.tech_levels)
		SSblackbox.record_feedback("tally", "cargo max tech level sold", SSeconomy.tech_levels[tech_id], tech_id)

	GLOB.discord_manager.send2discord_simple(DISCORD_WEBHOOK_PRIMARY, "A round of [name] has ended - [surviving_total] survivors, [ghosts] ghosts.")
	if(SSredis.connected)
		// Send our presence to required channels
		var/list/presence_data = list()
		presence_data["author"] = "system"
		presence_data["source"] = GLOB.configuration.system.instance_id
		presence_data["message"] = "Round [GLOB.round_id] ended at `[SQLtime()]`"

		var/presence_text = json_encode(presence_data)

		for(var/channel in list("byond.asay", "byond.msay")) // Channels to announce to
			SSredis.publish(channel, presence_text)

		// Report detailed presence info to system
		var/list/presence_data_2 = list()
		presence_data_2["source"] = GLOB.configuration.system.instance_id
		presence_data_2["round_id"] = GLOB.round_id
		presence_data_2["event"] = "round_end"
		SSredis.publish("byond.system", json_encode(presence_data_2))

	return 0


/datum/game_mode/proc/check_win() //universal trigger to be called at mob death, nuke explosion, etc. To be called from everywhere.
	if(rev_team)
		rev_team.check_all_victory()

/datum/game_mode/proc/get_players_for_role(role, override_jobbans=0)
	var/list/players = list()
	var/list/candidates = list()
	//var/list/drafted = list()
	//var/datum/mind/applicant = null

	var/roletext = get_roletext(role)

	// Assemble a list of active players without jobbans.
	for(var/mob/new_player/player in GLOB.player_list)
		if(player.client && player.ready)
			if(!jobban_isbanned(player, ROLE_SYNDICATE) && !jobban_isbanned(player, roletext))
				if(player_old_enough_antag(player.client,role))
					players += player

	// Shuffle the players list so that it becomes ping-independent.
	players = shuffle(players)

	// Get a list of all the people who want to be the antagonist for this round, except those with incompatible species
	for(var/mob/new_player/player in players)
		if(!player.client.skip_antag)
			if((role in player.client.prefs.be_special) && !(player.client.prefs.active_character.species in protected_species))
				player_draft_log += "[player.key] had [roletext] enabled, so we are drafting them."
				candidates += player.mind
				players -= player

	// Remove candidates who want to be antagonist but have a job that precludes it
	if(restricted_jobs)
		for(var/datum/mind/player in candidates)
			for(var/job in restricted_jobs)
				if(player.assigned_role == job)
					candidates -= player


	return candidates		// Returns: The number of people who had the antagonist role set to yes, regardless of recomended_enemies, if that number is greater than recommended_enemies
							//			recommended_enemies if the number of people with that role set to yes is less than recomended_enemies,
							//			Less if there are not enough valid players in the game entirely to make recommended_enemies.


/datum/game_mode/proc/latespawn(mob)
	if(rev_team)
		rev_team.update_team_objectives()
		rev_team.process_promotion(REVOLUTION_PROMOTION_OPTIONAL)


/*
/datum/game_mode/proc/check_player_role_pref(role, mob/player)
	if(player.preferences.be_special & role)
		return 1
	return 0
*/

/datum/game_mode/proc/num_players()
	. = 0
	for(var/mob/new_player/P in GLOB.player_list)
		if(P.client && P.ready)
			.++

/datum/game_mode/proc/num_players_started()
	. = 0
	for(var/mob/living/carbon/human/H in GLOB.player_list)
		if(H.client)
			.++

///////////////////////////////////
//Keeps track of all living heads//
///////////////////////////////////
/datum/game_mode/proc/get_living_heads()
	. = list()
	for(var/thing in GLOB.human_list)
		var/mob/living/carbon/human/player = thing
		if(player.stat != DEAD && player.mind && (player.mind.assigned_role in GLOB.command_head_positions))
			. |= player.mind


////////////////////////////
//Keeps track of all heads//
////////////////////////////
/datum/game_mode/proc/get_all_heads()
	. = list()
	for(var/mob/player in GLOB.mob_list)
		if(player.mind && (player.mind.assigned_role in GLOB.command_head_positions))
			. |= player.mind

//////////////////////////////////////////////
//Keeps track of all living security members//
//////////////////////////////////////////////
/datum/game_mode/proc/get_living_sec()
	. = list()
	for(var/thing in GLOB.human_list)
		var/mob/living/carbon/human/player = thing
		if(player.stat != DEAD && player.mind && (player.mind.assigned_role in GLOB.active_security_positions))
			. |= player.mind

////////////////////////////////////////
//Keeps track of all  security members//
////////////////////////////////////////
/datum/game_mode/proc/get_all_sec()
	. = list()
	for(var/thing in GLOB.human_list)
		var/mob/living/carbon/human/player = thing
		if(player.mind && (player.mind.assigned_role in GLOB.active_security_positions))
			. |= player.mind

/datum/game_mode/proc/check_antagonists_topic(href, href_list[])
	return 0

/datum/game_mode/New()
	newscaster_announcements = pick(GLOB.newscaster_standard_feeds)

//////////////////////////
//Reports player logouts//
//////////////////////////
/proc/display_roundstart_logout_report()
	var/msg = "<span class='notice'>Roundstart logout report</span>\n\n"
	for(var/mob/living/L in GLOB.mob_list)

		if(L.ckey)
			var/found = 0
			for(var/client/C in GLOB.clients)
				if(C.ckey == L.ckey)
					found = 1
					break
			if(!found)
				msg += "<b>[L.name]</b> ([L.ckey]), the [L.job] (<font color='#ffcc00'><b>Disconnected</b></font>)\n"


		if(L.ckey && L.client)
			if(L.client.inactivity >= (ROUNDSTART_LOGOUT_REPORT_TIME / 2))	//Connected, but inactive (alt+tabbed or something)
				msg += "<b>[L.name]</b> ([L.ckey]), the [L.job] (<font color='#ffcc00'><b>Connected, Inactive</b></font>)\n"
				continue //AFK client
			if(L.stat)
				if(L.suiciding)	//Suicider
					msg += "<b>[L.name]</b> ([L.ckey]), the [L.job] (<font color='red'><b>Suicide</b></font>)\n"
					SSjobs.FreeRole(L.job)
					message_admins("<b>[key_name_admin(L)]</b>, the [L.job] has been freed due to (<font color='#ffcc00'><b>Early Round Suicide</b></font>)\n")
					continue //Disconnected client
				if(L.stat == UNCONSCIOUS)
					msg += "<b>[L.name]</b> ([L.ckey]), the [L.job] (Dying)\n"
					continue //Unconscious
				if(L.stat == DEAD)
					msg += "<b>[L.name]</b> ([L.ckey]), the [L.job] (Dead)\n"
					continue //Dead

			continue //Happy connected client
		for(var/mob/dead/observer/D in GLOB.mob_list)
			if(D.mind && (D.mind.is_original_mob(L) || D.mind.current == L))
				if(L.stat == DEAD)
					if(L.suiciding)	//Suicider
						msg += "<b>[L.name]</b> ([ckey(D.mind.key)]), the [L.job] (<font color='red'><b>Suicide</b></font>)\n"
						continue //Disconnected client
					else
						msg += "<b>[L.name]</b> ([ckey(D.mind.key)]), the [L.job] (Dead)\n"
						continue //Dead mob, ghost abandoned
				else
					if(D.can_reenter_corpse)
						msg += "<b>[L.name]</b> ([ckey(D.mind.key)]), the [L.job] (<font color='red'><b>This shouldn't appear.</b></font>)\n"
						continue //Lolwhat
					else
						msg += "<b>[L.name]</b> ([ckey(D.mind.key)]), the [L.job] (<font color='red'><b>Ghosted</b></font>)\n"
						SSjobs.FreeRole(L.job)
						message_admins("<b>[key_name_admin(L)]</b>, the [L.job] has been freed due to (<font color='#ffcc00'><b>Early Round Ghosted While Alive</b></font>)\n")
						continue //Ghosted while alive



	for(var/mob/M in GLOB.mob_list)
		if(check_rights(R_ADMIN, 0, M))
			to_chat(M, msg)

//Announces objectives/generic antag text.
/proc/show_generic_antag_text(datum/mind/player)
	if(player.current)
		to_chat(player.current, "You are an antagonist! <font color=blue>Within the rules,</font> \
		try to act as an opposing force to the crew. Further RP and try to make sure \
		other players have <i>fun</i>! If you are confused or at a loss, always adminhelp, \
		and before taking extreme actions, please try to also contact the administration! \
		Think through your actions and make the roleplay immersive! <b>Please remember all \
		rules aside from those without explicit exceptions apply to antagonists.</b>")

/proc/get_roletext(role)
	return role

/proc/get_nuke_code()
	var/nukecode = "ERROR"
	for(var/obj/machinery/nuclearbomb/bomb in GLOB.machines)
		if(bomb && bomb.r_code && is_station_level(bomb.z))
			nukecode = bomb.r_code
	return nukecode

/proc/get_nuke_status()
	var/nuke_status = NUKE_MISSING
	for(var/obj/machinery/nuclearbomb/bomb in GLOB.machines)
		if(is_station_level(bomb.z))
			nuke_status = NUKE_CORE_MISSING
			if(bomb.core)
				nuke_status = NUKE_STATUS_INTACT
	return nuke_status

/datum/game_mode/proc/replace_jobbanned_player(mob/living/M, role_type)
	var/list/mob/dead/observer/candidates = SSghost_spawns.poll_candidates("Do you want to play as a [role_type]?", role_type, FALSE, 10 SECONDS)
	var/mob/dead/observer/theghost = null
	if(length(candidates))
		theghost = pick(candidates)
		to_chat(M, "<span class='userdanger'>Your mob has been taken over by a ghost! Appeal your job ban if you want to avoid this in the future!</span>")
		message_admins("[key_name_admin(theghost)] has taken control of ([key_name_admin(M)]) to replace a jobbanned player.")
		M.ghostize()
		M.key = theghost.key
		dust_if_respawnable(theghost)
	else
		message_admins("[M] ([M.key] has been converted into [role_type] with an active antagonist jobban for said role since no ghost has volunteered to take [M.p_their()] place.")
		to_chat(M, "<span class='biggerdanger'>You have been converted into [role_type] with an active jobban. Any further violations of the rules on your part are likely to result in a permanent ban.</span>")

/proc/printplayer(datum/mind/ply, fleecheck)
	var/jobtext = ""
	if(ply.assigned_role)
		jobtext = " the <b>[ply.assigned_role]</b>"
	var/text = "<b>[ply.get_display_key()]</b> was <b>[ply.name]</b>[jobtext] and"
	if(ply.current)
		if(ply.current.stat == DEAD)
			text += " <span class='redtext'>died</span>"
		else
			text += " <span class='greentext'>survived</span>"
		if(fleecheck)
			var/turf/T = get_turf(ply.current)
			if(!T || !is_station_level(T.z))
				text += " while <span class='redtext'>fleeing the station</span>"
		if(ply.current.real_name != ply.name)
			text += " as <b>[ply.current.real_name]</b>"
	else
		text += " <span class='redtext'>had [ply.p_their()] body destroyed</span>"
	return text

/proc/printeventplayer(datum/mind/ply)
	var/text = "<b>[ply.get_display_key()]</b> was <b>[ply.name]</b>"
	if(ply.special_role != SPECIAL_ROLE_EVENTMISC)
		text += " the [ply.special_role]"
	text += " and"
	if(ply.current)
		if(ply.current.stat == DEAD)
			text += " <b>died</b>"
		else
			text += " <b>survived</b>"
	else
		text += " <b>had [ply.p_their()] body destroyed</b>"
	return text

/proc/printobjectives(datum/mind/ply)
	var/list/objective_parts = list()
	var/count = 1
	for(var/datum/objective/objective in ply.get_all_objectives(include_team = FALSE))
		if(objective.check_completion())
			objective_parts += "<b>Objective #[count]</b>: [objective.explanation_text] <span class='greentext'>Success!</span>"
		else
			objective_parts += "<b>Objective #[count]</b>: [objective.explanation_text] <span class='redtext'>Fail.</span>"
		count++
	return objective_parts.Join("<br>")

/datum/game_mode/proc/generate_station_goals()
	var/list/possible = list()
	for(var/T in subtypesof(/datum/station_goal))
		if(ispath(T, /datum/station_goal/secondary))
			continue
		var/datum/station_goal/G = T
		if(config_tag in initial(G.gamemode_blacklist))
			continue
		possible += G
	var/goal_weights = 0
	while(length(possible) && goal_weights < STATION_GOAL_BUDGET)
		var/datum/station_goal/picked = pick_n_take(possible)
		goal_weights += initial(picked.weight)
		station_goals += new picked

	if(station_goals.len)
		send_station_goals_message()

/datum/game_mode/proc/send_station_goals_message()
	var/message_text = "<div style='text-align:center;'><img src='ntlogo.png'>"
	message_text += "<h3>NAS Trurl Orders</h3></div><hr>"
	message_text += "<b>Special Orders for [station_name()]:</b><br><br>"

	for(var/datum/station_goal/G in station_goals)
		G.on_report()
		message_text += G.get_report()
		message_text += "<hr>"

	print_command_report(message_text, "NAS Trurl Orders", FALSE)

/datum/game_mode/proc/declare_station_goal_completion()
	for(var/datum/station_goal/goal in station_goals)
		goal.print_result()

	var/departments = list()
	for(var/datum/station_goal/secondary/goal in secondary_goals)
		if(goal.completed)
			if(!departments[goal.department])
				departments[goal.department] = 0
			departments[goal.department]++

	to_chat(world, "<b>Secondary Goals</b>:")
	var/any = FALSE
	for(var/department in departments)
		if(departments[department])
			any = TRUE
			to_chat(world, "<b>[department]</b>: <span class='greenannounce'>[departments[department]] completed!</span>")
	if(!any)
		to_chat(world, "<span class='boldannounceic'>None completed!</span>")

/datum/game_mode/proc/generate_station_trait_report()
	var/something_to_print = FALSE
	var/list/trait_list_desc = list("<hr><b>Identified shift divergencies:</b>")
	for(var/datum/station_trait/station_trait as anything in SSstation.station_traits)
		if(!station_trait.show_in_report)
			continue
		trait_list_desc += station_trait.get_report()
		something_to_print = TRUE
	if(something_to_print)
		print_command_report(trait_list_desc.Join("<br>"), "NAS Trurl Detected Divergencies", FALSE)


/datum/game_mode/proc/update_eventmisc_icons_added(datum/mind/mob_mind)
	var/datum/atom_hud/antag/antaghud = GLOB.huds[ANTAG_HUD_EVENTMISC]
	antaghud.join_hud(mob_mind.current)
	set_antag_hud(mob_mind.current, "hudevent")

/datum/game_mode/proc/update_eventmisc_icons_removed(datum/mind/mob_mind)
	var/datum/atom_hud/antag/antaghud = GLOB.huds[ANTAG_HUD_EVENTMISC]
	antaghud.leave_hud(mob_mind.current)
	set_antag_hud(mob_mind.current, null)

/// Gets the value of all end of round stats through auto_declare and returns them
/datum/game_mode/proc/get_end_of_round_antagonist_statistics()
	. = list()
	. += auto_declare_completion_traitor()
	. += auto_declare_completion_vampire()
	. += auto_declare_completion_enthralled()
	. += auto_declare_completion_changeling()
	. += auto_declare_completion_nuclear()
	. += auto_declare_completion_wizard()
	. += auto_declare_completion_revolution()
	. += auto_declare_completion_abduction()
	listclearnulls(.)
