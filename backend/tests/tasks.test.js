'use strict';
const request = require('supertest');
const { app } = require('../src/app');

describe('tasks authorization and ownership', () => {
  let userAToken;
  let userBToken;
  let userATaskId;

  beforeAll(async () => {
    // Register User A
    const resA = await request(app).post('/api/v1/auth/register').send({
      email: `userA-${Date.now()}@example.test`,
      password: 'password-for-user-a-1234',
    });
    userAToken = resA.body.accessToken;

    // Register User B
    const resB = await request(app).post('/api/v1/auth/register').send({
      email: `userB-${Date.now()}@example.test`,
      password: 'password-for-user-b-1234',
    });
    userBToken = resB.body.accessToken;

    // User A creates a task
    const taskRes = await request(app)
      .post('/api/v1/tasks')
      .set('Authorization', `Bearer ${userAToken}`)
      .send({ title: 'User A Secret Task', description: 'Important info' });
    userATaskId = taskRes.body.item.id;
  });

  test('User A can view their own task', async () => {
    const res = await request(app)
      .get('/api/v1/tasks')
      .set('Authorization', `Bearer ${userAToken}`);
    expect(res.status).toBe(200);
    expect(res.body.items.some((t) => t.id === userATaskId)).toBe(true);
  });

  test('User B cannot see User A task', async () => {
    const res = await request(app)
      .get('/api/v1/tasks')
      .set('Authorization', `Bearer ${userBToken}`);
    expect(res.status).toBe(200);
    expect(res.body.items.some((t) => t.id === userATaskId)).toBe(false);
  });

  test('User B cannot update User A task', async () => {
    const res = await request(app)
      .patch(`/api/v1/tasks/${userATaskId}`)
      .set('Authorization', `Bearer ${userBToken}`)
      .send({ title: 'Hacked by B' });
    expect(res.status).toBe(404);
  });

  test('User B cannot delete User A task', async () => {
    const res = await request(app)
      .delete(`/api/v1/tasks/${userATaskId}`)
      .set('Authorization', `Bearer ${userBToken}`);
    expect(res.status).toBe(404);
  });

  test('User A can update and delete their own task', async () => {
    const updateRes = await request(app)
      .patch(`/api/v1/tasks/${userATaskId}`)
      .set('Authorization', `Bearer ${userAToken}`)
      .send({ completed: true });
    expect(updateRes.status).toBe(200);
    expect(updateRes.body.item.completed).toBe(true);

    const deleteRes = await request(app)
      .delete(`/api/v1/tasks/${userATaskId}`)
      .set('Authorization', `Bearer ${userAToken}`);
    expect(deleteRes.status).toBe(204);
  });
});
