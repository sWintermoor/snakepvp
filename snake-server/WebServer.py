import asyncio
import websockets
import json
from aiohttp import web
import os
import socket 
from socket import *
import threading
import subprocess

BASE_DIR = os.path.dirname(os.path.abspath(__file__))

matchmaking_queue = []
lock = threading.Lock()

async def forward_to_racket(message):
    uri = "ws://localhost:9092"
    async with websockets.connect(uri) as websocket:
        await websocket.send(message)
        response = await websocket.recv()
        return response

async def handle_client(websocket):
    try:
        print(f"New connection attempt from {websocket.remote_address}")

        with lock:
            matchmaking_queue.append(websocket)
            print(f"Client {websocket.remote_address} added to matchmaking queue")
            print(f"Queue size: {len(matchmaking_queue)}")

        # Send initial acknowledgment
        await websocket.send(json.dumps({"status": "waiting"}))

        # Wait until two clients are connected
        while len(matchmaking_queue) < 2:
            await asyncio.sleep(0.1)
            # Keep connection alive
            await websocket.ping()

        player1 = matchmaking_queue.pop(0)
        player2 = matchmaking_queue.pop(0)

        # Start Racket server first
        racket_started = await execute_racket_file(
            os.path.join(BASE_DIR, '../snake-racket/launch-snake-pvp-universe.rkt')
        )

        if not racket_started:
            print("Failed to start Racket server")
            return
        
        print(f"Match found between {player1.remote_address} and {player2.remote_address}")
        # Register players as worlds in Racket universe
        register_world1 = await forward_to_racket(json.dumps({
            "type": "register",
            "player": 1,
            "id": str(id(player1))
        }))
        
        register_world2 = await forward_to_racket(json.dumps({
            "type": "register",
            "player": 2,
            "id": str(id(player2))
        }))

        print("Notified Racket of player registration")
        # Notify players of successful registration
        await player1.send(json.dumps({"status": "connected", "player": 1}))
        await player2.send(json.dumps({"status": "connected", "player": 2}))

        print("Entering while-Loop")

        # Continuously receive and send messages
        while True:
            message1 = await player1.recv()
            message2 = await player2.recv()

            response1 = await forward_to_racket(message1)
            response2 = await forward_to_racket(message2)

            data1 = json.loads(response1)
            data2 = json.loads(response2)

            print(f"Received data from player1: {data1}")
            print(f"Received data from player2: {data2}")

            # Example of sending a message back to the clients
            await player1.send(json.dumps(data1))
            await player2.send(json.dumps(data2)) 

    except websockets.ConnectionClosed as e:
        print(f"Connection closed by client {websocket.remote_address}. Clean: {e.code} Reason: {e.reason}")
    except Exception as e:
        print(f"Error handling client {websocket.remote_address}: {str(e)}")
    finally:
        if websocket in matchmaking_queue:
            matchmaking_queue.remove(websocket)
        print(f"Client {websocket.remote_address} disconnected. Queue size: {len(matchmaking_queue)}")


# Handling html request
async def handle_html(request):
    try:
        html_file_path = os.path.join(BASE_DIR, '../snake-templates/index.html')
        with open(html_file_path, 'r') as file:
            html_content = file.read()

        return web.Response(text=html_content, content_type="text/html")
    except Exception as e:
        return web.Response(text=f"Fehler beim Laden der Datei: {e}", content_type='text/html')
    

# Creating http-Server
async def init():
    app = web.Application()
    app.router.add_get('/', handle_html)
    app.router.add_static('/snake-static/', os.path.join(BASE_DIR, '../snake-static'))
    return app

# Starting http-Server 
def start_http_server():
    web.run_app(init(), port=5500)
    print("HTTP server running at http://localhost:5500")

def start_ws_server():
    async def run_ws_server():
        start_server = await websockets.serve(handle_client, '0.0.0.0', 5501)
        print("WebSocket server running at ws://0.0.0.0:5501")
        await start_server.wait_closed()

    # I have to create an event loop for the websockets server, because http server is running in the main thread
    loop = asyncio.new_event_loop()
    asyncio.set_event_loop(loop)
    loop.run_until_complete(run_ws_server())


async def execute_racket_file(filepath):
    """
    Execute a Racket file using subprocess and return its output or errors.
    """
    try:
        # Run the Racket file
        process = subprocess.Popen(
            ['racket', filepath],  # Command to execute the Racket file
            stdout=subprocess.PIPE,  # Capture standard output
            stderr=subprocess.PIPE   # Capture standard error
        )

    	# Wait for server to start (Adding delay)
        await asyncio.sleep(2)

        # Verify that the racket server is running
        try:
            async with websockets.connect('ws://localhost:9092') as ws:
                await ws.close()
                print("Racket server is ready")
                return True
        except:
            print("Failed to connect to Racket server")
            return False
            
    except Exception as e:
        print(f"Error starting Racket: {e}")
        return False

def main():
    ws_thread = threading.Thread(target=start_ws_server)
    ws_thread.start()

    start_http_server()

if __name__ == "__main__":
    main()