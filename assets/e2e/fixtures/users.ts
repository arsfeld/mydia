/**
 * User fixtures for E2E tests
 */

export const testUsers = {
  admin: {
    username: 'admin',
    password: 'admin',
    email: 'admin@example.com',
    role: 'admin'
  },
  user: {
    username: 'testuser',
    password: 'testpass',
    email: 'testuser@example.com',
    role: 'user'
  }
} as const;

export type TestUser = typeof testUsers.admin | typeof testUsers.user;
