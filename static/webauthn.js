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

    // Browser and platform detection
    isChrome() {
        return navigator.userAgent.includes('Chrome') && !navigator.userAgent.includes('Edg');
    }
    
    isFirefox() {
        return navigator.userAgent.includes('Firefox');
    }
    
    isWindows() {
        return navigator.userAgent.includes('Windows');
    }
    
    isMac() {
        return navigator.userAgent.includes('Mac');
    }
    
    isLinux() {
        return navigator.userAgent.includes('Linux');
    }
    
    // Enhanced platform authenticator check with Linux detection
    async isPlatformAuthenticatorAvailable() {
        if (!this.isSupported()) return false;
        
        // On Linux, platform authenticators are rarely available
        if (this.isLinux()) {
            console.log('🐧 Linux detected - platform authenticators typically not available');
            return false;
        }
        
        try {
            const available = await PublicKeyCredential.isUserVerifyingPlatformAuthenticatorAvailable();
            console.log(`📱 Platform authenticator available: ${available}`);
            return available;
        } catch (error) {
            console.log('Platform authenticator check failed:', error);
            return false;
        }
    }
    
    // Determine best registration strategy based on platform
    async getBestRegistrationStrategy() {
        const isLinux = this.isLinux();
        const isFirefox = this.isFirefox();
        const platformAuthAvailable = await this.isPlatformAuthenticatorAvailable();
        
        console.log('🔍 Platform Detection:', {
            isLinux,
            isFirefox,
            platformAuthAvailable,
            userAgent: navigator.userAgent
        });
        
        if (isLinux) {
            // For Linux, offer choice between software and hardware
            return 'linux-choice'; // Special case for Linux
        } else if (!platformAuthAvailable) {
            return 'cross-platform'; // Use security keys
        } else if (platformAuthAvailable) {
            return 'platform'; // Use biometrics
        } else {
            return 'universal'; // Let browser decide
        }
    }

    // Linux-specific choice between software and hardware authentication
    async getLinuxAuthenticationChoice() {
        // Check if browser supports software-based WebAuthn
        const canUseSoftware = this.isSupported();
        
        return new Promise((resolve) => {
            // More detailed dialog for Firefox users
            const isFirefox = this.isFirefox();
            const message = isFirefox ? 
                '🐧 Firefox on Linux Authentication:\n\n' +
                '💻 Browser Storage: No security key needed, stored in Firefox\n' +
                '🔑 Security Key: Requires physical FIDO2/U2F key\n\n' +
                'Click OK for Browser Storage (no key), Cancel for Security Key' :
                '🐧 Linux Authentication Choice:\n\n' +
                '✅ Software (Browser): More convenient, stored in browser\n' +
                '🔑 Hardware Key: Maximum security, requires physical key\n\n' +
                'Click OK for Software, Cancel for Hardware Key';
                
            if (confirm(message)) {
                resolve('software');
            } else {
                resolve('hardware');
            }
        });
    }

    // Firefox-specific workaround for software authentication
    async createSoftwareCredential(options) {
        // For Firefox on Linux, try to create credential without hardware prompts
        try {
            console.log('🦊 Attempting Firefox software credential creation...');
            
            // Remove any authenticator selection that might trigger hardware
            if (options.publicKey.authenticatorSelection) {
                delete options.publicKey.authenticatorSelection;
                console.log('🦊 Removed authenticatorSelection for Firefox compatibility');
            }
            
            // Add software-friendly authenticator selection
            options.publicKey.authenticatorSelection = {
                userVerification: "discouraged"  // NO PIN, biometric, or password required
            };
            
            // Ensure no hardware-specific extensions
            if (options.publicKey.extensions) {
                delete options.publicKey.extensions;
                console.log('🦊 Removed extensions for Firefox compatibility');
            }
            
            const credential = await navigator.credentials.create(options);
            return credential;
            
        } catch (error) {
            console.error('🦊 Firefox software credential failed:', error);
            throw error;
        }
    }

    // Register with automatic platform detection
    async register(options = {}) {
        if (this.inProgress) {
            console.log('WebAuthn operation already in progress, ignoring duplicate call');
            return { success: false, error: 'Operation in progress' };
        }

        this.inProgress = true;
        
        const {
            fetchFn = fetch,
            atobFn = atob,
            btoaFn = btoa,
            onStatus = () => {},
            onSuccess = () => {},
            onError = () => {},
            credentialsAPI = navigator.credentials
        } = options;

        try {
            // Collect username before starting registration
            let username = options.username;
            if (!username) {
                username = prompt('👤 Enter your username:');
                if (!username || username.trim() === '') {
                    throw new Error('Username is required for registration');
                }
                username = username.trim();
            }
            
            onStatus('Detecting platform...', 'info');
            
            // Determine registration strategy
            const strategy = this.getBestRegistrationStrategy();
            console.log(`🎯 Selected registration strategy: ${strategy}`);
            
            let endpoint = '/webauthn/register/begin';
            let linuxChoice = null;
            
            // Handle Linux-specific choice
            if (strategy === 'linux-choice') {
                linuxChoice = await this.getLinuxAuthenticationChoice();
                if (linuxChoice === 'software') {
                    endpoint = '/webauthn/register/begin/linux-software';
                } else {
                    endpoint = '/webauthn/register/begin/linux';
                }
            } else if (strategy === 'cross-platform') {
                endpoint = '/webauthn/register/begin/linux';
            } else if (strategy === 'universal') {
                endpoint = '/webauthn/register/begin/universal';
            }
            
            onStatus('Preparing registration...', 'info');
            
            // Add browser info for debugging
            const browserInfo = {
                userAgent: typeof window !== 'undefined' ? window.navigator.userAgent : '',
                isChrome: this.isChrome(),
                isFirefox: this.isFirefox(),
                isWindows: this.isWindows(),
                isMac: this.isMac(),
                isLinux: this.isLinux(),
                platform: typeof window !== 'undefined' ? window.navigator.platform : '',
                strategy: strategy,
                linuxChoice: linuxChoice
            };
            console.log('🔍 Browser Info:', browserInfo);
            
            // Get registration options from server
            const response = await fetchFn(endpoint, {
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
            
            // Provide strategy-specific user guidance
            if (strategy === 'linux-choice' && linuxChoice === 'software') {
                onStatus('Setting up browser-based authentication...', 'info');
            } else if (strategy === 'linux-choice' && linuxChoice === 'hardware') {
                onStatus('Insert your security key and follow the prompts', 'info');
            } else if (strategy === 'cross-platform') {
                onStatus('Insert your security key and follow the prompts', 'info');
            } else if (strategy === 'platform') {
                onStatus('Create your passkey using biometrics', 'info');
            } else {
                onStatus('Create your passkey', 'info');
            }
            
            onStatus('Create your passkey', 'info');
            
            // Convert base64 strings to ArrayBuffer
            options.publicKey.challenge = this.base64ToArrayBuffer(options.publicKey.challenge, atobFn);
            options.publicKey.user.id = this.base64ToArrayBuffer(options.publicKey.user.id, atobFn);
            
            try {
                // Create credential with platform-specific handling
                let credential;
                if (strategy === 'linux-choice' && linuxChoice === 'software' && this.isFirefox()) {
                    credential = await this.createSoftwareCredential(options);
                } else {
                    credential = await credentialsAPI.create(options);
                }
                
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
                    emoji: options.emoji || '👤'
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
                
                onStatus('Registration successful', 'success');
                onSuccess({ username, emoji: options.emoji || '👤' });
                return { success: true, username, emoji: options.emoji || '👤' };
                
            } catch (credentialError) {
                console.error('WebAuthn credential creation error:', credentialError);
                console.error('Error details:', {
                    name: credentialError.name,
                    message: credentialError.message,
                    stack: credentialError.stack
                });
                
                // Special handling for Firefox Linux software mode ONLY
                if (this.isFirefox() && this.isLinux() && strategy === 'linux-choice' && linuxChoice === 'software') {
                    if (credentialError.name === 'NotAllowedError') {
                        // Only try fallback if this seems like a genuine software authentication failure
                        if (credentialError.message && 
                            (credentialError.message.includes('security key') || 
                             credentialError.message.includes('authenticator') ||
                             credentialError.message.includes('U2F'))) {
                            
                            console.log('🦊 Firefox Linux: Detected hardware key prompt - attempting true software fallback...');
                            
                            try {
                                // Get fresh options with absolute minimum configuration
                                const firefoxResponse = await fetchFn('/webauthn/register/begin/linux-software', {
                                    method: 'POST',
                                    headers: { 'Content-Type': 'application/json' },
                                    body: JSON.stringify({ username })
                                });
                                
                                if (firefoxResponse.ok) {
                                    const firefoxOptions = await firefoxResponse.json();
                                    
                                    // Firefox Linux specific modifications
                                    firefoxOptions.publicKey.challenge = this.base64ToArrayBuffer(firefoxOptions.publicKey.challenge, atobFn);
                                    firefoxOptions.publicKey.user.id = this.base64ToArrayBuffer(firefoxOptions.publicKey.user.id, atobFn);
                                    
                                    // Try with manual credential creation bypassing Firefox's hardware detection
                                    const manualCredential = await this.createFirefoxLinuxCredential(firefoxOptions);
                                    
                                    if (manualCredential) {
                                        const verificationData = {
                                            id: manualCredential.id,
                                            rawId: this.arrayBufferToBase64(manualCredential.rawId, btoaFn),
                                            response: {
                                                attestationObject: this.arrayBufferToBase64(manualCredential.response.attestationObject, btoaFn),
                                                clientDataJSON: this.arrayBufferToBase64(manualCredential.response.clientDataJSON, btoaFn)
                                            },
                                            type: manualCredential.type,
                                            username,
                                            emoji: options.emoji || '👤'
                                        };
                                        
                                        const verificationResponse = await fetchFn('/webauthn/register/complete', {
                                            method: 'POST',
                                            headers: { 'Content-Type': 'application/json' },
                                            body: JSON.stringify(verificationData)
                                        });
                                        
                                        if (verificationResponse.ok) {
                                            onStatus('🦊 Firefox Linux software authentication successful!', 'success');
                                            onSuccess({ username, emoji: options.emoji || '👤' });
                                            return { success: true, username, emoji: options.emoji || '👤' };
                                        }
                                    }
                                }
                            } catch (firefoxError) {
                                console.error('🦊 Firefox Linux fallback failed:', firefoxError);
                            }
                        }
                        
                        throw new Error('🦊 Firefox Linux Software Mode Failed\n\nFirefox on Linux may not support pure software authentication.\n\nTry:\n1. Chrome/Chromium browser (better Linux support)\n2. Use hardware security key option instead\n3. Disconnect any USB security keys and retry');
                    }
                }
                
                // Handle other browser-specific errors
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
            
            // Prepare request body - send null for usernameless authentication
            const requestBody = username === null ? {} : { username: username };
            
            const optionsResponse = await fetchFn('/webauthn/authenticate/begin', {
                method: 'POST',
                headers: { 'Content-Type': 'application/json' },
                body: JSON.stringify(requestBody)
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
                }
            };
            
            // Only include username in credential if it was provided
            if (username !== null) {
                credential.username = username;
            }
            
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

    // Firefox Linux specific credential creation
    async createFirefoxLinuxCredential(options) {
        // Firefox Linux specific workaround
        try {
            console.log('🦊 Firefox Linux: Attempting TRUE software-only authentication...');
            
            // For Firefox Linux, completely remove authenticatorSelection
            // This forces Firefox to use whatever is available without hardware preference
            const cleanOptions = {
                publicKey: {
                    challenge: options.publicKey.challenge,
                    rp: options.publicKey.rp,
                    user: options.publicKey.user,
                    pubKeyCredParams: options.publicKey.pubKeyCredParams,
                    timeout: 30000,  // Shorter timeout
                    attestation: "none"
                    // NO authenticatorSelection AT ALL - let Firefox choose software
                    // NO extensions
                    // NO userVerification settings
                }
            };
            
            console.log('🦊 Firefox Linux: Using completely minimal options (no authenticator restrictions)', cleanOptions);
            
            // Try with navigator.credentials.create directly
            const credential = await navigator.credentials.create(cleanOptions);
            
            console.log('🦊 Firefox Linux: Successfully created software credential!');
            return credential;
            
        } catch (error) {
            console.error('🦊 Firefox Linux credential creation failed:', error);
            return null;
        }
    }
}

// Export the WebAuthn client class
const webAuthnClient = new WebAuthnClient(); 