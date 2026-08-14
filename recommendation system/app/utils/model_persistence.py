import os
import pickle
import logging
import pandas as pd
from typing import Optional, Tuple, List
from pathlib import Path

logger = logging.getLogger(__name__)

class ModelPersistence:
    """Utility class for saving and loading trained recommendation models"""
    
    def __init__(self, model_dir: str = "models"):
        self.model_dir = Path(model_dir)
        self.model_dir.mkdir(exist_ok=True)
        self.model_file = self.model_dir / "recommendation_model.pkl"
        self.metadata_file = self.model_dir / "model_metadata.txt"
    
    def save_model(
        self, 
        rules_df: pd.DataFrame, 
        one_hot_encoded_df: pd.DataFrame, 
        feature_names: List[str],
        products_cache: dict,
        training_params: dict
    ) -> bool:
        """Save the trained model to disk"""
        try:
            model_data = {
                'rules_df': rules_df,
                'one_hot_encoded_df': one_hot_encoded_df,
                'feature_names': feature_names,
                'products_cache': products_cache,
                'training_params': training_params
            }
            
            with open(self.model_file, 'wb') as f:
                pickle.dump(model_data, f)
            
            # Save metadata for quick reference
            metadata = f"""Model Training Parameters:
- Min Support: {training_params.get('min_support', 'N/A')}
- Min Confidence: {training_params.get('min_confidence', 'N/A')}
- Min Lift: {training_params.get('min_lift', 'N/A')}
- Number of Rules: {len(rules_df) if rules_df is not None else 0}
- Number of Features: {len(feature_names)}
- Number of Products: {len(products_cache)}
- Model File: {self.model_file}
"""
            
            with open(self.metadata_file, 'w') as f:
                f.write(metadata)
            
            logger.info(f"Model saved successfully to {self.model_file}")
            return True
            
        except Exception as e:
            logger.error(f"Error saving model: {str(e)}")
            return False
    
    def load_model(self) -> Optional[Tuple[pd.DataFrame, pd.DataFrame, List[str], dict, dict]]:
        """Load the trained model from disk"""
        try:
            if not self.model_file.exists():
                logger.info("No saved model found")
                return None
            
            with open(self.model_file, 'rb') as f:
                model_data = pickle.load(f)
            
            rules_df = model_data.get('rules_df')
            one_hot_encoded_df = model_data.get('one_hot_encoded_df')
            feature_names = model_data.get('feature_names', [])
            products_cache = model_data.get('products_cache', {})
            training_params = model_data.get('training_params', {})
            
            logger.info(f"Model loaded successfully from {self.model_file}")
            logger.info(f"Loaded {len(rules_df) if rules_df is not None else 0} rules with {len(feature_names)} features")
            
            return rules_df, one_hot_encoded_df, feature_names, products_cache, training_params
            
        except Exception as e:
            logger.error(f"Error loading model: {str(e)}")
            return None
    
    def model_exists(self) -> bool:
        """Check if a saved model exists"""
        return self.model_file.exists()
    
    def get_model_info(self) -> Optional[dict]:
        """Get information about the saved model"""
        try:
            if not self.model_file.exists():
                return None
            
            with open(self.model_file, 'rb') as f:
                model_data = pickle.load(f)
            
            rules_df = model_data.get('rules_df')
            feature_names = model_data.get('feature_names', [])
            training_params = model_data.get('training_params', {})
            
            return {
                'rules_count': len(rules_df) if rules_df is not None else 0,
                'features_count': len(feature_names),
                'training_params': training_params,
                'model_file': str(self.model_file),
                'last_modified': os.path.getmtime(self.model_file)
            }
            
        except Exception as e:
            logger.error(f"Error getting model info: {str(e)}")
            return None
    
    def delete_model(self) -> bool:
        """Delete the saved model"""
        try:
            if self.model_file.exists():
                self.model_file.unlink()
                logger.info(f"Model file deleted: {self.model_file}")
            
            if self.metadata_file.exists():
                self.metadata_file.unlink()
                logger.info(f"Metadata file deleted: {self.metadata_file}")
            
            return True
            
        except Exception as e:
            logger.error(f"Error deleting model: {str(e)}")
            return False 