import os
import socket 
from socket import *
import threading
import subprocess
import sys # In order to terminate the program

# def handleClient(connectionSocket):
    
def main():
    serverSocket = socket(AF_INET, SOCK_STREAM) # AF_INET für IPv4 und SOCK_STREAM für TCP

    #Verzeichnis für statische Dateien
    BASE_DIR = os.path.join(os.getcwd(), '..', 'snake-static')

    #Prepare a sever socket
    serverSocket.bind(('0.0.0.0', 6603))
    serverSocket.listen(1)

    print('Ready to serve...')

    while True:
        #Accept a new connection
        connectionSocket, addr = serverSocket.accept()
        print(f"Connection established with{addr}")

        #Starting a new thread
        client_thread = threading.Thread(target=handle_client, args=(connectionSocket,))
        client_thread.start()

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

def handle_client(connectionSocket):
    try:
        #Empfange die Nachricht (also den Dateinamen)
        message = connectionSocket.recv(1024).decode()
        filename = message.split()[1]

        # Handle unterschiedliche Dateitypen
        if filename == '/':
            filename = '/templates/index.html'  # Standardseite ist index.html
        if filename.endswith('.css'):
            content_type = 'text/css'
        elif filename.endswith('.html'):
            content_type = 'text/html'
        elif filename.endswith('.js'):
            content_type = 'application/javascript'
        else:
            content_type = 'text/html'
    
        filepath = os.path.join(os.getcwd(), '..', filename[1:])

        try:
            with open(filepath, 'r') as f:
                outputdata = f.read()
        
            #Sende Header und Dateiinhalte
            connectionSocket.send(f"HTTP/1.1 200 OK\r\nContent-Type: {content_type}\r\n\r\n".encode())
            connectionSocket.send(outputdata.encode())
        
        except IOError:
            #Send response message for file not found
            connectionSocket.send("HTTP/1.1 404 Not Found\r\n".encode())
            connectionSocket.send("<html><body><h1>404 Not Found</h1></body></html>".encode())
            
            #Close client socket
            connectionSocket.close()

    except Exception as e:
        print(f"Error occured: {e}")
        connectionSocket.close()

