//  RandomNumberTimer.js
//  Created by Svyatoslav Popov on 03.02.2024.

document.addEventListener("DOMContentLoaded", function() {

    function UpdateElement() {
        document.getElementById('randomInt').innerText = 1 + Math.floor(Math.random() * 99)
    }

    UpdateElement()
    
    setInterval(UpdateElement, 2000);
});
