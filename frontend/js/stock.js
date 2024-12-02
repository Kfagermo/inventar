let currentItemId = null;

// Function to unlock an item
async function unlockItem(itemId) {
    try {
        const response = await fetch(`${API_BASE_URL}/unlock_item`, {
            method: 'POST',
            headers: {
                'Content-Type': 'application/json'
            },
            body: JSON.stringify({
                el_nummer_id: itemId,
                user: 'mobile_user'
            })
        });
        
        if (!response.ok) {
            console.error('Failed to unlock item:', itemId);
        }
    } catch (error) {
        console.error('Error unlocking item:', error);
    }
}

window.openStockAdjustModal = async function(item) {
    if (!item) {
        console.error('No item provided to openStockAdjustModal');
        return;
    }
    
    try {
        // If there's a currently locked item, unlock it first
        if (currentItemId) {
            await unlockItem(currentItemId);
            currentItemId = null;
        }

        const response = await fetch(`${API_BASE_URL}/lock_item`, {
            method: 'POST',
            headers: {
                'Content-Type': 'application/json'
            },
            body: JSON.stringify({
                el_nummer_id: item.el_nummer_id,
                user: 'mobile_user'
            })
        });

        if (!response.ok) {
            const errorData = await response.json();
            throw new Error(errorData.message || 'Item is currently being edited by another user');
        }

        currentItemId = item.el_nummer_id;
        const modal = document.getElementById('adjustStockModal');
        const itemDesc = document.getElementById('itemDescription');
        const currentStockSpan = document.getElementById('currentStock');
        const stockInput = document.getElementById('stockInput');

        itemDesc.textContent = item.beskrivelse;
        currentStockSpan.textContent = `${item.antall} ${item.enhet || 'stk'}`;
        stockInput.value = item.antall;
        modal.style.display = 'flex';
        
    } catch (error) {
        console.error('Error in openStockAdjustModal:', error);
        showError(error.message);
    }
};

document.addEventListener('DOMContentLoaded', () => {
    const modal = document.getElementById('adjustStockModal');
    const stockInput = document.getElementById('stockInput');
    const confirmBtn = document.getElementById('confirmStockButton');
    const closeBtn = document.getElementById('closeStockModal');
    const errorMessageElement = document.getElementById('stockErrorMessage');

    // Close modal and unlock item
    const closeModal = async () => {
        if (currentItemId) {
            await unlockItem(currentItemId);
            currentItemId = null;
        }
        modal.style.display = 'none';
        errorMessageElement.style.display = 'none';
    };

    closeBtn.onclick = closeModal;

    // Close modal when clicking outside
    window.onclick = async (event) => {
        if (event.target === modal) {
            await closeModal();
        }
    };

    confirmBtn.onclick = async () => {
        const newStock = parseInt(stockInput.value);
        if (isNaN(newStock) || newStock < 0) {
            errorMessageElement.textContent = 'Vennligst skriv inn et gyldig tall';
            errorMessageElement.style.display = 'block';
            return;
        }

        try {
            showLoading();
            const now = new Date().toISOString();
            const response = await fetch(`${API_BASE_URL}/update_stock`, {
                method: 'POST',
                headers: {
                    'Content-Type': 'application/json',
                },
                body: JSON.stringify({
                    el_nummer_id: currentItemId,
                    antall: newStock,
                    last_updated: now
                })
            });
            
            if (!response.ok) {
                throw new Error('Kunne ikke oppdatere lager');
            }

            // Get the updated item data
            const updatedItem = await response.json();
            console.log('Updated item response:', updatedItem);
            
            // Close modal and unlock item
            await closeModal();
            
            // Refresh inventory to get updated data
            await fetchInventory();

            // Find and highlight the updated item after refresh
            setTimeout(() => {
                const updatedItemElement = document.querySelector(`[data-id="${currentItemId}"]`);
                if (updatedItemElement) {
                    updatedItemElement.classList.add('update-success');
                    updatedItemElement.scrollIntoView({ behavior: 'smooth', block: 'start' });
                    setTimeout(() => {
                        updatedItemElement.classList.remove('update-success');
                    }, 1000);
                }
            }, 200);

        } catch (error) {
            errorMessageElement.textContent = error.message;
            errorMessageElement.style.display = 'block';
            console.error('Error updating stock:', error);
        } finally {
            hideLoading();
        }
    };

    // Add increase/decrease button handlers
    const increaseBtn = document.getElementById('increaseStock');
    const decreaseBtn = document.getElementById('decreaseStock');

    increaseBtn.onclick = () => {
        stockInput.value = parseInt(stockInput.value || 0) + 1;
    };

    decreaseBtn.onclick = () => {
        const currentValue = parseInt(stockInput.value || 0);
        if (currentValue > 0) {
            stockInput.value = currentValue - 1;
        }
    };
});
