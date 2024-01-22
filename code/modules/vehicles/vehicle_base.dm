#define BASE_MOVE_DELAY 5
/// Highest possible move delay, the "low" mark for velocity.
#define MAX_MOVE_DELAY 8
/// Time between accelerations, so you don't accidentally go faster than you mean to.
#define ACCELERATION_COOLDOWN (0.5 SECONDS)

#define MIN_THROW_VELOCITY 5
#define MIN_THROW_VELOCITY_ONEHAND 6
#define MIN_THROW_VELOCITY_TWOHAND 7

#define MIN_WINDOW_SMASH_VELOCITY 4

#define NO_DIRECTION_PRESSED (-1)

/obj/vehicle
	name = "vehicle"
	density = TRUE
	anchored = FALSE
	can_buckle = TRUE
	buckle_lying = FALSE
	icon = 'icons/obj/vehicles.dmi'
	icon_state = "docwagon2"
	max_buckled_mobs = 1

	/// If true, components will be dropped on destroy.
	// TODO implement this properly. Maybe only drop some, and make sure they're heavily damaged.
	var/drop_components_on_destroy = FALSE

	/// Active for the vehicle. The in-hand item.
	var/obj/item/twohanded/vehicle_controls/controls

	/// The type for the vehicle's controls
	var/control_type = /obj/item/twohanded/vehicle_controls

	/// Who's driving the thing
	var/mob/living/carbon/driver

	/// How fast we're currently moving.
	var/velocity = 0
	/// The last time we stepped. Necessary for inertia management.
	var/last_move_time = 0
	/// The amount of acceleration pending application from the user.
	var/pending_acceleration = 0
	/// The dir from our current movement.
	var/inertia_next_dir
	/// When we should be making our next move.
	var/next_move_time = 0
	/// The direction that will be accounted for during our next acceleration process
	var/desired_movement_direction = NO_DIRECTION_PRESSED
	/// The last time we moved
	var/last_vehicle_move = 0

	/// The last time we accelerated with the direction button
	var/last_acceleration_time = 0

	var/turning = FALSE
	var/turning_direction
	/// If we're turning, how many steps are we into said turn?
	var/steps_into_turn = 0

	var/controls_fluff_name = "controls"

	var/datum/action/innate/toggle_vehicle_controls/control_toggle

	// todo convert these to traits
	var/can_turn_in_place = FALSE
	/// How slow this vehicle needs to be going in order to be able to turn in place
	var/minimum_speed_for_in_place_turning = 0

	/// Minimum speed at which you can break out of a turn by just pressing another direction.
	/// If you're over this value, you've committed to a turn.
	var/minimum_break_out_of_turn_speed = 2


	// Grip stuff
	/// The current active grip
	var/active_grip = VEHICLE_CONTROL_GRIP_NONE

	/// If true, parts can only be removed if broken.
	/// This allows for some "special" parts to not be extractable to use in other vehicles.
	var/unbroken_parts_removable = FALSE

	// The main parts that make up any vehicle.
	var/obj/item/vehicle_part/chassis/active_chassis
	var/obj/item/vehicle_part/propulsion/active_propulsion
	var/obj/item/vehicle_part/engine/active_engine

	/// Any extra components which are on the vehicle but not part of the standard three.
	var/list/additional_components

/obj/vehicle/Initialize(mapload)
	. = ..()
	additional_components = list()
	control_toggle = new(src)
	// START_PROCESSING(SSvehicle, src)
	handle_vehicle_layer()

/obj/vehicle/proc/all_components()
	return list(active_chassis, active_propulsion, active_engine) + additional_components

/obj/vehicle/examine(mob/user, infix, suffix)
	. = ..()
	if(driver)
		. += "<span class='notice'>It's currently being driven by [driver].</span>"
		. += "<span class='notice'>[driver.p_they(TRUE)] [driver.p_have()] [active_grip] hand\s on the [controls_fluff_name].</span>"
		. += "<span class='notice'>You could try to pull them off by clicking the vehicle with <b>grab</i> intent.</span>"

/obj/vehicle/proc/handle_vehicle_layer()
	if(dir != NORTH)
		layer = MOB_LAYER+0.1
	else
		layer = OBJ_LAYER



/obj/vehicle/user_buckle_mob(mob/living/M, mob/user)
	if(user.incapacitated())
		return
	if(max_buckled_mobs <= length(buckled_mobs))
		to_chat(user, "<span class='warning'>There's not enough space on [src]!</span>")
		return FALSE
	for(var/atom/movable/A in get_turf(src))
		if(A.density)
			if(A != src && A != M)
				return
	M.forceMove(get_turf(src))
	. = ..()
	if(!.)
		return .
	SEND_SIGNAL(src, COMSIG_VEHICLE_ADD_RIDER, M, isnull(driver))
	if(isnull(driver))  // just added a rider
		driver = M
		START_PROCESSING(SSvehicle, src)
		control_toggle.Grant(M)

/obj/vehicle/attack_hand(mob/living/user)
	if(!isnull(driver))
		// todo this should be expanded to account for multiple people on it
		if(driver.incapacitated())
			return ..()  // free unbuckle

		if(user.a_intent != INTENT_GRAB)
			to_chat(user, "<span class='notice'>You can't open the panel while someone's driving it!</span>")
			to_chat(user, "<span class='notice'>If you want to try pulling [driver] off of [src], try <i>grabbing</i> them.</span>")
			return TRUE

		var/do_after_time

		switch(active_grip)
			if(VEHICLE_CONTROL_GRIP_NONE)
				do_after_time = 0
			if(VEHICLE_CONTROL_GRIP_ONEHAND)
				do_after_time = 2 SECONDS
			if(VEHICLE_CONTROL_GRIP_TWOHAND)
				do_after_time = 5 SECONDS
			else
				stack_trace("Someone tried to unbuckle someone else who had an invalid grip level of [active_grip]")

		if(do_after_time > 0)
			driver.visible_message(
				"<span class='warning'>[user] tries to unbuckle [driver] from [src]!</span>",
				"<span class='userdanger'>[user] is trying to unbuckle you from [src]!</span>"
			)

		if(do_after_time <= 0 || do_after(user, do_after_time, TRUE, src))
			return ..()

		driver.visible_message(
			"<span class='warning'>[user] fails to unbuckle [driver] from [src]!</span>",
			"<span class='userdanger'>[user] fails to unbuckle you from [src]!</span>"
		)
		return TRUE

	return ..()

/obj/vehicle/unbuckle_mob(mob/living/buckled_mob, force)
	. = ..()
	if(!.)
		return .
	SEND_SIGNAL(src, COMSIG_VEHICLE_REMOVE_RIDER, buckled_mob, isnull(driver))
	if(buckled_mob == driver)
		STOP_PROCESSING(SSvehicle, src)
		control_toggle.Remove(buckled_mob)
		driver = null


// TODO probably make this some kind of atom variable, like hit_by_vehicle
/obj/vehicle/Bump(atom/A, yes)
	. = ..()
	var/throw_occupant = FALSE
	var/stopped_by = FALSE
	if(!A.density)
		return
	if(iswallturf(A))
		throw_occupant = TRUE
		stopped_by = TRUE
	else if(iswallturf(A) || isstructure(A) || ismachinery(A) || ismecha(A))
		throw_occupant = TRUE
		stopped_by = TRUE
	else if(ismovable(A))
		var/atom/movable/M = A
		if(M.density && (M.anchored || M.move_resist >= MOVE_FORCE_STRONG))
			throw_occupant = TRUE
			stopped_by = TRUE

	else if(isliving(A))
		var/mob/living/L = A
		if(L.move_resist >= MOVE_FORCE_STRONG)
			throw_occupant = TRUE
			stopped_by = TRUE


	if(throw_occupant)
		if(velocity < MIN_THROW_VELOCITY || (active_grip == VEHICLE_CONTROL_GRIP_ONEHAND && velocity < MIN_THROW_VELOCITY_ONEHAND) || (active_grip == VEHICLE_CONTROL_GRIP_TWOHAND && velocity < MIN_THROW_VELOCITY_TWOHAND))
			return
		var/buckled_mobs_tmp = buckled_mobs
		for(var/mob/living/buckled in buckled_mobs)
			unbuckle_mob(buckled, TRUE)
			buckled.throw_at(A, 5, velocity * 25)
	if(stopped_by)
		velocity = 0
	// TODO


/obj/vehicle/Destroy()
	. = ..()
	QDEL_NULL(controls)
	if(!drop_components_on_destroy)
		QDEL_NULL(active_chassis)
		QDEL_NULL(active_propulsion)
		QDEL_NULL(active_engine)
	additional_components.Cut()
	STOP_PROCESSING(SSfastprocess, src)
	driver = null

// These getters will get their values from the underlying components
/obj/vehicle/proc/acceleration_rate()

/obj/vehicle/proc/turning_radius()
	return 1

/obj/vehicle/proc/get_low_speed()

/obj/vehicle/proc/get_medium_speed()

/obj/vehicle/proc/get_high_speed()

/obj/vehicle/proc/max_speed()


/obj/vehicle/proc/create_new_controls()
	if(controls)
		stack_trace("[src] tried to create controls while it already had some!")
		return
	controls = new control_type(src)
	RegisterSignal(controls, COMSIG_VEHICLE_GRIP_CHANGE, PROC_REF(on_grip_change))

/obj/vehicle/proc/get_controls()
	if(QDELETED(controls))
		create_new_controls()
	return controls

/obj/vehicle/proc/on_grip_change(obj/item/grip, grip_level)
	SIGNAL_HANDLER  // COMSIG_VEHICLE_GRIP_CHANGE
	active_grip = grip_level

// So that beepsky can't push the janicart
/obj/vehicle/CanPass(atom/movable/mover, turf/target, height)
	if(istype(mover) && mover.checkpass(PASSMOB))
		return TRUE
	else
		return ..()

/obj/vehicle/proc/accelerate(delta)
	to_chat(world, "Accelerating by [delta]")
	pending_acceleration += delta

/obj/vehicle/proc/process_turn()
	return


/obj/vehicle/relaymove(mob/user, direction)
	. = ..()
	if(user != driver)
		return

	// if(!active_propulsion)
	// 	// good luck going anywhere
	// 	return

	desired_movement_direction = direction

	return

/**
 * Based on the user's inputs and our current state, set our next target direction/acceleration
 */
/obj/vehicle/proc/handle_movement(direction)

	if(direction == NO_DIRECTION_PRESSED)
		// pure inertia, continue in the direction we're heading
		return

	if(direction == dir)
		accelerate(1)
		return
	if(velocity <= minimum_speed_for_in_place_turning && dir != direction)
		dir = direction
		return
	if(!turning)
		// we aren't in a turn, so we'll either accelerate, decelerate, or enter a turn.
		if(turn(direction, 180) == dir || turn(direction, 225) == dir || turn(direction, 135) == dir)
			// this direction is somewhere behind where we're heading -- apply the brakes
			// if(velocity <= minimum_speed_for_in_place_turning)
			// 	dir = direction
			// 	handle_vehicle_layer()
			// else
			accelerate(-1)

		// not in a turn, let's start a new one
		else if(turn(direction, 90) == dir || turn(direction, -90) == dir)
			turning_direction = direction
			steps_into_turn = 0
			turning = TRUE

		// guess it's ahead
		else
			accelerate(1)
		return

	// we're currently in a turn

	if(velocity > minimum_break_out_of_turn_speed || turning_direction == direction)
		// you're not breaking out of the turn that easily
		return  // don't accelerate through turns

	// we're in a turn, but we're going slow enough
	if(velocity < minimum_break_out_of_turn_speed && \
		turn(direction, 45) == turning_direction || turn(direction, -45) == turning_direction || \
		turn(direction, 90) == turning_direction || turn(direction, -90) == turning_direction)

		turning = FALSE
		steps_into_turn = 0
		return

	// at this point, we're actively in the process of a turn.
	// probably don't want to accelerate into a turn...

	// if(turning)
	// 	if(steps_into_turn < turning_radius())
	// 		next_dir = dir | turning_direction
	// 		steps_into_turn++
	// 	else
	// 		turning = FALSE
	// 		steps_into_turn = 0
	// 		dir = turning_direction
	// 		next_dir = turning_direction
	// else
	// 	next_dir = inertia_next_dir
	// TODO figure out what we need to do here?
/**
 * With acceleration and direction out of the way, decide how we will actually behave.
 */
/obj/vehicle/proc/handle_inertia()
	velocity += pending_acceleration
	pending_acceleration = 0
	to_chat(world, "[velocity]")
	var/next_dir

	if(!isturf(loc))
		return

	if(turning)
		if(steps_into_turn < turning_radius())
			next_dir = dir | turning_direction
			steps_into_turn++
		else
			turning = FALSE
			steps_into_turn = 0
			dir = turning_direction
			next_dir = turning_direction
	else
		next_dir = inertia_next_dir

	dir = next_dir
	if(velocity > 10)  // todo make this not a magic number
		return

	// TODO need to work out how to best handle velocity changes
	// for simplicity's sake let's assume that 10 velocity lets you move a tile
	var/temp_velocity = velocity
	var/turf/next = get_turf(src)
	while(temp_velocity > 10)
		next = get_step(next, next_dir)

	handle_vehicle_layer()


	Move(next, next_dir, round(SSvehicle.wait, 2))

	inertia_next_dir = NO_DIRECTION_PRESSED


/// it's inertia time babey
/obj/vehicle/process()
	// if(buckled.incapacitated())
	// 	unbuckle_mob(buckle_mob)
	// 	return PROCESS_KILL

	// on each process, if we have a new direction inputted, do something new with
	var/direction = desired_movement_direction
	log_world("[direction] registered as pressed")
	desired_movement_direction = NO_DIRECTION_PRESSED




	// we will move, but adjust our move delay
	handle_movement(direction)
	handle_inertia()






	//todo work out delays
	// if(turning && direction == turning_direction)
	// 	steps_into_turn++
	// 	if(steps_into_turn > turning_radius())
	// 		turning = FALSE
	// 		dir = direction
	// 		steps_into_turn = 0
	// 		turning_direction = null
	// 		next_direction = direction
	// 		next_direction_set = TRUE
	// 	else
	// 		next_direction = turning_direction | direction  // keep turning diagonally
	// 		next_direction_set = TRUE

	// turning = FALSE
	// steps_into_turn = 0
	// turning_direction = null

	// now, check the relative direction to decide what to do.











/**
 * Pre-built vehicle. Spawns with a pre-assigned set of components.
 */
/obj/vehicle/prebuilt

/obj/vehicle/prebuilt/Initialize(mapload)
	. = ..()
	active_propulsion = new /obj/item/vehicle_part/propulsion/wheelbase(src)


/datum/action/innate/toggle_vehicle_controls
	name = "Toggle Vehicle Controls"
	desc = "Click to toggle vehicle controls (such as a steering wheel)."
	var/obj/vehicle/source_vehicle

/datum/action/innate/toggle_vehicle_controls/New(Target)
	. = ..()
	source_vehicle = target


/datum/action/innate/toggle_vehicle_controls/Activate()
	if(!target || !iscarbon(owner))
		return

	var/mob/living/carbon/C = owner
	if(!C.has_left_hand() && !C.has_right_hand())
		to_chat(owner, "<span class='warning'>You don't have any hands with which to hold [source_vehicle]'s controls!</span>")
		return

	if(ismob(source_vehicle.controls?.loc))
		if(owner.l_hand == source_vehicle.controls || owner.r_hand == source_vehicle.controls)
			qdel(source_vehicle.controls)
			to_chat(owner, "<span class='notice'>You release [source_vehicle]'s controls.</span>")
			return
		stack_trace("Somehow, controls exist outside of the rider's hands.")

	if(!C.put_in_hands(source_vehicle.get_controls()))
		to_chat(owner, "<span class='warning'>You aren't able to get a grip on [source_vehicle]'s controls!</span>")
	else
		owner.visible_message("<span class='notice'>[owner] takes [source_vehicle]'s controls!</span>")

#undef NO_DIRECTION_PRESSED
