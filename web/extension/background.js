// contextMenu.js
const getIframeUrl = () => chrome.runtime.getURL("web-ext.html");
const onClicked = async (
  { menuItemId, linkUrl, pageUrl, srcUrl, selectionText, checked },
  tab,
) => {
  let content = "";
  let source = "";
  let url = getIframeUrl();
  switch (menuItemId) {
    case "create_new_note":
      url += "?note";
      openPopup(url, true);
      return;
    case "new_window":
      openPopup(url, false);
      return;
    case "save_page":
      source = pageUrl;
      break;
    case "save_link":
      source = linkUrl;
      break;
    case "save_video":
      source = srcUrl;
      break;
    case "save_image":
      source = srcUrl;
      break;
    case "save_highlight":
      content = `${selectionText.trim()}`;
      source = pageUrl;
      break;
    case "use_sidebar":
      await setSidebarStatus(checked);
      return;
  }
  url += `?content=${encodeURIComponent(content)}&source=${
    encodeURIComponent(source)
  }`;
  await onActionPressed(tab, url);
};
const onCommand = (command) => {
  let url = chrome.runtime.getURL("web-ext.html");
  switch (command) {
    case "create-new-note":
      url += "?note";
      openPopup(url, true);
      break;
    case "open-persistent-window":
      openPopup(url, false);
      break;
  }
};

const initContextMenu = async () => {
  //remove all to be sure
  try {
    await chrome.contextMenus.removeAll();
  } catch (e) {}
  const use_sidebar = await getSidebarStatus();

  //create
  await Promise.all([
    chrome.contextMenus.create({
      id: "create_new_note",
      title: "Create new note",
      contexts: ["action", "browser_action"],
    }),
    chrome.contextMenus.create({
      id: "new_window",
      title: "Open persistent window",
      contexts: ["action", "browser_action"],
    }),
    chrome.contextMenus.create({
      id: "save_page",
      title: "Create new note",
      contexts: ["page"],
    }),
    chrome.contextMenus.create({
      id: "save_link",
      title: "Save link",
      contexts: ["link"],
    }),
    chrome.contextMenus.create({
      id: "save_video",
      title: "Save video url",
      contexts: ["video"],
    }),
    chrome.contextMenus.create({
      id: "save_image",
      title: "Save image url",
      contexts: ["image"],
    }),
    chrome.contextMenus.create({
      id: "save_highlight",
      title: "Save highlight",
      contexts: ["selection"],
    }),
    chrome.contextMenus.create({
      id: "use_sidebar",
      title: "Use sidebar (Requires third-party cookies)",
      checked: use_sidebar,
      type: "checkbox",
      contexts: ["action", "browser_action"],
    }),
  ]);
  chrome.contextMenus.onClicked.removeListener(onClicked);
  chrome.contextMenus.onClicked.addListener(onClicked);
};

const initCommands = () => {
  chrome.commands.onCommand.removeListener(onCommand);
  chrome.commands.onCommand.addListener(onCommand);
};

// popup.js
const winIds = new Set();
const openPopup = async (url, closeOnFocusChange = true) => {
  let currWin;
  try {
    currWin = await chrome.windows.getCurrent();
  } catch (e) {}
  const width = 365;
  const height = 400;
  const top = (currWin) ? currWin.top : 0;
  const left = (currWin) ? (currWin.left + currWin.width - width) : 0;
  const win = await chrome.windows.create({
    url: url,
    type: "popup",
    //position
    width,
    height,
    left,
    top,
  });
  win.alwaysOnTop = true;

  //delay autoclose on blur, otherwise buggy on arch linux
  if (closeOnFocusChange) {
    setTimeout(() => {
      winIds.add(win.id);
    }, 100);
  }
};

/* Close all open popups when focused window change */
const onFocusChanged = (id) => {
  for (const close of winIds) {
    if (close != id) {
      chrome.windows.remove(close);
      winIds.delete(close);
    }
  }
};

const initPopup = () => {
  chrome.windows.onFocusChanged.removeListener(onFocusChanged);
  chrome.windows.onFocusChanged.addListener(onFocusChanged);
};

const onActionPressed = async (tab, src) => {
  if (typeof src != "string") {
    src = getIframeUrl();
    try {
      const srcInfo = await chrome.tabs.sendMessage(tab.id, { msg: "get-src" });
      console.log(srcInfo);
      if (srcInfo.source) {
        src += `?source=${encodeURIComponent(srcInfo.source)}`;
        if (srcInfo.source_title) {
          src += `&source_title=${encodeURIComponent(srcInfo.source_title)}`;
        }
        if (srcInfo.source_description) {
          src += `&source_description=${
            encodeURIComponent(srcInfo.source_description)
          }`;
        }
        if (srcInfo.source_image_url) {
          src += `&source_image_url=${
            encodeURIComponent(srcInfo.source_image_url)
          }`;
        }
      }
    } catch (e) {}
  }
  const use_sidebar = await getSidebarStatus();
  if (use_sidebar) {
    chrome.tabs.sendMessage(tab.id, { msg: "toggle-sidebar", src: null });
  } else {
    openPopup(src, true);
  }
};

const initSidebar = () => {
  chrome.action.onClicked.removeListener(onActionPressed);
  chrome.action.onClicked.addListener(onActionPressed);
};

const getSidebarStatus = async () => {
  let res = await chrome.storage.local.get(["use_sidebar"]);
  let use_sidebar = res.use_sidebar;
  if (use_sidebar == null) {
    // set default value of sidebar
    use_sidebar = false;
    await chrome.storage.local.set({ use_sidebar });
  }
  return use_sidebar;
};
const setSidebarStatus = async (use_sidebar) => {
  await chrome.storage.local.set({ use_sidebar });
};

// init
initContextMenu();
initPopup();
initCommands();
initSidebar();

