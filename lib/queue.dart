/// A queue for executing jobs.
class Queue {
  final List<Future<void> Function()> _jobs = [];

  /// Adds a job to the queue.
  ///
  /// The job is a function that returns a `Future<void>`.
  /// It will be executed in the order it was added when the `run` method is called.
  void add(Future<void> Function() job) {
    _jobs.add(job);
  }

  /// Runs all the jobs in the queue in order, waiting for each job to finish before
  /// starting the next one.
  ///
  /// This method returns a future that completes when all the jobs in the queue
  /// have completed.
  Future<void> run() async {
    for (var job in _jobs) {
      await job();
    }
  }

  /// Removes all jobs from the queue.
  ///
  /// This is useful when you want to discard all the jobs in the queue and start
  /// over with a fresh queue.
  void clear() {
    _jobs.clear();
  }

  /// Removes a job from the queue.
  ///
  /// The job is removed from the queue, and will not be executed when `run` is called.
  ///
  /// If the job is not in the queue, this method does nothing.
  void remove(Future<void> Function() job) {
    _jobs.remove(job);
  }
}
