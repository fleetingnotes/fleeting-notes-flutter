// This prevents default browser actions on key combinations.
// See https://stackoverflow.com/a/67039463/6509751.
window.addEventListener("keydown", function (e) {
  if (event.target == document.body) {
    // Prevents going back to the previous tab.
    if (event.key == "Backspace") {
      event.preventDefault();
    }
  }

  if (event.metaKey || event.ctrlKey) {
    switch (event.key) {
      case "s": // Prevent save
        event.preventDefault();
        break;
      case "o": // Prevent open
        event.preventDefault();
        break;
      case "k": // Prevent search
        event.preventDefault();
        break;
    }
  }
});

