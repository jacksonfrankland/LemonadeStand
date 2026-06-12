package input

import "vendor:glfw"

Details :: struct {
	mouse:        [2]f32,
	mouse_down:   bool,
	frame_width:  i32,
	frame_height: i32,
	width:        f32,
	height:       f32,
	pixel_ratio:  f32,
}

poll :: proc "contextless" (win: glfw.WindowHandle) -> (details: Details) {
	fb_width, fb_height := glfw.GetFramebufferSize(win)
	ww, _ := glfw.GetWindowSize(win)
	details.frame_width = fb_width
	details.frame_height = fb_height
	details.pixel_ratio = ww > 0 ? f32(fb_width) / f32(ww) : 1
	details.width = f32(details.frame_width) / max(details.pixel_ratio, 1)
	details.height = f32(details.frame_height) / max(details.pixel_ratio, 1)

	mx, my := glfw.GetCursorPos(win)
	details.mouse = {f32(mx) * details.pixel_ratio, f32(my) * details.pixel_ratio}
	details.mouse_down = glfw.GetMouseButton(win, glfw.MOUSE_BUTTON_LEFT) == glfw.PRESS
	return
}
