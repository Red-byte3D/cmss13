// This is where the fun begins.
// These are the main datums that emit light.

/datum/static_light_source
	///The atom we're emitting light from (for example a mob if we're from a flashlight that's being held).
	var/atom/top_atom
	///The atom that we belong to.
	var/atom/source_atom

	///The turf under the source atom.
	var/turf/source_turf
	///The turf the top_atom appears to over.
	var/turf/pixel_turf
	///Intensity of the emitter light.
	var/light_power
	/// The range of the emitted light.
	var/light_range
	/// The colour of the light, string, decomposed by parse_light_color()
	var/light_color
	// Variables for keeping track of the colour.
	var/lum_r
	var/lum_g
	var/lum_b

	// The lumcount values used to apply the light.
	var/tmp/applied_lum_r
	var/tmp/applied_lum_g
	var/tmp/applied_lum_b

	/// List used to store how much we're affecting corners.
	var/list/datum/static_lighting_corner/effect_str

	/// Whether we have applied our light yet or not.
	var/applied = FALSE

	/// whether we are to be added to SSlighting's static_sources_queue list for an update
	var/needs_update = LIGHTING_NO_UPDATE

// Thanks to Lohikar for flinging this tiny bit of code at me, increasing my brain cell count from 1 to 2 in the process.
// This macro will only offset up to 1 tile, but anything with a greater offset is an outlier and probably should handle its own lighting offsets.
// Anything pixelshifted 16px or more will be considered on the next tile.
#define GET_APPROXIMATE_PIXEL_DIR(PX, PY) ((!(PX) ? 0 : ((PX >= 16 ? EAST : (PX <= -16 ? WEST : 0)))) | (!PY ? 0 : (PY >= 16 ? NORTH : (PY <= -16 ? SOUTH : 0))))
#define UPDATE_APPROXIMATE_PIXEL_TURF var/_mask = GET_APPROXIMATE_PIXEL_DIR(top_atom.pixel_x, top_atom.pixel_y); pixel_turf = _mask ? (get_step(source_turf, _mask) || source_turf) : source_turf

/datum/static_light_source/New(atom/owner, atom/top)
	source_atom = owner // Set our new owner.
	LAZYADD(source_atom.static_light_sources, src)
	top_atom = top
	if (top_atom != source_atom)
		LAZYADD(top_atom.static_light_sources, src)

	source_turf = top_atom
	UPDATE_APPROXIMATE_PIXEL_TURF

	light_power = source_atom.light_power
	light_range = source_atom.light_range
	light_color = source_atom.light_color

	PARSE_LIGHT_COLOR(src)

	update()

/datum/static_light_source/Destroy(force)
	remove_lum()
	if (source_atom)
		LAZYREMOVE(source_atom.static_light_sources, src)

	if (top_atom)
		LAZYREMOVE(top_atom.static_light_sources, src)

	if (needs_update)
		SSlighting.static_sources_queue -= src
	return ..()

#define EFFECT_UPDATE(level) \
	if (needs_update == LIGHTING_NO_UPDATE) \
		SSlighting.static_sources_queue += src; \
	if (needs_update < level) \
		needs_update = level; \


/// This proc will cause the light source to update the top atom, and add itself to the update queue.
/datum/static_light_source/proc/update(atom/new_top_atom)
	// This top atom is different.
	if (new_top_atom && new_top_atom != top_atom)
		if(top_atom != source_atom && top_atom.static_light_sources) // Remove ourselves from the light sources of that top atom.
			LAZYREMOVE(top_atom.static_light_sources, src)

		top_atom = new_top_atom

		if (top_atom != source_atom)
			LAZYADD(top_atom.static_light_sources, src) // Add ourselves to the light sources of our new top atom.

	EFFECT_UPDATE(LIGHTING_CHECK_UPDATE)

/// Will force an update without checking if it's actually needed.
/datum/static_light_source/proc/force_update()
	EFFECT_UPDATE(LIGHTING_FORCE_UPDATE)

/// Will cause the light source to recalculate turfs that were removed or added to visibility only.
/datum/static_light_source/proc/vis_update()
	EFFECT_UPDATE(LIGHTING_VIS_UPDATE)

// Macro that applies light to a new corner.
// It is a macro in the interest of speed, yet not having to copy paste it.
// If you're wondering what's with the backslashes, the backslashes cause BYOND to not automatically end the line.
// As such this all gets counted as a single line.
// The braces and semicolons are there to be able to do this on a single line.

//Original lighting falloff calculation. This looks the best out of the three. However, this is also the most expensive.
//#define LUM_FALLOFF(C, T) (1 - CLAMP01(sqrt((C.x - T.x) ** 2 + (C.y - T.y) ** 2 + LIGHTING_HEIGHT) / max(1, light_range)))

//Cubic lighting falloff. This has the *exact* same range as the original lighting falloff calculation, down to the exact decimal, but it looks a little unnatural due to the harsher falloff and how it's generally brighter across the board.
//#define LUM_FALLOFF(C, T) (1 - CLAMP01((((C.x - T.x) * (C.x - T.x)) + ((C.y - T.y) * (C.y - T.y)) + LIGHTING_HEIGHT) / max(1, light_range*light_range)))

//Linear lighting falloff. This resembles the original lighting falloff calculation the best, but results in lights having a slightly larger range, which is most noticeable with large light sources. This also results in lights being diamond-shaped, fuck. This looks the darkest out of the three due to how lights are brighter closer to the source compared to the original falloff algorithm. This falloff method also does not at all take into account lighting height, as it acts as a flat reduction to light range with this method.
//#define LUM_FALLOFF(C, T) (1 - CLAMP01(((abs(C.x - T.x) + abs(C.y - T.y))) / max(1, light_range+1)))

//Linear lighting falloff but with an octagonal shape in place of a diamond shape. Lummox JR please add pointer support.
#define GET_LUM_DIST(DISTX, DISTY) (DISTX + DISTY + abs(DISTX - DISTY)*0.4)
#define LUM_FALLOFF(C, T) (1 - CLAMP01(max(GET_LUM_DIST(abs(C.x - T.x), abs(C.y - T.y)),LIGHTING_HEIGHT) / max(1, light_range+1)))

#define APPLY_CORNER(C)                          \
	. = LUM_FALLOFF(C, pixel_turf);              \
	. *= light_power;                            \
	var/OLD = effect_str[C];                     \
	C.update_lumcount                            \
	(                                            \
		(. * lum_r) - (OLD * applied_lum_r),     \
		(. * lum_g) - (OLD * applied_lum_g),     \
		(. * lum_b) - (OLD * applied_lum_b)      \
	);

#define REMOVE_CORNER(C)                         \
	. = -effect_str[C];                          \
	C.update_lumcount                            \
	(                                            \
		. * applied_lum_r,                       \
		. * applied_lum_g,                       \
		. * applied_lum_b                        \
	);

/// This is the define used to calculate falloff.
/datum/static_light_source/proc/remove_lum()
	applied = FALSE
	for(var/datum/static_lighting_corner/corner as anything in effect_str)
		REMOVE_CORNER(corner)
		LAZYREMOVE(corner.affecting, src)

	effect_str = null

/datum/static_light_source/proc/recalc_corner(datum/static_lighting_corner/corner)
	LAZYINITLIST(effect_str)
	if (effect_str[corner]) // Already have one.
		REMOVE_CORNER(corner)
		effect_str[corner] = 0

	APPLY_CORNER(corner)
	effect_str[corner] = .

/datum/static_light_source/proc/update_corners()
	var/update = FALSE
	var/atom/source_atom = src.source_atom

	if (QDELETED(source_atom))
		qdel(src)
		return

	if (source_atom.light_power != light_power)
		light_power = source_atom.light_power
		update = TRUE

	if (source_atom.light_range != light_range)
		light_range = source_atom.light_range
		update = TRUE

	if (!top_atom)
		top_atom = source_atom
		update = TRUE

	if (!light_range || !light_power)
		qdel(src)
		return

	if (isturf(top_atom))
		if (source_turf != top_atom)
			source_turf = top_atom
			UPDATE_APPROXIMATE_PIXEL_TURF
			update = TRUE
	else if (top_atom.loc != source_turf)
		source_turf = top_atom.loc
		UPDATE_APPROXIMATE_PIXEL_TURF
		update = TRUE
	else
		var/pixel_loc = get_turf_pixel(top_atom)
		if (pixel_loc != pixel_turf)
			pixel_turf = pixel_loc
			update = TRUE

	if (!isturf(source_turf))
		if (applied)
			remove_lum()
		return

	if (light_range && light_power && !applied)
		update = TRUE

	if (source_atom.light_color != light_color)
		light_color = source_atom.light_color
		PARSE_LIGHT_COLOR(src)
		update = TRUE

	else if (applied_lum_r != lum_r || applied_lum_g != lum_g || applied_lum_b != lum_b)
		update = TRUE

	if (update)
		needs_update = LIGHTING_CHECK_UPDATE
		applied = TRUE
	else if (needs_update == LIGHTING_CHECK_UPDATE)
		return //nothing's changed

	var/list/datum/static_lighting_corner/corners = list()
	var/list/turf/turfs = list()
	if (source_turf)
		var/oldlum = source_turf.luminosity
		source_turf.luminosity = ceil(light_range)
		for(var/turf/T in view(ceil(light_range), source_turf))
			if(!IS_OPAQUE_TURF(T))
				if (!T.lighting_corners_initialised)
					T.static_generate_missing_corners()
				corners[T.lighting_corner_NE] = 0
				corners[T.lighting_corner_SE] = 0
				corners[T.lighting_corner_SW] = 0
				corners[T.lighting_corner_NW] = 0
			turfs += T

			var/turf/above = SSmapping.get_turf_above(T)

			while(above && istransparentturf(above))
				if (!above.lighting_corners_initialised)
					above.static_generate_missing_corners()
				corners[above.lighting_corner_NE] = 0
				corners[above.lighting_corner_SE] = 0
				corners[above.lighting_corner_SW] = 0
				corners[above.lighting_corner_NW] = 0

				above = SSmapping.get_turf_above(above)

			turfs += above

			var/turf/below = SSmapping.get_turf_below(T)
			var/turf/previous = T

			while(below && istransparentturf(previous))
				if (!below.lighting_corners_initialised)
					below.static_generate_missing_corners()
				corners[below.lighting_corner_NE] = 0
				corners[below.lighting_corner_SE] = 0
				corners[below.lighting_corner_SW] = 0
				corners[below.lighting_corner_NW] = 0

				previous = below
				below = SSmapping.get_turf_below(below)

		source_turf.luminosity = oldlum

	var/list/datum/static_lighting_corner/new_corners = (corners - effect_str)
	LAZYINITLIST(effect_str)
	if (needs_update == LIGHTING_VIS_UPDATE)
		for (var/datum/static_lighting_corner/corner as anything in new_corners)
			APPLY_CORNER(corner)
			if (. != 0)
				LAZYADD(corner.affecting, src)
				effect_str[corner] = .
	else
		for (var/datum/static_lighting_corner/corner as anything in new_corners)
			APPLY_CORNER(corner)
			if (. != 0)
				LAZYADD(corner.affecting, src)
				effect_str[corner] = .

		for (var/datum/static_lighting_corner/corner as anything in corners - new_corners) // Existing corners
			APPLY_CORNER(corner)
			if (. != 0)
				effect_str[corner] = .
			else
				LAZYREMOVE(corner.affecting, src)
				effect_str -= corner

	var/list/datum/static_lighting_corner/gone_corners = effect_str - corners
	for (var/datum/static_lighting_corner/corner as anything in gone_corners)
		REMOVE_CORNER(corner)
		LAZYREMOVE(corner.affecting, src)
	effect_str -= gone_corners

	applied_lum_r = lum_r
	applied_lum_g = lum_g
	applied_lum_b = lum_b

	UNSETEMPTY(effect_str)

#undef EFFECT_UPDATE
#undef LUM_FALLOFF
#undef GET_LUM_DIST
#undef REMOVE_CORNER
#undef APPLY_CORNER
