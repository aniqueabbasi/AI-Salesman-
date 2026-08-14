// API base URL
const API_BASE_URL = 'http://localhost:8000/api';

document.addEventListener('DOMContentLoaded', function() {
    // Add event listeners
    document.getElementById('trainForm').addEventListener('submit', handleTrainSubmit);
    document.getElementById('recommendForm').addEventListener('submit', handleRecommendSubmit);
    document.getElementById('rulesForm').addEventListener('submit', handleRulesSubmit);
    document.getElementById('addAttribute').addEventListener('click', addAttributeRow);
    document.getElementById('refreshStatus').addEventListener('click', checkModelStatus);
    
    // Add event listener for initial attribute row's remove button
    document.querySelector('.remove-attribute').addEventListener('click', function() {
        if (document.querySelectorAll('.attribute-row').length > 1) {
            this.closest('.attribute-row').remove();
        } else {
            alert('At least one attribute is required.');
        }
    });

    // Display connection status and check model status
    checkApiConnection();
    checkModelStatus();
});

// Check if API is available
async function checkApiConnection() {
    try {
        const response = await fetch(`${API_BASE_URL.replace('/api', '')}/`);
        if (response.ok) {
            console.log('API connection successful');
        } else {
            showApiConnectionError();
        }
    } catch (error) {
        showApiConnectionError();
    }
}

function showApiConnectionError() {
    const alertDiv = document.createElement('div');
    alertDiv.className = 'alert alert-danger';
    alertDiv.role = 'alert';
    alertDiv.innerHTML = `
        <h4 class="alert-heading">API Connection Error</h4>
        <p>Unable to connect to the API server at ${API_BASE_URL}.</p>
        <hr>
        <p class="mb-0">Please make sure the backend server is running at http://localhost:8000.</p>
    `;
    
    document.querySelector('.container').prepend(alertDiv);
}

// Check model status
async function checkModelStatus() {
    const statusContainer = document.getElementById('modelStatusContainer');
    const spinner = document.getElementById('statusSpinner');
    
    try {
        spinner.style.display = 'inline-block';
        statusContainer.innerHTML = `
            <div class="d-flex align-items-center">
                <div class="spinner-border spinner-border-sm me-2" role="status" id="statusSpinner">
                    <span class="visually-hidden">Loading...</span>
                </div>
                <span>Checking model status...</span>
            </div>
        `;
        
        const response = await fetch(`${API_BASE_URL}/model/status`);
        const data = await response.json();
        
        if (response.ok) {
            if (data.status === 'trained') {
                const modelInfo = data.model_info;
                statusContainer.innerHTML = `
                    <div class="alert alert-success">
                        <h5 class="alert-heading">✅ Model is trained and ready!</h5>
                        <p class="mb-1">Your recommendation model is loaded and ready for use.</p>
                        <hr>
                        <div class="row">
                            <div class="col-md-3">
                                <strong>Rules:</strong> ${modelInfo.rules_count}
                            </div>
                            <div class="col-md-3">
                                <strong>Features:</strong> ${modelInfo.features_count}
                            </div>
                            <div class="col-md-3">
                                <strong>Products:</strong> ${modelInfo.products_cache_size}
                            </div>
                            <div class="col-md-3">
                                <strong>Source:</strong> ${modelInfo.model_loaded_from_disk ? 'Disk' : 'Memory'}
                            </div>
                        </div>
                    </div>
                `;
            } else {
                statusContainer.innerHTML = `
                    <div class="alert alert-warning">
                        <h5 class="alert-heading">⚠️ Model needs training</h5>
                        <p class="mb-0">The recommendation model has not been trained yet. Use the "Train Model" section below to train it.</p>
                    </div>
                `;
            }
        } else {
            statusContainer.innerHTML = `
                <div class="alert alert-danger">
                    <h5 class="alert-heading">❌ Error checking model status</h5>
                    <p class="mb-0">${data.detail || 'Unknown error occurred'}</p>
                </div>
            `;
        }
    } catch (error) {
        statusContainer.innerHTML = `
            <div class="alert alert-danger">
                <h5 class="alert-heading">❌ Connection Error</h5>
                <p class="mb-0">Failed to connect to the API server. Make sure the backend is running.</p>
            </div>
        `;
    } finally {
        spinner.style.display = 'none';
    }
}

// Handle training form submission
async function handleTrainSubmit(event) {
    event.preventDefault();
    
    const minSupport = document.getElementById('minSupport').value;
    const minConfidence = document.getElementById('minConfidence').value;
    const minLift = document.getElementById('minLift').value;
    
    const trainingStatus = document.getElementById('trainingStatus');
    trainingStatus.style.display = 'block';
    trainingStatus.textContent = 'Training in progress...';
    trainingStatus.className = 'alert alert-info';
    
    try {
        const response = await fetch(`${API_BASE_URL}/train?min_support=${minSupport}&min_confidence=${minConfidence}&min_lift=${minLift}`, {
            method: 'POST'
        });
        
        const data = await response.json();
        
        if (response.ok) {
            trainingStatus.textContent = `Training successful! Generated ${data.length} rules.`;
            trainingStatus.className = 'alert alert-success';
            // Refresh model status after successful training
            setTimeout(() => checkModelStatus(), 1000);
        } else {
            trainingStatus.textContent = `Error: ${data.detail || JSON.stringify(data) || 'Unknown error'}`;
            trainingStatus.className = 'alert alert-danger';
        }
    } catch (error) {
        trainingStatus.textContent = `Error: ${error.message || 'Failed to connect to API. Make sure the backend server is running.'}`;
        trainingStatus.className = 'alert alert-danger';
    }
}

// Handle recommendation form submission
async function handleRecommendSubmit(event) {
    event.preventDefault();
    
    const attributes = [];
    const attributeRows = document.querySelectorAll('.attribute-row');
    
    attributeRows.forEach(row => {
        const attributeType = row.querySelector('.attribute-type').value;
        const attributeValue = row.querySelector('.attribute-value').value;
        
        if (attributeValue.trim() !== '') {
            attributes.push({
                attribute_type: attributeType,
                attribute_value: attributeValue
            });
        }
    });
    
    if (attributes.length === 0) {
        alert('Please add at least one attribute with a value.');
        return;
    }
    
    const minConfidence = document.getElementById('recMinConfidence').value;
    const minLift = document.getElementById('recMinLift').value;
    const maxResults = document.getElementById('maxResults').value;
    
    const requestBody = {
        attributes: attributes,
        min_confidence: parseFloat(minConfidence),
        min_lift: parseFloat(minLift),
        max_results: parseInt(maxResults),
        include_products: true
    };
    
    const recommendationsContainer = document.getElementById('recommendationsContainer');
    recommendationsContainer.innerHTML = '<div class="alert alert-info">Loading recommendations...</div>';
    
    try {
        const response = await fetch(`${API_BASE_URL}/recommend`, {
            method: 'POST',
            headers: {
                'Content-Type': 'application/json'
            },
            body: JSON.stringify(requestBody)
        });
        
        const data = await response.json();
        
        if (response.ok) {
            displayRecommendations(data.recommendations);
        } else {
            recommendationsContainer.innerHTML = `<div class="alert alert-danger">Error: ${data.detail || JSON.stringify(data) || 'Unknown error'}</div>`;
        }
    } catch (error) {
        recommendationsContainer.innerHTML = `<div class="alert alert-danger">Error: ${error.message || 'Failed to connect to API. Make sure the backend server is running.'}</div>`;
    }
}

// Handle rules form submission
async function handleRulesSubmit(event) {
    event.preventDefault();
    
    const minConfidence = document.getElementById('rulesMinConfidence').value;
    const minLift = document.getElementById('rulesMinLift').value;
    const antecedentContains = document.getElementById('antecedentContains').value;
    
    let url = `${API_BASE_URL}/rules?min_confidence=${minConfidence}&min_lift=${minLift}`;
    
    if (antecedentContains.trim() !== '') {
        url += `&antecedent_contains=${encodeURIComponent(antecedentContains)}`;
    }
    
    const rulesContainer = document.getElementById('rulesContainer');
    rulesContainer.innerHTML = '<div class="alert alert-info">Loading rules...</div>';
    
    try {
        const response = await fetch(url);
        const data = await response.json();
        
        if (response.ok) {
            displayRules(data);
        } else {
            rulesContainer.innerHTML = `<div class="alert alert-danger">Error: ${data.detail || JSON.stringify(data) || 'Unknown error'}</div>`;
        }
    } catch (error) {
        rulesContainer.innerHTML = `<div class="alert alert-danger">Error: ${error.message || 'Failed to connect to API. Make sure the backend server is running.'}</div>`;
    }
}

// Add a new attribute row
function addAttributeRow() {
    const attributesContainer = document.getElementById('attributesContainer');
    const newRow = document.createElement('div');
    newRow.className = 'row mb-2 attribute-row';
    
    newRow.innerHTML = `
        <div class="col-md-5">
            <select class="form-select attribute-type">
                <option value="brand">Brand</option>
                <option value="category">Category</option>
                <option value="sub_category">Sub Category</option>
                <option value="Color">Color</option>
                <option value="Pattern">Pattern</option>
                <option value="Fabric">Fabric</option>
            </select>
        </div>
        <div class="col-md-5">
            <input type="text" class="form-control attribute-value" placeholder="Value">
        </div>
        <div class="col-md-2">
            <button type="button" class="btn btn-danger remove-attribute">Remove</button>
        </div>
    `;
    
    attributesContainer.appendChild(newRow);
    
    // Add event listener for the new remove button
    newRow.querySelector('.remove-attribute').addEventListener('click', function() {
        this.closest('.attribute-row').remove();
    });
}

// Display recommendations
function displayRecommendations(recommendations) {
    const container = document.getElementById('recommendationsContainer');
    
    if (!recommendations || recommendations.length === 0) {
        container.innerHTML = '<p class="text-muted">No recommendations found for the given attributes.</p>';
        return;
    }
    
    let html = '';
    
    recommendations.forEach(rec => {
        if (!rec.recommended_attributes || rec.recommended_attributes.length === 0) {
            return;
        }
        
        const attributes = rec.recommended_attributes.map(attr => 
            `<span class="recommendation-attribute">${attr.attribute_type}: ${attr.attribute_value}</span>`
        ).join(', ');
        
        // Create recommendation item
        let recommendationHtml = `
            <div class="recommendation-item">
                <div>${attributes}</div>
                <div class="recommendation-metrics">
                    <span class="metric">Confidence: ${(rec.confidence * 100).toFixed(2)}%</span>
                    <span class="metric">Lift: ${rec.lift.toFixed(2)}</span>
                    <span class="metric">Support: ${(rec.support * 100).toFixed(2)}%</span>
                </div>
        `;
        
        // Add matching products if available
        if (rec.matching_products && rec.matching_products.length > 0) {
            recommendationHtml += `
                <div class="matching-products mt-3">
                    <h6>Matching Products:</h6>
                    <div class="row">
            `;
            
            rec.matching_products.forEach(product => {
                // Choose the best image source
                let imageUrl = '';
                
                // First try images array
                if (product.images && product.images.length > 0) {
                    imageUrl = product.images[0];
                } 
                // Then try image_url
                else if (product.image_url) {
                    imageUrl = product.image_url;
                }
                
                // Always use the image proxy endpoint on port 8002
                if (imageUrl) {
                    imageUrl = `http://localhost:8002/api/image-proxy?url=${encodeURIComponent(imageUrl)}`;
                }
                
                // Fallback image
                const fallbackImage = `https://placehold.co/300x400/eee/999?text=${encodeURIComponent(product.title.substring(0, 20))}`;
                
                recommendationHtml += `
                    <div class="col-md-4 mb-3">
                        <div class="card h-100">
                            ${imageUrl ? 
                                `<img src="${imageUrl}" class="card-img-top product-image" alt="${product.title}" onerror="this.onerror=null; this.src='${fallbackImage}';">` : 
                                `<div class="no-image">No Image</div>`
                            }
                            <div class="card-body">
                                <h6 class="card-title">${product.title}</h6>
                                <p class="card-text">
                                    <small>Brand: ${product.brand}</small><br>
                                    <small>Category: ${product.category}</small><br>
                                    <small>Sub-category: ${product.sub_category}</small>
                                </p>
                            </div>
                        </div>
                    </div>
                `;
            });
            
            recommendationHtml += `
                    </div>
                </div>
            `;
        }
        
        recommendationHtml += `</div>`;
        html += recommendationHtml;
    });
    
    if (html === '') {
        container.innerHTML = '<p class="text-muted">No recommendations found for the given attributes.</p>';
    } else {
        container.innerHTML = html;
    }
}

// Display rules
function displayRules(rules) {
    const container = document.getElementById('rulesContainer');
    
    if (!rules || rules.length === 0) {
        container.innerHTML = '<p class="text-muted">No rules found with the given criteria.</p>';
        return;
    }
    
    let html = '';
    
    rules.forEach(rule => {
        if (!rule.antecedent || !rule.consequent) {
            return;
        }
        
        const antecedent = rule.antecedent.join(', ');
        const consequent = rule.consequent.join(', ');
        
        html += `
            <div class="rule-card">
                <div><strong>If</strong> ${antecedent}</div>
                <div><strong>Then</strong> ${consequent}</div>
                <div class="rule-metrics">
                    <span class="metric">Support: ${(rule.support * 100).toFixed(2)}%</span>
                    <span class="metric">Confidence: ${(rule.confidence * 100).toFixed(2)}%</span>
                    <span class="metric">Lift: ${rule.lift.toFixed(2)}</span>
                </div>
            </div>
        `;
    });
    
    if (html === '') {
        container.innerHTML = '<p class="text-muted">No valid rules found with the given criteria.</p>';
    } else {
        container.innerHTML = html;
    }
} 