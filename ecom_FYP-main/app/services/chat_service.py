from typing import List
from fastapi import WebSocket
from collections import defaultdict

class ChatService:
    def __init__(self):
        self.active_connections: defaultdict = defaultdict(list)  # To store connections by user_id
        self.agent_connections: List[WebSocket] = []  # To store agent connections

    async def connect_customer(self, websocket: WebSocket, user_id: str):
        """Connect a customer to a WebSocket channel"""
        await websocket.accept()
        self.active_connections[user_id].append(websocket)

    async def connect_agent(self, websocket: WebSocket):
        """Connect an agent to a WebSocket channel"""
        await websocket.accept()
        self.agent_connections.append(websocket)

    async def disconnect(self, websocket: WebSocket, user_id: str = None):
        """Disconnect the user/agent"""
        if user_id:
            self.active_connections[user_id].remove(websocket)
        else:
            self.agent_connections.remove(websocket)

    async def send_message(self, user_id: str, message: str):
        """Send message to the customer via WebSocket"""
        for connection in self.active_connections.get(user_id, []):
            await connection.send_text(message)

    async def send_message_to_agent(self, message: str):
        """Send a message to all connected agents"""
        for agent in self.agent_connections:
            await agent.send_text(message)

    async def send_message_to_customer(self, customer_id: str, message: str):
        """Send a message from agent to customer"""
        if customer_id in self.active_connections:
            await self.send_message(customer_id, message)
