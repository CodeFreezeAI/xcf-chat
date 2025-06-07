// WebAuthn Core Implementation
// Completely decoupled from DOM/Window - pure logic only

class WebAuthnClient {
    constructor() {
        this.inProgress = false;
    }

    // Check if WebAuthn is supported (only allowed window access)
    isSupported() {
        return window.PublicKeyCredential && 
               typeof window.PublicKeyCredential === 'function' &&
               navigator.credentials && 
               typeof navigator.credentials.create === 'function';
    }

    // Register a new WebAuthn credential
    async register(username, emoji = '👤', callbacks = {}, browserAPI = {}) {
        if (this.inProgress) {
            console.log('WebAuthn operation already in progress, ignoring duplicate call');
            return { success: false, error: 'Operation in progress' };
        }

        this.inProgress = true;
        const { onStatus = () => {}, onError = () => {}, onSuccess = () => {} } = callbacks;
        const { 
            fetch: fetchFn = fetch, 
            atob: atobFn = atob, 
            btoa: btoaFn = btoa,
            credentialsAPI = navigator.credentials
        } = browserAPI;

        try {
            if (!username) {
                const error = 'Username is required';
                onError(error);
                return { success: false, error };
            }

            // Check username availability first
            try {
                onStatus('Checking username...', 'info');
                
                const checkResponse = await fetchFn('/webauthn/username/check', {
                    method: 'POST',
                    headers: { 'Content-Type': 'application/json' },
                    body: JSON.stringify({ username })
                });
                const checkResult = await checkResponse.json();
                if (!checkResult.available) {
                    const error = 'Username is already taken';
                    onError(error);
                    return { success: false, error };
                }
            } catch (err) {
                const error = 'Username check failed';
                onError(error);
                return { success: false, error };
            }

            try {
                onStatus('Preparing registration...', 'info');
                
                // Get registration options from server
                const response = await fetchFn('/webauthn/register/begin', {
                    method: 'POST',
                    headers: { 'Content-Type': 'application/json' },
                    body: JSON.stringify({ username })
                });
                
                if (!response.ok) throw new Error('Registration failed');
                
                const options = await response.json();
                
                if (!options.publicKey || !options.publicKey.challenge) {
                    const error = 'Server error - invalid options';
                    onError(error);
                    return { success: false, error };
                }
                
                onStatus('Create your passkey', 'info');
                
                // Convert base64 strings to ArrayBuffer
                options.publicKey.challenge = this.base64ToArrayBuffer(options.publicKey.challenge, atobFn);
                options.publicKey.user.id = this.base64ToArrayBuffer(options.publicKey.user.id, atobFn);
                
                // Create credentials
                const credential = await credentialsAPI.create(options);
                
                onStatus('Verifying...', 'info');
                
                // Convert ArrayBuffer to base64
                const attestationObject = this.arrayBufferToBase64(credential.response.attestationObject, btoaFn);
                const clientDataJSON = this.arrayBufferToBase64(credential.response.clientDataJSON, btoaFn);
                
                // Send registration data to server
                const verificationResponse = await fetchFn('/webauthn/register/complete', {
                    method: 'POST',
                    headers: { 'Content-Type': 'application/json' },
                    body: JSON.stringify({
                        id: this.arrayBufferToBase64(credential.rawId, btoaFn),
                        rawId: this.arrayBufferToBase64(credential.rawId, btoaFn),
                        response: {
                            attestationObject,
                            clientDataJSON
                        },
                        type: credential.type,
                        username,
                        emoji
                    })
                });
                
                if (!verificationResponse.ok) throw new Error('Registration verification failed');
                
                onStatus('Registration successful', 'success');
                onSuccess({ username, emoji });
                return { success: true, username, emoji };
                
            } catch (error) {
                console.error('WebAuthn registration error:', error);
                const errorMsg = 'Registration failed';
                onError(errorMsg);
                return { success: false, error: errorMsg };
            }
        } finally {
            this.inProgress = false;
        }
    }

    // Authenticate with existing WebAuthn credential
    async authenticate(username = null, callbacks = {}, browserAPI = {}) {
        if (this.inProgress) {
            console.log('WebAuthn operation already in progress, ignoring duplicate call');
            return { success: false, error: 'Operation in progress' };
        }

        this.inProgress = true;
        const { onStatus = () => {}, onError = () => {}, onSuccess = () => {} } = callbacks;
        const { 
            fetch: fetchFn = fetch, 
            atob: atobFn = atob, 
            btoa: btoaFn = btoa,
            credentialsAPI = navigator.credentials
        } = browserAPI;

        try {
            onStatus('Preparing login...', 'info');
            
            const optionsResponse = await fetchFn('/webauthn/authenticate/begin', {
                method: 'POST',
                headers: { 'Content-Type': 'application/json' },
                body: JSON.stringify({ username: username || '' })
            });
            
            if (!optionsResponse.ok) {
                throw new Error('Failed to get authentication options');
            }
            
            const options = await optionsResponse.json();
            
            if (!options.publicKey || !options.publicKey.challenge) {
                const error = 'Server error - invalid options';
                onError(error);
                return { success: false, error };
            }
            
            onStatus('Authenticate with your passkey', 'info');
            
            // Convert challenge to ArrayBuffer
            options.publicKey.challenge = this.base64ToArrayBuffer(options.publicKey.challenge, atobFn);
            // Convert each allowCredentials id to ArrayBuffer
            if (options.publicKey.allowCredentials) {
                options.publicKey.allowCredentials = options.publicKey.allowCredentials.map(cred => ({
                    ...cred,
                    id: this.base64ToArrayBuffer(cred.id, atobFn)
                }));
            }
            
            const assertion = await credentialsAPI.get({ publicKey: options.publicKey });
            
            if (!assertion) {
                throw new Error('User cancelled');
            }
            
            onStatus('Verifying...', 'info');
            
            const credential = {
                id: assertion.id,
                rawId: this.arrayBufferToBase64(assertion.rawId, btoaFn),
                type: assertion.type,
                response: {
                    clientDataJSON: this.arrayBufferToBase64(assertion.response.clientDataJSON, btoaFn),
                    authenticatorData: this.arrayBufferToBase64(assertion.response.authenticatorData, btoaFn),
                    signature: this.arrayBufferToBase64(assertion.response.signature, btoaFn),
                    userHandle: assertion.response.userHandle ? this.arrayBufferToBase64(assertion.response.userHandle, btoaFn) : null
                },
                username: username || ''
            };
            
            const verifyResponse = await fetchFn('/webauthn/authenticate/complete', {
                method: 'POST',
                headers: { 'Content-Type': 'application/json' },
                body: JSON.stringify(credential)
            });
            
            const result = await verifyResponse.json();
            
            if (result.success) {
                onStatus('Login successful', 'success');
                onSuccess({ username: result.username || username });
                return { success: true, username: result.username || username };
            } else {
                const error = 'Login failed';
                onError(error);
                return { success: false, error };
            }
            
        } catch (error) {
            console.error('WebAuthn authentication error:', error);
            
            // Handle specific error cases
            let errorMessage = 'Authentication failed';
            if (error.message === 'User cancelled' || 
                error.name === 'NotAllowedError' ||
                error.message.includes('cancelled') ||
                error.message.includes('abort')) {
                errorMessage = 'User cancelled';
            }
            
            onError(errorMessage);
            return { success: false, error: errorMessage };
        } finally {
            this.inProgress = false;
        }
    }

    // Utility functions for ArrayBuffer conversion (pure functions)
    base64ToArrayBuffer(base64, atobFn) {
        const binaryString = atobFn(base64);
        const bytes = new Uint8Array(binaryString.length);
        for (let i = 0; i < binaryString.length; i++) {
            bytes[i] = binaryString.charCodeAt(i);
        }
        return bytes.buffer;
    }

    arrayBufferToBase64(buffer, btoaFn) {
        const bytes = new Uint8Array(buffer);
        let binary = '';
        for (let i = 0; i < bytes.byteLength; i++) {
            binary += String.fromCharCode(bytes[i]);
        }
        return btoaFn(binary);
    }
}

// Export the WebAuthn client class
const webAuthnClient = new WebAuthnClient(); 