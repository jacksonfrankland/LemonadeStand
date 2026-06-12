package drawing

import "../input"
import "core:math"
import "vendor:nanovg"

base_point: [2]f32
axis_unit_length: f32
nanovg_context: ^nanovg.Context
X_AXIS :: [2]f32{2 / math.SQRT_FIVE, -1 / math.SQRT_FIVE}
Y_AXIS :: [2]f32{-2 / math.SQRT_FIVE, -1 / math.SQRT_FIVE}
Z_AXIS :: [2]f32{0, -1}

draw :: proc(io: input.Details, nc: ^nanovg.Context) {
	nanovg_context = nc
	axis_unit_length = math.min(io.width / 2, io.height) / 11
	base_point = {io.width / 2, io.height / 2 + 2 * math.SQRT_FIVE * axis_unit_length}
	draw_base()
	draw_tree({5, 5, 0})
}

logical_to_real :: proc(point: [3]f32) -> (real: [2]f32) {
	real = base_point
	real += X_AXIS * axis_unit_length * point.x
	real += Y_AXIS * axis_unit_length * point.y
	real += Z_AXIS * axis_unit_length * point.z
	return
}

draw_base :: proc() {
	draw_shape(nanovg.ColorHex(0xff6ed6a4), {0, 0, 0}, {10, 0, 0}, {10, 10, 0}, {0, 10, 0})
	draw_shape(nanovg.ColorHex(0xff5ab9a2), {0, 0, 0}, {0, 0, -1}, {10, 0, -1}, {10, 0, 0})
	draw_shape(nanovg.ColorHex(0xff549a8d), {0, 0, 0}, {0, 0, -1}, {0, 10, -1}, {0, 10, 0})
}

draw_shape :: proc(color: nanovg.Color, points: ..[3]f32) {
	nanovg.BeginPath(nanovg_context)
	for point, i in points {
		p := logical_to_real(point)
		if i == 0 do nanovg.MoveTo(nanovg_context, p.x, p.y)
		else do nanovg.LineTo(nanovg_context, p.x, p.y)
	}
	nanovg.FillColor(nanovg_context, color)
	nanovg.Fill(nanovg_context)
}

draw_tree :: proc(position: [3]f32) {
	draw_shape(
		nanovg.ColorHex(0xff3b132b),
		position + {-.75, .75, 2},
		position + {.75, .75, 2},
		position + {.75, -.75, 2},
		position + {-.75, -.75, 2},
	)
	draw_shape(
		nanovg.ColorHex(0xffb2555d),
		position + {-.5, -.5, 0},
		position + {.5, -.5, 0},
		position + {.75, -.75, 2},
		position + {-.75, -.75, 2},
	)
	draw_shape(
		nanovg.ColorHex(0xff8b3a49),
		position + {-.5, -.5, 0},
		position + {-.5, .5, 0},
		position + {-.75, .75, 2},
		position + {-.75, -.75, 2},
	)
}
