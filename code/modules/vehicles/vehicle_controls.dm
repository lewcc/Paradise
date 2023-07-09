/**
 * Controls for a vehicle.
 * Icon changes based on the speed of the vehicle itself, and the "grip" determines the degree of control the user has.
 */
/obj/item/twohanded/vehicle_controls
	// TODO make a better icon that reflects the acceleration level
	icon = 'icons/obj/vehicles.dmi'
	icon_state = "keyjanitor"
	var/speed_level = 0
	/// The vehicle these controls control
	var/obj/vehicle/connected_vehicle

/obj/item/twohanded/vehicle_controls/Initialize(mapload, obj/vehicle/controlling)
	. = ..()
	connected_vehicle = controlling

/obj/item/twohanded/vehicle_controls/Destroy()
	. = ..()
	connected_vehicle = null








