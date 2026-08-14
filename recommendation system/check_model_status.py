#!/usr/bin/env python3
"""
Simple script to check the status of the recommendation model.
This script helps users understand if the model is trained and ready for use.
"""

import requests
import json
import sys

def check_model_status(base_url="http://localhost:8002"):
    """Check the status of the recommendation model"""
    try:
        # Check if the server is running
        response = requests.get(f"{base_url}/", timeout=5)
        if response.status_code != 200:
            print(f"❌ Server is not responding at {base_url}")
            return False
        
        server_info = response.json()
        print(f"✅ Server is running at {base_url}")
        print(f"📊 Model status: {server_info.get('model_status', 'unknown')}")
        
        # Check detailed model status
        status_response = requests.get(f"{base_url}/api/model/status", timeout=5)
        if status_response.status_code == 200:
            status_data = status_response.json()
            
            if status_data['status'] == 'trained':
                print("🎉 Model is trained and ready for recommendations!")
                model_info = status_data['model_info']
                print(f"   📈 Rules: {model_info['rules_count']}")
                print(f"   🔧 Features: {model_info['features_count']}")
                print(f"   🛍️  Products cached: {model_info['products_cache_size']}")
                print(f"   💾 Loaded from disk: {model_info['model_loaded_from_disk']}")
                return True
            else:
                print("⚠️  Model is not trained yet.")
                print("   To train the model, run:")
                print(f"   curl -X POST \"{base_url}/api/train\" -H \"accept: application/json\"")
                return False
        else:
            print(f"❌ Error checking model status: {status_response.status_code}")
            return False
            
    except requests.exceptions.ConnectionError:
        print(f"❌ Cannot connect to server at {base_url}")
        print("   Make sure the server is running with: python run.py")
        return False
    except Exception as e:
        print(f"❌ Error: {str(e)}")
        return False

def main():
    """Main function"""
    print("🔍 Checking Recommendation Model Status")
    print("=" * 50)
    
    # Check model status
    is_ready = check_model_status()
    
    print("\n" + "=" * 50)
    if is_ready:
        print("✅ Your recommendation system is ready to use!")
        print("\n📝 Available endpoints:")
        print("   • GET  /api/model/status     - Check model status")
        print("   • POST /api/train            - Train the model")
        print("   • POST /api/recommend        - Get recommendations")
        print("   • GET  /api/rules            - Get association rules")
    else:
        print("❌ Your recommendation system needs setup.")
        print("\n🚀 Next steps:")
        print("   1. Make sure the server is running: python run.py")
        print("   2. Train the model: curl -X POST \"http://localhost:8002/api/train\"")
        print("   3. Check status again: python check_model_status.py")

if __name__ == "__main__":
    main() 