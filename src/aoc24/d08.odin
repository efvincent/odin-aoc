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

Ant :: struct {
	id:   int,
	freq: rune,
	loc:  Point,
}

Puz :: struct {
	ants:      map[int]Ant,
	antinodes: map[int]bool,
	maxx:      int,
	maxy:      int,
}

solve_d08 :: proc(part: util.Part, data: string) -> string {
	puz := parse(data)
	print_puz(puz)
	for _, ant in puz.ants {
		scan_ant(&puz, ant, part)
	}
	print_puz(puz)
	return util.to_str(len(puz.antinodes))
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
	puz := Puz {
		ants      = make(map[int]Ant),
		antinodes = make(map[int]bool),
	}
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
	fmt.printfln("(%v,%v) - %v", p.x, p.y, ok)
	if part == .p2 && ok {
		antinode_of(puz, p1, p, part)
		antinode_of(puz, p, p1, part)
	}
}

@(private = "file")
print_puz :: proc(puz: Puz) {
	for y in 0 ..= puz.maxy {
		for x in 0 ..= puz.maxx {
			p := Point{x, y}
			id := hash(p)
			_, found := puz.antinodes[id]
			if found {
				fmt.print("#")
			} else {
				ant, found_ant := puz.ants[id]
				if found_ant {
					fmt.print(ant.freq)
				} else {
					fmt.print(".")
				}
			}
		}
		fmt.println()
	}
	fmt.println("\n")
}
