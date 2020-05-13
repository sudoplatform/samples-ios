import * as functions from "firebase-functions"
import * as admin from "firebase-admin"

admin.initializeApp()

// Usage: POST https://host/endpoint?p=postboxId
// Headers: Content-Type: application/didcomm-envelope-enc
//            or application/didcomm-enc-env
//            or application/jwe
//            or application/json
//            or nothing
// Body: Raw bytes of the DIDComm Encrypted Evelope
export const endpoint = functions.https.onRequest(async (request, response) => {
    // validate HTTP method
    if (request.method !== "POST") {
        return response.status(501).send()
    }

    // validate recipient query parameter
    const postbox = request.query.p

    if (!postbox || (typeof postbox !== "string")) {
        return response.status(400).send()
    }

    if (postbox.length > 100 || postbox.indexOf("/") !== -1 || postbox.indexOf(".") !== -1) {
        return response.status(400).send()
    }

    // validate the body
    // not validating the Content-Type right now
    const messageBody = request.rawBody

    if (!messageBody) {
        return response.status(400).send()
    }

    console.log(`Creating document of size ${messageBody.byteLength} in postbox ${postbox}`)

    // make the request available to the edge agent
    await admin.firestore()
        .collection("postboxes")
        .doc(postbox)
        .collection("messages")
        .add({
            message: messageBody,
            createdAt: admin.firestore.FieldValue.serverTimestamp()
        })

    // successfully processed
    return response.status(202).send()
})
