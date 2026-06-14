package drawing

import "../constants"
import "../game"
import "../helpers"
import "../input"
import hm "core:container/handle_map"
import "core:math"
import "vendor:nanovg"

nanovg_context: ^nanovg.Context

draw :: proc(io: input.Details, nc: ^nanovg.Context) {
	nanovg_context = nc
	nanovg.BeginFrame(nanovg_context, io.width, io.height, max(io.pixel_ratio, 1))

	helpers.axis_unit_length = math.min(io.width / 2, io.height) / 11
	helpers.base_point = {
		io.width / 2,
		io.height / 2 + 2 * math.SQRT_FIVE * helpers.axis_unit_length,
	}
	draw_base()

	iterator := hm.iterator_make(&game.entities)
	for entity, handle in hm.iterate(&iterator) {
		if tree, tree_ok := entity.type.(game.Tree); tree_ok {
			draw_tree(entity, tree)
		}
	}
	for entity, handle in hm.iterate(&iterator) {
		if citrus, citrus_ok := entity.type.(game.Citrus); citrus_ok {
			draw_citrus(entity, citrus)
		}
	}
	nanovg.EndFrame(nanovg_context)
}


draw_base :: proc() {
	draw_shape(nanovg.ColorHex(0xff6ed6a4), {0, 0, 0}, {10, 0, 0}, {10, 10, 0}, {0, 10, 0})
	draw_shape(nanovg.ColorHex(0xff5ab9a2), {0, 0, 0}, {0, 0, -1}, {10, 0, -1}, {10, 0, 0})
	draw_shape(nanovg.ColorHex(0xff549a8d), {0, 0, 0}, {0, 0, -1}, {0, 10, -1}, {0, 10, 0})
}

draw_shape :: proc(color: nanovg.Color, points: ..[3]f32) {
	nanovg.BeginPath(nanovg_context)
	for point, i in points {
		p := helpers.logical_to_real(point)
		if i == 0 do nanovg.MoveTo(nanovg_context, p.x, p.y)
		else do nanovg.LineTo(nanovg_context, p.x, p.y)
	}
	nanovg.FillColor(nanovg_context, color)
	nanovg.Fill(nanovg_context)
}

draw_circle :: proc(color: nanovg.Color, position: [3]f32, radius: f32) {
	nanovg.BeginPath(nanovg_context)
	point := helpers.logical_to_real(position)
	nanovg.Circle(nanovg_context, point.x, point.y, helpers.axis_unit_length * radius)
	nanovg.FillColor(nanovg_context, color)
	nanovg.Fill(nanovg_context)
}

draw_circle_outline :: proc(
	color: nanovg.Color,
	position: [3]f32,
	radius: f32,
	stroke_width: f32,
) {
	nanovg.BeginPath(nanovg_context)
	point := helpers.logical_to_real(position)
	nanovg.Circle(nanovg_context, point.x, point.y, helpers.axis_unit_length * radius)
	nanovg.StrokeWidth(nanovg_context, stroke_width)
	nanovg.StrokeColor(nanovg_context, color)
	nanovg.Stroke(nanovg_context)
}

draw_tree :: proc(entity: ^game.Entity, tree: game.Tree) {
	position := entity.position
	draw_shape(
		nanovg.ColorHex(0xff3b132b),
		position + {-.3, .3, .5},
		position + {.3, .3, .5},
		position + {.3, -.3, .5},
		position + {-.3, -.3, .5},
	)
	draw_shape(
		nanovg.ColorHex(0xffb2555d),
		position + {-.2, -.2, 0},
		position + {.2, -.2, 0},
		position + {.3, -.3, .5},
		position + {-.3, -.3, .5},
	)
	draw_shape(
		nanovg.ColorHex(0xff8b3a49),
		position + {-.2, -.2, 0},
		position + {-.2, .2, 0},
		position + {-.3, .3, .5},
		position + {-.3, -.3, .5},
	)
	draw_shape(
		nanovg.ColorHex(0xFFBCD979),
		position + {-.5, -.5, .5},
		position + {.5, -.5, .5},
		position + {0, 0, 2},
	)
	draw_shape(
		nanovg.ColorHex(0xFF28502E),
		position + {-.5, -.5, .5},
		position + {-.5, .5, .5},
		position + {0, 0, 2},
	)
	for citrus_position in tree.citrus_positions {
		draw_circle(
			nanovg.RGBA(0, 0, 0, 100),
			entity.position + citrus_position,
			constants.CITRUS_RADIUS,
		)
	}
}

draw_citrus :: proc(entity: ^game.Entity, citrus: game.Citrus) {
	colors := [game.Citrus_Type]nanovg.Color {
		.Lemon  = nanovg.RGB(255, 255, 0),
		.Lime   = nanovg.RGB(0, 255, 0),
		.Orange = nanovg.RGB(255, 165, 0),
		.Grapes = nanovg.RGB(218, 177, 218),
	}
	switch data in citrus.state {
	case game.Growing:
		draw_circle(
			colors[citrus.type],
			entity.position,
			constants.CITRUS_RADIUS * f32(data.current_growth / data.grow_time),
		)
	case game.Shrinking:
		draw_circle(
			colors[citrus.type],
			entity.position,
			constants.CITRUS_RADIUS * f32(data.current_growth / data.grow_time),
		)
	case game.Grown:
		color := colors[citrus.type]
		color.a = .4
		draw_circle_outline(
			data.hovering ? nanovg.RGB(255, 255, 255) : color,
			entity.position,
			constants.CITRUS_RADIUS,
			helpers.axis_unit_length * .07,
		)
		draw_circle(colors[citrus.type], entity.position, constants.CITRUS_RADIUS)
	case game.Following:
		draw_circle(colors[citrus.type], entity.position, constants.CITRUS_RADIUS)
	}
}
