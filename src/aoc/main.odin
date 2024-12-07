package aoc

import "core:log"
import "core:mem"

TrackingData :: struct {
	count: int,
	size:  int,
}

main :: proc() {
	// when ODIN_DEBUG {
	// set up the tracking allocator
	track: mem.Tracking_Allocator
	mem.tracking_allocator_init(&track, context.allocator)
	orig_allocator := context.allocator

	// and the console logger
	logger := log.create_console_logger()
	orig_logger := context.logger

	// set the context to use these
	context.allocator = mem.tracking_allocator(&track)
	context.logger = logger

	defer {
		log_track(track)
		if len(track.allocation_map) > 0 {
			m := make(map[string]TrackingData)
			defer delete(m)
			log.warnf("%v allocations not freed", len(track.allocation_map))
			for _, entry in track.allocation_map {

				key := entry.location.procedure
				data, found := m[key]
				if found {
					data.count += 1
					data.size += entry.size
					m[key] = data
				} else {
					m[key] = {1, entry.size}
				}
			}
			for k, v in m {
				log.warnf("%v allocs, %v bytes not freed: at '%v'", v.count, v.size, k)
			}
		}
		if len(track.bad_free_array) > 0 {
			m := make(map[string]TrackingData)
			defer delete(m)
			log.warnf("%v incorrect frees", len(track.bad_free_array))
			for entry in track.bad_free_array {
				log.warnf("at: %v", entry.location)
			}
		}

		context.allocator = orig_allocator
		mem.tracking_allocator_destroy(&track)

		console_logger := context.logger
		context.logger = orig_logger
		log.destroy_console_logger(console_logger)
	}
	// }

	// start_time := time.read_cycle_counter()
	run()
	// end_time := time.read_cycle_counter()
	// elapsed_time := end_time - start_time
	// freq, ok := time.tsc_frequency()
	// if ok {
	// 	elapsed_secs := elapsed_time / freq
	// 	log.infof("Exec time in seconds/cycles: %v/%v", elapsed_secs, elapsed_time)
	// } else {
	// 	log.warnf("Cannot determine tsc frequency")
	// }
}

log_track :: proc(t: mem.Tracking_Allocator) {
	log.infof(
		"*** ALLOCATION TRACKING ***\n\tTotal Mem Alloc:\t%v\n\tTotal Alloc Count:\t%v\n\tTotal Mem Freed:\t%v\n\tTotal Free Count:\t%v\n\tPeak Mem Alloc:\t\t%v",
		t.total_memory_allocated,
		t.total_allocation_count,
		t.total_memory_freed,
		t.total_free_count,
		t.peak_memory_allocated,
	)
}
