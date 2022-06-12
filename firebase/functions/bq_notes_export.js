const functions = require("firebase-functions");

const { BigQuery, BigQueryDatetime } = require('@google-cloud/bigquery');

const bigquery = new BigQuery();

exports.bq_notes_export = functions.firestore.document('notes/{noteId}').onWrite(async (change, context) => {
    const note = change.after.data();
    const note_event = {
        note_id: context.params.noteId,
        uid: note._partition,
        created_time: new BigQueryDatetime(new Date(note.created_timestamp._seconds * 1000).toISOString()),
        last_modified_time: new BigQueryDatetime(new Date(note.last_modified_timestamp._seconds * 1000).toISOString()),
    }
    functions.logger.info(note_event);
    const dataset = bigquery.dataset('firebase_functions');
    const table = dataset.table('note_events');

    return await table.insert([note_event]);
});
