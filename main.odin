package main

import "core:fmt"
import "core:math"
import "core:time"
import "input"
import "vendor:OpenGL"
import "vendor:glfw"
import "vendor:nanovg"
import nanovg_gl "vendor:nanovg/gl"

GL_MAJOR :: 3
GL_MINOR :: 3

Citrus :: enum {
	None,
	Lemon,
	Lime,
	Orange,
	Grapes,
}

Citrus_State :: enum {
	Gone,
	Growing,
	Grown,
}

Tree :: struct {
	citrus:         Citrus,
	citrus_slots:   [dynamic]Citrus_State,
	amount:         int,
	capacity:       int,
	grow_time:      f64,
	current_growth: f64,
}

Converters :: struct {
	input:            [dynamic]Citrus,
	output:           [dynamic]Citrus,
	recipe_input:     [dynamic]Citrus,
	recipe_output:    [dynamic]Citrus,
	run_time:         f64,
	current_run_time: f64,
}

Recipe :: struct {
	ingredients: [dynamic]Citrus,
}

trees: [4]Tree
basket: [dynamic]Citrus

init :: proc() {
	trees = [4]Tree {
		Tree{.Lemon, make([dynamic]Citrus_State, 4), 0, 4, 2, 0},
		Tree{.Lime, make([dynamic]Citrus_State, 3), 0, 3, 3, 0},
		Tree{.Orange, make([dynamic]Citrus_State, 2), 0, 2, 4, 0},
		Tree{.Grapes, make([dynamic]Citrus_State, 1), 0, 1, 5, 0},
	}
	basket = make([dynamic]Citrus, 8)
}

update :: proc(delta: f64) {
	// grow citrus
	for &tree in trees {
		if tree.amount >= tree.capacity do continue
		tree.current_growth += delta
		for &slot in tree.citrus_slots {
			if slot == .Growing do break
			if slot == .Gone {
				slot = .Growing
				break
			}
		}
		if tree.current_growth < tree.grow_time do continue

		tree.amount += 1
		tree.current_growth -= tree.grow_time
		for &slot in tree.citrus_slots {
			if slot == .Growing {
				slot = .Grown
				break
			}
		}
	}
}

draw :: proc(io: input.Details, nanovg_context: ^nanovg.Context) {
	nanovg.BeginFrame(nanovg_context, io.width, io.height, max(io.pixel_ratio, 1))

	drawTree(io, nanovg_context, io.height * .2, io.height * .2, trees[0])
	drawTree(io, nanovg_context, io.height * .2, io.height * .4, trees[1])
	drawTree(io, nanovg_context, io.height * .2, io.height * .6, trees[2])
	drawTree(io, nanovg_context, io.height * .2, io.height * .8, trees[3])

	drawBasket(io, nanovg_context)

	nanovg.EndFrame(nanovg_context)
}

drawTree :: proc(io: input.Details, nanovg_context: ^nanovg.Context, x, y: f32, tree: Tree) {
	nanovg.BeginPath(nanovg_context)
	nanovg.RoundedRect(
		nanovg_context,
		x - io.height * .075,
		y - io.height * .075,
		io.height * .15,
		io.height * .15,
		io.height * .01,
	)
	nanovg.FillColor(nanovg_context, nanovg.RGB(135, 163, 46))
	nanovg.Fill(nanovg_context)

	colors := [Citrus]nanovg.Color {
		.None   = nanovg.RGB(255, 255, 255),
		.Lemon  = nanovg.RGB(255, 255, 0),
		.Lime   = nanovg.RGB(0, 255, 0),
		.Orange = nanovg.RGB(255, 165, 0),
		.Grapes = nanovg.RGB(138, 43, 226),
	}

	for slot, i in tree.citrus_slots {
		logicalX := f32(i % 3)
		logicalY := f32(math.floor(f32(i) / 3))
		slotSpace := io.height * .15 / 4
		xPosition := (x - io.height * .075) + slotSpace * logicalX + slotSpace
		yPosition := (y - io.height * .075) + slotSpace * logicalY + slotSpace

		nanovg.BeginPath(nanovg_context)
		nanovg.Circle(nanovg_context, xPosition, yPosition, io.height * .01)
		nanovg.FillColor(nanovg_context, nanovg.RGBA(0, 0, 0, 50))
		nanovg.Fill(nanovg_context)

		if slot == .Grown {
			nanovg.BeginPath(nanovg_context)
			nanovg.Circle(nanovg_context, xPosition, yPosition, io.height * .01)
			nanovg.StrokeColor(nanovg_context, nanovg.RGBA(255, 255, 255, 50))
			nanovg.StrokeWidth(nanovg_context, io.height * .01)
			nanovg.Stroke(nanovg_context)
			nanovg.BeginPath(nanovg_context)
			nanovg.Circle(nanovg_context, xPosition, yPosition, io.height * .01)
			nanovg.FillColor(nanovg_context, colors[tree.citrus])
			nanovg.Fill(nanovg_context)
		}

		if slot == .Growing {
			nanovg.BeginPath(nanovg_context)
			nanovg.Circle(
				nanovg_context,
				xPosition,
				yPosition,
				io.height * .01 * f32(tree.current_growth / tree.grow_time),
			)
			nanovg.FillColor(nanovg_context, colors[tree.citrus])
			nanovg.Fill(nanovg_context)
		}
	}
}

drawBasket :: proc(io: input.Details, nanovg_context: ^nanovg.Context) {
	nanovg.BeginPath(nanovg_context)
	nanovg.RoundedRect(
		nanovg_context,
		io.width * .2,
		io.height * .02,
		io.width * .6,
		io.height * .05,
		io.width * .01,
	)
	nanovg.FillColor(nanovg_context, nanovg.RGB(120, 120, 120))
	nanovg.Fill(nanovg_context)
}

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

	init()
	last_time := time.tick_now()
	for !glfw.WindowShouldClose(window) {
		glfw.PollEvents()

		now := time.tick_now()
		delta := time.duration_seconds(time.tick_diff(last_time, now))
		last_time = now

		io := input.poll(window)

		update(delta)

		// Setup Render
		OpenGL.Viewport(0, 0, io.frame_width, io.frame_height)
		OpenGL.ClearColor(0, 0, 0, 1)
		OpenGL.Clear(OpenGL.COLOR_BUFFER_BIT | OpenGL.DEPTH_BUFFER_BIT | OpenGL.STENCIL_BUFFER_BIT)

		draw(io, nanovg_context)

		// Finish up
		glfw.SwapBuffers(window)
		free_all(context.temp_allocator)
	}
}
