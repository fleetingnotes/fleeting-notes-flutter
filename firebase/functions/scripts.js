const { BigQuery, BigQueryDatetime } = require('@google-cloud/bigquery');
const functions = require("firebase-functions");
const admin = require('firebase-admin');

const bigquery = new BigQuery();
var db = admin.firestore();

const exportFirestore2Json = async (collection) => {
    const items = {};
    const querySnapshot = await db.collection(collection).get();
    querySnapshot.forEach(doc => {
        items[doc.id] = doc.data();
    });
    return items
}

exports.initNoteEvents = functions.https.onRequest(async (req, res) => {
    const notesCollection = await exportFirestore2Json('notes');
    const noteEvents = [];

    for (const [key, value] of Object.entries(notesCollection)) {
        const noteEvent = {
            note_id: key,
            uid: value._partition,
            created_time: new BigQueryDatetime(new Date(value.created_timestamp._seconds * 1000).toISOString()),
            last_modified_time: new BigQueryDatetime(new Date(value.last_modified_timestamp._seconds * 1000).toISOString()),
        }
        noteEvents.push(noteEvent);
    }

    const dataset = bigquery.dataset('firebase_functions');
    const table = dataset.table('note_events');
    return table.insert(noteEvents);
});