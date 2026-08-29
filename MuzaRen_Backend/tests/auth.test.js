const authService = require('../src/modules/auth/auth.service');
const prisma = require('../src/config/db');

jest.mock('../src/config/db', () => ({
  user: {
    findUnique: jest.fn(),
    create: jest.fn(),
  },
}));

describe('Auth Service Flow Validation', () => {
  beforeEach(() => {
    jest.clearAllMocks();
  });

  describe('User Registration Limits', () => {
    it('Should cleanly explicitly reject registrations using emails that already exist locally', async () => {
      prisma.user.findUnique.mockResolvedValue({ id: '123', email: 'test@renthubindia.com' });

      await expect(
        authService.register({ name: 'Test User', email: 'test@renthubindia.com', password: 'password123' })
      ).rejects.toThrow('User already exists. Redirecting to login!');
    });
    
    it('Should correctly map and construct a new unverified node into Prisma correctly when empty', async () => {
        prisma.user.findUnique.mockResolvedValue(null);
        prisma.user.create.mockResolvedValue({ id: '12345', email: 'valid@renthubindia.com' });
        
        const result = await authService.register({ name: 'Valid User', email: 'valid@renthubindia.com', password: 'password123' });
        expect(result.user).toHaveProperty('id');
        expect(result).toHaveProperty('token');
        expect(prisma.user.create).toHaveBeenCalledTimes(1);
    });
  });
});
