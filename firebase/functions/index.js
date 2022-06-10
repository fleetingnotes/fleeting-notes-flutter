const { initializeApp } = require('firebase-admin/app');
initializeApp();

const get_all_notes = require('./get_all_notes');
const logout_all_sessions = require('./logout_all_sessions');
const bq_user_export = require('./bq_user_export');
const rank_sentence_similarity = require('./rank_sentence_similarity');

exports.get_all_notes = get_all_notes.get_all_notes;
exports.logout_all_sessions = logout_all_sessions.logout_all_sessions;
exports.bq_user_export = bq_user_export.bq_user_export;
exports.rank_sentence_similarity = rank_sentence_similarity.rank_sentence_similarity;
