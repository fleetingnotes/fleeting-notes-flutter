require('@tensorflow/tfjs-node');
const functions = require("firebase-functions");
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

exports.rank_sentence_similarity = functions.https.onRequest(async (req, res) => {
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
