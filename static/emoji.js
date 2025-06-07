// Emoji Data for XCF Chat
// Contains all available emojis for user avatars

const EMOJI_DATA = [
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

// Function to populate emoji grid containers
function populateEmojiGrid(containerSelector, onClickHandler = null) {
    const container = document.querySelector(containerSelector);
    if (!container) return;
    
    // Clear existing content
    container.innerHTML = '';
    
    // Add each emoji
    EMOJI_DATA.forEach(emoji => {
        const span = document.createElement('span');
        span.className = 'emoji-option';
        span.textContent = emoji;
        
        if (onClickHandler) {
            span.onclick = () => onClickHandler(emoji);
        }
        
        container.appendChild(span);
    });
}

// Initialize emoji grids when DOM is loaded
document.addEventListener('DOMContentLoaded', function() {
    // Populate login screen emoji picker
    populateEmojiGrid('.login-form .emoji-grid', function(emoji) {
        // Handle emoji selection for login
        selectEmoji(emoji);
    });
    
    // Populate user emoji picker modal
    populateEmojiGrid('#user-emoji-picker-modal .emoji-grid', function(emoji) {
        // Handle emoji change for user
        changeUserEmoji(emoji);
    });
});

// Export for use in other modules
if (typeof window !== 'undefined') {
    window.EMOJI_DATA = EMOJI_DATA;
    window.populateEmojiGrid = populateEmojiGrid;
} 