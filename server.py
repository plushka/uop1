# server.py
import socket

server_ip = "192.168.50.1"
server_port = 8080

server = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
server.bind((server_ip, server_port))
server.listen(1)

print(f"Server listening on {server_ip}:{server_port}")
while True:
    client_socket, client_address = server.accept()
    print(f"Connection from {client_address}")
    client_socket.send(b"Hello from server!\n")
    client_socket.close()
