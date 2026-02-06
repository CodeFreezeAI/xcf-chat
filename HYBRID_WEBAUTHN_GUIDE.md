# 🔐 Hybrid WebAuthn Guide

## What's New: QR Code + Security Key Support

This implementation now supports **both QR code/phone passkey AND security key options simultaneously** in Google Chrome on Ubuntu Linux (and all other platforms).

### ✨ Features

- **📱 QR Code/Phone Passkey** - Scan QR code to use your phone as authenticator
- **🔑 Security Key** - Insert USB/NFC security key (YubiKey, etc.)
- **💻 Platform Authenticators** - Touch ID, Face ID, Windows Hello
- **🤖 Android Credential Providers** - Third-party credential managers with discoverable credentials
- **🌐 Universal Compatibility** - Works across all browsers and platforms

### 🎯 Chrome Behavior

When using the hybrid WebAuthn implementation, Chrome will present a dialog with **multiple options**:

1. **"Use your phone"** - Shows QR code to scan with your phone
2. **"Use a security key"** - For USB/NFC security keys  
3. **Platform options** - Touch ID (Mac), Windows Hello, etc.

## 🚀 How to Use

### 1. Server-Side Implementation

The key changes are in the WebAuthn configuration:

```swift
// New hybrid registration method
let options = manager.generateHybridRegistrationOptions(username: username)

// Key features:
// - NO authenticatorAttachment restriction
// - Supports all transport types: ["internal", "usb", "nfc", "hybrid"]
// - Flexible userVerification: "preferred"
```

### 2. Endpoints

New hybrid endpoints have been added:

- **Registration**: `POST /webauthn/register/begin/hybrid`
- **Authentication**: `POST /webauthn/authenticate/begin/hybrid`

### 3. Client-Side Usage

```javascript
// The client now defaults to hybrid strategy
const { strategy } = await webauthn.getBestRegistrationStrategy();
// strategy will be 'hybrid' for maximum compatibility

// Use hybrid endpoints directly
const response = await fetch('/webauthn/register/begin/hybrid', {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({ username })
});
```

### 4. Test Page

Use the test page to verify functionality:
```
open static/hybrid-webauthn-test.html
```

## 🔧 Technical Details

### What Changed

1. **Removed `authenticatorAttachment` restrictions** - This is the key change that allows Chrome to show both options
2. **Added all transport types** - Including "hybrid" for QR code support
3. **Flexible verification** - `userVerification: "preferred"` works with both types
4. **New hybrid endpoints** - Dedicated endpoints for hybrid functionality

### WebAuthn Configuration

```javascript
// OLD (restrictive)
authenticatorSelection: {
    authenticatorAttachment: "platform",  // RESTRICTS to platform only
    userVerification: "required"
}

// NEW (hybrid)
authenticatorSelection: {
    // NO authenticatorAttachment - allows both platform and cross-platform
    userVerification: "preferred",  // Flexible
    requireResidentKey: false,
    residentKey: "preferred"
}

// Transport support
transports: ["internal", "usb", "nfc", "hybrid"]  // All types supported
```

## 🧪 Testing

1. **Open Chrome** on Ubuntu Linux
2. **Navigate to the test page**: `static/hybrid-webauthn-test.html`
3. **Click "Register with Hybrid WebAuthn"**
4. **Chrome should show multiple options**:
   - QR code option for phone
   - Security key option for USB/NFC keys
   - Any available platform authenticators

## 📱 QR Code Flow

When you select "Use your phone" in Chrome:

1. Chrome displays a QR code
2. Scan with your phone's camera
3. Your phone prompts for biometric authentication
4. Registration/authentication completes on your phone
5. Chrome receives the credential

## 🔑 Security Key Flow

When you select "Use a security key" in Chrome:

1. Chrome prompts to insert security key
2. Insert USB key or tap NFC key
3. Follow security key prompts (PIN, touch, etc.)
4. Registration/authentication completes

## 🎯 Benefits

- **User Choice** - Users can choose their preferred authentication method
- **Backwards Compatible** - Still works with existing security keys
- **Future Proof** - Supports latest WebAuthn standards
- **Cross-Platform** - Works on all operating systems
- **Secure** - Maintains all WebAuthn security guarantees

## 🛠️ Migration

To migrate existing implementations:

1. **Use hybrid endpoints** instead of platform-specific ones
2. **Update client-side strategy** to use 'hybrid' by default
3. **Test with multiple authenticator types**
4. **Update user documentation** to mention QR code support

## 🔍 Troubleshooting

### Chrome doesn't show QR code option
- Ensure `authenticatorAttachment` is NOT set to "platform" or "cross-platform"
- Verify "hybrid" transport is included
- Check Chrome version (requires recent Chrome)

### Security key still works?
- Yes! The hybrid approach is fully backwards compatible
- Security keys will appear as "Use a security key" option

### Phone authentication not working?
- Ensure phone supports WebAuthn (iOS 16+, Android with Chrome)
- Check phone's biometric setup
- Verify network connectivity

### Android showing Linux behavior?
- Android's user agent contains "Linux", so `isLinux()` now explicitly excludes Android
- Check console for `🤖 Android` logs (not `🐧 Linux`)
- Android uses `/webauthn/register/begin/android` endpoint with discoverable credentials
- Third-party credential providers require `residentKey: "preferred"` and no `authenticatorAttachment`

## 📖 Resources

- [WebAuthn Specification](https://w3c.github.io/webauthn/)
- [Chrome WebAuthn Updates](https://developer.chrome.com/blog/webauthn-conditional-ui/)
- [Test Page](static/hybrid-webauthn-test.html) 