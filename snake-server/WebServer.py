import os
import socket 
from socket import *
import sys # In order to terminate the program

serverSocket = socket(AF_INET, SOCK_STREAM)

#Verzeichnis für statische Dateien
BASE_DIR = os.path.join(os.getcwd(), '..', 'snake-static')

#Prepare a sever socket
serverSocket.bind(('0.0.0.0', 6603))
serverSocket.listen(1)

while True:
    #Establish the connection
    print('Ready to serve...')
    connectionSocket, addr = serverSocket.accept()


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

serverSocket.close()
sys.exit() #Terminate the program after sending the corresponding data

