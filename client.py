# client.py
import socket

server_ip = "192.168.50.1"
server_port = 8080

client = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
client.connect((server_ip, server_port))

# Receive data from server
data = client.recv(1024)
print(f"Received from server: {data.decode()}")

client.close()
