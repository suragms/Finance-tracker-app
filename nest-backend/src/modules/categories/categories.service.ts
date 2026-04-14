import {
  BadRequestException,
  ConflictException,
  Injectable,
  NotFoundException,
} from '@nestjs/common';
import { CategoryType } from '@prisma/client';
import { normalizeEntityNameKey } from '../../common/utils/normalize-name-key';
import { CategoriesRepository } from './categories.repository';
import { CreateCategoryDto } from './dto/create-category.dto';
import { CreateSubcategoryDto } from './dto/create-subcategory.dto';

@Injectable()
export class CategoriesService {
  constructor(private readonly repo: CategoriesRepository) {}

  findAll(userId: string) {
    return this.repo.findManyByUser(userId);
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
}
