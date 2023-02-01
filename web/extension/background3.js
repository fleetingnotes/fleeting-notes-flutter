// contextMenu.js
const onClicked = async({ menuItemId, linkUrl, pageUrl, srcUrl, selectionText }, tab) => {
    let content = '';
    let source = '';
    let url = chrome.runtime.getURL("web-ext.html");
    switch(menuItemId) {
        case 'new_window':
            open(url, false);
            return;
        case 'save_page':
            source = pageUrl;
            break;
        case 'save_link':
            source = linkUrl;
            break;
        case 'save_video':
            source = srcUrl;
            break;
        case 'save_image':
            source = srcUrl;
            break;
        case 'save_highlight':
            content = `${selectionText.trim()}`;
            source = pageUrl;
            break;
    }
    url += `?content=${encodeURIComponent(content)}&source=${encodeURIComponent(source)}`;
    chrome.tabs.sendMessage(tab.id, { msg: "toggle-sidebar", src: url });
}
const onCommand = (command) => {
  switch (command) {
    case "open-persistent-window":
      const url = chrome.runtime.getURL("web-ext.html");
      open(url, false);
      break;
  }
}

const initContextMenu = async () => {
    //remove all to be sure
    try{
        await chrome.contextMenus.removeAll()
    } catch (e) {}

    //create
    await Promise.all([
        chrome.contextMenus.create({
            id: 'new_window',
            title: 'Open persistent window',
            contexts: ['page']
        }),
        chrome.contextMenus.create({
            id: 'save_page',
            title: 'Create new note',
            contexts: ['page']
        }),
        chrome.contextMenus.create({
            id: 'save_link',
            title: 'Save link',
            contexts: ['link']
        }),
        chrome.contextMenus.create({
            id: 'save_video',
            title: 'Save video url',
            contexts: ['video']
        }),
        chrome.contextMenus.create({
            id: 'save_image',
            title: 'Save image url',
            contexts: ['image']
        }),
        chrome.contextMenus.create({
            id: 'save_highlight',
            title: 'Save highlight',
            contexts: ['selection']
        })
    ]);
    chrome.contextMenus.onClicked.removeListener(onClicked);
    chrome.contextMenus.onClicked.addListener(onClicked);
}

const initCommands = () => {
  chrome.commands.onCommand.removeListener(onCommand);
  chrome.commands.onCommand.addListener(onCommand);
}

// popup.js
const winIds = new Set()
const open = async (url, closeOnFocusChange = true) => {
    const width = 800;
    const height = 500;
    const { id } = await chrome.windows.create({
        url: url,
        type: 'popup',
        //position
        width,
        height,
    });
    
    //delay autoclose on blur, otherwise buggy on arch linux
    if (closeOnFocusChange) {
        setTimeout(() => { winIds.add(id) }, 100)
    }
}

/* Close all open popups when focused window change */
const onFocusChanged = (id) => {
    for(const close of winIds)
        if (close != id) {
            chrome.windows.remove(close)
            winIds.delete(close)
        }
}

const initPopup = () => {
    chrome.windows.onFocusChanged.removeListener(onFocusChanged);
    chrome.windows.onFocusChanged.addListener(onFocusChanged);
}

const onActionPressed = (tab) => {
  chrome.tabs.sendMessage(tab.id, { msg: "toggle-sidebar" });
}

const initSidebar = () => {
  chrome.action.onClicked.removeListener(onActionPressed);
  chrome.action.onClicked.addListener(onActionPressed);
}

// init
initContextMenu();
initPopup();
initCommands();
initSidebar();