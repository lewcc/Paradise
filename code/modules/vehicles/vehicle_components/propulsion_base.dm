// special resistance flags for tires.
/// Base behavior, no special attributes.
#define VEHICLE_TIRE_STRONG (1 << 0)
/// Immune to getting tied up by bolas.
#define VEHICLE_TIRE_BOLA_PROOF (1 << 1)
/// Immune to sharpness.
#define VEHICLE_TIRE_SHARP_PROOF (1 << 2)

/obj/item/vehicle_part/propulsion
	name = "propulsion"
	// Use object damage to deal with the item taking damage from things like running over sharp items.
	max_integrity = 50
	integrity_failure = 10
	/// How many tiles it should take to make a full turn, assuming it's not omnimaneuverable.
	var/turning_radius = 1
	/// How much the propulsion contributes to the vehicle's acceleration
	var/acceleration = 0
	/// Bool, whether or not this works to move the vehicle in space.
	var/spaceworthy = FALSE
	/// How effectively this form of propulsion can slow the vehicle.
	/// This value roughly translates to the amount of deceleration to provide every time we try to brake
	var/braking_power = 1
	/// How efficient this particular form of propulsion is, or how much extra power it uses.
	var/extra_power_usage = 0
	/// Whether this piece of propulsion is temporarily restrained, preventing its movement
	var/restrained = FALSE

/obj/item/vehicle_part/propulsion/proc/get_turning_radius()
	return turning_radius

/**
 * Jam up tires with some item (or nothing, in which case this might be null).
 */
/obj/item/vehicle_part/propulsion/wheelbase/proc/jam(atom/movable/jammer)
	// send signal
	restrained = TRUE

/**
 * Clear the jam
 */
/obj/item/vehicle_part/propulsion/wheelbase/proc/unjam(atom/movable/jammer)
	// send signal
	restrained = FALSE

/obj/item/vehicle_part/propulsion/wheelbase
	name = "wheels"
	desc = "A basic set of tires. Try not to kick them too hard."
	max_integrity = 25
	spaceworthy = FALSE
	turning_radius = 2
	braking_power = 2  // not too bad
	var/resistances = VEHICLE_TIRE_STRONG
	var/popped = FALSE
	/// Minimum amount of force on a sharp item before we even start checking for popping
	var/min_sharpness_threshold = 10
	/// How much resistance the thing has to popping.

/obj/item/vehicle_part/propulsion/wheelbase/proc/on_crossed(obj/vehicle/V, atom/movable/crossed_atom)
	SIGNAL_HANDLER  // COMSIG_CROSSED_MOVABLE
	if(istype(crossed_atom, /obj/item/restraints/legcuffs/bola) && !(resistances & VEHICLE_TIRE_BOLA_PROOF))
		jam(crossed_atom)
	if(isobj(crossed_atom))
		var/obj/crossed_obj = crossed_atom
		if(!(resistances & VEHICLE_TIRE_SHARP_PROOF) && crossed_obj.sharp && crossed_obj.force > min_sharpness_threshold)
			// check for popping
			take_damage(crossed_obj.force, BRUTE)




	// todo find a good clever way to handle caltrops
	if(crossed_atom.GetComponent(/datum/component/caltrop))
		return

	// todo add things like spike strips which have a 100% chance to pop tires when deployed

	// if(istype(crossed_atom))

/**
 * Pop tires, or in some other way render the propulsion unusable.
 */
/obj/item/vehicle_part/propulsion/wheelbase/proc/pop_tires(atom/movable/popper)
	return

/obj/item/vehicle_part/propulsion/wheelbase/obj_break(damage_flag)
	. = ..()
	popped = TRUE
	// send POPPED signal

/obj/item/vehicle_part/propulsion/wheelbase/on_insert(obj/vehicle/V)
	. = ..()
	// keep tabs on what we've passed over
	RegisterSignal(V, COMSIG_CROSSED_MOVABLE, PROC_REF(on_crossed))

/obj/item/vehicle_part/propulsion/wheelbase/on_removal(obj/vehicle/target, force)
	. = ..()
	UnregisterSignal(target, COMSIG_CROSSED_MOVABLE)

/obj/item/vehicle_part/propulsion/wheelbase/high_grip
	name = "high-traction tires"
	desc = "A set of high-traction tires with some tricked-out brakes. They look like they could stop on a dime."
	acceleration = 2
	braking_power = 4


/obj/item/vehicle_part/propulsion/flying
	name = "basic ion jets"
	desc = "A set of electrically-powered jets useful for moving around in zero-gravity without creating noxious emissions."
	spaceworthy = TRUE
	acceleration = 2
	turning_radius = 3
	braking_power = 1  // get up to speed pretty easily, but good luck slowing down.
	extra_power_usage = 2

/obj/item/vehicle_part/propulsion/flying/reversers
	name = "ion jets with thrust reversers"
	desc = "A set of ion jets with an integrated thrust reverser to assist with quick stops."
	braking_power = 3
	turning_radius = 2  // easier to control too
