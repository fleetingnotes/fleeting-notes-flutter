const functions = require("firebase-functions");
const { logEvent } = require('./scripts');

// CORS Express middleware to enable CORS Requests.
const request = require('request');
const cors = require('cors')({origin: true});

// Firebase Setup
const admin = require('firebase-admin');

exports.get_all_notes = functions.https.onRequest(async (req, res) => {
    const handleError = (email, error) => {
      functions.logger.error({ User: email }, error);
      res.sendStatus(500);
      return;
    };
  
    const handleResponse = (email, status, body) => {
      functions.logger.log(
        { User: email },
        {
          Response: {
            Status: status,
          },
        }
      );
      if (body) {
        return res.status(200).json(body);
      }
      return res.sendStatus(status);
    };
    let email = '';
    try {
      return cors(req, res, async () => {
        // Authentication requests are POSTed, other requests are forbidden
        if (req.method !== 'POST') {
          return handleResponse(email, 403);
        }
        email = req.body.email;
        if (!email) {
          return handleResponse(email, 400);
        }
        const password = req.body.password;
        if (!password) {
          return handleResponse(email, 400);
        }
  
        const authRes = await authenticate(email, password)
        const valid = authRes['error'] === undefined;
        if (!valid) {
          functions.logger.error({ User: email }, authRes['error']);
          return handleResponse(email, 401); // Invalid username/password
        }
        var db = admin.firestore();
        var notes = []
        const uid = authRes['localId'];
        const snapshot = await db.collection("notes").where('_partition', '==', uid).get()


        snapshot.forEach(doc => {
          var newNote = {
            "_id": doc.id,
            "title": doc.data().title,
            "content": doc.data().content,
            "source": doc.data().source,
            "timestamp": doc.data().created_timestamp.toDate(),
            "_isDeleted": doc.data()._isDeleted,
          }
          notes = notes.concat(newNote);
        });
        logEvent(uid, 'get_all_notes');
        return handleResponse(email, 200, notes);
      });
    } catch (error) {
      return handleError(email, error);
    }
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
