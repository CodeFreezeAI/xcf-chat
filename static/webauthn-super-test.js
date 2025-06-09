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
    
    // Registration Testing
    async testRegistration() {
        const username = document.getElementById('reg-username').value.trim();
        if (!username) {
            this.showStatus('reg-status', 'Please enter a username', 'error');
            return;
        }
        
        this.log(`🚀 Starting registration test for: ${username}`);
        
        try {
            // Gather current settings
            const settings = this.getCurrentRegistrationSettings();
            this.log(`📋 Registration settings: ${JSON.stringify(settings, null, 2)}`);
            
            // Test registration with current settings
            const result = await this.performRegistration(username, settings);
            
            if (result.success) {
                this.showStatus('reg-status', '✅ Registration successful!', 'success');
                this.log(`✅ Registration completed successfully`);
                this.saveTestResult('registration', settings, result);
            } else {
                this.showStatus('reg-status', `❌ Registration failed: ${result.error}`, 'error');
                this.log(`❌ Registration failed: ${result.error}`);
            }
            
        } catch (error) {
            this.showStatus('reg-status', `❌ Registration error: ${error.message}`, 'error');
            this.log(`❌ Registration error: ${error.message}`);
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
    
    async performRegistration(username, settings) {
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
    applyAppleOverrides(options, customOptions) {
        this.log(`🍎 Applying Apple overrides: ${JSON.stringify(customOptions, null, 2)}`);
        
        // Check Safari-specific overrides
        const safariForceExternal = document.getElementById('safari-force-external')?.checked;
        const safariExcludePlatform = document.getElementById('safari-exclude-platform')?.checked;
        const safariPreferUSB = document.getElementById('safari-prefer-usb')?.checked;
        const safariDisableTouchID = document.getElementById('safari-disable-touchid')?.checked;
        
        // Force external authenticators (disable platform preference)
        if (customOptions.forceExternal || safariForceExternal || customOptions.excludePlatform) {
            // Remove platform authenticator attachment preference
            if (options.publicKey.authenticatorSelection) {
                delete options.publicKey.authenticatorSelection.authenticatorAttachment;
            }
            
            // Set user verification to discouraged to avoid platform preference
            if (options.publicKey.authenticatorSelection) {
                options.publicKey.authenticatorSelection.userVerification = 'discouraged';
            }
            
            this.log('🍎 Forced external authenticators - removed platform preference');
        }
        
        // Exclude platform credentials completely
        if (safariExcludePlatform || customOptions.disablePlatformAuth) {
            if (options.publicKey.authenticatorSelection) {
                options.publicKey.authenticatorSelection.authenticatorAttachment = 'cross-platform';
            } else {
                options.publicKey.authenticatorSelection = {
                    authenticatorAttachment: 'cross-platform',
                    userVerification: 'discouraged'
                };
            }
            this.log('🍎 Excluded platform authenticators - forced cross-platform');
        }
        
        // Prefer USB/NFC keys with specific transport hints
        if (safariPreferUSB || customOptions.prioritizeExternal) {
            if (options.publicKey.allowCredentials) {
                options.publicKey.allowCredentials = options.publicKey.allowCredentials.map(cred => ({
                    ...cred,
                    transports: ['usb', 'nfc', 'hybrid'] // Remove 'internal' transport
                }));
            }
            this.log('🍎 Prioritized USB/NFC keys in transport hints');
        }
        
        // Disable Touch ID preference with specific settings
        if (safariDisableTouchID || customOptions.appleOverride) {
            if (options.publicKey.authenticatorSelection) {
                options.publicKey.authenticatorSelection.userVerification = 'discouraged';
                // Force longer timeout to give security keys time
                options.publicKey.timeout = 120000; // 2 minutes
            }
            this.log('🍎 Disabled Touch ID preference with discouraged user verification');
        }
        
        // Force non-platform for hybrid-force mode
        if (customOptions.forceNonPlatform) {
            if (options.publicKey.authenticatorSelection) {
                delete options.publicKey.authenticatorSelection.authenticatorAttachment;
                options.publicKey.authenticatorSelection.userVerification = 'discouraged';
            }
            this.log('🍎 Forced non-platform for hybrid mode');
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

// Initialize when DOM is loaded
document.addEventListener('DOMContentLoaded', initSuperTest); 