package aoc24

import "../util"
import "core:fmt"
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
	distinct_only := part == .p2
	puz := parse(data)
	count := 0
	for th in puz.trailheads {
		ends := make_map(map[int]bool, allocator = context.temp_allocator)
		sub_count := trails_from_head(&puz, th, distinct_only, &ends)
		count += sub_count
	}
	return util.to_str(count)
}

@(private = "file")
trails_from_head :: proc(puz: ^Puz, head: Point, distinct_only: bool, ends: ^map[int]bool) -> int {
	altitude := get(puz^, head)
	count := 0
	for dir in Direction {
		neighbor := move(puz^, head, dir) or_continue
		neighbor_altitude := get(puz^, neighbor)
		key := hash(neighbor)
		if altitude == '8' && neighbor_altitude == '9' && !(key in ends) {
			if !distinct_only do ends[key] = true
			count += 1
		} else {
			if neighbor_altitude == altitude + 1 {
				neighbor, _ = move(puz^, head, dir)
				count += trails_from_head(puz, neighbor, distinct_only, ends)
			}
		}
	}
	return count
}

@(private = "file")
parse :: proc(data: string) -> Puz {
	span := strings.index(data, "\n")
	puz := Puz {
		data       = transmute([]u8)(data),
		maxx       = span,
		maxy       = (len(data) / span),
		trailheads = make_dynamic_array([dynamic]Point, allocator = context.temp_allocator),
	}
	value_fn :: proc(puz: ^Puz, p: Point, v: u8) {
		if v == '0' {
			append_elem(&puz.trailheads, p)
		}
	}
	iterate_puz(&puz, value_fn)
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
hash :: proc(p: Point) -> int {
	return 1000 * p.y + p.x
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
	fmt.println()
}
