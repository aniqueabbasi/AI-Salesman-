import firebase_admin
from firebase_admin import messaging, credentials
import os
import logging

# Set up logging
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

# Flag to track if Firebase is initialized
firebase_initialized = False

try:
    cred_path = os.path.join(os.path.dirname(__file__), '../../ecom-50c5e-firebase-adminsdk-9ekxv-b995f3b3d9.json')
    cred = credentials.Certificate(cred_path)
    firebase_admin.initialize_app(cred)
    firebase_initialized = True
    logger.info("Firebase initialized successfully")
except Exception as e:
    logger.error(f"Firebase initialization failed: {str(e)}")
    logger.warning("Push notifications will not be sent. Please provide a valid Firebase service account key.")

 
def send_push_notification(token, title, body):
    if not firebase_initialized:
        logger.warning(f"Push notification not sent: {title} - {body}")
        return {"error": "Firebase not initialized", "success": False}
    
    try:
        message = messaging.Message(
            notification=messaging.Notification(
                title=title,
                body=body
            ),
            token=token,
        )
        response = messaging.send(message)
        return {"message_id": response, "success": True}
    except Exception as e:
        logger.error(f"Failed to send push notification: {str(e)}")
        return {"error": str(e), "success": False}
