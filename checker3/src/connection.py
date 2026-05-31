from types import TracebackType
from typing import Self, Type, cast
from logging import LoggerAdapter
import httpx
from enochecker3 import MumbleException


class Connection(httpx.AsyncClient):
    def __init__(self, client: httpx.AsyncClient, logger: LoggerAdapter) -> None:
        self.logger = logger
        self.client = client
        self.client.headers.update(
            {
                "User-Agent": "Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36"
            }
        )

    async def send(
        self,
        request: httpx.Request,
        *,
        stream: bool = False,
        auth: (
            httpx._types.AuthTypes | httpx._client.UseClientDefault | None
        ) = httpx.USE_CLIENT_DEFAULT,
        follow_redirects: (
            bool | httpx._client.UseClientDefault
        ) = httpx.USE_CLIENT_DEFAULT,
    ) -> httpx.Response:
        self.last_request = request
        return await super().send(
            request, stream=stream, auth=auth, follow_redirects=follow_redirects
        )

    async def __aenter__(self: Self) -> Self:
        """Enter context and properly initialize the underlying httpx client."""
        await super().__aenter__()
        return self

    async def __aexit__(
        self,
        exc_type: Type[BaseException] | None = None,
        exc_value: BaseException | None = None,
        traceback: TracebackType | None = None,
    ) -> None:
        """Exit context and properly teardown the underlying httpx client."""
        # Check for MumbleException and append request context if available
        if (
            isinstance(exc_value, MumbleException)
            and exc_value.message is not None
            and self.last_request is not None
        ):
            exc_value.message += (
                f" ({self.last_request.method} {self.last_request.url.path})"
            )

        # Ensure the base class connection pool is properly closed
        await super().__aexit__(exc_type, exc_value, traceback)

    @classmethod
    def wrap(cls, client: httpx.AsyncClient) -> Self:
        """Wrap an existing http client."""
        client.__class__ = cls
        wrapped_client = cast(Self, client)

        # Initialize the attribute on the wrapped instance if it doesn't exist
        if not hasattr(wrapped_client, "last_request"):
            wrapped_client.last_request = None

        return wrapped_client
