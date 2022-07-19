const functions = require("firebase-functions");
const { logEvent } = require('./scripts');

// CORS Express middleware to enable CORS Requests.
const request = require('request');
const cors = require('cors')({origin: true});

// Firebase Setup
const admin = require('firebase-admin');
let db = admin.firestore();
db.settings({ ignoreUndefinedProperties: true })

const handleError = (res, email, error) => {
  functions.logger.error({ User: email }, error);
  res.sendStatus(500);
  return;
};

const handleResponse = (res, email, status, body) => {
  functions.logger.log(
    { User: email },
    {
      Response: {
        Status: status,
      },
    }
  );
  if (body) {
    return res.status(status).json(body);
  }
  return res.status(status).json({});
};

const getAuthFromRequest = (req) => {
  let email = req.body.email;
  let password = req.body.password;

  // tries to read authentication header
  if ((!email || !password) && req.get('authorization')) {
    const base64_auth = req.get('authorization').substring(6);
    const auth = Buffer.from(base64_auth, 'base64').toString().split(':');
    email = auth[0];
    password = auth.splice(1).join('');
  }
  return { email, password };
}

const getNotesFromRequest = (req) => {
  let notes = req.body.notes;
  if (!notes) {
    notes = JSON.parse(req.get('notes'));
  }
  return notes;
}

const isEncryptionValid = async (req, uid) => {
    // check hashed encryption key
    const hashedKey = req.get('hashed-encryption-key')
    const encryptionRef = db.collection("encryption").doc(uid);
    const encryptionData = (await encryptionRef.get()).data()

    if ((hashedKey && !encryptionData) || (encryptionData && encryptionData.key && hashedKey !== encryptionData.key)) {
      return false;
    }
    return true;
}

exports.get_all_notes = functions.https.onRequest(async (req, res) => {
    return cors(req, res, async () => {
      let email, password;
      try {
        const auth = getAuthFromRequest(req);
        email = auth.email;
        password = auth.password;
        // Authentication requests are POSTed, other requests are forbidden
        if (req.method !== 'POST') {
          return handleResponse(res, email, 403);
        }
        if (!email || !password) {
          return handleResponse(res, email, 400);
        }

        const authRes = await authenticate(email, password)
        const valid = authRes['error'] === undefined;
        if (!valid) {
          functions.logger.error({ User: email }, authRes['error']);
          return handleResponse(res, email, 401, { error: 'Invalid username or password'});
        }
        const uid = authRes['localId'];

        if (!await isEncryptionValid(req, uid)) {
          return handleResponse(res, email, 400, { error: 'Invalid or missing encryption key' });
        }

        var notes = []
        const snapshot = await db.collection("notes").where('_partition', '==', uid).where('_isDeleted', '==', false).get()
        snapshot.forEach(doc => {
          var newNote = {
            "_id": doc.id,
            "title": doc.data().title,
            "content": doc.data().content,
            "source": doc.data().source,
            "timestamp": doc.data().created_timestamp.toDate(),
            "is_encrypted": doc.data().is_encrypted,
            "_isDeleted": doc.data()._isDeleted,
          }
          notes = notes.concat(newNote);
        });
        logEvent(uid, 'get_all_notes');
        return handleResponse(res, email, 200, notes);
      } catch (error) {
        return handleError(res, email, error);
      }
    });
});

exports.update_notes = functions.https.onRequest(async (req, res) => {
    return cors(req, res, async () => {
      // get email and password from request
      let email, password;
      try {
        const auth = getAuthFromRequest(req);
        email = auth.email;
        password = auth.password;
        if (!email || !password) {
          return handleResponse(res, email, 400);
        }

        // authenticate
        const authRes = await authenticate(email, password)
        const valid = authRes['error'] === undefined;
        if (!valid) {
          functions.logger.error({ User: email }, authRes['error']);
          return handleResponse(res, email, 401); // Invalid username/password
        }
        const uid = authRes['localId'];

        if (!await isEncryptionValid(req, uid)) {
          return handleResponse(res, email, 400, { error: 'Invalid or missing encryption key' });
        }

        // get notes from request
        let notes = getNotesFromRequest(req);
        const batch = db.batch();
        const last_modified_timestamp = new Date();
        if (notes.length > 500) {
          return handleResponse(res, email, 400);
        }

        await Promise.all(notes.map(async (note) => {
          const noteRef = db.collection("notes").doc(note._id)
          const partition = (await noteRef.get()).data()._partition;
          // check note is owned by user
          if (partition === uid) {
            batch.update(noteRef, {
              title: note.title,
              content: note.content,
              source: note.source,
              is_encrypted: note.is_encrypted,
              last_modified_timestamp: last_modified_timestamp,
            });
          }
        }));
        await batch.commit();
        logEvent(uid, 'update_notes');
        return handleResponse(res, email, 200, {});
      } catch (error) {
        return handleError(res, email, error);
      }
    });
});

/**
 * Authenticate the provided credentials.
 * @returns {Promise<JSON>} success or failure.
 */
function authenticate(email, password) {
  // For the purpose of this example use httpbin (https://httpbin.org) and send a basic authentication request.
  // (Only a password of `Testing123` will succeed)
  const firebaseApiKey= 'AIzaSyBXON2_4OVoHSplISHIQKtexvAlZEIZBRY'
  const authEndpoint = `https://identitytoolkit.googleapis.com/v1/accounts:signInWithPassword?key=${firebaseApiKey}`;
  const creds = {
    "email": email,
    "password": password,
  };
  return new Promise((resolve, reject) => {
    request.post({
      url: authEndpoint,
      headers: {
        'Content-Type': 'application/json'
      },
      body: creds,
      json: true,
    }, (error, response, body) => {
      
      if (error) {
        return reject(error);
      }
      const statusCode = response ? response.statusCode : 0;
      if (statusCode === 401 || statusCode === 400) { // Invalid username/password
        return resolve(body);
      }
      if (statusCode !== 200) {
        return reject(new Error(`invalid response returned from ${authEndpoint} status code ${statusCode}`));
      }
      return resolve(body);
    });
  });
}
