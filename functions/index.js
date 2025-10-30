const functions = require('firebase-functions');
const admin = require('firebase-admin');
admin.initializeApp();

function rolesToClaims(roleIds = []) {
  const claims = { roles: roleIds };
  claims.admin    = roleIds.includes('admin');
  claims.operador = roleIds.includes('operador');
  claims.cliente  = roleIds.includes('cliente');
  return claims;
}

// Trigger: si cambian los roles en Firestore -> actualizar custom claims
exports.onUserRoleChange = functions.firestore
  .document('users/{uid}')
  .onWrite(async (change, context) => {
    const after = change.after.exists ? change.after.data() : null;
    if (!after) return;

    const before = change.before.exists ? change.before.data() : null;
    const beforeRoles = (before && before.roleIds) || [];
    const afterRoles  = after.roleIds || [];

    if (JSON.stringify(beforeRoles) === JSON.stringify(afterRoles)) return;

    const uid = context.params.uid;
    await admin.auth().setCustomUserClaims(uid, rolesToClaims(afterRoles));
    await change.after.ref.set({
      lastClaimsSync: admin.firestore.FieldValue.serverTimestamp()
    }, { merge: true });
  });
