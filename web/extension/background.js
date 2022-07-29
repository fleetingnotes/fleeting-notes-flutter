// chrome.contextMenus.create({
//     "title": title,
// })

chrome.windows.create({
    url: `${chrome.runtime.getURL("web-ext.html")}?note=1b11a080-f7a4-11ec-a56d-898084d86b15`,
    type: "popup",
    width: 800,
    height: 500,
});