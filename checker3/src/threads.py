import threading
import functools
from typing import Callable
import asyncio


def run_in_thread(func: Callable) -> Callable:
    """Decorator to run an async function in a new thread."""

    @functools.wraps(func)
    def wrapper(*args, **kwargs) -> threading.Thread:
        def _run_async():
            asyncio.run(func(*args, **kwargs))

        print("running in new thread")
        thread = threading.Thread(target=_run_async)
        thread.start()
        return thread

    return wrapper
