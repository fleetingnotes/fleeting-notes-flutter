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
  }
  url += `?content=${encodeURIComponent(content)}&source=${
    encodeURIComponent(source)
  }`;
  await openPopup(url, true);
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
  const is_firefox = navigator.userAgent.indexOf("Firefox") > 0;

  //create
  await Promise.all([
    chrome.contextMenus.create({
      id: "create_new_note",
      title: "Create new note",
      contexts: (is_firefox)
        ? ["browser_action"]
        : ["action", "browser_action"],
    }),
    chrome.contextMenus.create({
      id: "new_window",
      title: "Open persistent window",
      contexts: (is_firefox)
        ? ["browser_action"]
        : ["action", "browser_action"],
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
  console.log('open popup');
  let currWin;
  try {
    currWin = await chrome.windows.getCurrent();
  } catch (e) {}
  const width = 500;
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
  chrome.action.setPopup({popup:'popup.html'});
  chrome.windows.onFocusChanged.removeListener(onFocusChanged);
  chrome.windows.onFocusChanged.addListener(onFocusChanged);
};

// init
initContextMenu();
initPopup();
initCommands();
