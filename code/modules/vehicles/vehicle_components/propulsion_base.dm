#define VEHICLE_TIRE_WEAK (1 << 0)
#define VEHICLE_TIRE_BOLA_PROOF (1 << 1)
#define VEHICLE_TIRE_SHARP_PROOF (1 << 2)
/obj/item/vehicle_part/propulsion
	name = "propulsion"
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

/obj/item/vehicle_part/propulsion/proc/get_turning_radius()
	return turning_radius

/obj/item/vehicle_part/propulsion/wheelbase
	name = "wheels"
	desc = "A basic set of tires. Try not to kick them too hard."
	spaceworthy = FALSE
	turning_radius = 2
	braking_power = 2  // not too bad
	var/resistances = VEHICLE_TIRE_WEAK
	var/popped = FALSE
	var/restrained = FALSE

/obj/item/vehicle_part/propulsion/wheelbase/proc/on_crossed(obj/vehicle/V, atom/movable/crossed_atom)
	SIGNAL_HANDLER  // COMSIG_CROSSED_MOVABLE
	if(istype(crossed_atom, /obj/item/restraints/legcuffs/bola) && (resistances & VEHICLE_TIRE_BOLA_PROOF))
		pop_tires(crossed_atom)
		return

	if(istype(crossed_atom))

/obj/vehicle_part/propulsion/wheelbase/proc/pop_tires(atom/movable/popper)


/obj/vehicle_part/propulsion/wheelbase/proc/restrain(atom/movable/restraint)


/obj/vehicle_part/propulsion/wheelbase/on_insert(obj/vehicle/V)
	// keep tabs on what we've passed over
	RegisterSignal(V, COMSIG_CROSSED_MOVABLE, PROC_REF(on_crossed))

/obj/vehicle_part/propulsion/wheelbase/high_grip
	name = "high-traction tires"
	desc = "A set of high-traction tires with some tricked-out brakes. They look like they could stop on a dime."
	acceleration = 2
	braking_power = 4


/obj/vehicle_part/propulsion/flying
	name = "basic ion jets"
	desc = "A set of electrically-powered jets useful for moving around in zero-gravity without creating noxious emissions."
	spaceworthy = TRUE
	acceleration = 2
	turning_radius = 3
	braking_power = 1  // get up to speed pretty easily, but good luck slowing down.
	extra_power_usage = 2

/obj/vehicle_part/propulsion/flying/reversers
	name = "ion jets with thrust reversers"
	desc = "A set of ion jets with an integrated thrust reverser to assist with quick stops."
	braking_power = 3
	turning_radius = 2  // easier to control too
