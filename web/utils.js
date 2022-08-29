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

function sendMessageOnVideo(tabId, message, browser_type) {
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
window.getSourceUrlBrowser = async function getSourceUrlBrowser() {
    const tabs = await queryCurrentTab(null, 'browser');
    var url = tabs[0].url
    url = await modifyUrl(url, 'browser');
    return url;
}

window.getSourceUrlChrome = async function getSourceUrlChrome() {
    const tabs = await queryCurrentTab(null, 'chrome');
    var url = tabs[0].url
    url = await modifyUrl(url, 'chrome');
    return url;
}

async function modifyUrl(url, browser_type) {
    const ytRegex = /https:\/\/www.youtube.com\/watch\?v=.+/;
    if (url.match(ytRegex)) {
        const tabs = await queryCurrentTab("https://www.youtube.com/watch?v=*", browser_type)
        if (tabs.length > 0) {
            console.log('youtube tab');
            const timestampData = await sendMessageOnVideo(tabs[0].id, {msg: "obtain-timestamp"}, browser_type);
            console.log(timestampData);
            url = `https://www.youtube.com/watch?v=${timestampData.videoId}&t=${timestampData.timestamp}`
        }
    }
    return url;
}

// youtube utils
// Parse the current page URL for the video ID and returns the ID.
// https://stackoverflow.com/questions/3452546/how-do-i-get-the-youtube-video-id-from-a-url
function getVideoId() {
    if (window.location.search.split('v=')[1] === undefined) {
        return "";
    }
    let videoId = window.location.search.split('v=')[1];
    let ampersandPosition = videoId.indexOf('&');
    // filter out irrevelant query part
    if (ampersandPosition != -1) {
        videoId = videoId.substring(0, ampersandPosition);
    }
    return videoId;
}
