import os
import socket 
from socket import *
import threading
import subprocess

matchmaking_queue = []
lock = threading.Lock()

def handle_client(connectionSocket):
    try:
        with lock:
            matchmaking_queue.append(connectionSocket)
            print("Client added to matchmaking queue")

        # Wait until two clients are connected
        while True:
            with lock:
                if len(matchmaking_queue) >= 2:
                    # Pair the first two clients 
                    player1 = matchmaking_queue.pop(0)
                    player2 = matchmaking_queue.pop(0)
                    break

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
        connectionSocket.close()

    finally:
        #Close the sockets
        connectionSocket.close()


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
    """
    Start the server and listen for connections
    """
    serverSocket = socket(AF_INET, SOCK_STREAM) # AF_INET für IPv4 und SOCK_STREAM für TCP
    serverSocket.bind(('0.0.0.0', 9092))
    serverSocket.listen(1)

    print('Ready to serve...')

    while True:
        #Accept a new connection
        connectionSocket, addr = serverSocket.accept()
        print(f"Connection established with{addr}")

        #Starting a new thread
        client_thread = threading.Thread(target=handle_client, args=(connectionSocket,))
        client_thread.start()

if __name__ == "__main__":
    main()