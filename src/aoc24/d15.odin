package aoc24

import "../util"
import "core:fmt"
import "core:strings"

@(private = "file")
Point :: [2]int

@(private = "file")
Dir :: enum {
	N = '^',
	S = 'v',
	E = '>',
	W = '<',
}

@(private = "file")
Content :: enum {
	Wall     = '#',
	Space    = '.',
	Box      = 'O',
	Bot      = '@',
	BoxLeft  = '[',
	BoxRight = ']',
}

@(private = "file")
Grid :: [dynamic][dynamic]Content

@(private = "file")
Puz :: struct {
	maxx: int,
	maxy: int,
	grid: Grid,
	bot:  Point,
	dirs: [dynamic]Dir,
}

@(private = "file")
Command :: struct {
	loc:   Point,
	value: Content,
}

solve_d15 :: proc(part: util.Part, data: string) -> string {
	switch part {
	case .p1:
		return solve1(data)
	case .p2:
		return solve2(data)
	}
	return ""
}

// -----------------------------------------------------------------------------------------

@(private = "file")
solve1 :: proc(data: string) -> string {
	puz := parse(data)
	defer destroy_puz(puz)
	for dir in puz.dirs {
		new_bot, ok := move1(&puz, puz.bot, dir)
		if ok {
			puz.bot = new_bot
		}
	}

	score := 0
	for y in 0 ..< puz.maxy {
		for x in 0 ..< puz.maxx {
			content := get(puz, Point{x, y})
			if content == .Box {
				score += 100 * y + x
			}
		}
	}

	return util.to_str(score)
}

@(private = "file")
solve2 :: proc(data: string) -> string {
	puz := parse(data, .p2)
	commands := make_dynamic_array([dynamic]Command)
	defer {
		destroy_puz(puz)
		delete_dynamic_array(commands)
	}

	for dir in puz.dirs {
		if dir == .N || dir == .S {
			new_bot, ok := move2_NS(&puz, &commands, puz.bot, dir)
			if ok {
				// we have a series of commands to apply
				for cmd in commands {
					puz.grid[cmd.loc.y][cmd.loc.x] = cmd.value
				}
				puz.bot = new_bot
				fixup(&puz)
			}
			clear_dynamic_array(&commands)
		} else {
			new_bot, ok := move1(&puz, puz.bot, dir)
			if ok {
				puz.bot = new_bot
			}
		}
	}

	score := 0
	// score is from the closest edge of the map to the box
	for y in 0 ..< puz.maxy {
		for x_left in 0 ..< puz.maxx {
			content := get(puz, Point{x_left, y})
			if content == .BoxLeft {
				score += 100 * y + x_left
			}
		}
	}

	return util.to_str(score)
}

fixup :: proc(puz: ^Puz) {
	for y in 0 ..< puz.maxy {
		for x in 0 ..< puz.maxx {
			content := get(puz^, Point{x, y})
			other_dir: Dir
			other_half: Content
			if content == .BoxLeft {
				other_dir = .E
				other_half = .BoxRight
			} else if content == .BoxRight {
				other_dir = .W
				other_half = .BoxLeft
			} else {
				continue
			}
			loc := shift(Point{x, y}, other_dir)
			puz.grid[loc.y][loc.x] = other_half
		}
	}
}

@(private = "file")
move1 :: proc(puz: ^Puz, loc: Point, dir: Dir) -> (Point, bool) {
	// can I move?
	cur := get(puz^, loc)
	if cur == .Wall do return Point{}, false
	if cur == .Space do return Point{}, true

	// I can move. Can the content of my "to" location move?
	next_loc := shift(loc, dir)
	if !inbounds(puz^, next_loc) do return Point{}, false
	_, ok := move1(puz, next_loc, dir)
	if ok {
		// the next block can also move... so we're good to go
		// move me to the new location, and put a space in my
		// old location
		puz.grid[next_loc.y][next_loc.x] = cur
		puz.grid[loc.y][loc.x] = .Space
		return next_loc, true
	}
	return Point{}, false
}

@(private = "file")
move2_NS :: proc(
	puz: ^Puz,
	commands: ^[dynamic]Command,
	loc: Point,
	dir: Dir,
	sent_by_other_half: bool = false,
) -> (
	Point,
	bool,
) {

	// get the next location, what's in the next location, and what's in the current location
	next_loc := shift(loc, dir)
	next := get(puz^, next_loc)
	cur := get(puz^, loc)
	ok: bool

	if cur == .Wall || next == .Wall || !inbounds(puz^, next_loc) {
		// either current is a wall, the next thing is a wall, or the next thing is out of bounds.
		// in any case, current cant' move. Clear any accumulated commands and return false
		clear(commands)
		return next_loc, false
	}

	// current spot is a space, so it doesn't have to move
	if cur == .Space do return next_loc, true

	// I can move... is my next location clear? Am I a box with another half?

	#partial switch cur {
	case .Bot:
		// I'm a robot, I'm concerned only with what's in my way
		if next == .Space {
			// nothing in my way -> move to next spot by enqueing a command to move
			// the current content to the next spot
			append_elem(commands, Command{next_loc, .Bot})
			append_elem(commands, Command{loc, .Space})
			return next_loc, true
		}

		// whatever's in front of me needs to move. Capture if it worked, and the updated
		// list of commands
		_, ok = move2_NS(puz, commands, next_loc, dir)
		if ok {
			// something was there, but I could move it out of the way, so I can move
			append(commands, Command{next_loc, .Bot})
			append(commands, Command{loc, .Space})
			return next_loc, true
		} else {
			// something was in my way that can't move, so neither can I
			return next_loc, false
		}

	case .BoxLeft, .BoxRight:
		// I'm half a box, so I migh need to check both current and the other half
		other_half_loc: Point
		other_half_ok: bool

		append(commands, Command{loc, .Space})

		if cur == .BoxLeft {
			other_half_loc = shift(loc, .E)
		} else {
			other_half_loc = shift(loc, .W)
		}

		// I'm one side of a box. If the other half told me to move, then I just need to
		// move myself. Otherwise, I need to tell my other half to move
		if !sent_by_other_half {
			_, other_half_ok = move2_NS(
				puz,
				commands,
				other_half_loc,
				dir,
				sent_by_other_half = true,
			)
		}

		if sent_by_other_half || other_half_ok {
			// either I've been told to move by my other half, or I told my other half to 
			// move and it was ok, either way I now can move
			if next == .Space {
				// I've got a space above, I can move
				append(commands, Command{next_loc, cur})
				return next_loc, true
			}
			// what's in front of me isn't a space... see if it can move
			_, ok = move2_NS(puz, commands, next_loc, dir)
			if ok {
				// the thing in front of me can move, so can I
				append(commands, Command{next_loc, cur})
				behind_loc := shift(loc, dir == .N ? .S : .N)
				behind := get(puz^, behind_loc)
				if behind == .Space {
					append(commands, Command{loc, .Space})
				}
				return next_loc, true
			}
		}
		// I can't move, didn't check the other side because it doesn't matter
		return Point{}, false

	case:
		panic("Unexpected case in move2_NS")
	}

	// we never get to this point
	panic("Unexpected reached end of move2_NS")
}

// -----------------------------------------------------------------------------------------

@(private = "file")
parse :: proc(data: string, part: util.Part = .p1) -> Puz {

	parts := strings.split(data, "\n\n", allocator = context.temp_allocator)
	grid, bot := parse_grid(parts[0], part)
	directions := make_dynamic_array([dynamic]Dir)
	for dir in parts[1] {
		if dir == '\n' do continue
		append(&directions, Dir(dir))
	}
	puz := Puz {
		maxx = len(grid[0]) - 1,
		maxy = len(grid) - 1,
		dirs = directions,
		bot  = bot,
		grid = grid,
	}
	return puz
}

@(private = "file")
destroy_puz :: proc(puz: Puz) {
	delete_dynamic_array(puz.dirs)
	for line in puz.grid {
		delete_dynamic_array(line)
	}
	delete_dynamic_array(puz.grid)
}

@(private = "file")
parse_grid :: proc(raw_grid: string, part: util.Part = .p1) -> (Grid, Point) {
	raw_lines := strings.split_lines(raw_grid, allocator = context.temp_allocator)
	grid := make_dynamic_array([dynamic]([dynamic]Content))
	bot: Point
	for raw_line, y in raw_lines {
		line := make_dynamic_array([dynamic]Content)
		for x := 0; x < (len(raw_line) * 2); x += 2 {
			raw_char := raw_line[x / 2]
			// for raw_char, x in raw_line {
			content := Content(raw_char)
			if part == .p1 {
				append_elem(&line, content)
				if content == .Bot {
					bot = {x / 2, y}
				}
			} else {
				#partial switch content {
				case .Space:
					append_elems(&line, content, content)
				case .Box:
					append_elems(&line, Content.BoxLeft, Content.BoxRight)
				case .Wall:
					append_elems(&line, Content.Wall, Content.Wall)
				case .Bot:
					append_elems(&line, content, Content.Space)
					bot = {x, y}
				case:
				}
			}
		}
		append(&grid, line)
	}
	return grid, bot
}

// -----------------------------------------------------------------------------------------

@(private = "file")
ppuz :: proc(puz: Puz, cmd: rune = ' ', pdirs: bool = false) {
	fmt.printfln("command: %v", cmd)
	for line in puz.grid {
		for cell in line {
			fmt.print(rune(cell))
		}
		fmt.println()
	}
	if pdirs {
		for dir, i in puz.dirs {
			if i > 0 && i % 140 == 0 do fmt.println()
			fmt.print(rune(dir))
		}
		fmt.println()
	}
	fmt.printfln("BOT: %v\n", puz.bot)
}

@(private = "file")
inbounds :: #force_inline proc(puz: Puz, loc: Point) -> bool {
	return !(loc.x < 0 || loc.x > puz.maxx || loc.y < 0 || loc.y > puz.maxy)
}

@(private = "file")
get :: #force_inline proc(puz: Puz, loc: Point) -> Content {
	if !inbounds(puz, loc) do return nil
	return puz.grid[loc.y][loc.x]
}

@(private = "file")
shift :: #force_inline proc(loc: Point, dir: Dir) -> Point {
	new_loc: Point
	switch dir {
	case .N:
		new_loc = loc + {0, -1}
	case .S:
		new_loc = loc + {0, 1}
	case .E:
		new_loc = loc + {1, 0}
	case .W:
		new_loc = loc + {-1, 0}
	}
	return new_loc
}
