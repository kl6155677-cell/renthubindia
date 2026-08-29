const prisma = require('../../config/db');

const getAllCategories = async () => {
  const categories = await prisma.category.findMany({
    orderBy: {
      name: 'asc',
    },
  });
  return categories;
};

module.exports = {
  getAllCategories,
};
