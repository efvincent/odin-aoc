#+private file
package aoc24

import "../util"
import "core:strconv"
import "core:strings"

@(private = "package")
solve_d05 :: proc(part: util.Part, data: string) -> string {
	switch part {
	case .p1:
		return solve1(data)
	case .p2:
		return solve2(data)
	}
	return ""
}

Puz :: struct {
	rules: map[int][dynamic]int,
	jobs:  [dynamic][dynamic]int,
}

parse :: proc(data: string) -> Puz {
	orig_allocator := context.allocator
	context.allocator = context.temp_allocator
	defer context.allocator = orig_allocator

	parts := strings.split(data, "\n\n")
	raw_rules := strings.split_lines(parts[0])
	raw_jobs := strings.split_lines(parts[1])

	rules := make(map[int][dynamic]int)
	for raw_rule in raw_rules {
		rule_parts := strings.split(raw_rule, "|")
		key := strconv.atoi(rule_parts[0])
		value := strconv.atoi(rule_parts[1])
		if key in rules {
			value_list := rules[key]
			append(&value_list, value)
			rules[key] = value_list
		} else {
			new_value_list := make([dynamic]int)
			append(&new_value_list, value)
			rules[key] = new_value_list
		}
	}

	jobs := make([dynamic][dynamic]int)
	for raw_job in raw_jobs {
		raw_pages := strings.split(raw_job, ",")
		page_list := make([dynamic]int)
		for raw_page in raw_pages {
			page := strconv.atoi(raw_page)
			append(&page_list, page)
		}
		append(&jobs, page_list)
	}

	puz := Puz{rules, jobs}
	return puz
}

solve2 :: proc(data: string) -> string {
	puz := parse(data)
	tot := 0
	for job, job_idx in puz.jobs {
		if !is_job_valid(puz, job_idx) {
			fix_job(&puz, job_idx)
			mid := job[len(job) / 2]
			tot += mid
		}
	}
	return util.to_str(tot)
}

fix_job :: proc(puz: ^Puz, job_idx: int) {
	job := puz.jobs[job_idx]
	recheck := false
	for !is_job_valid(puz^, job_idx) {
		recheck = false
		for job_page_idx := 0; job_page_idx < len(job) && !recheck; job_page_idx += 1 {
			job_page := job[job_page_idx]
			page_rule := puz.rules[job_page]
			for prev_page_idx := 0; prev_page_idx < job_page_idx && !recheck; prev_page_idx += 1 {
				prev_page := job[prev_page_idx]
				for rule_page in page_rule {
					if prev_page == rule_page {
						tmp := job_page
						job[job_page_idx] = prev_page
						job[prev_page_idx] = tmp
						recheck = true
						break
					}
				}
			}
		}
	}
}

is_job_valid :: proc(puz: Puz, job_idx: int) -> bool {
	job := puz.jobs[job_idx]
	for page, idx in job {
		page_rule := puz.rules[page]
		for prev_idx := 0; prev_idx < idx; prev_idx += 1 {
			prev_page := job[prev_idx]
			for rule_page in page_rule {
				if prev_page == rule_page {
					return false
				}
			}
		}
	}
	return true
}

solve1 :: proc(data: string) -> string {
	puz := parse(data)
	tot := 0
	for job, job_idx in puz.jobs {
		if is_job_valid(puz, job_idx) {
			mid := job[len(job) / 2]
			tot += mid
		}
	}
	return util.to_str(tot)
}
