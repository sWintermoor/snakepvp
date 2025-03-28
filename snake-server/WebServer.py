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
players_cnt = 0       # Should prevent a double connection to the Universe server
lock = threading.Lock()

async def forward_to_universe(websocket, message):
    await websocket.send(message)
    response = await websocket.recv()
    return response
    
async def prepare_json_for_universe(id, message):
    data = json.loads(message)
    data["id"] = id
    return json.dumps(data)


async def handle_client(websocket):
    global players_cnt
    print("WebServer: Start handle_client")
    try:
        players_cnt += 1
        print(f"WebServer: New connection attempt from {websocket.remote_address}")

        with lock:
            matchmaking_queue.append(websocket)
            print(f"WebServer: Client {websocket.remote_address} added to matchmaking queue")
            print(f"WebServer: Queue size: {len(matchmaking_queue)}")

        # Send initial acknowledgment
        await websocket.send(json.dumps({"gameStatus": "waiting"})) 

        # Wait until two clients are connected
        while len(matchmaking_queue) < 2:
            await asyncio.sleep(0.1)
            # Keep connection alive
            await websocket.ping()

        if players_cnt == 1:
            return
        
        players_cnt = 0

        player1 = matchmaking_queue.pop(0)
        player2 = matchmaking_queue.pop(0)

        print(f"WebServer: Queue size: {len(matchmaking_queue)}")
        print(f"WebServer: Match found between {player1.remote_address} and {player2.remote_address}")

        # Start Universe server first
        persistent_ws1_universe, persistent_ws2_universe = await create_universe_connection(
              "C:/Users/Mark Oliver/Desktop/Projekt/SnakePvPProjekt/snakepvp/out/build/universeCMake/Debug/universe.exe"
        )

        """
        if not universe_started:
            print("Failed to start Universe")
            return
        
        else:
            print("Universe started successfully")
        """
        
        """
        print(f"Match starting between {player1.remote_address} and {player2.remote_address}")
        # Register players as worlds in Racket universe
        register_world1 = await forward_to_universe(persistent_ws1_universe, json.dumps({  
            "type": "connect",
            "player": 1}))
        
        register_world2 = await forward_to_universe(persistent_ws2_universe, json.dumps({
            "type": "connect",
            "player": 2}))

        """

        print("WebServer: Notifing players of registration and starting game")   

        # Notify players of successful registration
        await player1.send(json.dumps({"gameStatus": "connected"}))
        await player2.send(json.dumps({"gameStatus": "connected"}))

        print("WebServer: Entering while-Loop")

        # Continuously receive and send messages
        while True:
            print("WebServer: Waiting for messages from players")
            message1, message2 = await asyncio.gather(player1.recv(), player2.recv())

            # message1 = await player1.recv()

            # print("a")

            # message2 = await player2.recv()

            print(f"WebServer: Received message from player1: {message1}, type: {type(message1)}")
            print(f"WebServer: Received message from player2: {message2}, type: {type(message2)}")

            print("WebServer: Forwarding messages to Universe")
            
            print("WebServer: Forwarding messages to Universe")
            prepared_message1 = await prepare_json_for_universe(1, message1)
            prepared_message2 = await prepare_json_for_universe(2, message2)

            response1, response2 = await asyncio.gather(
                forward_to_universe(persistent_ws1_universe, prepared_message1),
                forward_to_universe(persistent_ws2_universe, prepared_message2)
            )

            data1 = json.loads(response1)
            data2 = json.loads(response2)

            print(f"WebServer: Received data from player1: {data1}")
            print(f"WebServer: Received data from player2: {data2}")

            # Example of sending a message back to the clients
            asyncio.gather(player1.send(json.dumps(data1)), player2.send(json.dumps(data2)))

    except websockets.ConnectionClosed as e:
        print(f"WebServer: Connection closed by client {websocket.remote_address}. Clean: {e.code} Reason: {e.reason}")
    except Exception as e:
        print(f"WebServer: Error handling client {websocket.remote_address}: {str(e)}")
    finally:
        if websocket in matchmaking_queue:
            matchmaking_queue.remove(websocket)
        print(f"WebServer: Client {websocket.remote_address} disconnected. Queue size: {len(matchmaking_queue)}")


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
    print("WebServer: HTTP server running at http://localhost:5500")

def start_ws_server():
    async def run_ws_server():
        start_server = await websockets.serve(handle_client, '0.0.0.0', 5501)
        print("WebServer: WebSocket server running at ws://0.0.0.0:5501")
        await start_server.wait_closed()

    # I have to create an event loop for the websockets server, because http server is running in the main thread
    loop = asyncio.new_event_loop()
    asyncio.set_event_loop(loop)
    loop.run_until_complete(run_ws_server())


async def create_universe_connection(filepath):
    """Start pre-built universe.exe"""
    try:
        if not os.path.exists(filepath):
            print(f"WebServer: Error: universe.exe not found at {filepath}")
            return False
            
        # Start the pre-built executable
        process = subprocess.Popen(
            [filepath],
            # stdout=subprocess.PIPE,
            # stderr=subprocess.PIPE
        )

        # Wait for server startup
        await asyncio.sleep(2)

        """
        # Test connection
        try:
            async with websockets.connect('ws://localhost:9092') as ws:
                # await ws.close()
                print("Universe server is ready")
                return True
        except:
            print("Failed to connect to Universe")
            return False
        """

        persistent_ws1_universe = None
        persistent_ws2_universe = None

        try:
            persistent_ws1_universe, persistent_ws2_universe = await asyncio.gather(
                websockets.connect('ws://localhost:9092'),
                websockets.connect('ws://localhost:9092')
            )

            print("WebServer: Persistent connections to Universe established")

        except Exception as e:
            print(f"WebServer: Error establishing persistent connection: {e}")

        return persistent_ws1_universe, persistent_ws2_universe
            
    except Exception as e:
        print(f"WebServer: Error starting Universe: {e}")
        return False

def main():
    ws_thread = threading.Thread(target=start_ws_server)
    ws_thread.start()

    start_http_server()

if __name__ == "__main__":
    main()