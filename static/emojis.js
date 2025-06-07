// Emoji data from index.html
const EMOJIS = [
    '👤', '🐶', '🐱', '🐭', '🐹', '🐰', '🦊', '🐻', '🐼', '🐨',
    '🐯', '🦁', '🐸', '🐵', '🙈', '🙉', '🙊', '🐒', '🦍', '🦧',
    '🐕', '🐩', '🐺', '🦝', '🐈', '🐅', '🐆', '🦓', '🦄', '🐴',
    '🐎', '🦌', '🐮', '🐂', '🐃', '🐄', '🐷', '🐖', '🐗', '🐽',
    '🐏', '🐑', '🐐', '🐪', '🐫', '🦒', '🐘', '🦏', '🦛', '🐊',
    '🐢', '🦎', '🐍', '🐲', '🐉', '🦕', '🦖', '🐳', '🐋', '🐬',
    '🦈', '🐟', '🐠', '🐡', '🦀', '🦞', '🦐', '🐙', '🦑', '🦆',
    '🐓', '🐔', '🐣', '🐤', '🐥', '🦅', '🦉', '🦜', '🕊️', '🦢',
    '🦩', '🐧', '🦇', '🐝', '🐛', '🦋', '🐌', '🐞', '🐜', '🦗',
    '🕷️', '🦂'
];

// Function to render emoji grid
function renderEmojiGrid(containerId, onClickHandler = null) {
    const container = document.getElementById(containerId);
    if (!container) return;

    const grid = document.createElement('div');
    grid.className = 'emoji-grid';

    EMOJIS.forEach(emoji => {
        const option = document.createElement('span');
        option.className = 'emoji-option';
        option.textContent = emoji;
        
        if (onClickHandler) {
            option.onclick = () => onClickHandler(emoji);
        }
        
        grid.appendChild(option);
    });

    container.innerHTML = '';
    container.appendChild(grid);
}

// Function to initialize emoji pickers
function initializeEmojiPickers() {
    // Initialize login screen emoji picker
    renderEmojiGrid('login-emoji-grid', (emoji) => {
        const selectedEmoji = document.getElementById('selected-emoji');
        if (selectedEmoji) {
            selectedEmoji.textContent = emoji;
        }
        
        // Update emoji picker selection
        document.querySelectorAll('#login-emoji-grid .emoji-option').forEach(option => {
            option.classList.remove('selected');
            if (option.textContent === emoji) {
                option.classList.add('selected');
            }
        });
        
        window.currentEmoji = emoji;
        
        // Save to localStorage for current user
        const currentUsername = document.getElementById('nickname-input').value.trim();
        if (currentUsername) {
            localStorage.setItem(`userEmoji_${currentUsername}`, emoji);
        }
        
        // Apply emoji styling
        if (window.chatClient) {
            window.chatClient.loadEmojiStyling(emoji);
        } else {
            analyzeEmojiColorsStandalone(emoji);
        }
    });

    // Initialize user emoji picker modal
    renderEmojiGrid('user-emoji-grid', (emoji) => {
        const selectedEmoji = document.getElementById('selected-user-emoji');
        if (selectedEmoji) {
            selectedEmoji.textContent = emoji;
        }
        
        // Update emoji picker selection
        document.querySelectorAll('#user-emoji-grid .emoji-option').forEach(option => {
            option.classList.remove('selected');
            if (option.textContent === emoji) {
                option.classList.add('selected');
            }
        });
        
        if (window.chatClient) {
            window.chatClient.updateUserEmoji(emoji);
        }
    });
}

// Export functions
window.EMOJIS = EMOJIS;
window.renderEmojiGrid = renderEmojiGrid;
window.initializeEmojiPickers = initializeEmojiPickers; 