async function fetchInventory() {
    try {
        showLoading();
        const response = await fetch(`${API_BASE_URL}/inventory`, {
            method: 'GET',
            headers: {
                'Content-Type': 'application/json'
            }
        });
        
        if (!response.ok) {
            let errorMsg = 'Failed to fetch inventory';
            try {
                const errorData = await response.json();
                errorMsg = errorData.error || errorMsg;
            } catch (e) {
                errorMsg = 'Failed to fetch inventory: Server returned an error.';
            }
            throw new Error(errorMsg);
        }
        
        const inventory = await response.json();
        console.log('Raw API Response:', inventory);
        
        const items = Array.isArray(inventory) ? inventory : 
                     (inventory.items || inventory.data || []);
        
        if (items.length === 0) {
            const errorMessage = document.getElementById('stockErrorMessage');
            errorMessage.textContent = 'Ingen varer funnet i lageret';
            errorMessage.style.display = 'block';
            return;
        }
        
        displayInventory(items);
    } catch (error) {
        console.error('Error fetching inventory:', error);
        const errorMessage = document.getElementById('stockErrorMessage');
        errorMessage.textContent = error.message;
        errorMessage.style.display = 'block';
    } finally {
        hideLoading();
    }
}

// Call fetchInventory on page load
document.addEventListener('DOMContentLoaded', fetchInventory);

// Function to display inventory items
function displayInventory(items) {
    const inventoryList = document.getElementById('inventoryList');
    inventoryList.innerHTML = '';  // Clear existing items

    // Sort items by last_updated timestamp (most recent first)
    const sortedItems = [...items].sort((a, b) => {
        const dateA = a.last_updated ? new Date(a.last_updated).getTime() : 0;
        const dateB = b.last_updated ? new Date(b.last_updated).getTime() : 0;
        return dateB - dateA;
    });

    sortedItems.forEach(item => {
        const itemDiv = document.createElement('div');
        itemDiv.classList.add('inventory-item');
        itemDiv.setAttribute('data-id', item.el_nummer_id);
        
        // Format the timestamp if it exists
        const lastUpdated = item.last_updated ? 
            new Date(item.last_updated).toLocaleString('no-NO', {
                day: '2-digit',
                month: '2-digit',
                year: 'numeric',
                hour: '2-digit',
                minute: '2-digit'
            }) : 'Ikke oppdatert';

        itemDiv.innerHTML = `
            <div class="item-info">
                <div class="item-header">
                    <h3>${item.beskrivelse}</h3>
                    <span class="timestamp">${lastUpdated}</span>
                </div>
                <div class="item-details">
                    <div class="left-details">
                        <p><strong>ID:</strong> ${item.el_nummer_id}</p>
                        <p class="category"><strong>Kategori:</strong> ${item.kategori || 'Ikke angitt'}</p>
                    </div>
                    <div class="stock-info">
                        <p class="stock-count"><strong>Antall:</strong> ${item.antall} ${item.enhet || 'stk'}</p>
                        <p class="min-stock">Anbefalt minimum: ${item.min_antall || 0} ${item.enhet || 'stk'}</p>
                    </div>
                </div>
            </div>
        `;
        
        itemDiv.addEventListener('click', () => openStockAdjustModal(item));
        inventoryList.appendChild(itemDiv);
    });
}

function showError(message) {
    const errorDiv = document.createElement('div');
    errorDiv.className = 'error-toast';
    errorDiv.textContent = message;
    document.body.appendChild(errorDiv);
    setTimeout(() => errorDiv.remove(), 3000);
    console.error('Error:', message);
}

