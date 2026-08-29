const prisma = require('../../config/db');

exports.getActiveCities = async (req, res, next) => {
  try {
    const cities = await prisma.serviceableCity.findMany({
      where: { isActive: true },
      orderBy: { name: 'asc' }
    });
    res.status(200).json({ success: true, data: cities });
  } catch (error) {
    next(error);
  }
};
