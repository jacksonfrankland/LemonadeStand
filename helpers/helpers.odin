package helpers

import "core:math"

base_point: [2]f32
axis_unit_length: f32
X_AXIS :: [2]f32{2 / math.SQRT_FIVE, -1 / math.SQRT_FIVE}
Y_AXIS :: [2]f32{-2 / math.SQRT_FIVE, -1 / math.SQRT_FIVE}
Z_AXIS :: [2]f32{0, -1}

magnitude_squared :: proc(vector: [2]f32) -> f32 {
	return vector.x * vector.x + vector.y * vector.y
}

logical_to_real :: proc(point: [3]f32) -> (real: [2]f32) {
	real = base_point
	real += X_AXIS * axis_unit_length * point.x
	real += Y_AXIS * axis_unit_length * point.y
	real += Z_AXIS * axis_unit_length * point.z
	return
}

real_to_logical :: proc(point: [2]f32) -> (logical: [3]f32) {
	offset := (point - base_point) / axis_unit_length

	det := X_AXIS.x * Y_AXIS.y - X_AXIS.y * Y_AXIS.x
	logical.x = (offset.x * Y_AXIS.y - offset.y * Y_AXIS.x) / det
	logical.y = (X_AXIS.x * offset.y - X_AXIS.y * offset.x) / det
	logical.z = 0
	return
}
