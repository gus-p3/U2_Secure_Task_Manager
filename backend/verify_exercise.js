'use strict';
require('dotenv').config();
const { app } = require('./src/app');
const request = require('supertest');

async function runExercise() {
  console.log('=====================================================');
  console.log('SECURE TASK MANAGER - VERIFICATION & HANDS-ON EXERCISE');
  console.log('=====================================================\n');

  const randomSuffix = Math.floor(Math.random() * 900000) + 100000;
  const email = `student-${randomSuffix}@example.test`;
  const password = 'a-long-local-test-password-for-this-exercise';

  console.log(`[SETUP] Registering test account: ${email}`);
  const regRes = await request(app)
    .post('/api/v1/auth/register')
    .send({ email, password });

  console.log(`Register status: ${regRes.status}`);
  let access = regRes.body.accessToken;
  let refresh = regRes.body.refreshToken;
  console.log(`Access Token: [OBFUSCATED: ${access.substring(0, 10)}...]`);
  console.log(`Refresh Token: [OBFUSCATED: ${refresh.substring(0, 10)}...]\n`);

  // TASK 1: Rotation
  console.log('--- TASK 1: REFRESH-TOKEN ROTATION ---');
  const oldRefresh = refresh;
  const rotRes = await request(app)
    .post('/api/v1/auth/refresh')
    .send({ refreshToken: oldRefresh });

  const task1Status = rotRes.status;
  const newRefresh = rotRes.body.refreshToken;
  const newAccess = rotRes.body.accessToken;
  const isDifferent = newRefresh !== oldRefresh;
  console.log(`Refresh HTTP Status: ${task1Status} (Expected: 200)`);
  console.log(`Token comparison: ${isDifferent ? 'DIFFERENT' : 'SAME'} (Expected: DIFFERENT)`);
  console.log(`Task 1 Result: ${task1Status === 200 && isDifferent ? 'PASS' : 'FAIL'}\n`);

  // TASK 2: Reuse Detection
  console.log('--- TASK 2: TOKEN REUSE DETECTION ---');
  console.log('Reusing old revoked refresh token...');
  const reuseRes = await request(app)
    .post('/api/v1/auth/refresh')
    .send({ refreshToken: oldRefresh });
  console.log(`Reusing old token HTTP Status: ${reuseRes.status} (Expected: 401)`);

  console.log('Attempting to use newest token from the same family after reuse...');
  const newestRes = await request(app)
    .post('/api/v1/auth/refresh')
    .send({ refreshToken: newRefresh });
  console.log(`Newest token after family revocation HTTP Status: ${newestRes.status} (Expected: 401)`);
  console.log(`Task 2 Result: ${reuseRes.status === 401 && newestRes.status === 401 ? 'PASS' : 'FAIL'}\n`);

  // TASK 3: Logout
  console.log('--- TASK 3: LOGOUT & FAMILY REVOCATION ---');
  const loginRes = await request(app)
    .post('/api/v1/auth/login')
    .send({ email, password });
  const logoutRefresh = loginRes.body.refreshToken;

  const logoutRes = await request(app)
    .post('/api/v1/auth/logout')
    .send({ refreshToken: logoutRefresh });
  console.log(`Logout HTTP Status: ${logoutRes.status} (Expected: 204)`);

  const afterLogoutRes = await request(app)
    .post('/api/v1/auth/refresh')
    .send({ refreshToken: logoutRefresh });
  console.log(`Refresh after logout HTTP Status: ${afterLogoutRes.status} (Expected: 401)`);
  console.log(`Task 3 Result: ${logoutRes.status === 204 && afterLogoutRes.status === 401 ? 'PASS' : 'FAIL'}\n`);

  // TASK 4: Logout-All
  console.log('--- TASK 4: LOGOUT-ALL ---');
  const s1 = await request(app).post('/api/v1/auth/login').send({ email, password });
  const access1 = s1.body.accessToken;
  const refresh1 = s1.body.refreshToken;

  const s2 = await request(app).post('/api/v1/auth/login').send({ email, password });
  const refresh2 = s2.body.refreshToken;

  const logoutAllRes = await request(app)
    .post('/api/v1/auth/logout-all')
    .set('Authorization', `Bearer ${access1}`);
  console.log(`Logout-all HTTP Status: ${logoutAllRes.status} (Expected: 204)`);

  const refresh1After = await request(app).post('/api/v1/auth/refresh').send({ refreshToken: refresh1 });
  const refresh2After = await request(app).post('/api/v1/auth/refresh').send({ refreshToken: refresh2 });
  console.log(`Session 1 refresh after logout-all HTTP Status: ${refresh1After.status} (Expected: 401)`);
  console.log(`Session 2 refresh after logout-all HTTP Status: ${refresh2After.status} (Expected: 401)`);
  console.log(`Task 4 Result: ${logoutAllRes.status === 204 && refresh1After.status === 401 && refresh2After.status === 401 ? 'PASS' : 'FAIL'}\n`);

  console.log('=====================================================');
  console.log('SUMMARY TABLE: HANDS-ON EXERCISE COMPLIANCE');
  console.log('=====================================================');
  console.table([
    { Test: 'Refresh with valid token', 'Expected status': 200, 'Your result': task1Status, 'Pass?': task1Status === 200 ? 'YES' : 'NO' },
    { Test: 'Refresh with old token', 'Expected status': 401, 'Your result': reuseRes.status, 'Pass?': reuseRes.status === 401 ? 'YES' : 'NO' },
    { Test: 'Refresh with newest token after reuse', 'Expected status': 401, 'Your result': newestRes.status, 'Pass?': newestRes.status === 401 ? 'YES' : 'NO' },
    { Test: 'Refresh after logout', 'Expected status': 401, 'Your result': afterLogoutRes.status, 'Pass?': afterLogoutRes.status === 401 ? 'YES' : 'NO' },
    { Test: 'Refresh after logout-all', 'Expected status': 401, 'Your result': refresh1After.status, 'Pass?': refresh1After.status === 401 ? 'YES' : 'NO' },
  ]);
  process.exit(0);
}

runExercise().catch((err) => {
  console.error(err);
  process.exit(1);
});
