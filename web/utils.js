// Obtains the chrome tab object for the current tab and execute callback with it.
// If url supplied, then tab object will only be passed on to callback if it matches
// the url.
async function queryCurrentTab(url=null, browser_type="chrome") {
    let matchConditions = {active: true, currentWindow: true}
    if (url !== null) {
        matchConditions.url = url
    }
    if (browser_type == "chrome") {
        return await chrome.tabs.query(matchConditions);
    } else {
        return await browser.tabs.query(matchConditions);
    }
}

function sendMessage(tabId, message, browser_type) {
    return new Promise((resolve) => {
        if (browser_type == "chrome") {
            chrome.tabs.sendMessage(
                tabId, message,
                (response) => {
                    resolve(response);
                }
            );
        } else {
            browser.tabs.sendMessage(
                tabId, message,
                (response) => {
                    resolve(response);
                }
            );
        }
    });
}

// functions exposed to dart
window.getSourceUrl = async function getSourceUrl(browser_type) {
    const tabs = await queryCurrentTab(null, browser_type);
    const url = await sendMessage(tabs[0].id, { msg: "get-src" }, browser_type);
    return url;
}

window.getSelectionText = async (browser_type) => {
    const tabs = await queryCurrentTab(null, browser_type);
    const selectionText = await sendMessage(tabs[0].id, { msg: "get-selection-text" }, browser_type);
    return selectionText.trim();
};

async function modifyUrl(url, browser_type) {
    const ytRegex = /https:\/\/www.youtube.com\/watch\?v=.+/;
    if (url.match(ytRegex)) {
        const tabs = await queryCurrentTab("https://www.youtube.com/watch?v=*", browser_type)
        if (tabs.length > 0) {
            const timestampData = await sendMessage(tabs[0].id, {msg: "obtain-timestamp"}, browser_type);
            url = `https://www.youtube.com/watch?v=${timestampData.videoId}&t=${timestampData.timestamp}`
        }
    }
    return url;
}

const pasteHandler = function (e) {
  var items;

  if (e.clipboardData && e.clipboardData.items) {
    items = e.clipboardData.items;

    if (items) {
      items = Array.prototype.filter.call(items, function (element) {
        return element.type.indexOf("image") >= 0;
      });

      Array.prototype.forEach.call(items, function (item) {
        var blob = item.getAsFile();

        var rdr = new FileReader();
        rdr.onloadend = function () {
          window.postMessage(new Uint8Array(rdr.result));
        };

        rdr.readAsArrayBuffer(blob);
      });
    }
  }
};

window.addEventListener('paste', pasteHandler);
