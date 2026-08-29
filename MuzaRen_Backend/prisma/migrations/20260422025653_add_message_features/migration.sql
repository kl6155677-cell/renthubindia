/*
  Warnings:

  - You are about to drop the column `isEdited` on the `Message` table. All the data in the column will be lost.

*/
-- AlterTable
ALTER TABLE "Message" DROP COLUMN "isEdited",
ADD COLUMN     "deletedForAll" BOOLEAN NOT NULL DEFAULT false,
ADD COLUMN     "deletedForSelf" TEXT[] DEFAULT ARRAY[]::TEXT[],
ADD COLUMN     "editedAt" TIMESTAMP(3),
ADD COLUMN     "reactions" JSONB NOT NULL DEFAULT '{}',
ADD COLUMN     "replyToId" TEXT;

-- AddForeignKey
ALTER TABLE "Message" ADD CONSTRAINT "Message_replyToId_fkey" FOREIGN KEY ("replyToId") REFERENCES "Message"("id") ON DELETE SET NULL ON UPDATE CASCADE;
