/* =================================
   SehatSetu - JavaScript
   Persistent Hindi / English
================================= */

// Get saved language, otherwise use English
let currentLanguage = localStorage.getItem("sehatSetuLanguage") || "en";

// Apply language to the current page
function updateLanguage() {
    document.documentElement.lang = currentLanguage;

    // Update all translated text
    const elements = document.querySelectorAll("[data-en][data-hi]");

    elements.forEach(function (element) {
        const text = element.getAttribute("data-" + currentLanguage);

        if (text !== null) {
            element.textContent = text;
        }
    });

    // Update input placeholders
    const placeholderElements = document.querySelectorAll(
        "[data-placeholder-en], [data-placeholder-hi]"
    );

    placeholderElements.forEach(function (element) {
        const placeholder = element.getAttribute(
            "data-placeholder-" + currentLanguage
        );

        if (placeholder !== null) {
            element.placeholder = placeholder;
        }
    });

    // Update language button
    const languageButton = document.getElementById("languageBtn");

    if (languageButton) {
        languageButton.textContent =
            currentLanguage === "en" ? "हिंदी" : "English";
    }
}

// Toggle language and save the selection


function toggleLanguage() {
    currentLanguage = currentLanguage === "en" ? "hi" : "en";

    localStorage.setItem("sehatSetuLanguage", currentLanguage);

    updateLanguage();

    // Reload database articles in the selected language
    if (typeof loadDatabaseArticles === "function") {
        loadDatabaseArticles();
    }
}

document.addEventListener("DOMContentLoaded", function () {
    updateLanguage();
});