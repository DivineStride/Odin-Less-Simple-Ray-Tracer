package gui

import rt "../raytracer/"
import "core:fmt"
import "core:os"
import sdl "vendor:sdl3"

WINDOW_TITLE :: "Raytracer Viewer"
WINDOW_WIDTH :: 800
WINDOW_HEIGHT :: 450

main :: proc() {
	if !sdl.Init(sdl.INIT_VIDEO) {
		fmt.eprintln("SDL_Init failed:", sdl.GetError())
		os.exit(1)
	}
	defer sdl.Quit()

	window := sdl.CreateWindow(WINDOW_TITLE, WINDOW_WIDTH, WINDOW_HEIGHT, sdl.WINDOW_RESIZABLE)
	if window == nil {
		fmt.eprintln("SDL_CreateWindow failed:", sdl.GetError())
		os.exit(1)
	}
	defer sdl.DestroyWindow(window)

	renderer := sdl.CreateRenderer(window, nil)
	if renderer == nil {
		fmt.eprintln("SDL_CreateRenderer failed:", sdl.GetError())
		os.exit(1)
	}
	defer sdl.DestroyRenderer(renderer)

	texture := sdl.CreateTexture(
		renderer,
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

	pixel_buf := make([]u32, WINDOW_WIDTH * WINDOW_HEIGHT)
	needs_rerender := false

	event: sdl.Event
	running := true

	for running {
		for sdl.PollEvent(&event) {
			#partial switch event.type {

			case .QUIT:
				running = false
			case .KEY_DOWN:
				#partial switch event.key.scancode {
				case .ESCAPE, .Q:
					running = false
				case .W:
					needs_rerender = true
				}
			}
		}

		if needs_rerender {
			fill_test_gradient(pixel_buf, WINDOW_WIDTH, WINDOW_HEIGHT)
			needs_rerender = false
		}

		pitch := i32(WINDOW_WIDTH * size_of(u32))
		sdl.UpdateTexture(texture, nil, raw_data(pixel_buf), pitch)

		sdl.RenderClear(renderer)
		sdl.RenderTexture(renderer, texture, nil, nil)
		sdl.RenderPresent(renderer)
	}
}

fill_test_gradient :: proc(buf: []u32, width, height: int) {
	for y in 0 ..< height {
		for x in 0 ..< width {
			t := f32(y) / f32(height)
			v := f32(x) / f32(width)
			r := u32(lerp(0, 255, v))
			g := u32(lerp(0, 255, t))
			b := u32(0)

			buf[y * width + x] = (r << 16) | (g << 8) | b
		}
	}
}

lerp :: proc(a, b: f32, t: f32) -> f32 {
	return a + (b - a) * t
}
