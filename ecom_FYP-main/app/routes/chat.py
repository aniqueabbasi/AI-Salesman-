from fastapi import APIRouter, WebSocket, WebSocketDisconnect, HTTPException
from app.services.chat_service import ChatService

router = APIRouter()

chat_service = ChatService()

# WebSocket route for customers
@router.websocket("/chat/customer/{user_id}")
async def customer_chat(websocket: WebSocket, user_id: str):
    """Handle customer chat connections"""
    try:
        await chat_service.connect_customer(websocket, user_id)
        while True:
            data = await websocket.receive_text()
            # Here, we handle messages sent by the customer to the support agents
            await chat_service.send_message_to_agent(f"Customer {user_id}: {data}")
    except WebSocketDisconnect:
        chat_service.disconnect(websocket, user_id)
        print(f"Customer {user_id} disconnected")

# WebSocket route for support agents
@router.websocket("/chat/agent")
async def agent_chat(websocket: WebSocket):
    """Handle support agent chat connections"""
    try:
        await chat_service.connect_agent(websocket)
        while True:
            data = await websocket.receive_text()
            # Here, we send the message to the appropriate customer
            await chat_service.send_message_to_customer("customer_123", f"Agent says: {data}")
    except WebSocketDisconnect:
        chat_service.disconnect(websocket)
        print("Agent disconnected")
