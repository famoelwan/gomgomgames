const statusNode = document.querySelector("#connection-status");
const startButton = document.querySelector("#start-button");

function updateConnectionStatus() {
  if (!statusNode) return;
  statusNode.textContent = navigator.onLine ? "متصل بالإنترنت" : "وضع عدم الاتصال";
  statusNode.dataset.online = String(navigator.onLine);
}

window.addEventListener("online", updateConnectionStatus);
window.addEventListener("offline", updateConnectionStatus);
updateConnectionStatus();

startButton?.addEventListener("click", () => {
  // The playable stage flow will be connected after the authenticated
  // profile, question-delivery API, and server-side scoring are implemented.
  startButton.textContent = "المغامرة قيد التجهيز";
  startButton.disabled = true;
  startButton.setAttribute("aria-live", "polite");
});
