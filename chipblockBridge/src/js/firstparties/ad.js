chrome.runtime.sendMessage({
    type: "social_site_detected",
    url: window.location.hostname
});
