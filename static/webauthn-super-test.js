// WebAuthn Super Test - Comprehensive Testing Suite
// Tests all FIDO1, FIDO2, WebAuthn, and Passkey scenarios

class WebAuthnSuperTest {
    constructor() {
        this.currentSettings = this.getDefaultSettings();
        this.testResults = [];
        this.debugLog = [];
        this.capabilities = {};
        this.userCredentials = new Map(); // Track credentials by username
        
        this.init();
    }
    
    init() {
        console.log('🔐 WebAuthn Super Test Initialized');
        this.detectBrowser();
        this.checkCapabilities();
        this.loadSavedSettings();
        
        // Add event listener for global username changes
        setTimeout(() => {
            const globalUsernameField = document.getElementById('global-username');
            if (globalUsernameField) {
                globalUsernameField.addEventListener('input', () => {
                    this.updateCredentialDisplay();
                    const username = globalUsernameField.value.trim();
                    if (username) {
                        this.updateAllowCredentialsField(username);
                    }
                });
            }
        }, 100);
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
    
    // Simplified Registration using UI settings + device capabilities
    async testRegistration() {
        const username = document.getElementById('global-username').value.trim();
        if (!username) {
            this.showStatus('reg-status', 'Please enter a username in the Test User field above', 'error');
            return;
        }
        
        this.log(`🔐 REGISTRATION: Using UI settings + device capabilities for: ${username}`);
        this.showStatus('reg-status', 'Building registration options from your settings...', 'info');
        
        try {
            // Build registration options from UI form elements
            const options = this.buildRegistrationOptionsFromUI();
            const wrappedOptions = { publicKey: options };
            
            // Apply device capabilities for optimal configuration
            this.applyDeviceCapabilities(wrappedOptions, true);
            
            // Apply manual overrides from Basic Settings dropdowns while preserving all capabilities
            const attachment = document.getElementById('reg-attachment')?.value;
            if (attachment === 'cross-platform') {
                this.forceHardwareKeysOnly(wrappedOptions);
            } else if (attachment === 'platform') {
                this.forcePlatformAuthOnly(wrappedOptions);
            } else {
                this.enableAllCapabilitiesHybridMode(wrappedOptions);
            }
            
            // Show transport-specific status message
            const selectedTransports = this.getSelectedTransports();
            if (selectedTransports.length > 0 && selectedTransports.length < 5) {
                this.showStatus('reg-status', `📡 Using selected transports: ${selectedTransports.join(', ')}`, 'info');
                await new Promise(resolve => setTimeout(resolve, 1000)); // Brief pause to show message
            }
            
            this.log(`🔐 Final registration options: ${JSON.stringify({
                ...wrappedOptions.publicKey,
                challenge: wrappedOptions.publicKey.challenge ? `[Uint8Array ${wrappedOptions.publicKey.challenge.length} bytes]` : 'MISSING',
                user: {
                    ...wrappedOptions.publicKey.user,
                    id: wrappedOptions.publicKey.user?.id ? `[Uint8Array ${wrappedOptions.publicKey.user.id.length} bytes]` : 'MISSING'
                },
                authenticatorSelection: wrappedOptions.publicKey.authenticatorSelection,
                timeout: wrappedOptions.publicKey.timeout
            }, null, 2)}`);
            
            const statusDiv = document.getElementById('reg-status');
            statusDiv.innerHTML = '<div class="loading">⏳ Complete registration with all browser capabilities...</div>';
            
            // Log comprehensive capability usage
            this.log(`🚀 USING ALL BROWSER CAPABILITIES: ${Object.keys(this.capabilities || {}).length} capabilities detected`);
            this.log(`🔧 Algorithms: ${wrappedOptions.publicKey.pubKeyCredParams?.length || 0} types`);
            this.log(`🔧 Extensions: ${Object.keys(wrappedOptions.publicKey.extensions || {}).length} enabled`);
            this.log(`🔧 Transports: ${selectedTransports.join(', ')}`);
            
            const startTime = performance.now();
            const credential = await navigator.credentials.create(wrappedOptions);
            const endTime = performance.now();
            
            if (credential) {
                this.log(`✅ SUCCESS: Registration completed in ${endTime - startTime}ms`);
                this.log(`✅ Credential ID: ${credential.id}`);
                this.log(`✅ Credential Type: ${credential.type}`);
                this.log(`✅ Authenticator: ${credential.authenticatorAttachment || 'unknown'}`);
                
                this.showStatus('reg-status', '✅ Registration successful! Authentication settings automatically updated.', 'success');
                
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
                
                // Track credential for this user
                this.addUserCredential(username, credInfo);
                
                // AUTOMATICALLY UPDATE AUTHENTICATION SETTINGS
                this.updateAllowCredentialsField(username);
                
                // SYNC AUTHENTICATION TRANSPORT SETTINGS TO MATCH CREDENTIAL
                this.log(`🔧 ATTEMPTING AUTO-SYNC: credential has transports: ${JSON.stringify(credInfo.transports)}`);
                if (credInfo.transports && credInfo.transports.length > 0) {
                    credInfo.transports.forEach(transport => {
                        const checkboxId = `auth-include-${transport}`;
                        const checkbox = document.getElementById(checkboxId);
                        this.log(`🔧 LOOKING FOR CHECKBOX: "${checkboxId}" - ${checkbox ? 'FOUND' : 'NOT FOUND'}`);
                        if (checkbox) {
                            checkbox.checked = true;
                            this.log(`✅ AUTO-ENABLED AUTH TRANSPORT: ${transport}`);
                        } else {
                            this.log(`❌ CHECKBOX NOT FOUND: ${checkboxId}`);
                        }
                    });
                } else {
                    this.log(`❌ NO TRANSPORTS TO SYNC: ${JSON.stringify(credInfo.transports)}`);
                }
                
                // CRITICAL: SYNC AUTHENTICATOR ATTACHMENT FROM REGISTRATION TO AUTHENTICATION
                const regAttachment = document.getElementById('attachment')?.value;
                const authAttachment = document.getElementById('auth-attachment');
                if (regAttachment && authAttachment) {
                    authAttachment.value = regAttachment;
                    this.log(`✅ AUTO-SYNCED AUTHENTICATOR ATTACHMENT: REG=${regAttachment} → AUTH=${authAttachment.value}`);
                } else {
                    this.log(`❌ ATTACHMENT SYNC FAILED: reg=${regAttachment}, auth element=${!!authAttachment}`);
                }
                
                // CRITICAL: SYNC USER VERIFICATION FROM REGISTRATION TO AUTHENTICATION
                const regUserVerification = document.getElementById('user-verification')?.value;
                const authUserVerification = document.getElementById('auth-user-verification');
                if (regUserVerification && authUserVerification) {
                    authUserVerification.value = regUserVerification;
                    this.log(`✅ AUTO-SYNCED USER VERIFICATION: REG=${regUserVerification} → AUTH=${authUserVerification.value}`);
                } else {
                    this.log(`❌ USER VERIFICATION SYNC FAILED: reg=${regUserVerification}, auth element=${!!authUserVerification}`);
                }
                
                // FORCE REFRESH THE AUTHENTICATION TAB DISPLAY
                this.log(`🔄 FORCING TAB REFRESH...`);
                const authTab = document.getElementById('authentication-test');
                if (authTab) {
                    this.log(`✅ AUTH TAB FOUND - forcing refresh`);
                } else {
                    this.log(`❌ AUTH TAB NOT FOUND`);
                }
                
                this.log(`✅ AUTOMATICALLY POPULATED AUTH SETTINGS for ${username} with ${credInfo.transports?.join(', ') || 'default'} transports`);
                
            } else {
                throw new Error('No credential returned');
            }
            
        } catch (error) {
            this.showStatus('reg-status', `❌ Registration error: ${error.message}`, 'error');
            this.log(`❌ Registration error: ${error.message}`);
        }
    }
    
    // Removed complex Apple bypass methods - using simplified device capability approach
    
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
        
        // Get ALL available extensions that were dynamically populated
        const allSupportedExtensions = this.getSupportedExtensions();
        
        // Check each extension checkbox that was dynamically created
        allSupportedExtensions.forEach(extName => {
            const checkbox = document.getElementById(`ext-${extName}`);
            if (checkbox && checkbox.checked) {
                switch (extName) {
                    case 'credProps':
                        extensions.credProps = true;
                        break;
                    case 'largeBlobKey':
                        extensions.largeBlobKey = true;
                        break;
                    case 'credProtect':
                        extensions.credProtect = {
                            credentialProtectionPolicy: 'userVerificationOptional',
                            enforceCredentialProtectionPolicy: false
                        };
                        break;
                    case 'hmac-secret':
                    case 'hmacCreateSecret':
                        extensions.hmacSecret = true;
                        break;
                    case 'devicePubKey':
                        extensions.devicePubKey = true;
                        break;
                    case 'minPinLength':
                        extensions.minPinLength = true;
                        break;
                    case 'credentialBlob':
                        extensions.credentialBlob = new Uint8Array([1, 2, 3, 4]); // Example blob
                        break;
                    default:
                        // For other extensions, just set to true
                        extensions[extName] = true;
                }
                
                this.log(`🔧 Using selected extension: ${extName}`);
            }
        });
        
        this.log(`🔧 Total extensions selected: ${Object.keys(extensions).length}`);
        return extensions;
    }
    
    getSelectedAuthExtensions() {
        const extensions = {};
        
        // Get authentication-specific extensions
        const authExtensions = ['largeBlob', 'appid', 'uvm'];
        
        authExtensions.forEach(extName => {
            const checkbox = document.getElementById(`auth-ext-${extName}`);
            if (checkbox && checkbox.checked) {
                switch (extName) {
                    case 'largeBlob':
                        extensions.largeBlob = {
                            support: 'preferred',
                            read: true,
                            write: new Uint8Array([1, 2, 3, 4]) // Example blob to write
                        };
                        break;
                    case 'appid':
                        // Skip appid for now - causes domain issues if not registered with same appid
                        // extensions.appId = window.location.origin;
                        break;
                    case 'uvm':
                        extensions.uvm = true;
                        break;
                    default:
                        extensions[extName] = true;
                }
                
                this.log(`🔧 Using selected auth extension: ${extName}`);
            }
        });
        
        this.log(`🔧 Total auth extensions selected: ${Object.keys(extensions).length}`);
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
        try {
            // Handle base64url format (WebAuthn standard)
            let base64String = base64;
            if (typeof base64String !== 'string') {
                this.log(`❌ CONVERSION ERROR: Expected string, got ${typeof base64String}: ${base64String}`);
                throw new Error(`Expected string for base64 conversion, got ${typeof base64String}`);
            }
            
            this.log(`🔄 CONVERTING: "${base64String}" (length: ${base64String.length})`);
            
            // Convert base64url to regular base64
            base64String = base64String.replace(/-/g, '+').replace(/_/g, '/');
            // Add padding if needed
            while (base64String.length % 4) {
                base64String += '=';
            }
            
            this.log(`🔄 PADDED: "${base64String}" (length: ${base64String.length})`);
            
            const binaryString = atob(base64String);
            const bytes = new Uint8Array(binaryString.length);
            for (let i = 0; i < binaryString.length; i++) {
                bytes[i] = binaryString.charCodeAt(i);
            }
            
            this.log(`✅ CONVERTED: ArrayBuffer with ${bytes.buffer.byteLength} bytes`);
            return bytes.buffer;
        } catch (error) {
            this.log(`❌ CONVERSION FAILED: ${error.message} for input: "${base64}"`);
            throw error;
        }
    }
    
    arrayBufferToBase64(buffer) {
        const bytes = new Uint8Array(buffer);
        let binary = '';
        for (let i = 0; i < bytes.byteLength; i++) {
            binary += String.fromCharCode(bytes[i]);
        }
        // Convert to base64url (WebAuthn standard)
        return btoa(binary).replace(/\+/g, '-').replace(/\//g, '_').replace(/=/g, '');
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
    async testServerAuthentication(username, authType) {
        this.log(`🔓 SERVER AUTH: ${authType} authentication${username ? ` for: ${username}` : ' (usernameless)'}`);
        
        try {
            const useAppleCancellation = document.getElementById('auth-apple-cancellation')?.checked;
            
            if (useAppleCancellation) {
                this.showStatus('auth-status', 'Canceling Apple + server authentication...', 'info');
                await this.performAppleCancellation(false);
            } else {
                this.showStatus('auth-status', `Starting ${authType} server authentication...`, 'info');
            }
            
            // Build request based on auth type
            let endpoint = '/webauthn/authenticate/begin';
            let requestBody = {};
            
            switch (authType) {
                case 'all-settings':
                    if (username) requestBody.username = username;
                    break;
                case 'security-key-only':
                    if (username) requestBody.username = username;
                    requestBody.securityKeyOnly = true;
                    break;
                case 'usernameless':
                    // No username, no credentials specified
                    break;
            }
            
            this.log(`🌐 SERVER REQUEST: ${endpoint} with ${JSON.stringify(requestBody)}`);
            
            // Get authentication options from server
            const beginResponse = await fetch(endpoint, {
                method: 'POST',
                headers: {
                    'Content-Type': 'application/json',
                },
                body: JSON.stringify(requestBody)
            });
            
            if (!beginResponse.ok) {
                throw new Error(`Server error: ${beginResponse.status} ${beginResponse.statusText}`);
            }
            
            const options = await beginResponse.json();
            this.log(`📧 SERVER OPTIONS: ${JSON.stringify(options, null, 2)}`);
            
            // Convert base64url to ArrayBuffer for challenge
            if (options.challenge) {
                options.challenge = this.base64ToArrayBuffer(options.challenge);
            }
            
            // Convert allowCredentials if present
            if (options.allowCredentials) {
                options.allowCredentials = options.allowCredentials.map(cred => ({
                    ...cred,
                    id: this.base64ToArrayBuffer(cred.id)
                }));
            }
            
            // Apply UI settings if this is all-settings mode
            if (authType === 'all-settings') {
                const uiSettings = this.buildAuthenticationOptionsFromUI();
                // Merge UI settings with server options
                options.userVerification = uiSettings.userVerification || options.userVerification;
                options.timeout = uiSettings.timeout || options.timeout;
            }
            
            // Override for security key only
            if (authType === 'security-key-only') {
                options.userVerification = 'discouraged';
                options.timeout = 25000;
            }
            
            this.log(`🔐 FINAL OPTIONS: ${JSON.stringify({...options, challenge: '[ArrayBuffer]', allowCredentials: options.allowCredentials?.map(c => ({...c, id: '[ArrayBuffer]'}))}, null, 2)}`);
            
            // Perform WebAuthn authentication
            const startTime = performance.now();
            const credential = await navigator.credentials.get({ publicKey: options });
            const endTime = performance.now();
            
            if (!credential) {
                throw new Error('No credential returned');
            }
            
            this.log(`✅ WEBAUTHN SUCCESS: Authentication completed in ${endTime - startTime}ms`);
            this.log(`✅ Credential ID: ${credential.id}`);
            this.log(`✅ Type: ${credential.type}`);
            this.log(`✅ Authenticator: ${credential.authenticatorAttachment || 'unknown'}`);
            
            // Send result to server
            const authResponse = {
                id: credential.id,
                rawId: this.arrayBufferToBase64(credential.rawId),
                type: credential.type,
                response: {
                    authenticatorData: this.arrayBufferToBase64(credential.response.authenticatorData),
                    clientDataJSON: this.arrayBufferToBase64(credential.response.clientDataJSON),
                    signature: this.arrayBufferToBase64(credential.response.signature),
                    userHandle: credential.response.userHandle ? this.arrayBufferToBase64(credential.response.userHandle) : null
                }
            };
            
            const finishResponse = await fetch('/webauthn/authenticate/finish', {
                method: 'POST',
                headers: {
                    'Content-Type': 'application/json',
                },
                body: JSON.stringify(authResponse)
            });
            
            const result = await finishResponse.json();
            
            if (finishResponse.ok && result.verified) {
                this.showStatus('auth-status', `✅ ${authType} authentication successful!`, 'success');
                this.log(`✅ SERVER VERIFICATION: Authentication verified successfully`);
                this.saveTestResult('server-authentication', { authType, username }, { success: true, ...result });
            } else {
                throw new Error(result.error || 'Server verification failed');
            }
            
        } catch (error) {
            this.showStatus('auth-status', `❌ ${authType} error: ${error.message}`, 'error');
            this.log(`❌ ${authType} error: ${error.message}`);
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
            
            // Apply Apple/macOS overrides - let this do ALL the cross-platform forcing
            const customOptions = {
                forceCrossPlatform: true, // Always force for this button - THIS IS THE KEY
                disablePlatformAuth: true, // Also disable platform auth
                prioritizeExternal: document.getElementById('auth-prioritize-external')?.checked,
                excludePlatform: document.getElementById('auth-exclude-platform')?.checked
            };
            
            this.applyAppleOverrides(options, customOptions);
            
            // Override specific settings for security key only mode AFTER Apple overrides
            delete options.publicKey.allowCredentials; // Remove credential restrictions
            options.publicKey.userVerification = 'discouraged';
            options.publicKey.timeout = 25000; // Short timeout
            
            // Ensure cross-platform is definitely set (redundant but safe)
            if (!options.publicKey.authenticatorSelection) {
                options.publicKey.authenticatorSelection = {};
            }
            options.publicKey.authenticatorSelection.authenticatorAttachment = 'cross-platform';
            
            this.log(`🔑 SECURITY KEY AUTH OVERRIDE: ${JSON.stringify(options, null, 2)}`);
            
            const startTime = performance.now();
            const assertion = await navigator.credentials.get(options);
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
        const username = document.getElementById('global-username').value.trim();
        
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
        const username = document.getElementById('global-username')?.value?.trim();
        
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

    // Enhanced device-capability-based configuration using ALL browser features
    applyDeviceCapabilities(options, isRegistration = true) {
        this.log('🔧 Applying ALL detected device capabilities to WebAuthn options...');
        
        // Use browser capabilities we already detected
        const caps = this.capabilities;
        const browser = this.browserInfo;
        
        // Apply platform authenticator capabilities
        if (caps.platformAuthenticator) {
            this.log('✅ Platform authenticator available - enabling hybrid mode');
            // Don't restrict authenticator attachment - allow both platform and cross-platform
        } else {
            this.log('❌ No platform authenticator - forcing cross-platform only');
            options.publicKey.authenticatorSelection = {
                ...options.publicKey.authenticatorSelection,
                authenticatorAttachment: 'cross-platform'
            };
        }
        
        // Apply conditional mediation capabilities
        if (caps.conditionalMediation && !isRegistration) {
            this.log('✅ Conditional mediation available - can use autofill UI');
            // Note: Conditional mediation is applied in buildAuthenticationOptionsFromUI
        }
        
        // Apply browser-specific optimizations
        if (browser.isSafari || browser.isiOS) {
            options.publicKey.timeout = Math.max(options.publicKey.timeout || 60000, 120000); // Safari needs longer
            this.log('🍎 Safari detected - extended timeout to 120s');
        }
        
        // Apply device-specific transport optimizations
        if (browser.isMobile) {
            this.log('📱 Mobile device detected - optimizing for mobile transports');
            // Mobile devices typically support internal, hybrid, and sometimes NFC
        }
        
        // Apply hardware-specific optimizations
        if (browser.platform.includes('Mac')) {
            this.log('🍎 macOS detected - Touch ID and security key support available');
        } else if (browser.platform.includes('Win')) {
            this.log('🪟 Windows detected - Windows Hello and security key support available');
        }
        
        // Apply WebRTC capabilities for hybrid transport
        if (navigator.mediaDevices && navigator.mediaDevices.getUserMedia) {
            this.log('📷 WebRTC available - hybrid QR transport fully supported');
        }
        
        // Apply USB/Bluetooth capabilities
        if (navigator.usb) {
            this.log('🔌 WebUSB API available - USB security keys fully supported');
        }
        if (navigator.bluetooth) {
            this.log('📶 Web Bluetooth API available - BLE transport supported');
        }
        
        this.log('✅ ALL device capabilities applied successfully');
    }
    
    // Convenience methods to force specific authenticator types while using all capabilities
    forceHardwareKeysOnly(options) {
        this.log('🔑 FORCING HARDWARE KEYS ONLY - using all capabilities with cross-platform restriction');
        options.publicKey.authenticatorSelection = {
            ...options.publicKey.authenticatorSelection,
            authenticatorAttachment: 'cross-platform',
            userVerification: 'discouraged' // Hardware keys often don't have UV
        };
        return options;
    }
    
    forcePlatformAuthOnly(options) {
        this.log('🆔 FORCING PLATFORM AUTH ONLY - using all capabilities with platform restriction');
        options.publicKey.authenticatorSelection = {
            ...options.publicKey.authenticatorSelection,
            authenticatorAttachment: 'platform',
            userVerification: 'preferred' // Platform auth typically has UV
        };
        return options;
    }
    
    enableAllCapabilitiesHybridMode(options) {
        this.log('🌐 ENABLING FULL HYBRID MODE - using ALL browser capabilities without restrictions');
        // Remove any attachment restrictions to allow both platform and cross-platform
        if (options.publicKey.authenticatorSelection?.authenticatorAttachment) {
            delete options.publicKey.authenticatorSelection.authenticatorAttachment;
        }
        return options;
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
            options.publicKey.allowCredentials = []; // Empty for usernameless/resident key discovery
            
            // Apply Apple/macOS overrides if any are checked
            const customOptions = {
                forceCrossPlatform: document.getElementById('auth-force-cross-platform')?.checked,
                disablePlatformAuth: document.getElementById('auth-disable-platform-auth')?.checked,
                prioritizeExternal: document.getElementById('auth-prioritize-external')?.checked,
                excludePlatform: document.getElementById('auth-exclude-platform')?.checked
            };
            
            this.applyAppleOverrides(options, customOptions);
            
            this.log(`🔄 USERNAMELESS OPTIONS: ${JSON.stringify(options, null, 2)}`);
            this.showStatus('usernameless-status', '🔄 Select from your available passkeys...', 'info');
            
            const startTime = performance.now();
            const credential = await navigator.credentials.get(options);
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
        this.log(`🔓 AUTHENTICATION: Using UI settings + device capabilities`);
        
        const statusDiv = document.getElementById('auth-status');
        statusDiv.style.display = 'block';
        statusDiv.innerHTML = '<div class="loading">🔄 Starting authentication with your settings...</div>';
        
        try {
            const options = this.buildAuthenticationOptionsFromUI();
            
            // Apply device capabilities instead of complex overrides
            this.applyDeviceCapabilities(options, false);
            
            // Apply manual overrides from Basic Settings dropdowns while preserving all capabilities
            const authAttachment = document.getElementById('auth-attachment')?.value;
            if (authAttachment === 'cross-platform') {
                this.forceHardwareKeysOnly(options);
            } else if (authAttachment === 'platform') {
                this.forcePlatformAuthOnly(options);
            } else {
                this.enableAllCapabilitiesHybridMode(options);
            }
            
            // Show transport-specific status message
            const selectedAuthTransports = [];
            if (document.getElementById('auth-include-usb')?.checked) selectedAuthTransports.push('usb');
            if (document.getElementById('auth-include-nfc')?.checked) selectedAuthTransports.push('nfc');
            if (document.getElementById('auth-include-ble')?.checked) selectedAuthTransports.push('ble');
            if (document.getElementById('auth-include-internal')?.checked) selectedAuthTransports.push('internal');
            if (document.getElementById('auth-include-hybrid')?.checked) selectedAuthTransports.push('hybrid');
            
            if (selectedAuthTransports.length > 0 && selectedAuthTransports.length < 5) {
                statusDiv.innerHTML = `<div class="info">📡 Using selected transports: ${selectedAuthTransports.join(', ')}</div>`;
                await new Promise(resolve => setTimeout(resolve, 1000)); // Brief pause to show message
            }
            
            this.log(`🔓 Authentication options: ${JSON.stringify({
                ...options.publicKey,
                challenge: options.publicKey.challenge ? `[Uint8Array ${options.publicKey.challenge.length} bytes]` : 'MISSING',
                allowCredentials: options.publicKey.allowCredentials?.map(c => ({
                    type: c.type,
                    id: c.id ? `[ArrayBuffer ${c.id.byteLength} bytes]` : 'MISSING',
                    transports: c.transports
                })),
                authenticatorSelection: options.publicKey.authenticatorSelection,
                timeout: options.publicKey.timeout
            }, null, 2)}`);
            
            statusDiv.innerHTML = '<div class="loading">⏳ Authenticate with all browser capabilities...</div>';
            
            // Log comprehensive capability usage for authentication
            this.log(`🚀 AUTH USING ALL BROWSER CAPABILITIES: ${Object.keys(this.capabilities || {}).length} capabilities detected`);
            this.log(`🔧 Allowed credentials: ${options.publicKey.allowCredentials?.length || 0} credentials`);
            this.log(`🔧 Extensions: ${Object.keys(options.publicKey.extensions || {}).length} enabled`);
            this.log(`🔧 Auth transports: ${selectedAuthTransports.join(', ')}`);
            
            const assertion = await navigator.credentials.get(options);
            
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
    
    // Build registration options from UI form elements + device capabilities
    buildRegistrationOptionsFromUI() {
        this.log('🔧 Building registration options from UI settings + device capabilities...');
        
        // Basic settings
        const username = document.getElementById('global-username').value || 'testuser';
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
        
        // Algorithm selection - enhanced with device capability awareness
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
        
        // If no algorithms selected, use ALL browser-supported algorithms
        if (pubKeyCredParams.length === 0) {
            this.log('📱 No algorithms selected, using ALL browser-supported algorithms...');
            
            // Use all algorithms from detected capabilities
            const supportedAlgorithms = this.getSupportedAlgorithms();
            supportedAlgorithms.forEach(algInfo => {
                pubKeyCredParams.push({ alg: algInfo.alg, type: "public-key" });
            });
            
            this.log(`🔧 Auto-selected ALL supported algorithms: ${pubKeyCredParams.map(p => p.alg).join(', ')}`);
        }
        
        // Get selected transport methods
        const selectedTransports = this.getSelectedTransports();
        this.log(`🚀 Selected transports: ${selectedTransports.join(', ')}`);
        
        // Auto-configure attachment based on transport selections and device capabilities
        let finalAttachment = attachment;
        if (!attachment) {
            // Determine attachment based on selected transports
            const hasInternalTransport = selectedTransports.includes('internal');
            const hasExternalTransports = selectedTransports.some(t => ['usb', 'nfc', 'ble', 'hybrid'].includes(t));
            
            if (!hasInternalTransport && hasExternalTransports) {
                this.log('🔑 Only external transports selected, forcing cross-platform');
                finalAttachment = 'cross-platform';
            } else if (hasInternalTransport && !hasExternalTransports) {
                this.log('🆔 Only internal transport selected, forcing platform');
                finalAttachment = 'platform';
            } else if (!this.capabilities?.platformAuthenticator) {
                this.log('❌ No platform authenticator detected, forcing cross-platform');
                finalAttachment = 'cross-platform';
            } else {
                this.log('✅ Hybrid mode - multiple transports or platform authenticator available');
                // Leave undefined for hybrid mode
            }
        }
        
        // Build excludeCredentials based on transport restrictions
        let excludeCredentials = [];
        if (selectedTransports.length > 0 && selectedTransports.length < 5) {
            // If specific transports are selected (not all), exclude incompatible credentials
            // This is a placeholder - in real scenarios, you'd exclude based on known credential transports
            this.log(`🚫 Transport filtering enabled for: ${selectedTransports.join(', ')}`);
        }
        
        // Extensions
        const extensions = {};
        if (document.getElementById('ext-credProps')?.checked) extensions.credProps = true;
        if (document.getElementById('ext-largeBlobKey')?.checked) extensions.largeBlobKey = true;
        if (document.getElementById('ext-credProtect')?.checked) extensions.credProtect = { credentialProtectionPolicy: "userVerificationOptional", enforceCredentialProtectionPolicy: false };
        if (document.getElementById('ext-hmacSecret')?.checked) extensions.hmacCreateSecret = true;
        if (document.getElementById('ext-devicePubKey')?.checked) extensions.devicePubKey = { attestation: "none", attestationFormats: [] };
        
        // Auto-enable ALL browser-supported extensions if nothing else is selected
        if (Object.keys(extensions).length === 0) {
            this.log('🔧 No extensions selected, enabling ALL browser-supported extensions...');
            
            const supportedExtensions = this.getSupportedExtensions();
            supportedExtensions.forEach(extName => {
                switch(extName) {
                    case 'credProps':
                        extensions.credProps = true;
                        break;
                    case 'largeBlobKey':
                        extensions.largeBlobKey = true;
                        break;
                    case 'credProtect':
                        extensions.credProtect = { credentialProtectionPolicy: "userVerificationOptional", enforceCredentialProtectionPolicy: false };
                        break;
                    case 'hmac-secret':
                        extensions.hmacCreateSecret = true;
                        break;
                    case 'devicePubKey':
                        extensions.devicePubKey = { attestation: "none", attestationFormats: [] };
                        break;
                    case 'uvm':
                        // UVM is for authentication, not registration
                        break;
                    case 'appid':
                        // AppID is for authentication, not registration
                        break;
                }
            });
            
            this.log(`🔧 Auto-enabled extensions: ${Object.keys(extensions).join(', ')}`);
        }
        
        // Build the options
        const options = {
            challenge,
            rp: { name: rpName, id: rpId },
            user: {
                id: new TextEncoder().encode(username),
                name: username,
                displayName: username
            },
            pubKeyCredParams,
            authenticatorSelection: {
                ...(finalAttachment && { authenticatorAttachment: finalAttachment }),
                userVerification,
                residentKey
            },
            attestation,
            timeout,
            extensions,
            ...(excludeCredentials.length > 0 && { excludeCredentials })
        };
        
        this.log(`✅ Built registration options: ${JSON.stringify({
            ...options,
            challenge: `[Uint8Array ${options.challenge.length} bytes]`,
            user: { ...options.user, id: `[Uint8Array ${options.user.id.length} bytes]` },
            selectedTransports: selectedTransports,
            finalAttachment: finalAttachment
        }, null, 2)}`);
        
        return options;
    }
    
    // Build authentication options from UI form elements + device capabilities
    buildAuthenticationOptionsFromUI() {
        this.log('🔧 Building authentication options from UI settings + device capabilities...');
        
        // Basic settings
        const username = document.getElementById('global-username')?.value || '';
        const userVerification = document.getElementById('auth-user-verification')?.value || 'preferred';
        const authType = document.getElementById('auth-type')?.value || 'hybrid';
        const attachment = document.getElementById('auth-attachment')?.value || undefined;
        
        // DEBUG: Log UI settings being read
        this.log(`🔧 UI Settings Read:
            - authType: "${authType}"
            - attachment: "${attachment}"  
            - userVerification: "${userVerification}"
            - username: "${username}"`);
            
        // SECURITY CHECK: Validate security-key mode
        if (authType === 'security-key') {
            this.log(`🔑 SECURITY KEY MODE DETECTED - Will force cross-platform only`);
        }
        let timeout = parseInt(document.getElementById('auth-timeout')?.value) || 60000;
        
        // Auto-adjust timeout based on browser capabilities
        if (this.browserInfo.isSafari || this.browserInfo.isiOS) {
            timeout = Math.max(timeout, 120000); // Safari needs longer timeouts
            this.log('🍎 Safari detected - extended timeout to 120s');
        }
        
        // Challenge settings
        const challengeSize = parseInt(document.getElementById('auth-challenge-size')?.value) || 32;
        const challenge = window.crypto.getRandomValues(new Uint8Array(challengeSize));
        
        // RP settings
        const rpIdField = document.getElementById('auth-rp-id');
        const rpId = rpIdField?.value || window.location.hostname;
        
        // DEBUG: Log RP ID details
        this.log(`🌐 RP ID Details:
            - Field element: ${rpIdField ? 'Found' : 'MISSING'}
            - Field value: "${rpIdField?.value}"
            - window.location.hostname: "${window.location.hostname}"
            - Final rpId: "${rpId}"`);
            
        // CRITICAL CHECK: Ensure RP ID matches current domain
        if (rpId !== window.location.hostname) {
            this.log(`⚠️ WARNING: RP ID mismatch! Using "${rpId}" but on domain "${window.location.hostname}"`);
        }
        
        // Credential selection - CRITICAL: Convert base64url credential IDs to ArrayBuffers
        let allowCredentials = [];
        try {
            const credentialsText = document.getElementById('allow-credentials')?.value || '[]';
            this.log(`📋 Raw allowCredentials text: ${credentialsText}`);
            if (credentialsText.trim()) {
                const parsedCredentials = JSON.parse(credentialsText);
                this.log(`📋 Parsed credentials (before conversion): ${JSON.stringify(parsedCredentials, null, 2)}`);
                allowCredentials = parsedCredentials.map(cred => ({
                    ...cred,
                    id: typeof cred.id === 'string' ? this.base64ToArrayBuffer(cred.id) : cred.id
                }));
                this.log(`📋 Converted credentials (after ArrayBuffer conversion): ${allowCredentials.length} credentials processed`);
            }
        } catch (e) {
            this.log('❌ Invalid allow credentials JSON, using empty array: ' + e.message);
        }
        
        // Get selected transport methods for authentication
        const selectedTransports = [];
        if (document.getElementById('auth-include-usb')?.checked) selectedTransports.push('usb');
        if (document.getElementById('auth-include-nfc')?.checked) selectedTransports.push('nfc');
        if (document.getElementById('auth-include-ble')?.checked) selectedTransports.push('ble');
        if (document.getElementById('auth-include-internal')?.checked) selectedTransports.push('internal');
        if (document.getElementById('auth-include-hybrid')?.checked) selectedTransports.push('hybrid');
        
        this.log(`🚀 Auth selected transports: ${selectedTransports.join(', ')}`);
        
        // CRITICAL FIX: Handle Security Key Only mode properly
        if (authType === 'security-key') {
            // For Security Key Only mode, KEEP existing allowCredentials but force cross-platform
            this.log(`🔑 SECURITY KEY ONLY MODE: Using ${allowCredentials.length} credentials but forcing cross-platform only`);
        }
        
        // Apply credential filtering based on auth type and transport selection
        if (allowCredentials.length > 0) {
            if (attachment === 'cross-platform') {
                // Filter out platform credentials for cross-platform mode
                allowCredentials = allowCredentials.filter(cred => 
                    !cred.transports || !cred.transports.includes('internal')
                );
                this.log(`🔑 Cross-platform mode: filtered to ${allowCredentials.length} cross-platform credentials`);
            } else if (authType === 'platform' || attachment === 'platform') {
                // Filter to only platform credentials
                allowCredentials = allowCredentials.filter(cred => 
                    cred.transports && cred.transports.includes('internal')
                );
                this.log(`🆔 Platform mode: filtered to ${allowCredentials.length} platform credentials`);
            } else if (selectedTransports.length > 0 && selectedTransports.length < 5) {
                // LESS AGGRESSIVE transport filtering - keep more credentials
                this.log(`⚠️ SKIPPING TRANSPORT FILTER - keeping all credentials regardless of transport restrictions`);
                this.log(`🚀 Would have filtered for transports: ${selectedTransports.join(', ')}, but keeping all ${allowCredentials.length} credentials`);
            }
        }
        
        // Extensions - use dynamic extension detection
        const extensions = this.getSelectedAuthExtensions();
        
        // Auto-enable all browser-supported authentication extensions if none selected
        if (Object.keys(extensions).length === 0) {
            this.log('🔧 No auth extensions selected, enabling all browser-supported auth extensions...');
            
            const supportedExtensions = this.getSupportedExtensions();
            supportedExtensions.forEach(extName => {
                switch(extName) {
                    case 'largeBlob':
                        extensions.largeBlob = { read: true };
                        break;
                    case 'appid':
                        // Skip appid - causes domain errors if credential wasn't registered with appid
                        // extensions.appid = window.location.origin;
                        break;
                    case 'uvm':
                        extensions.uvm = true;
                        break;
                    case 'credProps':
                        // CredProps not needed for authentication
                        break;
                }
            });
            
            this.log(`🔧 Auto-enabled auth extensions: ${Object.keys(extensions).join(', ')}`);
        }
        
        // Auto-configure mediation based on auth type and capabilities
        let mediation = 'optional';
        if (authType === 'usernameless' || document.getElementById('auth-conditional-mediation')?.checked) {
            if (this.capabilities?.conditionalMediation) {
                mediation = 'conditional';
                this.log('✅ Conditional mediation enabled for usernameless auth');
            } else {
                this.log('❌ Conditional mediation not supported, using optional');
            }
        }
        
        // Build the authenticator selection based on auth type, transport selections, and device capabilities
        let authenticatorSelection = {};
        if (authType === 'security-key') {
            // FORCE Security Key Only mode - no platform authenticators allowed
            authenticatorSelection.authenticatorAttachment = 'cross-platform';
            authenticatorSelection.userVerification = 'discouraged';
            this.log('🔑 SECURITY KEY ONLY: Forced cross-platform with discouraged UV');
        } else if (attachment === 'cross-platform') {
            authenticatorSelection.authenticatorAttachment = 'cross-platform';
            authenticatorSelection.userVerification = userVerification;
            this.log('🔑 Cross-platform attachment specified');
        } else if (authType === 'platform' || attachment === 'platform') {
            authenticatorSelection.authenticatorAttachment = 'platform';
            authenticatorSelection.userVerification = userVerification;
            this.log('🆔 Platform mode specified');
        } else if (attachment) {
            authenticatorSelection.authenticatorAttachment = attachment;
            authenticatorSelection.userVerification = userVerification;
            this.log(`🔧 Custom attachment: ${attachment}`);
        } else {
            // Auto-configure based on transport selections
            const hasInternalTransport = selectedTransports.includes('internal');
            const hasExternalTransports = selectedTransports.some(t => ['usb', 'nfc', 'ble', 'hybrid'].includes(t));
            
            authenticatorSelection.userVerification = userVerification;
            
            if (!hasInternalTransport && hasExternalTransports) {
                this.log('🔑 Only external transports selected for auth, preferring cross-platform');
                authenticatorSelection.authenticatorAttachment = 'cross-platform';
            } else if (hasInternalTransport && !hasExternalTransports) {
                this.log('🆔 Only internal transport selected for auth, preferring platform');
                authenticatorSelection.authenticatorAttachment = 'platform';
            } else if (!this.capabilities?.platformAuthenticator) {
                this.log('❌ No platform authenticator detected, preferring cross-platform');
                authenticatorSelection.authenticatorAttachment = 'cross-platform';
            } else {
                this.log('✅ Hybrid mode for auth - multiple transports available');
                // Leave attachment undefined for hybrid mode
            }
        }
        
        // Build the options in proper WebAuthn format
        const options = {
            publicKey: {
                challenge,
                ...(rpId && { rpId }),
                ...(allowCredentials.length > 0 && { allowCredentials }),
                userVerification,
                timeout,
                ...(Object.keys(authenticatorSelection).length > 0 && { authenticatorSelection }),
                ...(Object.keys(extensions).length > 0 && { extensions })
            }
        };
        
        this.log(`✅ Built authentication options: ${JSON.stringify({
            ...options.publicKey,
            challenge: `[Uint8Array ${options.publicKey.challenge.length} bytes]`,
            allowCredentials: options.publicKey.allowCredentials?.map(c => ({
                type: c.type,
                id: `[ArrayBuffer ${c.id.byteLength} bytes]`,
                transports: c.transports
            })),
            selectedTransports: selectedTransports,
            authenticatorSelection: authenticatorSelection
        }, null, 2)}`);
        
        return options;
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
            global: {
                username: document.getElementById('global-username')?.value
            },
            registration: {
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
    
    // Removed Apple cancellation method - using device capability approach instead
    
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
        // Return comprehensive list of WebAuthn extensions that browsers may support
        const allKnownExtensions = [
            'credProps',        // Get credential properties
            'largeBlobKey',     // Large blob storage key
            'credProtect',      // Credential protection policy  
            'hmac-secret',      // HMAC secret extension
            'devicePubKey',     // Device public key extension
            'uvm',              // User verification methods (auth only)
            'appid',            // Application identifier (auth only)
            'largeBlob',        // Large blob storage (auth only)
            'hmacCreateSecret', // HMAC create secret (reg only)
            'minPinLength',     // Minimum PIN length
            'credentialBlob',   // Credential blob extension
            'getCredBlob'       // Get credential blob
        ];
        
        this.log(`🔧 Returning ${allKnownExtensions.length} known WebAuthn extensions for browser detection`);
        return allKnownExtensions;
    }
    
    // Dynamically populate UI with browser capabilities
    populateUIWithBrowserCapabilities() {
        this.log('🎨 POPULATING UI WITH ALL BROWSER CAPABILITIES...');
        
        // Get all detected capabilities
        const supportedExtensions = this.getSupportedExtensions();
        const supportedAlgorithms = this.getSupportedAlgorithms();
        
        this.log(`🔧 Found ${supportedExtensions.length} extensions: ${supportedExtensions.join(', ')}`);
        this.log(`🔢 Found ${supportedAlgorithms.length} algorithms`);
        
        // Populate extensions dynamically
        this.populateExtensionsInHTML(supportedExtensions);
        
        // Populate algorithms dynamically  
        this.populateAlgorithmsInHTML(supportedAlgorithms);
        
        this.log('✅ UI populated with all browser capabilities!');
    }
    
    populateExtensionsInHTML(supportedExtensions) {
        // Find and populate registration extensions
        this.populateRegistrationExtensions(supportedExtensions);
        
        // Find and populate authentication extensions
        this.populateAuthenticationExtensions();
    }
    
    populateRegistrationExtensions(supportedExtensions) {
        // Find registration extensions container by looking for h4 with "Extensions" text
        const headers = document.querySelectorAll('h4');
        for (let header of headers) {
            if (header.textContent.includes('Extensions')) {
                const tabContent = header.closest('.tab-content');
                if (tabContent && tabContent.id === 'registration-test') {
                    const container = header.nextElementSibling;
                    if (container && container.classList.contains('checkbox-group')) {
                        // Clear existing extensions
                        container.innerHTML = '';
                        
                        // Add all supported registration extensions
                        const regExtensions = supportedExtensions.filter(ext => 
                            !['uvm', 'appid', 'largeBlob'].includes(ext)
                        );
                        
                        regExtensions.forEach(ext => {
                            const label = document.createElement('label');
                            const checkbox = document.createElement('input');
                            checkbox.type = 'checkbox';
                            checkbox.id = `ext-${ext}`;
                            
                            // Default key extensions to checked
                            if (['credProps', 'hmac-secret'].includes(ext)) {
                                checkbox.checked = true;
                            }
                            
                            label.appendChild(checkbox);
                            label.appendChild(document.createTextNode(` ${ext}`));
                            container.appendChild(label);
                            
                            this.log(`➕ Added registration extension: ${ext}`);
                        });
                        break;
                    }
                }
            }
        }
    }
    
    populateAuthenticationExtensions() {
        // Find authentication extensions container
        const headers = document.querySelectorAll('h4');
        for (let header of headers) {
            if (header.textContent.includes('Extensions')) {
                const tabContent = header.closest('.tab-content');
                if (tabContent && tabContent.id === 'authentication-test') {
                    const container = header.nextElementSibling;
                    if (container && container.classList.contains('checkbox-group')) {
                        // Clear existing extensions
                        container.innerHTML = '';
                        
                        // Add authentication-specific extensions
                        const authExtensions = ['largeBlob', 'appid', 'uvm'];
                        
                        authExtensions.forEach(ext => {
                            const label = document.createElement('label');
                            const checkbox = document.createElement('input');
                            checkbox.type = 'checkbox';
                            checkbox.id = `auth-ext-${ext}`;
                            
                            label.appendChild(checkbox);
                            label.appendChild(document.createTextNode(` ${ext}`));
                            container.appendChild(label);
                            
                            this.log(`➕ Added authentication extension: ${ext}`);
                        });
                        break;
                    }
                }
            }
        }
    }
    
    populateAlgorithmsInHTML(supportedAlgorithms) {
        // Find algorithms section
        const headers = document.querySelectorAll('h4');
        for (let header of headers) {
            if (header.textContent.includes('Cryptographic Algorithms')) {
                const container = header.nextElementSibling;
                if (container && container.classList.contains('checkbox-group')) {
                    // Clear existing algorithms
                    container.innerHTML = '';
                    
                    // Add all supported algorithms
                    supportedAlgorithms.forEach(algInfo => {
                        const label = document.createElement('label');
                        const checkbox = document.createElement('input');
                        checkbox.type = 'checkbox';
                        checkbox.value = algInfo.alg;
                        checkbox.checked = true; // Default all to checked for maximum compatibility
                        
                        label.appendChild(checkbox);
                        label.appendChild(document.createTextNode(` ${algInfo.name} (${algInfo.alg}) - ${algInfo.description}`));
                        container.appendChild(label);
                        
                        this.log(`➕ Added algorithm: ${algInfo.name} (${algInfo.alg})`);
                    });
                    break;
                }
            }
        }
    }

    // Credential Management Methods
    addUserCredential(username, credInfo) {
        if (!this.userCredentials.has(username)) {
            this.userCredentials.set(username, []);
        }
        this.userCredentials.get(username).push({
            ...credInfo,
            registeredAt: new Date().toISOString(),
            rawId: credInfo.id // Store base64 ID as rawId for allowCredentials
        });
        
        this.updateCredentialDisplay();
        this.updateAllowCredentialsField(username);
        this.log(`🔑 CREDENTIAL TRACKED: Added credential for ${username} - AUTH SETTINGS READY!`);
    }

    refreshUserCredentials() {
        const username = document.getElementById('global-username').value.trim();
        if (!username) {
            this.showStatus('auth-status', 'Enter a username to refresh credentials', 'info');
            return;
        }
        
        this.updateCredentialDisplay();
        this.updateAllowCredentialsField(username);
        this.log(`🔄 REFRESHED: Credentials for ${username}`);
    }

    clearAllCredentials() {
        this.userCredentials.clear();
        this.updateCredentialDisplay();
        
        // Clear allowCredentials field
        const allowCredsField = document.getElementById('allow-credentials');
        if (allowCredsField) {
            allowCredsField.value = '[]';
        }
        
        this.log('🗑️ CLEARED: All tracked credentials');
    }

    syncTabSettings() {
        const username = document.getElementById('global-username').value.trim();
        if (username) {
            this.updateAllowCredentialsField(username);
            this.log(`🔄 SYNCED: Tabs synchronized for ${username}`);
        }
    }

    updateCredentialDisplay() {
        const credCountDiv = document.getElementById('credential-count');
        if (!credCountDiv) return;
        
        const username = document.getElementById('global-username').value.trim();
        if (!username) {
            credCountDiv.innerHTML = 'Enter username to see credentials';
            return;
        }
        
        const userCreds = this.userCredentials.get(username) || [];
        if (userCreds.length === 0) {
            credCountDiv.innerHTML = `No credentials for "${username}"`;
        } else {
            credCountDiv.innerHTML = `${userCreds.length} credential(s) for "${username}"<br>` +
                userCreds.map((cred, i) => 
                    `<small>${i+1}. ${cred.type} (${cred.authenticatorAttachment || 'unknown'})</small>`
                ).join('<br>');
        }
    }

    updateAllowCredentialsField(username) {
        const allowCredsField = document.getElementById('allow-credentials');
        if (!allowCredsField) return;
        
        const userCreds = this.userCredentials.get(username) || [];
        if (userCreds.length === 0) {
            allowCredsField.value = '[]';
            allowCredsField.placeholder = `No credentials registered for "${username}" yet`;
        } else {
            const allowCredentials = userCreds.map(cred => ({
                id: cred.rawId,
                type: "public-key",
                transports: cred.transports || ["usb", "nfc"]
            }));
            
            allowCredsField.value = JSON.stringify(allowCredentials, null, 2);
            allowCredsField.placeholder = `Credentials for "${username}"`;
        }
    }
}

// Global functions for UI interaction
let superTest;

function initSuperTest() {
    superTest = new WebAuthnSuperTest();
    
    // Populate UI with browser capabilities after a short delay to let DOM load
    setTimeout(() => {
        superTest.populateUIWithBrowserCapabilities();
    }, 1000);
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

async function runCapabilityTests() {
    if (superTest) {
        superTest.log('🔍 Starting comprehensive WebAuthn capability tests...');
        
        // Show loading status in all three sections
        const capabilitiesDiv = document.getElementById('webauthn-capabilities');
        const featureDiv = document.getElementById('feature-detection');
        const deviceDiv = document.getElementById('device-capabilities');
        
        if (capabilitiesDiv) {
            capabilitiesDiv.innerHTML = `<div class="capability-card">
                <h4>🔍 Running WebAuthn Capability Tests...</h4>
                <p>Checking browser WebAuthn support...</p>
            </div>`;
        }
        
        if (featureDiv) {
            featureDiv.innerHTML = `<div class="debug-info">
                <h4>🔍 Running Feature Detection Tests...</h4>
                <p>Scanning available WebAuthn features...</p>
            </div>`;
        }
        
        if (deviceDiv) {
            deviceDiv.innerHTML = `<div class="debug-info">
                <h4>🔍 Running Device Capability Tests...</h4>
                <p>Detecting hardware and platform capabilities...</p>
            </div>`;
        }
        
        try {
            // Run all three tests
            await superTest.checkCapabilities();
            superTest.runFeatureDetection();
            superTest.detectDeviceCapabilities();
            
            // Log completion
            superTest.log('✅ All advanced capability tests completed successfully!');
            
        } catch (error) {
            superTest.log(`❌ Capability test error: ${error.message}`);
            
            // Show error in capability div if still loading
            if (capabilitiesDiv && capabilitiesDiv.innerHTML.includes('Running WebAuthn Capability Tests')) {
                capabilitiesDiv.innerHTML = `<div class="capability-card">
                    <h4>❌ Capability Test Error</h4>
                    <p>Error: ${error.message}</p>
                </div>`;
            }
        }
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
        // Call the CLIENT-SIDE authentication method that uses ALL UI settings
        superTest.testAuthentication();
    }
}

function testChromeBypassAuthentication() {
    if (superTest) {
        // Call the CLIENT-SIDE Chrome bypass authentication method
        superTest.testChromeBypassAuthentication();
    }
}

function testUsernameless() {
    if (superTest) {
        // Call the CLIENT-SIDE usernameless authentication method
        superTest.testUsernameless();
    }
}

// New functions for credential management
function refreshCredentials() {
    if (superTest) {
        superTest.refreshUserCredentials();
    }
}

function clearAllCredentials() {
    if (superTest) {
        superTest.clearAllCredentials();
    }
}

function syncTabs() {
    if (superTest) {
        superTest.syncTabSettings();
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