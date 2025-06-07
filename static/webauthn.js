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

    // Check if Windows Hello is available
    async isWindowsHelloAvailable() {
        if (!this.isSupported()) return false;
        
        try {
            // Check if platform authenticator is available (Windows Hello, Touch ID, Face ID)
            const available = await PublicKeyCredential.isUserVerifyingPlatformAuthenticatorAvailable();
            return available;
        } catch (error) {
            console.log('Platform authenticator check failed:', error);
            return false;
        }
    }

    // Check if this is Chrome browser
    isChrome() {
        const userAgent = typeof window !== 'undefined' ? window.navigator.userAgent : '';
        return userAgent.includes('Chrome') && !userAgent.includes('Edg'); // Chrome but not Edge
    }

    // Check if this is Windows browser
    isWindows() {
        const userAgent = typeof window !== 'undefined' ? window.navigator.userAgent : '';
        return userAgent.includes('Windows');
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
                
                // Add browser info for debugging
                const browserInfo = {
                    userAgent: typeof window !== 'undefined' ? window.navigator.userAgent : '',
                    isChrome: this.isChrome(),
                    isWindows: this.isWindows(),
                    platform: typeof window !== 'undefined' ? window.navigator.platform : ''
                };
                console.log('🔍 Browser Info:', browserInfo);
                
                // Get registration options from server
                const response = await fetchFn('/webauthn/register/begin', {
                    method: 'POST',
                    headers: { 'Content-Type': 'application/json' },
                    body: JSON.stringify({ username })
                });
                
                if (!response.ok) throw new Error('Registration failed');
                
                const options = await response.json();
                console.log('🔍 Server Options:', JSON.stringify(options, null, 2));
                
                if (!options.publicKey || !options.publicKey.challenge) {
                    const error = 'Server error - invalid options';
                    onError(error);
                    return { success: false, error };
                }
                
                onStatus('Create your passkey', 'info');
                
                // Convert base64 strings to ArrayBuffer
                options.publicKey.challenge = this.base64ToArrayBuffer(options.publicKey.challenge, atobFn);
                options.publicKey.user.id = this.base64ToArrayBuffer(options.publicKey.user.id, atobFn);
                
                try {
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
                    
                    if (!verificationResponse.ok) {
                        const errorResult = await verificationResponse.json().catch(() => ({}));
                        if (errorResult.error && (errorResult.error.includes('disabled') || errorResult.error.includes('locked') || errorResult.error.includes('Account Lockout'))) {
                            throw new Error('Account Lockout');
                        }
                        throw new Error('Registration verification failed');
                    }
                    
                    onStatus('Registration successful', 'success');
                    onSuccess({ username, emoji });
                    return { success: true, username, emoji };
                    
                } catch (credentialError) {
                    console.error('WebAuthn credential creation error:', credentialError);
                    console.error('Error details:', {
                        name: credentialError.name,
                        message: credentialError.message,
                        stack: credentialError.stack
                    });
                    
                    // Handle Chrome-specific "device can't be used" error
                    if (this.isChrome() && credentialError.name === 'NotAllowedError') {
                        throw new Error('Chrome WebAuthn Issue\nYour device may not be compatible\nTry Firefox or Edge browser');
                    } else if (this.isWindows() && credentialError.name === 'NotAllowedError') {
                        throw new Error('Windows Hello Registration Failed\nPlease check Windows Hello setup\nSettings > Accounts > Sign-in options');
                    } else if (credentialError.name === 'NotAllowedError') {
                        if (credentialError.message && credentialError.message.includes('device')) {
                            throw new Error('Device Not Compatible\nYour device may not support this\nTry a different browser or device');
                        }
                        throw new Error('Registration Not Allowed\nCheck browser permissions\nand privacy settings');
                    } else if (credentialError.name === 'InvalidStateError') {
                        throw new Error('Already Registered\nThis device is already registered\nTry logging in instead');
                    } else if (credentialError.name === 'SecurityError') {
                        throw new Error('Security Error\nPlease ensure secure connection\n(HTTPS required)');
                    } else if (credentialError.name === 'AbortError') {
                        throw new Error('Registration Cancelled\nPlease try again when ready');
                    } else if (credentialError.name === 'TimeoutError') {
                        throw new Error('Registration Timeout\nPlease try again\nCheck authenticator response');
                    }
                    
                    throw credentialError;
                }
                
            } catch (error) {
                console.error('WebAuthn registration error:', error);
                let errorMsg = 'Registration failed';
                
                // Handle specific Windows 11 error messages
                if (error.message && error.message.includes('Windows Hello')) {
                    errorMsg = error.message;
                } else if (error.message && error.message.includes('not allowed')) {
                    errorMsg = 'Registration not allowed - check privacy settings';
                }
                
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
                // Check for specific error types
                let error = 'Login failed';
                if (result.error) {
                    if (result.error.includes('disabled') || result.error.includes('locked') || result.error.includes('Account Lockout')) {
                        error = 'Account Lockout';
                    } else {
                        error = result.error;
                    }
                }
                onError(error);
                return { success: false, error };
            }
            
        } catch (error) {
            console.error('WebAuthn authentication error:', error);
            
            // Handle specific error cases with multi-line messages
            let errorMessage = 'Authentication failed';
            if (error.message === 'User cancelled' || 
                error.name === 'NotAllowedError' ||
                error.message.includes('cancelled') ||
                error.message.includes('abort')) {
                errorMessage = 'Authentication Cancelled\nPlease try again when ready';
            } else if (error.name === 'SecurityError') {
                errorMessage = 'Security Error\nPlease ensure secure connection\n(HTTPS required)';
            } else if (error.name === 'TimeoutError') {
                errorMessage = 'Authentication Timeout\nPlease try again\nCheck authenticator response';
            } else if (error.name === 'InvalidStateError') {
                errorMessage = 'Invalid State\nPlease refresh and try again';
            } else if (this.isWindows() && error.name === 'NotAllowedError') {
                errorMessage = 'Windows Hello Authentication Failed\nCheck Windows Hello is enabled\nSettings > Accounts > Sign-in options';
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