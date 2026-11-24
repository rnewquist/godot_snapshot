# test_integration_threading_threadpool.gd
# Tier 1 Integration Suite 14: Threading, WorkerThreadPool & Concurrency (10 tests)
# Tests WorkerThreadPool, Mutex, Semaphore, and Threads with wait_to_finish lifecycle.
extends "res://addons/gdtest/core/test_suite.gd"

func _init() -> void:
	suite_name = "Tier1_Threading_ThreadPool_Integration_Suite"
	test_type = "integration"

## 1. Thread Creation, Execution & wait_to_finish
func test_thread_creation_execution_and_wait_to_finish() -> void:
	var thread: Thread = Thread.new()
	var executed: Array[bool] = [false]
	
	var worker = func():
		executed[0] = true
		return 123
		
	thread.start(worker)
	assert_true(thread.is_started(), "Thread must report started")
	var result = thread.wait_to_finish()
	
	assert_true(executed[0], "Thread worker must execute")
	assert_eq(result, 123, "wait_to_finish must return worker return value")
	assert_false(thread.is_alive(), "Thread must not be alive after finish")

## 2. Thread Parameterized Task Return Value
func test_thread_with_return_value() -> void:
	var thread: Thread = Thread.new()
	var calc = func():
		var sum = 0
		for i in range(100):
			sum += i
		return sum
		
	thread.start(calc)
	var total = thread.wait_to_finish()
	assert_eq(total, 4950, "Calculated sum 0..99 must equal 4950")

## 3. Mutex Lock and Unlock Synchronization
func test_mutex_lock_unlock_synchronization() -> void:
	var mutex: Mutex = Mutex.new()
	var counter: Array[int] = [0]
	
	mutex.lock()
	counter[0] += 1
	mutex.unlock()
	
	assert_eq(counter[0], 1, "Counter under mutex must increment to 1")

## 4. Mutex try_lock Behavior
func test_mutex_try_lock() -> void:
	var mutex: Mutex = Mutex.new()
	var locked_first = mutex.try_lock()
	assert_true(locked_first, "Initial try_lock on unlocked mutex must succeed")
	
	# Spawn thread to verify try_lock returns false while held
	var check_thread: Thread = Thread.new()
	var thread_try_success: Array[bool] = [true]
	
	check_thread.start(func():
		thread_try_success[0] = mutex.try_lock()
	)
	check_thread.wait_to_finish()
	
	mutex.unlock()
	assert_false(thread_try_success[0], "try_lock on locked mutex from another thread must fail")

## 5. Semaphore Post and Wait (try_wait)
func test_semaphore_post_and_wait() -> void:
	var sem: Semaphore = Semaphore.new()
	assert_false(sem.try_wait(), "Initial try_wait on zero-count semaphore must return false")
	
	sem.post()
	assert_true(sem.try_wait(), "try_wait after post() must return true")
	assert_false(sem.try_wait(), "Subsequent try_wait must return false")

## 6. WorkerThreadPool Single Task Execution & Wait
func test_worker_thread_pool_add_task_and_wait() -> void:
	var completed: Array[bool] = [false]
	var task_fn = func():
		completed[0] = true
		
	var task_id = WorkerThreadPool.add_task(task_fn)
	assert_gte(task_id, 0, "Task ID must be non-negative")
	
	var err = WorkerThreadPool.wait_for_task_completion(task_id)
	assert_eq(err, OK, "wait_for_task_completion must return OK")
	assert_true(completed[0], "Task executed by WorkerThreadPool must complete")

## 7. WorkerThreadPool Group Task Distribution
func test_worker_thread_pool_add_group_task() -> void:
	var results: Array[int] = [0, 0, 0, 0]
	var group_fn = func(index: int):
		results[index] = (index + 1) * 10
		
	var group_id = WorkerThreadPool.add_group_task(group_fn, 4)
	WorkerThreadPool.wait_for_group_task_completion(group_id)
	
	assert_eq(results[0], 10, "Index 0 result must be 10")
	assert_eq(results[1], 20, "Index 1 result must be 20")
	assert_eq(results[2], 30, "Index 2 result must be 30")
	assert_eq(results[3], 40, "Index 3 result must be 40")

## 8. WorkerThreadPool Group Task Data Integrity with Mutex
func test_worker_thread_pool_group_task_data_integrity() -> void:
	var mutex: Mutex = Mutex.new()
	var total_sum: Array[int] = [0]
	
	var accumulate_fn = func(index: int):
		mutex.lock()
		total_sum[0] += (index + 1)
		mutex.unlock()
		
	var group_id = WorkerThreadPool.add_group_task(accumulate_fn, 10)
	WorkerThreadPool.wait_for_group_task_completion(group_id)
	
	# Sum of 1..10 = 55
	assert_eq(total_sum[0], 55, "Group task parallel sum of 1..10 must equal 55")

## 9. Multi-Thread Concurrent Data Aggregation
func test_multi_thread_concurrent_data_aggregation() -> void:
	var threads: Array[Thread] = []
	var mutex: Mutex = Mutex.new()
	var shared_list: Array[int] = []
	
	for i in range(4):
		var t = Thread.new()
		var thread_idx = i
		t.start(func():
			var sub_sum = 0
			for j in range(25):
				sub_sum += (thread_idx * 25 + j)
			mutex.lock()
			shared_list.append(sub_sum)
			mutex.unlock()
		)
		threads.append(t)
		
	for t in threads:
		t.wait_to_finish()
		
	assert_eq(shared_list.size(), 4, "All 4 threads must contribute results")
	var grand_total = 0
	for val in shared_list:
		grand_total += val
	assert_eq(grand_total, 4950, "Grand total across 4 threads must equal 4950")

## 10. Semaphore Producer-Consumer Thread Pattern
func test_semaphore_producer_consumer_pattern() -> void:
	var sem: Semaphore = Semaphore.new()
	var thread: Thread = Thread.new()
	var data_payload: Array[String] = [""]
	
	thread.start(func():
		data_payload[0] = "Thread_Data_Ready"
		sem.post()
	)
	
	sem.wait()
	assert_eq(data_payload[0], "Thread_Data_Ready", "Consumer must receive data after semaphore post")
	thread.wait_to_finish()
