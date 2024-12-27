package aoc24

import "../util"
import pq "core:container/priority_queue"
import "core:fmt"
import "core:math"
import "core:slice"
import "core:strings"

@(private = "file")
Point :: [2]int

@(private = "file")
Dir :: enum {
	N = 0,
	E = 1,
	S = 2,
	W = 3,
}

@(private = "file")
Content :: enum {
	Wall  = '█',
	Space = ' ',
	Start = 'S',
	End   = 'E',
}

@(private = "file")
CostNode :: struct {
	pos:  Point,
	dir:  Dir,
	cost: int,
}

@(private = "file")
PathNode :: struct {
	pos: Point,
	dir: Dir,
}

@(private = "file")
Grid :: []Content

@(private = "file")
Puz :: struct {
	maxx:  int,
	grid:  []Content,
	maxy:  int,
	start: Point,
	end:   Point,
}

solve_d16 :: proc(part: util.Part, data: string) -> string {
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
	puz := parse(data)
	defer delete(puz.grid)
	a, b := find_all_best_paths(&puz)
	fmt.printfln("a:%v\nb:%v", a, b)
	return ""
}

@(private = "file")
solve1 :: proc(data: string) -> string {
	puz := parse(data)
	defer delete(puz.grid)
	c := find_smallest_cost(&puz)
	return util.to_str(c)
}

@(private = "file")
find_smallest_cost :: proc(puz: ^Puz) -> int {
	smallest_cost := max(int)
	visited := make(map[int]struct {})
	distance := make(map[int]int)
	queue: pq.Priority_Queue(CostNode)

	defer {
		delete(visited)
		delete(distance)
		pq.destroy(&queue)
	}

	// initialize the queue with the starting position
	pq.init(&queue, node_less_cost, node_swap)
	pq.push(&queue, CostNode{puz.start, .E, 0})

	// iterate through all the nodes in the priority queue
	for pq.len(queue) > 0 {

		// pop a node off the queue, calc it's hash ID
		cur_node := pq.pop(&queue)
		cur_node_id := hash(cur_node.pos, cur_node.dir)

		// record the fact this node was visited
		visited[cur_node_id] = {}

		// Check to see if this is the end of the path we're searching for
		if cur_node.pos == puz.end {
			// if so, update the smallest cost to the cost at the current (End) node if
			// it's smaller than the current smallest cost
			smallest_cost = min(smallest_cost, cur_node.cost)
			// pop the next node off the queue
			continue
		}

		// If we've gotten this far, we haven't yet reached the end.
		// Loop through all the directions
		for n in 0 ..< 4 {
			// check each direction from the current pos
			next_pos: Point
			ok: bool
			dir := Dir(n)

			// if the move in the current dir is not allowed, continue to next dir
			if next_pos, ok = can_move(puz^, nil, cur_node.pos, dir, false); !ok {
				continue
			}

			// if we've visited this node from this direction, continue to next dir
			next_node_id := hash(next_pos, dir)
			if next_node_id in visited {
				// the next node has been visited from direction `dir`, check the next direction
				continue
			}

			// determine the cost of moving to this next node from the `dir` direction
			next_cost := cur_node.cost + 1 + cost_change(cur_node.dir, dir)
			prev_cost: int

			// have we visited this node at a cheaper cost?
			if prev_cost, ok = distance[next_node_id]; ok && prev_cost < next_cost {
				// we've seen this node from a cheaper path, check the next direction
				continue
			}

			// if the cost to the next node from this direction is more than the 
			// smallest cost yet found, check the next direction
			if next_cost >= smallest_cost {
				continue
			}

			// record that we've visited the `next_node` from the `dir` direction
			distance[next_node_id] = next_cost

			// push the `next_node` onto the queue at `next_cost` cost
			pq.push(&queue, CostNode{next_pos, dir, next_cost})
		}
	}
	return smallest_cost
}

ppreds :: proc(preds: map[PathNode][dynamic]PathNode, indent: int = 0) {
	for k, v in preds {
		for i in 0 ..< indent {
			fmt.print(" ")
		}
		fmt.printf("preds of (%v,%v) : ", k.pos[0], k.pos[1])
		for pred in v {
			fmt.printf("%v(%v, %v) ", pred.dir, pred.pos[0], pred.pos[1])
		}
		fmt.println()
	}
}

find_all_best_paths :: proc(puz: ^Puz) -> (int, [dynamic][]PathNode) {
	smallest_cost := max(int)
	distances_from_start := make(map[PathNode]int) // maps (loc, dir) to a distance from the start
	predecessors := make(map[PathNode][dynamic]PathNode)
	queue: pq.Priority_Queue(CostNode)
	defer {
		delete(distances_from_start)
		delete(predecessors)
		pq.destroy(&queue)
	}

	// no visited set, we use distance to track where we have been
	pq.init(&queue, node_less_cost, node_swap)
	pq.push(&queue, CostNode{puz.start, .E, 0})

	// intialize start distance
	start_node := PathNode {
		pos = puz.start,
		dir = .E,
	}
	distances_from_start[start_node] = 0

	// process items in the priority queue
	for pq.len(queue) > 0 {
		fmt.printfln("priority queue now: %v", queue.queue)
		cur_cost_node := pq.pop(&queue)
		cur_path_node := PathNode {
			pos = cur_cost_node.pos,
			dir = cur_cost_node.dir,
		}
		fmt.printfln(
			"  - popped cost node: %v\n    made cur_path_node: %v",
			cur_cost_node,
			cur_path_node,
		)

		// skip if the cost of this node is bigger than we have found previously
		if cost, ok := distances_from_start[cur_path_node]; ok {
			fmt.printfln(
				"  - found a previous distance from start at cur_path_node, cost = %v",
				cost,
			)
			if cur_cost_node.cost > cost {
				fmt.printfln("  - cur cost > stored distance from start, continuing")
				continue
			} else {
				fmt.printfln("  - cur cost <= stored distance from start")
			}
		} else {
			fmt.printfln("  - did not find previous distance from start at cur_path_node")
		}

		if cur_cost_node.pos == puz.end {
			smallest_cost = min(smallest_cost, cur_cost_node.cost)
			// don't continue, we need to explore all paths to the end
			fmt.printfln("  - cur_cost_node.pos == puz.end, smallest cost now %v", smallest_cost)
		} else {
			fmt.printfln("  - cur_cost_node.pos != puz.end, smallest cost unchanged")
		}

		// loop through all directions
		for test_dir_idx in 0 ..< 4 {
			fmt.printfln("      - priority queue now: %v", queue.queue)
			test_dir := Dir(test_dir_idx)

			fmt.printfln(
				"      - testing going %v from %v to %v",
				test_dir,
				cur_cost_node.pos,
				shift(cur_cost_node.pos, test_dir),
			)

			test_next_node := PathNode {
				pos = shift(cur_cost_node.pos, test_dir),
				dir = test_dir,
			}

			// if the move in the current dir from the current node is not allowed, check next dir
			if _, ok := can_move(puz^, nil, cur_cost_node.pos, test_dir, false); !ok {
				fmt.printfln("        - can't move")
				continue
			} else {
				fmt.printfln("        - can move!")
			}

			// get the next node from `cur_node` in direction `dir`
			test_next_cost := cur_cost_node.cost + 1 + cost_change(cur_cost_node.dir, test_dir)
			fmt.printfln("        - cost of moving %v", test_next_cost)

			// ignore paths with cost too big
			if test_next_cost > smallest_cost && cur_cost_node.pos != puz.end {
				fmt.printfln(
					"        - cost > smallest cost (%v) and not at puz end - ignoring path",
					smallest_cost,
				)
				continue
			} else {
				fmt.printfln(
					"        - either next cost %v < current smallest %v, or we're at the end",
					test_next_cost,
					smallest_cost,
				)
			}

			// is the path we're exploring better than the one we already have here?
			// existing_cost_id := hash(test_next_node.pos, test_dir)
			existing_cost, existing_cost_found := distances_from_start[test_next_node]
			fmt.printfln(
				"        - exising cost found: %v - %v",
				existing_cost_found,
				existing_cost_found ? util.to_str(existing_cost) : "N/A",
			)

			if !existing_cost_found || (existing_cost_found && test_next_cost < existing_cost) {
				fmt.printfln(
					"        - existing cost not found or found and next cost %v < existing cost %v\n          save in distances_from_start",
					test_next_cost,
					existing_cost,
				)
				// better path
				distances_from_start[test_next_node] = test_next_cost
				if test_next_node in predecessors {
					append(&predecessors[test_next_node], cur_path_node)
					fmt.printf("        - added new predecessors map for %v: ", test_next_node)
				} else {
					pred_list := make_dynamic_array([dynamic]PathNode)
					append(&pred_list, cur_path_node)
					predecessors[test_next_node] = pred_list
					fmt.printf(
						"        - added to existing predecessors map for %v: ",
						test_next_node,
					)
				}
				ppreds(predecessors, 8)
			} else if test_next_cost > existing_cost {
				continue
			} else {
				// same path, just update predecessors
				if pred_list, pred_list_found := predecessors[test_next_node]; pred_list_found {
					if !slice.contains(pred_list[:], cur_path_node) {
						append(&pred_list, cur_path_node)
					}
				}
			}

			pq.push(&queue, CostNode{test_next_node.pos, cur_path_node.dir, test_next_cost})

		}
	}

	// clean up the predecessors at the end
	defer {
		for _, p in predecessors {
			delete_dynamic_array(p)
		}
	}

	ppreds(predecessors)

	// now that we have explored the whole pam, create the paths
	all_shortest_paths := make([dynamic]([]PathNode))
	defer delete_dynamic_array(all_shortest_paths)

	// a stack to keep all the in-progress paths we're building
	// it's a queue of a tuple of ([]PathNode, T) where T is a tuple of (Point, Dir) 
	// let mut stack: VecDeque<(Vec<PathNode>, (usize, Direction))> = VecDeque::new();
	StackNode :: struct {
		path: [dynamic]PathNode,
		node: PathNode,
	}
	stack := make_dynamic_array([dynamic]StackNode)

	for n in 0 ..< 4 {
		// loop through all directions
		dir := Dir(n)
		end_node := PathNode {
			pos = puz.end,
			dir = dir,
		}
		end_node_id := hash(end_node.pos, end_node.dir)
		// find all different distances from the end node to the start
		if end_node_cost, ok := distances_from_start[end_node]; ok {
			fmt.printfln(
				"end node from dir %v has distance/cost of %v",
				end_node.dir,
				end_node_cost,
			)
			stackNode := StackNode {
				path = make_dynamic_array([dynamic]PathNode),
				node = end_node,
			}
			append(&stackNode.path, end_node)
			append(&stack, stackNode)
		}
	}

	for len(stack) > 0 {
		fmt.printfln("stack has %v StackNodes", len(stack))
		cur_stack_node := pop(&stack)
		cur_path_node := PathNode {
			pos = cur_stack_node.node.pos,
			dir = cur_stack_node.node.dir,
		}
		fmt.printfln("cur_stack_node: %v", cur_stack_node)

		if cur_stack_node.node == (PathNode{pos = puz.start, dir = .E}) {
			// found a complete path, add it to the list of complete paths
			complete_path := new_clone(cur_stack_node.path, allocator = context.temp_allocator)
			slice.reverse(complete_path[:])
			append_elem(&all_shortest_paths, complete_path[:])
		} else if prev_nodes, ok := predecessors[cur_path_node]; ok {
			// we got all the predecessors of the current node
			fmt.printfln(" -> prev nodes: %v", prev_nodes)
			for prev_node in prev_nodes {
				// for each predecessor, create a new path and add it to the stack to be checked
				new_path := new_clone(cur_stack_node.path, allocator = context.temp_allocator)
				added, err := append_elem(
					new_path,
					PathNode{pos = prev_node.pos, dir = prev_node.dir},
				)
				if err != nil {
					fmt.printfln(" -> error on append to new_path: %v", err)
				}

				added, err = append_elem(&stack, StackNode{path = new_path^, node = prev_node})
				if err != nil {
					fmt.printfln(" -> error on append to stack: %v", err)
				}
			}
		}
	}

	return smallest_cost, all_shortest_paths
}

// compute the change in cost incurred by turning from direction `a` to direction `b`
@(private = "file")
cost_change :: proc(a: Dir, b: Dir) -> int {
	d1 := int(a)
	d2 := int(b)
	if d1 == d2 do return 0
	diff := int(math.abs(d1 - d2))
	dist := math.min(diff, 4 - diff)
	if dist == 1 do return 1000
	return 2000
}

// -------------------------------------------------------------------------

@(private = "file")
parse :: proc(data: string) -> Puz {
	puz: Puz
	raw_lines := strings.split_lines(data, allocator = context.temp_allocator)
	puz.maxy = len(raw_lines)
	first := true
	cost: int
	for raw_line, y in raw_lines {
		if first {
			first = false
			puz.maxx = len(raw_line)
			puz.grid = make([]Content, puz.maxy * puz.maxx)
		}
		for char, x in raw_line {
			loc := Point{x, y}
			if char == 'S' {
				puz.start = loc
				cost = 0
			} else if char == 'E' {
				puz.end = loc
			}
			char_mod: rune
			if char == '.' do char_mod = ' '
			else if char == '#' do char_mod = '█'
			else do char_mod = char
			put(&puz, loc, Content(char_mod))
		}
	}

	return puz
}

// -------------------------------------------------------------------------

@(private = "file")
can_move :: proc(
	puz: Puz,
	visited: map[int]struct {},
	loc: Point,
	dir: Dir,
	check_visited: bool = true,
) -> (
	moved: Point,
	ok: bool,
) {
	moved = shift(loc, dir)
	if get(puz, moved) == Content.Wall do return loc, false
	if inbounds(puz, loc) && (!check_visited || !(hash(moved) in visited)) do return moved, true
	return loc, false
}

@(private = "file")
ppuz :: proc(puz: Puz, visited: map[int]struct {} = nil) {
	for y in 0 ..< puz.maxy {
		for x in 0 ..< puz.maxx {
			p := Point{x, y}
			c := rune(get(puz, p))
			if c == rune(Content.Wall) {
				fmt.printf("%v%v", c, c)
			} else if visited != nil && c == rune(Content.Space) && hash(p) in visited {
				fmt.print(". ")
			} else {
				fmt.printf("%v ", c)
			}
		}
		fmt.println()
	}
	fmt.printfln("Start: (%v,%v)\nEnd:   (%v,%v)", puz.start.x, puz.start.y, puz.end.x, puz.end.y)
}

@(private = "file")
inbounds :: #force_inline proc(puz: Puz, loc: Point) -> bool {
	return !(loc.x < 0 || loc.x >= puz.maxx || loc.y < 0 || loc.y >= puz.maxy)
}

@(private = "file")
get :: #force_inline proc(puz: Puz, loc: Point) -> Content {
	if !inbounds(puz, loc) do return nil
	return puz.grid[loc.y * puz.maxy + loc.x]
}

@(private = "file")
put :: #force_inline proc(puz: ^Puz, loc: Point, content: Content) -> bool {
	if !inbounds(puz^, loc) do return false
	puz.grid[loc.y * puz.maxy + loc.x] = content
	return true
}

@(private = "file")
hash :: proc(loc: Point, dir: Dir = .N) -> int {
	return int(dir) * 1000000 + loc.y * 1000 + loc.x
}

@(private = "file")
destroy_puz :: proc(puz: ^Puz) {
	delete(puz.grid)
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

@(private = "file")
node_less_cost :: proc(a, b: CostNode) -> bool {return a.cost < b.cost}

@(private = "file")
node_swap :: proc(q: []CostNode, i, j: int) {q[i], q[j] = q[j], q[i]}
