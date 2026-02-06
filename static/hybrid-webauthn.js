// Hybrid WebAuthn Client - for testing QR code + security key functionality simultaneously
class HybridWebAuthnClient {
    constructor() {
        this.inProgress = false;
    }

    isSupported() {
        return (typeof window !== 'undefined' && 
                window.navigator && 
                window.navigator.credentials && 
                window.PublicKeyCredential);
    }

    isChrome() {
        return /Chrome/.test(navigator.userAgent) && /Google Inc/.test(navigator.vendor);
    }

    isFirefox() {
        return /Firefox/.test(navigator.userAgent);
    }

    isWindows() {
        return /Win/.test(navigator.platform);
    }

    isMac() {
        return /Mac/.test(navigator.platform);
    }

    isLinux() {
        return /Linux/.test(navigator.platform) && !/Android/.test(navigator.userAgent);
    }

    isAndroid() {
        return /Android/.test(navigator.userAgent);
    }

    async register(username, emoji = '👤', callbacks = {}, browserAPI = {}) {
        const { 
            onStatus = () => {}, 
            onSuccess = () => {}, 
            onError = () => {} 
        } = callbacks;

        if (this.inProgress) {
            const error = 'Registration already in progress';
            onError(error);
            return { success: false, error };
        }

        if (!this.isSupported()) {
            const error = 'WebAuthn not supported in this browser';
            onError(error);
            return { success: false, error };
        }

        try {
            if (!username || username.trim() === '') {
                throw new Error('Username is required');
            }

            username = username.trim();

            if (username.length < 2) {
                throw new Error('Username must be at least 2 characters long');
            }

            if (username.length > 50) {
                throw new Error('Username must be 50 characters or less');
            }

            if (!/^[a-zA-Z0-9_-]+$/.test(username)) {
                throw new Error('Username can only contain letters, numbers, underscores, and dashes');
            }

        } catch (error) {
            console.error('❌ Username validation error:', error.message);
            onError(error.message);
            return { success: false, error };
        }

        this.inProgress = true;
        const { 
            fetch: fetchFn = fetch, 
            atob: atobFn = atob, 
            btoa: btoaFn = btoa,
            credentialsAPI = navigator.credentials
        } = browserAPI;
        
        try {
            onStatus('Checking username availability...', 'info');
            
            // Check if username is available before proceeding
            console.log(`🔍 Checking username availability for: "${username}"`);
            const usernameCheckResponse = await fetchFn('/webauthn/username/check', {
                method: 'POST',
                headers: { 'Content-Type': 'application/json' },
                body: JSON.stringify({ username })
            });
            
            if (!usernameCheckResponse.ok) {
                throw new Error('Failed to check username availability');
            }
            
            const usernameResult = await usernameCheckResponse.json();
            
            if (!usernameResult.available) {
                onStatus('Username already taken', 'error');
                throw new Error('Username Already Taken\nPlease choose a different username.');
            }
            
            console.log(`✅ Username "${username}" is available`);
            onStatus('Starting hybrid registration (QR code + security key)...', 'info');
            
            // Always use hybrid endpoint for testing
            const endpoint = '/webauthn/register/begin/hybrid';
            console.log(`🎯 Using hybrid endpoint: ${endpoint}`);
            
            // Get registration options from server
            const response = await fetchFn(endpoint, {
                method: 'POST',
                headers: { 'Content-Type': 'application/json' },
                body: JSON.stringify({ username })
            });
            
            if (!response.ok) throw new Error('Registration failed');
            
            const options = await response.json();
            console.log('🔍 Hybrid Server Options:', JSON.stringify(options, null, 2));
            
            if (!options.publicKey || !options.publicKey.challenge) {
                throw new Error('Server error - invalid options');
            }
            
            onStatus('Choose: QR code (phone passkey) or security key', 'info');
            
            // Log the actual options that will be sent to Chrome
            console.log('📋 Final options being sent to navigator.credentials.create():');
            console.log(JSON.stringify(options, null, 2));
            
            // Additional macOS-specific logging
            if (this.isMac()) {
                console.log('🍎 Running on macOS - Chrome behavior may vary');
                console.log('Expected: Touch ID + QR code + security key options');
                if (typeof PublicKeyCredential !== 'undefined' && PublicKeyCredential.isUserVerifyingPlatformAuthenticatorAvailable) {
                    PublicKeyCredential.isUserVerifyingPlatformAuthenticatorAvailable().then(available => {
                        console.log(`Touch ID Available: ${available}`);
                    }).catch(() => console.log('Could not check Touch ID availability'));
                }
            }
            
            // Convert base64 strings to ArrayBuffer
            options.publicKey.challenge = this.base64ToArrayBuffer(options.publicKey.challenge, atobFn);
            options.publicKey.user.id = this.base64ToArrayBuffer(options.publicKey.user.id, atobFn);
            
            // Special handling for macOS Chrome to force hybrid options
            if (this.isMac() && this.isChrome()) {
                console.log('🍎 Detected Chrome on macOS - applying special hybrid workaround');
                
                // Remove any remaining restrictions that might cause Chrome to prioritize Touch ID
                if (options.publicKey.authenticatorSelection) {
                    delete options.publicKey.authenticatorSelection;
                    console.log('🔧 Removed authenticatorSelection for macOS Chrome');
                }
                
                // Force userVerification to discouraged to prevent Touch ID preference
                if (options.publicKey.userVerification) {
                    options.publicKey.userVerification = 'discouraged';
                    console.log('🔧 Set userVerification to discouraged for macOS Chrome');
                }
                
                console.log('🔧 Final macOS-optimized options:', JSON.stringify(options, null, 2));
            }
            
            // Create credential using hybrid approach
            const credential = await credentialsAPI.create(options);
            
            onStatus('Verifying...', 'info');
            
            const verificationData = {
                id: credential.id,
                rawId: this.arrayBufferToBase64(credential.rawId, btoaFn),
                response: {
                    attestationObject: this.arrayBufferToBase64(credential.response.attestationObject, btoaFn),
                    clientDataJSON: this.arrayBufferToBase64(credential.response.clientDataJSON, btoaFn)
                },
                type: credential.type,
                username,
                emoji
            };
            
            const verificationResponse = await fetchFn('/webauthn/register/complete', {
                method: 'POST',
                headers: { 'Content-Type': 'application/json' },
                body: JSON.stringify(verificationData)
            });
            
            if (!verificationResponse.ok) {
                const errorResult = await verificationResponse.json().catch(() => ({}));
                if (errorResult.error && (errorResult.error.includes('disabled') || errorResult.error.includes('locked') || errorResult.error.includes('Account Lockout'))) {
                    throw new Error('Account Lockout');
                }
                throw new Error('Registration verification failed');
            }
            
            onStatus('Hybrid registration successful!', 'success');
            onSuccess({ username, emoji });
            return { success: true, username, emoji };
            
        } catch (credentialError) {
            console.error('Hybrid WebAuthn credential creation error:', credentialError);
            
            // Handle user cancellation
            if (credentialError.name === 'AbortError') {
                onStatus('Registration cancelled by user', 'error');
                throw new Error('Registration Cancelled\nYou cancelled the registration process.');
            }
            
            // Handle other specific errors
            if (credentialError.name === 'NotAllowedError') {
                onStatus('Registration not allowed', 'error');
                throw new Error('Registration Not Allowed\nCheck browser permissions and privacy settings\nEnsure you have a security key or phone available');
            } else if (credentialError.name === 'InvalidStateError') {
                onStatus('Already registered', 'error');
                throw new Error('Already Registered\nThis device is already registered\nTry logging in instead');
            } else if (credentialError.name === 'SecurityError') {
                onStatus('Security error', 'error');
                throw new Error('Security Error\nPlease ensure secure connection (HTTPS required)');
            } else if (credentialError.name === 'TimeoutError') {
                onStatus('Registration timeout', 'error');
                throw new Error('Registration Timeout\nPlease try again\nCheck authenticator response');
            } else {
                onStatus('Hybrid registration failed', 'error');
                throw credentialError;
            }
        } finally {
            this.inProgress = false;
        }
    }

    async authenticate(username = null, callbacks = {}, browserAPI = {}) {
        const { 
            onStatus = () => {}, 
            onSuccess = () => {}, 
            onError = () => {} 
        } = callbacks;

        if (this.inProgress) {
            const error = 'Authentication already in progress';
            onError(error);
            return { success: false, error };
        }

        if (!this.isSupported()) {
            const error = 'WebAuthn not supported in this browser';
            onError(error);
            return { success: false, error };
        }

        this.inProgress = true;
        const { 
            fetch: fetchFn = fetch, 
            atob: atobFn = atob, 
            btoa: btoaFn = btoa,
            credentialsAPI = navigator.credentials
        } = browserAPI;

        try {
            onStatus('Starting hybrid authentication...', 'info');
            
            // Always use hybrid endpoint for testing
            const endpoint = '/webauthn/authenticate/begin/hybrid';
            console.log(`🎯 Using hybrid auth endpoint: ${endpoint}`);
            
            const response = await fetchFn(endpoint, {
                method: 'POST',
                headers: { 'Content-Type': 'application/json' },
                body: JSON.stringify({ username })
            });
            
            if (!response.ok) throw new Error('Authentication initialization failed');
            
            const options = await response.json();
            console.log('🔍 Hybrid Auth Options:', JSON.stringify(options, null, 2));
            
            if (!options.publicKey || !options.publicKey.challenge) {
                throw new Error('Server error - invalid auth options');
            }
            
            onStatus('Choose: Phone passkey (QR) or security key', 'info');
            
            // Convert base64 strings to ArrayBuffer
            options.publicKey.challenge = this.base64ToArrayBuffer(options.publicKey.challenge, atobFn);
            
            if (options.publicKey.allowCredentials) {
                options.publicKey.allowCredentials = options.publicKey.allowCredentials.map(cred => ({
                    ...cred,
                    id: this.base64ToArrayBuffer(cred.id, atobFn)
                }));
            }
            
            const credential = await credentialsAPI.get(options);
            
            onStatus('Verifying authentication...', 'info');
            
            const authData = {
                id: credential.id,
                rawId: this.arrayBufferToBase64(credential.rawId, btoaFn),
                response: {
                    authenticatorData: this.arrayBufferToBase64(credential.response.authenticatorData, btoaFn),
                    clientDataJSON: this.arrayBufferToBase64(credential.response.clientDataJSON, btoaFn),
                    signature: this.arrayBufferToBase64(credential.response.signature, btoaFn),
                    userHandle: credential.response.userHandle ? this.arrayBufferToBase64(credential.response.userHandle, btoaFn) : null
                },
                type: credential.type
            };
            
            const verificationResponse = await fetchFn('/webauthn/authenticate/complete', {
                method: 'POST',
                headers: { 'Content-Type': 'application/json' },
                body: JSON.stringify(authData)
            });
            
            if (!verificationResponse.ok) {
                const errorResult = await verificationResponse.json().catch(() => ({}));
                if (errorResult.error && errorResult.error.includes('locked')) {
                    throw new Error('Account Lockout');
                }
                throw new Error('Authentication verification failed');
            }
            
            const result = await verificationResponse.json();
            onStatus('Hybrid authentication successful!', 'success');
            onSuccess(result);
            return { success: true, ...result };
            
        } catch (authError) {
            console.error('Hybrid WebAuthn authentication error:', authError);
            
            if (authError.name === 'AbortError') {
                onStatus('Authentication cancelled', 'error');
                throw new Error('Authentication Cancelled\nYou cancelled the authentication process.');
            } else if (authError.name === 'NotAllowedError') {
                onStatus('Authentication not allowed', 'error');
                throw new Error('Authentication Not Allowed\nCheck that your security key or phone is available');
            } else if (authError.name === 'SecurityError') {
                onStatus('Security error', 'error');
                throw new Error('Security Error\nPlease ensure secure connection (HTTPS required)');
            } else if (authError.name === 'TimeoutError') {
                onStatus('Authentication timeout', 'error');
                throw new Error('Authentication Timeout\nPlease try again');
            } else {
                onStatus('Hybrid authentication failed', 'error');
                throw authError;
            }
        } finally {
            this.inProgress = false;
        }
    }

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

// Initialize the hybrid client when the page loads
let hybridWebAuthnClient;

document.addEventListener('DOMContentLoaded', function() {
    hybridWebAuthnClient = new HybridWebAuthnClient();
    console.log('🔄 Hybrid WebAuthn Client initialized');
    
    // Update UI based on browser support
    if (!hybridWebAuthnClient.isSupported()) {
        document.getElementById('unsupported-message').style.display = 'block';
        document.getElementById('webauthn-forms').style.display = 'none';
    }
}); 