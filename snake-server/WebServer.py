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

async def handle_client(websocket, path):
    try:
        with lock:
            matchmaking_queue.append(websocket)
            print("Client added to matchmaking queue")

        # Wait until two clients are connected
        while len(matchmaking_queue) < 2:
            await asyncio.sleep(0.1)

        player1 = matchmaking_queue.pop(0)
        player2 = matchmaking_queue.pop(0)
        

        # Notify both players
        player1.send(json.dumps({"message": "Matched! Game starting...\n"}))
        player2.send(json.dumps({"message": "Matched! Game starting...\n"}))

        # Execute Racket file for the pair
        racket_file_path = os.path.join(BASE_DIR, '../snake-racket/launch-snake-pvp-universe.rkt')
        result = execute_racket_file(racket_file_path)

        # Send results to both players
        player1.send(json.dumps({"game-results": result}))
        player2.send(json.dumps({"game-results": result}))

        # Continuously receive and send messages
        while True:
            message1 = await player1.recv()
            message2 = await player2.recv()

            response1 = await forward_to_racket(message1)
            response2 = await forward_to_racket(message2)

            data1 = json.loads(message1)
            data2 = json.loads(message2)

            print(f"Received data from player1: {data1}")
            print(f"Received data from player2: {data2}")

            # Example of sending a message back to the clients
            await player1.send(json.dumps(data1))
            await player2.send(json.dumps(data2)) 

    except Exception as e:
        print(f"Error in handle_client: {e}")

    finally:
        #Close the sockets
        await websocket.close()


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


def execute_racket_file(filepath):
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
        stdout, stderr = process.communicate()

        # Check for success or errors
        if process.returncode == 0:
            return stdout.decode()  # Return the program's output
        else:
            return f"Error executing Racket file:\n{stderr.decode()}"
    except FileNotFoundError:
        return "Racket interpreter not found. Ensure Racket is installed and in PATH."
    except Exception as e:
        return f"Unexpected error: {e}"


def main():
    ws_thread = threading.Thread(target=start_ws_server)
    ws_thread.start()

    start_http_server()

if __name__ == "__main__":
    main()