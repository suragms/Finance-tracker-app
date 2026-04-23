import {
  BadRequestException,
  ConflictException,
  Injectable,
  NotFoundException,
} from '@nestjs/common';
import { CategorySystemKey, CategoryType } from '@prisma/client';
import { normalizeEntityNameKey } from '../../common/utils/normalize-name-key';
import { PrismaService } from '../../prisma/prisma.service';
import { CategoriesRepository } from './categories.repository';
import { CreateCategoryDto } from './dto/create-category.dto';
import { CreateSubcategoryDto } from './dto/create-subcategory.dto';

@Injectable()
export class CategoriesService {
  constructor(
    private readonly repo: CategoriesRepository,
    private readonly prisma: PrismaService,
  ) {}

  findAll(userId: string) {
    return this.getUserCategories(userId);
  }

  async createCategory(userId: string, dto: CreateCategoryDto) {
    const name = dto.name.trim().replace(/\s+/g, ' ');
    if (!name) {
      throw new BadRequestException('Category name is required');
    }
    const nameKey = normalizeEntityNameKey(name);
    const existing = await this.repo.findCategoryByUserAndNameKey(userId, nameKey);
    if (existing) {
      throw new ConflictException({
        message: 'A category with this name already exists',
        existingCategoryId: existing.id,
      });
    }
    return this.repo.createCategory({
      userId,
      name,
      nameKey,
      systemKey: null,
      type: (dto.type as CategoryType | undefined) ?? CategoryType.expense,
    });
  }

  async createSubcategory(userId: string, categoryId: string, dto: CreateSubcategoryDto) {
    const cat = await this.repo.findCategoryForUser(userId, categoryId);
    if (!cat) throw new NotFoundException('Category not found');
    const name = dto.name.trim().replace(/\s+/g, ' ');
    if (!name) {
      throw new BadRequestException('Subcategory name is required');
    }
    const nameKey = normalizeEntityNameKey(name);
    const dup = await this.repo.findSubcategoryByCategoryAndNameKey(categoryId, nameKey);
    if (dup) {
      throw new ConflictException({
        message: 'A subcategory with this name already exists in this category',
        existingSubCategoryId: dup.id,
      });
    }
    return this.repo.createSubCategory({ categoryId, name, nameKey });
  }

  async getUserCategories(userId: string) {
    const categories = await this.repo.findManyByUser(userId);
    const categoryIds = categories.map((c) => c.id);
    const subCategoryIds = categories.flatMap((c) => c.subCategoryRows.map((s) => s.id));

    const [categorySpend, subCategorySpend] = await Promise.all([
      categoryIds.length
        ? this.prisma.expense.groupBy({
            by: ['categoryId'],
            where: { userId, categoryId: { in: categoryIds } },
            _sum: { amount: true },
          })
        : Promise.resolve([]),
      subCategoryIds.length
        ? this.prisma.expense.groupBy({
            by: ['subCategoryId'],
            where: { userId, subCategoryId: { in: subCategoryIds } },
            _sum: { amount: true },
          })
        : Promise.resolve([]),
    ]);

    const categorySpendMap = new Map(
      categorySpend.map((row) => [row.categoryId, Number(row._sum.amount ?? 0)]),
    );
    const subSpendMap = new Map(
      subCategorySpend.map((row) => [row.subCategoryId ?? '', Number(row._sum.amount ?? 0)]),
    );

    return {
      data: categories.map((category) => {
        const visual = categoryVisuals(category.systemKey);
        return {
          id: category.id,
          name: category.name,
          systemKey: category.systemKey,
          type: category.type,
          icon: visual.icon,
          color: visual.color,
          subcategories: category.subCategoryRows.map((sub) => ({
            id: sub.id,
            name: sub.name,
            totalSpent: subSpendMap.get(sub.id) ?? 0,
          })),
          totalSpent: categorySpendMap.get(category.id) ?? 0,
        };
      }),
    };
  }

  async getCategoryWithDrillDown(userId: string, categoryId: string) {
    const category = await this.repo.findCategoryForUserWithSubs(userId, categoryId);
    if (!category) throw new NotFoundException('Category not found');

    const subIds = category.subCategoryRows.map((s) => s.id);
    const [categoryExpenses, groupedSubTotals, expensesBySub] = await Promise.all([
      this.prisma.expense.findMany({
        where: { userId, categoryId },
        orderBy: { date: 'desc' },
      }),
      subIds.length
        ? this.prisma.expense.groupBy({
            by: ['subCategoryId'],
            where: { userId, categoryId, subCategoryId: { in: subIds } },
            _sum: { amount: true },
          })
        : Promise.resolve([]),
      subIds.length
        ? this.prisma.expense.findMany({
            where: { userId, categoryId, subCategoryId: { in: subIds } },
            orderBy: { date: 'desc' },
          })
        : Promise.resolve([]),
    ]);

    const subTotalMap = new Map(
      groupedSubTotals.map((row) => [row.subCategoryId ?? '', Number(row._sum.amount ?? 0)]),
    );
    const bySub = new Map<string, typeof expensesBySub>();
    for (const expense of expensesBySub) {
      const key = expense.subCategoryId ?? '';
      bySub.set(key, [...(bySub.get(key) ?? []), expense]);
    }

    const totalSpent = categoryExpenses.reduce(
      (sum, expense) => sum + Number(expense.amount),
      0,
    );
    const visual = categoryVisuals(category.systemKey);
    return {
      data: {
        id: category.id,
        name: category.name,
        systemKey: category.systemKey,
        type: category.type,
        icon: visual.icon,
        color: visual.color,
        totalSpent,
        subcategories: category.subCategoryRows.map((sub) => ({
          id: sub.id,
          name: sub.name,
          totalSpent: subTotalMap.get(sub.id) ?? 0,
          expenses: bySub.get(sub.id) ?? [],
        })),
      },
    };
  }

  async getCategoryHistory(
    userId: string,
    categoryId: string,
    from?: string,
    to?: string,
  ) {
    const category = await this.repo.findCategoryForUser(userId, categoryId);
    if (!category) throw new NotFoundException('Category not found');

    const dateFilter: { gte?: Date; lte?: Date } = {};
    if (from) {
      const start = new Date(from);
      if (!Number.isNaN(start.getTime())) dateFilter.gte = start;
    }
    if (to) {
      const end = new Date(to);
      if (!Number.isNaN(end.getTime())) dateFilter.lte = end;
    }

    const expenses = await this.prisma.expense.findMany({
      where: {
        userId,
        categoryId,
        ...(Object.keys(dateFilter).length ? { date: dateFilter } : {}),
      },
      orderBy: { date: 'desc' },
    });

    // Income model in current schema has no category/subcategory relation.
    const incomes =
      category.type === CategoryType.income
        ? await this.prisma.income.findMany({
            where: {
              userId,
              ...(Object.keys(dateFilter).length ? { date: dateFilter } : {}),
            },
            orderBy: { date: 'desc' },
          })
        : [];

    return {
      data: {
        categoryId,
        from: from ?? null,
        to: to ?? null,
        expenses,
        incomes,
      },
    };
  }

  async deleteCategory(userId: string, categoryId: string) {
    const category = await this.repo.findCategoryForUser(userId, categoryId);
    if (!category) throw new NotFoundException('Category not found');
    if (category.systemKey && category.systemKey !== CategorySystemKey.custom) {
      throw new BadRequestException('Only custom categories can be deleted');
    }
    await this.repo.softDeleteCustomCategory(categoryId);
    return { ok: true };
  }

  async seedDefaultCategories(userId: string) {
    const defaults = [
      { name: 'Food & Dining', systemKey: CategorySystemKey.daily_expenses, type: CategoryType.expense, sub: ['Groceries', 'Restaurants', 'Zomato/Swiggy'] },
      { name: 'Home & Utilities', systemKey: CategorySystemKey.household, type: CategoryType.expense, sub: ['Rent', 'Electricity', 'Water', 'Internet'] },
      { name: 'Transport', systemKey: CategorySystemKey.vehicle, type: CategoryType.expense, sub: ['Fuel', 'Uber/Ola', 'Public Transport'] },
      { name: 'Health & Wellness', systemKey: CategorySystemKey.insurance, type: CategoryType.expense, sub: ['Medicines', 'Doctor', 'Gym'] },
      { name: 'Entertainment', systemKey: CategorySystemKey.custom, type: CategoryType.expense, sub: ['Netflix', 'Movies', 'Gaming'] },
      { name: 'Salary', systemKey: null, type: CategoryType.income, sub: [] },
      { name: 'Other', systemKey: CategorySystemKey.custom, type: CategoryType.expense, sub: [] },
    ];

    for (const d of defaults) {
      const nameKey = normalizeEntityNameKey(d.name);
      try {
        const cat = await this.repo.createCategory({
          userId,
          name: d.name,
          nameKey,
          systemKey: d.systemKey,
          type: d.type,
        });
        for (const s of d.sub) {
          await this.repo.createSubCategory({
            categoryId: cat.id,
            name: s,
            nameKey: normalizeEntityNameKey(s),
          });
        }
      } catch (e) {
        // Silently skip if category exists (idempotent seeding)
      }
    }
  }
}

function categoryVisuals(systemKey: CategorySystemKey | null) {
  switch (systemKey) {
    case CategorySystemKey.daily_expenses:
      return { icon: 'restaurant', color: '#EF4444' };
    case CategorySystemKey.household:
      return { icon: 'home', color: '#F59E0B' };
    case CategorySystemKey.vehicle:
      return { icon: 'directions_car', color: '#3B82F6' };
    case CategorySystemKey.insurance:
      return { icon: 'health_and_safety', color: '#10B981' };
    case CategorySystemKey.financial:
      return { icon: 'account_balance', color: '#6366F1' };
    case CategorySystemKey.donations:
      return { icon: 'volunteer_activism', color: '#EC4899' };
    case CategorySystemKey.business:
      return { icon: 'business_center', color: '#8B5CF6' };
    case CategorySystemKey.custom:
      return { icon: 'category', color: '#64748B' };
    default:
      return { icon: 'category', color: '#64748B' };
  }
}
