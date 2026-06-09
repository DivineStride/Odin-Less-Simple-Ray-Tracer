package headless

import rt "../raytracer/"

main :: proc() {
	render_details := rt.Render_Details {
		image_width = 600,
		samples     = 125,
		depth       = 20,
	}

	rt.render_world(1, render_details)
}
