// WebAuthn Implementation Functions
// Extracted from main chat client for better code organization

// WebAuthn Implementation
async function registerWebAuthn() {
    // Prevent multiple concurrent operations
    if (window.webauthnInProgress) {
        console.log('WebAuthn operation already in progress, ignoring duplicate click');
        return;
    }
    window.webauthnInProgress = true;
    
    const username = document.getElementById('nickname-input').value;
    
    try {
        if (!username) {
            showLoginStatus('❌ Enter username first', 'error');
            return;
        }

        // Check username availability first
        try {
            showLoginStatus('Checking username...', 'info');
            
            const checkResponse = await fetch('/webauthn/username/check', {
                method: 'POST',
                headers: { 'Content-Type': 'application/json' },
                body: JSON.stringify({ username })
            });
            const checkResult = await checkResponse.json();
            if (!checkResult.available) {
                showLoginStatus('❌ Username taken', 'error');
                return;
            }
        } catch (err) {
            showLoginStatus('❌ Username check failed', 'error');
            return;
        }

        try {
            showLoginStatus('Preparing registration...', 'info');
            
            // Get registration options from server
            const response = await fetch('/webauthn/register/begin', {
                method: 'POST',
                headers: { 'Content-Type': 'application/json' },
                body: JSON.stringify({ username })
            });
            
            if (!response.ok) throw new Error('Registration failed');
            
            const options = await response.json();
            
            if (!options.publicKey || !options.publicKey.challenge) {
                showLoginStatus('❌ Server error', 'error');
                return;
            }
            
            showLoginStatus('Create your passkey', 'info');
            
            // Convert base64 strings to ArrayBuffer
            options.publicKey.challenge = base64ToArrayBuffer(options.publicKey.challenge);
            options.publicKey.user.id = base64ToArrayBuffer(options.publicKey.user.id);
            
            // Create credentials
            const credential = await navigator.credentials.create(options);
            
            showLoginStatus('Verifying...', 'info');
            
            // Convert ArrayBuffer to base64
            const attestationObject = arrayBufferToBase64(credential.response.attestationObject);
            const clientDataJSON = arrayBufferToBase64(credential.response.clientDataJSON);
            
            // Send registration data to server
            const verificationResponse = await fetch('/webauthn/register/complete', {
                method: 'POST',
                headers: { 'Content-Type': 'application/json' },
                body: JSON.stringify({
                    id: arrayBufferToBase64(credential.rawId),
                    rawId: arrayBufferToBase64(credential.rawId),
                    response: {
                        attestationObject,
                        clientDataJSON
                    },
                    type: credential.type,
                    username,
                    emoji: window.currentEmoji || '👤'
                })
            });
            
            if (!verificationResponse.ok) throw new Error('Registration verification failed');
            
            showLoginStatus('✅ Registration Success', 'success');
            
        } catch (error) {
            console.error('WebAuthn registration error:', error);
            showLoginStatus('❌ Registration failed', 'error');
        } finally {
            // Reset state without disabling buttons
            window.webauthnInProgress = false;
        }
    } finally {
        window.webauthnInProgress = false;
    }
}

async function loginWithWebAuthn() {
    // Prevent multiple concurrent operations
    if (window.webauthnInProgress) {
        console.log('WebAuthn operation already in progress, ignoring duplicate click');
        return;
    }
    window.webauthnInProgress = true;
    
    const usernameInput = document.getElementById('nickname-input');
    
    let username = usernameInput.value.trim();
    if (username === '') {
        username = null;
    }
    
    try {
        showLoginStatus('Preparing login...', 'info');
        
        const optionsResponse = await fetch('/webauthn/authenticate/begin', {
            method: 'POST',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify({ username: username })
        });
        
        if (!optionsResponse.ok) {
            throw new Error('Failed to get authentication options');
        }
        
        const options = await optionsResponse.json();
        
        if (!options.publicKey || !options.publicKey.challenge) {
            showLoginStatus('❌ Server error', 'error');
            return;
        }
        
        showLoginStatus('Authenticate', 'info');
        
        // Convert challenge to ArrayBuffer
        options.publicKey.challenge = base64ToArrayBuffer(options.publicKey.challenge);
        // Convert each allowCredentials id to ArrayBuffer
        if (options.publicKey.allowCredentials) {
            options.publicKey.allowCredentials = options.publicKey.allowCredentials.map(cred => ({
                ...cred,
                id: base64ToArrayBuffer(cred.id)
            }));
        }
        
        const assertion = await navigator.credentials.get({ publicKey: options.publicKey });
        
        if (!assertion) {
            throw new Error('User cancelled');
        }
        
        showLoginStatus('Verifying...', 'info');
        
        const credential = {
            id: assertion.id,
            rawId: arrayBufferToBase64(assertion.rawId),
            type: assertion.type,
            response: {
                clientDataJSON: arrayBufferToBase64(assertion.response.clientDataJSON),
                authenticatorData: arrayBufferToBase64(assertion.response.authenticatorData),
                signature: arrayBufferToBase64(assertion.response.signature),
                userHandle: assertion.response.userHandle ? arrayBufferToBase64(assertion.response.userHandle) : null
            },
            username: username || ''
        };
        
        const verifyResponse = await fetch('/webauthn/authenticate/complete', {
            method: 'POST',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify(credential)
        });
        
        const result = await verifyResponse.json();
        
        if (result.success) {
            if (!usernameInput.value && result.username) {
                usernameInput.value = result.username;
            }
            showLoginStatus('✅ Login Success', 'success');
            
            // Join the chat after successful authentication
            setTimeout(() => {
                joinChat();
            }, 1000);
        } else {
            showLoginStatus('❌ Login failed', 'error');
        }
        
    } catch (error) {
        console.error('WebAuthn authentication error:', error);
        
        // Handle specific error cases
        if (error.message === 'User cancelled' || 
            error.name === 'NotAllowedError' ||
            error.message.includes('cancelled') ||
            error.message.includes('abort')) {
            showLoginStatus('❌ User cancelled', 'error');
        } else {
            showLoginStatus('❌ Authentication failed', 'error');
        }
    } finally {
        // Reset state without disabling buttons
        window.webauthnInProgress = false;
    }
}

// Utility functions for ArrayBuffer conversion
function base64ToArrayBuffer(base64) {
    const binaryString = window.atob(base64);
    const bytes = new Uint8Array(binaryString.length);
    for (let i = 0; i < binaryString.length; i++) {
        bytes[i] = binaryString.charCodeAt(i);
    }
    return bytes.buffer;
}

function arrayBufferToBase64(buffer) {
    const bytes = new Uint8Array(buffer);
    let binary = '';
    for (let i = 0; i < bytes.byteLength; i++) {
        binary += String.fromCharCode(bytes[i]);
    }
    return window.btoa(binary);
}

// Status message functions
function showLoginStatus(message, type = 'info') {
    const statusEl = document.getElementById('login-status');
    if (!statusEl) return;
    
    statusEl.textContent = message;
    statusEl.className = `status-message ${type}`;
}

function clearLoginStatus() {
    const statusEl = document.getElementById('login-status');
    
    // Clear ALL status-related timeouts
    if (window.statusTimeout) {
        clearTimeout(window.statusTimeout);
        window.statusTimeout = null;
    }
    if (window.statusFadeTimeout) {
        clearTimeout(window.statusFadeTimeout);
        window.statusFadeTimeout = null;
    }
    
    statusEl.classList.remove('fading');
    statusEl.className = 'status-message';
    statusEl.textContent = '';
    statusEl.style.display = 'none';
}

function setButtonState(registerBtn, loginBtn, disabled, registerText, loginText) {
    registerBtn.disabled = disabled;
    loginBtn.disabled = disabled;
    registerBtn.textContent = registerText;
    loginBtn.textContent = loginText;
}

// Initialize WebAuthn state on page load
document.addEventListener('DOMContentLoaded', function() {
    document.querySelectorAll('#rp-id').forEach(function(el) {
        el.textContent = window.location.hostname;
    });
    
    // Reset all global state to prevent accumulation
    window.statusTimeout = null;
    window.statusFadeTimeout = null;
    window.webauthnInProgress = false;
    
    // Clear any status message on page load
    clearLoginStatus();
}); 