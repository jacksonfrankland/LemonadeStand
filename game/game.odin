package game

import "../constants"
import "../helpers"
import "../input"
import "base:intrinsics"
import hm "core:container/handle_map"
import "core:math"
import "core:math/ease"

Handle :: hm.Handle32

Entity :: struct {
	handle:   Handle,
	type:     Entity_Type,
	position: [3]f32,
}

Entity_Type :: union {
	Tree,
	Citrus,
}

Citrus_Type :: enum {
	Lemon,
	Lime,
	Orange,
	Grapes,
}

Citrus_State :: union {
	Growing,
	Shrinking,
	Grown,
	Following,
}

Growing :: struct {
	current_growth: f64,
	grow_time:      f64,
}

Shrinking :: struct {
	current_growth: f64,
	grow_time:      f64,
}

Grown :: struct {
	hovering:    bool,
	destination: Maybe(Destination),
}

Following :: struct {
	origin: [3]f32,
}

Tree :: struct {
	citrus_type:      Citrus_Type,
	citrus:           [dynamic]Maybe(Handle),
	citrus_positions: [dynamic][3]f32,
	grow_time:        f64,
}

Citrus :: struct {
	type:  Citrus_Type,
	state: Citrus_State,
	tree:  Maybe(Handle),
}

Destination :: struct {
	original:    [3]f32,
	target:      [3]f32,
	time_passed: f64,
	total_time:  f64,
}

entities: hm.Dynamic_Handle_Map(Entity, Handle)
holding_citrus_type: Maybe(Citrus_Type)

init :: proc() {
	hm.dynamic_init(&entities, context.allocator)

	make_tree := proc(
		position: [3]f32,
		citrus_type: Citrus_Type,
		capacity: int,
		grow_time: f64,
		citrus_positions: ..[3]f32,
	) {

		type := Tree {
			citrus_type      = citrus_type,
			citrus           = make([dynamic]Maybe(Handle), capacity),
			citrus_positions = make([dynamic][3]f32, capacity),
			grow_time        = grow_time,
		}

		for citrus_position, i in citrus_positions {
			type.citrus_positions[i] = citrus_position
		}

		entity := Entity {
			position = position,
			type     = type,
		}

		tree_handle := hm.add(&entities, entity)
		citrus_handle := hm.add(
			&entities,
			Entity {
				position = entity.position + citrus_positions[0],
				type = Citrus {
					type = type.citrus_type,
					state = Growing{grow_time = type.grow_time},
					tree = tree_handle,
				},
			},
		)
		if entity, data, ok := get_entity_data(tree_handle, Tree); ok {
			data.citrus[0] = citrus_handle
		}
	}

	citrus_positions: [4][3]f32 = {
		{-.1833, 0, 1.45},
		{0, -.266, 1.2},
		{-.35, 0, .95},
		{0, -.433, 0.7},
	}
	make_tree(
		{1, 2, 0},
		.Lemon,
		4,
		4,
		citrus_positions[0],
		citrus_positions[1],
		citrus_positions[2],
		citrus_positions[3],
	)
	make_tree(
		{1, 4, 0},
		.Lime,
		3,
		16 / 3,
		citrus_positions[0],
		citrus_positions[1],
		citrus_positions[2],
	)
	make_tree({1, 6, 0}, .Orange, 2, 8, citrus_positions[0], citrus_positions[1])
	make_tree({1, 8, 0}, .Grapes, 1, 16, citrus_positions[0])
}

get_entity_data :: proc(
	handle: Handle,
	$T: typeid,
) -> (
	entity: ^Entity,
	data: ^T,
	ok: bool,
) where intrinsics.type_is_variant_of(Entity_Type, T) {
	entity_pointer, entity_ok := hm.dynamic_get(&entities, handle)
	if !entity_ok do return nil, nil, false
	type_data, type_ok := &entity_pointer.type.(T)
	if !type_ok do return nil, nil, false
	return entity_pointer, type_data, true
}

update :: proc(delta: f64, io: input.Details) {
	iterator := hm.iterator_make(&entities)
	for entity, handle in hm.iterate(&iterator) {
		switch &data in entity.type {
		case Tree:
		case Citrus:
			switch &state in data.state {
			case Grown:
				if destination, destination_ok := &state.destination.?; destination_ok {
					destination.time_passed += delta
					t := f32(destination.time_passed / destination.total_time)
					eased_t := ease.ease(.Quadratic_Out, t)
					entity.position = math.lerp(destination.original, destination.target, eased_t)
					if t >= 1 do state.destination = nil
				}
				state.hovering =
					helpers.magnitude_squared(
						io.mouse - helpers.logical_to_real(entity.position),
					) <=
					constants.CITRUS_RADIUS *
						helpers.axis_unit_length *
						constants.CITRUS_RADIUS *
						helpers.axis_unit_length
				if _, holding := holding_citrus_type.?;
				   !holding && state.hovering && io.mouse_down {
					holding_citrus_type = data.type
					data.state = Following {
						origin = entity.position,
					}
				}
			case Growing:
				state.current_growth += delta
				if state.current_growth > state.grow_time {
					data.state = Grown{}
					tree_handle, handle_ok := data.tree.?
					if !handle_ok do continue
					tree_entity, tree_data, tree_ok := get_entity_data(tree_handle, Tree)
					if !tree_ok do continue
					for &citrus, i in tree_data.citrus {
						_, citrus_ok := citrus.?
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
						citrus = new_handle
						break
					}
					continue
				}
			case Shrinking:
				state.current_growth -= delta
				if state.current_growth <= 0 {
					hm.dynamic_remove(&entities, handle)
					// TODO converter logic
				}
			case Following:
				if !io.mouse_down {
					data.state = Grown {
						destination = Destination {
							original = helpers.real_to_logical(io.mouse),
							target = state.origin,
							total_time = .25,
						},
					}
					holding_citrus_type = nil
				}
				entity.position = helpers.real_to_logical(io.mouse)
			}
		}
	}
}

destroy :: proc() {
	hm.dynamic_destroy(&entities)
}
