## Firebase Getting Started Guide: 
https://firebase.google.com/docs/functions/get-started

## Start Firebase Local Emulator Server:
```
firebase emulators:start
```

## Deploy Firebase Function
```
firebase deploy --only functions
```

## Run function from scripts (e.g. initNoteExport)
1. Go into `index.js`
2. Uncomment the `exports.initNoteEvents = scripts.initNoteEvents;`
3. Start firebase local emulator `firebase emulators:start`
4. Make a request to the URL to run the script
