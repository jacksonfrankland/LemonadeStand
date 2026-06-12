package main

import "core:fmt"
import "core:math"
import "core:time"
import "drawing"
import "input"
import "vendor:OpenGL"
import "vendor:glfw"
import "vendor:nanovg"
import nanovg_gl "vendor:nanovg/gl"

GL_MAJOR :: 3
GL_MINOR :: 3

Maybe :: union($T: typeid) {
	T,
}

Entity :: struct {
	position: [2]f32,
}

Citrus_Type :: enum {
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
	using entity:   Entity,
	citrus_type:    Citrus_Type,
	citrus:         [dynamic]Citrus,
	amount:         int,
	capacity:       int,
	grow_time:      f64,
	current_growth: f64,
}

Citrus :: struct {
	using entity: Entity,
	type:         Citrus_Type,
	state:        Citrus_State,
}

Converters :: struct {
	input:            [dynamic]Citrus_Type,
	output:           [dynamic]Citrus_Type,
	recipe_input:     [dynamic]Citrus_Type,
	recipe_output:    [dynamic]Citrus_Type,
	run_time:         f64,
	current_run_time: f64,
}

Recipe :: struct {
	ingredients: [dynamic]Citrus_Type,
}

trees: [4]Tree
basket: [dynamic]Citrus_Type
carried: Maybe(Citrus_Type)
citrus_radius: f32

init :: proc(io: input.Details) {
	trees = [4]Tree {
		Tree{citrus_type = .Lemon, citrus = make([dynamic]Citrus, 4), capacity = 4, grow_time = 2},
		Tree{citrus_type = .Lime, citrus = make([dynamic]Citrus, 3), capacity = 3, grow_time = 3},
		Tree {
			citrus_type = .Orange,
			citrus = make([dynamic]Citrus, 2),
			capacity = 2,
			grow_time = 4,
		},
		Tree {
			citrus_type = .Grapes,
			citrus = make([dynamic]Citrus, 1),
			capacity = 1,
			grow_time = 5,
		},
	}
	basket = make([dynamic]Citrus_Type, 8)

}

update :: proc(delta: f64, io: input.Details) {
	trees[0].position = {io.height * .2, io.height * .2}
	trees[1].position = {io.height * .2, io.height * .4}
	trees[2].position = {io.height * .2, io.height * .6}
	trees[3].position = {io.height * .2, io.height * .8}

	for tree in trees {
		for &citrus, i in tree.citrus {
			logicalX := f32(i % 3)
			logicalY := f32(math.floor(f32(i) / 3))
			slotSpace := io.height * .15 / 4
			xPosition := (tree.position.x - io.height * .075) + slotSpace * logicalX + slotSpace
			yPosition := (tree.position.y - io.height * .075) + slotSpace * logicalY + slotSpace
			citrus.position = {xPosition, yPosition}
		}
	}
	citrus_radius = io.height * .01

	// grow citrus
	for &tree in trees {
		if tree.amount >= tree.capacity do continue
		tree.current_growth += delta
		for &citrus in tree.citrus {
			if citrus.state == .Growing do break
			if citrus.state == .Gone {
				citrus.state = .Growing
				break
			}
		}
		if tree.current_growth < tree.grow_time do continue

		tree.amount += 1
		tree.current_growth -= tree.grow_time
		for &citrus in tree.citrus {
			if citrus.state == .Growing {
				citrus.state = .Grown
				break
			}
		}
	}

	// hover citrus
	for tree in trees {
		for citrus in tree.citrus {

		}
	}
}

draw :: proc(io: input.Details, nanovg_context: ^nanovg.Context) {
	nanovg.BeginFrame(nanovg_context, io.width, io.height, max(io.pixel_ratio, 1))

	drawing.draw(io, nanovg_context)
	// drawTree(io, nanovg_context, trees[0])
	// drawTree(io, nanovg_context, trees[1])
	// drawTree(io, nanovg_context, trees[2])
	// drawTree(io, nanovg_context, trees[3])

	// drawBasket(io, nanovg_context)

	nanovg.EndFrame(nanovg_context)
}

drawTree :: proc(io: input.Details, nanovg_context: ^nanovg.Context, tree: Tree) {
	nanovg.BeginPath(nanovg_context)
	nanovg.RoundedRect(
		nanovg_context,
		tree.position.x - io.height * .075,
		tree.position.y - io.height * .075,
		io.height * .15,
		io.height * .15,
		io.height * .01,
	)
	nanovg.FillColor(nanovg_context, nanovg.RGB(135, 163, 46))
	nanovg.Fill(nanovg_context)

	colors := [Citrus_Type]nanovg.Color {
		.None   = nanovg.RGB(255, 255, 255),
		.Lemon  = nanovg.RGB(255, 255, 0),
		.Lime   = nanovg.RGB(0, 255, 0),
		.Orange = nanovg.RGB(255, 165, 0),
		.Grapes = nanovg.RGB(138, 43, 226),
	}

	for citrus in tree.citrus {
		nanovg.BeginPath(nanovg_context)
		nanovg.Circle(nanovg_context, citrus.position.x, citrus.position.y, io.height * .01)
		nanovg.FillColor(nanovg_context, nanovg.RGBA(0, 0, 0, 50))
		nanovg.Fill(nanovg_context)

		if citrus.state == .Grown {
			nanovg.BeginPath(nanovg_context)
			nanovg.Circle(nanovg_context, citrus.position.x, citrus.position.y, io.height * .01)
			nanovg.StrokeColor(nanovg_context, nanovg.RGBA(255, 255, 255, 50))
			nanovg.StrokeWidth(nanovg_context, io.height * .01)
			nanovg.Stroke(nanovg_context)
			nanovg.BeginPath(nanovg_context)
			nanovg.Circle(nanovg_context, citrus.position.x, citrus.position.y, io.height * .01)
			nanovg.FillColor(nanovg_context, colors[tree.citrus_type])
			nanovg.Fill(nanovg_context)
		}

		if citrus.state == .Growing {
			nanovg.BeginPath(nanovg_context)
			nanovg.Circle(
				nanovg_context,
				citrus.position.x,
				citrus.position.y,
				io.height * .01 * f32(tree.current_growth / tree.grow_time),
			)
			nanovg.FillColor(nanovg_context, colors[tree.citrus_type])
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

	io := input.poll(window)
	init(io)

	last_time := time.tick_now()
	for !glfw.WindowShouldClose(window) {
		glfw.PollEvents()

		now := time.tick_now()
		delta := time.duration_seconds(time.tick_diff(last_time, now))
		last_time = now

		io = input.poll(window)

		update(delta, io)

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
