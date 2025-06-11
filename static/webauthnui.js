// ===== WEBAUTHN UI FUNCTIONS =====
// These functions handle DOM interactions and use the pure WebAuthn client

// Global state tracking
window.webauthnInProgress = false;

// Synchronous wrapper for HTML onclick handlers
function registerWebAuthnSync() {
    registerWebAuthn().catch(error => {
        console.error('🔴 Registration wrapper error:', error);
        if (typeof showLoginStatus === 'function') {
            showLoginStatus(`❌ Registration Error: ${error.message || error}`, 'error');
        }
    });
}

// Synchronous wrapper for HTML onclick handlers
function loginWithWebAuthnSync() {
    loginWithWebAuthn().catch(error => {
        console.error('🔴 Login wrapper error:', error);
        if (typeof showLoginStatus === 'function') {
            showLoginStatus(`❌ Login Error: ${error.message || error}`, 'error');
        }
    });
}

// Synchronous wrapper for security key login
function loginWithSecurityKeySync() {
    loginWithSecurityKey().catch(error => {
        console.error('🔴 Security key login wrapper error:', error);
        if (typeof showLoginStatus === 'function') {
            showLoginStatus(`❌ Security Key Error: ${error.message || error}`, 'error');
        }
    });
}

async function registerWebAuthn() {
    try {
        console.log('🔵 Starting WebAuthn registration...');
        
        // Get username from DOM
        const usernameElement = document.getElementById('nickname-input');
        const username = usernameElement ? usernameElement.value : '';
        
        console.log('🔵 Username:', username);
        
        // Get emoji from global variable (fallback to default)
        const emoji = (typeof window !== 'undefined' && window.currentEmoji) ? window.currentEmoji : '👤';
        
        console.log('🔵 Emoji:', emoji);
        
        // Create browser API object
        const browserAPI = {
            fetch: window.fetch,
            atob: window.atob,
            btoa: window.btoa,
            credentialsAPI: navigator.credentials
        };
        
        const result = await webAuthnClient.register(username, emoji, {
            onStatus: (message, type) => {
                console.log('🔵 Status:', message, type);
                showLoginStatus(message, type);
            },
            onError: (error) => {
                console.log('🔴 Error:', error);
                // Handle specific error cases for account lockout
                let displayError = error;
                if (error.includes('disabled') || error.includes('locked') || error === 'Account Lockout') {
                    displayError = 'Account Lockout';
                }
                showLoginStatus(`❌ ${displayError}`, 'error');
            },
            onSuccess: () => {
                console.log('🟢 Success!');
                showLoginStatus('✅ Registration Success', 'success');
            }
        }, browserAPI);
        
        console.log('🔵 Registration result:', result);
        return result;
        
    } catch (error) {
        console.error('🔴 Unhandled registration error:', error);
        showLoginStatus(`❌ Registration Error: ${error.message || error}`, 'error');
        return { success: false, error: error.message || error };
    }
}

async function loginWithWebAuthn() {
    try {
        console.log('🔵 Starting WebAuthn login...');
        
        // Get username from DOM
        const usernameElement = document.getElementById('nickname-input');
        const username = usernameElement ? usernameElement.value.trim() : '';
        
        // Use null for usernameless authentication if no username provided
        const authUsername = username.length > 0 ? username : null;
        
        console.log('🔵 Username:', authUsername === null ? 'usernameless' : authUsername);
        
        // Create browser API object
        const browserAPI = {
            fetch: window.fetch,
            atob: window.atob,
            btoa: window.btoa,
            credentialsAPI: navigator.credentials
        };

        const result = await webAuthnClient.authenticate(authUsername, {
            onStatus: (message, type) => {
                console.log('🔵 Status:', message, type);
                // Convert 'info' status messages to 'passkey' for green color
                const displayType = type === 'info' ? 'passkey' : type;
                showLoginStatus(message, displayType);
            },
            onError: (error) => {
                console.log('🔴 Error:', error);
                // Handle specific error cases for account lockout
                let displayError = error;
                if (error.includes('disabled') || error.includes('locked') || error === 'Account Lockout') {
                    displayError = 'Account Lockout';
                } else if (authUsername === null) {
                    // Enhanced error messages for usernameless authentication
                    if (error.includes('No credentials available')) {
                        displayError = 'No Credentials Found\nPlease insert your security key\nor register a new credential';
                    } else if (error.includes('NotAllowedError') || error.includes('cancelled')) {
                        displayError = 'Authentication Cancelled\nPlease try again or enter a username\nif this issue persists';
                    }
                }
                showLoginStatus(`❌ ${displayError}`, 'error');
            },
            onSuccess: (data) => {
                console.log('🟢 Success!', data);
                
                // Determine success message based on authentication method
                let successMessage = '✅ Login Success';
                let messageType = 'success';
                if (data.method === 'security-key') {
                    successMessage = authUsername === null ? '✅ Security Key Authentication Success' : '✅ Security Key Login Success';
                    messageType = 'success'; // Keep security key as green success
                } else if (data.method === 'passkey') {
                    successMessage = authUsername === null ? '✅ Passkey Authentication Success' : '✅ Passkey Login Success';
                    messageType = 'passkey'; // Use passkey green color
                } else {
                    successMessage = authUsername === null ? '✅ Authentication Success' : '✅ Login Success';
                    messageType = 'passkey'; // Default to passkey green for general auth
                }
                
                showLoginStatus(successMessage, messageType);
                
                // Update username field with the discovered username if it was usernameless auth
                if (authUsername === null && data.username) {
                    const usernameElement = document.getElementById('nickname-input');
                    if (usernameElement) {
                        usernameElement.value = data.username;
                        console.log(`🏷️ Discovered username: ${data.username}`);
                    }
                    
                    // Load user's emoji if available
                    const userEmoji = localStorage.getItem(`userEmoji_${data.username}`);
                    if (userEmoji) {
                        const selectedEmojiElement = document.getElementById('selected-emoji');
                        if (selectedEmojiElement) {
                            selectedEmojiElement.textContent = userEmoji;
                        }
                        
                        // Update emoji picker selection
                        document.querySelectorAll('.emoji-option').forEach(option => {
                            option.classList.remove('selected');
                            if (option.textContent === userEmoji) {
                                option.classList.add('selected');
                            }
                        });
                        
                        window.currentEmoji = userEmoji;
                        if (typeof currentEmoji !== 'undefined') {
                            currentEmoji = userEmoji;
                        }
                    }
                }
                
                // Join the chat after successful authentication
                setTimeout(() => {
                    if (typeof joinChat === 'function') {
                        joinChat();
                    }
                }, 1000);
            }
        }, browserAPI);

        console.log('🔵 Login result:', result);
        return result;
        
    } catch (error) {
        console.error('🔴 Unhandled login error:', error);
        showLoginStatus(`❌ Login Error: ${error.message || error}`, 'error');
        return { success: false, error: error.message || error };
    }
}

async function loginWithSecurityKey() {
    try {
        console.log('🔑 Starting security key login...');
        
        // Get username from DOM
        const usernameElement = document.getElementById('nickname-input');
        const username = usernameElement ? usernameElement.value.trim() : '';
        
        // REQUIRE username for security key authentication
        if (!username || username.length === 0) {
            console.log('🔑 Username required for security key authentication');
            showLoginStatus('Please enter username for security key', 'error');
            return { success: false, error: 'Username required for security key authentication' };
        }
        
        console.log('🔑 Username:', username);
        
        // No longer support usernameless for security key button - always use provided username
        const authUsername = username;
        
        // Create browser API object
        const browserAPI = {
            fetchFn: window.fetch,
            atobFn: window.atob,
            btoaFn: window.btoa,
            credentialsAPI: navigator.credentials
        };

        const result = await webAuthnClient.trySecurityKeyAuthentication(authUsername, {
            onStatus: (message, type) => {
                console.log('🔑 Status:', message, type);
                showLoginStatus(message, type);
            },
            onError: (error) => {
                console.log('🔴 Error:', error);
                // Handle specific error cases for account lockout
                let displayError = error;
                if (error.includes('disabled') || error.includes('locked') || error === 'Account Lockout') {
                    displayError = 'Account Lockout';
                } else if (authUsername === null) {
                    // Enhanced error messages for usernameless authentication
                    if (error.includes('No credentials available') || error.includes('No security key credentials found')) {
                        displayError = 'No Security Key Found\nPlease insert your YubiKey\nor security key and try again';
                    } else if (error.includes('NotAllowedError') || error.includes('cancelled')) {
                        displayError = 'Security Key Cancelled\nPlease try again or enter a username\nif this issue persists';
                    }
                }
                showLoginStatus(`❌ ${displayError}`, 'error');
            },
            onSuccess: (data) => {
                console.log('🟢 Success!', data);
                
                // Success message for security key
                let successMessage = authUsername === null ? '✅ Security Key Authentication Success' : '✅ Security Key Login Success';
                showLoginStatus(successMessage, 'success');
                
                // Update username field with the discovered username if it was usernameless auth
                if (authUsername === null && data.username) {
                    const usernameElement = document.getElementById('nickname-input');
                    if (usernameElement) {
                        usernameElement.value = data.username;
                        console.log(`🏷️ Discovered username: ${data.username}`);
                    }
                    
                    // Load user's emoji if available
                    const userEmoji = localStorage.getItem(`userEmoji_${data.username}`);
                    if (userEmoji) {
                        const selectedEmojiElement = document.getElementById('selected-emoji');
                        if (selectedEmojiElement) {
                            selectedEmojiElement.textContent = userEmoji;
                        }
                        
                        // Update emoji picker selection
                        document.querySelectorAll('.emoji-option').forEach(option => {
                            option.classList.remove('selected');
                            if (option.textContent === userEmoji) {
                                option.classList.add('selected');
                            }
                        });
                        
                        window.currentEmoji = userEmoji;
                        if (typeof currentEmoji !== 'undefined') {
                            currentEmoji = userEmoji;
                        }
                    }
                }
                
                // Join the chat after successful authentication
                setTimeout(() => {
                    if (typeof joinChat === 'function') {
                        joinChat();
                    }
                }, 1000);
            }
        }, browserAPI);

        console.log('🔑 Security key result:', result);
        return result;
        
    } catch (error) {
        console.error('🔴 Unhandled security key error:', error);
        showLoginStatus(`❌ Security Key Error: ${error.message || error}`, 'error');
        return { success: false, error: error.message || error };
    }
}

// Test function to verify status display is working
function testStatusDisplay() {
    console.log('🔧 Testing status display...');
    showLoginStatus('Test message - info', 'info');
    setTimeout(() => showLoginStatus('Test message - passkey', 'passkey'), 1000);
    setTimeout(() => showLoginStatus('Test message - error', 'error'), 2000);
    setTimeout(() => showLoginStatus('Test message - success', 'success'), 3000);
}

// Test function for multi-line status messages
function testMultiLineStatus() {
    console.log('🔧 Testing multi-line status display...');
    
    // Test basic multi-line
    setTimeout(() => {
        showLoginStatus('Line 1\nLine 2\nLine 3', 'info');
    }, 1000);
    
    // Test Windows Hello error scenario with multiple lines
    setTimeout(() => {
        showLoginStatus('Setup Windows Hello in Settings', 'error');
    }, 4000);
    
    // Test success message with instructions
    setTimeout(() => {
        showLoginStatus('✅ Registration Complete!', 'success');
    }, 8000);
    
    // Test literal \n conversion
    setTimeout(() => {
        showLoginStatus('Converted literal:\\nThis should be\\na new line', 'info');
    }, 12000);
}

// Test function for Mac browser detection and strategy
function testMacBrowserStrategy() {
    console.log('🍎 Testing Mac Browser Strategy...');
    
    if (!webAuthnClient.isMac()) {
        console.log('❌ Not running on Mac - test not applicable');
        return;
    }
    
    const browserInfo = {
        isMac: webAuthnClient.isMac(),
        isChrome: webAuthnClient.isChrome(), 
        isFirefox: webAuthnClient.isFirefox(),
        isSafari: navigator.userAgent.includes('Safari') && !navigator.userAgent.includes('Chrome'),
        userAgent: navigator.userAgent
    };
    
    console.log('🔍 Mac Browser Detection:', browserInfo);
    
    // Test strategy detection
    webAuthnClient.getBestRegistrationStrategy().then(result => {
        console.log('🎯 Registration Strategy Result:', result);
        
        if (result.strategy === 'hybrid') {
            console.log('✅ Mac browser correctly assigned hybrid strategy for "Other Options"');
            
            if (browserInfo.isChrome) {
                console.log('🍎 Chrome on Mac: Will show "Chrome Mac: Touch ID or click Cancel for other options"');
            } else if (browserInfo.isFirefox) {
                console.log('🍎 Firefox on Mac: Will show "Firefox Mac: Touch ID or tap Other Options"');
            } else if (browserInfo.isSafari) {
                console.log('🍎 Safari on Mac: Will show "Safari Mac: Touch ID or tap Other Options"');
            }
        } else {
            console.log('❌ Mac browser did not get hybrid strategy:', result.strategy);
        }
    }).catch(error => {
        console.log('❌ Error testing Mac browser strategy:', error);
    });
}

// Comprehensive WebAuthn browser debugging function
function debugWebAuthnSupport() {
    console.log('🔍 WebAuthn Browser Debug Report');
    console.log('================================');
    
    // Basic browser info
    const browserInfo = {
        userAgent: navigator.userAgent,
        platform: navigator.platform,
        language: navigator.language,
        cookieEnabled: navigator.cookieEnabled,
        onLine: navigator.onLine
    };
    console.log('🌐 Browser Info:', browserInfo);
    
    // WebAuthn support check
    const webauthnSupport = {
        publicKeyCredential: typeof window.PublicKeyCredential !== 'undefined',
        credentialsAPI: typeof navigator.credentials !== 'undefined',
        createMethod: typeof navigator.credentials?.create === 'function',
        getMethod: typeof navigator.credentials?.get === 'function'
    };
    console.log('🔐 WebAuthn Support:', webauthnSupport);
    
    // Platform authenticator check
    if (typeof PublicKeyCredential !== 'undefined' && PublicKeyCredential.isUserVerifyingPlatformAuthenticatorAvailable) {
        PublicKeyCredential.isUserVerifyingPlatformAuthenticatorAvailable()
            .then(available => {
                console.log('📱 Platform Authenticator Available:', available);
            })
            .catch(error => {
                console.log('❌ Platform Authenticator Check Failed:', error);
            });
    } else {
        console.log('❌ Platform Authenticator Check Not Available');
    }
    
    // Browser-specific checks
    const browserChecks = {
        isChrome: navigator.userAgent.includes('Chrome') && !navigator.userAgent.includes('Edg'),
        isFirefox: navigator.userAgent.includes('Firefox'),
        isEdge: navigator.userAgent.includes('Edg'),
        isSafari: navigator.userAgent.includes('Safari') && !navigator.userAgent.includes('Chrome'),
        isWindows: navigator.userAgent.includes('Windows'),
        isMac: navigator.userAgent.includes('Mac'),
        isLinux: navigator.userAgent.includes('Linux')
    };
    console.log('🔍 Browser Detection:', browserChecks);
    
    // HTTPS check
    const isSecure = location.protocol === 'https:' || location.hostname === 'localhost';
    console.log('🔒 Secure Context:', isSecure);
    
    // Test minimal WebAuthn options
    if (webauthnSupport.publicKeyCredential && webauthnSupport.credentialsAPI) {
        console.log('🧪 Testing minimal WebAuthn options...');
        
        const testOptions = {
            publicKey: {
                challenge: new Uint8Array(32),
                rp: { name: "Test" },
                user: {
                    id: new Uint8Array(16),
                    name: "test",
                    displayName: "Test User"
                },
                pubKeyCredParams: [{ type: "public-key", alg: -7 }],
                timeout: 60000,
                attestation: "none"
            }
        };
        
        console.log('📋 Test Options:', testOptions);
        
        // Don't actually create, just log what would be sent
        console.log('💡 This would test credential creation with minimal options');
        console.log('💡 Run testWebAuthnCreation() to actually test (will prompt for passkey)');
    }
    
    return {
        browserInfo,
        webauthnSupport,
        browserChecks,
        isSecure,
        summary: {
            compatible: webauthnSupport.publicKeyCredential && webauthnSupport.credentialsAPI && isSecure,
            reason: !webauthnSupport.publicKeyCredential ? 'No WebAuthn support' :
                   !webauthnSupport.credentialsAPI ? 'No Credentials API' :
                   !isSecure ? 'Not HTTPS/localhost' : 'Should work'
        }
    };
}

// Test actual WebAuthn credential creation (will prompt user)
function testWebAuthnCreation() {
    console.log('🧪 Testing WebAuthn Creation (will prompt)...');
    
    const testOptions = {
        publicKey: {
            challenge: crypto.getRandomValues(new Uint8Array(32)),
            rp: { 
                id: location.hostname,
                name: "Test Registration" 
            },
            user: {
                id: crypto.getRandomValues(new Uint8Array(16)),
                name: "testuser",
                displayName: "Test User"
            },
            pubKeyCredParams: [{ type: "public-key", alg: -7 }],
            timeout: 60000,
            attestation: "none"
        }
    };
    
    navigator.credentials.create(testOptions)
        .then(credential => {
            console.log('✅ WebAuthn Creation Success:', credential);
            showLoginStatus('✅ WebAuthn Test Successful', 'success');
        })
        .catch(error => {
            console.log('❌ WebAuthn Creation Failed:', error);
            showLoginStatus('❌ WebAuthn Test Failed: ' + error.name, 'error');
        });
}

// ===== STATUS MESSAGE FUNCTIONS =====
// Multi-line status messages are supported! 
// Use \n for line breaks: showLoginStatus('Line 1\nLine 2\nLine 3', 'error')
// Auto-hide timing adjusts based on number of lines (longer for more lines)
// Max height: 120px (desktop), 100px (mobile) with automatic scrolling

// Status message functions (DOM manipulation)
function showLoginStatus(message, type = 'info') {
    const statusEl = document.getElementById('login-status');
    if (!statusEl) return;
    
    // Clear any existing timeouts
    if (window.statusTimeout) {
        clearTimeout(window.statusTimeout);
        window.statusTimeout = null;
    }
    if (window.statusFadeTimeout) {
        clearTimeout(window.statusFadeTimeout);
        window.statusFadeTimeout = null;
    }
    
    // Handle multi-line text by preserving line breaks
    // Convert newlines to appropriate format for CSS pre-wrap
    let processedMessage = message;
    if (typeof message === 'string') {
        // Normalize line breaks and handle various formats
        processedMessage = message
            .replace(/\\n/g, '\n')           // Convert literal \n to actual newlines
            .replace(/\r\n/g, '\n')          // Normalize Windows line endings
            .replace(/\r/g, '\n')            // Normalize Mac line endings
            .trim();                         // Remove extra whitespace
    }
    
    statusEl.textContent = processedMessage;
    statusEl.className = `status-message ${type}`;
    statusEl.style.display = 'block';
    statusEl.style.opacity = '1';
    
    // Auto-hide success/error messages after a delay (longer for multi-line)
    if (type === 'success' || type === 'error') {
        // Calculate delay based on message length (more time for longer messages)
        const lines = processedMessage.split('\n').length;
        const baseDelay = 3000;
        const extraDelay = Math.max(0, (lines - 1) * 1500); // +1.5s per extra line
        const totalDelay = Math.min(baseDelay + extraDelay, 10000); // Max 10 seconds
        
        window.statusTimeout = setTimeout(() => {
            statusEl.style.opacity = '0';
            window.statusFadeTimeout = setTimeout(() => {
                statusEl.style.display = 'none';
                statusEl.textContent = '';
            }, 300);
        }, totalDelay);
    }
}

function clearLoginStatus() {
    const statusEl = document.getElementById('login-status');
    if (!statusEl) return;
    
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
    statusEl.className = 'status-message mobile-error-space';
    statusEl.textContent = '';
    statusEl.style.display = 'none';
    statusEl.style.opacity = '1';
}

// Check platform authenticator availability and update UI
async function checkPlatformAuthenticatorSupport() {
    if (!webAuthnClient.isSupported()) {
        return false;
    }
    
    try {
        const isAvailable = await webAuthnClient.isWindowsHelloAvailable();
        const isWindows = webAuthnClient.isWindows();
        const isMac = webAuthnClient.isMac();
        
        const registerBtn = document.getElementById('webauthn-register-btn');
        const loginBtn = document.getElementById('webauthn-login-btn');
        
        if (isWindows && isAvailable) {
            console.log('✅ Windows Hello is available and ready');
            
            // Show privacy information if this is the first time
            showWindowsHelloPrivacyInfo();
        } else if (isMac && isAvailable) {
            console.log('✅ Mac Touch ID is available');
            
            if (registerBtn && loginBtn) {
                // Add helpful tooltip for Mac users without changing button text
                registerBtn.title = 'Touch ID or tap "Other Options" for security keys';
                loginBtn.title = 'Use Touch ID or other available authenticators';
            }
        } else if (isWindows && !isAvailable) {
            console.log('⚠️ Windows detected but Windows Hello not available');
            showWindowsHelloSetupInfo();
        } else if (isAvailable) {
            console.log('✅ Platform authenticator available (Touch ID, Face ID, etc.)');
        }
        
        return isAvailable;
    } catch (error) {
        console.log('Platform authenticator check failed:', error);
        return false;
    }
}

// Show privacy information for Windows Hello users
function showWindowsHelloPrivacyInfo() {
    // Only show once per session
    if (sessionStorage.getItem('windowsHelloPrivacyShown')) {
        return;
    }
    
    const isFirstVisit = !localStorage.getItem('windowsHelloPrivacyAcknowledged');
    if (isFirstVisit) {
        console.log('🔒 Windows Hello Privacy: Your biometric data never leaves your device');
        
        // Mark as acknowledged
        localStorage.setItem('windowsHelloPrivacyAcknowledged', 'true');
    }
    
    sessionStorage.setItem('windowsHelloPrivacyShown', 'true');
}

// Show setup information for Windows users without Windows Hello
function showWindowsHelloSetupInfo() {
    const statusEl = document.getElementById('login-status');
    if (statusEl) {
        statusEl.textContent = 'Windows Hello not set up. You can still use security keys.';
        statusEl.className = 'status-message info';
        statusEl.style.display = 'block';
        statusEl.style.opacity = '1';
        
        // Auto-hide after 8 seconds
        setTimeout(() => {
            if (statusEl.textContent.includes('Windows Hello not set up')) {
                statusEl.style.opacity = '0';
                setTimeout(() => {
                    statusEl.style.display = 'none';
                    statusEl.textContent = '';
                }, 300);
            }
        }, 8000);
    }
}

// Initialize platform-specific UI when page loads
document.addEventListener('DOMContentLoaded', function() {
    // Small delay to ensure all elements are loaded
    setTimeout(() => {
        checkPlatformAuthenticatorSupport();
    }, 100);
}); 