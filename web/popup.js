// sets iframe src to query parameters
document.addEventListener('DOMContentLoaded', () => {
  function getQueryString(url) {
    try {
      const urlObj = new URL(url);
      return urlObj.search;
    } catch (e) {
      console.error('Invalid URL', e);
      return '';
    }
  }

  async function updateIframeSrc() {
    const iframe = document.getElementById('fleeting-notes-popup-container');
    try {
      // if possible, retrieve src from content script (more info)
      const tab = (await chrome.tabs.query({ active: true }))[0];
      src = await chrome.tabs.sendMessage(tab.id, { msg: "get-src" });
      iframe.src = `web-ext.html${getQueryString(src)}`;
    } catch (e) {
      console.error(e);
    }
  }


  updateIframeSrc();
});
