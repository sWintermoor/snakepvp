import asyncio
import websockets
from aiohttp import web
import socket 
from socket import *
import threading
import subprocess

matchmaking_queue = []
lock = threading.Lock()

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
        player1.send("Matched! Game starting...\n".encode())
        player2.send("Matched! Game starting...\n".encode())

        # Execute Racket file for the pair
        result = execute_racket_file('../snake-racket/launch-snake-pvp-universe.rkt')

        # Send results to both players
        player1.send(f"Game Results:\n{result}".encode())
        player2.send(f"Game Results:\n{result}".encode())

    except Exception as e:
        print(f"Error in handle_client: {e}")

    finally:
        #Close the sockets
        await websocket.close()


# Handling html request
async def handle_html(request):
    try:
        with open('../snake-templates/index.html', 'r') as file:
            html_content = file.read()

        return web.Response(text=html_content, content_type="text/html")
    except Exception as e:
        return web.Response(text=f"Fehler beim Laden der Datei: {e}", content_type='text/html')
    

# Creating http-Server
async def init():
    app = web.Application()
    app.router.add_get('/', handle_html)
    return app

# Starting http-Server 
def start_http_server():
    web.run_app(init(), port=5500)
    print("HTTP server running at http://localhost:5500")

def start_ws_server():
    start_server = websockets.serve(handle_client, "localhost, 5501")
    asyncio.get_event_loop().run_until_complete(start_server)
    print("WebSocket server running at ws://localhost:5501")
    asyncio.get_event_loop().run_forever()

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