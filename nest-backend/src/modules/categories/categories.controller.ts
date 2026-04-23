import { Body, Controller, Delete, Get, Param, Post, Query, Req, UseGuards } from '@nestjs/common';

import { JwtAuthGuard } from '../../common/guards/jwt-auth.guard';

import { assertWorkspacePermission } from '../workspaces/workspace-permissions';

import { WorkspaceContextGuard } from '../workspaces/workspace-context.guard';

import { RequestWithWorkspace } from '../workspaces/workspace.types';

import { CategoriesService } from './categories.service';

import { CreateCategoryDto } from './dto/create-category.dto';

import { CreateSubcategoryDto } from './dto/create-subcategory.dto';



@Controller('categories')

@UseGuards(JwtAuthGuard, WorkspaceContextGuard)

export class CategoriesController {

  constructor(private readonly categories: CategoriesService) {}



  @Get()

  findAll(@Req() req: RequestWithWorkspace) {

    assertWorkspacePermission(req.workspaceContext.role, 'category:read');

    return this.categories.findAll(req.workspaceContext.ownerUserId);

  }

  @Get(':id')
  findOne(@Req() req: RequestWithWorkspace, @Param('id') id: string) {
    assertWorkspacePermission(req.workspaceContext.role, 'category:read');
    return this.categories.getCategoryWithDrillDown(req.workspaceContext.ownerUserId, id);
  }



  @Post()

  create(@Req() req: RequestWithWorkspace, @Body() dto: CreateCategoryDto) {

    assertWorkspacePermission(req.workspaceContext.role, 'category:create');

    return this.categories.createCategory(req.workspaceContext.ownerUserId, dto);

  }



  @Post(':categoryId/subcategories')

  createSub(

    @Req() req: RequestWithWorkspace,

    @Param('categoryId') categoryId: string,

    @Body() dto: CreateSubcategoryDto,

  ) {

    assertWorkspacePermission(req.workspaceContext.role, 'category:create');

    return this.categories.createSubcategory(req.workspaceContext.ownerUserId, categoryId, dto);

  }

  @Delete(':id')
  remove(@Req() req: RequestWithWorkspace, @Param('id') id: string) {
    assertWorkspacePermission(req.workspaceContext.role, 'category:create');
    return this.categories.deleteCategory(req.workspaceContext.ownerUserId, id);
  }

  @Get(':id/history')
  history(
    @Req() req: RequestWithWorkspace,
    @Param('id') id: string,
    @Query('from') from?: string,
    @Query('to') to?: string,
  ) {
    assertWorkspacePermission(req.workspaceContext.role, 'category:read');
    return this.categories.getCategoryHistory(req.workspaceContext.ownerUserId, id, from, to);
  }

}

