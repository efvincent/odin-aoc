package aoc24

import "../util"
import "core:fmt"
import "core:log"
import "core:math"
import "core:slice"
import conv "core:strconv"
import "core:strings"
import "core:testing"

@(private = "file")
Point :: struct {
	x: int,
	y: int,
}

@(private = "file")
Ant :: struct {
	id:   int,
	freq: rune,
	loc:  Point,
}

@(private = "file")
Puz :: struct {
	ants:      map[int]Ant,
	antinodes: map[int]bool,
	maxx:      int,
	maxy:      int,
}

@(private = "file")
init_puz :: proc() -> Puz {
	return Puz {
		ants = make_map(map[int]Ant, allocator = context.temp_allocator),
		antinodes = make_map(map[int]bool, allocator = context.temp_allocator),
	}
}

solve_d08 :: proc(part: util.Part, data: string) -> string {
	puz := parse(data)
	for _, ant in puz.ants {
		scan_ant(&puz, ant, part)
	}
	if part == .p1 {
		return util.to_str(len(puz.antinodes))
	} else {
		count := 0
		for _, ant in puz.ants {
			if !(hash(ant.loc) in puz.antinodes) {
				count += 1
			}
		}
		return util.to_str(count + len(puz.antinodes))
	}
}

@(private = "file")
put :: proc(puz: ^Puz, p: Point) -> bool {
	if p.x < 0 || p.x > puz.maxx do return false
	if p.y < 0 || p.y > puz.maxy do return false
	id := hash(p)
	if !(id in puz.antinodes) {
		puz.antinodes[id] = true
	}
	return true
}

@(private = "file")
hash :: proc(p: Point) -> int {
	return p.y * 1000 + p.x
}

@(private = "file")
parse :: proc(data: string) -> Puz {

	raw_lines := strings.split_lines(data, context.temp_allocator)
	puz := init_puz()
	for raw_line, y_idx in raw_lines {
		for char, x_idx in raw_line {
			switch char {
			case '.': // space
			case:
				p := Point{x_idx, y_idx}
				ant := Ant {
					id   = hash(p),
					loc  = p,
					freq = char,
				}
				puz.ants[hash(p)] = ant
			}
			puz.maxx = x_idx
		}
		puz.maxy = y_idx
	}
	return puz
}

@(private = "file")
scan_ant :: proc(puz: ^Puz, ant: Ant, part: util.Part = .p1) {
	for _, cur_ant in puz.ants {
		if cur_ant == ant || cur_ant.freq != ant.freq do continue
		antinode_of(puz, cur_ant.loc, ant.loc, part)
	}
}

@(private = "file")
antinode_of :: proc(puz: ^Puz, p1: Point, p2: Point, part: util.Part = .p1) {
	x := math.abs(p1.x - p2.x)
	y := math.abs(p1.y - p2.y)
	dx, dy: int
	if p1.x > p2.x {
		dx = x
	} else {
		dx = -1 * x
	}
	if p1.y > p2.y {
		dy = y
	} else {
		dy = -1 * y
	}

	p := Point{p1.x + dx, p1.y + dy}
	ok := put(puz, p)

	for part == .p2 && ok {
		p.x += dx
		p.y += dy
		ok = put(puz, p)
	}
}
