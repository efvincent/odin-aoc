package aoc24

import "../util"
import "core:fmt"
import "core:slice"
import conv "core:strconv"
import "core:strings"

@(private = "file")
Puz :: struct {
	data:       []u8,
	maxx:       int,
	maxy:       int,
	trailheads: [dynamic]Point,
}

@(private = "file")
Point :: [2]int
@(private = "file")
Direction :: enum (u8) {
	N,
	E,
	S,
	W,
}

solve_d10 :: proc(part: util.Part, data: string) -> string {
	switch part {
	case .p1:
		return solve1(data)
	case .p2:
		return solve2(data)
	}
	return ""
}

@(private = "file")
solve2 :: proc(data: string) -> string {
	return ""
}

@(private = "file")
solve1 :: proc(data: string) -> string {
	puz := parse(data)
	for th in puz.trailheads {

	}
	return ""
}

@(private = "file")
parse :: proc(data: string) -> Puz {
	// NOTE: to wrap enum -> d2 := Direction((u8(Direction.E) + 7) % 4)
	span := strings.index(data, "\n")
	puz := Puz {
		data = transmute([]u8)(data),
		maxx = span,
		maxy = (len(data) / span),
	}
	puz.trailheads = make_dynamic_array([dynamic]Point, allocator = context.temp_allocator)
	context.user_ptr = &puz.trailheads
	defer context.user_ptr = nil

	value_fn :: proc(puz: ^Puz, p: Point, v: u8) {
		if v == '0' {
			append_elem(&puz.trailheads, p)
		}
	}

	iterate_puz(&puz, value_fn)

	ppuz(&puz)
	return puz
}

@(private = "file")
peek :: proc(puz: Puz, from: Point, dir: Direction) -> (value: u8, ok: bool) {
	p := move(puz, from, dir) or_return
	return get(puz, p), true
}

@(private = "file")
move :: proc(puz: Puz, from: Point, dir: Direction) -> (to: Point, ok: bool) {
	switch dir {
	case .N:
		to = from + Point{0, -1}
	case .S:
		to = from + Point{0, 1}
	case .E:
		to = from + Point{1, 0}
	case .W:
		to = from + Point{-1, 0}
	}
	if to.x > puz.maxx || to.y > puz.maxy || to.x < 0 || to.y < 0 {
		ok = false
	} else {
		ok = true
	}
	return to, ok
}

@(private = "file")
get :: proc(puz: Puz, p: Point) -> u8 {
	if p.x < 0 || p.x >= puz.maxx do return 0
	if p.y < 0 || p.y >= puz.maxx do return 0
	return puz.data[p.x + p.y * puz.maxx + p.y]
}

@(private = "file")
iterate_puz :: proc(
	puz: ^Puz,
	value_fn: proc(puz: ^Puz, point: Point, value: u8),
	row_fn: proc() = proc() {},
) {
	for y in 0 ..< puz.maxy {
		for x in 0 ..< puz.maxx {
			p := Point{x, y}
			value_fn(puz, p, get(puz^, p))
		}
		row_fn()
	}
}

@(private = "file")
ppuz :: proc(puz: ^Puz) {
	value_fn :: proc(_: ^Puz, p: Point, v: u8) {fmt.print(rune(v))}
	row_fn :: proc() {fmt.println()}
	iterate_puz(puz, value_fn, row_fn)
	for th in puz.trailheads {
		fmt.printfln("trailhead: %v", th)
	}
	fmt.println()
}
