-- CategorySystemKey enum + normalized nameKey for case-insensitive dedupe
CREATE TYPE "CategorySystemKey" AS ENUM (
  'daily_expenses',
  'household',
  'vehicle',
  'insurance',
  'financial',
  'donations',
  'business',
  'custom'
);

ALTER TABLE "Category"
  ADD COLUMN "nameKey" TEXT,
  ADD COLUMN "systemKey" "CategorySystemKey",
  ADD COLUMN "sortOrder" INTEGER NOT NULL DEFAULT 0;

UPDATE "Category"
SET "nameKey" = lower(trim(regexp_replace(name, '\s+', ' ', 'g')));

WITH numbered AS (
  SELECT
    id,
    lower(trim(regexp_replace(name, '\s+', ' ', 'g'))) AS base_name,
    ROW_NUMBER() OVER (
      PARTITION BY "userId", lower(trim(regexp_replace(name, '\s+', ' ', 'g')))
      ORDER BY id
    ) AS rn
  FROM "Category"
)
UPDATE "Category" AS c
SET "nameKey" = CASE
  WHEN n.rn = 1 THEN n.base_name
  ELSE n.base_name || '-' || (n.rn - 1)::text
END
FROM numbered AS n
WHERE c.id = n.id;

ALTER TABLE "Category" ALTER COLUMN "nameKey" SET NOT NULL;

ALTER TABLE "SubCategory" ADD COLUMN "nameKey" TEXT;

UPDATE "SubCategory"
SET "nameKey" = lower(trim(regexp_replace(name, '\s+', ' ', 'g')));

WITH numbered AS (
  SELECT
    id,
    lower(trim(regexp_replace(name, '\s+', ' ', 'g'))) AS base_name,
    ROW_NUMBER() OVER (
      PARTITION BY "categoryId", lower(trim(regexp_replace(name, '\s+', ' ', 'g')))
      ORDER BY id
    ) AS rn
  FROM "SubCategory"
)
UPDATE "SubCategory" AS s
SET "nameKey" = CASE
  WHEN n.rn = 1 THEN n.base_name
  ELSE n.base_name || '-' || (n.rn - 1)::text
END
FROM numbered AS n
WHERE s.id = n.id;

ALTER TABLE "SubCategory" ALTER COLUMN "nameKey" SET NOT NULL;

DROP INDEX IF EXISTS "Category_userId_name_key";
DROP INDEX IF EXISTS "SubCategory_categoryId_name_key";

CREATE UNIQUE INDEX "Category_userId_nameKey_key" ON "Category"("userId", "nameKey");
CREATE UNIQUE INDEX "SubCategory_categoryId_nameKey_key" ON "SubCategory"("categoryId", "nameKey");
CREATE INDEX "Category_userId_sortOrder_idx" ON "Category"("userId", "sortOrder");
CREATE INDEX "SubCategory_categoryId_idx" ON "SubCategory"("categoryId");
