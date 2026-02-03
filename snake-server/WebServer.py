import asyncio
import websockets
import json
from aiohttp import web
import os
from socket import *
import threading
import subprocess
from dotenv import load_dotenv

load_dotenv()

SHOW_COMMENTS = False

BASE_DIR = os.path.dirname(os.path.abspath(__file__))

matchmaking_queue = []
players_cnt = 0       # Should prevent a double connection to the Universe server
lock = threading.Lock()

async def forward_to_universe(websocket, message):
    if not isinstance(message, str):
        message = json.dumps(message)
    if SHOW_COMMENTS: print(f"WebServer: Sending message to universe: {message}, type: {type(message)}")
    await websocket.send(message)
    
async def prepare_json_for_universe(id, message):
    data = json.loads(message)
    data["id"] = id
    return json.dumps(data)


async def handle_client(websocket):
    global players_cnt
    if SHOW_COMMENTS: print("WebServer: Start handle_client")
    try:
        players_cnt += 1
        if SHOW_COMMENTS: print(f"WebServer: New connection attempt from {websocket.remote_address}")

        with lock:
            matchmaking_queue.append(websocket)
            if SHOW_COMMENTS: print(f"WebServer: Client {websocket.remote_address} added to matchmaking queue")
            if SHOW_COMMENTS: print(f"WebServer: Queue size: {len(matchmaking_queue)}")

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

        if SHOW_COMMENTS: print(f"WebServer: Queue size: {len(matchmaking_queue)}")
        if SHOW_COMMENTS: print(f"WebServer: Match found between {player1.remote_address} and {player2.remote_address}")

        # Start Universe server first
        persistent_ws1_universe, persistent_ws2_universe = await create_universe_connection(
              os.getenv("UNIVERSE_PATH")
        )

        if SHOW_COMMENTS: print("WebServer: Notifing players of registration and starting game")   

        # Notify players of successful registration
        await player1.send(json.dumps({"gameStatus": "connected"}))
        await player2.send(json.dumps({"gameStatus": "connected"}))

        # Creating tasks for receiving messages from players.

        message_queue1_client = asyncio.Queue()
        message_queue2_client = asyncio.Queue()

        async def receive_messages_client(client, queue, client_id):
            while True:
                try:
                    message = await client.recv()
                    await queue.put(message)
                except websockets.ConnectionClosed:
                    if SHOW_COMMENTS: print(f"WebServer: Connection closed by client {client_id}")
                    break
        
        receive_task1_client = asyncio.create_task(receive_messages_client(player1, message_queue1_client, "1"))
        receive_task2_client = asyncio.create_task(receive_messages_client(player2, message_queue2_client, "2"))

        # Creating tasks for receiving messages from Universe server.

        message_queue1_universe = asyncio.Queue()
        message_queue2_universe = asyncio.Queue()

        async def receive_messages_universe(websocket, queue, websocket_id):
            while True:
                try:
                    message = await websocket.recv()
                    await queue.put(message)
                except websockets.ConnectionClosed:
                    if SHOW_COMMENTS: print(f"WebServer: Connection closed by Universe {websocket_id}")
                    break

        receive_task1_universe = asyncio.create_task(receive_messages_universe(persistent_ws1_universe, message_queue1_universe, "1"))
        receive_task2_universe = asyncio.create_task(receive_messages_universe(persistent_ws2_universe, message_queue2_universe, "2"))

        if SHOW_COMMENTS: print("WebServer: Entering while-Loop")

        # Continuously receive and send messages
        while True:
            try:
                if SHOW_COMMENTS: print("WebServer: Waiting for messages from players")
                
                messageFromClient1 = None
                messageFromClient2 = None

                messageFromUniverse1 = None
                messageFromUniverse2 = None

                dataToClient1 = None	
                dataToClient2 = None

                try:
                    messageFromClient1 = message_queue1_client.get_nowait()
                except asyncio.QueueEmpty:
                    pass

                try:
                    messageFromClient2 = message_queue2_client.get_nowait()
                except asyncio.QueueEmpty:
                    pass

                if messageFromClient1 or messageFromClient2:
                    # Process available messages
                    if messageFromClient1:
                        if SHOW_COMMENTS: print(f"WebServer: Received message from player1: {messageFromClient1}, type: {type(messageFromClient1)}") 
                        if SHOW_COMMENTS: print("WebServer: Forwarding message 1 to Universe")
                        preparedMessageFromClient1 = await prepare_json_for_universe(1, messageFromClient1)
                        await forward_to_universe(persistent_ws1_universe, preparedMessageFromClient1)
                    
                    if messageFromClient2:
                        if SHOW_COMMENTS: print(f"WebServer: Received message from player2: {messageFromClient2}, type: {type(messageFromClient2)}")
                        if SHOW_COMMENTS: print("WebServer: Forwarding message 2 to Universe")
                        preparedMessageFromClient2 = await prepare_json_for_universe(2, messageFromClient2)
                        await forward_to_universe(persistent_ws2_universe, preparedMessageFromClient2)

                await asyncio.sleep(0.001)

                try:
                    messageFromUniverse1 = message_queue1_universe.get_nowait()
                except asyncio.QueueEmpty:
                    pass

                try:
                    messageFromUniverse2 = message_queue2_universe.get_nowait()
                except asyncio.QueueEmpty:
                    pass

                if messageFromUniverse1 or messageFromUniverse2:
                    # Process available messages from Universe
                    if messageFromUniverse1:
                        if SHOW_COMMENTS: print(f"WebServer: Received message from Universe1: {messageFromUniverse1}, type: {type(messageFromUniverse1)}")
                        dataToClient1 = json.loads(messageFromUniverse1)
                        if SHOW_COMMENTS: print(f"WebServer: Received data from player1: {dataToClient1}")

                    if messageFromUniverse2:
                        if SHOW_COMMENTS: print(f"WebServer: Received message from Universe2: {messageFromUniverse2}, type: {type(messageFromUniverse2)}")
                        dataToClient2 = json.loads(messageFromUniverse2)
                        if SHOW_COMMENTS: print(f"WebServer: Received data from player2: {dataToClient2}")

                await asyncio.sleep(0.001)

                # Example of sending a message back to the clients
                if SHOW_COMMENTS: print("WebServer: Sending data to players")
                await asyncio.gather(
                        player1.send(json.dumps(dataToClient1 if messageFromUniverse1 else {"gameStatus": "no_update"})),
                        player2.send(json.dumps(dataToClient2 if messageFromUniverse2 else {"gameStatus": "no_update"}))
                    )
                
                # Small delay to prevent busy-waiting
                await asyncio.sleep(0.001)

            except Exception as e:
                if SHOW_COMMENTS: print(f"WebServer: Error in event loop: {e}")
                break

    except websockets.ConnectionClosed as e:
        if SHOW_COMMENTS: print(f"WebServer: Connection closed by client {websocket.remote_address}. Clean: {e.code} Reason: {e.reason}")
    except Exception as e:
        if SHOW_COMMENTS: print(f"WebServer: Error handling client {websocket.remote_address}: {str(e)}")
    finally:
        if websocket in matchmaking_queue:
            matchmaking_queue.remove(websocket)
        if SHOW_COMMENTS: print(f"WebServer: Client {websocket.remote_address} disconnected. Queue size: {len(matchmaking_queue)}")


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
    if SHOW_COMMENTS: print("WebServer: HTTP server running at http://localhost:5500")

def start_ws_server():
    async def run_ws_server():
        start_server = await websockets.serve(handle_client, '0.0.0.0', 5501)
        if SHOW_COMMENTS: print("WebServer: WebSocket server running at ws://0.0.0.0:5501")
        await start_server.wait_closed()

    # I have to create an event loop for the websockets server, because http server is running in the main thread
    loop = asyncio.new_event_loop()
    asyncio.set_event_loop(loop)
    loop.run_until_complete(run_ws_server())


async def create_universe_connection(filepath):
    """Start pre-built universe.exe"""
    try:
        if not os.path.exists(filepath):
            if SHOW_COMMENTS: print(f"WebServer: Error: universe.exe not found at {filepath}")
            return False
            
        # Start the pre-built executable
        process = subprocess.Popen(
            [filepath],
            # stdout=subprocess.PIPE,
            # stderr=subprocess.PIPE
        )

        # Wait for server startup
        await asyncio.sleep(2)

        persistent_ws1_universe = None
        persistent_ws2_universe = None

        try:
            persistent_ws1_universe, persistent_ws2_universe = await asyncio.gather(
                websockets.connect('ws://localhost:9092'),
                websockets.connect('ws://localhost:9092')
            )

            if SHOW_COMMENTS: print("WebServer: Persistent connections to Universe established")

        except Exception as e:
            if SHOW_COMMENTS: print(f"WebServer: Error establishing persistent connection: {e}")

        return persistent_ws1_universe, persistent_ws2_universe
            
    except Exception as e:
        if SHOW_COMMENTS: print(f"WebServer: Error starting Universe: {e}")
        return False

def main():
    ws_thread = threading.Thread(target=start_ws_server)
    ws_thread.start()

    start_http_server()

if __name__ == "__main__":
    main()