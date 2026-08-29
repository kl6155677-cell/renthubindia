const prisma = require('../../config/db');

const submitReport = async (reporterId, data) => {
  const { targetType, targetId, category, description } = data;

  const payload = {
    reporterId,
    targetType,
    category,
    description,
    status: 'OPEN'
  };

  // Map the generic targetId natively into Prisma relational bounds precisely depending on the enum mapping
  if (targetType === 'LISTING') {
    payload.targetListingId = targetId;
  } else if (targetType === 'USER') {
    payload.targetUserId = targetId;
  } else {
    // Currently MESSAGE targets do not have explicit relation links in schema natively
    // They are tracked implicitly for admins by the raw targetId if extended later.
  }

  const report = await prisma.report.create({
    data: payload
  });

  return report;
};

module.exports = {
  submitReport
};
