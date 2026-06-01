from types import TracebackType
from typing import Self, Type, cast
from logging import LoggerAdapter
import httpx
from enochecker3 import MumbleException


class Connection(httpx.AsyncClient):
    logger: LoggerAdapter

    async def __aenter__(self: Self) -> Self:
        return self

    async def __aexit__(
        self,
        exc_type: Type[BaseException] | None = None,
        exc_value: BaseException | None = None,
        traceback: TracebackType | None = None,
    ) -> None:
        if (
            isinstance(exc_value, MumbleException)
            and exc_value.message is not None
            and hasattr(self, "last_request")
            and self.last_request is not None
        ):
            exc_value.message += (
                f" ({self.last_request.method} {self.last_request.url.path})"
            )

    @classmethod
    def wrap(cls, client: httpx.AsyncClient, logger: LoggerAdapter) -> Self:
        """Wrap an existing http client."""
        client.__class__ = cls
        wrapped_client = cast(Self, client)
        wrapped_client.logger = logger
        wrapped_client.last_request = None
        wrapped_client.headers.update(
            {
                "User-Agent": "Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36"
            }
        )
        return wrapped_client
