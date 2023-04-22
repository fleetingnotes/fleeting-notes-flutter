// Parse the current page URL for the video ID and returns the ID.
// https://stackoverflow.com/questions/3452546/how-do-i-get-the-youtube-video-id-from-a-url
function getVideoId() {
  if (window.location.search.split("v=")[1] === undefined) {
    return "";
  }
  let videoId = window.location.search.split("v=")[1];
  let ampersandPosition = videoId.indexOf("&");
  // filter out irrevelant query part
  if (ampersandPosition != -1) {
    videoId = videoId.substring(0, ampersandPosition);
  }
  return videoId;
}

// Obtain all relevant info for the timestamp and returns it.
function getCurrentTimestampInfo() {
  const time = document.getElementsByTagName("video")[0].currentTime;
  const videoId = getVideoId();
  // obtain title by scraping webpage
  const title = document.getElementsByClassName(
    "title style-scope ytd-video-primary-info-renderer",
  )[0].firstChild.innerText;

  return {
    timestamp: Math.floor(time),
    videoId,
    title,
  };
}

// sidebar logic
let sidebarWidth = parseInt(window.localStorage.getItem("sidebarWidth")) || 365;
let sidebarHeight = parseInt(window.localStorage.getItem("sidebarHeight")) ||
  400;
let rootElement;
let sidebar;
let closeBtn;
let resizer;
let startX, startY, startWidth, startHeight;
const createSidebar = () => {
  rootElement = document.createElement("div");
  // remove potential global styles
  rootElement.style.setProperty("all", "initial");

  const className = "sidebar";
  const rootShadow = rootElement.attachShadow({ mode: "closed" });
  const url = `${chrome.runtime.getURL("web-ext.html")}`;

  rootShadow.innerHTML = `
    <style>
      .${className} {
        width: ${sidebarWidth}px;
        height: ${sidebarHeight}px;
        position: fixed;
        top: 8px;
        right: ${-sidebarWidth}px;
        background-color: white;
        border-radius: 12px;
        transition: right 0.15s ease-in;
        transition-delay: 0.2s;
        box-shadow: 0 2px 2px 0 rgb(0 0 0 / 14%), 0 3px 1px -2px rgb(0 0 0 / 20%), 0 1px 5px 0 rgb(0 0 0 / 12%);
        z-index: ${Number.MAX_SAFE_INTEGER - 1};
      }
      #close-fab {
        position:fixed;
        top: ${sidebarHeight + 15}px;
        right: ${-sidebarHeight}px;
        z-index: ${Number.MAX_SAFE_INTEGER};
        transition: right 0.15s ease-in;
        transition-delay: 0.2s;
        border: none;
        border-radius: 12px;
        padding: 10px;
        color: rgb(255, 255, 255);
        background-color: rgb(10, 10, 35);
        cursor: pointer;
        box-shadow: 0 2px 2px 0 rgb(0 0 0 / 14%), 0 3px 1px -2px rgb(0 0 0 / 20%), 0 1px 5px 0 rgb(0 0 0 / 12%);
      }
      #resizer {
        display: none;
        position: fixed;
        width: 10px;
        height: 10px;
        background: transparent;
        z-index: ${Number.MAX_SAFE_INTEGER};
        top: ${sidebarHeight}px;
        right: ${sidebarWidth}px;
        cursor: nesw-resize;
      }
    </style>
    <iframe frameborder="0" sandbox="allow-same-origin allow-scripts allow-forms allow-popups allow-popups-to-escape-sandbox" class="${className}" src="${url}"></iframe>
    <div id='resizer'></div>
    <button id='close-fab'>Close</button>
  `;
  sidebar = rootShadow.querySelector(`.${className}`);
  sidebar?.style.setProperty("right", `${-sidebarWidth}px`);

  // sidebar listener
  closeBtn = rootShadow.querySelector("#close-fab");
  closeBtn.addEventListener("click", (e) => {
    if (e.target.id === "close-fab") {
      toggleSidebar();
    }
  });

  resizer = rootShadow.querySelector("#resizer");
  resizer.addEventListener("mousedown", initDrag, false);

  return rootElement;
};

function updateSidebarDimensions({ width = null, height = null }) {
  if (width) {
    sidebar?.style.setProperty("width", `${width}px`);
    sidebarWidth = width;
  }
  if (height) {
    sidebar?.style.setProperty("height", `${height}px`);
    closeBtn?.style.setProperty("top", `${height + 15}px`);
    sidebarHeight = height;
  }
}

function initDrag(e) {
  startX = e.clientX;
  startY = e.clientY;
  startWidth = sidebarWidth;
  startHeight = sidebarHeight;
  // expand resizer so iframe doesnt eat up inputs
  resizer.style.top = 0;
  resizer.style.right = 0;
  resizer.style.height = "100%";
  resizer.style.width = "100%";
  document.documentElement.addEventListener("mousemove", doDrag, false);
  document.documentElement.addEventListener("mouseup", stopDrag, false);
}

function doDrag(e) {
  e.preventDefault();
  const width = startWidth + startX - e.clientX;
  const height = startHeight + e.clientY - startY;
  console.log(width, height);
  updateSidebarDimensions({
    width: (width > 250) ? width : 250,
    height: (height > 300) ? height : 300,
  });
}

function stopDrag(e) {
  window.localStorage.setItem("sidebarWidth", sidebarWidth);
  window.localStorage.setItem("sidebarHeight", sidebarHeight);
  // shrink resizer
  resizer?.style.setProperty("right", `${sidebarWidth}px`);
  resizer?.style.setProperty("top", `${sidebarHeight}px`);
  resizer?.style.setProperty("width", "10px");
  resizer?.style.setProperty("height", "10px");
  document.documentElement.removeEventListener("mousemove", doDrag, false);
  document.documentElement.removeEventListener("mouseup", stopDrag, false);
}

function modifySrc(src) {
  const ytRegex = /https:\/\/www.youtube.com\/watch\?v=.+/;
  if (src.match(ytRegex)) {
    const timestampData = getCurrentTimestampInfo();
    src =
      `https://www.youtube.com/watch?v=${timestampData.videoId}&t=${timestampData.timestamp}s`;
  }
  return src;
}

const getIframeSrc = () => {
  const selectionText = window.getSelection().toString().trim();
  const src = modifySrc(window.location.href);
  let url = `${chrome.runtime.getURL("web-ext.html")}?`;
  url += (selectionText) ? `content=${encodeURIComponent(selectionText)}&` : "";
  url += `source=${encodeURIComponent(src)}&`;
  return url;
};

const toggleSidebar = (src) => {
  if (sidebar?.style.right.startsWith("-")) {
    document.body.appendChild(rootElement);
    if (!src) {
      src = getIframeSrc();
    }
    sidebar.src = src;
    sidebar?.style.setProperty("right", "8px");
    closeBtn?.style.setProperty("right", "8px");
    resizer?.style.setProperty("display", "block");
    sidebar.contentWindow.focus();
  } else if (src) {
    sidebar.src = src;
    sidebar.contentWindow.focus();
  } else {
    sidebar?.style.setProperty("right", `-${sidebarWidth}px`);
    closeBtn?.style.setProperty("right", `-${sidebarWidth}px`);
    resizer?.style.setProperty("display", "none");
    setTimeout(() => document.body.removeChild(rootElement), 500);
  }
};

function initSidebar() {
  rootElement = createSidebar();
}

function getSrcInfo() {
  const sourceTitle = document.title ||
    document.querySelector("meta[property=og\\:title]")?.content;
  const sourceDescription = document.querySelector('meta[name="description"]')
    ?.content ||
    document.querySelector("meta[property=og\\:description]")?.content;
  let sourceImageUrl = document.querySelector("meta[property=og\\:image]")
    ?.content;

  if (!sourceImageUrl) {
    const iconHref = document.querySelector("link[rel='shortcut icon']")
      ?.getAttribute(
        "href",
      );
    sourceImageUrl = (iconHref?.startsWith("/"))
      ? window.location.origin + iconHref
      : iconHref;
  }

  const srcInfo = {
    "source": modifySrc(window.location.href),
    "source_title": sourceTitle,
    "source_description": sourceDescription,
    "source_image_url": sourceImageUrl,
  };
  return srcInfo;
}

// listeneres
function listenMessages() {
  // Listen for add timestamp request msg from popup
  chrome.runtime.onMessage.addListener((request, _sender, response) => {
    if (request.msg === "get-selection-text") {
      const selectionText = window.getSelection().toString();
      response(selectionText);
    } else if (request.msg === "toggle-sidebar") {
      toggleSidebar(request.src);
      response(true);
    } else if (request.msg === "get-src") {
      const srcInfo = getSrcInfo();
      console.log(srcInfo);
      response(srcInfo);
    }
    return true; // used to send response async
  });
}

initSidebar();
listenMessages();

