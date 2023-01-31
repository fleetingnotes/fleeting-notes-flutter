// contextMenu.js
const onClicked = async({ menuItemId, linkUrl, pageUrl, srcUrl, selectionText }, tab) => {
    let content = '';
    let source = '';
    let url = browser.runtime.getURL("web-ext.html");
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
    browser.tabs.sendMessage(tab.id, { msg: "toggle-sidebar", src: url });
}
const onCommand = (command) => {
  switch (command) {
    case "open-persistent-window":
      const url = browser.runtime.getURL("web-ext.html");
      open(url, false);
      break;
  }
}

const initContextMenu = async () => {
    //remove all to be sure
    try{
        await browser.contextMenus.removeAll()
    } catch (e) {}

    //create
    await Promise.all([
        browser.contextMenus.create({
            id: 'new_window',
            title: 'Open persistent window',
            contexts: ['page']
        }),
        browser.contextMenus.create({
            id: 'save_page',
            title: 'Create new note',
            contexts: ['page']
        }),
        browser.contextMenus.create({
            id: 'save_link',
            title: 'Save link',
            contexts: ['link']
        }),
        browser.contextMenus.create({
            id: 'save_video',
            title: 'Save video url',
            contexts: ['video']
        }),
        browser.contextMenus.create({
            id: 'save_image',
            title: 'Save image url',
            contexts: ['image']
        }),
        browser.contextMenus.create({
            id: 'save_highlight',
            title: 'Save highlight',
            contexts: ['selection']
        })
    ]);
    browser.contextMenus.onClicked.removeListener(onClicked);
    browser.contextMenus.onClicked.addListener(onClicked);
}

const initCommands = () => {
  browser.commands.onCommand.removeListener(onCommand);
  browser.commands.onCommand.addListener(onCommand);
}

// popup.js
const winIds = new Set()
const open = async (url, closeOnFocusChange = true) => {
    const width = 800;
    const height = 500;
    const { id } = await browser.windows.create({
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
            browser.windows.remove(close)
            winIds.delete(close)
        }
}

const initPopup = () => {
    browser.windows.onFocusChanged.removeListener(onFocusChanged);
    browser.windows.onFocusChanged.addListener(onFocusChanged);
}

const onActionPressed = (tab) => {
  browser.tabs.sendMessage(tab.id, { msg: "toggle-sidebar" });
}

const initSidebar = () => {
  browser.browserAction.onClicked.removeListener(onActionPressed);
  browser.browserAction.onClicked.addListener(onActionPressed);
}

// init
initContextMenu();
initPopup();
initCommands();
initSidebar();