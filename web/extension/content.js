// Parse the current page URL for the video ID and returns the ID.
// https://stackoverflow.com/questions/3452546/how-do-i-get-the-youtube-video-id-from-a-url
function getVideoId() {
  if (window.location.search.split("v=")[1] === undefined) {
    return "";
  }
  let videoId = window.location.search.split("v=")[1];
  const ampersandPosition = videoId.indexOf("&");
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
  const srcInfo = getSrcInfo();
  if (srcInfo.source) {
    url += `?source=${encodeURIComponent(srcInfo.source)}`;
    if (srcInfo.source_title) {
      url += `&source_title=${encodeURIComponent(srcInfo.source_title)}`;
    }
    if (srcInfo.source_description) {
      url += `&source_description=${
        encodeURIComponent(srcInfo.source_description)
      }`;
    }
    if (srcInfo.source_image_url) {
      url += `&source_image_url=${
        encodeURIComponent(srcInfo.source_image_url)
      }`;
    }
  }
  return url;
};


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
    } else if (request.msg === "get-src") {
      const src = getIframeSrc();
      response(src);
    }
    return true; // used to send response async
  });
}

listenMessages();
