const API_BASE_URL = window.location.hostname === 'localhost' 
    ? 'http://localhost:5000/api'
    : window.location.protocol === 'https:' 
        ? 'https://152.93.129.206/api'
        : 'http://152.93.129.206/api';

const QR_API_BASE_URL = API_BASE_URL;