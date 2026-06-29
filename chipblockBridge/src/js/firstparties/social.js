document.addEventListener("visibilitychange", () => {
  if (!document.hidden) {
    chrome.runtime.sendMessage({ type: "onSocialSite" });
  }
});

if (!document.hidden) {
  chrome.runtime.sendMessage({ type: "onSocialSite" });
}
