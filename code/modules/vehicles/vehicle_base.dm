#define BASE_MOVE_DELAY 5

/obj/vehicle
	name = "vehicle"
	density = TRUE
	anchored = FALSE
	can_buckle = TRUE
	buckle_lying = FALSE
	icon = 'icons/obj/vehicles.dmi'
	icon_state = "docwagon2"

	/// If true, components will be dropped on destroy.
	// TODO implement this properly. Maybe only drop some, and make sure they're heavily damaged.
	var/drop_components_on_destroy = FALSE

	/// Active for the vehicle. The in-hand item.
	var/obj/item/twohanded/vehicle_controls/controls

	/// The type for the vehicle's controls
	var/control_type = /obj/item/twohanded/vehicle_controls

	/// How fast we're currently moving.
	var/velocity = 0
	/// The last time we stepped. Necessary for inertia management.
	var/last_move_time = 0
	/// The amount of acceleration pending application from the user.
	var/pending_acceleration = 0
	/// How many ticks to wait before moving a tile.
	var/move_delay = 0
	/// The last time we moved
	var/last_vehicle_move = 0

	var/turning = FALSE
	var/turning_direction
	/// If we're turning, how many steps are we into said turn?
	var/steps_into_turn = 0

	var/controls_fluff_name = "controls"

	// todo convert these to traits
	var/can_turn_in_place = FALSE
	var/minimum_speed_for_in_place_turning = 0

	var/minimum_break_out_of_turn_speed = 1


	// Grip stuff
	/// The current active grip
	var/active_grip = VEHICLE_CONTROL_GRIP_NONE

	/// If true, parts can only be removed if broken.
	/// This allows for some "special" parts to not be extractable to use in other vehicles.
	var/unbroken_parts_removable = FALSE

	// The main parts that make up any vehicle.
	var/obj/vehicle_part/chassis/active_chassis
	var/obj/vehicle_part/propulsion/active_propulsion
	var/obj/vehicle_part/engine/active_engine

	/// Any extra components which are on the vehicle but not part of the standard three.
	var/list/additional_components

/obj/vehicle/Initialize(mapload)
	. = ..()
	additional_components = list()
	START_PROCESSING(SSfastprocess, src)

/obj/vehicle/proc/handle_movement()
	// todo check grip
	var/turf/next = get_step(src, dir)
	if(!isturf(loc))
		return

	Move(next, dir, move_delay)

/obj/vehicle/user_buckle_mob(mob/living/M, mob/user)
	if(user.incapacitated())
		return
	for(var/atom/movable/A in get_turf(src))
		if(A.density)
			if(A != src && A != M)
				return
	M.forceMove(get_turf(src))
	..()


/obj/vehicle/proc/handle_grip()

/// it's inertia time babey
/obj/vehicle/process()
	. = ..()

	if(last_vehicle_move + move_delay > world.time)
		return

	var/acceleration = acceleration_rate()
	move_delay -= acceleration

	// we will move, but adjust our move delay
	handle_movement()

	last_vehicle_move = world.time

	// // todo sort out the exact logic later with acceleration
	// var/acceleration = acceleration_rate() * pending_acceleration

	// // todo convert any acceleration that takes us below 1 into fractional/tiles per tick
	// move_delay -= acceleration

	// move_delay

	// TODO check grip

	Move(get_step(src, dir))




/obj/vehicle/Bump(atom/A, yes)
	. = ..()
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

// These getters will get their values from the underlying components
/obj/vehicle/proc/acceleration_rate()

/obj/vehicle/proc/turning_radius()

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
	if(!controls)
		controls = create_new_controls()
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
	return

/obj/vehicle/proc/process_turn(new_dir)
	return


/obj/vehicle/relaymove(mob/user, direction)
	. = ..()
	if(user.incapacitated())
		unbuckle_mob(user)
		return
	var/next_direction
	var/next_direction_set = FALSE
	if(direction == dir)
		accelerate(1)
		return
	if(!turning)
		// behind us
		if(turn(direction, 180) == dir || turn(direction, 235) == dir || turn(direction, 135) == dir)
			if(velocity <= minimum_speed_for_in_place_turning)
				dir = direction
			else
				accelerate(-1)

		else if(turn(direction, 90) == dir || turn(direction, -90) == dir)
			turning_direction = direction
			steps_into_turn = 0
			turning = TRUE

		else
			accelerate(1)
		return

	else
		if(velocity > minimum_break_out_of_turn_speed)
			var/dummy = 3 +  1




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


/datum/action/innate/toggle_vehicle_controls
	name = "Toggle Vehicle Controls"
	desc = "Click to toggle vehicle controls (such as a steering wheel)."
	var/obj/vehicle/source_vehicle

/datum/action/innate/toggle_vehicle_controls/New(Target, source_vehicle)
	. = ..()
	src.source_vehicle = source_vehicle


/datum/action/innate/toggle_vehicle_controls/Activate()
	if(!target || !iscarbon(owner))
		return

	var/mob/living/carbon/C = owner
	if(!C.has_left_hand() && !C.has_right_hand())
		to_chat(owner, "<span class='warning'>You don't have any hands with which to hold [source_vehicle]'s controls!</span>")
		return

	if(ismob(source_vehicle.controls.loc))
		if(owner.l_hand == source_vehicle.controls || owner.r_hand == source_vehicle.controls)
			qdel(source_vehicle.controls)
			to_chat(owner, "<span class='notice'>You release [source_vehicle]'s controls.</span>")
			return
		stack_trace("Somehow, controls exist outside of the rider's hands.")

	if(!C.put_in_hands(source_vehicle.get_controls()))
		to_chat(owner, "<span class='warning'>You aren't able to get a grip on [source_vehicle]'s controls!</span>")
	else
		owner.visible_message("<span class='notice'>[owner] takes [source_vehicle]'s controls!</span>")
