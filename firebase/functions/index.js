// CORS Express middleware to enable CORS Requests.
const cors = require('cors')({origin: true});

// Firebase Setup
const functions = require("firebase-functions");
const admin = require('firebase-admin');
admin.initializeApp();
// @ts-ignore
// const serviceAccount = require('./service-account.json');
// admin.initializeApp({
//   credential: admin.credential.cert(serviceAccount),
//   databaseURL: `https://${process.env.GCLOUD_PROJECT}.firebaseio.com`,
// });

// We use Request to make the basic authentication request in our example.
const basicAuthRequest = require('request');

require('@tensorflow/tfjs-node');
const use = require("@tensorflow-models/universal-sentence-encoder");
let model;

// Calculate the dot product of two vector arrays.
const dotProduct = (xs, ys) => {
    const sum = xs => xs ? xs.reduce((a, b) => a + b, 0) : undefined;
  
    return xs.length === ys.length ?
      sum(zipWith((a, b) => a * b, xs, ys))
      : undefined;
}
  
// zipWith :: (a -> b -> c) -> [a] -> [b] -> [c]
const zipWith = (f, xs, ys) => {
    const ny = ys.length;
    return (xs.length <= ny ? xs : xs.slice(0, ny))
        .map((x, i) => f(x, ys[i]));
}

// // Create and Deploy Your First Cloud Functions
// // https://firebase.google.com/docs/functions/write-firebase-functions

exports.rank_sentence_similarity = functions.runWith({memory: "1GB"}).https.onRequest(async (req, res) => {
    // Embed an array of sentences.
    const sentences = [
        req.body['query'],
        ...req.body['sentences'],
    ];
    model = model || await use.load();
    model.embed(sentences).then((embeddings) => {
        let embeddings_arr = embeddings.arraySync();
        let queryVector = embeddings_arr[0];
        let sentenceVectors = embeddings_arr.slice(1);
        let sentenceMap = {}
        for (let i = 0; i < sentenceVectors.length; i++) {
            sentenceMap[sentences[i+1]] = dotProduct(queryVector, sentenceVectors[i]);
        }
        res.send(sentenceMap);
    });
});



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
            Body: body,
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
  
        // TODO(DEVELOPER): In production you'll need to update the `authenticate` function so that it authenticates with your own credentials system.
        const valid = await authenticate(email, password)
        if (!valid) {
          return handleResponse(email, 401); // Invalid username/password
        }
  
        // On success return the Firebase Custom Auth Token.
        // const firebaseToken = await admin.auth().createCustomToken(email);
        return handleResponse(email, 200);
      });
    } catch (error) {
      return handleError(email, error);
    }
});

/**
 * Authenticate the provided credentials.
 * TODO(DEVELOPER): In production you'll need to update this function so that it authenticates with your own credentials system.
 * @returns {Promise<boolean>} success or failure.
 */
 function authenticate(email, password) {
    // For the purpose of this example use httpbin (https://httpbin.org) and send a basic authentication request.
    // (Only a password of `Testing123` will succeed)
    const firebaseApiKey= 'AIzaSyBXON2_4OVoHSplISHIQKtexvAlZEIZBRY'
    const authEndpoint = `https://identitytoolkit.googleapis.com/v1/accounts:signInWithPassword?key=${firebaseApiKey}`;
    const creds = {
      email: email,
      password: password,
    };
    return new Promise((resolve, reject) => {
      request.post(authEndpoint, creds, (error, response, body) => {
        if (error) {
          return reject(error);
        }
        const statusCode = response ? response.statusCode : 0;
        if (statusCode === 401) { // Invalid username/password
          return resolve(false);
        }
        if (statusCode !== 200) {
          return reject(new Error(`invalid response returned from ${authEndpoint} status code ${statusCode}`));
        }
        return resolve(true);
      });
    });
  }