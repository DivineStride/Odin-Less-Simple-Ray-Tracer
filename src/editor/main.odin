package editor

import rt "../raytracer/"
import "core:fmt"
import "core:os"
import "core:thread"
import sdl "vendor:sdl3"

WINDOW_TITLE :: "Raytracer Viewer"
WINDOW_WIDTH :: 800
WINDOW_HEIGHT :: 450
MAX_SAMPLES :: 512

main :: proc() {
	app := app_init()
	defer close_app(app)

	texture := sdl.CreateTexture(
		app.renderer,
		sdl.PixelFormat.XRGB8888,
		sdl.TextureAccess.STREAMING,
		WINDOW_WIDTH,
		WINDOW_HEIGHT,
	)
	if texture == nil {
		fmt.eprintln("SDL_CreateTexture failed:", sdl.GetError())
		os.exit(1)
	}
	defer sdl.DestroyTexture(texture)

	ctx: rt.Render_Context
	rt.render_set_state(&ctx, .Idle)
	ctx.pixel_buf = make([]u32, WINDOW_WIDTH * WINDOW_HEIGHT)
	ctx.accum = make([]rt.Color, WINDOW_WIDTH * WINDOW_HEIGHT)
	ctx.scratch = make([]rt.Color, WINDOW_WIDTH * WINDOW_HEIGHT)
	defer delete(ctx.pixel_buf)
	defer delete(ctx.accum)
	defer delete(ctx.scratch)


	// We're only gettin this once, so if we want to update anything it will have to be moved
	// If we want to adjust image width, we'll need to have this updated within the loop
	// If want to move the camera, we will need to record the change in the loop
	ctx.scene, ctx.cam = rt.world_cornell_box()

	rt.camera_init(&ctx.cam)

	ctx.cam.image_width = WINDOW_WIDTH
	ctx.cam.aspect_ratio = f64(WINDOW_WIDTH) / f64(WINDOW_HEIGHT)
	ctx.cam.samples_per_pixel = 10
	ctx.cam.max_depth = 20

	rt.render_set_state(&ctx, .Requested)


	render_thread: ^thread.Thread = nil

	defer rt.scene_destroy(&ctx.scene)

	event: sdl.Event
	main_loop: for {

		for sdl.PollEvent(&event) {
			#partial switch event.type {
			case .QUIT:
				break main_loop
			case .KEY_DOWN:
				if ok := handle_keyboard_press(event.key.scancode, &ctx); !ok {
					break main_loop
				}
			}
		}

		if rt.render_get_state(&ctx) == .Requested {
			if render_thread != nil {
				thread.join(render_thread)
				thread.destroy(render_thread)
			}

			sdl.SetWindowTitle(app.window, "Raytracer - rendering...")

			render_thread = thread.create(rt.render_worker)
			render_thread.data = &ctx
			thread.start(render_thread)
		}

		if rt.render_get_state(&ctx) == .Done {
			rt.accumulate_and_display(&ctx)
			if ctx.sample_count < MAX_SAMPLES {
				rt.render_set_state(&ctx, .Requested)
			} else {
				rt.render_set_state(&ctx, .Idle)
			}
			sdl.SetWindowTitle(app.window, "Raytracer")
		}

		// We're going to need a way to accumulate samples for this texture as well
		pitch := i32(WINDOW_WIDTH * size_of(u32))
		sdl.UpdateTexture(texture, nil, raw_data(ctx.pixel_buf), pitch)

		sdl.RenderClear(app.renderer)
		sdl.RenderTexture(app.renderer, texture, nil, nil)
		sdl.RenderPresent(app.renderer)
	}

	if render_thread != nil {
		thread.join(render_thread)
		thread.destroy(render_thread)
	}
}
