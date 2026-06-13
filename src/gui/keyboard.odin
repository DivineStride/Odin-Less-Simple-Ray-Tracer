package gui

import rt "../raytracer/"
import "core:sync"
import sdl "vendor:sdl3"

Key_Pressed :: struct {
	key: string,
}

handle_keyboard_press :: proc(key_scancode: sdl.Scancode, ctx: ^rt.Render_Context) -> bool {
	#partial switch key_scancode {
	case .ESCAPE, .Q:
		return false
	case .W:
		if rt.render_get_state(ctx) == .Idle {
			sync.mutex_lock(&ctx.mutex)

			sync.mutex_unlock(&ctx.mutex)
			rt.render_set_state(ctx, .Requested)
		}
	}

	return true
}

set_key_pressed :: proc(key_logger: ^Key_Pressed, key: string) {
	key_logger.key = key
}
