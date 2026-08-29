-- AlterTable
ALTER TABLE "Chat" ADD COLUMN     "deletedBy" TEXT[] DEFAULT ARRAY[]::TEXT[];
