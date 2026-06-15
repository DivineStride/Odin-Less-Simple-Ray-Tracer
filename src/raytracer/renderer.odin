package raytracer

import "core:fmt"
import "core:os"
import "core:time"

CORE_COUNT := 1

Render_Details :: struct {
	image_width, samples, depth: int,
}

set_processor_core_count :: proc(override: int = 0) {
	if override > 0 {
		CORE_COUNT = override
	} else {
		CORE_COUNT = os.get_processor_core_count()
	}
}

render_frame_raw :: proc(cam: ^Camera, world: []Hittable, out: []Color, frame_index: int) {
	camera_init(cam)

	build_render_threads(cam, world, out, false, frame_index)
}

render_to_buffer :: proc(cam: ^Camera, world: []Hittable, buf: []u32) {
	camera_init(cam)

	pixels := make([]Color, cam.image_height * cam.image_width)
	defer delete(pixels)

	build_render_threads(cam, world, pixels, false)

	for c, i in pixels {
		buf[i] = color_to_xrgb(c * cam.pixel_samples_scale, cam.ev_scale)
	}
}

render_to_ppm :: proc(cam: ^Camera, world: []Hittable) {
	camera_init(cam)

	// Start Render Time Tracker
	render_start := time.now()

	pixels := make([]Color, cam.image_height * cam.image_width)
	defer delete(pixels)

	build_render_threads(cam, world, pixels)


	// Build Image Output
	fmt.println("P3")
	fmt.printfln("%v %v", cam.image_width, cam.image_height)
	fmt.println("255")

	// Then we write to the PPM from the buffer
	for j := 0; j < cam.image_height; j += 1 {
		for i := 0; i < cam.image_width; i += 1 {
			write_color(pixels[j * cam.image_width + i] * cam.pixel_samples_scale, cam.ev_scale)
		}
	}

	// End Time Tracking
	render_end := time.now()
	duration := time.diff(render_start, render_end)

	minutes := time.duration_minutes(duration)
	seconds := time.duration_seconds(duration) - f64(int(minutes)) * 60

	console_stats(cam, duration)
	write_stats(cam, duration)
}
