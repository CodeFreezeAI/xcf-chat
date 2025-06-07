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
        return navigator.userAgent.includes('Chrome'); //&& !navigator.userAgent.includes('Edg');
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
        
        let strategy = 'default';
        let linuxChoice = null;
        
        if (this.isLinux()) {
            if (this.isFirefox()) {
                // Firefox on Linux: Use hardware key automatically (works well)
                strategy = 'linux-hardware';
                console.log('🐧 Firefox on Linux detected - using hardware security key mode');
            } else {
                // All other browsers on Linux: Use software authentication
                strategy = 'linux-software';
                console.log('🐧 Linux detected - using browser-based authentication');
            }
        } else if (this.isWindows()) {
            strategy = 'windows';
            console.log('�� Windows detected - using Windows authenticators');
        } else if (this.isMac()) {
            strategy = 'mac';
            console.log('🖥️ Mac detected - preparing Touch ID registration');
        } else if (!platformAuthAvailable) {
            strategy = 'cross-platform'; // Use security keys
        } else if (platformAuthAvailable) {
            strategy = 'platform'; // Use biometrics
        } else {
            strategy = 'universal'; // Let browser decide
        }
        
        return { strategy, linuxChoice };
    }

    // Firefox-specific workaround for software authentication
    async createSoftwareCredential(options) {
        // For non-Firefox browsers on Linux - browser-stored credentials
        try {
            console.log('🐧 Attempting Linux software credential creation...');
            
            // Remove any authenticator selection that might trigger hardware
            if (options.publicKey.authenticatorSelection) {
                delete options.publicKey.authenticatorSelection;
                console.log('🐧 Removed authenticatorSelection for Linux compatibility');
            }
            
            // Add software-friendly authenticator selection
            options.publicKey.authenticatorSelection = {
                userVerification: "discouraged"  // NO PIN, biometric, or password required
            };
            
            // Ensure no hardware-specific extensions
            if (options.publicKey.extensions) {
                delete options.publicKey.extensions;
                console.log('🐧 Removed extensions for Linux compatibility');
            }
            
            const credential = await navigator.credentials.create(options);
            return credential;
            
        } catch (error) {
            console.error('🐧 Linux software credential failed:', error);
            throw error;
        }
    }

    // Register with automatic platform detection
    async register(username, emoji = '👤', callbacks = {}, browserAPI = {}) {
        console.log(`🚀 WebAuthn registration started for username: "${username}"`);
        
        // Destructure callbacks early to ensure they're always available
        const { onStatus = () => {}, onError = () => {}, onSuccess = () => {} } = callbacks;
        
        // FIRST CHECK: Validate username for ALL flows and browsers
        if (!username || username.trim() === '') {
            onStatus('Username required for registration', 'error');
            const error = new Error('Username Required\n\nPlease enter a username before registering.');
            onError(error.message);
            throw error;
        }
        
        // Clean username
        username = username.trim();
        console.log(`🧹 Cleaned username: "${username}"`);
        
        try {
            if (this.inProgress) {
                console.log('WebAuthn operation already in progress, ignoring duplicate call');
                const error = 'Operation in progress';
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
            
            onStatus('Checking username availability...', 'info');
            
            // Check if username is available before proceeding
            console.log(`🔍 Checking username availability for: "${username}"`);
            const usernameCheckResponse = await fetchFn('/webauthn/username/check', {
                method: 'POST',
                headers: { 'Content-Type': 'application/json' },
                body: JSON.stringify({ username })
            });
            
            console.log(`🔍 Username check response status: ${usernameCheckResponse.status}`);
            
            if (!usernameCheckResponse.ok) {
                console.error('❌ Username check failed with status:', usernameCheckResponse.status);
                throw new Error('Failed to check username availability');
            }
            
            const usernameResult = await usernameCheckResponse.json();
            console.log(`🔍 Username check result:`, usernameResult);
            
            if (!usernameResult.available) {
                console.log(`❌ Username "${username}" is already taken`);
                onStatus('Username already taken', 'error');
                throw new Error('Username Already Taken\n\nPlease choose a different username.');
            }
            
            console.log(`✅ Username "${username}" is available`);
            onStatus('Starting registration...', 'info');
            
            // Determine best registration strategy
            const { strategy, linuxChoice } = await this.getBestRegistrationStrategy();
            console.log(`🎯 Selected registration strategy: ${strategy}`);
            
            let endpoint = '/webauthn/register/begin';
            
            // Select appropriate endpoint based on strategy
            if (strategy === 'linux-hardware') {
                endpoint = '/webauthn/register/begin/linux';  // Hardware security key endpoint
            } else if (strategy === 'linux-software') {
                endpoint = '/webauthn/register/begin/linux-software';  // Software browser endpoint
            } else if (strategy === 'windows') {
                endpoint = '/webauthn/register/begin';  // Windows Hello compatible
            } else if (strategy === 'cross-platform') {
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
            if (strategy === 'linux-hardware') {
                onStatus('🐧🦊 Firefox Linux: Insert your security key and follow the prompts', 'info');
            } else if (strategy === 'linux-software') {
                onStatus('🐧 Linux: Setting up browser-based authentication...', 'info');
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
                if (strategy === 'linux-software' && !this.isFirefox()) {
                    // Only non-Firefox browsers on Linux use software credentials
                    credential = await this.createSoftwareCredential(options);
                } else {
                    // All other cases including Firefox on Linux (hardware keys)
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
                
                // Handle user cancellation FIRST
                if (credentialError.name === 'AbortError') {
                    onStatus('Registration cancelled by user', 'error');
                    throw new Error('Registration Cancelled\n\nYou cancelled the registration process.');
                }
                
                // Handle other specific errors
                if (credentialError.name === 'NotAllowedError') {
                    onStatus('Registration not allowed', 'error');
                    if (this.isChrome()) {
                        throw new Error('Chrome WebAuthn Issue\nYour device may not be compatible\nTry Firefox or Edge browser');
                    } else if (this.isWindows()) {
                        throw new Error('Windows Hello Registration Failed\nPlease check Windows Hello setup\nSettings > Accounts > Sign-in options');
                    } else if (credentialError.message && credentialError.message.includes('device')) {
                        throw new Error('Device Not Compatible\nYour device may not support this\nTry a different browser or device');
                    } else {
                        throw new Error('Registration Not Allowed\nCheck browser permissions\nand privacy settings');
                    }
                } else if (credentialError.name === 'InvalidStateError') {
                    onStatus('Already registered', 'error');
                    throw new Error('Already Registered\nThis device is already registered\nTry logging in instead');
                } else if (credentialError.name === 'SecurityError') {
                    onStatus('Security error', 'error');
                    throw new Error('Security Error\nPlease ensure secure connection\n(HTTPS required)');
                } else if (credentialError.name === 'TimeoutError') {
                    onStatus('Registration timeout', 'error');
                    throw new Error('Registration Timeout\nPlease try again\nCheck authenticator response');
                } else {
                    onStatus('Registration failed', 'error');
                    throw credentialError;
                }
            }
            
        } catch (error) {
            console.error('WebAuthn registration error:', error);
            
            // Handle specific error messages that are already formatted
            if (error.message && (
                error.message.includes('Username Already Taken') ||
                error.message.includes('Registration Cancelled') ||
                error.message.includes('Chrome WebAuthn Issue') ||
                error.message.includes('Windows Hello Registration Failed') ||
                error.message.includes('Device Not Compatible') ||
                error.message.includes('Registration Not Allowed') ||
                error.message.includes('Already Registered') ||
                error.message.includes('Security Error') ||
                error.message.includes('Registration Timeout')
            )) {
                onError(error.message);
                return { success: false, error: error.message };
            }
            
            // Handle other errors
            let errorMsg = 'Registration failed';
            if (error.message && error.message.includes('username availability')) {
                errorMsg = 'Failed to check username availability - please try again';
            } else if (error.message && error.message.includes('not allowed')) {
                errorMsg = 'Registration not allowed - check privacy settings';
            } else if (error.message) {
                errorMsg = error.message;
            }
            
            onError(errorMsg);
            return { success: false, error: errorMsg };
        } finally {
            this.inProgress = false;
        }
    }

    // Authenticate with existing WebAuthn credential - with fallback support
    async authenticate(username = null, callbacks = {}, browserAPI = {}) {
        // Destructure callbacks early to ensure they're always available
        const { onStatus = () => {}, onError = () => {}, onSuccess = () => {} } = callbacks;
        
        if (this.inProgress) {
            console.log('WebAuthn operation already in progress, ignoring duplicate call');
            const error = 'Operation in progress';
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
            onStatus('Preparing passkey login...', 'info');
            
            // Only try passkey authentication (no automatic fallback to security keys)
            const passkeyResult = await this.tryPasskeyAuthentication(username, { onStatus, onError, onSuccess }, { fetchFn, atobFn, btoaFn, credentialsAPI });
            if (passkeyResult.success) {
                return passkeyResult;
            }
            
            // If passkey authentication failed, return specific error
            const error = 'No passkey credentials available\nTry using the "Use Security Key" button\nor register a new credential';
            onError(error);
            return { success: false, error };
            
        } catch (error) {
            console.error('WebAuthn passkey authentication error:', error);
            
            // Handle specific error cases with multi-line messages
            let errorMessage = 'Passkey authentication failed';
            if (error.message === 'User cancelled' || 
                error.name === 'NotAllowedError' ||
                error.message.includes('cancelled') ||
                error.message.includes('abort')) {
                errorMessage = 'Passkey Authentication Cancelled\nPlease try again when ready';
            } else if (error.name === 'SecurityError') {
                errorMessage = 'Security Error\nPlease ensure secure connection\n(HTTPS required)';
            } else if (error.name === 'TimeoutError') {
                errorMessage = 'Passkey Authentication Timeout\nPlease try again\nCheck authenticator response';
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

    // Try authentication with security keys (cross-platform authenticators)
    async trySecurityKeyAuthentication(username, callbacks, browserAPI) {
        const { onStatus, onError, onSuccess } = callbacks;
        const { fetchFn, atobFn, btoaFn, credentialsAPI } = browserAPI;
        
        try {
            console.log('🔑 Attempting security key authentication...');
            
            // Check browser support first
            const isSafari = /^((?!chrome|android).)*safari/i.test(navigator.userAgent);
            if (isSafari) {
                console.log('🍎 Safari detected - checking WebAuthn support...');
                if (!window.PublicKeyCredential) {
                    const error = 'Safari WebAuthn not supported\nPlease update Safari or use Chrome';
                    onError(error);
                    return { success: false, error };
                }
                onStatus('Safari: Insert your security key and touch when it blinks...', 'info');
            } else {
                onStatus('Insert your security key...', 'info');
            }
            
            // Prepare request body - FORCE security key only by telling server
            const requestBody = username === null ? { securityKeyOnly: true } : { username: username, securityKeyOnly: true };
            
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
                return { success: false, error: 'Server error - invalid options' };
            }
            
            // Convert challenge to ArrayBuffer
            options.publicKey.challenge = this.base64ToArrayBuffer(options.publicKey.challenge, atobFn);
            
            // CRITICAL: Filter credentials to ONLY security keys (remove Touch ID/passkeys)
            if (options.publicKey.allowCredentials) {
                console.log('🔑 Original credentials:', options.publicKey.allowCredentials.length);
                
                // Convert credentials and prepare for security key only
                options.publicKey.allowCredentials = options.publicKey.allowCredentials.map(cred => ({
                    ...cred,
                    id: this.base64ToArrayBuffer(cred.id, atobFn)
                }));
                
                console.log('🔑 Security key credentials ready:', options.publicKey.allowCredentials.length);
            } else {
                console.log('🔑 No allowCredentials - using usernameless security key auth');
            }
            
            // Modify options to prefer cross-platform authenticators (security keys)
            options.publicKey.timeout = 30000; // 30 seconds for security key
            
            // Safari-specific options for security keys
            
            let securityKeyOptions = {
                ...options.publicKey,
                userVerification: 'discouraged' // Don't require PIN for security keys
            };
            
            // Safari-specific handling - NUCLEAR OPTION: Force security key only
            if (isSafari) {
                console.log('🍎 Safari detected: SECURITY KEY ONLY MODE');
                
                // Safari requires specific configuration to properly prompt for YubiKey
                securityKeyOptions = {
                    challenge: options.publicKey.challenge,
                    timeout: 120000, // Extra long timeout for YubiKey insertion
                    rpId: options.publicKey.rpId,
                    userVerification: 'discouraged',
                    allowCredentials: [], // Empty array forces Safari to prompt for any external authenticator
                    authenticatorSelection: {
                        authenticatorAttachment: 'cross-platform',
                        userVerification: 'discouraged'
                    }
                };
                
                console.log('🍎 Safari: Security key options configured for external authenticator');
                onStatus('Safari: Insert and touch your YubiKey when it blinks...', 'info');
                
                // Add a small delay before calling get() to ensure Safari is ready
                await new Promise(resolve => setTimeout(resolve, 100));
                
            }
            
            console.log('🔑 Security key options:', securityKeyOptions);
            
            // Try to get assertion with security key preference
            const assertion = await credentialsAPI.get({ 
                publicKey: securityKeyOptions
            });
            
            if (!assertion) {
                return { success: false, error: 'Security key authentication cancelled' };
            }
            
            onStatus('Verifying security key...', 'info');
            
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
                console.log('✅ Security key authentication successful');
                onStatus('Security key login successful', 'success');
                onSuccess({ username: result.username || username, method: 'security-key' });
                return { success: true, username: result.username || username, method: 'security-key' };
            } else {
                console.log('❌ Security key verification failed:', result.error);
                return { success: false, error: result.error || 'Security key verification failed' };
            }
            
        } catch (error) {
            console.log('🔑 Security key authentication failed:', error.name, error.message);
            
            // Enhanced Safari error handling
            const isSafariBrowser = /^((?!chrome|android).)*safari/i.test(navigator.userAgent);
            
            let errorMessage = error.message;
            if (isSafariBrowser) {
                console.log('🍎 Safari security key error:', error);
                if (error.name === 'NotAllowedError') {
                    errorMessage = 'Safari Security Key Error\nPlease ensure:\n1. Security key is inserted\n2. You have registered with this key\n3. Touch the key when it blinks';
                } else if (error.name === 'NotSupportedError') {
                    errorMessage = 'Safari does not support this security key\nTry using a different key or browser';
                } else if (error.name === 'InvalidStateError') {
                    errorMessage = 'Security key in invalid state\nPlease remove and reinsert the key';
                }
                onError(errorMessage);
            }
            
            // Don't show errors for expected failures in other browsers
            if (error.name === 'NotAllowedError' && error.message.includes('not allowed')) {
                return { success: false, error: 'No security key credentials found' };
            }
            
            return { success: false, error: errorMessage };
        }
    }

    // Try authentication with passkeys (platform authenticators)
    async tryPasskeyAuthentication(username, callbacks, browserAPI) {
        const { onStatus, onError, onSuccess } = callbacks;
        const { fetchFn, atobFn, btoaFn, credentialsAPI } = browserAPI;
        
        try {
            console.log('🔐 Attempting passkey authentication...');
            onStatus('Authenticate with your passkey...', 'info');
            
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
                return { success: false, error: 'Server error - invalid options' };
            }
            
            // Convert challenge to ArrayBuffer
            options.publicKey.challenge = this.base64ToArrayBuffer(options.publicKey.challenge, atobFn);
            // Convert each allowCredentials id to ArrayBuffer
            if (options.publicKey.allowCredentials) {
                options.publicKey.allowCredentials = options.publicKey.allowCredentials.map(cred => ({
                    ...cred,
                    id: this.base64ToArrayBuffer(cred.id, atobFn)
                }));
            }
            
            // Modify options to prefer platform authenticators (passkeys)
            options.publicKey.timeout = 60000; // 60 seconds for passkeys
            
            const assertion = await credentialsAPI.get({ publicKey: options.publicKey });
            
            if (!assertion) {
                return { success: false, error: 'Passkey authentication cancelled' };
            }
            
            onStatus('Verifying passkey...', 'info');
            
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
                console.log('✅ Passkey authentication successful');
                onStatus('Passkey login successful', 'success');
                onSuccess({ username: result.username || username, method: 'passkey' });
                return { success: true, username: result.username || username, method: 'passkey' };
            } else {
                console.log('❌ Passkey verification failed:', result.error);
                return { success: false, error: result.error || 'Passkey verification failed' };
            }
            
        } catch (error) {
            console.log('🔐 Passkey authentication failed:', error.message);
            return { success: false, error: error.message };
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
            console.log('🦊 Firefox Linux: Attempting bypass of hardware detection...');
            
            // Strip out ALL possible hardware triggers for Firefox Linux
            const cleanOptions = {
                publicKey: {
                    challenge: options.publicKey.challenge,
                    rp: options.publicKey.rp,
                    user: options.publicKey.user,
                    pubKeyCredParams: options.publicKey.pubKeyCredParams,
                    timeout: 30000,  // Shorter timeout
                    attestation: "none",
                    authenticatorSelection: {
                        userVerification: "discouraged"  // NO PIN, biometric, or password required
                    }
                    // Absolutely NO authenticatorAttachment restriction
                    // Absolutely NO extensions
                    // Absolutely NO residentKey requirements
                }
            };
            
            console.log('🦊 Firefox Linux: Using ultra-minimal options', cleanOptions);
            
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

// Export for Node.js testing
if (typeof module !== 'undefined' && module.exports) {
    module.exports = { WebAuthnClient, webAuthnClient };
}

// Make available globally for browser use
if (typeof window !== 'undefined') {
    window.webAuthnClient = webAuthnClient;
} else if (typeof global !== 'undefined') {
    global.webAuthnClient = webAuthnClient;
} 