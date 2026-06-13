package headless

import rt "../raytracer/"
import "core:log"

main :: proc() {
	logger := log.create_console_logger()
	context.logger = logger

	render_details := rt.Render_Details {
		image_width = 600,
		samples     = 125,
		depth       = 20,
	}

	rt.render_world(4, render_details)
}
