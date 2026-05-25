import asyncio
import httpx
from utils import Connection, get_placeholder_png
from logging import getLogger
import sys
import json

logger = getLogger('test')

async def t():
    client = httpx.AsyncClient(base_url='http://192.168.178.31:1337')
    conn = Connection(client, logger)
    u = 'test_final_' + str(id(client))
    try:
        print(f"Registering {u}")
        await conn.register_user(u, u, u)
        print(f"Logging in {u}")
        await conn.login_user(u, u)
        print(f"UID: {conn.uid}")
        
        print(f"Uploading photo for {u}")
        loc = await conn.upload_photo(
            description="test photo",
            premium=False,
            private=False,
            location="Berlin",
            camera="Gemini",
            tags="test",
            photo_name="test.png",
            photo_data=get_placeholder_png(),
        )
        print(f"UPLOAD result (loc): {loc}")
        
        # Test profile with retries
        for attempt in range(5):
            print(f"Polling profile (attempt {attempt+1})")
            profile_html = await conn.get_user_profile(u)
            profile_data = json.loads(profile_html)
            if profile_data.get("photos"):
                print(f"SUCCESS: Photo found! ID: {profile_data['photos'][0]['public_id']}")
                return
            await asyncio.sleep(2)
        
        print("FAILED: Photo never appeared in profile")
    except Exception as e:
        print(f"ERROR: {e}")
    finally:
        await client.aclose()

if __name__ == "__main__":
    asyncio.run(t())
