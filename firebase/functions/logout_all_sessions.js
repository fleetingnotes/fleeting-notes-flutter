const functions = require("firebase-functions");
const cors = require('cors')({origin: true});

const admin = require('firebase-admin');

exports.logout_all_sessions = functions.https.onRequest(async (req, res) => {
    return cors(req, res, async () => {
      // Authentication requests are POSTed, other requests are forbidden
      if (req.method !== 'POST') {
        return res.sendStatus(403);
      }
      const uid = req.body.uid;
      if (!uid) {
        return res.sendStatus(400);
      }

      try {
        await admin.auth().revokeRefreshTokens(uid);
        return res.sendStatus(200);
      } catch {
        return res.sendStatus(400);
      }
    });
});
