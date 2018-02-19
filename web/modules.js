var caisson = (function() {
    var popup_div = document.getElementById('caisson') || null;
    if (!popup_div) {
        console.log("La div d'id 'caisson' n'existe pas")
    }
    return {
        add_content: function(content) {
            popup_div.style.display = 'block';
            popup_div.innerHTML = content || ''
        },
        remove: function() {
            if (popup_div.style.display == 'block') {
                popup_div.style.display = 'none'
            }
        }
    }
}());
