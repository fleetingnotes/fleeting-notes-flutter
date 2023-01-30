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

// Obtain all relevant info for the timestamp and returns it.
function getCurrentTimestampInfo() {
  const time = document.getElementsByTagName("video")[0].currentTime;
  const videoId = getVideoId();
  // obtain title by scraping webpage
  const title = document.getElementsByClassName(
      "title style-scope ytd-video-primary-info-renderer"
  )[0].firstChild.innerText;

  return {
    timestamp: Math.floor(time),
    videoId,
    title,
  }
}

// sidebar logic
const sidebarWidth = 400;
let rootElement;
let sidebar;
const createSidebar = () => {
  rootElement = document.createElement("div");
  // remove potential global styles
  rootElement.style.setProperty("all", "initial");

  const className = "sidebar";
  const height = 360;
  const rootShadow = rootElement.attachShadow({ mode: "closed" });
  const url = `${chrome.runtime.getURL("web-ext.html")}`;
  
  rootShadow.innerHTML = `
    <style>
      .${className} {
        width: ${sidebarWidth}px;
        height: ${height}px;
        position: fixed;
        top: 8px;
        background-color: white;
        border-radius: 12px;
        transition: right 0.15s ease-in;
        transition-delay: 0.3s;
        box-shadow: 0 2px 2px 0 rgb(0 0 0 / 14%), 0 3px 1px -2px rgb(0 0 0 / 20%), 0 1px 5px 0 rgb(0 0 0 / 12%);
        z-index: ${Number.MAX_SAFE_INTEGER};
      }
    </style>
    <iframe frameborder="0" sandbox="allow-same-origin allow-scripts allow-forms allow-popups allow-popups-to-escape-sandbox" class="${className}" src="${url}"></iframe>
  `;
  sidebar = rootShadow.querySelector(`.${className}`);
  sidebar?.style.setProperty("right", `${-sidebarWidth}px`);

  return rootElement;
};

function modifySrc(src) {
    const ytRegex = /https:\/\/www.youtube.com\/watch\?v=.+/;
    if (src.match(ytRegex)) {
      const timestampData = getCurrentTimestampInfo();
      src = `https://www.youtube.com/watch?v=${timestampData.videoId}&t=${timestampData.timestamp}s`
    }
    return src;
}

const getIframeSrc = () => {
  const selectionText = window.getSelection().toString().trim();
  const src = modifySrc(window.location.href);
  let url = `${chrome.runtime.getURL("web-ext.html")}?`;
  url += (selectionText) ? `content=${encodeURIComponent(selectionText)}&` : '';
  url += `source=${encodeURIComponent(src)}&`;
  return url;
}

const toggleSidebar = (src) => {
  if (sidebar?.style.right.startsWith('-')) {
    if (!src) {
      src = getIframeSrc();
    }
    sidebar.src = src
    sidebar?.style.setProperty("right", "8px");
  } else {
    sidebar?.style.setProperty("right", `-${sidebarWidth}px`);
  }
};

function initSidebar() {
  rootElement = createSidebar();
  document.body.appendChild(rootElement);
}

// listeneres
function listenMessages() {
  // Listen for add timestamp request msg from popup
  chrome.runtime.onMessage.addListener((request, sender, response) => {
    if (request.msg === "get-selection-text") {
      const selectionText = window.getSelection().toString();
      response(selectionText);
    } else if (request.msg === "toggle-sidebar") {
      toggleSidebar(request.src);
    } else if (request.msg === "get-src") {
      const src = modifySrc(window.location.href);
      response(src);
    }
    return true; // used to send response async
  });
}

initSidebar();
listenMessages();