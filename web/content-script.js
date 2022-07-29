console.log('content-script.js');
var iFrame = document.createElement('iframe');
iFrame.id='content-script-div';
iFrame.src = chrome.runtime.getURL('web-ext.html');
iFrame.width=800;
iFrame.height=500;
iFrame.resize='true';

var div = document.createElement('div');
div.id='mydiv';
div.innerHTML = '<div id="mydivheader">Click here to move</div>'
div.appendChild(iFrame);

// div.draggable = 'true';
// div.style.position = 'absolute';
// div.style.zIndex = '9999';
// div.ondragstart='onDragStart(event)';
// div.drag
// Immediately-invoked function expression
(function() {
    // Load the script
    const script = document.createElement("script");
    script.src = chrome.runtime.getURL('jquery-3.6.0.min.js');
    script.type = 'text/javascript';
    script.addEventListener('load', () => {
        console.log(`jQuery ${$.fn.jquery} has been loaded successfully!`);
        document.body.appendChild(div)
        dragElement(div);
        addCss();
      // use jQuery below
    });
    document.head.appendChild(script);
})();

function addCss() {
    var head  = document.getElementsByTagName('head')[0];
    var link  = document.createElement('link');
    // link.id   = cssId;
    link.rel  = 'stylesheet';
    link.type = 'text/css';
    link.href = chrome.runtime.getURL('styles.css');
    link.media = 'all';
    head.appendChild(link);
}

function dragElement(elmnt) {
    var pos1 = 0, pos2 = 0, pos3 = 0, pos4 = 0;
    if (document.getElementById(elmnt.id + "header")) {
      // if present, the header is where you move the DIV from:
      document.getElementById(elmnt.id + "header").onmousedown = dragMouseDown;
    } else {
      // otherwise, move the DIV from anywhere inside the DIV:
      elmnt.onmousedown = dragMouseDown;
    }
  
    function dragMouseDown(e) {
      e = e || window.event;
      e.preventDefault();
      // get the mouse cursor position at startup:
      pos3 = e.clientX;
      pos4 = e.clientY;
      document.onmouseup = closeDragElement;
      // call a function whenever the cursor moves:
      document.onmousemove = elementDrag;
    }
  
    function elementDrag(e) {
      e = e || window.event;
      e.preventDefault();
      // calculate the new cursor position:
      pos1 = pos3 - e.clientX;
      pos2 = pos4 - e.clientY;
      pos3 = e.clientX;
      pos4 = e.clientY;
      // set the element's new position:
      elmnt.style.top = (elmnt.offsetTop - pos2) + "px";
      elmnt.style.left = (elmnt.offsetLeft - pos1) + "px";
    }
  
    function closeDragElement() {
      // stop moving when mouse button is released:
      document.onmouseup = null;
      document.onmousemove = null;
    }
  }

  window.addEventListener('click', function(e){   
    if (document.getElementById('mydiv').contains(e.target)){
      // Clicked in box
    } else{
      // Clicked outside the box
      div.style.display= 'none';
      div.style.visibility= 'hidden';
    }
  });