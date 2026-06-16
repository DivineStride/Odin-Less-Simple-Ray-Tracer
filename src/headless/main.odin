package headless

import rt "../raytracer/"
import "core:flags"
import "core:fmt"
import "core:log"
import "core:os"

Headless_Flags :: struct {
	world:   int `usage:"Scene to render (1-11)"`,
	width:   int `usage:"Image width in pixels"`,
	samples: int `usage:"Samples per pixel"`,
	depth:   int `usage:"Maximum ray bounce depth"`,
	threads: int `usage:"Thread count override (0 = use all cores)"`,
}

main :: proc() {
	logger := log.create_console_logger()
	context.logger = logger

	opts := Headless_Flags {
		world   = 11,
		width   = 600,
		samples = 125,
		depth   = 50,
		threads = 0,
	}
	flags.parse_or_exit(&opts, os.args, .Unix)

	rt.set_processor_core_count(opts.threads)

	render_details := rt.Render_Details {
		image_width = opts.width,
		samples     = opts.samples,
		depth       = opts.depth,
	}

	rt.render_world(opts.world, render_details)
}
