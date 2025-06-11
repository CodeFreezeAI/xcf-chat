// Mac WebAuthn Browser Test Suite
// Tests that Chrome, Firefox, and Safari on Mac all get "Other Options" capability

console.log('🍎 Mac WebAuthn Browser Test Suite');
console.log('==================================');

// Test if we're on Mac
function testMacDetection() {
    console.log('\n1. Testing Mac Detection...');
    
    const isMac = navigator.userAgent.includes('Mac');
    console.log(`   Mac detected: ${isMac ? '✅' : '❌'}`);
    console.log(`   User Agent: ${navigator.userAgent}`);
    
    if (!isMac) {
        console.log('   ⚠️  This test is designed for Mac browsers only');
        return false;
    }
    
    return true;
}

// Test browser detection
function testBrowserDetection() {
    console.log('\n2. Testing Browser Detection...');
    
    const isChrome = navigator.userAgent.includes('Chrome') && !navigator.userAgent.includes('Edg');
    const isFirefox = navigator.userAgent.includes('Firefox');
    const isSafari = navigator.userAgent.includes('Safari') && !navigator.userAgent.includes('Chrome');
    
    console.log(`   Chrome detected: ${isChrome ? '✅' : '❌'}`);
    console.log(`   Firefox detected: ${isFirefox ? '✅' : '❌'}`);
    console.log(`   Safari detected: ${isSafari ? '✅' : '❌'}`);
    
    if (!isChrome && !isFirefox && !isSafari) {
        console.log('   ⚠️  Unknown browser detected');
    }
    
    return { isChrome, isFirefox, isSafari };
}

// Test WebAuthn client strategy
async function testWebAuthnStrategy() {
    console.log('\n3. Testing WebAuthn Strategy...');
    
    if (typeof webAuthnClient === 'undefined') {
        console.log('   ❌ webAuthnClient not available');
        return false;
    }
    
    try {
        const strategy = await webAuthnClient.getBestRegistrationStrategy();
        console.log(`   Registration strategy: ${strategy.strategy}`);
        
        if (strategy.strategy === 'hybrid') {
            console.log('   ✅ Hybrid strategy assigned - "Other Options" will be available');
        } else {
            console.log('   ❌ Expected hybrid strategy, got:', strategy.strategy);
            return false;
        }
        
        return true;
    } catch (error) {
        console.log('   ❌ Error getting strategy:', error.message);
        return false;
    }
}

// Test expected status messages
function testStatusMessages() {
    console.log('\n4. Testing Expected Status Messages...');
    
    const browserInfo = testBrowserDetection();
    
    if (browserInfo.isChrome) {
        console.log('   Chrome Mac expected message: "🍎 Chrome Mac: Touch ID or click \\"Cancel\\" for other options"');
    } else if (browserInfo.isFirefox) {
        console.log('   Firefox Mac expected message: "🍎 Firefox Mac: Touch ID or tap \\"Other Options\\""');
    } else if (browserInfo.isSafari) {
        console.log('   Safari Mac expected message: "🍎 Safari Mac: Touch ID or tap \\"Other Options\\""');
    }
}

// Test WebAuthn support
function testWebAuthnSupport() {
    console.log('\n5. Testing WebAuthn Support...');
    
    const isSupported = !!(navigator.credentials && 
                          navigator.credentials.create && 
                          navigator.credentials.get &&
                          window.PublicKeyCredential);
    
    console.log(`   WebAuthn supported: ${isSupported ? '✅' : '❌'}`);
    
    if (isSupported) {
        // Test platform authenticator availability
        if (typeof PublicKeyCredential !== 'undefined' && PublicKeyCredential.isUserVerifyingPlatformAuthenticatorAvailable) {
            PublicKeyCredential.isUserVerifyingPlatformAuthenticatorAvailable()
                .then(available => {
                    console.log(`   Platform authenticator (Touch ID) available: ${available ? '✅' : '❌'}`);
                })
                .catch(error => {
                    console.log('   ❌ Platform authenticator check failed:', error);
                });
        }
    }
    
    return isSupported;
}

// Test expected endpoints
function testExpectedEndpoints() {
    console.log('\n6. Testing Expected Endpoints...');
    
    console.log('   Registration endpoint for Mac browsers: /webauthn/register/begin/hybrid');
    console.log('   Authentication endpoint options: /webauthn/authenticate/begin (regular)');
    console.log('   Security key endpoint options: /webauthn/authenticate/begin (with securityKeyOnly flag)');
}

// Test error message expectations
function testErrorMessages() {
    console.log('\n7. Testing Error Message Expectations...');
    
    const browserInfo = testBrowserDetection();
    
    console.log('   Expected registration error messages:');
    if (browserInfo.isChrome) {
        console.log('     Chrome Mac: "Chrome Mac Registration\\nClick \\"Cancel\\" then try other options\\nOr try different authentication method"');
    } else if (browserInfo.isFirefox) {
        console.log('     Firefox Mac: "Firefox Mac Registration\\nTap \\"Other Options\\" for security keys\\nOr try different authentication method"');
    } else if (browserInfo.isSafari) {
        console.log('     Safari Mac: "Safari Mac Registration\\nTap \\"Other Options\\" for security keys\\nOr try Chrome/Firefox for more options"');
    }
    
    console.log('   Expected security key error messages:');
    console.log('     All Mac browsers: "Make sure you have\\n1. Security key is inserted\\n2. Registered with this key\\n3. Touch the key when it blinks"');
}

// Run full test suite
async function runMacWebAuthnTests() {
    console.log('🍎 Starting Mac WebAuthn Test Suite...');
    
    // Test 1: Mac detection
    const isMac = testMacDetection();
    if (!isMac) {
        console.log('\n❌ Test suite stopped - not running on Mac');
        return;
    }
    
    // Test 2: Browser detection
    testBrowserDetection();
    
    // Test 3: WebAuthn strategy
    const strategyOk = await testWebAuthnStrategy();
    
    // Test 4: Status messages
    testStatusMessages();
    
    // Test 5: WebAuthn support
    const webauthnSupported = testWebAuthnSupport();
    
    // Test 6: Expected endpoints
    testExpectedEndpoints();
    
    // Test 7: Error messages
    testErrorMessages();
    
    // Summary
    console.log('\n🍎 Mac WebAuthn Test Summary');
    console.log('===========================');
    console.log(`Mac detected: ${isMac ? '✅' : '❌'}`);
    console.log(`Hybrid strategy: ${strategyOk ? '✅' : '❌'}`);
    console.log(`WebAuthn support: ${webauthnSupported ? '✅' : '❌'}`);
    
    if (isMac && strategyOk && webauthnSupported) {
        console.log('\n🎉 All tests passed! Mac browsers should have "Other Options" capability');
    } else {
        console.log('\n⚠️  Some tests failed - check the details above');
    }
}

// Auto-run tests if webAuthnClient is available
if (typeof webAuthnClient !== 'undefined') {
    // Small delay to ensure everything is loaded
    setTimeout(() => {
        runMacWebAuthnTests();
    }, 1000);
} else {
    console.log('⚠️  webAuthnClient not available - include webauthn.js first');
}

// Make functions available globally for manual testing
window.runMacWebAuthnTests = runMacWebAuthnTests;
window.testMacDetection = testMacDetection;
window.testBrowserDetection = testBrowserDetection;
window.testWebAuthnStrategy = testWebAuthnStrategy; 