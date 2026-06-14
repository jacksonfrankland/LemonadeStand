package main

import "core:fmt"
import "core:time"
import "drawing"
import "game"
import "input"
import "vendor:OpenGL"
import "vendor:glfw"
import "vendor:nanovg"
import nanovg_gl "vendor:nanovg/gl"

GL_MAJOR :: 3
GL_MINOR :: 3

main :: proc() {
	if !glfw.Init() {
		fmt.eprintln("glfw.Init failed")
		return
	}
	defer glfw.Terminate()

	glfw.WindowHint(glfw.CONTEXT_VERSION_MAJOR, GL_MAJOR)
	glfw.WindowHint(glfw.CONTEXT_VERSION_MINOR, GL_MINOR)
	glfw.WindowHint(glfw.OPENGL_PROFILE, glfw.OPENGL_CORE_PROFILE)
	glfw.WindowHint(glfw.OPENGL_FORWARD_COMPAT, glfw.TRUE)
	glfw.WindowHint(glfw.STENCIL_BITS, 8)
	glfw.WindowHint(glfw.SAMPLES, 4)

	window := glfw.CreateWindow(960, 540, "Lemon Stand", nil, nil)
	if window == nil {
		fmt.eprintln("glfw.CeateWindow failed")
		return
	}
	defer glfw.DestroyWindow(window)

	glfw.MakeContextCurrent(window)
	glfw.SwapInterval(1)
	OpenGL.load_up_to(GL_MAJOR, GL_MINOR, glfw.gl_set_proc_address)

	nanovg_context := nanovg_gl.Create({.ANTI_ALIAS, .STENCIL_STROKES})
	defer nanovg_gl.Destroy(nanovg_context)

	io := input.poll(window)
	game.init()

	last_time := time.tick_now()
	for !glfw.WindowShouldClose(window) {
		glfw.PollEvents()

		now := time.tick_now()
		delta := time.duration_seconds(time.tick_diff(last_time, now))
		last_time = now

		io = input.poll(window)

		game.update(delta, io)

		// Setup Render
		OpenGL.Viewport(0, 0, io.frame_width, io.frame_height)
		OpenGL.ClearColor(0, 0, 0, 1)
		OpenGL.Clear(OpenGL.COLOR_BUFFER_BIT | OpenGL.DEPTH_BUFFER_BIT | OpenGL.STENCIL_BUFFER_BIT)

		drawing.draw(io, nanovg_context)

		// Finish up
		glfw.SwapBuffers(window)
		free_all(context.temp_allocator)
	}
}
