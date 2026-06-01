import asyncio
import websockets


async def run_censor_tests(mask: bytearray):
    # Try all known 29x29 photo IDs from the database
    photo_ids = ["Wo6vGDoYfzk"]
    uri_template = "ws://127.0.0.1:1337/censor/{}"

    scenarios = ["nothing", "half", "all", "blackout", "middle", "middle_up"]

    for photo_id in photo_ids:
        print(f"\n=== Testing Photo ID: {photo_id} ===")
        uri = uri_template.format(photo_id)

        for mode in scenarios:
            print(f"--- Scenario: Censor {mode.upper()} ---")
            try:
                # Use a longer timeout and explicit close
                async with websockets.connect(uri, close_timeout=10) as websocket:
                    print("Connected! Sending mask...")
                    await websocket.send(mask)

                    # The server sends two messages: a binary frame (the image) and a text frame (the size)
                    for i in range(2):
                        try:
                            response = await asyncio.wait_for(
                                websocket.recv(), timeout=5.0
                            )
                            if isinstance(response, bytes):
                                filename = f"censored_{photo_id}_{mode}.png"
                                with open(filename, "wb") as f:
                                    f.write(response)
                                print(
                                    f"Received image: {len(response)} bytes -> {filename}"
                                )
                            else:
                                print(f"Server replied: {response}")
                        except asyncio.TimeoutError:
                            print(f"Timeout waiting for message {i + 1}")
                            break

            except Exception as e:
                print(f"Error: {e}")
                # traceback.print_exc()
