package game

import "base:intrinsics"
import hm "core:container/handle_map"

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
}

Growing :: struct {
	current_growth: f64,
	grow_time:      f64,
}

Shrinking :: struct {
	current_growth: f64,
	grow_time:      f64,
}

Grown :: struct {}

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

entities: hm.Dynamic_Handle_Map(Entity, Handle)

init :: proc() {
	hm.dynamic_init(&entities, context.allocator)

	make_tree := proc(position: [3]f32, citrus_type: Citrus_Type, capacity: int, grow_time: f64) {
		_ = hm.add(
			&entities,
			Entity {
				position = position,
				type = Tree {
					citrus_type = citrus_type,
					citrus = make([dynamic]Maybe(Handle), capacity),
					citrus_positions = make([dynamic][3]f32, capacity),
					grow_time = grow_time,
				},
			},
		)
	}

	make_tree({1, 2, 0}, .Lemon, 4, 1)
	make_tree({1, 4, 0}, .Lime, 3, 4 / 3)
	make_tree({1, 6, 0}, .Orange, 2, 2)
	make_tree({1, 8, 0}, .Grapes, 1, 4)
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

update :: proc(delta: f64) {
	iterator := hm.iterator_make(&entities)
	for entity, handle in hm.iterate(&iterator) {
		switch &data in entity.type {
		case Tree:
		case Citrus:
			switch &state in data.state {
			case Grown:
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
								position = tree_data.citrus_positions[i],
								type = Citrus {
									type = tree_data.citrus_type,
									state = Growing{grow_time = tree_data.grow_time},
									tree = tree_handle,
								},
							},
						)
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
			}
		}
	}
}

destroy :: proc() {
	hm.dynamic_destroy(&entities)
}
