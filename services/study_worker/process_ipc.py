"""Bounded JSON pipe reception without blocking the owner's deadline loop."""
import json
import threading


def send_result(connection, result, *, maximum=None, before_send=None):
    payload = json.dumps(result, ensure_ascii=False, allow_nan=False).encode()
    if maximum is not None and len(payload) > maximum:
        raise ValueError('result_too_large')
    if before_send is not None:
        before_send()
    connection.send_bytes(payload)


class ResultReader:
    def __init__(self, connection, maximum):
        self.done = threading.Event()
        self.value = None
        self.error = None
        def receive():
            try:
                self.value = json.loads(connection.recv_bytes(maxlength=maximum))
            except Exception as error:
                self.error = error
            finally:
                self.done.set()
        # A partial pipe frame can stall recv_bytes after poll() reports ready.
        # Only this reader waits in recv; the owner keeps enforcing cancellation.
        self.thread = threading.Thread(target=receive, daemon=True)
        self.thread.start()

    def result(self):
        if self.error is not None: raise self.error
        return self.value

    def close(self, timeout):
        # Call after terminating/reaping all writers. EOF then releases recv.
        self.thread.join(timeout=max(0, timeout))
        return not self.thread.is_alive()
