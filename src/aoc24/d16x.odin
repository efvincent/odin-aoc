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
Node :: struct {
	pos:  Point,
	dir:  Dir,
	cost: int,
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

solve_d16x :: proc(part: util.Part, data: string) -> string {
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
	defer delete(puz.grid)
	c := find_smallest_cost(&puz)
	return util.to_str(c)
}

@(private = "file")
find_smallest_cost :: proc(puz: ^Puz) -> int {
	smallest_cost := max(int)
	visited := make(map[int]struct {})
	distance := make(map[int]int)
	queue: pq.Priority_Queue(Node)

	defer {
		delete(visited)
		delete(distance)
		pq.destroy(&queue)
	}

	// initialize the queue with the starting position
	pq.init(&queue, node_less_cost, node_swap)
	pq.push(&queue, Node{puz.start, .E, 0})

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
			pq.push(&queue, Node{next_pos, dir, next_cost})
		}
	}
	return smallest_cost
}

// find_all_best_paths :: proc(puz: ^Puz) -> (int, [][]Node) {
// 	Pred :: struct {
// 		pos: Point,
// 		dir: Dir,
// 	}

// 	smallest_cost := max(int)
// 	distance := make(map[int]int)
// 	predecessors := make(map[int][dynamic]Pred)
// 	queue: pq.Priority_Queue(Node)
// 	defer {
// 		delete(distance)
// 		delete(predecessors)
// 		pq.destroy(&queue)
// 	}

// 	// no visited set, we use distance to track where we have been
// 	pq.init(&queue, node_less_cost, node_swap)
// 	pq.push(&queue, Node{puz.start, .E, 0})

// 	// intialize start distance
// 	distance[hash(puz.start, .E)] = 0

// 	// process items in the priority queue
// 	for pq.len(queue) > 0 {
// 		cur_node := pq.pop(&queue)
// 		d := cur_node.dir
// 		cur_node_id := hash(cur_node.pos, cur_node.dir)

// 		// skip if the cost of this node is bigger than we have found previously
// 		if cost, ok := distance[cur_node_id]; ok {
// 			if cur_node.cost > cost do continue
// 		}

// 		if cur_node.pos == puz.end {
// 			smallest_cost = min(smallest_cost, cur_node.cost)
// 			// don't continue, we need to explore all paths to the end
// 		}

// 		// loop through all directions
// 		for n in 0 ..< 4 {
// 			next_pos: Point
// 			ok: bool
// 			dir := Dir(n)

// 			// if the move in the current dir from the current node is not allowed, check next dir
// 			if next_pos, ok = can_move(puz^, nil, cur_node.pos, dir, false); !ok {
// 				continue
// 			}

// 			// get the next node from `cur_node` in direction `dir`
// 			next_node_id := hash(next_pos, dir)
// 			next_cost := cur_node.cost + 1 + cost_change(d, dir)

// 			// ignore paths with cost too big
// 			if next_cost > smallest_cost && cur_node.pos != puz.end {
// 				continue
// 			}

// 			// is the path we're exploring better than the one we already have here?
// 			existing_cost_id := hash(next_pos, d)
// 			existing_cost, existing_cost_found := distance[existing_cost_id]
// 			pred := Pred {
// 				pos = next_pos,
// 				dir = d,
// 			}
// 			if !existing_cost_found || next_cost < existing_cost {
// 				// better path
// 				distance[existing_cost_id] = next_cost
// 				{
// 					pred_list := make_dynamic_array([dynamic]Pred)
// 					append(&pred_list, pred)
// 					predecessors[existing_cost_id] = pred_list
// 				}
// 			} else if next_cost > existing_cost {
// 				continue
// 			} else {
// 				// same path, just update predecessors
// 				if pred_list, pred_list_found := predecessors[existing_cost_id]; pred_list_found {
// 					if !slice.contains(pred_list[:], pred) {
// 						append(&pred_list, pred)
// 					}
// 				}
// 			}

// 			pq.push(&queue, Node{next_pos, dir, next_cost})

// 		}
// 	}

// 	// clean up the predecessors at the end
// 	defer {
// 		for _, p in predecessors {
// 			delete_dynamic_array(p)
// 		}
// 	}

// 	// now that we have explored the whole pam, create the paths
// 	all_shortest_paths := make([dynamic]([dynamic]Pred))
// 	defer delete_dynamic_array(all_shortest_paths)

// 	// a stack to keep all the in-progress paths we're building
// 	stack := make_dynamic_array([dynamic]Pred)

// 	for n in 0 ..< 4 {
// 		dir := Dir(n)
// 		node := Pred {
// 			pos = puz.end,
// 			dir = dir,
// 		}
// 		if node in distance {
// 			append(&stack)
// 		}
// 	}

// 	return 0, nil
// }

/*


    // Now that we have explored the whole map, create the paths.
    // Iterative Backtracking.
    let mut all_shortest_paths: Vec<Vec<PathNode>> = Vec::new();
    // A stack to keep all the in-progress paths we are building.
    let mut stack: VecDeque<(Vec<PathNode>, (usize, Direction))> = VecDeque::new();

    // Initialize the stack with the end position / direction pair.
    for end_direction in ALL_DIRECTIONS
        .iter()
        .filter(|&&d| distance.contains_key(&(end, d)))
    {
        stack.push_back((
            vec![PathNode {
                pos: end,
                dir: *end_direction,
            }],
            (end, *end_direction),
        ));
    }

    while let Some((current_path, current_node)) = stack.pop_back() {
        if current_node == (start, start_direction) {
            // A complete path is found, adding it to the list.
            let mut complete_path = current_path.clone();
            // Path was build from end, so reverse it.
            complete_path.reverse();
            all_shortest_paths.push(complete_path);
        } else if let Some(prev_nodes) = predecessors.get(&current_node) {
            // We got all the predecessors of the current node.
            for &(prev_pos, prev_dir) in prev_nodes {
                // For each predecessor, we create a new path and add it
                // to the stack, to be checked.
                let mut new_path = current_path.clone();
                new_path.push(PathNode {
                    pos: prev_pos,
                    dir: prev_dir,
                });
                stack.push_back((new_path, (prev_pos, prev_dir)));
            }
        }
    }

    (smallest_cost, all_shortest_paths)
}
*/
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
node_less_cost :: proc(a, b: Node) -> bool {return a.cost < b.cost}

@(private = "file")
node_swap :: proc(q: []Node, i, j: int) {q[i], q[j] = q[j], q[i]}
