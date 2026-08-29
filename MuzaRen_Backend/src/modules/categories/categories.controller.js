const categoriesService = require('./categories.service');

const getAllCategories = async (req, res, next) => {
  try {
    const categories = await categoriesService.getAllCategories();
    res.status(200).json({ success: true, data: categories });
  } catch (error) {
    next(error);
  }
};

module.exports = {
  getAllCategories,
};
