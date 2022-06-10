const functions = require("firebase-functions");

const admin = require('firebase-admin');
const { BigQuery } = require('@google-cloud/bigquery');

const bigquery = new BigQuery();

const listAllUsers = async () => {
    const appendToAllUsers = async (allUsers, nextPageToken) => {
        // List batch of users, 1000 at a time.
        listUsersResult = await admin.auth().listUsers(1000, nextPageToken)
        listUsersResult.users.forEach((userRecord) => {
            userRecord.metadata.creationTime = new Date(userRecord.metadata.creationTime)
            allUsers.push({
                uid: userRecord.uid,
                last_sign_in_time: new Date(userRecord.metadata.lastSignInTime).toISOString(),
                creation_time: new Date(userRecord.metadata.creationTime).toISOString(),
                export_time: new Date().toISOString(),
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

exports.bq_user_export = functions.pubsub.schedule('every hour').onRun(async (context) => {
    let allUsers = await listAllUsers();
    const dataset = bigquery.dataset('firebase_functions');
    const table = dataset.table('auth_users');

    return await table.insert(allUsers);
});