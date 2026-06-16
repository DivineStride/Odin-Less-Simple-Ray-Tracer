package raytracer

import "core:mem"

Scene :: struct {
	arena:     mem.Arena,
	world:     [dynamic]Hittable,
	materials: [dynamic]^Material,
	hittables: [dynamic]^Hittable,
	images:    [dynamic]^Image,
	bvh:       Hittable,
	bvh_world: [1]Hittable,
}

scene_init :: proc(s: ^Scene, arena_size: int = 32 * mem.Megabyte) {
	backing := make([]byte, arena_size)
	mem.arena_init(&s.arena, backing)

	arena_alloc := mem.arena_allocator(&s.arena)
	s.world = make([dynamic]Hittable, arena_alloc)
	s.materials = make([dynamic]^Material, arena_alloc)
	s.hittables = make([dynamic]^Hittable, arena_alloc)
	s.images = make([dynamic]^Image, arena_alloc)
}

scene_destroy :: proc(s: ^Scene) {
	for m in s.materials do free(m)
	for h in s.hittables do free(h)
	for i in s.images do destroy_image(i)

	delete(s.materials)
	delete(s.hittables)
	delete(s.world)
	delete(s.images)

	backing := s.arena.data
	mem.arena_free_all(&s.arena)
	delete(backing)
}
