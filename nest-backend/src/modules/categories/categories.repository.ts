import { Injectable } from '@nestjs/common';
import { Prisma } from '@prisma/client';
import { PrismaService } from '../../prisma/prisma.service';

@Injectable()
export class CategoriesRepository {
  constructor(private readonly prisma: PrismaService) {}

  findManyByUser(userId: string) {
    return this.prisma.category.findMany({
      where: {
        userId,
        NOT: { nameKey: { startsWith: '__deleted__' } },
      },
      include: {
        subCategoryRows: { orderBy: [{ sortOrder: 'asc' }, { name: 'asc' }] },
      },
      orderBy: [{ sortOrder: 'asc' }, { name: 'asc' }],
    });
  }

  findCategoryByUserAndNameKey(userId: string, nameKey: string) {
    return this.prisma.category.findFirst({ where: { userId, nameKey } });
  }

  findSubcategoryByCategoryAndNameKey(categoryId: string, nameKey: string) {
    return this.prisma.subCategory.findFirst({ where: { categoryId, nameKey } });
  }

  createCategory(data: Prisma.CategoryUncheckedCreateInput) {
    return this.prisma.category.create({
      data,
      include: { subCategoryRows: true },
    });
  }

  createSubCategory(data: Prisma.SubCategoryUncheckedCreateInput) {
    return this.prisma.subCategory.create({ data });
  }

  findCategoryForUser(userId: string, categoryId: string) {
    return this.prisma.category.findFirst({
      where: {
        id: categoryId,
        userId,
        NOT: { nameKey: { startsWith: '__deleted__' } },
      },
    });
  }

  findCategoryForUserWithSubs(userId: string, categoryId: string) {
    return this.prisma.category.findFirst({
      where: {
        id: categoryId,
        userId,
        NOT: { nameKey: { startsWith: '__deleted__' } },
      },
      include: {
        subCategoryRows: { orderBy: [{ sortOrder: 'asc' }, { name: 'asc' }] },
      },
    });
  }

  softDeleteCustomCategory(categoryId: string) {
    return this.prisma.category.update({
      where: { id: categoryId },
      data: {
        name: 'Deleted category',
        nameKey: `__deleted__${categoryId}`,
      },
    });
  }
}
