"""Synthetic local HTTP/process tests. No model, user data or external request."""
import io
import json
import multiprocessing as mp
import os
import signal
import socket
import struct
import threading
import time
import unittest
from concurrent.futures import ThreadPoolExecutor
from unittest.mock import patch

import solver
import worker


def blocking_calculate(_value):
    time.sleep(30)


def cpu_calculate(_value):
    while True: pass


def memory_calculate(_value):
    return bytearray(solver.CAS_MEMORY_BYTES * 2)


def wall_cas(connection, operation, value):
    with patch("math_tools.calculate", blocking_calculate):
        solver.cas_child(connection, operation, value)


def cpu_cas(connection, operation, value):
    with patch("math_tools.calculate", cpu_calculate):
        solver.cas_child(connection, operation, value)


def memory_cas(connection, operation, value):
    with patch("math_tools.calculate", memory_calculate):
        solver.cas_child(connection, operation, value)


def environment_cas(connection, operation, value):
    def inspect(_value):
        import resource
        return json.dumps({"empty_environment": not os.environ,
            "cpu": resource.getrlimit(resource.RLIMIT_CPU),
            "memory": resource.getrlimit(resource.RLIMIT_AS),
            "core": resource.getrlimit(resource.RLIMIT_CORE)})
    with patch("math_tools.calculate", inspect): solver.cas_child(connection, operation, value)


def tracked_cas(connection, operation, value):
    value["pid_pipe"].send(os.getpid())
    value["ready"].set()
    with patch("math_tools.calculate", blocking_calculate):
        solver.cas_child(connection, operation, {})


def worker_with_cas(body, connection):
    tool = {"ready": body["ready"], "pid_pipe": body["pid_pipe"]}
    with patch("solver.complete", return_value={"tools": [tool]}), patch("solver.cas_child", tracked_cas):
        worker.child(body, connection)


def normal_worker(body, connection):
    with patch("worker.infer_ocr", return_value={"fixture": True}): worker.child(body, connection)


def partial_cas(connection, _operation, _value):
    # multiprocessing's pipe frame says 128 bytes, but only one arrives.
    os.write(connection.fileno(), struct.pack("!i", 128) + b"{")
    time.sleep(30)


def partial_worker(body, connection):
    os.setsid()
    signal.signal(signal.SIGTERM, signal.SIG_IGN)
    os.write(connection.fileno(), struct.pack("!i", 128) + b"{")
    body["ready"].set()
    time.sleep(30)


def stubborn_worker_with_cas(body, connection):
    def complete(_messages):
        signal.signal(signal.SIGTERM, signal.SIG_IGN)
        return {"tools": [{"ready": body["ready"], "pid_pipe": body["pid_pipe"]}]}
    with patch("solver.complete", side_effect=complete), patch("solver.cas_child", tracked_cas):
        worker.child(body, connection)


class ProcessTests(unittest.TestCase):
    def test_partial_cas_pipe_frame_does_not_disable_wall_timeout(self):
        before = set(threading.enumerate())
        result = solver.bounded_cas("calculate", {}, timeout=.25, _target=partial_cas)
        self.assertEqual(result.error, "tool_timeout")
        self.assertEqual(mp.active_children(), [])
        self.assertEqual(set(threading.enumerate()), before)

    def test_partial_worker_pipe_frame_does_not_disable_deadline(self):
        ready = mp.get_context("spawn").Event()
        now = [0.0]
        before = set(threading.enumerate())
        with ThreadPoolExecutor(max_workers=1) as pool:
            future = pool.submit(worker.execute, {"ready": ready}, timeout=20,
                _target=partial_worker, _clock=lambda: now[0])
            self.assertTrue(ready.wait(10))
            now[0] = 19
            with self.assertRaises(TimeoutError): future.result(timeout=3)
            self.assertTrue(future.done(), "executor must finish, not the test's Future timeout")
        self.assertEqual(mp.active_children(), [])
        self.assertEqual(set(threading.enumerate()), before)

    def test_real_cas_limits_and_empty_environment(self):
        result = solver.bounded_cas("calculate", {}, _target=environment_cas)
        self.assertIsNone(result.error)
        limits = json.loads(result.value)
        self.assertTrue(limits["empty_environment"])
        self.assertEqual(limits["cpu"], [4, 4])
        self.assertEqual(limits["memory"], [768 * 1024**2] * 2)
        self.assertEqual(limits["core"], [0, 0])

    def test_real_cas_memory_limit_failure(self):
        self.assertEqual(solver.bounded_cas("calculate", {}, _target=memory_cas).error, "tool_unavailable")
        self.assertEqual(mp.active_children(), [])

    def test_actual_cas_failure_stops_the_real_solve_loop(self):
        tool = {"action": "simplify", "expression": {"number": "2"}}
        with patch("solver.complete", return_value={"tools": [tool, tool]}) as model, \
             patch("solver.cas_child", memory_cas):
            with self.assertRaises(solver.CalculationUnavailable):
                solver.solve({"text": "1+1", "document_id": "fixture", "revision": 1, "reference_answer": "2"})
            self.assertEqual(model.call_count, 1)
        self.assertEqual(mp.active_children(), [])

    def test_real_cas_cpu_limit_failure(self):
        self.assertEqual(solver.bounded_cas("calculate", {}, _target=cpu_cas).error, "tool_unavailable")
        self.assertEqual(mp.active_children(), [])

    def test_real_cas_wall_timeout_kills_and_reaps(self):
        # Short injected parent wall limit; actual CPU/memory limits are unchanged.
        result = solver.bounded_cas("calculate", {}, timeout=0.25, _target=wall_cas)
        self.assertEqual(result.error, "tool_timeout")
        self.assertEqual(mp.active_children(), [])

    def test_worker_cancellation_reaps_active_cas_then_next_request_succeeds(self):
        ctx = mp.get_context("spawn")
        ready = ctx.Event(); parent, remote = ctx.Pipe(duplex=False)
        cancelled = threading.Event()
        body = {"operation": "solve", "text": "fixture", "document_id": "fixture", "revision": 1,
                "reference_answer": "2", "ready": ready, "pid_pipe": remote}
        try:
            with ThreadPoolExecutor(max_workers=1) as pool:
                future = pool.submit(worker.execute, body, timeout=20,
                    cancelled=cancelled.is_set, _target=worker_with_cas)
                self.assertTrue(ready.wait(10), "CAS must be running before cancellation")
                cas_pid = parent.recv(); cancelled.set()
                with self.assertRaises(TimeoutError): future.result(timeout=3)
                self.assertTrue(future.done())
            with self.assertRaises(ProcessLookupError): os.kill(cas_pid, 0)
            self.assertEqual(mp.active_children(), [])
            self.assertEqual(worker.execute({"operation": "ocr"}, timeout=5, _target=normal_worker), {"fixture": True})
        finally: parent.close(); remote.close()

    def test_worker_total_deadline_reaps_cas_descendant(self):
        ctx = mp.get_context("spawn")
        ready = ctx.Event(); parent, remote = ctx.Pipe(duplex=False)
        body = {"operation": "solve", "text": "fixture", "document_id": "fixture", "revision": 1,
                "reference_answer": "2", "ready": ready, "pid_pipe": remote}
        now = [0.0]
        try:
            with ThreadPoolExecutor(max_workers=1) as pool:
                future = pool.submit(worker.execute, body, timeout=20, _target=worker_with_cas,
                    _clock=lambda: now[0])
                self.assertTrue(ready.wait(10))
                cas_pid = parent.recv()
                # Exhaust inference's portion of the same total deadline,
                # leaving its reserved second for kill/join, not another budget.
                now[0] = 19
                with self.assertRaises(TimeoutError): future.result(timeout=3)
                self.assertTrue(future.done())
            with self.assertRaises(ProcessLookupError): os.kill(cas_pid, 0)
            self.assertEqual(mp.active_children(), [])
        finally: parent.close(); remote.close()

    def test_hard_group_kill_reaps_cas_without_relying_on_host_init(self):
        ctx = mp.get_context("spawn")
        ready = ctx.Event(); parent, remote = ctx.Pipe(duplex=False)
        cancelled = threading.Event()
        body = {"operation": "solve", "text": "fixture", "document_id": "fixture", "revision": 1,
                "reference_answer": "2", "ready": ready, "pid_pipe": remote}
        try:
            with ThreadPoolExecutor(max_workers=1) as pool:
                future = pool.submit(worker.execute, body, timeout=20,
                    cancelled=cancelled.is_set, _target=stubborn_worker_with_cas)
                self.assertTrue(ready.wait(10))
                cas_pid = parent.recv(); cancelled.set()
                with self.assertRaises(TimeoutError): future.result(timeout=3)
                self.assertTrue(future.done())
            # Also excludes an unreaped zombie: kill(pid, 0) would find it.
            with self.assertRaises(ProcessLookupError): os.kill(cas_pid, 0)
            self.assertEqual(mp.active_children(), [])
            self.assertEqual(worker.execute({"operation": "ocr"}, timeout=5, _target=normal_worker), {"fixture": True})
        finally: parent.close(); remote.close()


class FakeSocket:
    def __init__(self): self.timeouts = []
    def settimeout(self, value): self.timeouts.append(value)


class BodyTests(unittest.TestCase):
    def test_production_budgets_are_10_and_50(self):
        self.assertEqual(worker.BODY_SECONDS, 10)
        self.assertEqual(worker.REQUEST_SECONDS, 50)

    def test_absolute_body_deadline_does_not_restart_for_drip_bytes(self):
        now = [0.0]; connection = FakeSocket()
        class Drip:
            calls = 0
            def read1(self, _size):
                self.calls += 1
                now[0] += 8
                return b" "
        stream = Drip()
        with patch("worker.time.monotonic", side_effect=lambda: now[0]):
            with self.assertRaises(TimeoutError): worker.read_body(stream, connection, 100, 10)
        # The second read receives only the remaining 2 seconds, not 10.
        self.assertEqual(connection.timeouts, [10, 2])
        self.assertEqual(stream.calls, 2)

    def test_body_byte_limits_and_truncation(self):
        for length in [5_599_999, 5_600_000, 5_600_001]:
            with self.subTest(length=length):
                if length <= worker.MAX_BODY:
                    self.assertEqual(len(worker.read_body(io.BytesIO(b" " * length), FakeSocket(), length, time.monotonic() + 5)), length)
                else:
                    with self.assertRaises(ValueError): worker.read_body(io.BytesIO(b" " * length), FakeSocket(), length, time.monotonic() + 5)
        with self.assertRaises(ValueError): worker.read_body(io.BytesIO(b"{"), FakeSocket(), 2, time.monotonic() + 5)


class HttpTests(unittest.TestCase):
    def setUp(self):
        self.secret = "synthetic-test-only-0000000000000000"
        self.env = patch.dict(os.environ, {"WORKER_SECRET": self.secret}); self.env.start()
        self.slot = patch.object(worker, "SLOT", threading.BoundedSemaphore(1)); self.slot.start()
        self.started = threading.Event()
        self.finished = threading.Event()
        self.reading = threading.Event()
        self.received = []
        test = self
        original_read = worker.read_body
        def read(*args):
            self.reading.set()
            return original_read(*args)
        self.body_patch = patch("worker.read_body", side_effect=read); self.body_patch.start()
        class TestHandler(worker.Handler):
            body_seconds = .15
            request_seconds = 2
            def do_POST(self):
                try: super().do_POST()
                finally: test.finished.set()
            @staticmethod
            def execute(body, timeout, cancelled):
                test.received.append(timeout)
                test.started.set()
                return {"fixture": True}
        self.handler = TestHandler
        self.server = worker.ThreadingHTTPServer(("127.0.0.1", 0), TestHandler)
        self.thread = threading.Thread(target=self.server.serve_forever, kwargs={"poll_interval": .01}, daemon=True)
        self.thread.start()

    def tearDown(self):
        self.server.shutdown(); self.server.server_close(); self.thread.join(2)
        self.body_patch.stop(); self.slot.stop(); self.env.stop()

    def connect(self, length, secret=None):
        client = socket.create_connection(self.server.server_address, timeout=2)
        client.sendall(f"POST /infer HTTP/1.1\r\nHost: localhost\r\nAuthorization: Bearer {secret or self.secret}\r\nContent-Length: {length}\r\n\r\n".encode())
        return client

    def normal(self, raw=None):
        raw = raw or b'{"schema_version":1,"operation":"ocr","kind":"text"}'
        with self.connect(len(raw)) as client:
            client.sendall(raw)
            return client.recv(4096).split(b"\r\n", 1)[0]

    def assert_free(self):
        self.assertTrue(worker.SLOT.acquire(timeout=2))
        worker.SLOT.release()

    def test_actual_handler_drip_deadline_and_slot_recovery(self):
        with self.connect(100) as slow:
            slow.sendall(b" ")
            # Wait until the real handler owns the slot, then a second request
            # must reject without releasing that first request's semaphore.
            self.assertTrue(self.reading.wait(2))
            with self.connect(2) as other:
                other.sendall(b"{}")
                self.assertIn(b"429", other.recv(1024).split(b"\r\n")[0])
            self.assertFalse(worker.SLOT.acquire(blocking=False))
            self.assertIn(b"503", slow.recv(4096).split(b"\r\n")[0])
        self.assert_free()
        self.assertIn(b"200", self.normal())

    def test_body_time_is_deducted_from_inference_budget(self):
        # Inject the monotonic clock, while still invoking the actual Handler.
        original = worker.read_body
        now = [0.0]
        def read(*args):
            value = original(*args); now[0] = .1; return value
        with patch("worker.time.monotonic", side_effect=lambda: now[0]), patch("worker.read_body", side_effect=read):
            self.assertIn(b"200", self.normal())
        self.assertEqual(self.received, [1.9])
        self.assert_free()

    def test_malformed_body_disconnect_timeout_all_release_slot(self):
        self.assertIn(b"503", self.normal(b"{"))
        self.assert_free()
        self.finished.clear()
        client = self.connect(100); client.sendall(b"{"); client.close()
        self.assertTrue(self.finished.wait(2))
        self.assert_free()
        self.assertIn(b"200", self.normal())

    def test_inference_observes_disconnect_before_slot_reuse(self):
        exited = threading.Event()
        def execute(_body, timeout, cancelled):
            self.started.set()
            deadline = time.monotonic() + timeout
            while not cancelled():
                if time.monotonic() >= deadline: raise TimeoutError()
                threading.Event().wait(.001)
            exited.set(); raise TimeoutError()
        self.handler.execute = staticmethod(execute)
        raw = b'{"schema_version":1,"operation":"ocr","kind":"text"}'
        client = self.connect(len(raw)); client.sendall(raw)
        self.assertTrue(self.started.wait(2)); client.close()
        self.assertTrue(exited.wait(2)); self.assert_free()

    def test_response_exact_limit_and_overflow(self):
        for length, status in [(worker.MAX_RESPONSE, b"200"), (worker.MAX_RESPONSE + 1, b"503")]:
            # json.dumps adds two quote bytes to this ASCII string.
            self.handler.execute = staticmethod(lambda *_args, **_kwargs: "a" * (length - 2))
            self.assertIn(status, self.normal()); self.assert_free()


if __name__ == "__main__": unittest.main()
