package game

import "../constants"
import "../helpers"
import "../input"
import hm "core:container/handle_map"
import "core:math"
import "core:math/ease"

update_citrus :: proc(
	entity: ^Entity,
	citrus: ^Citrus,
	handle: Handle,
	delta: f64,
	io: input.Details,
) {
	switch &state in citrus.state {
	case Grown:
		if destination, destination_ok := &state.destination.?; destination_ok {
			destination.time_passed += delta
			t := f32(destination.time_passed / destination.total_time)
			eased_t := ease.ease(.Quadratic_Out, t)
			entity.position = math.lerp(destination.original, destination.target, eased_t)
			if t >= 1 do state.destination = nil
		}
		state.hovering =
			helpers.magnitude_squared(io.mouse - helpers.logical_to_real(entity.position)) <=
			constants.CITRUS_RADIUS *
				helpers.axis_unit_length *
				constants.CITRUS_RADIUS *
				helpers.axis_unit_length
		if _, holding := holding_citrus.?; !holding && state.hovering && io.mouse_down {
			holding_citrus = handle
			citrus.state = Following {
				origin = entity.position,
			}
		}
	case Growing:
		state.current_growth += delta
		if state.current_growth > state.grow_time {
			citrus.state = Grown{}
			tree_handle, handle_ok := citrus.tree.?
			if !handle_ok do return
			tree_entity, tree_data, tree_ok := get_entity_data(tree_handle, Tree)
			if !tree_ok do return
			for &trees_citrus, i in tree_data.citrus {
				_, citrus_ok := trees_citrus.?
				if citrus_ok do continue
				new_handle := hm.add(
					&entities,
					Entity {
						position = tree_entity.position + tree_data.citrus_positions[i],
						type = Citrus {
							type = tree_data.citrus_type,
							state = Growing{grow_time = tree_data.grow_time},
							tree = tree_handle,
						},
					},
				)
				trees_citrus = new_handle
				return
			}
			return
		}
	case Shrinking:
		state.current_growth -= delta
		if state.current_growth <= 0 {
			hm.dynamic_remove(&entities, handle)
			// TODO converter logic
		}
	case Following:
		if !io.mouse_down {
			citrus.state = Grown {
				destination = Destination {
					original = helpers.real_to_logical(io.mouse),
					target = state.origin,
					total_time = .25,
				},
			}
			holding_citrus = nil
		}
		entity.position = helpers.real_to_logical(io.mouse)
	}
}
