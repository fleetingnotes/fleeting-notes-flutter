console.log('background.js');
// chrome.windows.create({url: "web-ext.html", type: "popup", height: 500, width: 800, resizeable: false});
chrome.action.onClicked.addListener((tab) => {
    chrome.scripting.insertCSS(
        {
            file: 'styles.css'
        }
    )
    chrome.scripting.executeScript({
        target: { tabId: tab.id },
        files: ['content-script.js', 'styles.css'],
    });
});