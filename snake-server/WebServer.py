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

async def forward_to_universe(message):
    uri = "ws://localhost:9092"
    async with websockets.connect(uri) as websocket:
        await websocket.send(message)
        response = await websocket.recv()
        return response
    
async def prepare_json_for_universe(id, message):
    data = json.loads(message)
    data["id"] = id
    return json.dumps(data)


async def handle_client(websocket):
    try:
        print(f"New connection attempt from {websocket.remote_address}")

        with lock:
            matchmaking_queue.append(websocket)
            print(f"Client {websocket.remote_address} added to matchmaking queue")
            print(f"Queue size: {len(matchmaking_queue)}")

        # Send initial acknowledgment
        await websocket.send(json.dumps({"gameStatus": "waiting"})) 

        # Wait until two clients are connected
        while len(matchmaking_queue) < 2:
            await asyncio.sleep(0.1)
            # Keep connection alive
            await websocket.ping()

        player1 = matchmaking_queue.pop(0)
        player2 = matchmaking_queue.pop(0)

        # Start Racket server first
        universe_started = await execute_universe(
            os.path.join(BASE_DIR, 'universe.cpp')
        )

        if not universe_started:
            print("Failed to start Universe")
            return
        
        print(f"Match found between {player1.remote_address} and {player2.remote_address}")
        # Register players as worlds in Racket universe
        register_world1 = await forward_to_universe(json.dumps({  
            "type": "connect",
            "player": 1}))
        
        register_world2 = await forward_to_universe(json.dumps({
            "type": "connect",
            "player": 2}))

        print("Notified Racket of player registration")   

        # Notify players of successful registration
        await player1.send(json.dumps({"gameStatus": "connected"}))
        await player2.send(json.dumps({"gameStatus": "connected"}))

        print("Entering while-Loop")

        # Continuously receive and send messages
        while True:
            message1 = await player1.recv()   
            message2 = await player2.recv()

            response1 = await forward_to_universe(prepare_json_for_universe(1, message1))
            response2 = await forward_to_universe(prepare_json_for_universe(2, message2))

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


async def execute_universe(filepath):
    """
    Execute a Universe using subprocess and return its output or errors.
    """
    try:
        # Debug print absolute path
        abs_path = os.path.abspath(filepath)
        print(f"Looking for file at: {abs_path}")

        # Check if file exists
        if not os.path.exists(abs_path):
            print(f"Error: File not found at {abs_path}")
            return False

        # Add VS Developer Command Prompt path
        vs_path = r"C:/Program Files/Microsoft Visual Studio/2022/Community/VC/Auxiliary/Build"
        os.environ['PATH'] = vs_path + os.pathsep + os.environ['PATH']

        ## Run vcvars64.bat first
        subprocess.run(
            [os.path.join(vs_path, 'vcvars64.bat')],
            shell=True
        )

        # Compile with full path to cl.exe
        cl_path = r"C:/Program Files/Microsoft Visual Studio/2022/Community/VC/Tools/MSVC/14.38.33130\bin/Hostx64/x64/cl.exe"
        compile_process = subprocess.run(
            [cl_path, '/EHsc', abs_path],
            capture_output=True,
            encoding='cp1252',
            errors='replace',
            #text=True
        )

        # Log compilation output
        print("Compiler output:", compile_process.stdout)
        print("Compiler errors:", compile_process.stderr)

        if compile_process.returncode != 0:
            print(f"Error compiling C++ file: {compile_process}")
            return False
        
        # Get executable name (remove .cpp and add .exe)
        exe_path = filepath.replace('.cpp', '.exe')

        # Run the Racket file
        process = subprocess.Popen(
            [exe_path],  # Command to execute the compiled file
            stdout=subprocess.PIPE,  # Capture standard output
            stderr=subprocess.PIPE   # Capture standard error
        )

    	# Wait for server to start (Adding delay)
        await asyncio.sleep(2)

        # Verify that the racket server is running
        try:
            async with websockets.connect('ws://localhost:9092') as ws:
                await ws.close()
                print("Universe server is ready")
                return True
        except:
            print("Failed to connect to Universe")
            return False
            
    except Exception as e:
        print(f"Error starting Universe: {e}")
        return False

def main():
    ws_thread = threading.Thread(target=start_ws_server)
    ws_thread.start()

    start_http_server()

if __name__ == "__main__":
    main()