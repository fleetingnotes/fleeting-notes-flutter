const functions = require("firebase-functions");

const admin = require('firebase-admin');
const { BigQuery, BigQueryDatetime } = require('@google-cloud/bigquery');

const bigquery = new BigQuery();

const listAllUsers = async () => {
    const appendToAllUsers = async (allUsers, nextPageToken) => {
        const export_time = new BigQueryDatetime(new Date().toISOString())
        // List batch of users, 1000 at a time.
        let listUsersResult = await admin.auth().listUsers(1000, nextPageToken)
        listUsersResult.users.forEach((userRecord) => {
            userRecord.metadata.creationTime = new Date(userRecord.metadata.creationTime)
            allUsers.push({
                uid: userRecord.uid,
                last_sign_in_time: new BigQueryDatetime(new Date(userRecord.metadata.lastSignInTime).toISOString()),
                creation_time: new BigQueryDatetime(new Date(userRecord.metadata.creationTime).toISOString()),
                export_time: export_time,
            })
        });
        return listUsersResult.pageToken;
    }

    let allUsers = [];
    let nextPageToken = await appendToAllUsers(allUsers);
    while (nextPageToken) {
        nextPageToken = await appendToAllUsers(allUsers, nextPageToken);
    }
    return allUsers
};

exports.bq_user_export = functions.pubsub.schedule('every hour').onRun(async () => {
    let allUsers = await listAllUsers();
    const dataset = bigquery.dataset('firebase_functions');
    const table = dataset.table('auth_users');

    await table.insert(allUsers);

    return null;
});