// MARK: - JavaScript Content
func generateChatJS() -> String {
    // Try to read from external file first, fallback to default if not found
    let staticJSPath = "static/chatv008.js"
    
    if let jsContent = try? String(contentsOfFile: staticJSPath) {
        return jsContent
    }
    
    // Fallback: return basic JavaScript
    return """
    // Updated: 2024-12-19 - Mobile Layout Fixed, Admin Security Fixed
    // Admin status is now determined server-side for security

    class ChatClient {
        constructor() {
            this.ws = null;
            this.username = '';
            this.userEmoji = '👤';
            this.isAdmin = false; // Server will set this
            this.currentRoom = null;
            this.previousRoomId = null; // Track previous room for reconnection
            this.rooms = [];
            this.messages = [];
            this.messagesByRoom = {}; // Store messages by room ID to prevent loss
            this.isConnected = false;
            this.isReconnecting = false; // Flag to distinguish reconnection from initial connection
            this.selectedFiles = [];
            this.connectionHealthTimer = null; // Timer for connection health checks
            this.lastPongReceived = Date.now(); // Track last pong response
            this.pingInterval = null; // Ping interval timer
            this.CONNECTION_TIMEOUT = 120000; // 2 minutes - much more reasonable
            this.PING_INTERVAL = 30000; // Send ping every 30 seconds - less aggressive
            this.reconnectTimeout = null; // Add reconnect timeout tracker
            
            this.initializeEventListeners();
        }
        
        initializeEventListeners() {
            // Enter key handlers
            document.getElementById('message-input').addEventListener('keypress', (e) => {
                if (e.key === 'Enter') this.sendMessage();
            });
            
            document.getElementById('room-name-input').addEventListener('keypress', (e) => {
                if (e.key === 'Enter') this.createRoom();
            });
        }
        
        connect() {
            // Don't close healthy connections - just return if already connected
            if (this.ws && this.ws.readyState === WebSocket.OPEN) {
                console.log('✅ Already connected, skipping reconnection');
                return;
            }
            
            // Clear any existing reconnect timeout
            if (this.reconnectTimeout) {
                clearTimeout(this.reconnectTimeout);
                this.reconnectTimeout = null;
            }
            
            this.isConnected = false;
            const protocol = window.location.protocol === 'https:' ? 'wss:' : 'ws:';
            const wsUrl = `${protocol}//${window.location.host}/ws`;
            
            console.log('🔌 Connecting to WebSocket:', wsUrl);
            
            this.ws = new WebSocket(wsUrl);
            
            this.ws.onopen = () => {
                console.log('✅ WebSocket connected');
                this.isConnected = true;
                this.connectionAttempts = 0;
                
                // Reset pong timer for fresh health check
                this.lastPongReceived = Date.now();
                
                // Update connection status immediately
                this.updateConnectionStatus();
                
                // Send join message with emoji
                this.sendToServer({
                    type: 'join',
                    username: this.username,
                    emoji: this.userEmoji || window.currentEmoji || '👤',
                    isReconnecting: this.isReconnecting
                });
                
                // Start much less aggressive connection monitoring
                this.startConnectionHealthCheck();
            };
            
            this.ws.onmessage = (event) => {
                const message = JSON.parse(event.data);
                
                // Handle ping/pong for connection health
                if (message.type === 'ping') {
                    this.sendToServer({ type: 'pong' });
                    return;
                } else if (message.type === 'pong') {
                    this.lastPongReceived = Date.now();
                    return;
                }
                
                this.handleServerMessage(message);
            };
            
            this.ws.onclose = () => {
                console.log('Disconnected from server');
                this.isConnected = false;
                this.isReconnecting = true; // Set flag for reconnection
                this.clearConnectionTimers(); // Clear health check timers
                this.updateConnectionStatus();
                
                // Save current room and messages before disconnection
                if (this.currentRoom) {
                    this.previousRoomId = this.currentRoom.id;
                    this.messagesByRoom[this.currentRoom.id] = [...this.messages]; // Save current messages
                    
                    // Disable UI but DON'T clear room state or messages
                    document.getElementById('leave-room-btn').disabled = true;
                    document.getElementById('clear-history-btn').disabled = true;
                    document.getElementById('message-input').disabled = true;
                    document.getElementById('send-btn').disabled = true;
                    document.getElementById('invite-btn').disabled = true;
                    document.getElementById('file-btn').disabled = true;
                }
                
                // Much less aggressive reconnection - only try once after 5 seconds
                this.reconnectTimeout = setTimeout(() => {
                    if (!this.isConnected) {
                        console.log('Attempting to reconnect...');
                        this.connect();
                    }
                }, 5000);
            };
            
            this.ws.onerror = (error) => {
                console.error('WebSocket error:', error);
            };
        }
        
        startConnectionHealthCheck() {
            // Clear any existing timers first to prevent duplicates
            this.clearConnectionTimers();
            
            // Send ping every 30 seconds (much less aggressive)
            this.pingInterval = setInterval(() => {
                if (this.isConnected && this.ws && this.ws.readyState === WebSocket.OPEN) {
                    this.sendToServer({ type: 'ping' });
                }
            }, this.PING_INTERVAL);
            
            // Check connection health every 30 seconds (much less aggressive)
            this.connectionHealthTimer = setInterval(() => {
                const now = Date.now();
                const timeSinceLastPong = now - this.lastPongReceived;
                
                // Only consider connection dead after 2 minutes of no response (much more reasonable)
                if (timeSinceLastPong > this.CONNECTION_TIMEOUT) {
                    console.log('Connection appears to be dead (no pong received for 2 minutes), forcing reconnection...');
                    this.forceReconnection();
                }
            }, 30000); // Check every 30 seconds instead of every 5 seconds
        }
        
        clearConnectionTimers() {
            if (this.pingInterval) {
                clearInterval(this.pingInterval);
                this.pingInterval = null;
            }
            if (this.connectionHealthTimer) {
                clearInterval(this.connectionHealthTimer);
                this.connectionHealthTimer = null;
            }
            if (this.reconnectTimeout) {
                clearTimeout(this.reconnectTimeout);
                this.reconnectTimeout = null;
            }
        }
        
        forceReconnection() {
            console.log('Forcing WebSocket reconnection due to health check failure');
            this.clearConnectionTimers();
            
            if (this.ws) {
                this.ws.onclose = null; // Prevent double reconnection
                this.ws.close();
            }
            
            this.isConnected = false;
            this.isReconnecting = true;
            this.updateConnectionStatus();
            
            // Save current state
            if (this.currentRoom) {
                this.previousRoomId = this.currentRoom.id;
                this.messagesByRoom[this.currentRoom.id] = [...this.messages];
                
                // Disable UI
                document.getElementById('leave-room-btn').disabled = true;
                document.getElementById('clear-history-btn').disabled = true;
                document.getElementById('message-input').disabled = true;
                document.getElementById('send-btn').disabled = true;
                document.getElementById('invite-btn').disabled = true;
                document.getElementById('file-btn').disabled = true;
            }
            
            // Reconnect after a longer delay to prevent rapid reconnection loops
            this.reconnectTimeout = setTimeout(() => {
                this.connect();
            }, 3000);
        }
        
        sendToServer(message) {
            if (this.ws && this.ws.readyState === WebSocket.OPEN) {
                this.ws.send(JSON.stringify(message));
            }
        }
        
        handleServerMessage(message) {
            console.log('Received server message:', message);
            
            switch (message.type) {
                case 'roomList':
                    this.rooms = message.rooms || [];
                    this.updateRoomsList();
                    
                    // Handle admin status update
                    if (typeof message.isAdmin !== 'undefined') {
                        this.isAdmin = message.isAdmin;
                        this.updateAdminUI();
                    }
                    
                    // Handle user emoji from server
                    if (message.userEmoji) {
                        this.userEmoji = message.userEmoji;
                        this.updateEmojiDisplay(message.userEmoji);
                        // Save to localStorage for current user
                        if (this.username) {
                            localStorage.setItem(`userEmoji_${this.username}`, message.userEmoji);
                        }
                    }
                    
                    // Handle room joining after receiving room list
                    if (this.isReconnecting && this.previousRoomId) {
                        // Try to rejoin the previous room
                        const previousRoom = this.rooms.find(r => r.id === this.previousRoomId);
                        if (previousRoom) {
                            console.log('Rejoining previous room:', previousRoom.name);
                            this.joinRoom(previousRoom.id);
                        } else {
                            // Previous room no longer exists, join Lobby
                            console.log('Previous room no longer exists, joining Lobby');
                            const lobbyRoom = this.rooms.find(r => r.name === 'Lobby');
                            if (lobbyRoom) {
                                this.joinRoom(lobbyRoom.id);
                            }
                        }
                        this.isReconnecting = false; // Reset reconnection flag
                    } else if (!this.currentRoom) {
                        // Initial connection without previous room, join Lobby
                        const lobbyRoom = this.rooms.find(r => r.name === 'Lobby');
                        if (lobbyRoom) {
                            this.joinRoom(lobbyRoom.id);
                        }
                    }
                    break;
                    
                case 'roomCreated':
                    if (!this.rooms.find(r => r.id === message.room.id)) {
                        this.rooms.push(message.room);
                        this.updateRoomsList();
                    }
                    // Close the create room dialog
                    hideCreateRoom();
                    
                    // Automatically open rooms list
                    const roomsListContainer = document.getElementById('rooms-list-container');
                    const toggleIcon = document.querySelector('.rooms-section-header .toggle-icon');
                    roomsListContainer.classList.remove('collapsed');
                    toggleIcon.textContent = '▼';
                    
                    // Automatically select the newly created room
                    this.joinRoom(message.room.id);
                    break;
                    
                case 'roomJoined':
                    const wasReconnectingToSameRoom = this.isReconnecting && 
                                                      this.currentRoom && 
                                                      this.currentRoom.id === message.room.id;
                    
                    this.currentRoom = message.room;
                    
                    // Handle admin status from server
                    if (typeof message.isAdmin !== 'undefined') {
                        this.isAdmin = message.isAdmin;
                        this.updateAdminUI();
                    }
                    
                    // Clean up any stuck system messages when joining rooms
                    this.cleanupSystemMessages();
                    
                    this.updateRoomsList();
                    document.getElementById('current-room-name').textContent = message.room.name;
                    document.getElementById('leave-room-btn').disabled = false;
                    document.getElementById('clear-history-btn').disabled = false;
                    document.getElementById('message-input').disabled = false;
                    document.getElementById('send-btn').disabled = false;
                    document.getElementById('invite-btn').disabled = false;
                    document.getElementById('file-btn').disabled = false;

                    // Handle message history properly
                    if (wasReconnectingToSameRoom) {
                        console.log('Reconnecting to same room, preserving existing messages');
                        // Keep existing messages, server will send any new ones we missed
                    } else {
                        // Save current messages before switching rooms
                        if (this.currentRoom && this.messages.length > 0) {
                            const previousRoomId = this.currentRoom.id;
                            this.messagesByRoom[previousRoomId] = [...this.messages];
                        }
                        
                        // For new room or initial join, clear messages and wait for server history
                        this.messages = [];
                        
                        // If we have cached messages for this room, restore them
                        // Server will send fresh history which will be merged with these
                        if (this.messagesByRoom[message.room.id]) {
                            console.log('Restoring cached messages for room:', message.room.name);
                            this.messages = [...this.messagesByRoom[message.room.id]];
                        }
                    }
                    
                    this.updateMessagesDisplay();

                    // Show/hide remove and clear history buttons based on admin status
                    this.updateRoomActionButtons();

                    // Show system message if Lobby
                    if (message.room.name === 'Lobby' && !wasReconnectingToSameRoom) {
                        // Remove the temporary system message
                        // this.showTemporarySystemMessage('You are now in the Lobby.', 10000);
                    }
                    break;
                    
                case 'chatMessage':
                    this.addMessage(message.message);
                    break;
                    
                case 'userJoined':
                    // Removed user joined message
                    break;
                    
                case 'userLeft':
                    // Removed user left message
                    break;
                    
                case 'inviteCreated':
                    this.showInviteLink(message.link);
                    break;
                    
                case 'chatHistoryCleared':
                    if (this.currentRoom && this.currentRoom.id === message.roomId) {
                        this.messages = [];
                        this.updateMessagesDisplay();
                        this.addSystemMessage('Chat history has been cleared');
                    }
                    break;
                    
                case 'error':
                    if (message.message.includes('room with this name already exists')) {
                        this.showRoomCreationError(message.message);
                    } else {
                        alert('Error: ' + message.message);
                    }
                    break;
                    
                case 'userCount':
                    this.updateUserCount(message.count);
                    break;
                    
                case 'roomRemoved':
                    console.log('[roomRemoved] Received for roomId:', message.roomId);
                    this.rooms = this.rooms.filter(r => r.id !== message.roomId);
                    if (this.currentRoom && this.currentRoom.id === message.roomId) {
                        this.currentRoom = null;
                        document.getElementById('current-room-name').textContent = 'Select a room';
                        document.getElementById('leave-room-btn').disabled = true;
                        document.getElementById('clear-history-btn').disabled = true;
                        document.getElementById('message-input').disabled = true;
                        document.getElementById('send-btn').disabled = true;
                        document.getElementById('invite-btn').disabled = true;
                        document.getElementById('file-btn').disabled = true;
                        document.getElementById('remove-room-btn').style.display = 'none';
                        this.messages = [];
                        this.updateMessagesDisplay();
                    }
                    this.updateRoomsList();
                    break;
                case 'emojiUpdated':
                    if (message.success) {
                        this.userEmoji = message.emoji;
                        this.updateEmojiDisplay(message.emoji);
                        // Save to localStorage for current user
                        if (this.username) {
                            localStorage.setItem(`userEmoji_${this.username}`, message.emoji);
                        }
                        console.log('✅ Emoji updated to:', message.emoji);
                    } else {
                        console.error('❌ Failed to update emoji:', message.error);
                    }
                    break;
            }
        }
        
        updateAdminUI() {
            // Update CSS classes for admin/user styling
            document.body.classList.remove('admin', 'user');
            document.body.classList.add(this.isAdmin ? 'admin' : 'user');
        }
        
        updateRoomActionButtons() {
            const removeBtn = document.getElementById('remove-room-btn');
            const clearBtn = document.getElementById('clear-history-btn');
            
            // Show/hide buttons based on admin status and room type
            if (this.currentRoom && this.currentRoom.name !== 'Lobby') {
                if (this.isAdmin) {
                    if (removeBtn) {
                        removeBtn.style.display = 'inline-block';
                        removeBtn.textContent = 'Remove';
                    }
                } else {
                    if (removeBtn) removeBtn.style.display = 'none';
                }
            } else {
                if (removeBtn) removeBtn.style.display = 'none';
            }
            
            if (clearBtn) {
                clearBtn.style.display = this.isAdmin ? 'inline-block' : 'none';
            }
        }
        
        joinChat() {
            const usernameInput = document.getElementById('nickname-input');
            const username = usernameInput.value.trim();
            
            if (!username) {
                alert('Please enter a username');
                return;
            }
            
            this.username = username;
            document.getElementById('current-username').textContent = username;
            
            // Switch to chat screen
            document.getElementById('login-screen').classList.add('hidden');
            document.getElementById('chat-screen').classList.remove('hidden');
            
            // Connect to server (this will NOT be a reconnection for initial login)
            this.isReconnecting = false;
            this.connect();
        }
        
        createRoom() {
            const roomNameInput = document.getElementById('room-name-input');
            const roomName = roomNameInput.value.trim();
            
            if (!roomName) {
                alert('Please enter a room name');
                return;
            }
            
            try {
                this.sendToServer({
                    type: 'createRoom',
                    name: roomName
                });
                
                roomNameInput.value = '';
            } catch (error) {
                console.error('Failed to create room:', error);
                this.showRoomCreationError('Failed to create room. Please try again.');
            }
        }
        
        showRoomCreationError(message) {
            const createRoomModal = document.getElementById('create-room-modal');
            
            // Show error message
            const errorContainer = document.createElement('div');
            errorContainer.className = 'error-message';
            errorContainer.textContent = message;
            createRoomModal.querySelector('.modal-content').insertBefore(
                errorContainer, 
                createRoomModal.querySelector('.modal-actions')
            );
            
            // Auto-remove error message after 10 seconds for non-admin users
            // Admins can see persistent error messages for debugging
            const removeTimeout = this.isAdmin ? 15000 : 10000; // Slightly longer for admins
            setTimeout(() => {
                if (errorContainer && errorContainer.parentNode) {
                    errorContainer.classList.add('expiring');
                    setTimeout(() => {
                        if (errorContainer && errorContainer.parentNode) {
                            errorContainer.remove();
                        }
                    }, 1000);
                }
            }, removeTimeout);
        }
        
        joinRoom(roomId) {
            const room = this.rooms.find(r => r.id === roomId);
            if (!room) return;
            
            // Save current room messages before switching
            if (this.currentRoom && this.currentRoom.id !== roomId) {
                this.messagesByRoom[this.currentRoom.id] = [...this.messages];
            }
            
            this.currentRoom = room;
            document.getElementById('current-room-name').textContent = room.name;
            document.getElementById('leave-room-btn').disabled = false;
            document.getElementById('clear-history-btn').disabled = false;
            document.getElementById('message-input').disabled = false;
            document.getElementById('send-btn').disabled = false;
            document.getElementById('invite-btn').disabled = false;
            document.getElementById('file-btn').disabled = false;
            
            // Update room action buttons based on admin status
            this.updateRoomActionButtons();
            
            // Load saved messages for this room or clear if none exist
            if (this.messagesByRoom[roomId]) {
                this.messages = [...this.messagesByRoom[roomId]];
            } else {
                this.messages = [];
            }
            this.updateMessagesDisplay();
            
            // Update room selection
            document.querySelectorAll('.room-item').forEach(item => {
                item.classList.remove('active');
            });
            document.querySelector(`[data-room-id="${roomId}"]`).classList.add('active');
            
            // Send join room message to server
            this.sendToServer({
                type: 'joinRoom',
                roomId: roomId
            });
        }
        
        leaveRoom() {
            if (!this.currentRoom) return;
            
            this.sendToServer({
                type: 'leaveRoom',
                roomId: this.currentRoom.id
            });
            
            this.currentRoom = null;
            
            // Update UI
            document.getElementById('current-room-name').textContent = 'Select a room';
            document.getElementById('leave-room-btn').disabled = true;
            document.getElementById('clear-history-btn').disabled = true;
            document.getElementById('message-input').disabled = true;
            document.getElementById('send-btn').disabled = true;
            document.getElementById('invite-btn').disabled = true;
            document.getElementById('file-btn').disabled = true;
            
            // Clear room selection
            document.querySelectorAll('.room-item').forEach(item => {
                item.classList.remove('active');
            });
            
            // Clear messages
            this.messages = [];
            this.updateMessagesDisplay();
        }
        
        clearChatHistory() {
            if (!this.isAdmin) {
                alert('Only administrators can clear chat history.');
                return;
            }
            if (!this.currentRoom) return;
            
            if (confirm('Are you sure you want to clear the chat history for this room? This action cannot be undone.')) {
                this.sendToServer({
                    type: 'clearChatHistory',
                    roomId: this.currentRoom.id
                });
            }
        }
        
        removeRoom() {
            if (!this.isAdmin) {
                alert('Only administrators can remove rooms.');
                return;
            }
            if (!this.currentRoom || this.currentRoom.name === 'Lobby') return;
            if (confirm(`Are you sure you want to remove the room '${this.currentRoom.name}'? This cannot be undone.`)) {
                this.sendToServer({ type: 'removeRoom', roomId: this.currentRoom.id });
            }
        }
        
        sendMessage() {
            const messageInput = document.getElementById('message-input');
            const content = messageInput.value.trim();
            
            if (!content || !this.currentRoom) return;
            
            // Check connection before sending
            if (!this.isConnected || !this.ws || this.ws.readyState !== WebSocket.OPEN) {
                console.log('Cannot send message: not connected to server');
                this.showConnectionError('Cannot send message while disconnected. Please wait for reconnection.');
                return;
            }
            
            this.sendToServer({
                type: 'sendMessage',
                roomId: this.currentRoom.id,
                content: content,
                emoji: this.userEmoji
            });
            
            messageInput.value = '';
        }
        
        showConnectionError(message) {
            // Show a temporary error message
            const container = document.getElementById('messages-container');
            const errorMsg = document.createElement('div');
            errorMsg.className = 'message system connection-error';
            errorMsg.textContent = message;
            container.appendChild(errorMsg);
            container.scrollTop = container.scrollHeight;
            
            // Auto-remove error message after 10 seconds for all users
            setTimeout(() => {
                if (errorMsg.parentNode) {
                    // Add expiring animation
                    errorMsg.classList.add('expiring');
                    setTimeout(() => {
                        if (errorMsg.parentNode) {
                            errorMsg.remove();
                        }
                    }, 1000); // Match CSS transition duration
                }
            }, 10000); // Always remove after 10 seconds
        }
        
        showErrorMessage(message, container = null, className = 'error-message') {
            // General method for showing error messages with auto-removal
            const targetContainer = container || document.getElementById('messages-container');
            const errorMsg = document.createElement('div');
            
            if (container) {
                // Modal or specific container error
                errorMsg.className = className;
            } else {
                // Chat area error
                errorMsg.className = 'message system connection-error';
            }
            
            errorMsg.textContent = message;
            
            if (container) {
                // Insert before modal actions if it's a modal
                const modalActions = container.querySelector('.modal-actions');
                if (modalActions) {
                    container.insertBefore(errorMsg, modalActions);
                } else {
                    container.appendChild(errorMsg);
                }
            } else {
                targetContainer.appendChild(errorMsg);
                targetContainer.scrollTop = targetContainer.scrollHeight;
            }
            
            // Auto-remove error message after 10 seconds for non-admin users
            // Admins get slightly longer timeout for debugging
            const removeTimeout = this.isAdmin ? 15000 : 10000;
            setTimeout(() => {
                if (errorMsg && errorMsg.parentNode) {
                    errorMsg.classList.add('expiring');
                    setTimeout(() => {
                        if (errorMsg && errorMsg.parentNode) {
                            errorMsg.remove();
                        }
                    }, 1000);
                }
            }, removeTimeout);
            
            return errorMsg;
        }
        
        createInvite() {
            if (!this.currentRoom) return;
            
            // Check connection before creating invite
            if (!this.isConnected || !this.ws || this.ws.readyState !== WebSocket.OPEN) {
                console.log('Cannot create invite: not connected to server');
                this.showConnectionError('Cannot create invite while disconnected. Please wait for reconnection.');
                return;
            }
            
            this.sendToServer({
                type: 'createInvite',
                roomId: this.currentRoom.id
            });
        }
        
        async uploadFile(file) {
            const formData = new FormData();
            formData.append('file', file);
            
            console.log('📤 Uploading file:', file.name, 'Size:', file.size, 'Type:', file.type);
            console.log('📤 FormData entries:');
            for (let [key, value] of formData.entries()) {
                console.log(`  ${key}:`, value);
            }
            
            try {
                const response = await fetch('/upload', {
                    method: 'POST',
                    body: formData
                    // Note: Don't set Content-Type header manually - let browser set it with boundary
                });
                
                console.log('📤 Response status:', response.status);
                console.log('📤 Response headers:', response.headers);
                
                if (!response.ok) {
                    const errorText = await response.text();
                    console.error('❌ Upload failed:', response.status, errorText);
                    throw new Error(`Upload failed: ${response.status} ${errorText}`);
                }
                const result = await response.json();
                if (result.success) {
                    console.log('✅ Upload successful:', result.attachment);
                    return result.attachment;
                } else {
                    console.error('❌ Upload failed:', result.error);
                    throw new Error(result.error || 'Upload failed');
                }
            } catch (error) {
                console.error('❌ File upload error:', error);
                throw error;
            }
        }
        
        async sendFileMessage(attachment, caption = '') {
            if (!this.currentRoom) return;
            
            // Check connection before sending file message
            if (!this.isConnected || !this.ws || this.ws.readyState !== WebSocket.OPEN) {
                console.log('Cannot send file: not connected to server');
                this.showConnectionError('Cannot send file while disconnected. Please wait for reconnection.');
                return;
            }
            
            console.log('Sending file message:', {
                roomId: this.currentRoom.id,
                attachment: attachment,
                caption: caption
            });
            
            this.sendToServer({
                type: 'sendFileMessage',
                roomId: this.currentRoom.id,
                attachment: attachment,
                caption: caption
            });
        }
        
        selectFiles() {
            if (!this.currentRoom) {
                alert('Please join a room before uploading files.');
                return;
            }
            document.getElementById('file-input').click();
        }
        
        handleFileSelection(files) {
            if (!this.currentRoom) {
                alert('Please join a room before uploading files.');
                return;
            }
            this.selectedFiles = Array.from(files);
            this.showFileUploadModal();
        }
        
        showFileUploadModal() {
            const modal = document.getElementById('file-upload-modal');
            const container = document.getElementById('file-preview-container');
            const uploadBtn = document.getElementById('upload-files-btn');
            
            container.innerHTML = '';
            
            if (this.selectedFiles.length === 0) {
                container.innerHTML = '<p>No files selected</p>';
                uploadBtn.disabled = true;
                return;
            }
            
            uploadBtn.disabled = false;
            
            this.selectedFiles.forEach((file, index) => {
                const item = document.createElement('div');
                item.className = 'file-preview-item';
                
                const thumbnail = document.createElement('div');
                thumbnail.className = 'file-preview-thumbnail';
                
                if (file.type.startsWith('image/')) {
                    const img = document.createElement('img');
                    img.src = URL.createObjectURL(file);
                    img.onload = () => URL.revokeObjectURL(img.src);
                    img.style.width = '100%';
                    img.style.height = '100%';
                    img.style.objectFit = 'cover';
                    img.style.borderRadius = '8px';
                    thumbnail.appendChild(img);
                } else {
                    thumbnail.textContent = this.getFileIcon(file.type);
                }
                
                const info = document.createElement('div');
                info.className = 'file-preview-info';
                
                const name = document.createElement('div');
                name.className = 'file-preview-name';
                name.textContent = file.name;
                
                const size = document.createElement('div');
                size.className = 'file-preview-size';
                size.textContent = this.formatFileSize(file.size);
                
                info.appendChild(name);
                info.appendChild(size);
                
                const removeBtn = document.createElement('button');
                removeBtn.className = 'file-preview-remove';
                removeBtn.textContent = '×';
                removeBtn.onclick = () => this.removeFile(index);
                
                item.appendChild(thumbnail);
                item.appendChild(info);
                item.appendChild(removeBtn);
                
                container.appendChild(item);
            });
            
            modal.classList.remove('hidden');
        }
        
        removeFile(index) {
            this.selectedFiles.splice(index, 1);
            this.showFileUploadModal();
        }
        
        async uploadFiles() {
            if (this.selectedFiles.length === 0) return;
            
            const caption = document.getElementById('file-caption').value.trim();
            const uploadBtn = document.getElementById('upload-files-btn');
            const errorDiv = document.getElementById('upload-error');
            
            uploadBtn.disabled = true;
            uploadBtn.textContent = 'Uploading...';
            if (errorDiv) errorDiv.textContent = '';
            
            try {
                for (const file of this.selectedFiles) {
                    console.log('📤 Processing file:', file.name);
                    const attachment = await this.uploadFile(file);
                    await this.sendFileMessage(attachment, caption);
                }
                
                this.hideFileUploadModal();
                this.selectedFiles = [];
                document.getElementById('file-caption').value = '';
                
            } catch (error) {
                console.error('❌ Upload failed:', error);
                if (errorDiv) {
                    errorDiv.textContent = error.message || 'Upload failed';
                    errorDiv.style.display = 'block';
                } else {
                    alert('Upload failed: ' + error.message);
                }
            } finally {
                uploadBtn.disabled = false;
                uploadBtn.textContent = 'Upload';
            }
        }
        
        hideFileUploadModal() {
            document.getElementById('file-upload-modal').classList.add('hidden');
        }
        
        getFileIcon(mimeType) {
            if (mimeType.startsWith('image/')) return '🖼️';
            if (mimeType.includes('pdf')) return '📄';
            if (mimeType.includes('word') || mimeType.includes('document')) return '📝';
            if (mimeType.includes('excel') || mimeType.includes('spreadsheet')) return '📊';
            if (mimeType.includes('powerpoint') || mimeType.includes('presentation')) return '📈';
            if (mimeType.includes('zip') || mimeType.includes('archive')) return '🗜️';
            if (mimeType.includes('text')) return '📄';
            return '📎';
        }
        
        formatFileSize(bytes) {
            if (bytes === 0) return '0 Bytes';
            const k = 1024;
            const sizes = ['Bytes', 'KB', 'MB', 'GB'];
            const i = Math.floor(Math.log(bytes) / Math.log(k));
            return parseFloat((bytes / Math.pow(k, i)).toFixed(2)) + ' ' + sizes[i];
        }
        
        addMessage(message) {
            // Check for duplicate messages to prevent repeats on reconnection
            const isDuplicate = this.messages.some(existingMessage => {
                return existingMessage.content === message.content &&
                       existingMessage.sender === message.sender &&
                       existingMessage.timestamp === message.timestamp &&
                       existingMessage.type === message.type;
            });
            
            if (!isDuplicate) {
                this.messages.push(message);
                
                // Save to room-specific storage immediately
                if (this.currentRoom) {
                    this.messagesByRoom[this.currentRoom.id] = [...this.messages];
                }
                
                this.updateMessagesDisplay();
            }
        }
        
        addSystemMessage(content) {
            // Check for duplicate system messages
            const isDuplicate = this.messages.some(existingMessage => {
                return existingMessage.content === content &&
                       existingMessage.type === 'system';
            });
            
            if (!isDuplicate) {
                const message = {
                    type: 'system',
                    content: content,
                    timestamp: new Date().toISOString(),
                    isExpiring: true // All system messages expire now
                };
                this.addMessage(message);
                
                // ALWAYS auto-remove system messages after 10 seconds - no exceptions
                setTimeout(() => {
                    this.removeSystemMessage(message);
                }, 10000);
            }
        }
        
        removeSystemMessage(messageToRemove) {
            // Find the DOM element for this system message
            const messageElements = document.querySelectorAll('.message.system');
            let targetElement = null;
            
            for (let element of messageElements) {
                if (element.textContent === messageToRemove.content) {
                    targetElement = element;
                    break;
                }
            }
            
            // Animate out the DOM element first
            if (targetElement) {
                targetElement.classList.add('expiring');
                setTimeout(() => {
                    if (targetElement.parentNode) {
                        targetElement.remove();
                    }
                }, 300); // Faster animation - reduced from 1000ms
            }
            
            // Remove from messages array
            const index = this.messages.findIndex(msg => 
                msg.type === 'system' && 
                msg.content === messageToRemove.content && 
                msg.timestamp === messageToRemove.timestamp
            );
            
            if (index !== -1) {
                this.messages.splice(index, 1);
                
                // Update room-specific storage
                if (this.currentRoom) {
                    this.messagesByRoom[this.currentRoom.id] = [...this.messages];
                }
                
                // Update display after a short delay to allow animation
                setTimeout(() => {
                    this.updateMessagesDisplay();
                }, 400); // Reduced from 1100ms
            }
        }
        
        updateMessagesDisplay() {
            const container = document.getElementById('messages-container');
            
            if (this.messages.length === 0) {
                const welcomeText = this.currentRoom ? 
                    `Welcome to ${this.currentRoom.name}!` : 
                    `Welcome to ${window.location.hostname}!`;
                    
                container.innerHTML = `
                    <div class="welcome-message">
                        <h3>${welcomeText} 🎉</h3>
                        <p>${this.currentRoom ? 'Start chatting with others in this room.' : 'Create a room or join an existing one to start chatting.'}</p>
                    </div>
                `;
                return;
            }
            
            container.innerHTML = '';
            
            this.messages.forEach(message => {
                const messageEl = document.createElement('div');
                
                if (message.type === 'system') {
                    messageEl.className = 'message system lobby-welcome';
                    messageEl.textContent = message.content;
                } else {
                    const isOwn = message.sender === this.username;
                    messageEl.className = `message ${isOwn ? 'own' : 'other'}`;
                    
                    const time = new Date(message.timestamp).toLocaleTimeString([], {
                        hour: '2-digit',
                        minute: '2-digit'
                    });
                    
                    let attachmentHTML = '';
                    if (message.attachment) {
                        const attachment = message.attachment;
                        if (attachment.isImage) {
                            const imageUrl = `/files/${attachment.id}/${encodeURIComponent(attachment.originalFileName)}`;
                            attachmentHTML = `
                                <div class="message-attachment">
                                    <img src="${imageUrl}" 
                                         alt="${attachment.originalFileName}"
                                         class="message-attachment-image"
                                         onclick="window.open('${imageUrl}', '_blank')">
                                </div>
                            `;
                        } else {
                            const fileUrl = `/files/${attachment.id}/${encodeURIComponent(attachment.originalFileName)}`;
                            attachmentHTML = `
                                <div class="message-attachment">
                                    <a href="${fileUrl}" 
                                       class="message-attachment-file" 
                                       target="_blank" 
                                       download="${attachment.originalFileName}">
                                        <div class="message-attachment-icon">${this.getFileIcon(attachment.mimeType)}</div>
                                        <div class="message-attachment-info">
                                            <div class="message-attachment-name">${attachment.originalFileName}</div>
                                            <div class="message-attachment-size">${this.formatFileSize(attachment.fileSize)}</div>
                                        </div>
                                    </a>
                                </div>
                            `;
                        }
                    }
                    
                    messageEl.innerHTML = `
                        <div class="message-header">
                            <span class="user-emoji">${message.emoji || '👤'}</span>
                            <span class="username">${message.sender}</span>
                            <span class="time">${time}</span>
                        </div>
                        <div class="message-content">${this.escapeHtml(message.content)}</div>
                        ${attachmentHTML}
                    `;
                    
                    // Apply emoji styling to message emojis immediately
                    if (message.emoji) {
                        // Apply fallback styling first, then load dynamic styling
                        const emojiElements = messageEl.querySelectorAll('.user-emoji');
                        emojiElements.forEach(emojiElement => {
                            if (emojiElement.textContent === message.emoji) {
                                this.applyFallbackEmojiStyling(emojiElement);
                            }
                        });
                        this.loadEmojiStyling(message.emoji);
                    }
                }
                
                container.appendChild(messageEl);
            });
            
            // Ensure all unique emojis in messages get their styling applied
            this.applyAllMessageEmojiStyling();
            
            // Force immediate styling application for any emojis that might have been missed
            setTimeout(() => {
                this.applyAllMessageEmojiStyling();
            }, 10); // Very short delay to ensure DOM is fully updated
            
            // Scroll to bottom
            container.scrollTop = container.scrollHeight;
        }
        
        updateRoomsList() {
            const container = document.getElementById('rooms-list');
            container.innerHTML = '';
            
            this.rooms.forEach(room => {
                const roomEl = document.createElement('div');
                roomEl.className = 'room-item';
                roomEl.setAttribute('data-room-id', room.id);
                
                // Store the full room name as a data attribute
                roomEl.setAttribute('data-full-name', room.name);
                
                // Update room name display based on window width
                const updateRoomName = () => {
                    if (window.innerWidth <= 768) {
                        const firstWord = room.name.split(' ')[0] || room.name;
                        roomEl.textContent = firstWord;
                    } else {
                        roomEl.textContent = room.name;
                    }
                };
                
                // Initial display
                updateRoomName();
                
                // Add title attribute to show full name on hover (useful for mobile too)
                roomEl.setAttribute('title', room.name);
                
                roomEl.onclick = () => this.joinRoom(room.id);
                container.appendChild(roomEl);
            });
            
            // Add window resize listener to update room names
            window.addEventListener('resize', () => {
                const roomElements = container.querySelectorAll('.room-item');
                roomElements.forEach(roomEl => {
                    const fullName = roomEl.getAttribute('data-full-name');
                    if (window.innerWidth <= 768) {
                        const firstWord = fullName.split(' ')[0] || fullName;
                        roomEl.textContent = firstWord;
                    } else {
                        roomEl.textContent = fullName;
                    }
                });
            });
            
            // Highlight the selected room
            if (this.currentRoom) {
                const activeRoom = container.querySelector(`[data-room-id="${this.currentRoom.id}"]`);
                if (activeRoom) activeRoom.classList.add('active');
            }
        }
        
        updateConnectionStatus() {
            const statusEl = document.getElementById('connection-status');
            const messageInput = document.getElementById('message-input');
            const sendBtn = document.getElementById('send-btn');
            const fileBtn = document.getElementById('file-btn');
            const messagesContainer = document.getElementById('messages-container');
            
            if (this.isConnected) {
                statusEl.textContent = 'Connected';
                statusEl.className = 'status-connected';
                
                // Re-enable message input and buttons if in a room
                if (this.currentRoom) {
                    messageInput.disabled = false;
                    sendBtn.disabled = false;
                    fileBtn.disabled = false;
                    messageInput.placeholder = 'Type a message...';
                }
                
                // Remove disconnected styling from chat area
                if (messagesContainer) {
                    messagesContainer.classList.remove('disconnected');
                }
                
            } else {
                statusEl.textContent = 'Disconnected';
                statusEl.className = 'status-disconnected';
                
                // Disable message input and buttons
                messageInput.disabled = true;
                sendBtn.disabled = true;
                fileBtn.disabled = true;
                messageInput.placeholder = 'Disconnected - please wait for reconnection...';
                
                // Add disconnected styling to chat area
                if (messagesContainer) {
                    messagesContainer.classList.add('disconnected');
                }
            }
        }
        
        updateUserCount(count) {
            document.getElementById('user-count').textContent = `${count} user${count !== 1 ? 's' : ''} online`;
        }
        
        showInviteLink(link) {
            document.getElementById('invite-link').value = link;
            document.getElementById('invite-modal').classList.remove('hidden');
        }
        
        escapeHtml(text) {
            const div = document.createElement('div');
            div.textContent = text;
            return div.innerHTML;
        }

        showTemporarySystemMessage(content, durationMs) {
            const container = document.getElementById('messages-container');
            const msg = document.createElement('div');
            msg.className = 'message system lobby-welcome';
            msg.textContent = content;
            container.appendChild(msg);
            container.scrollTop = container.scrollHeight;

            // ALWAYS auto-remove system messages - no admin exception
            setTimeout(() => {
                msg.style.transition = 'opacity 0.3s';
                msg.style.opacity = 0;
                setTimeout(() => {
                    if (msg.parentNode) {
                        msg.remove();
                    }
                }, 300); // Faster removal
            }, Math.min(durationMs, 10000)); // Max 10 seconds
        }

        // Cleanup function to remove ALL stuck system messages immediately
        cleanupSystemMessages() {
            console.log('Cleaning up stuck system messages...');
            
            // Remove from DOM immediately
            const systemMessages = document.querySelectorAll('.message.system');
            systemMessages.forEach(msg => {
                msg.style.transition = 'opacity 0.1s';
                msg.style.opacity = 0;
                setTimeout(() => {
                    if (msg.parentNode) {
                        msg.remove();
                    }
                }, 100);
            });
            
            // Remove from messages array
            this.messages = this.messages.filter(msg => msg.type !== 'system');
            
            // Update room-specific storage
            if (this.currentRoom) {
                this.messagesByRoom[this.currentRoom.id] = [...this.messages];
            }
            
            // Update display
            setTimeout(() => {
                this.updateMessagesDisplay();
            }, 200);
        }

        updateEmojiDisplay(emoji) {
            // Update user avatar in sidebar
            const userAvatar = document.querySelector('.user-avatar');
            if (userAvatar) {
                userAvatar.textContent = emoji;
            }
            
            // Update selected emoji in login form if visible
            const selectedEmoji = document.getElementById('selected-emoji');
            if (selectedEmoji) {
                selectedEmoji.textContent = emoji;
            }
            
            // Update emoji picker selection
            document.querySelectorAll('.emoji-option').forEach(option => {
                option.classList.remove('selected');
                if (option.textContent === emoji) {
                    option.classList.add('selected');
                }
            });
            
            // Save emoji to localStorage for current user
            if (this.username) {
                localStorage.setItem(`userEmoji_${this.username}`, emoji);
            }
            
            // Apply cached or analyze emoji colors
            this.loadEmojiStyling(emoji);
        }
        
        loadEmojiStyling(emoji) {
            // Check if we have cached colors for this emoji
            const cachedColors = localStorage.getItem(`emojiColors_${emoji}`);
            if (cachedColors) {
                try {
                    const colors = JSON.parse(cachedColors);
                    this.applyEmojiStyling(emoji, colors.contrastColor, colors.textColor);
                    return;
                } catch (error) {
                    console.log('Failed to parse cached emoji colors:', error);
                }
            }
            
            // If no cached colors, analyze them
            this.analyzeEmojiColors(emoji);
        }

        applyAllMessageEmojiStyling() {
            // Find all unique emojis currently displayed in messages
            const uniqueEmojis = new Set();
            document.querySelectorAll('.user-emoji').forEach(emojiElement => {
                const emoji = emojiElement.textContent;
                if (emoji) { // Include ALL emojis, even default ones
                    uniqueEmojis.add(emoji);
                    
                    // ALWAYS apply immediate fallback styling first
                        this.applyFallbackEmojiStyling(emojiElement);
                }
            });
            
            // Apply dynamic styling to each unique emoji (this will override fallback)
            uniqueEmojis.forEach(emoji => {
                this.loadEmojiStyling(emoji);
            });
        }

        applyFallbackEmojiStyling(emojiElement) {
            // Apply a default contrasting background immediately
            emojiElement.style.backgroundColor = 'rgba(255, 255, 255, 0.9)';
            emojiElement.style.color = '#333333';
            emojiElement.style.border = '2px solid rgba(255, 255, 255, 0.7)';
            emojiElement.style.boxShadow = '0 2px 6px rgba(0, 0, 0, 0.15)';
        }

        updateUserEmoji(newEmoji) {
            this.sendToServer({
                type: 'updateEmoji',
                emoji: newEmoji
            });
            
            // Analyze emoji colors for contrasting background
            this.analyzeEmojiColors(newEmoji);
        }
        
        async analyzeEmojiColors(emoji) {
            try {
                const response = await fetch('/emoji/analyze', {
                    method: 'POST',
                    headers: { 'Content-Type': 'application/json' },
                    body: JSON.stringify({ emoji })
                });
                
                if (response.ok) {
                    const result = await response.json();
                    if (result.success) {
                        // Apply the contrasting background color to emoji elements
                        this.applyEmojiStyling(emoji, result.contrastColor, result.textColor);
                        
                        // Save colors to localStorage for this emoji
                        localStorage.setItem(`emojiColors_${emoji}`, JSON.stringify({
                            contrastColor: result.contrastColor,
                            textColor: result.textColor
                        }));
                    }
                }
            } catch (error) {
                console.log('Emoji color analysis failed:', error);
                // Fallback to default styling
                this.applyEmojiStyling(emoji, '#f0f0f0', '#000000');
            }
        }
        
        applyEmojiStyling(emoji, backgroundColor, textColor) {
            // Apply styling to user avatar in sidebar
            const userAvatar = document.querySelector('.user-avatar');
            if (userAvatar && userAvatar.textContent === emoji) {
                userAvatar.style.backgroundColor = backgroundColor;
                userAvatar.style.color = textColor;
                userAvatar.style.border = 'none';
            }
            
            // Apply styling to selected emoji in login form
            const selectedEmoji = document.getElementById('selected-emoji');
            if (selectedEmoji && selectedEmoji.textContent === emoji) {
                selectedEmoji.style.backgroundColor = backgroundColor;
                selectedEmoji.style.color = textColor;
                selectedEmoji.style.border = `3px solid ${this.adjustColorBrightness(backgroundColor, 30)}`;
            }
            
            // Apply styling to user emoji picker modal
            const selectedUserEmoji = document.getElementById('selected-user-emoji');
            if (selectedUserEmoji && selectedUserEmoji.textContent === emoji) {
                selectedUserEmoji.style.backgroundColor = backgroundColor;
                selectedUserEmoji.style.color = textColor;
                selectedUserEmoji.style.border = `3px solid ${this.adjustColorBrightness(backgroundColor, 30)}`;
            }
            
            // Apply styling to ALL message emoji bubbles with this emoji (including default user icons)
            document.querySelectorAll('.user-emoji').forEach(emojiElement => {
                if (emojiElement.textContent === emoji) {
                    emojiElement.style.setProperty('background-color', backgroundColor, 'important');
                    emojiElement.style.setProperty('color', textColor, 'important');
                    emojiElement.style.setProperty('border', `2px solid ${this.adjustColorBrightness(backgroundColor, 15)}`, 'important');
                    emojiElement.style.setProperty('box-shadow', '0 2px 6px rgba(0, 0, 0, 0.15)', 'important');
                }
            });
        }
        
        // Helper function to adjust color brightness
        adjustColorBrightness(hex, percent) {
            // Remove the hash if it exists
            hex = hex.replace('#', '');
            
            // Parse r, g, b values
            const r = parseInt(hex.substr(0, 2), 16);
            const g = parseInt(hex.substr(2, 2), 16);
            const b = parseInt(hex.substr(4, 2), 16);
            
            // Calculate new values
            const newR = Math.max(0, Math.min(255, r + percent));
            const newG = Math.max(0, Math.min(255, g + percent));
            const newB = Math.max(0, Math.min(255, b + percent));
            
            // Convert back to hex
            return `#${newR.toString(16).padStart(2, '0')}${newG.toString(16).padStart(2, '0')}${newB.toString(16).padStart(2, '0')}`;
        }
    }
    
    // Global functions for HTML onclick handlers
    let chatClient;
    
    function joinChat() {
        chatClient.joinChat();
    }
    
    function createRoom() {
        chatClient.createRoom();
    }
    
    function leaveRoom() {
        chatClient.leaveRoom();
    }
    
    function sendMessage() {
        chatClient.sendMessage();
    }
    
    function createInvite() {
        chatClient.createInvite();
    }
    
    function clearChatHistory() {
        chatClient.clearChatHistory();
    }
    
    function selectFiles() {
        chatClient.selectFiles();
    }
    
    function uploadFiles() {
        chatClient.uploadFiles();
    }
    
    function hideFileUploadModal() {
        chatClient.hideFileUploadModal();
    }
    
    function showCreateRoom() {
        document.getElementById('create-room-modal').classList.remove('hidden');
        document.getElementById('room-name-input').focus();
    }
    
    function hideCreateRoom() {
        document.getElementById('create-room-modal').classList.add('hidden');
    }
    
    function hideInviteModal() {
        document.getElementById('invite-modal').classList.add('hidden');
    }
    
    function copyInviteLink() {
        const linkInput = document.getElementById('invite-link');
        linkInput.select();
        document.execCommand('copy');
        
        // Show feedback
        const button = event.target;
        const originalText = button.textContent;
        button.textContent = 'Copied!';
        setTimeout(() => {
            button.textContent = originalText;
        }, 2000);
    }
    
    function toggleRoomsList() {
        const roomsListContainer = document.getElementById('rooms-list-container');
        const toggleIcon = document.querySelector('.rooms-section-header .toggle-icon');
        
        roomsListContainer.classList.toggle('collapsed');
        
        // Change arrow based on state
        if (roomsListContainer.classList.contains('collapsed')) {
            toggleIcon.textContent = '▶'; // Right arrow when collapsed
        } else {
            toggleIcon.textContent = '▼'; // Down arrow when expanded
        }
    }
    
    // Ensure initial state is correct on page load
    document.addEventListener('DOMContentLoaded', () => {
        const roomsListContainer = document.getElementById('rooms-list-container');
        const toggleIcon = document.querySelector('.rooms-section-header .toggle-icon');
        
        // Initially collapsed
        roomsListContainer.classList.add('collapsed');
        toggleIcon.textContent = '▶';

        chatClient = new ChatClient();
        
        // Load saved username from localStorage
        const savedUsername = localStorage.getItem('lastUsername');
        const usernameInput = document.getElementById('nickname-input');
        if (savedUsername && usernameInput) {
            usernameInput.value = savedUsername;
            usernameInput.blur();
        }

        // Emoji picker setup
        const selectedEmoji = document.getElementById('selected-emoji');
        const emojiOptions = document.querySelectorAll('.emoji-option');
        
        // Load saved emoji for the current user from localStorage or use default
        const savedEmoji = savedUsername ? localStorage.getItem(`userEmoji_${savedUsername}`) : null;
        let currentEmoji = savedEmoji || '👤';

        // Set initial selected emoji
        selectedEmoji.textContent = currentEmoji;
        
        // Update emoji picker selection based on saved emoji
        emojiOptions.forEach((option, index) => {
            option.classList.remove('selected');
            if (option.textContent === currentEmoji) {
                option.classList.add('selected');
            } else if (index === 0 && !savedEmoji) {
                // Select first option only if no saved emoji
                option.classList.add('selected');
            }
        });
        
        // Apply emoji styling
        analyzeEmojiColorsStandalone(currentEmoji);

        emojiOptions.forEach(option => {
            option.addEventListener('click', () => {
                // Remove selected class from all options
                emojiOptions.forEach(opt => opt.classList.remove('selected'));
                
                // Add selected class to clicked option
                option.classList.add('selected');
                
                // Update selected emoji
                currentEmoji = option.textContent;
                selectedEmoji.textContent = currentEmoji;
                
                // Save to localStorage for current user
                const currentUsername = document.getElementById('nickname-input').value.trim();
                if (currentUsername) {
                    localStorage.setItem(`userEmoji_${currentUsername}`, currentEmoji);
                }
                window.currentEmoji = currentEmoji;
                
                // Analyze emoji colors for styling
                if (chatClient) {
                    chatClient.loadEmojiStyling(currentEmoji);
                } else {
                    // If chatClient doesn't exist yet, just analyze directly
                    analyzeEmojiColorsStandalone(currentEmoji);
                }
            });
        });
        
        // Modify joinChat to include emoji
        window.joinChat = function() {
            const inputElement = document.getElementById('nickname-input');
            const username = inputElement.value.trim();
            
            if (!username) {
                alert('Please enter a username');
                return;
            }
            
            // Save username and emoji to localStorage
            localStorage.setItem('lastUsername', username);
            localStorage.setItem(`userEmoji_${username}`, currentEmoji);
            
            chatClient.username = username;
            chatClient.userEmoji = currentEmoji;
            document.getElementById('current-username').textContent = username;
            document.querySelector('.user-avatar').textContent = currentEmoji;
            
            // Switch to chat screen
            document.getElementById('login-screen').classList.add('hidden');
            document.getElementById('chat-screen').classList.remove('hidden');
            
            // Connect to server
            chatClient.connect();
        }
        
        // Focus username input and select text if present
        const nicknameInput = document.getElementById('nickname-input');
        if (nicknameInput) {
            //nicknameInput.focus();
            if (savedUsername) {
                //nicknameInput.select();
            }
            inputElement.blur();

            // Add event listener to load emoji when username changes
            nicknameInput.addEventListener('blur', function() {
                const username = this.value.trim();
                if (username) {
                    const userEmoji = localStorage.getItem(`userEmoji_${username}`);
                    if (userEmoji) {
                        // Update the emoji display
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
                        currentEmoji = userEmoji;
                    }
                }
            });
        }
        
        // Mobile keyboard handling for login form - prevent duplicate listeners
        const mobileInput = document.getElementById('nickname-input');
        if (mobileInput && !mobileInput.hasEventListeners) {
            mobileInput.hasEventListeners = true; // Mark to prevent duplicates
            
            // Simplified focus handling - remove complex scrolling that can cause issues
            mobileInput.addEventListener('focus', (e) => {
                // Ensure input stays focused and selectable
                e.target.style.userSelect = 'text';
                e.target.style.webkitUserSelect = 'text';
                e.target.style.pointerEvents = 'auto';
                e.target.style.touchAction = 'manipulation';
            });
            
            // Ensure input is always clickable and selectable
            mobileInput.addEventListener('touchstart', (e) => {
                // Prevent any interference with input selection
                e.target.style.userSelect = 'text';
                e.target.style.webkitUserSelect = 'text';
                e.target.style.pointerEvents = 'auto';
                e.target.style.touchAction = 'manipulation';
            });
            
            // Fix for iPhone keyboard issues
            mobileInput.addEventListener('click', (e) => {
                e.stopPropagation();
                e.target.focus();
            });
        }
        


        // Simplified mobile background tap handling - only for form elements that should blur
        const loginForm = document.querySelector('.login-form');
        if (loginForm) {
            loginForm.addEventListener('click', (e) => {
                // Only blur if clicking on the title or empty form areas, not on interactive elements
                if (window.innerWidth <= 768) {
                    const clickedElement = e.target;
                    
                    // Only blur for very specific non-interactive elements
                    if (clickedElement.tagName === 'H2' && clickedElement.textContent.includes('Welcome')) {
                        const inputEl = document.getElementById('nickname-input');
                        if (inputEl && document.activeElement === inputEl) {
                            inputEl.blur();
                        }
                    }
                    // Don't interfere with any other clicks - let them work normally
                }
            });
        }
        
        // Close modals when clicking outside
        document.addEventListener('click', (e) => {
            if (e.target.classList.contains('modal')) {
                e.target.classList.add('hidden');
            }
        });
        
        // File input event listener
        document.getElementById('file-input').addEventListener('change', (e) => {
            if (e.target.files.length > 0) {
                chatClient.handleFileSelection(e.target.files);
            }
        });

        // Add keyboard shortcut to manually clean up system messages (Ctrl/Cmd + K)
        document.addEventListener('keydown', (e) => {
            if ((e.ctrlKey || e.metaKey) && e.key === 'k') {
                e.preventDefault();
                if (chatClient) {
                    console.log('Manual system message cleanup triggered');
                    chatClient.cleanupSystemMessages();
                }
            }
        });

        // Note: Create room button already exists in HTML - no need to create duplicate
        
        // Trigger mobile emoji sequence on page load after DOM is ready
        if (window.innerWidth <= 768) {
            setTimeout(function() {
                onMobileEmojiSequence();
            }, 500);
        }
    });

    // After the ChatClient class definition, add:
    window.removeRoom = function() { chatClient.removeRoom(); };

    // Global function to clean up system messages
    window.cleanupMessages = function() {
        if (chatClient) {
            console.log('Manual cleanup triggered from global function');
            chatClient.cleanupSystemMessages();
        } else {
            console.log('Chat client not available yet');
        }
    };
    
    // ===== STANDALONE LOGIN FUNCTIONS (Moved from HTML) =====
    
    // Mobile emoji interaction sequence  
    function onMobileEmojiSequence() {
        if (window.innerWidth > 768) return;
        
        setTimeout(function() { 
            const emojiOption = document.querySelector('.emoji-option');
            if (emojiOption) emojiOption.dispatchEvent(new Event('click'));
        }, 10);
        
        setTimeout(function() { 
            const selectedEmoji = document.getElementById('selected-emoji');
            if (selectedEmoji) selectedEmoji.focus();
        }, 20);
        
        setTimeout(function() { 
            document.activeElement.blur();
        }, 30);
        
        setTimeout(function() { 
            const selectedEmoji = document.getElementById('selected-emoji');
            if (selectedEmoji) selectedEmoji.style.transform = 'scale(1.1)';
        }, 40);
        
        setTimeout(function() { 
            const selectedEmoji = document.getElementById('selected-emoji');
            if (selectedEmoji) selectedEmoji.style.transform = 'scale(1.0)';
        }, 50);
        
        setTimeout(function() { 
            document.body.style.pointerEvents = 'auto';
        }, 60);
    }

    // WebAuthn Implementation
    async function registerWebAuthn() {
        // Prevent multiple concurrent operations
        if (window.webauthnInProgress) {
            console.log('WebAuthn operation already in progress, ignoring duplicate click');
            return;
        }
        window.webauthnInProgress = true;
        
        const username = document.getElementById('nickname-input').value;
        
        try {
            if (!username) {
                showLoginStatus('❌ Enter username first', 'error');
                return;
            }

            // Check username availability first
            try {
                showLoginStatus('Checking username...', 'info');
                
                const checkResponse = await fetch('/webauthn/username/check', {
                    method: 'POST',
                    headers: { 'Content-Type': 'application/json' },
                    body: JSON.stringify({ username })
                });
                const checkResult = await checkResponse.json();
                if (!checkResult.available) {
                    showLoginStatus('❌ Username taken', 'error');
                    return;
                }
            } catch (err) {
                showLoginStatus('❌ Username check failed', 'error');
                return;
            }

            try {
                showLoginStatus('Preparing registration...', 'info');
                
                // Get registration options from server
                const response = await fetch('/webauthn/register/begin', {
                    method: 'POST',
                    headers: { 'Content-Type': 'application/json' },
                    body: JSON.stringify({ username })
                });
                
                if (!response.ok) throw new Error('Registration failed');
                
                const options = await response.json();
                
                if (!options.publicKey || !options.publicKey.challenge) {
                    showLoginStatus('❌ Server error', 'error');
                    return;
                }
                
                showLoginStatus('Create your passkey', 'info');
                
                // Convert base64 strings to ArrayBuffer
                options.publicKey.challenge = base64ToArrayBuffer(options.publicKey.challenge);
                options.publicKey.user.id = base64ToArrayBuffer(options.publicKey.user.id);
                
                // Create credentials
                const credential = await navigator.credentials.create(options);
                
                showLoginStatus('Verifying...', 'info');
                
                // Convert ArrayBuffer to base64
                const attestationObject = arrayBufferToBase64(credential.response.attestationObject);
                const clientDataJSON = arrayBufferToBase64(credential.response.clientDataJSON);
                
                // Send registration data to server
                const verificationResponse = await fetch('/webauthn/register/complete', {
                    method: 'POST',
                    headers: { 'Content-Type': 'application/json' },
                    body: JSON.stringify({
                        id: arrayBufferToBase64(credential.rawId),
                        rawId: arrayBufferToBase64(credential.rawId),
                        response: {
                            attestationObject,
                            clientDataJSON
                        },
                        type: credential.type,
                        username,
                        emoji: window.currentEmoji || '👤'
                    })
                });
                
                if (!verificationResponse.ok) throw new Error('Registration verification failed');
                
                showLoginStatus('✅ Registration Success', 'success');
                
            } catch (error) {
                console.error('WebAuthn registration error:', error);
                showLoginStatus('❌ Registration failed', 'error');
            } finally {
                // Reset state without disabling buttons
                window.webauthnInProgress = false;
            }
        } finally {
            window.webauthnInProgress = false;
        }
    }

    async function loginWithWebAuthn() {
        // Prevent multiple concurrent operations
        if (window.webauthnInProgress) {
            console.log('WebAuthn operation already in progress, ignoring duplicate click');
            return;
        }
        window.webauthnInProgress = true;
        
        const usernameInput = document.getElementById('nickname-input');
        
        let username = usernameInput.value.trim();
        if (username === '') {
            username = null;
        }
        
        try {
            showLoginStatus('Preparing login...', 'info');
            
            const optionsResponse = await fetch('/webauthn/authenticate/begin', {
                method: 'POST',
                headers: { 'Content-Type': 'application/json' },
                body: JSON.stringify({ username: username })
            });
            
            if (!optionsResponse.ok) {
                throw new Error('Failed to get authentication options');
            }
            
            const options = await optionsResponse.json();
            
            if (!options.publicKey || !options.publicKey.challenge) {
                showLoginStatus('❌ Server error', 'error');
                return;
            }
            
            showLoginStatus('Authenticate', 'info');
            
            // Convert challenge to ArrayBuffer
            options.publicKey.challenge = base64ToArrayBuffer(options.publicKey.challenge);
            // Convert each allowCredentials id to ArrayBuffer
            if (options.publicKey.allowCredentials) {
                options.publicKey.allowCredentials = options.publicKey.allowCredentials.map(cred => ({
                    ...cred,
                    id: base64ToArrayBuffer(cred.id)
                }));
            }
            
            const assertion = await navigator.credentials.get({ publicKey: options.publicKey });
            
            if (!assertion) {
                throw new Error('User cancelled');
            }
            
            showLoginStatus('Verifying...', 'info');
            
            const credential = {
                id: assertion.id,
                rawId: arrayBufferToBase64(assertion.rawId),
                type: assertion.type,
                response: {
                    clientDataJSON: arrayBufferToBase64(assertion.response.clientDataJSON),
                    authenticatorData: arrayBufferToBase64(assertion.response.authenticatorData),
                    signature: arrayBufferToBase64(assertion.response.signature),
                    userHandle: assertion.response.userHandle ? arrayBufferToBase64(assertion.response.userHandle) : null
                },
                username: username || ''
            };
            
            const verifyResponse = await fetch('/webauthn/authenticate/complete', {
                method: 'POST',
                headers: { 'Content-Type': 'application/json' },
                body: JSON.stringify(credential)
            });
            
            const result = await verifyResponse.json();
            
            if (result.success) {
                if (!usernameInput.value && result.username) {
                    usernameInput.value = result.username;
                }
                showLoginStatus('✅ Login Success', 'success');
                
                // Join the chat after successful authentication
                setTimeout(() => {
                    joinChat();
                }, 1000);
            } else {
                showLoginStatus('❌ Login failed', 'error');
            }
            
        } catch (error) {
            console.error('WebAuthn authentication error:', error);
            
            // Handle specific error cases
            if (error.message === 'User cancelled' || 
                error.name === 'NotAllowedError' ||
                error.message.includes('cancelled') ||
                error.message.includes('abort')) {
                showLoginStatus('❌ User cancelled', 'error');
            } else {
                showLoginStatus('❌ Authentication failed', 'error');
            }
        } finally {
            // Reset state without disabling buttons
            window.webauthnInProgress = false;
        }
    }

    // Utility functions for ArrayBuffer conversion
    function base64ToArrayBuffer(base64) {
        const binaryString = window.atob(base64);
        const bytes = new Uint8Array(binaryString.length);
        for (let i = 0; i < binaryString.length; i++) {
            bytes[i] = binaryString.charCodeAt(i);
        }
        return bytes.buffer;
    }

    function arrayBufferToBase64(buffer) {
        const bytes = new Uint8Array(buffer);
        let binary = '';
        for (let i = 0; i < bytes.byteLength; i++) {
            binary += String.fromCharCode(bytes[i]);
        }
        return window.btoa(binary);
    }

    // Status message functions
    function showLoginStatus(message, type = 'info') {
        console.log(`[LoginStatus] ${type.toUpperCase()}: ${message}`);
        const statusEl = document.getElementById('login-status');
        
        // Force clear ALL existing timeouts to prevent accumulation
        if (window.statusTimeout) {
            clearTimeout(window.statusTimeout);
            window.statusTimeout = null;
        }
        if (window.statusFadeTimeout) {
            clearTimeout(window.statusFadeTimeout);
            window.statusFadeTimeout = null;
        }
        
        // Immediately set clean state without calling clearLoginStatus
        statusEl.classList.remove('fading');
        statusEl.textContent = message;
        statusEl.className = `status-message ${type}`;
        statusEl.style.display = 'block';
        
        // Auto-hide after 3 seconds with fade - use separate timeout variables
        window.statusTimeout = setTimeout(() => {
            statusEl.classList.add('fading');
            window.statusFadeTimeout = setTimeout(() => {
                statusEl.style.display = 'none';
                statusEl.classList.remove('fading');
                window.statusTimeout = null;
                window.statusFadeTimeout = null;
            }, 100); // Reduced from 300ms to 100ms (3x faster)
        }, 3000); // Reduced from 10000ms to 3000ms
        
        // Scroll status message into view on mobile - remove delay for responsiveness
        if (window.innerWidth <= 768) {
            statusEl.scrollIntoView({ 
                behavior: 'smooth', 
                block: 'nearest',
                inline: 'nearest'
            });
        }
    }

    function clearLoginStatus() {
        const statusEl = document.getElementById('login-status');
        
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
        statusEl.className = 'status-message';
        statusEl.textContent = '';
        statusEl.style.display = 'none';
    }

    function setButtonState(registerBtn, loginBtn, disabled, registerText, loginText) {
        registerBtn.disabled = disabled;
        loginBtn.disabled = disabled;
        registerBtn.textContent = registerText;
        loginBtn.textContent = loginText;
    }

    // Standalone emoji color analysis for when chatClient isn't available
    async function analyzeEmojiColorsStandalone(emoji) {
        try {
            const response = await fetch('/emoji/analyze', {
                method: 'POST',
                headers: { 'Content-Type': 'application/json' },
                body: JSON.stringify({ emoji })
            });
            
            if (response.ok) {
                const result = await response.json();
                if (result.success) {
                    // Apply the contrasting background color to emoji elements
                    applyEmojiStylingStandalone(emoji, result.contrastColor, result.textColor);
                    
                    // Save colors to localStorage for this emoji
                    localStorage.setItem(`emojiColors_${emoji}`, JSON.stringify({
                        contrastColor: result.contrastColor,
                        textColor: result.textColor
                    }));
                }
            }
        } catch (error) {
            console.log('Standalone emoji color analysis failed:', error);
            // Fallback to default styling
            applyEmojiStylingStandalone(emoji, '#f0f0f0', '#000000');
        }
    }
    
    function applyEmojiStylingStandalone(emoji, backgroundColor, textColor) {
        // Apply styling to selected emoji in login form
        const selectedEmoji = document.getElementById('selected-emoji');
        if (selectedEmoji && selectedEmoji.textContent === emoji) {
            selectedEmoji.style.backgroundColor = backgroundColor;
            selectedEmoji.style.color = textColor;
            selectedEmoji.style.border = `3px solid ${adjustColorBrightnessStandalone(backgroundColor, 30)}`;
        }
        
        // Apply styling to user emoji picker modal
        const selectedUserEmoji = document.getElementById('selected-user-emoji');
        if (selectedUserEmoji && selectedUserEmoji.textContent === emoji) {
            selectedUserEmoji.style.backgroundColor = backgroundColor;
            selectedUserEmoji.style.color = textColor;
            selectedUserEmoji.style.border = `3px solid ${adjustColorBrightnessStandalone(backgroundColor, 30)}`;
        }
    }
    
    // Helper function for standalone color adjustment
    function adjustColorBrightnessStandalone(hex, percent) {
        // Remove the hash if it exists
        hex = hex.replace('#', '');
        
        // Parse r, g, b values
        const r = parseInt(hex.substr(0, 2), 16);
        const g = parseInt(hex.substr(2, 2), 16);
        const b = parseInt(hex.substr(4, 2), 16);
        
        // Calculate new values
        const newR = Math.max(0, Math.min(255, r + percent));
        const newG = Math.max(0, Math.min(255, g + percent));
        const newB = Math.max(0, Math.min(255, b + percent));
        
        // Convert back to hex
        return `#${newR.toString(16).padStart(2, '0')}${newG.toString(16).padStart(2, '0')}${newB.toString(16).padStart(2, '0')}`;
    }

    // Emoji picker functions
    function selectEmoji(emoji) {
        // Remove selection from all emoji options
        document.querySelectorAll('.emoji-option').forEach(option => {
            option.classList.remove('selected');
        });
        
        // Add selection to clicked emoji
        event.target.classList.add('selected');
        
        // Update selected emoji display
        const selectedEmojiDisplay = document.getElementById('selected-emoji');
        if (selectedEmojiDisplay) {
            selectedEmojiDisplay.textContent = emoji;
        }
        
        // Update user avatar immediately
        const userAvatar = document.querySelector('.user-avatar');
        if (userAvatar) {
            userAvatar.textContent = emoji;
        }
        
        // Store the selected emoji
        window.currentEmoji = emoji;
        
        // Save to localStorage for current user
        const inputElement = document.getElementById('nickname-input');
        if (inputElement && inputElement.value.trim()) {
            localStorage.setItem(`userEmoji_${inputElement.value.trim()}`, emoji);
        }
        
        console.log('🎭 Selected emoji:', emoji);
    }
    
    function toggleEmojiPicker() {
        const emojiPicker = document.getElementById('emoji-picker');
        if (emojiPicker) {
            emojiPicker.classList.toggle('hidden');
        }
    }

    // Initialize page when DOM is loaded
    document.addEventListener('DOMContentLoaded', function() {
        document.querySelectorAll('#rp-id').forEach(function(el) {
            el.textContent = window.location.hostname;
        });
        
        // Reset all global state to prevent accumulation
        window.statusTimeout = null;
        window.statusFadeTimeout = null;
        window.webauthnInProgress = false;
        
        // Clear any status message on page load
        clearLoginStatus();
        
        // Load saved username from localStorage
        const savedUsername = localStorage.getItem('lastUsername');
        const usernameInput = document.getElementById('nickname-input');
        if (savedUsername && usernameInput) {
            usernameInput.value = savedUsername;
            usernameInput.blur();
        }
        
        // Load saved emoji for the current user from localStorage
        const savedEmoji = savedUsername ? localStorage.getItem(`userEmoji_${savedUsername}`) : null;
        if (savedEmoji) {
            // Set the emoji in the picker
            const selectedEmojiElement = document.getElementById('selected-emoji');
            if (selectedEmojiElement) {
                selectedEmojiElement.textContent = savedEmoji;
            }
            
            // Update emoji picker selection
            document.querySelectorAll('.emoji-option').forEach(option => {
                option.classList.remove('selected');
                if (option.textContent === savedEmoji) {
                    option.classList.add('selected');
                }
            });
            
            window.currentEmoji = savedEmoji;
            
            // Apply saved emoji styling
            analyzeEmojiColorsStandalone(savedEmoji);
        } else {
            window.currentEmoji = '👤'; // Default emoji
            // Apply default emoji styling
            analyzeEmojiColorsStandalone('👤');
        }

        // Emoji picker setup
        const selectedEmoji = document.getElementById('selected-emoji');
        const emojiOptions = document.querySelectorAll('.emoji-option');
        
        // Load saved emoji for the current user from localStorage or use default
        let currentEmoji = savedEmoji || '👤';

        // Set initial selected emoji
        if (selectedEmoji) selectedEmoji.textContent = currentEmoji;
        
        // Update emoji picker selection based on saved emoji
        emojiOptions.forEach((option, index) => {
            option.classList.remove('selected');
            if (option.textContent === currentEmoji) {
                option.classList.add('selected');
            } else if (index === 0 && !savedEmoji) {
                // Select first option only if no saved emoji
                option.classList.add('selected');
            }
        });
        
        // Apply emoji styling
        analyzeEmojiColorsStandalone(currentEmoji);

        emojiOptions.forEach(option => {
            option.addEventListener('click', () => {
                // Remove selected class from all options
                emojiOptions.forEach(opt => opt.classList.remove('selected'));
                
                // Add selected class to clicked option
                option.classList.add('selected');
                
                // Update selected emoji
                currentEmoji = option.textContent;
                if (selectedEmoji) selectedEmoji.textContent = currentEmoji;
                
                // Save to localStorage for current user
                const currentUsername = document.getElementById('nickname-input').value.trim();
                if (currentUsername) {
                    localStorage.setItem(`userEmoji_${currentUsername}`, currentEmoji);
                }
                window.currentEmoji = currentEmoji;
                
                // Analyze emoji colors for styling
                if (chatClient) {
                    chatClient.loadEmojiStyling(currentEmoji);
                } else {
                    // If chatClient doesn't exist yet, just analyze directly
                    analyzeEmojiColorsStandalone(currentEmoji);
                }
            });
        });

        // Username input blur handler
        if (usernameInput) {
            usernameInput.addEventListener('blur', function() {
                const username = this.value.trim();
                if (username) {
                    const userEmoji = localStorage.getItem(`userEmoji_${username}`);
                    if (userEmoji) {
                        // Update the emoji display
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
                        currentEmoji = userEmoji;
                    }
                }
            });
        }
        
        // Trigger mobile emoji sequence on page load after DOM is ready
        if (window.innerWidth <= 768) {
            setTimeout(function() {
                onMobileEmojiSequence();
            }, 500);
        }
    });

    // Override joinChat to use the updated version
    window.joinChat = function() {
        const inputElement = document.getElementById('nickname-input');
        const username = inputElement.value.trim();
        
        if (!username) {
            alert('Please enter a username');
            return;
        }
        
        // Save username and emoji to localStorage
        localStorage.setItem('lastUsername', username);
        const currentEmoji = window.currentEmoji || '👤';
        localStorage.setItem(`userEmoji_${username}`, currentEmoji);
        
        chatClient.username = username;
        chatClient.userEmoji = currentEmoji;
        document.getElementById('current-username').textContent = username;
        document.querySelector('.user-avatar').textContent = currentEmoji;
        
        // Switch to chat screen
        document.getElementById('login-screen').classList.add('hidden');
        document.getElementById('chat-screen').classList.remove('hidden');
        
        // Connect to server
        chatClient.connect();
    };

    function logout() {
        // Return to login screen, restore saved values
        document.getElementById('chat-screen').classList.add('hidden');
        document.getElementById('login-screen').classList.remove('hidden');
        
        // Restore saved username and emoji from localStorage
        const savedUsername = localStorage.getItem('lastUsername');
        const savedEmoji = savedUsername ? localStorage.getItem(`userEmoji_${savedUsername}`) : null;
        
        const inputElement = document.getElementById('nickname-input');
        const selectedEmojiElement = document.getElementById('selected-emoji');
        
        // Restore username
        if (savedUsername && inputElement) {
            inputElement.value = savedUsername;
            inputElement.blur();
        }
        
        // Restore emoji
        if (savedEmoji && selectedEmojiElement) {
            selectedEmojiElement.textContent = savedEmoji;
            window.currentEmoji = savedEmoji;
            
            // Update emoji picker selection
            document.querySelectorAll('.emoji-option').forEach(option => {
                option.classList.remove('selected');
                if (option.textContent === savedEmoji) {
                    option.classList.add('selected');
                }
            });
            
            // Apply emoji styling
            analyzeEmojiColorsStandalone(savedEmoji);
        } else {
            // Use defaults if no saved values
            if (selectedEmojiElement) {
                selectedEmojiElement.textContent = '👤';
            }
            window.currentEmoji = '👤';
            
            // Apply default emoji styling
            analyzeEmojiColorsStandalone('👤');
        }
        
        // Focus and select username input
        if (inputElement) {
            //inputElement.focus();
            if (savedUsername) {
                //inputElement.select();
            }
            inputElement.blur();
        }
        
        // Disconnect WebSocket if needed
        if (window.chatClient && window.chatClient.ws) {
            window.chatClient.ws.close();
        }
    }
    
    // User emoji picker functions
    function showUserEmojiPicker() {
        const modal = document.getElementById('user-emoji-picker-modal');
        if (modal) {
            // Get current user emoji
            const currentEmoji = chatClient?.userEmoji || window.currentEmoji || '👤';
            
            // Update the large emoji display
            const selectedEmojiDisplay = document.getElementById('selected-user-emoji');
            if (selectedEmojiDisplay) {
                selectedEmojiDisplay.textContent = currentEmoji;
            }
            
            // Clear previous selections and select current emoji
            modal.querySelectorAll('.emoji-option').forEach(option => {
                option.classList.remove('selected');
                if (option.textContent === currentEmoji) {
                    option.classList.add('selected');
                }
            });
            
            // Apply color styling to the displayed emoji
            if (chatClient) {
                chatClient.loadEmojiStyling(currentEmoji);
            } else {
                // Fallback for when chatClient doesn't exist yet
                analyzeEmojiColorsStandalone(currentEmoji);
            }
            
            modal.classList.remove('hidden');
        }
    }
    
    function hideUserEmojiPicker() {
        const modal = document.getElementById('user-emoji-picker-modal');
        if (modal) {
            modal.classList.add('hidden');
        }
    }
    
    function changeUserEmoji(emoji) {
        // Update the large emoji display immediately
        const selectedEmojiDisplay = document.getElementById('selected-user-emoji');
        if (selectedEmojiDisplay) {
            selectedEmojiDisplay.textContent = emoji;
        }
        
        // Update visual selection in the grid
        document.querySelectorAll('#user-emoji-picker-modal .emoji-option').forEach(option => {
            option.classList.remove('selected');
            if (option.textContent === emoji) {
                option.classList.add('selected');
            }
        });
        
        // Update locally immediately
        if (chatClient) {
            chatClient.userEmoji = emoji;
            chatClient.updateEmojiDisplay(emoji);
            
            // Send update to server
            chatClient.updateUserEmoji(emoji);
            
            // Save to localStorage for current user
            if (chatClient.username) {
                localStorage.setItem(`userEmoji_${chatClient.username}`, emoji);
            }
            
            // Analyze emoji colors for styling
            chatClient.loadEmojiStyling(emoji);
        }
        
        window.currentEmoji = emoji;
        
        console.log('🎭 Changed emoji to:', emoji);
        
        // Don't hide the picker immediately - let user see the change
        // They can click Close when done
    }
    """
}
