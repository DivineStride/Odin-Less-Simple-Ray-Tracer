package gui

import rt "../raytracer/"
import "core:fmt"
import "core:os"
import sdl "vendor:sdl3"

App :: struct {
	window:   ^sdl.Window,
	renderer: ^sdl.Renderer,
}

app_init :: proc() -> App {
	if !sdl.Init(sdl.INIT_VIDEO) {
		fmt.eprintln("SDL_Init failed:", sdl.GetError())
		os.exit(1)
	}

	rt.render_set_processor_core_count()

	window := sdl.CreateWindow(WINDOW_TITLE, WINDOW_WIDTH, WINDOW_HEIGHT, sdl.WINDOW_RESIZABLE)
	if window == nil {
		fmt.eprintln("SDL_CreateWindow failed:", sdl.GetError())
		os.exit(1)
	}

	renderer := sdl.CreateRenderer(window, nil)
	if renderer == nil {
		fmt.eprintln("SDL_CreateRenderer failed:", sdl.GetError())
		os.exit(1)
	}


	return {window, renderer}
}

close_app :: proc(app: App) {
	sdl.Quit()
	sdl.DestroyWindow(app.window)
	sdl.DestroyRenderer(app.renderer)
}
