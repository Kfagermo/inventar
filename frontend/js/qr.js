let html5QrcodeScanner = null;

// Function to initialize the QR scanner
function initializeScanner() {
    console.log('Initializing QR scanner...');
    if (!html5QrcodeScanner) {
        html5QrcodeScanner = new Html5Qrcode("reader");
    }

    const qrCodeSuccessCallback = (decodedText, decodedResult) => {
        console.log(`QR Code Scanned: ${decodedText}`, decodedResult);
        console.log('Attempting to fetch item with ID:', decodedText.trim());
        html5QrcodeScanner.stop().then(() => {
            console.log('QR scanner stopped');
            const scannerContainer = document.getElementById('scannerContainer');
            scannerContainer.classList.remove('show');
            document.body.classList.remove('no-scroll');
            fetchItemAndSelect(decodedText.trim());
        }).catch(err => {
            console.error('Error stopping QR scanner:', err);
            showError('Kunne ikke stoppe QR-skanner.');
        });
    };

    const config = { fps: 10, qrbox: 250 };

    html5QrcodeScanner.start(
        { facingMode: "environment" },
        config,
        qrCodeSuccessCallback
    ).then(() => {
        console.log('QR scanner started successfully.');
    }).catch(err => {
        console.error('Unable to start QR scanner:', err);
        showError('Kunne ikke starte QR-skanner. Vennligst prøv igjen.');
    });
}

// Function to start the QR scanner
function startScanner() {
    console.log('Starting QR scanner...');
    const scannerContainer = document.getElementById('scannerContainer');
    scannerContainer.classList.add('show');
    document.body.classList.add('no-scroll');
    initializeScanner();
}

// Function to stop the QR scanner
function stopScanner() {
    console.log('Stopping QR scanner...');
    const scannerContainer = document.getElementById('scannerContainer');
    scannerContainer.classList.remove('show');
    document.body.classList.remove('no-scroll');
    if (html5QrcodeScanner) {
        html5QrcodeScanner.stop().then(() => {
            console.log('QR scanner stopped');
        }).catch(err => {
            console.error('Error stopping QR scanner:', err);
            showError('Kunne ikke stoppe QR-skanner.');
        });
    }
}

// Fetch item by QR code and open the modal
async function fetchItemAndSelect(el_nummer_id) {
    try {
        console.log(`Fetching item with ID: ${el_nummer_id}`);
        showLoading();
        const response = await fetch(`${API_BASE_URL}/inventory/${el_nummer_id}`);
        
        if (!response.ok) {
            let errorMsg = 'Kunne ikke hente varen';
            try {
                const errorData = await response.json();
                errorMsg = errorData.error || errorMsg;
            } catch (e) {
                errorMsg = 'Kunne ikke hente varen: Server returnerte en feil.';
            }
            throw new Error(errorMsg);
        }

        const item = await response.json();
        console.log('Fetched item:', item);
        openStockAdjustModal(item);
    } catch (error) {
        console.error('Error fetching item:', error);
        showError(error.message);
    } finally {
        hideLoading();
    }
}

// Show loading indicator
function showLoading() {
    const loadingIndicator = document.getElementById('loadingIndicator');
    if (loadingIndicator) {
        loadingIndicator.style.display = 'block';
    }
}

// Hide loading indicator
function hideLoading() {
    const loadingIndicator = document.getElementById('loadingIndicator');
    if (loadingIndicator) {
        loadingIndicator.style.display = 'none';
    }
}

// Show error message
function showError(message) {
    const errorToast = document.getElementById('errorToast');
    if (errorToast) {
        errorToast.textContent = message;
        errorToast.style.display = 'block';
        errorToast.style.animation = 'fadeInOut 3s forwards';
    }
}

// Set up event listeners on DOMContentLoaded
document.addEventListener('DOMContentLoaded', () => {
    console.log('DOMContentLoaded event fired.');

    const scanButton = document.getElementById('scanButton');
    const scannerContainer = document.getElementById('scannerContainer');

    if (scanButton) {
        scanButton.addEventListener('click', () => {
            console.log('Scan QR Code button clicked.');
            startScanner();
        });
    } else {
        console.error('Scan button with ID "scanButton" not found.');
    }

    if (scannerContainer) {
        scannerContainer.addEventListener('click', (event) => {
            // Close the scanner only if the click is on the scannerContainer (outside the reader)
            if (event.target === scannerContainer) {
                console.log('Clicked outside the QR reader. Closing scanner.');
                stopScanner();
            }
        });

        // Prevent clicks inside the reader from propagating to the scannerContainer
        const reader = document.getElementById('reader');
        if (reader) {
            reader.addEventListener('click', (event) => {
                event.stopPropagation();
            });
        } else {
            console.error('Reader div with ID "reader" not found.');
        }
    } else {
        console.error('Scanner container with ID "scannerContainer" not found.');
    }
}); 