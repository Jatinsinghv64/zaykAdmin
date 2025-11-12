// This file does NOT go in your Flutter app.
// You must deploy it to Firebase using the Firebase CLI.

const { onDocumentCreated, onDocumentUpdated } = require("firebase-functions/v2/firestore");
const { getFirestore, FieldValue } = require("firebase-admin/firestore");
const { getMessaging } = require("firebase-admin/messaging");
const { initializeApp } = require("firebase-admin/app");
const { logger } = require("firebase-functions");

// Initialize Firebase Admin
initializeApp();
const db = getFirestore();

/**
 * Triggers when a new document is created in the 'Orders' collection.
 * Sends data-only push notifications to branch admins for new pending orders.
 */
exports.sendNotificationOnNewOrder = onDocumentCreated("Orders/{orderId}", async (event) => {
  try {
    // 1. Get the new document snapshot and data
    const snap = event.data;
    if (!snap) {
      logger.log("No data associated with the event, exiting.");
      return;
    }

    const orderData = snap.data();
    const orderId = event.params.orderId;

    logger.log(`Processing new order: ${orderId}`, {
      status: orderData.status,
      branchIds: orderData.branchIds,
      orderType: orderData.Order_type
    });

    // 2. Only send notifications for 'pending' orders.
    if (orderData.status !== "pending") {
      logger.log(`Order ${orderId} is not 'pending', skipping notification.`);
      return;
    }

    // 3. Get the branch IDs from the order.
    const branchIds = orderData.branchIds;
    if (!branchIds || branchIds.length === 0) {
      logger.log(`Order ${orderId} has no branch IDs, skipping.`);
      return;
    }

    logger.log(`New pending order ${orderId} for branches:`, branchIds);

    // 4. Find all active 'branch_admin' staff assigned to these branches.
    const staffQuery = await db
      .collection("staff")
      .where("role", "==", "branch_admin")
      .where("isActive", "==", true)
      .where("branchIds", "array-contains-any", branchIds)
      .get();

    if (staffQuery.empty) {
      logger.log("No active branch admin staff found for these branches.");
      return;
    }

    logger.log(`Found ${staffQuery.size} staff members for notification`);

    // 5. Collect all the unique FCM tokens from those staff members.
    const tokens = new Set();
    const staffEmails = [];

    staffQuery.docs.forEach((doc) => {
      const staffData = doc.data();
      const token = staffData.fcmToken;
      const email = doc.id;

      if (token && typeof token === 'string' && token.length > 0) {
        tokens.add(token);
        staffEmails.push(email);
        logger.log(`Added token for staff: ${email}`);
      } else {
        logger.log(`No valid FCM token for staff: ${email}`);
      }
    });

    if (tokens.size === 0) {
      logger.log("No staff have valid FCM tokens.");
      return;
    }

    const tokensList = Array.from(tokens);
    const orderNumber = orderData.dailyOrderNumber ||
      orderData.orderNumber ||
      orderId.substring(0, 8).toUpperCase();

    // 6. Prepare notification content
    const orderType = orderData.Order_type || 'order';
    const customerName = orderData.customerName || 'Customer';
    const items = orderData.items || [];
    const itemCount = items.length;

    const notificationBody = itemCount > 0
      ? `${customerName} - ${itemCount} item${itemCount > 1 ? 's' : ''} (${orderType})`
      : `New ${orderType} order from ${customerName}`;

    const notificationTitle = `New Order #${orderNumber}`;

    // 7. Create the DATA-ONLY payload.
    // We move the title and body *inside* the data map.
    // The app will be responsible for displaying this.
    const dataPayload = {
      // Notification content for the app to display
      title: notificationTitle,
      body: notificationBody,

      // Custom app data
      orderId: orderId,
      orderNumber: orderNumber.toString(),
      orderType: orderType,
      customerName: customerName,
      branchIds: JSON.stringify(branchIds), // Must be a string
      click_action: "FLUTTER_NOTIFICATION_CLICK",
      type: "new_order",
      timestamp: new Date().toISOString(),
    };

    // 8. Create the multicast message
    // NOTICE: There is NO 'notification' key. This is critical.
    const multicastMessage = {
      data: dataPayload,
      tokens: tokensList,

      // Set delivery priority for Android and iOS
      android: {
        priority: "high", // Ensures message is delivered promptly
      },
      apns: {
        headers: {
          "apns-priority": "10", // High priority for APNs
        },
        payload: {
          aps: {
            "content-available": 1, // Wakes up iOS app
          },
        },
      },
    };

    logger.log(`Sending DATA-ONLY notification to ${tokensList.length} tokens for order ${orderId}`);
    logger.log(`Data payload:`, dataPayload);

    // 9. Send the push notification
    try {
      const response = await getMessaging().sendEachForMulticast(multicastMessage);

      logger.log(`Batch: Successfully sent ${response.successCount} messages`);

      // 10. Clean up invalid tokens
      response.responses.forEach((result, index) => {
        const error = result.error;
        if (error) {
          const failedToken = tokensList[index];
          logger.error(`Failure sending to token ${failedToken.substring(0, 10)}...:`, error);

          // Clean up invalid tokens from database
          if (error.code === 'messaging/registration-token-not-registered' ||
            error.code === 'messaging/invalid-registration-token' ||
            error.code === 'messaging/invalid-argument') {

            logger.log(`Removing invalid token for staff`);

            // Find and remove the invalid token from all staff documents
            staffQuery.docs.forEach(async (doc) => {
              const staffData = doc.data();
              if (staffData.fcmToken === failedToken) {
                await doc.ref.update({
                  fcmToken: FieldValue.delete(),
                  fcmTokenInvalidated: FieldValue.serverTimestamp()
                });
                logger.log(`Removed invalid FCM token for staff: ${doc.id}`);
              }
            });
          }
        }
      });

    } catch (batchError) {
      logger.error(`Error sending batch:`, batchError);
    }

    logger.log(`Notification process completed for order ${orderId}`);
    return;

  } catch (error) {
    logger.error("Error in sendNotificationOnNewOrder:", error);
    throw error;
  }
});

/**
 * Optional: Also trigger notifications when order status changes to pending
 */
exports.sendNotificationOnOrderStatusUpdate = onDocumentUpdated("Orders/{orderId}", async (event) => {
  try {
    const beforeData = event.data.before.data();
    const afterData = event.data.after.data();
    const orderId = event.params.orderId;

    // Only send notification if status changed TO 'pending'
    if (beforeData.status !== 'pending' && afterData.status === 'pending') {
      logger.log(`Order ${orderId} status changed to pending, triggering notification`);

      // We need to pass the "after" data to the creation function
      const fakeEvent = {
        data: event.data.after, // Use the new data
        params: event.params
      };

      // Call the original function with the new data
      await exports.sendNotificationOnNewOrder(fakeEvent);
    }
  } catch (error) {
    logger.error("Error in sendNotificationOnOrderStatusUpdate:", error);
  }
});


/**
 * Utility function to test DATA-ONLY notifications
 */
exports.testNotification = require("firebase-functions/v2/https").onRequest(async (req, res) => {
  try {
    const { staffEmail } = req.body;

    if (!staffEmail) {
      return res.status(400).json({ error: "staffEmail is required" });
    }

    const staffDoc = await db.collection("staff").doc(staffEmail).get();
    if (!staffDoc.exists) {
      return res.status(404).json({ error: "Staff not found" });
    }

    const staffData = staffDoc.data();
    const token = staffData.fcmToken;

    if (!token) {
      return res.status(400).json({ error: "No FCM token found for staff" });
    }

    // Create a data-only test payload
    const dataPayload = {
      title: "Test Notification",
      body: "This is a DATA-ONLY test from your Cloud Function",
      type: "test",
      message: "Test notification successful",
      timestamp: new Date().toISOString(),
    };

    const response = await getMessaging().send({
      data: dataPayload,
      token: token,
      android: { priority: "high" },
      apns: {
        headers: { "apns-priority": "10" },
        payload: { aps: { "content-available": 1 } }
      }
    });

    return res.json({
      success: true,
      message: "Test data-only notification sent",
      response: response
    });

  } catch (error) {
    logger.error("Error sending test notification:", error);
    return res.status(500).json({ error: error.message });
  }
});