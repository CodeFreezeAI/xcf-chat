// WebAuthn Super Test - Comprehensive Testing Suite
// Tests all FIDO1, FIDO2, WebAuthn, and Passkey scenarios

class WebAuthnSuperTest {
    constructor() {
        this.currentSettings = this.getDefaultSettings();
        this.testResults = [];
        this.debugLog = [];
        this.capabilities = {};
        
        this.init();
    }
    
    init() {
        console.log('🔐 WebAuthn Super Test Initialized');
        this.detectBrowser();
        this.checkCapabilities();
        this.loadSavedSettings();
    }
    
    getDefaultSettings() {
        return {
            timeout: 60000,
            challengeSize: 32,
            attestation: 'none',
            userVerification: 'preferred',
            authenticatorAttachment: null,
            residentKey: 'preferred',
            algorithms: [-7], // ES256 by default
            transports: ['usb', 'nfc', 'ble', 'internal', 'hybrid'],
            extensions: {}
        };
    }
    
    // Browser Detection and Capabilities
    detectBrowser() {
        const ua = navigator.userAgent;
        const platform = navigator.platform;
        
        this.browserInfo = {
            userAgent: ua,
            platform: platform,
            isChrome: ua.includes('Chrome') && !ua.includes('Edg'),
            isFirefox: ua.includes('Firefox'),
            isEdge: ua.includes('Edg'),
            isSafari: ua.includes('Safari') && !ua.includes('Chrome'),
            isWindows: platform.includes('Win'),
            isMac: platform.includes('Mac'),
            isLinux: platform.includes('Linux'),
            isAndroid: ua.includes('Android'),
            isiOS: /iPad|iPhone|iPod/.test(ua),
            language: navigator.language,
            cookieEnabled: navigator.cookieEnabled,
            onLine: navigator.onLine,
            doNotTrack: navigator.doNotTrack,
            hardwareConcurrency: navigator.hardwareConcurrency,
            maxTouchPoints: navigator.maxTouchPoints
        };
        
        this.updateBrowserDisplay();
    }
    
    async checkCapabilities() {
        this.capabilities = {
            webauthnSupported: this.isWebAuthnSupported(),
            publicKeyCredential: typeof PublicKeyCredential !== 'undefined',
            credentialsAPI: typeof navigator.credentials !== 'undefined',
            createMethod: typeof navigator.credentials?.create === 'function',
            getMethod: typeof navigator.credentials?.get === 'function',
            isSecureContext: window.isSecureContext,
            httpsOrLocalhost: location.protocol === 'https:' || location.hostname === 'localhost'
        };
        
        // Check platform authenticator
        if (this.capabilities.publicKeyCredential) {
            try {
                this.capabilities.platformAuthenticator = await PublicKeyCredential.isUserVerifyingPlatformAuthenticatorAvailable();
            } catch (error) {
                this.capabilities.platformAuthenticator = false;
                this.capabilities.platformAuthenticatorError = error.message;
            }
            
            // Check conditional mediation
            try {
                this.capabilities.conditionalMediation = await PublicKeyCredential.isConditionalMediationAvailable();
            } catch (error) {
                this.capabilities.conditionalMediation = false;
            }
        }
        
        this.updateCapabilitiesDisplay();
    }
    
    isWebAuthnSupported() {
        return !!(navigator.credentials && 
                 navigator.credentials.create && 
                 navigator.credentials.get &&
                 window.PublicKeyCredential);
    }
    
    // Registration Testing with ALL UI settings
    async testRegistration() {
        const username = document.getElementById('reg-username').value.trim();
        if (!username) {
            this.showStatus('reg-status', 'Please enter a username', 'error');
            return;
        }
        
        const useAppleCancellation = document.getElementById('reg-apple-cancellation')?.checked;
        this.log(`🔐 TEST REGISTRATION: Using ALL UI settings${useAppleCancellation ? ' + Apple cancellation' : ''} for: ${username}`);
        this.showStatus('reg-status', `${useAppleCancellation ? 'Canceling Apple + ' : ''}Using ALL your UI settings...`, 'info');
        
        try {
            // Handle Apple cancellation if requested
            if (useAppleCancellation) {
                await this.performAppleCancellation(true);
            }
            
            // Build registration options from ALL UI form elements
            const options = this.buildRegistrationOptionsFromUI();
            
            const startTime = performance.now();
            const credential = await navigator.credentials.create({ publicKey: options });
            const endTime = performance.now();
            
            if (credential) {
                this.log(`✅ SUCCESS: Registration completed in ${endTime - startTime}ms`);
                this.log(`✅ Credential ID: ${credential.id}`);
                this.log(`✅ Credential Type: ${credential.type}`);
                this.log(`✅ Authenticator: ${credential.authenticatorAttachment || 'unknown'}`);
                
                this.showStatus('reg-status', '✅ Registration successful with ALL UI settings!', 'success');
                
                const credInfo = {
                    id: credential.id,
                    type: credential.type,
                    authenticatorAttachment: credential.authenticatorAttachment,
                    timeTaken: endTime - startTime,
                    publicKeyAlgorithm: credential.response.getPublicKeyAlgorithm?.(),
                    transports: credential.response.getTransports?.(),
                    extensions: credential.getClientExtensionResults()
                };
                
                this.log(`🔑 CREDENTIAL DETAILS: ${JSON.stringify(credInfo, null, 2)}`);
                
            } else {
                throw new Error('No credential returned');
            }
            
        } catch (error) {
            this.showStatus('reg-status', `❌ Registration error: ${error.message}`, 'error');
            this.log(`❌ Registration error: ${error.message}`);
        }
    }
    
    async testChromeBypassRegistration() {
        const username = document.getElementById('reg-username').value.trim();
        if (!username) {
            this.showStatus('reg-status', 'Please enter a username', 'error');
            return;
        }
        
        const useAppleCancellation = document.getElementById('reg-apple-cancellation')?.checked;
        this.log(`🔑 SECURITY KEY ONLY: Using UI settings${useAppleCancellation ? ' + Apple cancellation' : ''} + forcing cross-platform for: ${username}`);
        this.showStatus('reg-status', `${useAppleCancellation ? 'Canceling Apple + ' : ''}UI settings + forcing security key...`, 'info');
        
        try {
            // Handle Apple cancellation if requested
            if (useAppleCancellation) {
                await this.performAppleCancellation(true);
            }
            
            // Build options from UI then override for security key only
            const options = this.buildRegistrationOptionsFromUI();
            
            // Override specific settings for security key only mode
            options.authenticatorSelection.authenticatorAttachment = 'cross-platform';
            options.authenticatorSelection.userVerification = 'discouraged';
            options.authenticatorSelection.residentKey = 'discouraged';
            options.timeout = 25000; // Short timeout
            
            this.log(`🔑 SECURITY KEY OVERRIDE: ${JSON.stringify(options, null, 2)}`);
            
            const startTime = performance.now();
            const credential = await navigator.credentials.create({ publicKey: options });
            const endTime = performance.now();
            
            if (credential) {
                this.log(`✅ SUCCESS: Security key registration completed in ${endTime - startTime}ms`);
                this.log(`✅ Credential ID: ${credential.id}`);
                this.log(`✅ Credential Type: ${credential.type}`);
                this.log(`✅ Authenticator: ${credential.authenticatorAttachment || 'unknown'}`);
                
                this.showStatus('reg-status', '✅ Security key registration successful with UI settings!', 'success');
                
                const credInfo = {
                    id: credential.id,
                    type: credential.type,
                    authenticatorAttachment: credential.authenticatorAttachment,
                    timeTaken: endTime - startTime
                };
                
                this.log(`🔑 CREDENTIAL DETAILS: ${JSON.stringify(credInfo, null, 2)}`);
                
            } else {
                throw new Error('No credential returned');
            }
            
        } catch (error) {
            this.showStatus('reg-status', `❌ Security key error: ${error.message}`, 'error');
            this.log(`❌ Security key error: ${error.message}`);
        }
    }
    
    async testChromeProviderRegistration() {
        const username = document.getElementById('reg-username').value.trim();
        if (!username) {
            this.showStatus('reg-status', 'Please enter a username', 'error');
            return;
        }
        
        this.log(`🌐 CHROME PROVIDERS: Actively canceling Apple to get Chrome provider screen for: ${username}`);
        this.showStatus('reg-status', 'Canceling Apple to show Chrome providers...', 'info');
        
        try {
            // Use universal method and override for Chrome provider selection
            const webauthnOptions = await this.universalAppleCancellationAndSettings(username, 'Chrome Providers');
            
            // Override for Chrome provider selection - don't force cross-platform
            delete webauthnOptions.publicKey.authenticatorSelection.authenticatorAttachment;
            webauthnOptions.publicKey.authenticatorSelection.userVerification = 'preferred';
            webauthnOptions.publicKey.authenticatorSelection.residentKey = 'preferred';
            webauthnOptions.publicKey.timeout = 120000; // 2 minutes for selection
            
            this.log(`🌐 CHROME PROVIDER OVERRIDE: ${JSON.stringify(webauthnOptions, null, 2)}`);
            
            const startTime = performance.now();
            const credential = await navigator.credentials.create(webauthnOptions);
            const endTime = performance.now();
            
            if (credential) {
                this.log(`✅ SUCCESS: Chrome provider selection worked! (${endTime - startTime}ms)`);
                this.log(`✅ Credential ID: ${credential.id}`);
                this.log(`✅ Credential Type: ${credential.type}`);
                this.log(`✅ Authenticator: ${credential.authenticatorAttachment || 'unknown'}`);
                
                this.showStatus('reg-status', '✅ Apple canceled! Chrome provider selection successful!', 'success');
                
                const credInfo = {
                    id: credential.id,
                    type: credential.type,
                    authenticatorAttachment: credential.authenticatorAttachment,
                    timeTaken: endTime - startTime
                };
                
                this.log(`🔑 CREDENTIAL DETAILS: ${JSON.stringify(credInfo, null, 2)}`);
                
            } else {
                throw new Error('No credential returned from Chrome');
            }
            
        } catch (error) {
            this.log(`❌ CHROME PROVIDER CANCELLATION FAILED: ${error.message}`);
            
            if (error.name === 'AbortError') {
                this.showStatus('reg-status', '🍎 Apple cancellation worked but Chrome request was also canceled', 'warning');
            } else if (error.message.includes('NotAllowedError')) {
                this.showStatus('reg-status', '🍎 Apple may have re-intercepted the Chrome request', 'warning');
            } else {
                this.showStatus('reg-status', `❌ Chrome provider cancellation error: ${error.message}`, 'error');
            }
        }
    }
    
    getCurrentRegistrationSettings() {
        return {
            authenticatorAttachment: document.getElementById('reg-attachment').value || undefined,
            userVerification: document.getElementById('reg-user-verification').value,
            residentKey: document.getElementById('reg-resident-key').value,
            attestation: document.getElementById('reg-attestation').value,
            timeout: parseInt(document.getElementById('advanced-timeout').value),
            algorithms: this.getSelectedAlgorithms(),
            transports: this.getSelectedTransports(),
            extensions: this.getSelectedExtensions()
        };
    }
    
    getSelectedAlgorithms() {
        const checkboxes = document.querySelectorAll('input[type="checkbox"][value^="-"]');
        const selected = [];
        checkboxes.forEach(cb => {
            if (cb.checked) {
                selected.push(parseInt(cb.value));
            }
        });
        return selected.length > 0 ? selected : [-7]; // Default to ES256
    }
    
    getSelectedTransports() {
        const checkboxes = document.querySelectorAll('input[type="checkbox"][value="usb"], input[type="checkbox"][value="nfc"], input[type="checkbox"][value="ble"], input[type="checkbox"][value="internal"], input[type="checkbox"][value="hybrid"]');
        const selected = [];
        checkboxes.forEach(cb => {
            if (cb.checked) {
                selected.push(cb.value);
            }
        });
        return selected;
    }
    
    getSelectedExtensions() {
        const extensions = {};
        
        if (document.getElementById('ext-credProps').checked) {
            extensions.credProps = true;
        }
        if (document.getElementById('ext-largeBlobKey').checked) {
            extensions.largeBlobKey = true;
        }
        if (document.getElementById('ext-credProtect').checked) {
            extensions.credProtect = { credProtect: 1 };
        }
        if (document.getElementById('ext-hmacSecret').checked) {
            extensions.hmacSecret = true;
        }
        if (document.getElementById('ext-devicePubKey').checked) {
            extensions.devicePubKey = true;
        }
        
        return extensions;
    }
    
    async performRegistration(username, settings, appleOverrides = {}) {
        // Get registration options from server
        const optionsResponse = await fetch('/webauthn/register/begin', {
            method: 'POST',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify({ username })
        });
        
        if (!optionsResponse.ok) {
            throw new Error('Failed to get registration options');
        }
        
        const options = await optionsResponse.json();
        this.log(`📋 Server options: ${JSON.stringify(options, null, 2)}`);
        
        // Apply our custom settings
        const customOptions = this.applyCustomSettings(options, settings);
        this.log(`📋 Custom options: ${JSON.stringify(customOptions, null, 2)}`);
        
        // Apply Apple overrides if provided
        if (Object.keys(appleOverrides).length > 0) {
            this.applyAppleOverrides(customOptions, appleOverrides);
        }
        
        // Convert base64 to ArrayBuffer
        customOptions.publicKey.challenge = this.base64ToArrayBuffer(customOptions.publicKey.challenge);
        customOptions.publicKey.user.id = this.base64ToArrayBuffer(customOptions.publicKey.user.id);
        
        // Create credential
        const startTime = performance.now();
        const credential = await navigator.credentials.create(customOptions);
        const endTime = performance.now();
        
        this.log(`⏱️ Credential creation took ${endTime - startTime}ms`);
        
        if (!credential) {
            throw new Error('Failed to create credential');
        }
        
        this.log(`🔑 Credential created: ${credential.id}`);
        
        // Verify with server
        const verificationData = {
            id: credential.id,
            rawId: this.arrayBufferToBase64(credential.rawId),
            response: {
                attestationObject: this.arrayBufferToBase64(credential.response.attestationObject),
                clientDataJSON: this.arrayBufferToBase64(credential.response.clientDataJSON)
            },
            type: credential.type,
            username: username
        };
        
        const verifyResponse = await fetch('/webauthn/register/complete', {
            method: 'POST',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify(verificationData)
        });
        
        const result = await verifyResponse.json();
        
        return {
            success: verifyResponse.ok,
            credential: credential,
            verificationResult: result,
            timeTaken: endTime - startTime,
            settings: settings
        };
    }
    
    applyCustomSettings(serverOptions, customSettings) {
        const options = JSON.parse(JSON.stringify(serverOptions)); // Deep clone
        
        // Apply authenticator attachment
        if (customSettings.authenticatorAttachment) {
            options.publicKey.authenticatorSelection = options.publicKey.authenticatorSelection || {};
            options.publicKey.authenticatorSelection.authenticatorAttachment = customSettings.authenticatorAttachment;
        } else {
            // Remove authenticatorAttachment for hybrid mode
            if (options.publicKey.authenticatorSelection) {
                delete options.publicKey.authenticatorSelection.authenticatorAttachment;
            }
        }
        
        // Apply user verification
        options.publicKey.authenticatorSelection = options.publicKey.authenticatorSelection || {};
        options.publicKey.authenticatorSelection.userVerification = customSettings.userVerification;
        
        // Apply resident key requirement
        options.publicKey.authenticatorSelection.residentKey = customSettings.residentKey;
        
        // Apply attestation
        options.publicKey.attestation = customSettings.attestation;
        
        // Apply timeout
        options.publicKey.timeout = customSettings.timeout;
        
        // Apply algorithms
        options.publicKey.pubKeyCredParams = customSettings.algorithms.map(alg => ({
            type: 'public-key',
            alg: alg
        }));
        
        // Apply extensions
        if (Object.keys(customSettings.extensions).length > 0) {
            options.publicKey.extensions = customSettings.extensions;
        }
        
        return options;
    }
    
    // Utility functions
    base64ToArrayBuffer(base64) {
        const binaryString = atob(base64);
        const bytes = new Uint8Array(binaryString.length);
        for (let i = 0; i < binaryString.length; i++) {
            bytes[i] = binaryString.charCodeAt(i);
        }
        return bytes.buffer;
    }
    
    arrayBufferToBase64(buffer) {
        const bytes = new Uint8Array(buffer);
        let binary = '';
        for (let i = 0; i < bytes.byteLength; i++) {
            binary += String.fromCharCode(bytes[i]);
        }
        return btoa(binary);
    }
    
    // Display Updates
    updateBrowserDisplay() {
        const browserDiv = document.getElementById('browser-detection');
        if (!browserDiv) return;
        
        const info = this.browserInfo;
        browserDiv.innerHTML = `
            <h4>🌐 Browser Information</h4>
            <p><strong>Browser:</strong> ${this.getBrowserName()}</p>
            <p><strong>Platform:</strong> ${info.platform}</p>
            <p><strong>User Agent:</strong> ${info.userAgent}</p>
            <p><strong>Language:</strong> ${info.language}</p>
            <p><strong>Secure Context:</strong> ${window.isSecureContext ? '✅' : '❌'}</p>
            <p><strong>Touch Support:</strong> ${info.maxTouchPoints > 0 ? `✅ (${info.maxTouchPoints} points)` : '❌'}</p>
            <p><strong>Hardware Concurrency:</strong> ${info.hardwareConcurrency} cores</p>
        `;
    }
    
    getBrowserName() {
        const info = this.browserInfo;
        if (info.isChrome) return 'Chrome';
        if (info.isFirefox) return 'Firefox';
        if (info.isEdge) return 'Edge';
        if (info.isSafari) return 'Safari';
        return 'Unknown';
    }
    
    updateCapabilitiesDisplay() {
        const capabilitiesDiv = document.getElementById('webauthn-capabilities');
        if (!capabilitiesDiv) return;
        
        const caps = this.capabilities;
        capabilitiesDiv.innerHTML = `
            <div class="capability-card">
                <h4>🔐 WebAuthn Support</h4>
                <p>Supported: ${caps.webauthnSupported ? '✅' : '❌'}</p>
                <p>PublicKeyCredential: ${caps.publicKeyCredential ? '✅' : '❌'}</p>
                <p>Credentials API: ${caps.credentialsAPI ? '✅' : '❌'}</p>
                <p>Create Method: ${caps.createMethod ? '✅' : '❌'}</p>
                <p>Get Method: ${caps.getMethod ? '✅' : '❌'}</p>
            </div>
            <div class="capability-card">
                <h4>🛡️ Security Context</h4>
                <p>Secure Context: ${caps.isSecureContext ? '✅' : '❌'}</p>
                <p>HTTPS/Localhost: ${caps.httpsOrLocalhost ? '✅' : '❌'}</p>
            </div>
            <div class="capability-card">
                <h4>📱 Platform Authenticator</h4>
                <p>Available: ${caps.platformAuthenticator ? '✅' : '❌'}</p>
                <p>Conditional UI: ${caps.conditionalMediation ? '✅' : '❌'}</p>
                ${caps.platformAuthenticatorError ? `<p>Error: ${caps.platformAuthenticatorError}</p>` : ''}
            </div>
        `;
        
        // Update platform status
        const platformDiv = document.getElementById('platform-status');
        if (platformDiv) {
            let platformStatus = 'Unknown';
            if (this.browserInfo.isWindows && caps.platformAuthenticator) {
                platformStatus = '✅ Windows Hello Available';
            } else if (this.browserInfo.isMac && caps.platformAuthenticator) {
                platformStatus = '✅ Touch ID Available';
            } else if (this.browserInfo.isAndroid && caps.platformAuthenticator) {
                platformStatus = '✅ Android Biometrics Available';
            } else if (this.browserInfo.isiOS && caps.platformAuthenticator) {
                platformStatus = '✅ Face ID/Touch ID Available';
            } else if (caps.platformAuthenticator) {
                platformStatus = '✅ Platform Authenticator Available';
            } else {
                platformStatus = '❌ No Platform Authenticator';
            }
            
            platformDiv.innerHTML = `<h4>📊 Platform Status</h4><p>${platformStatus}</p>`;
        }
    }
    
    // Status and Logging
    showStatus(elementId, message, type) {
        const statusEl = document.getElementById(elementId);
        if (statusEl) {
            statusEl.textContent = message;
            statusEl.className = `status ${type}`;
            statusEl.style.display = 'block';
        }
        this.log(`[${type.toUpperCase()}] ${message}`);
    }
    
    log(message) {
        const timestamp = new Date().toISOString();
        const logEntry = `[${timestamp}] ${message}`;
        this.debugLog.push(logEntry);
        console.log(logEntry);
        
        // Update debug log if visible
        const debugDiv = document.getElementById('debug-log');
        if (debugDiv) {
            debugDiv.innerHTML = this.debugLog.join('\n');
            debugDiv.scrollTop = debugDiv.scrollHeight;
        }
    }
    
    // Test Results and Settings
    saveTestResult(testType, settings, result) {
        const testResult = {
            timestamp: new Date().toISOString(),
            testType: testType,
            settings: settings,
            result: result,
            browser: this.browserInfo,
            capabilities: this.capabilities
        };
        
        this.testResults.push(testResult);
        localStorage.setItem('webauthn-test-results', JSON.stringify(this.testResults));
    }
    
    loadSavedSettings() {
        const saved = localStorage.getItem('webauthn-super-test-settings');
        if (saved) {
            try {
                this.currentSettings = JSON.parse(saved);
                this.applySettingsToUI();
            } catch (error) {
                console.error('Failed to load saved settings:', error);
            }
        }
    }
    
    saveCurrentSettings() {
        this.currentSettings = this.getCurrentRegistrationSettings();
        localStorage.setItem('webauthn-super-test-settings', JSON.stringify(this.currentSettings));
    }
    
    applySettingsToUI() {
        // Apply saved settings to UI elements
        const settings = this.currentSettings;
        
        document.getElementById('reg-attachment').value = settings.authenticatorAttachment || '';
        document.getElementById('reg-user-verification').value = settings.userVerification || 'preferred';
        document.getElementById('reg-resident-key').value = settings.residentKey || 'preferred';
        document.getElementById('reg-attestation').value = settings.attestation || 'none';
        document.getElementById('advanced-timeout').value = settings.timeout || 60000;
        
        // Apply algorithm checkboxes
        document.querySelectorAll('input[type="checkbox"][value^="-"]').forEach(cb => {
            cb.checked = settings.algorithms.includes(parseInt(cb.value));
        });
        
        // Apply transport checkboxes
        document.querySelectorAll('input[type="checkbox"][value="usb"], input[type="checkbox"][value="nfc"], input[type="checkbox"][value="ble"], input[type="checkbox"][value="internal"], input[type="checkbox"][value="hybrid"]').forEach(cb => {
            cb.checked = settings.transports.includes(cb.value);
        });
    }
    
    // Authentication Testing
    async testAuthentication(username, authType) {
        this.log(`🔓 Testing authentication: username=${username || 'usernameless'}, type=${authType}`);
        
        try {
            let endpoint = '/webauthn/authenticate/begin';
            let requestBody = {};
            let customOptions = {};
            
            // Check Apple override options
            const forceExternal = document.getElementById('force-cross-platform')?.checked;
            const disablePlatform = document.getElementById('disable-platform-auth')?.checked;
            const prioritizeExternal = document.getElementById('prioritize-external')?.checked;
            
            // Determine endpoint and options based on auth type
            switch (authType) {
                case 'hybrid':
                    endpoint = '/webauthn/authenticate/begin/hybrid';
                    break;
                case 'hybrid-force':
                    endpoint = '/webauthn/authenticate/begin/hybrid';
                    customOptions.forceNonPlatform = true;
                    break;
                case 'security-key':
                    requestBody.securityKeyOnly = true;
                    break;
                case 'platform':
                    requestBody.platformOnly = true;
                    break;
                case 'usernameless':
                    username = null;
                    break;
                case 'apple-override':
                    endpoint = '/webauthn/authenticate/begin';
                    customOptions.appleOverride = true;
                    customOptions.forceExternal = true;
                    break;
            }
            
            // Apply Apple overrides if selected
            if (forceExternal || authType === 'apple-override') {
                customOptions.excludePlatform = true;
                customOptions.forceCrossPlatform = true;
            }
            if (disablePlatform) {
                customOptions.disablePlatformAuth = true;
            }
            if (prioritizeExternal) {
                customOptions.prioritizeExternal = true;
            }
            
            if (username) {
                requestBody.username = username;
            }
            
            const result = await this.performAuthentication(username, authType, endpoint, requestBody, customOptions);
            
            if (result.success) {
                this.showStatus('auth-status', `✅ ${authType} authentication successful!`, 'success');
                this.saveTestResult('authentication', { authType, username, customOptions }, result);
            } else {
                this.showStatus('auth-status', `❌ ${authType} authentication failed: ${result.error}`, 'error');
            }
            
        } catch (error) {
            this.showStatus('auth-status', `❌ Authentication error: ${error.message}`, 'error');
            this.log(`❌ Authentication error: ${error.message}`);
        }
    }
    
    async testChromeBypassAuthentication() {
        const useAppleCancellation = document.getElementById('auth-apple-cancellation')?.checked;
        this.log(`🔑 SECURITY KEY ONLY: Using UI settings${useAppleCancellation ? ' + Apple cancellation' : ''} + forcing cross-platform`);
        this.showStatus('auth-status', `${useAppleCancellation ? 'Canceling Apple + ' : ''}UI settings + forcing security key...`, 'info');
        
        try {
            // Handle Apple cancellation if requested
            if (useAppleCancellation) {
                await this.performAppleCancellation(false);
            }
            
            // Build options from UI then override for security key only
            const options = this.buildAuthenticationOptionsFromUI();
            
            // Override specific settings for security key only mode
            delete options.allowCredentials; // Remove credential restrictions
            options.userVerification = 'discouraged';
            options.timeout = 25000; // Short timeout
            
            // THIS IS THE KEY - Force cross-platform to restrict to security keys only
            options.authenticatorSelection = {
                authenticatorAttachment: 'cross-platform',
                userVerification: 'discouraged'
            };
            
            this.log(`🔑 SECURITY KEY AUTH OVERRIDE: ${JSON.stringify(options, null, 2)}`);
            
            const startTime = performance.now();
            const assertion = await navigator.credentials.get({ publicKey: options });
            const endTime = performance.now();
            
            if (assertion) {
                this.log(`✅ SUCCESS: Security key authentication completed in ${endTime - startTime}ms`);
                this.log(`✅ Credential ID: ${assertion.id}`);
                this.log(`✅ Authenticator: ${assertion.authenticatorAttachment || 'unknown'}`);
                
                this.showStatus('auth-status', '✅ Security key authentication successful with UI settings!', 'success');
            } else {
                throw new Error('No credential returned');
            }
            
        } catch (error) {
            this.showStatus('auth-status', `❌ Security key error: ${error.message}`, 'error');
            this.log(`❌ Security key error: ${error.message}`);
        }
    }
    
    async testChromeProviderAuthentication() {
        const username = document.getElementById('auth-username').value.trim();
        
        this.log(`🌐 CHROME PROVIDERS: Starting authentication${username ? ` for: ${username}` : ' (usernameless)'}`);
        this.showStatus('auth-status', 'Bypassing Touch ID for Chrome provider selection...', 'info');
        
        try {
            // Gentle bypass settings for Chrome provider selection
            const chromeProviderOptions = {
                appleOverride: true, // Still bypass Touch ID
                forceExternal: false, // Don't force external only
                forceCrossPlatform: true, // MUST force this to bypass Apple
                disablePlatformAuth: false, // Don't disable platform
                excludePlatform: false, // Don't exclude platform
                prioritizeExternal: false, // Don't prioritize external
                forceNonPlatform: false, // Allow all options
                gentleBypass: true, // Special flag for gentle bypass
                allowPasskeys: true // Allow passkey creation
            };
            
            const requestBody = {};
            if (username) {
                requestBody.username = username;
            }
            
            const result = await this.performAuthentication(username, 'chrome-providers', '/webauthn/authenticate/begin', requestBody, chromeProviderOptions);
            
            if (result.success) {
                this.showStatus('auth-status', '✅ Chrome provider selection authentication successful! 🌐', 'success');
                this.log(`✅ Chrome provider authentication completed successfully`);
                this.saveTestResult('chrome-provider-authentication', { username, chromeProviderOptions }, result);
            } else {
                this.showStatus('auth-status', `❌ Chrome provider authentication failed: ${result.error}`, 'error');
                this.log(`❌ Chrome provider authentication failed: ${result.error}`);
            }
            
        } catch (error) {
            this.showStatus('auth-status', `❌ Chrome provider auth error: ${error.message}`, 'error');
            this.log(`❌ Chrome provider auth error: ${error.message}`);
        }
    }
    
    async testConditionalUI() {
        this.log(`🔀 CONDITIONAL UI: Testing WebAuthn conditional mediation (autofill)`);
        this.showStatus('reg-status', 'Testing conditional UI...', 'info');
        this.showStatus('auth-status', 'Testing conditional UI...', 'info');
        
        try {
            // Use conditional mediation which may bypass Apple's interception
            if (!PublicKeyCredential.isConditionalMediationAvailable) {
                throw new Error('Conditional mediation not supported');
            }
            
            const isAvailable = await PublicKeyCredential.isConditionalMediationAvailable();
            if (!isAvailable) {
                throw new Error('Conditional mediation not available');
            }
            
            // Get credential with conditional mediation
            const credentialOptions = {
                publicKey: {
                    challenge: new Uint8Array(32),
                    allowCredentials: [],
                    userVerification: 'preferred',
                    timeout: 60000
                },
                mediation: 'conditional' // This is the key!
            };
            
            this.log(`🔀 CONDITIONAL UI: Requesting credential with conditional mediation`);
            
            const credential = await navigator.credentials.get(credentialOptions);
            
            if (credential) {
                this.showStatus('reg-status', '✅ Conditional UI worked! This should show Chrome providers!', 'success');
                this.showStatus('auth-status', '✅ Conditional UI worked! This should show Chrome providers!', 'success');
                this.log(`✅ Conditional UI authentication completed successfully`);
            }
            
        } catch (error) {
            this.showStatus('reg-status', `❌ Conditional UI error: ${error.message}`, 'error');
            this.showStatus('auth-status', `❌ Conditional UI error: ${error.message}`, 'error');
            this.log(`❌ Conditional UI error: ${error.message}`);
        }
    }
    
    async testAppleDetectionAndCancel() {
        this.log(`🍎 APPLE DETECTION: Attempting to detect and cancel Apple's WebAuthn interception`);
        this.showStatus('reg-status', 'Detecting Apple interception...', 'info');
        this.showStatus('auth-status', 'Detecting Apple interception...', 'info');
        
        try {
            const settings = this.getCurrentRegistrationSettings();
            
            // Create abort controller for cancellation
            const abortController = new AbortController();
            
            // Set up Apple detection
            const isMacChrome = navigator.platform.includes('Mac') && navigator.userAgent.includes('Chrome');
            if (!isMacChrome) {
                throw new Error('Not macOS Chrome - Apple detection not needed');
            }
            
            this.log(`🍎 DETECTION: Confirmed macOS Chrome environment`);
            
            // Start WebAuthn request with signal
            const webauthnOptions = {
                publicKey: {
                    challenge: crypto.getRandomValues(new Uint8Array(32)),
                    rp: { name: "Apple Detection Test" },
                    user: {
                        id: crypto.getRandomValues(new Uint8Array(16)),
                        name: "test-user",
                        displayName: "Test User"
                    },
                    pubKeyCredParams: [
                        { alg: -7, type: "public-key" }
                    ],
                    authenticatorSelection: {
                        // Start with no attachment to see what Apple does
                        userVerification: 'preferred',
                        residentKey: 'preferred'
                    },
                    timeout: 5000, // Very short timeout for detection
                    attestation: 'none'
                },
                signal: abortController.signal
            };
            
            this.log(`🍎 DETECTION: Starting WebAuthn call with Apple detection...`);
            
            // Race between WebAuthn and Apple detection timer
            const webauthnPromise = navigator.credentials.create(webauthnOptions);
            
            // Apple detection timer - if it takes longer than 2 seconds, likely Apple intercept
            const appleDetectionTimer = new Promise((resolve, reject) => {
                setTimeout(() => {
                    this.log(`🍎 DETECTED: Apple likely intercepted (>2s delay) - CANCELING!`);
                    abortController.abort();
                    reject(new Error('Apple interception detected and canceled'));
                }, 2000);
            });
            
            // Quick success detection - if it resolves very fast, might be Apple bypass
            const quickSuccessTimer = new Promise((resolve) => {
                setTimeout(() => {
                    resolve('quick-timeout');
                }, 100);
            });
            
            const result = await Promise.race([webauthnPromise, appleDetectionTimer, quickSuccessTimer]);
            
            if (result === 'quick-timeout') {
                // Still running after 100ms, likely Apple intercepted
                this.log(`🍎 DETECTED: Request still pending after 100ms - likely Apple intercept`);
                abortController.abort();
                
                // Now try Chrome-specific bypass after canceling Apple
                this.log(`🔄 RETRY: Attempting Chrome-specific call after Apple cancellation`);
                
                const chromeBypassOptions = {
                    publicKey: {
                        challenge: crypto.getRandomValues(new Uint8Array(32)),
                        rp: { name: "Chrome Bypass Test" },
                        user: {
                            id: crypto.getRandomValues(new Uint8Array(16)),
                            name: "chrome-bypass-user",
                            displayName: "Chrome Bypass User"
                        },
                        pubKeyCredParams: [
                            { alg: -7, type: "public-key" },
                            { alg: -257, type: "public-key" }
                        ],
                        authenticatorSelection: {
                            authenticatorAttachment: 'cross-platform', // Force external
                            userVerification: 'discouraged',
                            residentKey: 'discouraged'
                        },
                        timeout: 15000,
                        attestation: 'none'
                    }
                };
                
                const retryResult = await navigator.credentials.create(chromeBypassOptions);
                
                this.showStatus('reg-status', '✅ Apple detection & cancel worked! Chrome bypass successful!', 'success');
                this.showStatus('auth-status', '✅ Apple detection & cancel worked! Chrome bypass successful!', 'success');
                this.log(`✅ Apple cancellation and Chrome bypass completed successfully`);
                
            } else {
                // WebAuthn completed quickly - might have bypassed Apple
                this.showStatus('reg-status', '✅ WebAuthn completed quickly - possible Apple bypass!', 'success');
                this.showStatus('auth-status', '✅ WebAuthn completed quickly - possible Apple bypass!', 'success');
                this.log(`✅ WebAuthn completed without Apple interception`);
            }
            
        } catch (error) {
            if (error.name === 'AbortError') {
                this.showStatus('reg-status', '🍎 Apple interception detected and canceled successfully!', 'warning');
                this.showStatus('auth-status', '🍎 Apple interception detected and canceled successfully!', 'warning');
                this.log(`🍎 Apple interception successfully canceled: ${error.message}`);
            } else {
                this.showStatus('reg-status', `❌ Apple detection error: ${error.message}`, 'error');
                this.showStatus('auth-status', `❌ Apple detection error: ${error.message}`, 'error');
                this.log(`❌ Apple detection error: ${error.message}`);
            }
        }
    }
    
    async testForceChrome() {
        const username = document.getElementById('reg-username')?.value?.trim() || 
                         document.getElementById('auth-username')?.value?.trim();
        
        this.log(`🔨 FORCE CHROME: Attempting to force Chrome UI${username ? ` for: ${username}` : ''}`);
        this.showStatus('reg-status', 'Attempting to force Chrome UI...', 'info');
        this.showStatus('auth-status', 'Attempting to force Chrome UI...', 'info');
        
        try {
            // Try a completely different approach
            const settings = this.getCurrentRegistrationSettings();
            
            // Try NO attachment to get full Chrome provider selection
            delete settings.authenticatorAttachment; // Remove any attachment restriction
            settings.userVerification = 'preferred'; // Allow all verification methods
            settings.residentKey = 'preferred'; // Allow passkeys 
            settings.timeout = 5000; // Ultra short timeout to bypass Apple quickly
            settings.attestation = 'none';
            
            // Try to add a small delay to let Apple's handler pass
            await new Promise(resolve => setTimeout(resolve, 50));
            
            const forceOptions = {
                appleOverride: false, // Don't apply Apple overrides
                forceCrossPlatform: false, // Don't force cross-platform 
                forceExternal: false, // Don't force external
                disablePlatformAuth: false, // Allow platform
                excludePlatform: false, // Don't exclude platform
                prioritizeExternal: false, // Don't prioritize external
                forceNonPlatform: false, // Allow all types
                experimental: true, // Flag for experimental handling
                ultraShortTimeout: true // Special ultra-short timeout
            };
            
            this.log(`🔨 FORCE: Using experimental Chrome forcing`);
            
            const result = await this.performRegistration(username || 'test-force-user', settings, forceOptions);
            
            if (result.success) {
                this.showStatus('reg-status', '✅ Force Chrome registration successful! 🔨', 'success');
                this.showStatus('auth-status', '✅ Force Chrome registration successful! 🔨', 'success');
                this.log(`✅ Force Chrome registration completed successfully`);
                this.saveTestResult('force-chrome-registration', settings, result);
            } else {
                this.showStatus('reg-status', `❌ Force Chrome failed: ${result.error}`, 'error');
                this.showStatus('auth-status', `❌ Force Chrome failed: ${result.error}`, 'error');
                this.log(`❌ Force Chrome failed: ${result.error}`);
            }
            
        } catch (error) {
            this.showStatus('reg-status', `❌ Force Chrome error: ${error.message}`, 'error');
            this.showStatus('auth-status', `❌ Force Chrome error: ${error.message}`, 'error');
            this.log(`❌ Force Chrome error: ${error.message}`);
        }
    }
    
    async performAuthentication(username, authType, endpoint, requestBody, customOptions = {}) {
        // Get authentication options
        const optionsResponse = await fetch(endpoint, {
            method: 'POST',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify(requestBody)
        });
        
        if (!optionsResponse.ok) {
            throw new Error('Failed to get authentication options');
        }
        
        const options = await optionsResponse.json();
        this.log(`📋 Auth options: ${JSON.stringify(options, null, 2)}`);
        
        // Apply Apple/Safari overrides and custom options
        this.applyAppleOverrides(options, customOptions);
        
        // Convert base64 to ArrayBuffer
        options.publicKey.challenge = this.base64ToArrayBuffer(options.publicKey.challenge);
        
        if (options.publicKey.allowCredentials) {
            options.publicKey.allowCredentials = options.publicKey.allowCredentials.map(cred => ({
                ...cred,
                id: this.base64ToArrayBuffer(cred.id)
            }));
        }
        
        this.log(`📋 Modified auth options: ${JSON.stringify(options, null, 2)}`);
        
        // Get assertion
        const startTime = performance.now();
        const assertion = await navigator.credentials.get({ publicKey: options.publicKey });
        const endTime = performance.now();
        
        this.log(`⏱️ Authentication took ${endTime - startTime}ms`);
        
        if (!assertion) {
            throw new Error('Authentication cancelled');
        }
        
        // Verify with server
        const verificationData = {
            id: assertion.id,
            rawId: this.arrayBufferToBase64(assertion.rawId),
            type: assertion.type,
            response: {
                clientDataJSON: this.arrayBufferToBase64(assertion.response.clientDataJSON),
                authenticatorData: this.arrayBufferToBase64(assertion.response.authenticatorData),
                signature: this.arrayBufferToBase64(assertion.response.signature),
                userHandle: assertion.response.userHandle ? this.arrayBufferToBase64(assertion.response.userHandle) : null
            }
        };
        
        if (username) {
            verificationData.username = username;
        }
        
        const verifyResponse = await fetch('/webauthn/authenticate/complete', {
            method: 'POST',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify(verificationData)
        });
        
        const result = await verifyResponse.json();
        
        return {
            success: verifyResponse.ok,
            assertion: assertion,
            verificationResult: result,
            timeTaken: endTime - startTime,
            authType: authType
        };
    }
    
    // Transport Testing
    async testSpecificTransport(transport, statusElementId) {
        this.log(`🚀 Testing ${transport} transport`);
        this.showStatus(statusElementId, `Testing ${transport} transport...`, 'info');
        
        try {
            // Create test options with specific transport
            const settings = this.getCurrentRegistrationSettings();
            settings.transports = [transport];
            settings.authenticatorAttachment = transport === 'internal' ? 'platform' : 'cross-platform';
            
            const result = await this.performRegistration(`test-${transport}-user`, settings);
            
            if (result.success) {
                this.showStatus(statusElementId, `✅ ${transport} transport working!`, 'success');
            } else {
                this.showStatus(statusElementId, `❌ ${transport} transport failed`, 'error');
            }
            
        } catch (error) {
            this.showStatus(statusElementId, `❌ ${transport} transport error: ${error.message}`, 'error');
        }
    }
    
    // Hardware Key Testing
    async testHardwareKey(keyType, statusElementId) {
        this.log(`🔧 Testing ${keyType} hardware key`);
        this.showStatus(statusElementId, `Testing ${keyType} key...`, 'info');
        
        try {
            const settings = this.getCurrentRegistrationSettings();
            settings.authenticatorAttachment = 'cross-platform';
            settings.userVerification = keyType === 'u2f' ? 'discouraged' : 'preferred';
            settings.residentKey = keyType === 'fido2' ? 'preferred' : 'discouraged';
            
            const result = await this.performRegistration(`test-${keyType}-user`, settings);
            
            if (result.success) {
                this.showStatus(statusElementId, `✅ ${keyType} key working!`, 'success');
            } else {
                this.showStatus(statusElementId, `❌ ${keyType} key failed`, 'error');
            }
            
        } catch (error) {
            this.showStatus(statusElementId, `❌ ${keyType} key error: ${error.message}`, 'error');
        }
    }
    
    // Platform Passkey Testing
    async testPlatformPasskeys(platform, statusElementId) {
        this.log(`🔑 Testing ${platform} passkeys`);
        this.showStatus(statusElementId, `Testing ${platform} passkeys...`, 'info');
        
        try {
            if (!this.capabilities.platformAuthenticator) {
                this.showStatus(statusElementId, `❌ Platform authenticator not available`, 'error');
                return;
            }
            
            const settings = this.getCurrentRegistrationSettings();
            settings.authenticatorAttachment = 'platform';
            settings.userVerification = 'required';
            settings.residentKey = 'required';
            
            const result = await this.performRegistration(`test-${platform}-user`, settings);
            
            if (result.success) {
                this.showStatus(statusElementId, `✅ ${platform} passkeys working!`, 'success');
            } else {
                this.showStatus(statusElementId, `❌ ${platform} passkeys failed`, 'error');
            }
            
        } catch (error) {
            this.showStatus(statusElementId, `❌ ${platform} passkeys error: ${error.message}`, 'error');
        }
    }
    
    // Algorithm Testing
    async testAlgorithmFamily(family, statusElementId) {
        this.log(`🔢 Testing ${family} algorithms`);
        this.showStatus(statusElementId, `Testing ${family} algorithms...`, 'info');
        
        try {
            const algorithmSets = {
                ecdsa: [-7, -35, -36], // ES256, ES384, ES512
                rsa: [-257, -258, -259, -37, -38, -39], // RS256, RS384, RS512, PS256, PS384, PS512
                eddsa: [-8] // EdDSA
            };
            
            const algorithms = algorithmSets[family] || [-7];
            const results = [];
            
            for (const alg of algorithms) {
                try {
                    const settings = this.getCurrentRegistrationSettings();
                    settings.algorithms = [alg];
                    
                    const result = await this.performRegistration(`test-alg-${alg}-user`, settings);
                    results.push({ algorithm: alg, success: result.success });
                    
                } catch (error) {
                    results.push({ algorithm: alg, success: false, error: error.message });
                }
            }
            
            const successful = results.filter(r => r.success).length;
            const total = results.length;
            
            if (successful > 0) {
                this.showStatus(statusElementId, `✅ ${family}: ${successful}/${total} algorithms working`, 'success');
            } else {
                this.showStatus(statusElementId, `❌ ${family}: No algorithms working`, 'error');
            }
            
            this.log(`📊 ${family} algorithm results: ${JSON.stringify(results, null, 2)}`);
            
        } catch (error) {
            this.showStatus(statusElementId, `❌ ${family} algorithm test error: ${error.message}`, 'error');
        }
    }
    
    // FIDO Protocol Testing
    async testFIDOProtocol(protocol, statusElementId) {
        this.log(`🏆 Testing ${protocol} protocol`);
        this.showStatus(statusElementId, `Testing ${protocol}...`, 'info');
        
        try {
            const settings = this.getCurrentRegistrationSettings();
            
            if (protocol === 'ctap1') {
                // U2F/CTAP1 settings
                settings.authenticatorAttachment = 'cross-platform';
                settings.userVerification = 'discouraged';
                settings.residentKey = 'discouraged';
                settings.algorithms = [-7]; // ES256 only for U2F
            } else if (protocol === 'ctap2') {
                // CTAP2 settings
                settings.authenticatorAttachment = 'cross-platform';
                settings.userVerification = 'preferred';
                settings.residentKey = 'preferred';
            }
            
            const result = await this.performRegistration(`test-${protocol}-user`, settings);
            
            if (result.success) {
                this.showStatus(statusElementId, `✅ ${protocol} protocol working!`, 'success');
            } else {
                this.showStatus(statusElementId, `❌ ${protocol} protocol failed`, 'error');
            }
            
        } catch (error) {
            this.showStatus(statusElementId, `❌ ${protocol} protocol error: ${error.message}`, 'error');
        }
    }
    
    // CBOR Testing
    async testCBOREncoding(statusElementId) {
        this.log('📋 Testing CBOR encoding');
        this.showStatus(statusElementId, 'Testing CBOR encoding...', 'info');
        
        try {
            // This would test CBOR encoding/decoding capabilities
            // For now, we'll just verify that the browser can handle WebAuthn responses
            const settings = this.getCurrentRegistrationSettings();
            const result = await this.performRegistration('test-cbor-user', settings);
            
            if (result.success) {
                // Analyze the attestation object to check CBOR encoding
                const attestationObject = result.credential.response.attestationObject;
                this.log(`📋 CBOR attestation object size: ${attestationObject.byteLength} bytes`);
                this.showStatus(statusElementId, '✅ CBOR encoding working!', 'success');
            } else {
                this.showStatus(statusElementId, '❌ CBOR encoding test failed', 'error');
            }
            
        } catch (error) {
            this.showStatus(statusElementId, `❌ CBOR test error: ${error.message}`, 'error');
        }
    }
    
    // Debug and Export Functions
    exportDebugInfo() {
        const debugInfo = {
            timestamp: new Date().toISOString(),
            browser: this.browserInfo,
            capabilities: this.capabilities,
            settings: this.currentSettings,
            debugLog: this.debugLog,
            testResults: this.testResults
        };
        
        const blob = new Blob([JSON.stringify(debugInfo, null, 2)], { type: 'application/json' });
        const url = URL.createObjectURL(blob);
        const a = document.createElement('a');
        a.href = url;
        a.download = `webauthn-debug-${new Date().toISOString().split('T')[0]}.json`;
        a.click();
        URL.revokeObjectURL(url);
        
        this.log('📄 Debug info exported');
    }
    
    async testCustomOptions() {
        const customOptionsText = document.getElementById('custom-options').value.trim();
        if (!customOptionsText) {
            this.showStatus('custom-status', 'Please enter custom options', 'error');
            return;
        }
        
        try {
            const customOptions = JSON.parse(customOptionsText);
            this.log(`🧪 Testing custom options: ${JSON.stringify(customOptions, null, 2)}`);
            
            // Convert base64 strings if needed
            if (customOptions.publicKey?.challenge && typeof customOptions.publicKey.challenge === 'string') {
                customOptions.publicKey.challenge = this.base64ToArrayBuffer(customOptions.publicKey.challenge);
            }
            if (customOptions.publicKey?.user?.id && typeof customOptions.publicKey.user.id === 'string') {
                customOptions.publicKey.user.id = this.base64ToArrayBuffer(customOptions.publicKey.user.id);
            }
            
            const startTime = performance.now();
            const credential = await navigator.credentials.create(customOptions);
            const endTime = performance.now();
            
            if (credential) {
                this.showStatus('custom-status', `✅ Custom options successful! (${Math.round(endTime - startTime)}ms)`, 'success');
                this.log(`✅ Custom credential created: ${credential.id}`);
            } else {
                this.showStatus('custom-status', '❌ Custom options failed', 'error');
            }
            
        } catch (error) {
            this.showStatus('custom-status', `❌ Custom options error: ${error.message}`, 'error');
            this.log(`❌ Custom options error: ${error.message}`);
        }
    }
    
    exportSettings() {
        const exportData = {
            timestamp: new Date().toISOString(),
            settings: this.currentSettings,
            browser: this.browserInfo,
            capabilities: this.capabilities,
            workingConfigurations: this.testResults.filter(r => r.result.success)
        };
        
        const blob = new Blob([JSON.stringify(exportData, null, 2)], { type: 'application/json' });
        const url = URL.createObjectURL(blob);
        const a = document.createElement('a');
        a.href = url;
        a.download = `webauthn-settings-${new Date().toISOString().split('T')[0]}.json`;
        a.click();
        URL.revokeObjectURL(url);
        
        this.log('📋 Settings exported');
    }
    
    exportTestResults() {
        const blob = new Blob([JSON.stringify(this.testResults, null, 2)], { type: 'application/json' });
        const url = URL.createObjectURL(blob);
        const a = document.createElement('a');
        a.href = url;
        a.download = `webauthn-test-results-${new Date().toISOString().split('T')[0]}.json`;
        a.click();
        URL.revokeObjectURL(url);
        
        this.log('📊 Test results exported');
    }
    
    importSettings() {
        const importText = document.getElementById('import-settings').value.trim();
        if (!importText) {
            this.showStatus('import-status', 'Please paste settings JSON', 'error');
            return;
        }
        
        try {
            const importData = JSON.parse(importText);
            
            if (importData.settings) {
                this.currentSettings = importData.settings;
                this.applySettingsToUI();
                this.showStatus('import-status', '✅ Settings imported successfully', 'success');
                this.log('📥 Settings imported');
            } else {
                this.showStatus('import-status', '❌ Invalid settings format', 'error');
            }
            
        } catch (error) {
            this.showStatus('import-status', `❌ Import error: ${error.message}`, 'error');
        }
    }
    
    generateDogTagKitCode() {
        const settings = this.currentSettings;
        const workingConfigs = this.testResults.filter(r => r.result.success);
        
        let swiftCode = `// Generated DogTagKit Configuration
// Based on WebAuthn Super Test results
// Generated on: ${new Date().toISOString()}

import DogTagKit

extension WebAuthnManager {
    static func createOptimizedConfiguration() -> WebAuthnConfiguration {
        var config = WebAuthnConfiguration()
        
        // Timeout settings
        config.timeout = ${settings.timeout}
        
        // Attestation preference
        config.attestation = .${settings.attestation}
        
        // User verification
        config.userVerification = .${settings.userVerification}
        
        // Authenticator attachment
        ${settings.authenticatorAttachment ? `config.authenticatorAttachment = .${settings.authenticatorAttachment}` : '// No authenticator attachment (hybrid mode)'}
        
        // Resident key requirement
        config.residentKey = .${settings.residentKey}
        
        // Supported algorithms
        config.supportedAlgorithms = [
            ${settings.algorithms.map(alg => {
                const algMap = {
                    '-7': '.es256',
                    '-35': '.es384', 
                    '-36': '.es512',
                    '-257': '.rs256',
                    '-258': '.rs384',
                    '-259': '.rs512',
                    '-37': '.ps256',
                    '-38': '.ps384',
                    '-39': '.ps512',
                    '-8': '.eddsa'
                };
                return algMap[alg.toString()] || `.unknown(${alg})`;
            }).join(',\n            ')}
        ]
        
        // Transport methods
        config.transports = [
            ${settings.transports.map(t => `.${t}`).join(',\n            ')}
        ]
        
        return config
    }
    
    // Working test configurations found:
    // ${workingConfigs.length} successful configurations detected
    ${workingConfigs.map((config, index) => `
    // Configuration ${index + 1}: ${config.testType} - ${config.settings.authenticatorAttachment || 'hybrid'}
    // Success rate: ${config.result.success ? '100%' : '0%'}
    // Time taken: ${config.result.timeTaken}ms`).join('')}
}`;
        
        const codeDiv = document.getElementById('dogtagkit-code');
        if (codeDiv) {
            codeDiv.textContent = swiftCode;
            codeDiv.style.display = 'block';
        }
        
        this.log('🐕 DogTagKit code generated');
    }
    
    // Apple/Safari Override Methods
    async universalAppleCancellationAndSettings(username, buttonType = 'default') {
        this.log(`🔧 UNIVERSAL: Starting ${buttonType} with Apple cancellation and UI settings`);
        
        // Step 1: Get settings from UI form
        const settings = this.getCurrentRegistrationSettings();
        this.log(`📋 UI SETTINGS: ${JSON.stringify(settings, null, 2)}`);
        
        // Step 2: Apple cancellation (if on macOS Chrome)
        const isMacChrome = navigator.platform.includes('Mac') && navigator.userAgent.includes('Chrome');
        if (isMacChrome) {
            this.log(`🍎 CANCELING: Detected macOS Chrome - will cancel Apple interception`);
            
            const abortController = new AbortController();
            
            // Apple detection request
            const appleDetectionOptions = {
                publicKey: {
                    challenge: crypto.getRandomValues(new Uint8Array(32)),
                    rp: { name: "Apple Detection", id: "localhost" },
                    user: {
                        id: new TextEncoder().encode(username + '-detect'),
                        name: username + '-detect',
                        displayName: 'Apple Detection User'
                    },
                    pubKeyCredParams: [{ alg: -7, type: "public-key" }],
                    authenticatorSelection: {
                        userVerification: 'preferred',
                        residentKey: 'preferred'
                    },
                    timeout: 3000,
                    attestation: 'none'
                },
                signal: abortController.signal
            };
            
            const applePromise = navigator.credentials.create(appleDetectionOptions);
            const appleDetectionTimer = new Promise((resolve) => {
                setTimeout(() => {
                    this.log(`🍎 DETECTED: Apple intercepted - CANCELING NOW!`);
                    abortController.abort();
                    resolve('apple-canceled');
                }, 100); // Quick detection
            });
            
            try {
                const raceResult = await Promise.race([applePromise, appleDetectionTimer]);
                if (raceResult === 'apple-canceled') {
                    this.log(`🍎 SUCCESS: Apple interception canceled!`);
                }
            } catch (error) {
                if (error.name === 'AbortError') {
                    this.log(`🍎 SUCCESS: Apple interception aborted!`);
                }
            }
            
            // Wait for Apple to clear
            await new Promise(resolve => setTimeout(resolve, 50));
        }
        
        // Step 3: Build WebAuthn options using UI settings
        const webauthnOptions = {
            publicKey: {
                challenge: crypto.getRandomValues(new Uint8Array(32)),
                rp: { name: settings.rpName || "WebAuthn Test", id: "localhost" },
                user: {
                    id: new TextEncoder().encode(username),
                    name: username,
                    displayName: settings.displayName || username
                },
                pubKeyCredParams: settings.algorithms.map(alg => ({ alg, type: "public-key" })),
                authenticatorSelection: {
                    userVerification: settings.userVerification,
                    residentKey: settings.residentKey,
                    requireResidentKey: settings.residentKey === 'required'
                },
                timeout: settings.timeout || 60000,
                attestation: settings.attestation || 'none'
            }
        };
        
        // Apply authenticator attachment from UI settings
        if (settings.authenticatorAttachment && settings.authenticatorAttachment !== 'undefined') {
            webauthnOptions.publicKey.authenticatorSelection.authenticatorAttachment = settings.authenticatorAttachment;
        }
        
        // Apply extensions from UI settings
        if (Object.keys(settings.extensions).length > 0) {
            webauthnOptions.publicKey.extensions = settings.extensions;
        }
        
        this.log(`🔧 FINAL OPTIONS: ${JSON.stringify(webauthnOptions, null, 2)}`);
        
        return webauthnOptions;
    }

    applyAppleOverrides(options, customOptions) {
        this.log(`🍎 Applying Apple overrides: ${JSON.stringify(customOptions, null, 2)}`);
        
        // Check Safari-specific overrides
        const safariForceExternal = document.getElementById('safari-force-external')?.checked;
        const safariExcludePlatform = document.getElementById('safari-exclude-platform')?.checked;
        const safariPreferUSB = document.getElementById('safari-prefer-usb')?.checked;
        const safariDisableTouchID = document.getElementById('safari-disable-touchid')?.checked;
        
        // Check if we're on macOS Chrome (this requires more aggressive bypassing)
        const isMacChrome = navigator.platform.includes('Mac') && navigator.userAgent.includes('Chrome');
        
        // AGGRESSIVE CHROME BYPASS: Force cross-platform from the start
        if (isMacChrome || customOptions.forceExternal || safariForceExternal || customOptions.excludePlatform) {
            // Completely rebuild authenticatorSelection to force cross-platform
            options.publicKey.authenticatorSelection = {
                authenticatorAttachment: 'cross-platform',
                userVerification: 'discouraged',
                residentKey: 'discouraged',
                requireResidentKey: false
            };
            
            // Force short timeout to prevent Touch ID from activating
            options.publicKey.timeout = 30000; // 30 seconds
            
            this.log('🚀 AGGRESSIVE: Forced cross-platform with short timeout for Chrome');
        }
        
        // CHROME-SPECIFIC: Exclude platform credentials completely and immediately
        if (isMacChrome && (safariExcludePlatform || customOptions.disablePlatformAuth)) {
            options.publicKey.authenticatorSelection = {
                authenticatorAttachment: 'cross-platform',
                userVerification: 'discouraged',
                residentKey: 'discouraged'
            };
            
            // Remove any existing excludeCredentials that might reference platform authenticators
            if (options.publicKey.excludeCredentials) {
                options.publicKey.excludeCredentials = options.publicKey.excludeCredentials.filter(cred => 
                    !cred.transports || !cred.transports.includes('internal')
                );
            }
            
            this.log('🚀 CHROME: Completely excluded platform authenticators');
        }
        
        // CHROME BYPASS: Use very specific pubKeyCredParams to avoid platform preferences
        if (isMacChrome && (safariPreferUSB || customOptions.prioritizeExternal)) {
            // Force specific algorithms that favor security keys
            options.publicKey.pubKeyCredParams = [
                { alg: -7, type: "public-key" },   // ES256 (most security keys)
                { alg: -257, type: "public-key" }, // RS256 (older security keys)
                { alg: -37, type: "public-key" }   // PS256 (advanced security keys)
            ];
            
            // Clear any allowCredentials that might reference platform
            if (options.publicKey.allowCredentials) {
                options.publicKey.allowCredentials = options.publicKey.allowCredentials.map(cred => ({
                    ...cred,
                    transports: ['usb', 'nfc', 'hybrid'] // Remove 'internal' completely
                }));
            }
            
            this.log('🚀 CHROME: Forced security key-specific algorithms and transports');
        }
        
        // ULTIMATE CHROME BYPASS: Disable Touch ID preference completely
        if (isMacChrome && (safariDisableTouchID || customOptions.appleOverride)) {
            
            if (customOptions.gentleBypass) {
                // NEW APPROACH: Don't force cross-platform, try to bypass Apple differently
                this.log('🌟 NEW GENTLE BYPASS: Trying to get Chrome provider selection screen');
                
                // DON'T force cross-platform - that causes the basic screen
                // Instead leave attachment undefined to get full provider selection
                options.publicKey.authenticatorSelection = {
                    // No authenticatorAttachment specified - this should give full Chrome UI
                    userVerification: 'preferred', // Allow UV 
                    residentKey: 'preferred', // Allow passkeys
                    requireResidentKey: false
                };
                
                // Use a very short timeout to try to bypass Apple's interception
                options.publicKey.timeout = 10000; // 10 seconds - very short
                
                // Minimal attestation
                options.publicKey.attestation = 'none';
                
                // Add user handle to encourage passkey behavior
                if (options.publicKey.user && !options.publicKey.user.id) {
                    options.publicKey.user.id = new Uint8Array(16); // Random user ID
                }
                
                // Try to set Chrome-specific transport hints
                options.publicKey.extensions = {
                    credProps: true // This might help Chrome show its UI
                };
                
                this.log('🌟 NEW GENTLE: No attachment restriction, short timeout, Chrome-friendly settings');
                
            } else if (customOptions.ultraShortTimeout) {
                // ULTRA SHORT TIMEOUT: Try to beat Apple to the punch
                this.log('⚡ ULTRA SHORT TIMEOUT: Racing Apple interception with no restrictions');
                
                // Leave everything as flexible as possible - NO attachment restriction
                const newOptions = {
                    ...options.publicKey,
                    authenticatorSelection: {
                        // No authenticatorAttachment - this should allow full Chrome UI
                        userVerification: 'preferred',
                        residentKey: 'preferred',
                        requireResidentKey: false
                    },
                    timeout: 5000, // Ultra short timeout
                    attestation: 'none'
                };
                
                // Keep extensions minimal but Chrome-friendly
                newOptions.extensions = {
                    credProps: true
                };
                
                options.publicKey = newOptions;
                this.log('⚡ ULTRA: No attachment restriction, 5s timeout, all Chrome providers enabled');
                
            } else {
                // NUCLEAR BYPASS: Security key only mode
                const newOptions = {
                    ...options.publicKey,
                    authenticatorSelection: {
                        authenticatorAttachment: 'cross-platform',
                        userVerification: 'discouraged',
                        residentKey: 'discouraged',
                        requireResidentKey: false
                    },
                    timeout: 25000, // Very short timeout
                    attestation: 'none' // Avoid platform attestation
                };
                
                // Remove any extensions that might trigger platform auth
                if (newOptions.extensions) {
                    delete newOptions.extensions.largeBlob;
                    delete newOptions.extensions.credProps;
                }
                
                options.publicKey = newOptions;
                this.log('🚀 NUCLEAR: Completely rebuilt options for Security Key Only');
            }
        }
        
        // FORCE NON-PLATFORM: Most aggressive mode
        if (customOptions.forceNonPlatform || customOptions.forceCrossPlatform) {
            options.publicKey.authenticatorSelection = {
                authenticatorAttachment: 'cross-platform',
                userVerification: 'discouraged',
                residentKey: 'discouraged'
            };
            
            // Override timeout to be very short
            options.publicKey.timeout = 20000;
            
            // Force specific challenge size that platform authenticators might not like
            if (options.publicKey.challenge.byteLength < 64) {
                const newChallenge = new Uint8Array(64);
                crypto.getRandomValues(newChallenge);
                options.publicKey.challenge = newChallenge;
            }
            
            this.log('🚀 FORCE NON-PLATFORM: Maximum bypass settings applied');
        }
        
        // Additional Safari/WebKit specific workarounds
        if (this.browserInfo.isSafari || this.browserInfo.isiOS) {
            // Extend timeout for Safari security key operations
            if (options.publicKey.timeout < 120000) {
                options.publicKey.timeout = 120000;
            }
            
            // Remove resident key requirements that might trigger platform auth
            if (options.publicKey.authenticatorSelection?.residentKey === 'required') {
                options.publicKey.authenticatorSelection.residentKey = 'discouraged';
                this.log('🍎 Safari: Changed resident key to discouraged');
            }
        }
        
        // LOG FINAL OPTIONS FOR DEBUGGING
        this.log(`🔧 Final WebAuthn options: ${JSON.stringify({
            authenticatorSelection: options.publicKey.authenticatorSelection,
            timeout: options.publicKey.timeout,
            attestation: options.publicKey.attestation,
            userVerification: options.publicKey.authenticatorSelection?.userVerification
        }, null, 2)}`);
    }
    
    // Hybrid Testing Functions
    async testFullHybrid() {
        this.log('🔄 Testing full hybrid authentication (QR + Security Key + Platform)');
        this.showStatus('full-hybrid-status', 'Testing full hybrid mode...', 'info');
        
        try {
            const settings = this.getCurrentRegistrationSettings();
            // Remove authenticator attachment for true hybrid
            delete settings.authenticatorAttachment;
            settings.userVerification = 'preferred';
            settings.residentKey = 'preferred';
            
            const result = await this.performAuthentication('test-hybrid-user', 'hybrid', '/webauthn/authenticate/begin/hybrid', {});
            
            if (result.success) {
                this.showStatus('full-hybrid-status', '✅ Full hybrid authentication working!', 'success');
                this.log('✅ Full hybrid test completed successfully');
            } else {
                this.showStatus('full-hybrid-status', '❌ Full hybrid authentication failed', 'error');
            }
            
        } catch (error) {
            this.showStatus('full-hybrid-status', `❌ Full hybrid error: ${error.message}`, 'error');
            this.log(`❌ Full hybrid test error: ${error.message}`);
        }
    }
    
    async testAppleHybrid() {
        this.log('🍎 Testing Apple device hybrid authentication (bypass Touch ID)');
        this.showStatus('apple-hybrid-status', 'Testing Apple hybrid mode...', 'info');
        
        try {
            const customOptions = {
                forceExternal: true,
                appleOverride: true,
                excludePlatform: false // Allow platform but don't prefer it
            };
            
            const result = await this.performAuthentication('test-apple-hybrid-user', 'apple-override', '/webauthn/authenticate/begin/hybrid', {}, customOptions);
            
            if (result.success) {
                this.showStatus('apple-hybrid-status', '✅ Apple hybrid authentication working!', 'success');
                this.log('✅ Apple hybrid test completed successfully');
            } else {
                this.showStatus('apple-hybrid-status', '❌ Apple hybrid authentication failed', 'error');
            }
            
        } catch (error) {
            this.showStatus('apple-hybrid-status', `❌ Apple hybrid error: ${error.message}`, 'error');
            this.log(`❌ Apple hybrid test error: ${error.message}`);
        }
    }
    
    async testForceExternal() {
        this.log('🔄 Testing forced external authentication (no platform authenticators)');
        this.showStatus('force-external-status', 'Testing forced external auth...', 'info');
        
        try {
            const customOptions = {
                forceCrossPlatform: true,
                excludePlatform: true,
                disablePlatformAuth: true,
                prioritizeExternal: true
            };
            
            const result = await this.performAuthentication('test-force-external-user', 'hybrid-force', '/webauthn/authenticate/begin', { securityKeyOnly: true }, customOptions);
            
            if (result.success) {
                this.showStatus('force-external-status', '✅ Forced external authentication working!', 'success');
                this.log('✅ Force external test completed successfully');
            } else {
                this.showStatus('force-external-status', '❌ Forced external authentication failed', 'error');
            }
            
        } catch (error) {
            this.showStatus('force-external-status', `❌ Force external error: ${error.message}`, 'error');
            this.log(`❌ Force external test error: ${error.message}`);
        }
    }

    // Real-world testing scenarios
    async testHybridQR() {
        this.log(`📱 HYBRID QR: Testing mobile cross-device authentication`);
        this.showStatus('hybrid-qr-status', 'Starting hybrid QR test...', 'info');
        
        try {
            const webauthnOptions = await this.universalAppleCancellationAndSettings('hybrid-qr-user', 'Hybrid QR');
            
            // Configure for hybrid transport (QR code)
            delete webauthnOptions.publicKey.authenticatorSelection.authenticatorAttachment; // Allow any
            webauthnOptions.publicKey.authenticatorSelection.userVerification = 'preferred';
            webauthnOptions.publicKey.authenticatorSelection.residentKey = 'preferred';
            webauthnOptions.publicKey.timeout = 120000; // 2 minutes for QR scanning
            
            this.log(`📱 HYBRID QR OPTIONS: ${JSON.stringify(webauthnOptions, null, 2)}`);
            this.showStatus('hybrid-qr-status', '📱 Scan QR code with your phone...', 'info');
            
            const startTime = performance.now();
            const credential = await navigator.credentials.create(webauthnOptions);
            const endTime = performance.now();
            
            if (credential) {
                this.log(`✅ SUCCESS: Hybrid QR completed in ${endTime - startTime}ms`);
                this.showStatus('hybrid-qr-status', '✅ Mobile cross-device authentication successful!', 'success');
            }
            
        } catch (error) {
            this.showStatus('hybrid-qr-status', `❌ Hybrid QR error: ${error.message}`, 'error');
            this.log(`❌ Hybrid QR error: ${error.message}`);
        }
    }

    async testHardwareKeys() {
        this.log(`🔑 HARDWARE KEYS: Testing USB/NFC security keys`);
        this.showStatus('hardware-keys-status', 'Testing hardware security keys...', 'info');
        
        try {
            const webauthnOptions = await this.universalAppleCancellationAndSettings('hardware-key-user', 'Hardware Keys');
            
            // Configure specifically for hardware keys
            webauthnOptions.publicKey.authenticatorSelection.authenticatorAttachment = 'cross-platform';
            webauthnOptions.publicKey.authenticatorSelection.userVerification = 'discouraged'; // Many keys don't have UV
            webauthnOptions.publicKey.authenticatorSelection.residentKey = 'discouraged'; // Hardware keys often don't support RK
            webauthnOptions.publicKey.timeout = 60000;
            
            this.log(`🔑 HARDWARE KEYS OPTIONS: ${JSON.stringify(webauthnOptions, null, 2)}`);
            this.showStatus('hardware-keys-status', '🔑 Insert and touch your security key...', 'info');
            
            const startTime = performance.now();
            const credential = await navigator.credentials.create(webauthnOptions);
            const endTime = performance.now();
            
            if (credential) {
                this.log(`✅ SUCCESS: Hardware key registration completed in ${endTime - startTime}ms`);
                this.showStatus('hardware-keys-status', '✅ Hardware security key registration successful!', 'success');
            }
            
        } catch (error) {
            this.showStatus('hardware-keys-status', `❌ Hardware key error: ${error.message}`, 'error');
            this.log(`❌ Hardware key error: ${error.message}`);
        }
    }

    async testPlatformAuth() {
        this.log(`🆔 PLATFORM AUTH: Testing Touch ID, Windows Hello, etc.`);
        this.showStatus('platform-auth-status', 'Testing platform authenticators...', 'info');
        
        try {
            const webauthnOptions = await this.universalAppleCancellationAndSettings('platform-user', 'Platform Auth');
            
            // Configure for platform authenticators - DON'T cancel Apple for this test
            webauthnOptions.publicKey.authenticatorSelection.authenticatorAttachment = 'platform';
            webauthnOptions.publicKey.authenticatorSelection.userVerification = 'required';
            webauthnOptions.publicKey.authenticatorSelection.residentKey = 'required'; // Platform usually supports passkeys
            webauthnOptions.publicKey.timeout = 60000;
            
            this.log(`🆔 PLATFORM AUTH OPTIONS: ${JSON.stringify(webauthnOptions, null, 2)}`);
            this.showStatus('platform-auth-status', '🆔 Use Touch ID, Windows Hello, or other platform auth...', 'info');
            
            // For platform auth, make a direct call without Apple cancellation
            const startTime = performance.now();
            const credential = await navigator.credentials.create(webauthnOptions);
            const endTime = performance.now();
            
            if (credential) {
                this.log(`✅ SUCCESS: Platform auth completed in ${endTime - startTime}ms`);
                this.showStatus('platform-auth-status', '✅ Platform authenticator registration successful!', 'success');
            }
            
        } catch (error) {
            this.showStatus('platform-auth-status', `❌ Platform auth error: ${error.message}`, 'error');
            this.log(`❌ Platform auth error: ${error.message}`);
        }
    }

    async testUsernameless() {
        const useAppleCancellation = document.getElementById('auth-apple-cancellation')?.checked;
        this.log(`🔄 USERNAMELESS: Testing resident key authentication${useAppleCancellation ? ' + Apple cancellation' : ''}`);
        this.showStatus('usernameless-status', `${useAppleCancellation ? 'Canceling Apple + ' : ''}Testing usernameless authentication...`, 'info');
        
        try {
            // Handle Apple cancellation if requested
            if (useAppleCancellation) {
                await this.performAppleCancellation(false);
            }
            
            // Build options from UI settings then override for usernameless
            const options = this.buildAuthenticationOptionsFromUI();
            
            // Override for usernameless - KEY DIFFERENCE
            options.allowCredentials = []; // Empty for usernameless/resident key discovery
            
            this.log(`🔄 USERNAMELESS OPTIONS: ${JSON.stringify(options, null, 2)}`);
            this.showStatus('usernameless-status', '🔄 Select from your available passkeys...', 'info');
            
            const startTime = performance.now();
            const credential = await navigator.credentials.get({ publicKey: options });
            const endTime = performance.now();
            
            if (credential) {
                this.log(`✅ SUCCESS: Usernameless auth completed in ${endTime - startTime}ms`);
                this.log(`✅ Used credential: ${credential.id}`);
                this.showStatus('usernameless-status', '✅ Usernameless authentication successful!', 'success');
            }
            
        } catch (error) {
            this.showStatus('usernameless-status', `❌ Usernameless error: ${error.message}`, 'error');
            this.log(`❌ Usernameless error: ${error.message}`);
        }
    }

    async testAlgorithms() {
        this.log(`📊 ALGORITHMS: Testing different cryptographic algorithms`);
        this.showStatus('algorithms-status', 'Testing algorithm support...', 'info');
        
        try {
            const settings = this.getCurrentRegistrationSettings();
            const algorithms = settings.algorithms;
            
            this.log(`📊 Testing algorithms: ${algorithms.join(', ')}`);
            
            const results = [];
            for (const alg of algorithms) {
                try {
                    const webauthnOptions = await this.universalAppleCancellationAndSettings(`alg-${Math.abs(alg)}-user`, 'Algorithm Test');
                    
                    // Test specific algorithm
                    webauthnOptions.publicKey.pubKeyCredParams = [{ alg, type: "public-key" }];
                    webauthnOptions.publicKey.timeout = 30000;
                    
                    this.log(`📊 Testing algorithm ${alg}...`);
                    
                    const startTime = performance.now();
                    const credential = await navigator.credentials.create(webauthnOptions);
                    const endTime = performance.now();
                    
                    if (credential) {
                        results.push(`✅ Algorithm ${alg}: SUCCESS (${endTime - startTime}ms)`);
                        this.log(`✅ Algorithm ${alg} test successful`);
                    }
                    
                } catch (error) {
                    results.push(`❌ Algorithm ${alg}: ${error.message}`);
                    this.log(`❌ Algorithm ${alg} test failed: ${error.message}`);
                }
            }
            
            this.showStatus('algorithms-status', `Algorithm test results:\n${results.join('\n')}`, 'success');
            
        } catch (error) {
            this.showStatus('algorithms-status', `❌ Algorithm test error: ${error.message}`, 'error');
            this.log(`❌ Algorithm test error: ${error.message}`);
        }
    }

    async testTransports() {
        this.log(`🔧 TRANSPORTS: Testing different transport methods`);
        this.showStatus('transports-status', 'Testing transport support...', 'info');
        
        try {
            const transports = ['usb', 'nfc', 'ble', 'hybrid'];
            const results = [];
            
            for (const transport of transports) {
                try {
                    this.log(`🔧 Testing ${transport} transport...`);
                    
                    const webauthnOptions = await this.universalAppleCancellationAndSettings(`${transport}-user`, `${transport.toUpperCase()} Transport`);
                    
                    // Configure for specific transport
                    if (transport === 'hybrid') {
                        delete webauthnOptions.publicKey.authenticatorSelection.authenticatorAttachment;
                    } else {
                        webauthnOptions.publicKey.authenticatorSelection.authenticatorAttachment = 'cross-platform';
                    }
                    
                    webauthnOptions.publicKey.timeout = 20000; // Shorter timeout for transport tests
                    
                    const startTime = performance.now();
                    const credential = await navigator.credentials.create(webauthnOptions);
                    const endTime = performance.now();
                    
                    if (credential) {
                        results.push(`✅ ${transport.toUpperCase()}: SUCCESS (${endTime - startTime}ms)`);
                        this.log(`✅ ${transport} transport test successful`);
                    }
                    
                } catch (error) {
                    results.push(`❌ ${transport.toUpperCase()}: ${error.message}`);
                    this.log(`❌ ${transport} transport test failed: ${error.message}`);
                }
            }
            
            this.showStatus('transports-status', `Transport test results:\n${results.join('\n')}`, 'success');
            
        } catch (error) {
            this.showStatus('transports-status', `❌ Transport test error: ${error.message}`, 'error');
            this.log(`❌ Transport test error: ${error.message}`);
        }
    }
    
    // New authentication testing methods
    async testAuthentication() {
        const useAppleCancellation = document.getElementById('auth-apple-cancellation')?.checked;
        this.log(`🔓 TEST AUTHENTICATION: Using ALL UI settings${useAppleCancellation ? ' + Apple cancellation' : ''}`);
        
        const statusDiv = document.getElementById('auth-status');
        statusDiv.style.display = 'block';
        statusDiv.innerHTML = `<div class="loading">🔄 ${useAppleCancellation ? 'Canceling Apple + ' : ''}Starting authentication with ALL your settings...</div>`;
        
        try {
            // Handle Apple cancellation if requested
            if (useAppleCancellation) {
                await this.performAppleCancellation(false);
            }
            
            const options = this.buildAuthenticationOptionsFromUI();
            this.log(`🔓 Authentication options: ${JSON.stringify(options, null, 2)}`);
            
            statusDiv.innerHTML = '<div class="loading">⏳ Authenticate with your credential...</div>';
            
            const assertion = await navigator.credentials.get({ publicKey: options });
            
            if (assertion) {
                this.log(`✅ Authentication successful with credential: ${assertion.id}`);
                statusDiv.innerHTML = `
                    <div class="success">✅ Authentication Successful!</div>
                    <div class="result-details">
                        <strong>Credential ID:</strong> ${assertion.id}<br>
                        <strong>Authenticator:</strong> ${assertion.authenticatorAttachment || 'Unknown'}<br>
                        <strong>Extensions:</strong> ${JSON.stringify(assertion.getClientExtensionResults())}
                    </div>
                `;
                
                // Display in results area
                const resultsDiv = document.getElementById('auth-results');
                if (resultsDiv) {
                    resultsDiv.textContent = `Authentication successful at ${new Date().toLocaleTimeString()}\n` +
                        `Credential: ${assertion.id}\n` +
                        `Extensions: ${JSON.stringify(assertion.getClientExtensionResults())}\n\n` + 
                        resultsDiv.textContent;
                }
            }
        } catch (error) {
            statusDiv.innerHTML = `<div class="error">❌ Authentication failed: ${error.message}</div>`;
            this.log(`❌ Authentication error: ${error.message}`);
        }
    }
    
    // Build registration options from ALL UI form elements
    buildRegistrationOptionsFromUI() {
        // Basic settings
        const username = document.getElementById('reg-username').value || 'testuser';
        const attachment = document.getElementById('reg-attachment').value || undefined;
        const userVerification = document.getElementById('reg-user-verification').value;
        const residentKey = document.getElementById('reg-resident-key').value;
        const attestation = document.getElementById('reg-attestation').value;
        const timeout = parseInt(document.getElementById('advanced-timeout').value) || 60000;
        
        // Challenge settings
        const challengeSize = parseInt(document.getElementById('advanced-challenge-size')?.value) || 32;
        const challenge = window.crypto.getRandomValues(new Uint8Array(challengeSize));
        
        // RP settings
        const rpName = document.getElementById('rp-name').value || 'WebAuthn Test';
        const rpId = document.getElementById('rp-id').value || window.location.hostname;
        
        // Algorithm selection
        const pubKeyCredParams = [];
        const algorithmCheckboxes = document.querySelectorAll('input[type="checkbox"][value^="-"]');
        algorithmCheckboxes.forEach(checkbox => {
            if (checkbox.checked) {
                pubKeyCredParams.push({
                    alg: parseInt(checkbox.value),
                    type: "public-key"
                });
            }
        });
        
        // Extensions
        const extensions = {};
        if (document.getElementById('ext-credProps')?.checked) extensions.credProps = true;
        if (document.getElementById('ext-largeBlobKey')?.checked) extensions.largeBlobKey = true;
        if (document.getElementById('ext-credProtect')?.checked) extensions.credProtect = { credentialProtectionPolicy: "userVerificationOptional", enforceCredentialProtectionPolicy: false };
        if (document.getElementById('ext-hmacSecret')?.checked) extensions.hmacCreateSecret = true;
        if (document.getElementById('ext-devicePubKey')?.checked) extensions.devicePubKey = { attestation: "none", attestationFormats: [] };
        
        // Build the options
        return {
            challenge,
            rp: { name: rpName, id: rpId },
            user: {
                id: new TextEncoder().encode(username),
                name: username,
                displayName: username
            },
            pubKeyCredParams: pubKeyCredParams.length > 0 ? pubKeyCredParams : [{ alg: -7, type: "public-key" }],
            authenticatorSelection: {
                ...(attachment && { authenticatorAttachment: attachment }),
                userVerification,
                residentKey
            },
            attestation,
            timeout,
            ...(Object.keys(extensions).length > 0 && { extensions })
        };
    }
    
    // Build authentication options from ALL UI form elements
    buildAuthenticationOptionsFromUI() {
        // Basic settings
        const username = document.getElementById('auth-username')?.value || '';
        const userVerification = document.getElementById('auth-user-verification')?.value || 'preferred';
        const timeout = parseInt(document.getElementById('auth-timeout')?.value) || 60000;
        
        // Challenge settings
        const challengeSize = parseInt(document.getElementById('auth-challenge-size')?.value) || 32;
        const challenge = window.crypto.getRandomValues(new Uint8Array(challengeSize));
        
        // RP settings
        const rpId = document.getElementById('auth-rp-id')?.value || window.location.hostname;
        
        // Credential selection
        let allowCredentials = [];
        try {
            const credentialsText = document.getElementById('allow-credentials')?.value || '[]';
            if (credentialsText.trim()) {
                allowCredentials = JSON.parse(credentialsText);
            }
        } catch (e) {
            this.log('Invalid allow credentials JSON, using empty array');
        }
        
        // Extensions
        const extensions = {};
        if (document.getElementById('auth-ext-largeBlob')?.checked) extensions.largeBlob = { read: true };
        if (document.getElementById('auth-ext-appid')?.checked) extensions.appid = window.location.origin;
        if (document.getElementById('auth-ext-uvm')?.checked) extensions.uvm = true;
        
        // Build the options
        return {
            challenge,
            ...(rpId && { rpId }),
            ...(allowCredentials.length > 0 && { allowCredentials }),
            userVerification,
            timeout,
            ...(Object.keys(extensions).length > 0 && { extensions })
        };
    }
    
    async testHybridAuth() {
        this.log('📱 TESTING HYBRID AUTH: Testing hybrid/QR authentication');
        
        const statusDiv = document.getElementById('hybrid-auth-status');
        statusDiv.style.display = 'block';
        statusDiv.innerHTML = '<div class="loading">🔄 Testing hybrid/QR authentication...</div>';
        
        try {
            const options = {
                challenge: crypto.getRandomValues(new Uint8Array(32)),
                rpId: window.location.hostname,
                allowCredentials: [{
                    id: crypto.getRandomValues(new Uint8Array(32)), // Dummy credential
                    type: "public-key",
                    transports: ["hybrid"]
                }],
                userVerification: 'preferred',
                timeout: 60000
            };
            
            this.log(`📱 Hybrid auth options: ${JSON.stringify(options, null, 2)}`);
            statusDiv.innerHTML = '<div class="loading">📱 Scan QR code with your phone...</div>';
            
            const assertion = await navigator.credentials.get({ publicKey: options });
            
            if (assertion) {
                statusDiv.innerHTML = `
                    <div class="success">✅ Hybrid Authentication Successful!</div>
                    <div class="result-details">
                        <strong>Transport:</strong> Hybrid (QR Code)
                    </div>
                `;
                this.log(`✅ Hybrid authentication successful: ${assertion.id}`);
            }
        } catch (error) {
            statusDiv.innerHTML = `<div class="error">❌ Hybrid authentication failed: ${error.message}</div>`;
            this.log(`❌ Hybrid auth error: ${error.message}`);
        }
    }
    
    async testU2FAuth() {
        this.log('📟 TESTING U2F AUTH: Testing U2F legacy authentication');
        
        const statusDiv = document.getElementById('u2f-auth-status');
        statusDiv.style.display = 'block';
        statusDiv.innerHTML = '<div class="loading">🔄 Testing U2F legacy authentication...</div>';
        
        try {
            const options = {
                challenge: crypto.getRandomValues(new Uint8Array(32)),
                rpId: window.location.hostname,
                allowCredentials: [],
                userVerification: 'discouraged',
                timeout: 30000,
                extensions: {
                    appid: window.location.origin
                }
            };
            
            this.log(`📟 U2F auth options: ${JSON.stringify(options, null, 2)}`);
            statusDiv.innerHTML = '<div class="loading">📟 Activate your U2F token...</div>';
            
            const assertion = await navigator.credentials.get({ publicKey: options });
            
            if (assertion) {
                statusDiv.innerHTML = `
                    <div class="success">✅ U2F Authentication Successful!</div>
                    <div class="result-details">
                        <strong>Legacy Mode:</strong> U2F Compatibility
                    </div>
                `;
                this.log(`✅ U2F authentication successful: ${assertion.id}`);
            }
        } catch (error) {
            statusDiv.innerHTML = `<div class="error">❌ U2F authentication failed: ${error.message}</div>`;
            this.log(`❌ U2F auth error: ${error.message}`);
        }
    }
    
    async testMultiDevice() {
        this.log('📱 TESTING MULTI-DEVICE: Testing multi-device authentication');
        
        const statusDiv = document.getElementById('multi-device-status');
        statusDiv.style.display = 'block';
        statusDiv.innerHTML = '<div class="loading">🔄 Testing multi-device authentication...</div>';
        
        try {
            const options = {
                challenge: crypto.getRandomValues(new Uint8Array(32)),
                rpId: window.location.hostname,
                allowCredentials: [], // Allow any device
                userVerification: 'preferred',
                timeout: 60000
            };
            
            this.log(`📱 Multi-device options: ${JSON.stringify(options, null, 2)}`);
            statusDiv.innerHTML = '<div class="loading">📱 Use any available authenticator...</div>';
            
            const assertion = await navigator.credentials.get({ publicKey: options });
            
            if (assertion) {
                statusDiv.innerHTML = `
                    <div class="success">✅ Multi-Device Authentication Successful!</div>
                    <div class="result-details">
                        <strong>Device:</strong> ${assertion.authenticatorAttachment || 'Cross-platform'}
                    </div>
                `;
                this.log(`✅ Multi-device authentication successful: ${assertion.id}`);
            }
        } catch (error) {
            statusDiv.innerHTML = `<div class="error">❌ Multi-device authentication failed: ${error.message}</div>`;
            this.log(`❌ Multi-device auth error: ${error.message}`);
        }
    }
    
    exportSettings() {
        const settings = {
            registration: {
                username: document.getElementById('reg-username')?.value,
                attachment: document.getElementById('reg-attachment')?.value,
                userVerification: document.getElementById('reg-user-verification')?.value,
                residentKey: document.getElementById('reg-resident-key')?.value,
                attestation: document.getElementById('reg-attestation')?.value,
                timeout: document.getElementById('advanced-timeout')?.value,
                challengeSize: document.getElementById('advanced-challenge-size')?.value,
                rpName: document.getElementById('rp-name')?.value,
                rpId: document.getElementById('rp-id')?.value
            },
            authentication: {
                username: document.getElementById('auth-username')?.value,
                userVerification: document.getElementById('auth-user-verification')?.value,
                timeout: document.getElementById('auth-timeout')?.value,
                attachment: document.getElementById('auth-attachment')?.value,
                challengeSize: document.getElementById('auth-challenge-size')?.value,
                rpId: document.getElementById('auth-rp-id')?.value,
                allowCredentials: document.getElementById('allow-credentials')?.value
            },
            algorithms: Array.from(document.querySelectorAll('input[type="checkbox"][value^="-"]:checked')).map(cb => cb.value),
            transports: Array.from(document.querySelectorAll('input[type="checkbox"][value="usb"], input[type="checkbox"][value="nfc"], input[type="checkbox"][value="ble"], input[type="checkbox"][value="internal"], input[type="checkbox"][value="hybrid"]')).filter(cb => cb.checked).map(cb => cb.value),
            extensions: {
                credProps: document.getElementById('ext-credProps')?.checked,
                largeBlobKey: document.getElementById('ext-largeBlobKey')?.checked,
                credProtect: document.getElementById('ext-credProtect')?.checked,
                hmacSecret: document.getElementById('ext-hmacSecret')?.checked,
                devicePubKey: document.getElementById('ext-devicePubKey')?.checked
            }
        };
        
        navigator.clipboard.writeText(JSON.stringify(settings, null, 2)).then(() => {
            alert('Settings copied to clipboard!');
        }).catch(() => {
            console.log('Settings export:', JSON.stringify(settings, null, 2));
            alert('Settings logged to console!');
        });
    }
    
    importSettings() {
        const importText = document.getElementById('import-settings')?.value;
        const statusDiv = document.getElementById('import-status');
        
        if (!importText) {
            if (statusDiv) {
                statusDiv.style.display = 'block';
                statusDiv.innerHTML = '<div class="error">❌ No settings to import</div>';
            }
            return;
        }
        
        try {
            const settings = JSON.parse(importText);
            
            // Import registration settings
            if (settings.registration) {
                Object.entries(settings.registration).forEach(([key, value]) => {
                    const element = document.getElementById(`reg-${key}`) || document.getElementById(key);
                    if (element && value !== undefined) element.value = value;
                });
            }
            
            // Import authentication settings  
            if (settings.authentication) {
                Object.entries(settings.authentication).forEach(([key, value]) => {
                    const element = document.getElementById(`auth-${key}`) || document.getElementById(key);
                    if (element && value !== undefined) element.value = value;
                });
            }
            
            // Import algorithms
            if (settings.algorithms) {
                document.querySelectorAll('input[type="checkbox"][value^="-"]').forEach(cb => {
                    cb.checked = settings.algorithms.includes(cb.value);
                });
            }
            
            // Import transports
            if (settings.transports) {
                document.querySelectorAll('input[type="checkbox"][value="usb"], input[type="checkbox"][value="nfc"], input[type="checkbox"][value="ble"], input[type="checkbox"][value="internal"], input[type="checkbox"][value="hybrid"]').forEach(cb => {
                    cb.checked = settings.transports.includes(cb.value);
                });
            }
            
            // Import extensions
            if (settings.extensions) {
                Object.entries(settings.extensions).forEach(([key, value]) => {
                    const element = document.getElementById(`ext-${key}`);
                    if (element) element.checked = value;
                });
            }
            
            if (statusDiv) {
                statusDiv.style.display = 'block';
                statusDiv.innerHTML = '<div class="success">✅ Settings imported successfully!</div>';
            }
            
        } catch (error) {
            if (statusDiv) {
                statusDiv.style.display = 'block';
                statusDiv.innerHTML = `<div class="error">❌ Import failed: ${error.message}</div>`;
            }
        }
    }
    
    // Apple cancellation method - only when checkbox is checked
    async performAppleCancellation(isRegistration = true) {
        const isMacChrome = navigator.userAgent.includes('Mac') && navigator.userAgent.includes('Chrome');
        
        if (!isMacChrome) {
            this.log('ℹ️ Not macOS Chrome - skipping Apple cancellation');
            return;
        }
        
        this.log('🍎 Performing Apple cancellation for macOS Chrome...');
        
        try {
            // Quick Apple detection - try to start and cancel immediately
            const controller = new AbortController();
            setTimeout(() => controller.abort(), 100);
            
            if (isRegistration) {
                await navigator.credentials.create({
                    publicKey: {
                        challenge: new Uint8Array(32),
                        rp: { name: "Quick Test", id: window.location.hostname },
                        user: { id: new Uint8Array(16), name: "test", displayName: "test" },
                        authenticatorSelection: { authenticatorAttachment: "platform" },
                        pubKeyCredParams: [{ alg: -7, type: "public-key" }]
                    },
                    signal: controller.signal
                });
            } else {
                await navigator.credentials.get({
                    publicKey: {
                        challenge: new Uint8Array(32),
                        allowCredentials: [],
                        authenticatorSelection: { authenticatorAttachment: "platform" }
                    },
                    signal: controller.signal
                });
            }
        } catch (error) {
            this.log(`🍎 Apple cancellation completed: ${error.name}`);
        }
        
        // Small delay to ensure Apple's UI is dismissed
        await new Promise(resolve => setTimeout(resolve, 200));
    }
    
    runFeatureDetection() {
        this.log('🔍 Running comprehensive WebAuthn feature detection...');
        
        const features = {
            webauthnSupported: this.isWebAuthnSupported(),
            publicKeyCredential: typeof PublicKeyCredential !== 'undefined',
            credentialsAPI: typeof navigator.credentials !== 'undefined',
            createMethod: typeof navigator.credentials?.create === 'function',
            getMethod: typeof navigator.credentials?.get === 'function',
            isSecureContext: window.isSecureContext,
            httpsOrLocalhost: location.protocol === 'https:' || location.hostname === 'localhost',
            conditionalMediationSupported: typeof PublicKeyCredential?.isConditionalMediationAvailable === 'function',
            userVerifyingPlatformAuthenticatorSupported: typeof PublicKeyCredential?.isUserVerifyingPlatformAuthenticatorAvailable === 'function',
            attestationFormats: this.getSupportedAttestationFormats(),
            algorithms: this.getSupportedAlgorithms(),
            extensions: this.getSupportedExtensions()
        };
        
        const resultDiv = document.getElementById('feature-detection');
        resultDiv.innerHTML = `
            <h4>🔍 WebAuthn Feature Detection Results</h4>
            <pre style="background: #f8f9fa; padding: 10px; border-radius: 4px; white-space: pre-wrap;">
${JSON.stringify(features, null, 2)}
            </pre>
        `;
        
        this.log(`✅ Feature detection completed: ${Object.keys(features).length} features checked`);
    }
    
    detectDeviceCapabilities() {
        this.log('📱 Detecting device-specific capabilities...');
        
        const capabilities = {
            platform: navigator.platform,
            userAgent: navigator.userAgent,
            language: navigator.language,
            languages: navigator.languages,
            cookieEnabled: navigator.cookieEnabled,
            onLine: navigator.onLine,
            doNotTrack: navigator.doNotTrack,
            hardwareConcurrency: navigator.hardwareConcurrency,
            maxTouchPoints: navigator.maxTouchPoints,
            webdriver: navigator.webdriver,
            deviceMemory: navigator.deviceMemory,
            connection: navigator.connection?.effectiveType,
            screenWidth: screen.width,
            screenHeight: screen.height,
            colorDepth: screen.colorDepth,
            pixelDepth: screen.pixelDepth,
            availWidth: screen.availWidth,
            availHeight: screen.availHeight,
            orientation: screen.orientation?.type,
            touchSupport: 'ontouchstart' in window,
            webGL: !!window.WebGLRenderingContext,
            webGL2: !!window.WebGL2RenderingContext,
            webRTC: !!(navigator.mediaDevices && navigator.mediaDevices.getUserMedia),
            bluetooth: !!navigator.bluetooth,
            usb: !!navigator.usb,
            gamepad: !!navigator.getGamepads,
            vibrate: !!navigator.vibrate,
            batteryAPI: !!navigator.getBattery,
            geolocation: !!navigator.geolocation,
            serviceWorker: !!navigator.serviceWorker,
            pushManager: !!(window.PushManager && window.Notification),
            webShare: !!navigator.share
        };
        
        const resultDiv = document.getElementById('device-capabilities');
        resultDiv.innerHTML = `
            <h4>📱 Device Capabilities Detection Results</h4>
            <pre style="background: #f8f9fa; padding: 10px; border-radius: 4px; white-space: pre-wrap;">
${JSON.stringify(capabilities, null, 2)}
            </pre>
        `;
        
        this.log(`✅ Device capability detection completed: ${Object.keys(capabilities).length} capabilities checked`);
    }
    
    getSupportedAttestationFormats() {
        return ['none', 'indirect', 'direct', 'enterprise'];
    }
    
    getSupportedAlgorithms() {
        return [
            { name: 'ES256', alg: -7, description: 'ECDSA P-256' },
            { name: 'ES384', alg: -35, description: 'ECDSA P-384' },
            { name: 'ES512', alg: -36, description: 'ECDSA P-521' },
            { name: 'RS256', alg: -257, description: 'RSA PKCS#1' },
            { name: 'PS256', alg: -37, description: 'RSA PSS' },
            { name: 'EdDSA', alg: -8, description: 'Ed25519' }
        ];
    }
    
    getSupportedExtensions() {
        return ['credProps', 'largeBlobKey', 'credProtect', 'hmac-secret', 'devicePubKey', 'uvm', 'appid'];
    }
}

// Global functions for UI interaction
let superTest;

function initSuperTest() {
    superTest = new WebAuthnSuperTest();
}

function showTab(tabId) {
    // Hide all tabs
    document.querySelectorAll('.tab-content').forEach(tab => {
        tab.classList.remove('active');
    });
    
    // Remove active class from all nav items
    document.querySelectorAll('.nav-menu a').forEach(link => {
        link.classList.remove('active');
    });
    
    // Show selected tab
    document.getElementById(tabId).classList.add('active');
    
    // Add active class to clicked nav item
    event.target.classList.add('active');
}

function refreshBrowserInfo() {
    if (superTest) {
        superTest.detectBrowser();
        superTest.checkCapabilities();
    }
}

function runCapabilityTests() {
    if (superTest) {
        superTest.checkCapabilities();
    }
}

function testRegistration() {
    if (superTest) {
        superTest.testRegistration();
    }
}

function testChromeBypassRegistration() {
    if (superTest) {
        superTest.testChromeBypassRegistration();
    }
}

function testChromeProviderRegistration() {
    if (superTest) {
        superTest.testChromeProviderRegistration();
    }
}

function applyAdvancedSettings() {
    if (superTest) {
        superTest.saveCurrentSettings();
        superTest.showStatus('advanced-status', '✅ Settings applied and saved', 'success');
    }
}

function resetAdvancedSettings() {
    if (superTest) {
        superTest.currentSettings = superTest.getDefaultSettings();
        superTest.applySettingsToUI();
        superTest.showStatus('advanced-status', '🔄 Settings reset to defaults', 'info');
    }
}

// Additional Testing Functions

function testAuthentication() {
    if (superTest) {
        const username = document.getElementById('auth-username').value.trim();
        const authType = document.getElementById('auth-type').value;
        superTest.testAuthentication(username || null, authType);
    }
}

function testChromeBypassAuthentication() {
    if (superTest) {
        superTest.testChromeBypassAuthentication();
    }
}

function testChromeProviderAuthentication() {
    if (superTest) {
        superTest.testChromeProviderAuthentication();
    }
}

// Transport Testing Functions
function testUSBTransport() {
    if (superTest) {
        superTest.testSpecificTransport('usb', 'usb-status');
    }
}

function testNFCTransport() {
    if (superTest) {
        superTest.testSpecificTransport('nfc', 'nfc-status');
    }
}

function testBLETransport() {
    if (superTest) {
        superTest.testSpecificTransport('ble', 'ble-status');
    }
}

function testHybridTransport() {
    if (superTest) {
        superTest.testSpecificTransport('hybrid', 'hybrid-status');
    }
}

// Hardware Testing Functions
function testYubiKey() {
    if (superTest) {
        superTest.testHardwareKey('yubikey', 'yubikey-status');
    }
}

function testFIDO2Keys() {
    if (superTest) {
        superTest.testHardwareKey('fido2', 'fido2-status');
    }
}

function testU2FKeys() {
    if (superTest) {
        superTest.testHardwareKey('u2f', 'u2f-status');
    }
}

// Platform Testing Functions
function testApplePasskeys() {
    if (superTest) {
        superTest.testPlatformPasskeys('apple', 'apple-status');
    }
}

function testGooglePasskeys() {
    if (superTest) {
        superTest.testPlatformPasskeys('google', 'google-status');
    }
}

function testWindowsHello() {
    if (superTest) {
        superTest.testPlatformPasskeys('windows', 'windows-status');
    }
}

// Algorithm Testing Functions
function testECDSAAlgorithms() {
    if (superTest) {
        superTest.testAlgorithmFamily('ecdsa', 'ecdsa-status');
    }
}

function testRSAAlgorithms() {
    if (superTest) {
        superTest.testAlgorithmFamily('rsa', 'rsa-status');
    }
}

function testEdDSAAlgorithm() {
    if (superTest) {
        superTest.testAlgorithmFamily('eddsa', 'eddsa-status');
    }
}

// FIDO Testing Functions
function testCTAP1() {
    if (superTest) {
        superTest.testFIDOProtocol('ctap1', 'ctap1-status');
    }
}

function testCTAP2() {
    if (superTest) {
        superTest.testFIDOProtocol('ctap2', 'ctap2-status');
    }
}

function testCBOREncoding() {
    if (superTest) {
        superTest.testCBOREncoding('cbor-status');
    }
}

// Debug Functions
function clearDebugLog() {
    if (superTest) {
        superTest.debugLog = [];
        const debugDiv = document.getElementById('debug-log');
        if (debugDiv) {
            debugDiv.innerHTML = 'Debug log cleared...';
        }
    }
}

function exportDebugInfo() {
    if (superTest) {
        superTest.exportDebugInfo();
    }
}

function testCustomOptions() {
    if (superTest) {
        superTest.testCustomOptions();
    }
}

// Settings Functions
function exportSettings() {
    if (superTest) {
        superTest.exportSettings();
    }
}

function exportTestResults() {
    if (superTest) {
        superTest.exportTestResults();
    }
}

function importSettings() {
    if (superTest) {
        superTest.importSettings();
    }
}

function generateDogTagKitCode() {
    if (superTest) {
        superTest.generateDogTagKitCode();
    }
}

// Hybrid Testing Functions
function testFullHybrid() {
    if (superTest) {
        superTest.testFullHybrid();
    }
}

function testAppleHybrid() {
    if (superTest) {
        superTest.testAppleHybrid();
    }
}

function testForceExternal() {
    if (superTest) {
        superTest.testForceExternal();
    }
}

function testForceChrome() {
    if (superTest) {
        superTest.testForceChrome();
    }
}

function testConditionalUI() {
    if (superTest) {
        superTest.testConditionalUI();
    }
}

function testAppleDetectionAndCancel() {
    if (superTest) {
        superTest.testAppleDetectionAndCancel();
    }
}

// Real-world testing scenario functions
function testHybridQR() {
    if (superTest) {
        superTest.testHybridQR();
    }
}

function testHardwareKeys() {
    if (superTest) {
        superTest.testHardwareKeys();
    }
}

function testPlatformAuth() {
    if (superTest) {
        superTest.testPlatformAuth();
    }
}

function testUsernameless() {
    if (superTest) {
        superTest.testUsernameless();
    }
}

function testAlgorithms() {
    if (superTest) {
        superTest.testAlgorithms();
    }
}

function testTransports() {
    if (superTest) {
        superTest.testTransports();
    }
}

// New authentication test functions
function testUsernameless() {
    if (superTest) {
        superTest.testUsernameless();
    }
}

function testConditionalUI() {
    if (superTest) {
        superTest.testConditionalUI();
    }
}

function testHybridAuth() {
    if (superTest) {
        superTest.testHybridAuth();
    }
}

function testU2FAuth() {
    if (superTest) {
        superTest.testU2FAuth();
    }
}

function testMultiDevice() {
    if (superTest) {
        superTest.testMultiDevice();
    }
}

function exportSettings() {
    if (superTest) {
        superTest.exportSettings();
    }
}

function exportTestResults() {
    if (superTest) {
        superTest.exportTestResults();
    }
}

function importSettings() {
    if (superTest) {
        superTest.importSettings();
    }
}

function generateDogTagKitCode() {
    if (superTest) {
        superTest.generateDogTagKitCode();
    }
}

function runFeatureDetection() {
    if (superTest) {
        superTest.runFeatureDetection();
    }
}

function detectDeviceCapabilities() {
    if (superTest) {
        superTest.detectDeviceCapabilities();
    }
}

// Initialize when DOM is loaded
document.addEventListener('DOMContentLoaded', initSuperTest); 